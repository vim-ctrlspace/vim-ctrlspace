#!/bin/sh
set -eu

# Usage: tests/run.sh [vim|nvim|all]
# VIM_BIN and NVIM_BIN may name alternate editor executables or wrappers.
test_repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_work=$(mktemp -d "${CTRLSPACE_TEST_TMPDIR:-${TMPDIR:-$test_repo/tests}}/.ctrlspace-tests.XXXXXX")
trap 'rm -rf "$test_work"' EXIT HUP INT TERM

case "${1:-all}" in
  vim) test_editors=vim ;;
  nvim) test_editors=nvim ;;
  all) test_editors='vim nvim' ;;
  *) printf 'Usage: %s [vim|nvim|all]\n' "$0" >&2; exit 2 ;;
esac

for test_editor in $test_editors; do
  case "$test_editor" in
    vim) test_binary=${VIM_BIN:-vim} ;;
    nvim) test_binary=${NVIM_BIN:-nvim} ;;
  esac
  if ! command -v "$test_binary" >/dev/null 2>&1; then
    printf 'Editor not found: %s (set VIM_BIN or NVIM_BIN)\n' "$test_binary" >&2
    exit 1
  fi

  for test_cache in 0 1; do
    test_case="$test_work/$test_editor-cache-$test_cache"
    mkdir -p "$test_case"
    if [ "$test_editor" = nvim ]; then
      set -- --headless -u NONE -i NONE -n
    else
      set -- -Nu NONE -i NONE -n -es
    fi
    if CTRLSPACE_TEST_TMP="$test_case" CTRLSPACE_TEST_CACHE="$test_cache" \
      "$test_binary" "$@" -S "$test_repo/tests/native_search.vim" >"$test_case/editor.log" 2>&1; then
      printf '%s (cache=%s): ' "$test_editor" "$test_cache"
      cat "$test_case/result.txt"
    else
      printf '%s (cache=%s) FAILED\n' "$test_editor" "$test_cache" >&2
      if [ -f "$test_case/result.txt" ]; then
        cat "$test_case/result.txt" >&2
      fi
      cat "$test_case/editor.log" >&2
      exit 1
    fi
  done
done
