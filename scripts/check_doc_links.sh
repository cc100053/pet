#!/usr/bin/env bash
# Checks relative markdown links and backticked repo paths in Markdown files.
# Usage: scripts/check_doc_links.sh [file.md ...]   (default: all tracked *.md)
# A path resolves if it exists relative to the file's folder or the repo root.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ "$#" -gt 0 ]; then files=("$@"); else
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(
    git ls-files '*.md' | grep -v -e '/archive/' -e '^ios/Pods/' -e '^build/')
fi

broken=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  dir=$(dirname "$f")
  {
    # [text](target) — drop anchors, URLs, mailto.
    grep -o '\]([^)]*)' "$f" | sed -e 's/^](//' -e 's/)$//' -e 's/#.*//' -e 's/ .*//' \
      | grep -v -e '^[a-z]*:' -e '^$' || true
    # `path/with/slash.ext` — only slash-bearing paths, so bare names like
    # `main.dart` (prose mentions) are not treated as repo paths.
    grep -o '`[A-Za-z0-9._/-]*/[A-Za-z0-9._-]*\.\(md\|sh\|dart\|py\|json\|yml\|yaml\|sql\|ts\|mjs\)`' "$f" \
      | tr -d '`' || true
  } | sort -u | while IFS= read -r p; do
    # Skip globs and placeholders.
    case "$p" in *'*'*|*'<'*|*'{'*) continue ;; esac
    if [ ! -e "$dir/$p" ] && [ ! -e "$p" ] && [ ! -e "${p#/}" ]; then
      echo "BROKEN $f -> $p"
    fi
  done
done | tee /dev/stderr | grep -q BROKEN && broken=1

exit "$broken"
