#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/sandriaas/_dotfiles.git"
TMPDIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() {
  rm -rf "$TMPDIR"
}

trap cleanup EXIT

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# ─── Detect package manager ────────────────────────────────────────
if command -v apt-get &>/dev/null; then
  PM="apt"
  update_packages() { [ "${DOTFILES_APT_UPDATE:-0}" = "1" ] && as_root apt-get update || true; }
  install_packages() { as_root apt-get install -y "$@"; }
elif command -v dnf &>/dev/null; then
  PM="dnf"
  update_packages() { :; }
  install_packages() {
    as_root dnf install -y "$@" || as_root dnf install -y --allowerasing "$@"
  }
elif command -v pacman &>/dev/null; then
  PM="pacman"
  update_packages() { :; }
  install_packages() { as_root pacman -S --needed --noconfirm "$@"; }
else
  echo "Unsupported distro" && exit 1
fi

resolve_repo_root() {
  if [ -f "$SCRIPT_DIR/setup-tokens.sh" ] && [ -d "$SCRIPT_DIR/local" ]; then
    printf '%s\n' "$SCRIPT_DIR"
    return
  fi

  if [ ! -d "$TMPDIR/_dotfiles/.git" ]; then
    echo "▸ Fetching _dotfiles payload..." >&2
    git clone --depth 1 "$REPO" "$TMPDIR/_dotfiles"
  fi

  printf '%s\n' "$TMPDIR/_dotfiles"
}

# ─── Core Utilities ────────────────────────────────────────────────
update_packages
if [ "$PM" = "pacman" ]; then
  install_packages git python python-pip tmux unzip curl gawk procps-ng fish
else
  install_packages git python3 python3-pip tmux unzip curl gawk procps
fi

# ─── GitHub CLI (DNF 5 compatible) ──────────────────────────────────
if ! command -v gh &>/dev/null; then
  if [ "$PM" = "apt" ]; then
    as_root mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | as_root dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    as_root apt-get update
  elif [ "$PM" = "dnf" ]; then
    if dnf --version | grep -q "dnf5"; then
      as_root dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
    else
      install_packages 'dnf-command(config-manager)'
      as_root dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    fi
  fi
  if [ "$PM" = "pacman" ]; then
    install_packages github-cli
  else
    install_packages gh
  fi
fi

# ─── Token & gh/git Configuration ──────────────────────────────────
REPO_ROOT="$(resolve_repo_root)"
# shellcheck source=setup-tokens.sh
source "$REPO_ROOT/setup-tokens.sh"

# ─── Node, NPM, Bun, uv ────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  if [ "$PM" = "pacman" ]; then
    install_packages nodejs npm
  else
    [ "$PM" = "apt" ] && curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash - || curl -fsSL https://rpm.nodesource.com/setup_lts.x | as_root bash -
    install_packages nodejs
  fi
fi

if command -v npm &>/dev/null; then
  as_root npm install -g @openai/codex || echo "⚠ Codex failed"
  as_root npm install -g @github/copilot@prerelease || echo "⚠ Copilot failed"
fi

