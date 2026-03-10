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

# configurations for local assistants
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_VERTEX_PROJECT_ID=itpc-gcp-pnd-pe-eng-claude

# source additional environment files outside of source control
source ~/.env_ai_assist
source ~/.env_personal

# Always get a new kubeconfig
$(kubectl-new-env)