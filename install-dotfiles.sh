#!/usr/bin/env bash
set -euo pipefail

# Submodule update may fail in read-only container mounts; don't block rsync
git submodule update --init --recursive || true
rsync -rlv --exclude='.git' dotfiles/ ~

# Merge managed config into ~/.env_ai_assist (idempotent)
DOTFILE_BLOCK="dotfiles/.env_ai_assist.dotfile"
if [ -f "$DOTFILE_BLOCK" ]; then
    touch ~/.env_ai_assist
    # Strip any existing managed block, then append the current one
    SED="$(command -v gsed || command -v sed)"
    "$SED" -i '/^# --- managed-by-dotfiles ---$/,/^# --- end-managed ---$/d' ~/.env_ai_assist
    cat "$DOTFILE_BLOCK" >> ~/.env_ai_assist
fi

# Sync custom oh-my-zsh plugins into place
rsync -rlv --exclude='.git' --exclude='README.md' omz-custom-plugins/ ~/.oh-my-zsh/custom/plugins/