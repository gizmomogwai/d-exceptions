#!/usr/bin/env bash
set -x
set -e
touch testfiles/not_readable.txt
chmod ugo-r testfiles/not_readable.txt