! command -v bun &>/dev/null && { curl -fsSL https://bun.sh/install | bash; export PATH="$HOME/.bun/bin:$PATH"; }
! command -v uv &>/dev/null && { curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }

# ─── superfile ──────────────────────────────────────────────────────
if ! command -v spf &>/dev/null; then
  echo "▸ Installing superfile..."
  bash -c "$(curl -sLo- https://superfile.dev/install.sh)" || echo "⚠ superfile failed"
fi

# ─── Claude Code CLI ───────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "▸ Installing Claude CLI..."
  curl -fsSL https://claude.ai/install.sh | bash || echo "⚠ Claude CLI failed"
fi

# ─── OpenCode CLI ───────────────────────────────────────────────────
echo "▸ Installing OpenCode CLI..."
curl -fsSL https://opencode.ai/install | bash || echo "⚠ OpenCode CLI failed"

# ─── Cosign ─────────────────────────────────────────────────────────
if ! command -v cosign &>/dev/null; then
  echo "▸ Installing Cosign..."
  ARCH=$(uname -m)
  BINARY=$([ "$ARCH" = "x86_64" ] && echo "cosign-linux-amd64" || echo "cosign-linux-arm64")
  curl -LO "https://github.com/sigstore/cosign/releases/latest/download/${BINARY}"
  chmod +x "${BINARY}"
  as_root mv "${BINARY}" /usr/local/bin/cosign 2>/dev/null || { mkdir -p "$HOME/.local/bin"; mv "${BINARY}" "$HOME/.local/bin/cosign"; }
fi

# ─── CAAM (AI Account Manager) ─────────────────────────────────────
if ! command -v caam &>/dev/null; then
  echo "▸ Installing CAAM..."
  export CAAM_SKIP_VERIFY=1
  curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_account_manager/main/install.sh" | bash || echo "⚠ CAAM installer failed"
fi

# ─── Dotfiles ──────────────────────────────────────────────────────
TARGET_USER=$(whoami)
[ "$TARGET_USER" = "root" ] && { echo "Enter target username:"; read -r TARGET_USER; }

SRC="$REPO_ROOT/local"
replace_and_copy() {
  local s="$1" d="$2"
  [ -f "$s" ] && sed "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" "$s" > "$d"
}

mkdir -p "$HOME/.copilot" "$HOME/.codex" "$HOME/.claude/hooks" "$HOME/.opencode/plugins" "$HOME/.local/bin" "$HOME/.local/share/caam"

# MCP & editor configs
replace_and_copy "$SRC/.mcp.json" "$HOME/.mcp.json"
replace_and_copy "$SRC/.claude.json" "$HOME/.claude.json"
replace_and_copy "$SRC/.copilot/mcp-config.json" "$HOME/.copilot/mcp-config.json"
replace_and_copy "$SRC/.codex/config.toml" "$HOME/.codex/config.toml"

# Claude settings, docs, hooks
replace_and_copy "$SRC/.claude/settings.json" "$HOME/.claude/settings.json"
replace_and_copy "$SRC/.claude/settings.json.copilotapi" "$HOME/.claude/settings.json.copilotapi"
replace_and_copy "$SRC/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
replace_and_copy "$SRC/.claude/AGENTS.md" "$HOME/.claude/AGENTS.md"
replace_and_copy "$SRC/.claude/hooks/subagent-start-marker.js" "$HOME/.claude/hooks/subagent-start-marker.js"

# Claude skills (full folder tree with username normalization)
if [ -d "$SRC/.claude/skills" ]; then
  echo "▸ Deploying Claude skills..."
  find "$SRC/.claude/skills" -type f | while read -r f; do
    rel="${f#$SRC/.claude/skills/}"
    dest="$HOME/.claude/skills/$rel"
    mkdir -p "$(dirname "$dest")"
    sed "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" "$f" > "$dest"
  done
fi

# OpenCode plugins
replace_and_copy "$SRC/.opencode/plugins/subagent-marker.js" "$HOME/.opencode/plugins/subagent-marker.js"

# CAAM bundled binary (repo-first, fallback already installed above)
if [ -f "$SRC/.local/bin/caam" ]; then
  echo "▸ Deploying bundled CAAM binary..."
  install -m 755 "$SRC/.local/bin/caam" "$HOME/.local/bin/caam"
fi

# claude --worktree fix wrapper
if [ -f "$SRC/.local/bin/claude" ]; then
  echo "▸ Deploying claude worktree wrapper..."
  [ -x "$HOME/.local/bin/claude" ] && [ ! -f "$HOME/.local/bin/claude.real" ] && mv "$HOME/.local/bin/claude" "$HOME/.local/bin/claude.real"
  install -m 755 "$SRC/.local/bin/claude" "$HOME/.local/bin/claude"
fi

# ─── Finalize ──────────────────────────────────────────────────────
echo ""
echo "✅ Deployment finished."
echo "🚀 Setup complete. Run 'source ~/.bashrc' (or restart fish) and restart your agent session."
