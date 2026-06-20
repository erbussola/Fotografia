#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INPUT="$BASE_DIR/docs/output/guida-completa.md"
META="$BASE_DIR/docs/metadata.yaml"
OUT_DIR="$BASE_DIR/docs/output"

PDF="$OUT_DIR/guida-completa.pdf"
DOCX="$OUT_DIR/guida-completa.docx"

echo ">> Generazione PDF..."
pandoc "$INPUT" \
  --metadata-file="$META" \
  --pdf-engine=xelatex \
  -o "$PDF"

echo ">> Generazione DOCX..."
pandoc "$INPUT" \
  --metadata-file="$META" \
  -o "$DOCX"

echo "✔ Build completata"