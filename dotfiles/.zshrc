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

# ─── goose / nono helpers ────────────────────────────────────────────────────
#
# _rhtgoose_env <cmd> [args]
#   Injects RHT Personal GCP Vertex AI credentials into the environment before running <cmd>.
#
# _lwgoose_env <cmd> [args]
#   Injects Lightwell (lightwell-devel) GCP Vertex AI credentials into the environment before running <cmd>.
#
# _goose_run [--profile <P>] [--workdir <W>] [--allow-cwd] -- <cmd> [args]
#   Runs <cmd> bare, or wrapped in nono when --profile is given.
#   --workdir and --allow-cwd are forwarded to nono; ignored when bare.
#
# Public commands (Personal / RHT):
#   rhtgoose              sandboxed session  (nono: goose)
#   rhtgoose-bare         unsandboxed session
#   rhtgoose-flash        sandboxed session  (gemini-2.5-flash-lite)
#   rhtgoose-flash-bare   unsandboxed session (gemini-2.5-flash-lite)
#   rhtagoose             sandboxed session  (claude-sonnet-5)
#   rhtagoose-bare        unsandboxed session (claude-sonnet-5)
#   rhogoose              sandboxed session  (openai: gpt-5.6-luna / planner: gpt-5.6-terra)
#   rhogoose-bare         unsandboxed session (openai: gpt-5.6-luna / planner: gpt-5.6-terra)
#   rhtgoose-local        sandboxed KinD session  (nono: goose-local)
#   rhtgoose-local-bare   unsandboxed KinD session
#
# Public commands (Lightwell):
#   lwgoose               sandboxed session  (nono: goose, lightwell-devel)
#   lwgoose-bare          unsandboxed session (lightwell-devel)
#   lwgoose-flash         sandboxed session  (gemini-2.5-flash-lite, lightwell-devel)
#   lwgoose-flash-bare    unsandboxed session (gemini-2.5-flash-lite, lightwell-devel)
#   lwagoose              sandboxed session  (claude-sonnet-5, lightwell-devel)
#   lwagoose-bare         unsandboxed session (claude-sonnet-5, lightwell-devel)
#   lwgoose-local         sandboxed KinD session  (nono: goose-local, lightwell-devel)
#   lwgoose-local-bare    unsandboxed KinD session (lightwell-devel)
#
# Recipe runners:
#   goose-recipe          sandboxed recipe runner  (nono: goose-sandbox, workdir=cwd)
#   goose-recipe-local    sandboxed recipe runner  (nono: goose-sandbox-local, workdir=cwd)
#   goose-recipe-bare     unsandboxed recipe runner
#   lwgoose-recipe        sandboxed recipe runner  (lightwell-devel)
#   lwgoose-recipe-local  sandboxed recipe runner  (nono: goose-sandbox-local, lightwell-devel)
#   lwgoose-recipe-bare   unsandboxed recipe runner (lightwell-devel)
#   grrc                  dual-model review shorthand  (nono: goose-sandbox)
#   grrc-local            dual-model review shorthand  (nono: goose-sandbox-local)
#   grrc-bare             dual-model review shorthand, unsandboxed

_rhtgoose_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="gemini-3.8-flash" \
  GOOSE_MAX_TOKENS="65536" \
  GOOSE_THINKING_EFFORT="low" \
  GOOSE_CONTEXT_LIMIT="1000000" \
  GOOSE_PLANNER_CONTEXT_LIMIT="1000000" \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_PERSONAL:-${GCP_PROJECT_ID}}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

_lwgoose_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="gemini-3.8-flash" \
  GOOSE_CONTEXT_LIMIT="1000000" \
  GOOSE_PLANNER_CONTEXT_LIMIT="1000000" \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_LW:-lightwell-devel}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

# Like _rhtgoose_env but uses gemini-2.5-flash-lite with GOOSE_MAX_TOKENS=65535
# workaround for https://github.com/aaif-goose/goose/issues/11364
_rhtgoose_flash_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="gemini-2.5-flash-lite" \
  GOOSE_MAX_TOKENS=65535 \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_PERSONAL:-${GCP_PROJECT_ID}}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

_lwgoose_flash_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="gemini-3.8-flash" \
  GOOSE_CONTEXT_LIMIT="1000000" \
  GOOSE_PLANNER_CONTEXT_LIMIT="1000000" \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_LW:-lightwell-devel}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

# Like _rhtgoose_env but uses sonnet
_rhtgoose_anthropic_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="claude-sonnet-5" \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_PERSONAL:-${GCP_PROJECT_ID}}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

# OpenAI helper env:
_rhtgoose_openai_env() {
  GOOSE_PROVIDER="openai" \
  GOOSE_MODEL="gpt-5.6-terra" \
  GOOSE_PLANNER_PROVIDER="openai" \
  GOOSE_PLANNER_MODEL="gpt-5.6-terra" \
  GIT_TERMINAL_PROMPT=0 \
  "$@"
}

