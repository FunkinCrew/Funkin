# Compiles a mod's scripted classes to a single .cppia the game can load.
# Usage: ./build_cppia.sh [--sdk <sdk-dir>] [--target <platform>] <game-root> <script-dir> <output.cppia> [Class ...]
# 	target defaults to windows, and only picks which SDK folder is used by default

# SDK here contains `export_classes.info and cppia.hxml`, and you also need the game checked out (as seen by 'game root)
# That refers to the games source code, not a compiled version of the game.

# A full example of it might be:
# ./build_cppia.sh --sdk ./funkin-cppia-sdk ./Funkin ./my-mod/scripts/cppia-src/ MyMod.cppia

# You are also able (as seen by 'Class ...') to write specific classes you want to compile.
# IE: [MyModule YourModule OurModule]

set -euo pipefail

SDK=""
TARGET="windows"
CONFIG="release"
while [ "$#" -gt 0 ]; do
	if [ "$1" = "--sdk" ]; then
		SDK="$2"; shift 2
	elif [ "$1" = "--target" ]; then
		TARGET="$2"; shift 2
	elif [ "$1" = "--config" ]; then
		CONFIG="$2"; shift 2
	else
		break
	fi
done

if [ "$#" -lt 3 ]; then
	echo "Usage: $0 [--sdk <sdk-dir>] <game-root> <script-dir> <output.cppia> [Class ...]" >&2
	exit 1
fi

ROOT="$1"; shift
SCRIPT_DIR="$1"; shift
OUTPUT="$1"; shift
CLASSES=("$@")

if [ ! -f "$ROOT/project.hxp" ]; then
	echo "$ROOT does not look like the game checkout, no project.hxp there." >&2
	exit 1
fi
ROOT="$(cd "$ROOT" && pwd)" || exit 1

if [ ! -d "$SCRIPT_DIR" ]; then
	echo "No such script directory: $SCRIPT_DIR" >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" || exit 1

if [ "${OUTPUT#/}" = "$OUTPUT" ] && [ "${OUTPUT#[A-Za-z]:}" = "$OUTPUT" ]; then
	OUTPUT="$(pwd)/$OUTPUT"
fi

if [ -z "$SDK" ] && [ -f "$ROOT/export/$CONFIG/$TARGET/cppia-sdk/cppia.hxml" ]; then
	SDK="$ROOT/export/$CONFIG/$TARGET/cppia-sdk"
fi

towin() {
	if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi
}

GENERATED="$(mktemp -t cppia-XXXXXX.hxml)"
trap 'rm -f "$GENERATED"' EXIT

if [ -n "$SDK" ]; then
	SDK_ABS="$(cd "$SDK" && pwd)" || exit 1

	if [ ! -f "$SDK_ABS/export_classes.info" ]; then
		echo "SDK at $SDK_ABS has no export_classes.info" >&2
		exit 1
	fi

	HOST_CLASSES="$(towin "$SDK_ABS/export_classes.info")"
	sed "s|\${FUNKIN_ROOT}|$(towin "$ROOT")|g" "$SDK_ABS/cppia.hxml" > "$GENERATED"
	echo "Using SDK $SDK_ABS"
else
	if [ ! -f "$ROOT/export_classes.info" ]; then
		echo "No SDK found at $ROOT/export/$CONFIG/$TARGET/cppia-sdk, and no $ROOT/export_classes.info to fall back on." >&2
		echo "Build the game once for this target and config, or pass --sdk <dir>." >&2
		exit 1
	fi

	HOST_CLASSES="$(towin "$ROOT/export_classes.info")"

	(cd "$ROOT" && haxelib run lime display "$TARGET" "-$CONFIG") \
		| grep -v '^-main ' \
		| grep -v '^-cpp ' \
		| grep -v '^--no-output$' \
		| grep -v '^-D scriptable$' \
		| grep -v '^--macro keep(' \
		> "$GENERATED"
	echo "No SDK given, deriving arguments from $ROOT"
fi

if [ "${#CLASSES[@]}" -eq 0 ]; then
	while IFS= read -r f; do
		rel="${f#"$SCRIPT_DIR"/}"
		CLASSES+=("$(echo "${rel%.hx}" | tr '/' '.')")
	done < <(find "$SCRIPT_DIR" -type f -name '*.hx' | sort)
fi

if [ "${#CLASSES[@]}" -eq 0 ]; then
	echo "No .hx files found under $SCRIPT_DIR" >&2
	exit 1
fi

{
	echo "-cp $(towin "$SCRIPT_DIR")"

	echo "cpp.cppia.HostClasses"

	for cls in "${CLASSES[@]}"; do
		echo "$cls"
	done

	CLASS_LIST=""
	for cls in "${CLASSES[@]}"; do
		if [ -n "$CLASS_LIST" ]; then CLASS_LIST="$CLASS_LIST,"; fi
		CLASS_LIST="$CLASS_LIST'$cls'"
	done
	echo "--macro funkin.util.macro.CppiaManifestMacro.build([$CLASS_LIST])"

	echo "-D dll_import=$HOST_CLASSES"
	echo "--cppia $(towin "$OUTPUT")"
} >> "$GENERATED"

echo "Building $OUTPUT from $SCRIPT_DIR"
echo "  ${#CLASSES[@]} class(es): ${CLASSES[*]}"

(cd "$ROOT" && haxe "$GENERATED")

if [ ! -f "$OUTPUT" ]; then
	echo "haxe reported success but produced no $OUTPUT" >&2
	exit 1
fi

echo "Wrote $OUTPUT ($(wc -c < "$OUTPUT") bytes)"
