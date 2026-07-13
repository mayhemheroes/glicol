#!/usr/bin/env bash
#
# glicol/mayhem/test.sh — RUN chaosprint/glicol's own Rust test suite (`cargo test`
# from the rs/ workspace root) and emit a CTRF summary. exit 0 iff no
# test failed.
#
# PATCH-grade oracle: glicol ships a real assertion suite —
#   - rs/parser/tests/sin.rs: asserts the exact AST structure (chain names, node
#     params) produced for concrete glicol programs;
#   - rs/main/tests/sin.rs + rs/main/src/lib.rs unit tests: build a full audio Engine,
#     update it with glicol code and assert the results (Ok/expected errors).
# These assert concrete values, so a no-op / exit(0) patch cannot pass.
# This script only RUNS the suite; build.sh pre-compiled it with `cargo test --no-run`.
#
# Upstream test inventory: 19 #[test] functions (rs/parser: 16, rs/main: 3).
# SKIPPED (broken upstream at tip, cannot be fixed additively):
#   - rs/parser/tests/all_nodes.rs (14 tests): does not compile against the current
#     glicol_parser API (expects NumberOrRef where the API now uses UsizeOrRef);
#   - glicol-wasm: no tests, and its wasm-bindgen feature chain makes rhai emit
#     compile_error! on a non-WASM host target.
# The js/ directory (npm web UI) ships no test suite (no test script in package.json).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not available — cannot run the test suite" >&2
  emit_ctrf "cargo-test" 0 1 0; exit 2
fi

echo "=== running cargo test (glicol unit + integration suite) ==="
# Workspace root is rs/. Use the image's DEFAULT toolchain (the Dockerfile pins the same
# nightly the fuzz build uses). --no-fail-fast so we count every test; RUSTFLAGS cleared
# so it inherits nothing from the sanitizer build (cache hit on build.sh's --no-run build).
out="$(cd "$SRC/rs" && RUSTFLAGS="" cargo test -p glicol_parser --test sin --no-fail-fast --jobs "$MAYHEM_JOBS" 2>&1; RUSTFLAGS="" cargo test -p glicol --lib --tests --no-fail-fast --jobs "$MAYHEM_JOBS" 2>&1)"; rc=$?
echo "$out"

# libtest prints one line per test binary:
#   test result: ok. 14 passed; 0 failed; 0 ignored; ...
PASSED=0; FAILED=0; IGNORED=0
while read -r p f i; do
  PASSED=$(( PASSED + p )); FAILED=$(( FAILED + f )); IGNORED=$(( IGNORED + i ))
done < <(printf '%s\n' "$out" \
  | sed -n 's/^test result:.* \([0-9][0-9]*\) passed; \([0-9][0-9]*\) failed; \([0-9][0-9]*\) ignored.*/\1 \2 \3/p')

if [ "$(( PASSED + FAILED + IGNORED ))" -eq 0 ]; then
  echo "could not parse any 'test result:' lines; using cargo exit code $rc" >&2
  emit_ctrf "cargo-test" 0 1 0; exit 1
fi

emit_ctrf "cargo-test" "$PASSED" "$FAILED" "$IGNORED"
