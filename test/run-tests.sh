#!/usr/bin/env bash

# Use privileged mode, to e.g. ignore $CDPATH.
set -p

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit

versions=''

for vimtest in ${versions} ; do
    : "${VADER_OUTPUT_FILE:=${vimtest}_test.log}"
    eval "${vimtest} -Nu test/testing.vimrc \
        -c 'Vader! test/ctrlspace.vader'"
done
