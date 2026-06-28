# Linux environment so readelf/objdump/nm work on a real ELF binary,
# even though the host is macOS (Mach-O).
FROM rust:latest

# binutils -> readelf, objdump, nm
# rustfilt  -> demangle Rust symbol names (nicer than nm -C alone)
RUN apt-get update \
    && apt-get install -y --no-install-recommends binutils \
    && rm -rf /var/lib/apt/lists/* \
    && cargo install rustfilt

WORKDIR /work

# The actual source is bind-mounted at run time (see README),
# so we don't COPY it in. Default to an interactive shell.
CMD ["bash"]
