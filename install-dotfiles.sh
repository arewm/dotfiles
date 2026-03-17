#!/usr/bin/env bash
set -euo pipefail

# Submodule update may fail in read-only container mounts; don't block rsync
git submodule update --init --recursive || true
rsync -rlv dotfiles/ ~