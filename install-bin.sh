#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/bin"
for f in bin/*; do
    if ! test -x "${f}"; then continue; fi
    if command -v gln >/dev/null; then
        gln -sfr "${f}" ~/.local/bin
    elif ln -sfr /dev/null /dev/null 2>/dev/null; then
        ln -sfr "${f}" ~/.local/bin
    else
        ln -sf "$(cd "$(dirname "${f}")" && pwd)/$(basename "${f}")" ~/.local/bin
    fi
done