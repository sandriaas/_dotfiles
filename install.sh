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
if command -v npm &>/dev/null; then
  echo "▸ Installing @openai/codex..."
  # Try without sudo first (npm may be user-installed)
  if npm install -g @openai/codex 2>/dev/null || sudo -E npm install -g @openai/codex; then
    echo "✓ Codex installed"
  else
    echo "⚠ Failed to install @openai/codex - you may need to install manually"
  fi
else
  echo "⚠ npm not found - skipping Codex install"
fi

# ─── GitHub Copilot CLI ────────────────────────────────────────────
if command -v npm &>/dev/null; then
  echo "▸ Installing @github/copilot (prerelease)..."
  # Try without sudo first (npm may be user-installed)
  if npm install -g @github/copilot@prerelease 2>/dev/null || sudo -E npm install -g @github/copilot@prerelease; then
    echo "✓ Copilot installed"
  else
    echo "⚠ Failed to install @github/copilot - you may need to install manually"
  fi
else
  echo "⚠ npm not found - skipping Copilot install"
fi

# ─── Clone & deploy dotfiles ───────────────────────────────────────
REPO="https://github.com/sandriaas/_dotfiles.git"
TMPDIR=$(mktemp -d)
echo "▸ Cloning $REPO..."
git clone "$REPO" "$TMPDIR/_dotfiles"

# Get username (auto-detect or prompt)
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" = "root" ] || [ -z "$CURRENT_USER" ]; then
  echo "▸ Enter your username for config paths:"
  read -r TARGET_USER
else
  echo "▸ Detected user: $CURRENT_USER"
  echo "▸ Use this username for config paths? (Y/n)"
  read -r CONFIRM
  if [[ "$CONFIRM" =~ ^[Nn] ]]; then
    echo "▸ Enter your preferred username:"
    read -r TARGET_USER
  else
    TARGET_USER="$CURRENT_USER"
  fi
fi

echo "▸ Using username: $TARGET_USER"
SRC="$TMPDIR/_dotfiles/local"

# Copy dotfiles to home with path replacement
echo "▸ Copying config files to ~/ ..."
replace_and_copy() {
  local src_file="$1"
  local dest_file="$2"
  if [ -f "$src_file" ]; then
    sed "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" "$src_file" > "$dest_file"
    echo "  ✓ $(basename "$dest_file") (with user paths adjusted)"
  else
    echo "  ⚠ Source file not found: $src_file"
  fi
}

replace_and_copy "$SRC/.mcp.json" "$HOME/.mcp.json"
replace_and_copy "$SRC/.claude.json" "$HOME/.claude.json"

mkdir -p "$HOME/.copilot"
replace_and_copy "$SRC/.copilot/mcp-config.json" "$HOME/.copilot/mcp-config.json"

mkdir -p "$HOME/.codex"  
replace_and_copy "$SRC/.codex/config.toml" "$HOME/.codex/config.toml"

mkdir -p "$HOME/.claude"
replace_and_copy "$SRC/.claude/settings.json" "$HOME/.claude/settings.json"
cp -v "$SRC/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
cp -v "$SRC/.claude/AGENTS.md" "$HOME/.claude/AGENTS.md"

# ─── CAAM (AI Account Manager) ─────────────────────────────────────
echo "▸ Installing CAAM (AI Account Manager)..."
mkdir -p "$HOME/.local/bin" "$HOME/.local/share"

# Install CAAM binary from official installer
if ! command -v caam &>/dev/null; then
  echo "▸ Downloading CAAM from official installer..."
  if curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_account_manager/main/install.sh?$(date +%s)" | bash; then
    echo "✓ CAAM installed successfully"
  else
    echo "⚠ CAAM installation failed - you may need to install manually"
    echo "  Run: curl -fsSL \"https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_account_manager/main/install.sh?\$(date +%s)\" | bash"
  fi
else
  echo "✓ CAAM already installed: $(which caam)"
fi

# Copy CAAM vault if available
if [ -d "$SRC/.local/share/caam" ]; then
  echo "▸ Copying CAAM vault with path adjustments..."
  mkdir -p "$HOME/.local/share"
  
  # Copy vault with path replacements
  cp -r "$SRC/.local/share/caam" "/tmp/caam_temp"
  find /tmp/caam_temp -type f -exec sed -i "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" {} +
  cp -r /tmp/caam_temp "$HOME/.local/share/caam"
  rm -rf /tmp/caam_temp
  
  echo "✓ CAAM vault copied with user paths adjusted"
else
  echo "ℹ CAAM vault not found in dotfiles - you can add accounts with: caam add"
fi

# Test CAAM installation and show status
export PATH="$HOME/.local/bin:$PATH"
if command -v caam &>/dev/null; then
  echo "▸ CAAM Status:"
  caam ls 2>/dev/null || echo "  No profiles found yet - use 'caam add' to add accounts"
  echo ""
  caam status 2>/dev/null || echo "  Use 'caam add' to add your first AI service account"
else
  echo "⚠ CAAM command not available - installation may have failed"
fi

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "✅ Done! All tools installed and dotfiles deployed."
echo ""
echo "To start the Serena MCP server in the background run:"
echo '  uvx --from git+https://github.com/oraios/serena serena start-mcp-server --transport streamable-http --host 127.0.0.1 --port 8080 --context agent --project-from-cwd &'
