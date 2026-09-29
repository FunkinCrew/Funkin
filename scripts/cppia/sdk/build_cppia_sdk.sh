# Usage: ./build_cppia_sdk.sh [--target <platform>] [--config <debug|release>] <game-root> [output-dir]
# 	target defaults to windows
# 	config defaults to release
# 	output-dir defaults to <game-root>/sdk/<target>/<config>

# This creates the 'export_classes.info' file for CPPIA exports. Typically, you do not need to run this script. haha

set -euo pipefail

TARGET="windows"
CONFIG="release"
while [ "$#" -gt 0 ]; do
	if [ "$1" = "--target" ]; then
		TARGET="$2"; shift 2
	elif [ "$1" = "--config" ]; then
		CONFIG="$2"; shift 2
	else
		break
	fi
done

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 [--target <platform>] <game-root> [output-dir]" >&2
	exit 1
fi

ROOT="$1"
if [ ! -f "$ROOT/project.hxp" ]; then
	echo "$ROOT does not look like the game checkout, no project.hxp there." >&2
	exit 1
fi
ROOT="$(cd "$ROOT" && pwd)" || exit 1

OUT_DIR="${2:-$ROOT/sdk/$TARGET/$CONFIG}"

HOST_CLASSES="$ROOT/export_classes.info"
if [ ! -f "$HOST_CLASSES" ]; then
	echo "Missing $HOST_CLASSES." >&2
	echo "Build the game once with FEATURE_CPPIA enabled first, -D scriptable writes it." >&2
	exit 1
fi

mkdir -p "$OUT_DIR"

if command -v cygpath >/dev/null 2>&1; then
	ROOT_FWD="$(cygpath -m "$ROOT")"
else
	ROOT_FWD="$ROOT"
fi

(cd "$ROOT" && haxelib run lime display "$TARGET" "-$CONFIG") \
	| grep -v '^-main ' \
	| grep -v '^-cpp ' \
	| grep -v '^--no-output$' \
	| grep -v '^-D scriptable$' \
	| grep -v '^--macro keep(' \
	| tr '\\' '/' \
	| sed -e "s|$ROOT_FWD/||g" -e "s|$ROOT_FWD|.|g" \
	| grep -vE '^-D [A-Za-z0-9_.]+=([A-Za-z]:/|/)' \
	> "$OUT_DIR/cppia.hxml"

grep -v '^file ' "$HOST_CLASSES" > "$OUT_DIR/export_classes.info"
rm -f "$HOST_CLASSES"

echo "Wrote $TARGET $CONFIG cppia SDK to $OUT_DIR"
echo "  cppia.hxml	$(wc -l < "$OUT_DIR/cppia.hxml") lines"
echo "  export_classes.info	$(grep -cE '^(class|interface|enum) ' "$OUT_DIR/export_classes.info") classes"
