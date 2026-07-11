#!/usr/bin/env bash

set -euo pipefail

TARGET="${1:-linux}"

if [ ! -f hmm.json ]; then
  echo "Error: hmm.json not found in $(pwd). This script expects to run from the repo root." >&2
  exit 1
fi

if [ "$TARGET" = "linux" ] || [ "$TARGET" = "android" ]; then
  sudo apt-get update -qq
  sudo apt-get install -y libvlc-dev libvlccore-dev libvlccore9
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

echo "Compiling hxcpp tools..."
(
  cd .haxelib/hxcpp/git/tools/hxcpp
  haxe compile.hxml
)

echo "Setting up Lime..."
haxelib run lime setup -y

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
