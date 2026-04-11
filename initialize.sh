#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up dotfiles environment..."

# Clone amix/vimrc if not present
if [ ! -d "$HOME/.vim_runtime" ]; then
  echo "==> Cloning amix/vimrc to ~/.vim_runtime..."
  git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
else
  echo "==> amix/vimrc already exists at ~/.vim_runtime"
fi

# Install homebrew packages if brew is available
if command -v brew &> /dev/null; then
  echo "==> Installing homebrew formulae..."
  brew install \
    bash \
    coreutils \
    cosign \
    crane \
    exiftool \
    findutils \
    gawk \
    gemini-cli \
    gh \
    git \
    glab \
    glow \
    gnu-sed \
    golangci-lint \
    helm \
    imagemagick \
    jira-cli \
    jq \
    just \
    k3d \
    kind \
    ko \
    krew \
    kubectx \
    kustomize \
    make \
    opa \
    operator-sdk \
    oras \
    pinentry-mac \
    pipx \
    podman-compose \
    pyenv \
    qemu \
    rust \
    skopeo \
    slp/krunkit/krunkit \
    tektoncd-cli \
    terminal-notifier \
    tree \
    uv \
    vim \
    wget \
    yarn \
    yq

  echo "==> Installing homebrew casks..."
  brew install --cask \
    claude-code \
    obsidian \
    podman-desktop \
    spotify
else
  echo "==> Homebrew not found, skipping package installation"
fi

echo "==> Initialization complete!"
