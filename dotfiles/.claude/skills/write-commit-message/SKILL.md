---
name: write-commit-message
description: Write a conventional commit message by articulating the user's intent explicitly, then using a Luna (gpt-5.6-luna) subagent to format it cleanly. Use immediately before any git commit.
---

# Write Commit Message

**Announce at start:** "I'm using the write-commit-message skill."

## Step 0: Verify Workspace Tree Location & Git Identity

Before staging or committing, verify that the repository or worktree is located in the proper workspace directory so that `~/.gitconfig` `includeIf` conditional directives apply:

1. **Check repo location**: Run `pwd` or `git rev-parse --show-toplevel`.
   - **Primary repositories** must reside under `~/workspace/src/<forge>/...`:
     - GitHub repos: `~/workspace/src/github.com/...` (so `~/.gitconfig-github` applies: `arewm@users.noreply.github.com`, GPG signing enabled).
     - GitLab repos: `~/workspace/src/gitlab.cee.redhat.com/...` or `~/workspace/src/gitlab.com/...` (so `~/.gitconfig-gitlab` applies: Red Hat enterprise identity).
   - **Linked worktrees** must reside under `~/workspace/worktrees/<forge>/...`:
     - GitHub worktrees: `~/workspace/worktrees/github.com/<org>/<worktree-name>` (so `~/.gitconfig-github` applies).
     - GitLab worktrees: `~/workspace/worktrees/gitlab.cee.redhat.com/<group>/<worktree-name>` or `~/workspace/worktrees/gitlab.com/<group>/<worktree-name>` (so `~/.gitconfig-gitlab` applies).
     - **NEVER** create worktrees as sibling folders inside `~/workspace/src/...`, inside `~/.obsidian/...`, or in temporary dirs like `/tmp/`. Always create worktrees under `~/workspace/worktrees/<forge>/<group>/`.
   - Workspaces inside devaipod containers must be under `/workspaces/...`.
2. **Check configured git identity**:
   ```bash
   git config user.name && git config user.email && git config commit.gpgsign
   ```
   If `user.email` is unset or resolves to the machine fallback (e.g. `user@hostname`), the repository or worktree is in the wrong directory path (e.g. `~/obsidian/...` instead of `~/workspace/src/...` or `~/workspace/worktrees/...`).
3. **Prompt / Fix before proceeding**:
   If the repository or worktree is not in the appropriate workspace path, **warn the user and relocate/switch to the proper location under `~/workspace/src/...` (for primary repos) or `~/workspace/worktrees/<forge>/...` (for worktrees)** before creating any commit messages or making commits!

## Step 1: Articulate Context

Before looking at any diff, answer these from your session knowledge:

1. **Intent** — What did the user ask for, in plain language? One sentence. This is the "why."
2. **Scope** — The conventional commit prefix (e.g. `auth`, `api`, `kernel`, `docs`, or a component name).
3. **Notable** — Any surprising or non-obvious implementation choice worth calling out? Leave blank if nothing unusual.

If you cannot clearly answer question 1, ask the user before continuing.

## Step 2: Get the Diff

```bash
git diff --cached --stat && echo "---" && git diff --cached
```

If nothing is staged:
```bash
git log -1 --stat && echo "---" && git show HEAD
```

## Step 3: Spawn Luna Subagent

### Calling Model & Tool Identification Hints:
Before spawning Luna, determine:
- The **tool** being used (e.g. `goose`, `Claude Code`)
- The **calling model** identity (e.g. `gemini-3.8-flash`, `gpt-5.6-luna`, `claude-sonnet-5`, `Sonnet 4.6`)

**Hints for Goose to identify its current model accurately:**
Do not guess or rely on training data assumptions. Check in this exact priority order:
1. **Check Environment Variable first:** Run `echo "$GOOSE_MODEL"` via shell.
   If set (e.g. `gemini-3.8-flash`, `gpt-5.6-luna`, `claude-sonnet-5`), use that value directly!
2. **Check Goose Session DB:** If `$GOOSE_MODEL` is empty or unset, query the latest active session from SQLite:
   ```bash
   sqlite3 ~/.local/share/goose/sessions/sessions.db "SELECT json_extract(model_config_json, '$.model_name') FROM sessions ORDER BY updated_at DESC LIMIT 1;" 2>/dev/null
   ```
3. **Check Goose Config File:** If the DB query fails or returns nothing, inspect the configured provider model in Goose config:
   ```bash
   python3 -c "import yaml; c=yaml.safe_load(open('$HOME/.config/goose/config.yaml')); p=c.get('active_provider'); print(c.get('providers', {}).get(p, {}).get('model', ''))" 2>/dev/null
   ```
4. **For Claude Code / Other Assistants:** Check session context or environment variables (e.g. `CLAUDE_MODEL`, `Sonnet 4.6`, `Opus 4.5`).

Substitute both into the `Assisted-by` placeholder: `TOOL (MODEL)` — e.g. `goose (gemini-3.8-flash)` or `goose (gpt-5.6-luna)`. Do **not** pass the placeholder literally.

### Delegate to Luna:
Use `delegate(instructions: "...", model: "gpt-5.6-luna", provider: "openai")`. (In Claude Code, use the Agent tool). Pass this prompt verbatim, filling in the placeholders:

---

Write a git commit message. Return ONLY the commit message text — no explanation, no markdown fences, nothing else.

**Format:**

```
<scope>: <Verb> <description>

<body — optional, 1-3 sentences explaining WHY>

Assisted-by: TOOL (MODEL)
```

Where `TOOL (MODEL)` is filled in by the caller — e.g. `goose (gemini-3.8-flash)`, `goose (gpt-5.6-luna)`, or `Claude Code (Opus 4.5)`. Use exactly the value provided; do not substitute your own tool name.

**Rules:**
- Title: `scope: Verb description` — imperative mood, under 72 chars, no trailing period
- Body: explains WHY (what problem this solves, what constraint shaped the approach). Omit if the title is self-contained.
- NO bulleted `Changes:` lists
- NO "Files changed:" sections
- NO passive voice
- `Assisted-by:` line always required

**Anti-patterns — never produce these:**
```
feat: Add authentication

Changes:
- Added login endpoint
- Modified user model
- Updated tests

Files changed: auth.rs, user.rs
```

**Good examples:**
```
auth: Replace cookies with JWT session tokens

Mobile clients can't share cookies across domains, so we switched to
JWT tokens passed in the Authorization header.

Assisted-by: goose (Sonnet 4.6)
```

```
kernel: Fix hyphen-dash equality in find API

Assisted-by: goose (gemini-3.8-flash)
```

---

Assisted-by value to use verbatim: <TOOL (MODEL)>
User intent: <INTENT>
Scope: <SCOPE>
Notable: <NOTABLE or "none">

Diff:
<DIFF>

---

## Step 4: Commit

Use the returned message verbatim:

```bash
git commit -m "$(cat <<'EOF'
<message from subagent>
EOF
)"
```

Do not paraphrase or reformat the returned message. If it looks wrong, re-run Step 3 with better intent context — don't edit the output by hand.
