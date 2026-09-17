#!/usr/bin/env bash
set -euo pipefail

# Submodule update may fail in read-only container mounts; don't block rsync
git submodule update --init --recursive || true
rsync -rlv --exclude='.git' --exclude='.config/goose' dotfiles/ ~

# Merge managed config into ~/.env_ai_assist (idempotent)
DOTFILE_BLOCK="dotfiles/.env_ai_assist.dotfile"
if [ -f "$DOTFILE_BLOCK" ]; then
    touch ~/.env_ai_assist
    # Strip any existing managed block, then append the current one
    SED="$(command -v gsed || command -v sed)"
    "$SED" -i '/^# --- managed-by-dotfiles ---$/,/^# --- end-managed ---$/d' ~/.env_ai_assist
    cat "$DOTFILE_BLOCK" >> ~/.env_ai_assist
fi

# Sync ~/.config/goose from dotfiles (copy, not symlink — goose writes state here at runtime)
GOOSE_SRC="$(cd "$(dirname "$0")" && pwd)/dotfiles/.config/goose"
GOOSE_LINK="${HOME}/.config/goose"
# If currently a symlink, replace with a real directory
if [[ -L "${GOOSE_LINK}" ]]; then
    echo "~/.config/goose is a symlink — converting to real directory"
    cp -rL "${GOOSE_LINK}" "${GOOSE_LINK}.tmp"
    rm "${GOOSE_LINK}"
    mv "${GOOSE_LINK}.tmp" "${GOOSE_LINK}"
fi
mkdir -p "${GOOSE_LINK}"
rsync -rlv "${GOOSE_SRC}/config.yaml" "${GOOSE_LINK}/config.yaml"
rsync -rlv "${GOOSE_SRC}/permissions.yaml" "${GOOSE_LINK}/permissions.yaml"
rsync -rlv "${GOOSE_SRC}/recipes/" "${GOOSE_LINK}/recipes/"
# Strip com.apple.provenance so goose can write freely
find "${GOOSE_LINK}" \( -type f -o -type d \) | while read -r f; do
    xattr -d com.apple.provenance "$f" 2>/dev/null || true
done
echo "Synced ${GOOSE_SRC} → ${GOOSE_LINK}"

# Sync custom oh-my-zsh plugins into place
rsync -rlv --exclude='.git' --exclude='README.md' omz-custom-plugins/ ~/.oh-my-zsh/custom/plugins/