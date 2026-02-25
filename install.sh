#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_PWD="$(pwd)"

# ─── Token & gh/git Configuration ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-tokens.sh
source "$SCRIPT_DIR/setup-tokens.sh"
# MY_TOKEN and SANDRIAAS_TOKEN are now set by setup-tokens.sh

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

# ─── Dotfiles ──────────────────────────────────────────────────────
REPO="https://github.com/sandriaas/_dotfiles.git"
TMPDIR=$(mktemp -d)
(export GH_TOKEN="$MY_TOKEN"; git clone "$REPO" "$TMPDIR/_dotfiles")

TARGET_USER=$(whoami)
[ "$TARGET_USER" = "root" ] && { echo "Enter target username:"; read -r TARGET_USER; }

SRC="$TMPDIR/_dotfiles/local"
replace_and_copy() {
  local s="$1" d="$2"
  [ -f "$s" ] && sed "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" "$s" > "$d"
}

mkdir -p "$HOME/.copilot" "$HOME/.codex" "$HOME/.claude"
replace_and_copy "$SRC/.mcp.json" "$HOME/.mcp.json"
replace_and_copy "$SRC/.claude.json" "$HOME/.claude.json"
replace_and_copy "$SRC/.copilot/mcp-config.json" "$HOME/.copilot/mcp-config.json"
replace_and_copy "$SRC/.codex/config.toml" "$HOME/.codex/config.toml"
replace_and_copy "$SRC/.claude/settings.json" "$HOME/.claude/settings.json"

# ─── Finalize ──────────────────────────────────────────────────────
rm -rf "$TMPDIR"
echo ""
echo "✅ Deployment finished."
echo "🚀 Setup complete. Run 'source ~/.bashrc' (or restart fish) and restart your agent session."