_rhtgoose_openai_luna_env() {
  GOOSE_PROVIDER="openai" \
  GOOSE_MODEL="gpt-5.6-luna" \
  GOOSE_PLANNER_PROVIDER="openai" \
  GOOSE_PLANNER_MODEL="gpt-5.6-luna" \
  GIT_TERMINAL_PROMPT=0 \
  "$@"
}

_lwgoose_anthropic_env() {
  GOOSE_PROVIDER="gcp_vertex_ai" \
  GOOSE_MODEL="claude-sonnet-5" \
  GIT_TERMINAL_PROMPT=0 \
  GCP_PROJECT_ID="${GCP_PROJECT_ID_LW:-lightwell-devel}" \
  GCP_LOCATION="${CLOUD_ML_REGION:-global}" \
  "$@"
}

# _goose_run [--profile P] [--workdir W] [--allow-cwd] -- cmd [args...]
_goose_run() {
  local profile="" workdir="" allow_cwd=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)   profile="$2";  shift 2 ;;
      --workdir)   workdir="$2";  shift 2 ;;
      --allow-cwd) allow_cwd=1;   shift   ;;
      --)          shift; break   ;;
      *)           break          ;;
    esac
  done
  if [[ -n "$profile" ]]; then
    local nono_args=(nono run --profile "$profile")
    [[ -n "$workdir"  ]] && nono_args+=(--workdir "$workdir")
    [[ "$allow_cwd" == 1 ]] && nono_args+=(--allow-cwd)
    nono_args+=(-- "$@")
    GIT_SSH_COMMAND="/usr/bin/ssh -F ${HOME}/.ssh/config.d/nono" "${nono_args[@]}"
  else
    "$@"
  fi
}

# ── interactive sessions (Personal / RHT) ────────────────────────────────────

