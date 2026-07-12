#!/usr/bin/env bash

set -euo pipefail

TARGET="${1:-linux}"

if [ ! -f hmm.json ]; then
  echo "Error: hmm.json not found in $(pwd). This script expects to run from the repo root." >&2
  exit 1
fi

if [ "$TARGET" = "linux" ] || [ "$TARGET" = "android" ]; then
  echo "Installing system dependencies and 32-bit support..."
  
  sudo dpkg --add-architecture i386
  sudo apt-get update -qq
 
  sudo apt-get install -y --no-install-recommends \
    build-essential cmake \
    gcc-multilib g++-multilib \
    libc6-dev-i386 \
    libbsd-dev libbsd-dev:i386 \
    libdbus-1-dev libdbus-1-dev:i386 \
    libvlc-dev libvlccore-dev libvlccore9 \
    libasound2-dev libpulse-dev \
    libudev-dev libxkbcommon-dev \
    libx11-dev libx11-dev:i386 \
    libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev \
    libxxf86vm-dev libxss-dev \
    libgl1-mesa-dev libgl1-mesa-dev:i386 libglu1-mesa-dev \
    libdrm-dev libgbm-dev libegl1-mesa-dev
fi

rm -rf .haxelib
mkdir -p .haxelib
haxelib --never newrepo

git config --global advice.detachedHead false

echo "Installing FunkinCrew's patched haxelib & hmm..."
haxelib --global git haxelib https://github.com/FunkinCrew/haxelib.git --quiet
haxelib --global git hmm https://github.com/FunkinCrew/hmm.git --quiet

echo "Reformatting haxelib repository for patched haxelib..."
haxelib --always fixrepo

echo "Installing dependencies via hmm (hmm.json)..."
haxelib --global run hmm install -q

haxelib set hxcpp git --always

echo "Compiling hxcpp run stub (tools/run)..."
(
  cd .haxelib/hxcpp/git/tools/run
  haxe compile.hxml
)

echo "Compiling hxcpp tools (tools/hxcpp)..."
(
  cd .haxelib/hxcpp/git/tools/hxcpp
  haxe compile.hxml
)

echo "Setting up Lime..."
haxelib run lime setup -y

echo "Forcing hxcpp to use the git-installed (FunkinCrew fork) version..."
haxelib set hxcpp git --always

if [ "$TARGET" = "android" ]; then
  mkdir -p "$HOME/.lime"
  cat > "$HOME/.lime/config.xml" << EOF
<xml>
  <set name="ANDROID_SETUP" value="true" />
  <set name="ANDROID_SDK" value="$ANDROID_HOME" />
  <set name="ANDROID_NDK_ROOT" value="$ANDROID_NDK_HOME" />
</xml>
EOF
  echo "Rebuilding Lime host (linux) ndll for asset packaging tools..."
  haxelib run lime rebuild linux
  echo "Rebuilding Lime Android ndll..."
  haxelib run lime rebuild android
else
  echo "Rebuilding Lime $TARGET ndll..."
  haxelib run lime rebuild "$TARGET"
fi
