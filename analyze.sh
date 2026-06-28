#!/usr/bin/env bash
# Compiles the Rust program and dumps the .rodata / .data / .bss sections.
# Run this INSIDE the container (see README). Outputs land in ./out/.
set -euo pipefail

BIN=target_binary
OUT=out
mkdir -p "$OUT"

echo "==> Compiling (no optimization, no debug info)"
rustc -C opt-level=0 -C debuginfo=0 src/main.rs -o "$BIN"

echo "==> Section headers (readelf -S)"
readelf -S "./$BIN" > "$OUT/readelf-sections.txt"

echo "==> .rodata contents (constants, string literals)"
objdump -s -j .rodata "./$BIN" > "$OUT/objdump-rodata.txt"

echo "==> .data contents (initialized writable statics)"
objdump -s -j .data "./$BIN" > "$OUT/objdump-data.txt"

echo "==> .bss (zero-initialized -> size only, no bytes in file)"
# .bss has no contents in the file, so this may warn; that's expected.
objdump -h -j .bss "./$BIN" > "$OUT/objdump-bss.txt" 2>&1 || true

echo "==> Global symbols, demangled"
nm "./$BIN" | rustfilt > "$OUT/nm-demangled.txt"

echo "==> Is .bss present? size:"
readelf -S "./$BIN" | grep -i '\.bss' > "$OUT/bss-section.txt" || true

echo
echo "Done. Searching for the named markers across the dumps:"
echo "----------------------------------------------------------"
for marker in FIRST_CONST SECOND THIRD_DATA FOURTH_BSS FIFTH_DATA_ARRAY; do
    printf '%-18s -> ' "$marker"
    if grep -rl "$marker" "$OUT" >/dev/null 2>&1; then
        grep -rl "$marker" "$OUT" | sed 's#^#found in: #' | paste -sd', ' -
    else
        echo "not found as plain text (likely inlined / mangled)"
    fi
done

echo
echo "All output files are in ./$OUT/"