rhtgoose() {
  _rhtgoose_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

rhtgoose-bare() {
  _rhtgoose_env _goose_run -- goose "$@"
}

# flash-lite variant
rhtgoose-flash() {
  _rhtgoose_flash_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

rhtgoose-flash-bare() {
  _rhtgoose_flash_env _goose_run -- goose "$@"
}

rhtagoose() {
  _rhtgoose_anthropic_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

rhtagoose-bare() {
  _rhtgoose_anthropic_env _goose_run -- goose "$@"
}

rhogoose() {
  _rhtgoose_openai_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

rhogoose-bare() {
  _rhtgoose_openai_env _goose_run -- goose "$@"
}

rholgoose() {
  _rhtgoose_openai_luna_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

rholgoose-bare() {
  _rhtgoose_openai_luna_env _goose_run -- goose "$@"
}

rhtgoose-local() {
  _rhtgoose_env _goose_run --profile goose-local --allow-cwd -- goose "$@"
}

rhtgoose-local-bare() {
  _rhtgoose_env _goose_run -- goose "$@"
}

# ── interactive sessions (Lightwell) ─────────────────────────────────────────

lwgoose() {
  _lwgoose_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

lwgoose-bare() {
  _lwgoose_env _goose_run -- goose "$@"
}

lwgoose-flash() {
  _lwgoose_flash_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

lwgoose-flash-bare() {
  _lwgoose_flash_env _goose_run -- goose "$@"
}

lwagoose() {
  _lwgoose_anthropic_env _goose_run --profile goose --allow-cwd -- goose "$@"
}

lwagoose-bare() {
  _lwgoose_anthropic_env _goose_run -- goose "$@"
}

lwgoose-local() {
  _lwgoose_env _goose_run --profile goose-local --allow-cwd -- goose "$@"
}

lwgoose-local-bare() {
  _lwgoose_env _goose_run -- goose "$@"
}

# ── recipe runner ─────────────────────────────────────────────────────────────
# goose-recipe       [-r <name> | -p <path>] [project_path] [--param k=v ...]
# goose-recipe-local [-r <name> | -p <path>] [project_path] [--param k=v ...]
# goose-recipe-bare  [-r <name> | -p <path>] [project_path] [--param k=v ...]
#
# Resolves the recipe then runs it sandboxed, scoped to project_path (default: cwd).
#   goose-recipe       — nono: goose-sandbox        (no cluster access)
#   goose-recipe-local — nono: goose-sandbox-local  (KinD unrestricted)
#   goose-recipe-bare  — unsandboxed
#
# All variants log to project_path/.goose-recipe-<timestamp>.log and acquire a
# lock at project_path/.goose-lock/ to prevent concurrent runs on the same dir.
#
# Examples:
#   goose-recipe -r design-review --param design_path="$(pwd)/docs/design.md"
#   goose-recipe -p /path/to/recipe.yaml ~/workspace/myproject --param foo=bar
#   goose-recipe-local -r kind-setup --param cluster=dev ~/workspace/myproject
#
# grrc '<task>' [project_path]         — shorthand for dual-model-review recipe
# grrc-local '<task>' [project_path]   — same with KinD access
# grrc-bare  '<task>' [project_path]   — unsandboxed

_goose_recipe_run() {
  local profile="$1"; shift   # "goose-sandbox", "goose-sandbox-local", or ""
  local recipe_path=""
  local project_path=""
  local -a goose_params=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r)
        [[ "$2" =~ [./] ]] && { echo "ERROR: Recipe name must not contain '.' or '/'" >&2; return 1; }
        recipe_path="${HOME}/.config/goose/recipes/${2}/recipe.yaml"
        shift 2 ;;
      -p) recipe_path="$2"; shift 2 ;;
      --param|--params) goose_params+=(--params "$2"); shift 2 ;;
      -*) break ;;
      *) project_path="$(cd "$1" && pwd)"; shift ;;
    esac
  done

  [[ -z "$recipe_path" ]] && { echo "Usage: goose-recipe [-r <name>|-p <path>] [project_path] [--param k=v ...]" >&2; return 1; }
  [[ ! -f "$recipe_path" ]] && { echo "ERROR: Recipe not found: ${recipe_path}" >&2; return 1; }
  [[ -z "$project_path" ]] && project_path="$(pwd)"

  local lock_dir="${project_path}/.goose-lock"
  local log_file="${project_path}/.goose-recipe-$(date '+%Y%m%d-%H%M%S').log"

  if ! mkdir "${lock_dir}" 2>/dev/null; then
    echo "ERROR: A goose recipe is already running for ${project_path}" >&2
    echo "       If stale, remove: ${lock_dir}" >&2
    return 1
  fi

  { echo "=== Goose Recipe Run ==="
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Recipe:  ${recipe_path}"
    echo "Project: ${project_path}"
    echo "Profile: ${profile:-none (bare)}"
    echo "===" } > "${log_file}"
  echo "Logging to: ${log_file}"

  (
    trap "rm -rf '${lock_dir}'" EXIT
    local run_args=()
    [[ -n "$profile" ]] && run_args+=(--profile "$profile" --workdir "$project_path")
    "${env_wrapper:-_rhtgoose_env}" _goose_run "${run_args[@]}" \
      -- goose run --recipe "$recipe_path" "${goose_params[@]}" 2>&1 | tee -a "${log_file}"
  )
}

goose-recipe() {
  _goose_recipe_run "goose-sandbox" "$@"
}

goose-recipe-local() {
  _goose_recipe_run "goose-sandbox-local" "$@"
}

goose-recipe-bare() {
  _goose_recipe_run "" "$@"
}

lwgoose-recipe() {
  env_wrapper="_lwgoose_env" _goose_recipe_run "goose-sandbox" "$@"
}

lwgoose-recipe-local() {
  env_wrapper="_lwgoose_env" _goose_recipe_run "goose-sandbox-local" "$@"
}

lwgoose-recipe-bare() {
  env_wrapper="_lwgoose_env" _goose_recipe_run "" "$@"
}

# ── grrc: shorthand for dual-model-review recipe ──────────────────────────────
# grrc          '<task>' [project_path]  — sandboxed (nono: goose-sandbox, RHT personal)
# grrc-local    '<task>' [project_path]  — sandboxed (nono: goose-sandbox-local, RHT personal)
# grrc-bare     '<task>' [project_path]  — unsandboxed (RHT personal)
# lwgrrc        '<task>' [project_path]  — sandboxed (nono: goose-sandbox, Lightwell)
# lwgrrc-local  '<task>' [project_path]  — sandboxed (nono: goose-sandbox-local, Lightwell)
# lwgrrc-bare   '<task>' [project_path]  — unsandboxed (Lightwell)

_grrc_run() {
  local profile="$1"; shift
  local env_wrap="${1:-_rhtgoose_env}"; shift
  local task_description="${1:?Usage: grrc '<task_description>' [project_path]}"
  local project_path="${2:-.}"
  env_wrapper="$env_wrap" _goose_recipe_run "$profile" \
    -r dual-model-review \
    "$project_path" \
    --params task_description="${task_description}" \
    --params project_path="$(cd "$project_path" && pwd)" \
    --params quality_standard="production"
}

grrc() {
  _grrc_run "goose-sandbox" "_rhtgoose_env" "$@"
}

grrc-local() {
  _grrc_run "goose-sandbox-local" "_rhtgoose_env" "$@"
}

grrc-bare() {
  _grrc_run "" "_rhtgoose_env" "$@"
}

lwgrrc() {
  _grrc_run "goose-sandbox" "_lwgoose_env" "$@"
}

lwgrrc-local() {
  _grrc_run "goose-sandbox-local" "_lwgoose_env" "$@"
}

lwgrrc-bare() {
  _grrc_run "" "_lwgoose_env" "$@"
}

alias rhglab='GITLAB_HOST=gitlab.cee.redhat.com glab'

# source additional environment files outside of source control
source ~/.env_ai_assist
source ~/.env_personal

# Always get a new kubeconfig
$(kubectl-new-env)
