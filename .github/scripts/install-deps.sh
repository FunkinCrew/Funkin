#!/usr/bin/env bash

set -euo pipefail

TARGET="${1:-linux}"

rm -rf .haxelib
mkdir -p .haxelib
haxelib setup .haxelib
haxelib --never newrepo

if [ "$TARGET" = "linux" ] || [ "$TARGET" = "android" ]; then
  sudo apt-get update -qq
  sudo apt-get install -y libhl-dev
fi

haxelib install hxcpp 4.3.2 --always --quiet

safe_git_install() {
  local name=$1
  local url=$2
  local rev=$3
  local sub_dir=${4:-}

  echo "Installing $name ($rev)..."
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
  )

  if [ -n "$sub_dir" ]; then
    haxelib dev "$name" ".haxelib/$name/git/$sub_dir"
  else
    haxelib dev "$name" ".haxelib/$name/git"
  fi
}

safe_git_install "lime" "https://github.com/FunkinCrew/lime" "826d25199c17329b730ae09838f3df7a2903c471"
safe_git_install "openfl" "https://github.com/FunkinCrew/openfl" "88534506595a32c3f02b21b3987e789a24074ae7"
safe_git_install "flixel" "https://github.com/FunkinCrew/flixel" "f7b94eebf7dbb452a929d0c67ab31a9cbd71d3a0"
safe_git_install "flixel-addons" "https://github.com/FunkinCrew/flixel-addons" "187f93b34f93c6a405d634a42913c745e443463a"
safe_git_install "flixel-animate" "https://github.com/MaybeMaru/flixel-animate" "c5e3393c70b71a191f20fa902114cea92042e486"
safe_git_install "FlxPartialSound" "https://github.com/FunkinCrew/FlxPartialSound.git" "2f984e244f1544ca98c0e03b9b21ae570f07ac55"
safe_git_install "astc-compressor" "https://github.com/KarimAkra/astc-compressor" "b7a91b3072dc16e785a9bde847f17ba0ef15dd47"
safe_git_install "extension-admob" "https://github.com/FunkinCrew/extension-admob" "5c908b3f7c74115a8b52eddf1e05525f4873f26e"
safe_git_install "extension-webviewcore" "https://github.com/LimeExtensions/extension-webviewcore" "d13109450d65c40678244ca23b1aa88ac18d77e6"
safe_git_install "funkin.vis" "https://github.com/FunkinCrew/funkVis" "02bada154b474c2554709b9d12aef0cbf0da3ec9"
safe_git_install "grig.audio" "https://github.com/FunkinCrew/grig.audio" "6409f3c6d1b4c52176813d3ede86c0d34e8af2c1" "src"
safe_git_install "haxeui-core" "https://github.com/FunkinCrew/haxeui-core" "09f2512564b45e92229e21433e6dd482391f7b7d"
safe_git_install "haxeui-flixel" "https://github.com/haxeui/haxeui-flixel" "100f2c96beab619cfe72c567a058c41c71e3e998"
safe_git_install "hxcpp-debug-server" "https://github.com/FunkinCrew/hxcpp-debugger" "7459934666a473a4cc4d066ba4a93ef92f1ce94c" "hxcpp-debug-server"
safe_git_install "hxjsonast" "https://github.com/nadako/hxjsonast/" "20e72cc68c823496359775ac1f06500e67f189d5"
safe_git_install "json2object" "https://github.com/FunkinCrew/json2object" "59e0467c953d1f26e3cbf2a070f140e2d2e8457d"
safe_git_install "newgrounds" "https://github.com/FunkinCrew/Newgrounds" "b2b53cd0a5f030af74efd325732951cddbea8826"
safe_git_install "polymod" "https://github.com/FunkinCrew/polymod" "fb123758b90127f5647727727f273d27e93cabdb"
safe_git_install "thx.core" "https://github.com/fponticelli/thx.core" "2bf2b992e06159510f595554e6b952e47922f128"
safe_git_install "thx.semver" "https://github.com/fponticelli/thx.semver" "bdb191fe7cf745c02a980749906dbf22719e200b"

haxelib install format 3.5.0 --always --quiet --nodeps
haxelib install hamcrest 3.0.0 --always --quiet --nodeps
haxelib install hxdiscord_rpc 1.3.0 --always --quiet --nodeps
haxelib install hxgamemode 1.0.1 --always --quiet --nodeps
haxelib install hxp 1.3.0 --always --quiet --nodeps
haxelib install hxvlc 2.2.6 --always --quiet --nodeps
haxelib install jsonpatch 1.1.0 --always --quiet --nodeps
haxelib install jsonpath 1.1.0 --always --quiet --nodeps
haxelib install extension-androidtools 2.2.2 --always --quiet --nodeps
haxelib install extension-haptics 1.0.4 --always --quiet --nodeps
haxelib install extension-iapcore 1.0.4 --always --quiet --nodeps
haxelib install extension-iarcore 1.0.3 --always --quiet --nodeps

echo "Compiling Lime tools (run.n)..."
(
  cd .haxelib/lime/git/tools
  haxe tools.hxml
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
  echo "Rebuilding Lime Android..."
  haxelib run lime rebuild android -v
else
  echo "Rebuilding Lime tools..."
  haxelib run lime rebuild tools -v
fi
