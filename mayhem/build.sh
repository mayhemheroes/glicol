#!/usr/bin/env bash
#
# glicol/mayhem/build.sh — build chaosprint/glicol's cargo-fuzz target as a sanitized
# libFuzzer binary (OSS-Fuzz Rust path: cargo-fuzz + ASan via RUSTFLAGS).
#
# glicol is a graph-oriented live-coding audio language in Rust; the fuzzed crate is
# glicol_parser (rs/parser — a pest grammar + AST builder).
#
# Sanitizer note: ASan is enabled the Rust way, through RUSTFLAGS `-Zsanitizer=address`
# (NOT clang's $SANITIZER_FLAGS / CFLAGS — those don't apply to rustc), which is what
# OSS-Fuzz's `compile` sets for FUZZING_LANGUAGE=rust.
#
# Targets (mayhem/fuzz/fuzz_targets/*.rs — ported from the old fork's rs/parser/fuzz crate):
#   parse_ast — UTF-8-decodes the input and runs glicol_parser::get_ast() over it
#               (full pest parse + AST construction).
set -euo pipefail

# clang rejects SOURCE_DATE_EPOCH='' — must be unset or a valid integer.
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${MAYHEM_JOBS:=$(nproc)}"
export MAYHEM_JOBS
# cargo-fuzz has no --jobs flag; cargo reads parallelism from CARGO_BUILD_JOBS.
export CARGO_BUILD_JOBS="$MAYHEM_JOBS"

# DWARF < 4 debug-info contract (§6.2 item 10). Force DWARF 2 so Mayhem triage / gdb
# can resolve project source lines. The rlenv runtime may export RUST_DEBUG_FLAGS before
# re-running build.sh offline; the default only applies when unset or empty.
: "${RUST_DEBUG_FLAGS:=-C debuginfo=2 -C force-frame-pointers=yes -C llvm-args=--dwarf-version=2}"

cd "$SRC"

# ── DWARF < 4 enforcement ──────────────────────────────────────────────────────
# Rust's ASan runtime (librustc-nightly_rt.asan.a) is built with the nightly's bundled
# LLVM (DWARF 5) and is linked before project code; strip its debug sections so it
# contributes no DWARF-5 CUs to the final binary.
ASAN_RT="$(find "$RUSTUP_HOME/toolchains" -name "librustc-nightly_rt.asan.a" 2>/dev/null | head -1)"
if [ -n "$ASAN_RT" ] && [ -f "$ASAN_RT" ]; then
    echo "Stripping debug info from Rust ASan runtime to enforce DWARF < 4: $ASAN_RT"
    objcopy --strip-debug "$ASAN_RT"
fi

# libfuzzer-sys compiles libFuzzer from C++ via the cc crate; force DWARF 3 there too.
export CFLAGS="${CFLAGS:+$CFLAGS }-gdwarf-3"
export CXXFLAGS="${CXXFLAGS:+$CXXFLAGS }-gdwarf-3"

# The cargo-fuzz crate is ADDITIVE under mayhem/fuzz/ (ported from the old fork's
# rs/parser/fuzz — upstream ships no fuzz crate; this keeps the overlay purely additive).
FUZZ_DIR="mayhem/fuzz"
FUZZ_TARGETS=(parse_ast)
TRIPLE="x86_64-unknown-linux-gnu"

# OSS-Fuzz Rust libFuzzer+ASan flags. cargo-fuzz sets the ASan flag itself, but pin it
# explicitly. --cfg fuzzing matches libfuzzer-sys; RUST_DEBUG_FLAGS keeps DWARF ≤ 2.
export RUSTFLAGS="${RUSTFLAGS:-} --cfg fuzzing -Zsanitizer=address ${RUST_DEBUG_FLAGS}"

echo "=== cargo fuzz build (image-default nightly toolchain, ASan via RUSTFLAGS) ==="
echo "RUSTFLAGS=$RUSTFLAGS"

# `-O` + `--debug-assertions` mirrors OSS-Fuzz. Use the image's DEFAULT toolchain (the
# Dockerfile pins the nightly); a `+toolchain` override would try to install another channel.
for t in "${FUZZ_TARGETS[@]}"; do
  echo "--- building fuzz target: $t ---"
  # cargo-fuzz must run from inside the HOST cargo project (it walks up from cwd and
  # skips the fuzz crate itself); the repo root has no Cargo.toml, so run from the
  # fuzzed crate rs/parser and point --fuzz-dir back at the additive mayhem/fuzz crate.
  ( cd "$SRC/rs/parser" && cargo fuzz build --fuzz-dir "$SRC/$FUZZ_DIR" -O --debug-assertions "$t" )
done

# Resolve the cargo target dir robustly via cargo metadata.
TARGET_DIR="$(cargo metadata --no-deps --format-version 1 --manifest-path "$FUZZ_DIR/Cargo.toml" \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["target_directory"])')"
echo "fuzz target_directory: $TARGET_DIR"

REL="$TARGET_DIR/$TRIPLE/release"
for t in "${FUZZ_TARGETS[@]}"; do
  bin="$REL/$t"
  if [ ! -x "$bin" ]; then
    echo "ERROR: expected fuzz binary not found at $bin" >&2
    ls -la "$REL" >&2 || true
    exit 1
  fi
  cp "$bin" "/mayhem/$t"
  echo "built /mayhem/$t"
done

# Build the project's TEST suite too — with the workspace's NORMAL flags (no sanitizer
# RUSTFLAGS, default target dir under rs/target) — so mayhem/test.sh only RUNS it.
# The workspace root is rs/ (members: main, parser, synth, wasm).
# NOT built (broken upstream at tip, cannot be fixed additively):
#   - glicol-wasm: enables the wasm-bindgen feature chain, which makes rhai emit
#     compile_error! on a non-WASM host target (and it has no tests anyway);
#   - rs/parser/tests/all_nodes.rs: does not compile against the current
#     glicol_parser API (expects NumberOrRef where the API now uses UsizeOrRef).
echo "=== cargo test --no-run (normal flags, pre-building the test suite) ==="
( cd "$SRC/rs" && RUSTFLAGS="" cargo test --no-run -p glicol_parser --test sin --jobs "$MAYHEM_JOBS" )
( cd "$SRC/rs" && RUSTFLAGS="" cargo test --no-run -p glicol --lib --tests --jobs "$MAYHEM_JOBS" )

echo "build.sh complete:"
ls -la /mayhem/parse_ast 2>&1 || true
