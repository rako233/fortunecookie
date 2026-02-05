#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="src"
OUT_DIR="out"
WIDTH=50

mkdir -p "$OUT_DIR"

find "$SRC_DIR" -maxdepth 1 -type f ! -name '*.msg' -print0 |
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  outname="${filename%.*}"
  outfile="$OUT_DIR/$outname"
  msgfile="$SRC_DIR/$outname.msg"

  msg=""
  if [[ -f "$msgfile" ]]; then
    msg="$(tr '\n' ' ' < "$msgfile" \
          | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
  fi

  : > "$outfile"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    # trim leading/trailing whitespace, then remove enclosing quotes
    line="$(printf '%s\n' "$line" \
           | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"(.*)"$/\1/')"

    # wrap at word boundaries to WIDTH characters
    printf '%s\n' "$line" | fold -s -w "$WIDTH" >> "$outfile"

    # append msg block only if msg is non-empty
    if [[ -n "$msg" ]]; then
      printf '\n\n   --- %s\n' "$msg" >> "$outfile"
    fi

    # insert comment line
    printf '%%\n' >> "$outfile"
  done < "$file"
  strfile -c % "$outfile" "$outfile.dat"
done

