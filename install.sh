#!/usr/bin/env bash
set -euo pipefail

# ─── Detect package manager ────────────────────────────────────────
if command -v apt-get &>/dev/null; then
  PM="apt"
  INSTALL="sudo apt-get update && sudo apt-get install -y"
elif command -v dnf &>/dev/null; then
  PM="dnf"
  INSTALL="sudo dnf install -y"
else
  echo "Unsupported distro (need apt or dnf)" && exit 1
fi

echo "▸ Package manager: $PM"

# ─── Core packages ─────────────────────────────────────────────────
echo "▸ Installing git, python3, tmux, micro, curl..."
eval "$INSTALL git python3 python3-pip tmux micro curl"

# ─── Node.js & npm (via NodeSource LTS) ────────────────────────────
if ! command -v node &>/dev/null; then
  echo "▸ Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  eval "$INSTALL nodejs"
fi
echo "▸ Node $(node -v)  npm $(npm -v)"

# ─── uv & uvx (Python package manager) ─────────────────────────────
if ! command -v uv &>/dev/null; then
  echo "▸ Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
echo "▸ uv $(uv --version)"

# ─── superfile ──────────────────────────────────────────────────────
if ! command -v spf &>/dev/null; then
  echo "▸ Installing superfile..."
  bash -c "$(curl -sLo- https://superfile.dev/install.sh)"
fi

# ─── Claude Code CLI ───────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "▸ Installing Claude CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

# ─── OpenAI Codex CLI ──────────────────────────────────────────────
echo "▸ Installing @openai/codex..."
sudo npm install -g @openai/codex

# ─── GitHub Copilot CLI ────────────────────────────────────────────
echo "▸ Installing @github/copilot (prerelease)..."
sudo npm install -g @github/copilot@prerelease

# ─── Clone & deploy dotfiles ───────────────────────────────────────
REPO="https://github.com/sandriaas/_dotfiles.git"
TMPDIR=$(mktemp -d)
echo "▸ Cloning $REPO..."
git clone "$REPO" "$TMPDIR/_dotfiles"

WHOAMI=$(whoami)
SRC="$TMPDIR/_dotfiles"

# Pick the right profile folder
if [ "$WHOAMI" = "sprite" ]; then
  PROFILE="sprites"
else
  PROFILE="local"
fi

echo "▸ Detected user: $WHOAMI → using profile: $PROFILE"

# Copy dotfiles to home
echo "▸ Copying config files to ~/ ..."
cp -v "$SRC/$PROFILE/.mcp.json"                "$HOME/.mcp.json"
cp -v "$SRC/$PROFILE/.claude.json"              "$HOME/.claude.json"
mkdir -p "$HOME/.copilot"
cp -v "$SRC/$PROFILE/.copilot/mcp-config.json"  "$HOME/.copilot/mcp-config.json"
mkdir -p "$HOME/.codex"
cp -v "$SRC/$PROFILE/.codex/config.toml"         "$HOME/.codex/config.toml"
mkdir -p "$HOME/.claude"
cp -v "$SRC/$PROFILE/.claude/settings.json"      "$HOME/.claude/settings.json"
cp -v "$SRC/$PROFILE/.claude/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"
cp -v "$SRC/$PROFILE/.claude/AGENTS.md"          "$HOME/.claude/AGENTS.md"

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "✅ Done! All tools installed and dotfiles deployed."
echo ""
echo "To start the Serena MCP server in the background run:"
echo '  uvx --from git+https://github.com/oraios/serena serena start-mcp-server --transport streamable-http --host 127.0.0.1 --port 8080 --context agent --project-from-cwd &'
