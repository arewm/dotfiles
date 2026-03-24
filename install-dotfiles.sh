#!/usr/bin/env bash
set -euo pipefail

# Submodule update may fail in read-only container mounts; don't block rsync
git submodule update --init --recursive || true
rsync -rlv --exclude='.git' dotfiles/ ~

# Sync custom oh-my-zsh plugins into place
rsync -rlv --exclude='.git' --exclude='README.md' omz-custom-plugins/ ~/.oh-my-zsh/custom/plugins/