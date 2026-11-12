#!/bin/bash
# Organizes astc-compression-data alphabetically because i hate it when it's not organized -zack

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_FILE="$SCRIPT_DIR/../../astc-compression-data.json"
OUTPUT_FILE="$SCRIPT_DIR/../../astc-compression-data.json"

# Check jq
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Install it with:"
    echo "  macOS: brew install jq"
    echo "  Linux (Debian/Ubuntu): sudo apt-get install jq"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: File $INPUT_FILE not found"
    exit 1
fi

jq '.
  | .custom = ( .custom | sort_by(.asset) )
  | .excludes = ( .excludes | sort )
' "$INPUT_FILE" > "$OUTPUT_FILE".tmp && mv "$OUTPUT_FILE".tmp "$OUTPUT_FILE"

echo "SUCCESS: Sorted JSON written to $OUTPUT_FILE WOOHOOO !!"
