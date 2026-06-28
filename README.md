# rust-statics-analysis

Inspect where Rust constants and statics live in a compiled binary
(`.rodata`, `.data`, `.bss`) — from **macOS**, using a Linux container.

## Why a container?

Those sections and the tools that read them (`readelf`, `objdump`, `nm`)
belong to the **ELF** binary format used on Linux. macOS binaries use
**Mach-O** instead, with different section names and a different toolchain.
The simplest way to follow the ELF-based tutorial on a Mac is to compile
and inspect inside a small Linux container. Docker Desktop runs that
container in a lightweight Linux VM for you automatically.

## What's in here

```
.
├── Dockerfile        # Linux + Rust + binutils + rustfilt
├── analyze.sh        # compiles and dumps every section to ./out/
├── src/
│   └── main.rs       # program with uniquely-named consts/statics
└── README.md
```

The statics in `main.rs` are named so you can grep for them:

| Name               | Expected section | Kind                          |
| ------------------ | ---------------- | ----------------------------- |
| `FIRST_CONST`      | `.rodata`        | string literal                |
| `SECOND`           | `.rodata`        | integer const (often inlined) |
| `THIRD_DATA`       | `.data`          | non-zero mutable static       |
| `FOURTH_BSS`       | `.bss`           | zero-initialized static       |
| `FIFTH_DATA_ARRAY` | `.data`          | non-zero static array         |

## Prerequisites (one time)

Install Docker Desktop for Mac:

```bash
brew install --cask docker
```

Then launch Docker Desktop once (from Applications) so the background
Linux VM starts. Check it's ready:

```bash
docker --version
```

> On Apple Silicon (M-series) the image runs as ARM64 by default, which is
> fine. To match a classic x86-64 Linux box exactly, add
> `--platform linux/amd64` to the build/run commands (slower, emulated).

## Usage

From the project root:

```bash
# 1. Build the image
docker build -t rust-statics .

# 2. Run it, mounting this folder into the container
docker run -it --rm -v "$(pwd)":/work rust-statics

# 3. Inside the container, run the analysis
./analyze.sh
```

The script writes all dumps to `./out/` (visible on your Mac too, thanks
to the bind mount) and prints which file each marker was found in.

### Poke around manually

Inside the container you can also run individual commands:

```bash
rustc -C opt-level=0 -C debuginfo=0 src/main.rs -o target_binary

readelf -S ./target_binary                      # list sections
objdump -s -j .rodata ./target_binary           # read-only data
objdump -s -j .data   ./target_binary           # initialized data
objdump -h -j .bss    ./target_binary           # .bss = size only
nm ./target_binary | rustfilt                    # demangled symbols

grep FIRST_CONST out/objdump-rodata.txt          # find a marker
```

## Notes

- `.bss` holds zero-initialized data, so it occupies **no bytes in the
  file** — only a size is recorded. `objdump -s -j .bss` therefore shows
  nothing useful; use `objdump -h` / `readelf -S` to see its size.
- Integer consts like `SECOND` are frequently inlined at use sites, so you
  may not find them as a standalone entry. That's expected.
- `opt-level=0` and `debuginfo=0` keep symbols present and the binary
  minimal, making the sections easier to read.
