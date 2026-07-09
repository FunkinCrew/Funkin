#!/usr/bin/env bash
# Общий скрипт установки зависимостей Haxe/Lime/Flixel для сборки FNF.
# Используется всеми джобами (windows / linux / android).
set -euo pipefail

TARGET="${1:-linux}"

if [ ! -f hmm.json ]; then
  echo "Error: hmm.json not found in $(pwd). This script expects to run from the repo root." >&2
  exit 1
fi

# Полная очистка локальной директории haxelib перед началом
rm -rf .haxelib
mkdir -p .haxelib
haxelib setup .haxelib
haxelib --never newrepo

# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ СКАЧИВАНИЯ ZIP-АРХИВОВ (Обход багов Git на CI) ---
download_zip_dependency() {
  local name=$1
  local url=$2
  local commit=$3
  
  echo "Manually downloading $name source ZIP (commit: $commit)..."
  rm -rf ".haxelib/$name"
  mkdir -p ".haxelib/$name/git"
  
  # Скачиваем архив коммита напрямую через GitHub, сохраняя во временную папку
  curl -sSL "$url/archive/$commit.zip" -o "temp_${name}.zip"
  unzip -q "temp_${name}.zip"
  
  # Ищем только директории (-type d), исключая скрытые и саму .haxelib
  local unpacked_dir
  unpacked_dir=$(find . -maxdepth 1 -type d -name "${name}-*" -o -name "*-${name}-*" | head -n 1)
  
  if [ -z "$unpacked_dir" ] || [ ! -d "$unpacked_dir" ]; then
    # Фолбэк на случай, если имя репозитория в GitHub архиве отличается
    unpacked_dir=$(find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name ".git" ! -name ".github" ! -name ".haxelib" | head -n 1)
  fi
  
  mv "$unpacked_dir"/* ".haxelib/$name/git/"
  rm -rf "$unpacked_dir" "temp_${name}.zip"
  
  # Регистрируем в локальном haxelib через dev-путь
  haxelib dev "$name" ".haxelib/$name/git"
}

# --- 1. НАДЕЖНАЯ УСТАНОВКА ОСНОВНЫХ БИБЛИОТЕК (Без использования Git) ---
download_zip_dependency "hxcpp" "https://github.com/FunkinCrew/hxcpp" "450d112e50acff57b1bc9d584dcf1374c9e33995"
download_zip_dependency "lime" "https://github.com/FunkinCrew/lime" "826d25199c17329b730ae09838f3df7a2903c471"
download_zip_dependency "openfl" "https://github.com/FunkinCrew/openfl" "88534506595a32c3f02b21b3987e789a24074ae7"
download_zip_dependency "flixel" "https://github.com/FunkinCrew/flixel" "f7b94eebf7dbb452a929d0c67ab31a9cbd71d3a0"

# --- 2. ХИРУРГИЧЕСКИЙ ПАТЧ СТАНДАРТА C++ (Решаем проблему Bit Rot для openal-soft) ---
echo "Patching hxcpp toolchains to force C++17 standard..."
# Меняем -std=c++11 и -std=c++14 на -std=c++17 для GCC (Linux/Android)
find .haxelib/hxcpp/git -name "toolchain.xml" -o -name "gcc-toolchain.xml" | xargs -r sed -i 's/-std=c++11/-std=c++17/g' || true
find .haxelib/hxcpp/git -name "toolchain.xml" -o -name "gcc-toolchain.xml" | xargs -r sed -i 's/-std=c++14/-std=c++17/g' || true
# Меняем /std:c++14 на /std:c++17 для MSVC (Windows)
find .haxelib/hxcpp/git -name "msvc-setup.bat" | xargs -r sed -i 's/\/std:c++14/\/std:c++17/g' || true

# --- 3. УСТАНОВКА ОСТАЛЬНЫХ ЗАВИСИМОСТЕЙ ---
# hmm сам ставится как обычный haxelib-пакет
haxelib install hmm --quiet

echo "Installing remaining dependencies via hmm (hmm.json)..."
# hmm увидит, что hxcpp, lime, openfl и flixel уже зарегистрированы, и займется только мелочью
haxelib run hmm install -q

# Компиляция hxcpp-тулов (compile.hxml) — обязательный шаг перед использованием hxcpp/lime
echo "Compiling hxcpp tools..."
(
  cd .haxelib/hxcpp/git/tools/hxcpp
  haxe compile.hxml
)

echo "Setting up Lime..."
haxelib run lime setup -y

echo "Rebuilding Lime tools..."
haxelib run lime rebuild tools -v

if [ "$TARGET" = "android" ]; then
  # Обход интерактивной проверки Android-окружения в Lime
  mkdir -p "$HOME/.lime"
  cat > "$HOME/.lime/config.xml" << EOF
<xml>
  <set name="ANDROID_SETUP" value="true" />
  <set name="ANDROID_SDK_ROOT" value="$ANDROID_HOME" />
  <set name="ANDROID_NDK_ROOT" value="$ANDROID_NDK_HOME" />
</xml>
EOF
  echo "Rebuilding Lime Android ndll..."
  haxelib run lime rebuild android -v
else
  # Явная пересборка под конкретную платформу (избегаем ошибок ABI / Primitive not found)
  echo "Rebuilding Lime $TARGET ndll..."
  haxelib run lime rebuild "$TARGET" -v
fi
