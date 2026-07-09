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

# 1. НАДЕЖНАЯ УСТАНОВКА HXCPP (Обход багов скачивания hmm/haxelib на CI)
echo "Manually fetching specific hxcpp commit..."
mkdir -p .haxelib/hxcpp/git
cd .haxelib/hxcpp/git
git init -q
git remote add origin "https://github.com/FunkinCrew/hxcpp"
# Fetch всей истории коммитов, чтобы точно найти старый хэш в ветке
git fetch origin --quiet
git reset --hard "450d112e50acff57b1bc9d584dcf1374c9e33995" --quiet
cd ../../..
# Регистрируем hxcpp в haxelib локально
haxelib dev hxcpp .haxelib/hxcpp/git

# 2. ХИРУРГИЧЕСКИЙ ПАТЧ СТАНДАРТА C++ (Решаем проблему Bit Rot для openal-soft)
echo "Patching hxcpp toolchains to force C++17 standard..."
# Меняем -std=c++11 и -std=c++14 на -std=c++17 для GCC (Linux/Android)
find .haxelib/hxcpp/git -name "toolchain.xml" -o -name "gcc-toolchain.xml" | xargs -r sed -i 's/-std=c++11/-std=c++17/g' || true
find .haxelib/hxcpp/git -name "toolchain.xml" -o -name "gcc-toolchain.xml" | xargs -r sed -i 's/-std=c++14/-std=c++17/g' || true
# Меняем /std:c++14 на /std:c++17 для MSVC (Windows)
find .haxelib/hxcpp/git -name "msvc-setup.bat" | xargs -r sed -i 's/\/std:c++14/\/std:c++17/g' || true

# 3. УСТАНОВКА ОСТАЛЬНЫХ ЗАВИСИМОСТЕЙ
# hmm сам ставится как обычный haxelib-пакет
haxelib install hmm --quiet

echo "Installing dependencies via hmm (hmm.json)..."
# hmm увидит, что hxcpp уже на месте (dev-путь), и просто пропустит его скачивание
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
