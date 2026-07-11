#!/usr/bin/env bash

set -euo pipefail

TARGET="${1:-linux}"

if [ ! -f hmm.json ]; then
  echo "Error: hmm.json not found in $(pwd). This script expects to run from the repo root." >&2
  exit 1
fi

rm -rf .haxelib
mkdir -p .haxelib
haxelib setup .haxelib
haxelib --never newrepo

download_zip_dependency() {
  local name=$1
  local url=$2
  local commit=$3

  echo "Manually downloading $name source ZIP (commit: $commit)..."
  rm -rf ".haxelib/$name"
  mkdir -p ".haxelib/$name/git"

  curl -sSL "$url/archive/$commit.zip" -o "temp_${name}.zip"
  unzip -q "temp_${name}.zip"

  local unpacked_dir
  unpacked_dir=$(find . -maxdepth 1 -type d -name "${name}-*" -o -name "*-${name}-*" | head -n 1)

  if [ -z "$unpacked_dir" ] || [ ! -d "$unpacked_dir" ]; then
    unpacked_dir=$(find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name ".git" ! -name ".github" ! -name ".haxelib" | head -n 1)
  fi

  mv "$unpacked_dir"/* ".haxelib/$name/git/"
  rm -rf "$unpacked_dir" "temp_${name}.zip"

  haxelib dev "$name" ".haxelib/$name/git"
}

# --- ФУНКЦИЯ ДЛЯ УСТАНОВКИ ЗАВИСИМОСТЕЙ С SUBMODULE'АМИ (git, не zip) ---
git_clone_with_submodules() {
  local name=$1
  local url=$2
  local rev=$3

  echo "Cloning $name via git (commit: $rev, with submodules)..."
  rm -rf ".haxelib/$name"
  mkdir -p ".haxelib/$name/git"
  (
    cd ".haxelib/$name/git"
    git init -q
    git remote add origin "$url"
    if ! git fetch --depth=1 origin "$rev" --quiet; then
      echo "  shallow fetch failed for $name, falling back to full fetch"
      git fetch origin --quiet
    fi
    git reset --hard "$rev" --quiet
    if [ -f .gitmodules ]; then
      echo "  Initializing submodules for $name..."
      git submodule update --init --recursive --depth 1
    fi
  )
  haxelib dev "$name" ".haxelib/$name/git"
}

# --- 1. УСТАНОВКА ОСНОВНЫХ БИБЛИОТЕК ---
download_zip_dependency "hxcpp" "https://github.com/FunkinCrew/hxcpp" "450d112e50acff57b1bc9d584dcf1374c9e33995"

git_clone_with_submodules "lime" "https://github.com/FunkinCrew/lime" "826d25199c17329b730ae09838f3df7a2903c471"
download_zip_dependency "openfl" "https://github.com/FunkinCrew/openfl" "88534506595a32c3f02b21b3987e789a24074ae7"
download_zip_dependency "flixel" "https://github.com/FunkinCrew/flixel" "f7b94eebf7dbb452a929d0c67ab31a9cbd71d3a0"

# --- 2. УСТАНОВКА ОСТАЛЬНЫХ ЗАВИСИМОСТЕЙ ЧЕРЕЗ hmm ---
haxelib install hmm --quiet

echo "Installing remaining dependencies via hmm (hmm.json)..."

haxelib run hmm install -q

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
  echo "Rebuilding Lime $TARGET ndll..."
  haxelib run lime rebuild "$TARGET" -v
fi
