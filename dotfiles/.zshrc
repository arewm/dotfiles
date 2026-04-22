# Configurations for oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="gentoo"
plugins=(git macos zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

export EDITOR='vim'

# Set the default authfile for podman
export REGISTRY_AUTH_FILE=~/.docker/config.json

# Ensure that gpg is configured properly
export GPG_TTY=$(tty)

# Configure homebrew
export HOMEBREW_NO_ANALYTICS=1
eval "$(/opt/homebrew/bin/brew shellenv)"

# override some packages to use homebrew-resolved ones
alias sed='gsed'
alias make='gmake'

# path updates
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# git sclone: structured cloning into ~/workspace/src/<host>/<org>/<repo>
export GIT_SCLONE_BASE="$HOME/workspace/src"
clone() {
    local dir
    dir=$(git sclone "$@") && cd "$dir"
}

# devaipod control plane
devaipod-start() {
  local image="${1:-ghcr.io/cgwalters/devaipod:latest}"
  echo "Pulling ${image}..."
  podman pull "${image}" || { echo "Failed to pull image"; return 1; }

  # Prune abandoned devaipod volumes (dangling volumes with devaipod- prefix)
  local stale
  stale=$(podman volume ls --filter dangling=true --format '{{.Name}}' | grep '^devaipod-' || true)
  if [[ -n "$stale" ]]; then
    echo "Removing $(echo "$stale" | wc -l | tr -d ' ') abandoned devaipod volume(s)..."
    echo "$stale" | xargs podman volume rm --force
  fi

  echo "Starting devaipod..."
  podman run -d --name devaipod --privileged --replace \
    -p 8080:8080 \
    -v devaipod-state:/var/lib/devaipod \
    -v /run/podman/podman.sock:/run/docker.sock \
    -e DEVAIPOD_HOST_SOCKET=/run/podman/podman.sock \
    --secret gemini_api_key,type=env,target=GOOGLE_GENERATIVE_AI_API_KEY \
    -v ~/.config/devaipod.toml:/root/.config/devaipod.toml:ro \
    -v ~/.ssh/config.d/devaipod:/run/devaipod-ssh:Z \
    "${image}"
  echo "devaipod started: http://127.0.0.1:8080/"
}

# source additional environment files outside of source control
source ~/.env_ai_assist
source ~/.env_personal

# Always get a new kubeconfig
$(kubectl-new-env)
