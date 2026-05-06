#!/usr/bin/env bash
set -euo pipefail

PARTS_DIR="./docs/parts"
OUTPUT="./docs/output/guida-completa.md"

mkdir -p ./docs/output

> "$OUTPUT"

find "$PARTS_DIR" -type f -name "*.md" | sort -V | while read -r file; do
    echo ">> Processing $(basename "$file")"
    cat "$file" >> "$OUTPUT"
    printf "\n\n---\n\n" >> "$OUTPUT"
done

echo "DONE -> $OUTPUT"