#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_PWD="$(pwd)"

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
  update_packages() {
    if [ "${DOTFILES_APT_UPDATE:-0}" = "1" ]; then
      echo "▸ Running apt update (DOTFILES_APT_UPDATE=1)..."
      as_root apt-get update
    else
      echo "▸ Skipping apt update by default (set DOTFILES_APT_UPDATE=1 to enable)"
    fi
  }
  install_packages() {
    if ! as_root apt-get install -y "$@"; then
      if [ "${DOTFILES_APT_UPDATE:-0}" != "1" ]; then
        echo "⚠ apt install failed with cached package lists."
        echo "  Retry with: DOTFILES_APT_UPDATE=1"
      fi
      return 1
    fi
  }
  micro_in_repo() { apt-cache show micro &>/dev/null; }
elif command -v dnf &>/dev/null; then
  PM="dnf"
  update_packages() { :; }
  install_packages() {
    if ! as_root dnf install -y "$@"; then
      echo "▸ dnf install failed for: $*"
      echo "▸ Retrying with --allowerasing to resolve package conflicts..."
      as_root dnf install -y --allowerasing "$@"
    fi
  }
  micro_in_repo() { dnf -q list micro &>/dev/null; }
else
  echo "Unsupported distro (need apt or dnf)" && exit 1
fi

echo "▸ Package manager: $PM"

# ─── Core packages ─────────────────────────────────────────────────
echo "▸ Installing git, python3, tmux..."
update_packages
install_packages git python3 python3-pip tmux unzip

# ─── micro editor (repo package or standalone binary) ──────────────
install_micro_binary() {
  local tmpdir
  tmpdir="$(mktemp -d)"

  if (cd "$tmpdir" && curl -fsSL https://getmic.ro | bash); then
    if as_root install -m 0755 "$tmpdir/micro" /usr/local/bin/micro 2>/dev/null; then
      echo "✓ micro installed to /usr/local/bin/micro"
    else
      mkdir -p "$HOME/.local/bin"
      install -m 0755 "$tmpdir/micro" "$HOME/.local/bin/micro"
      export PATH="$HOME/.local/bin:$PATH"
      echo "✓ micro installed to $HOME/.local/bin/micro"
    fi
  else
    echo "⚠ Failed to install micro via standalone binary"
  fi

  rm -rf "$tmpdir"
}

if command -v micro &>/dev/null; then
  echo "▸ micro already installed"
elif micro_in_repo; then
  echo "▸ Installing micro from $PM repositories..."
  install_packages micro
else
  echo "▸ micro package not available in $PM repos. Installing standalone binary..."
  install_micro_binary
fi

if ! command -v micro &>/dev/null; then
  echo "⚠ micro is still unavailable; continuing without it"
fi

# ─── GitHub CLI ─────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  echo "▸ gh already installed"
else
  echo "▸ Installing GitHub CLI..."
  if [ "$PM" = "apt" ]; then
    as_root mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | as_root dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    echo "▸ Updating apt package lists for GitHub CLI..."
    as_root apt-get update
    install_packages gh
  else
    install_packages 'dnf-command(config-manager)'
    as_root dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    install_packages gh --repo gh-cli
  fi
fi

# ─── Node.js & npm (via NodeSource LTS) ────────────────────────────
if ! command -v node &>/dev/null; then
  echo "▸ Installing Node.js LTS..."
  if [ "$PM" = "apt" ]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash -
  else
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | as_root bash -
  fi
  install_packages nodejs
fi
echo "▸ Node $(node -v)  npm $(npm -v)"

# ─── Bun ────────────────────────────────────────────────────────────
if ! command -v bun &>/dev/null; then
  echo "▸ Installing Bun..."
  curl -fsSL https://bun.com/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  if [ -f "$HOME/.bashrc" ]; then
    echo "▸ Reloading ~/.bashrc to pick up Bun PATH (if configured)..."
    set +e
    # shellcheck disable=SC1090
    source "$HOME/.bashrc"
    BASHRC_RC=$?
    set -e
    if [ "$BASHRC_RC" -ne 0 ]; then
      echo "⚠ Failed to source ~/.bashrc (exit $BASHRC_RC); continuing"
    fi
  fi
fi
if command -v bun &>/dev/null; then
  echo "▸ Bun $(bun --version)"
fi

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

# ─── OpenCode CLI ───────────────────────────────────────────────────
echo "▸ Installing OpenCode CLI..."
if curl -fsSL https://opencode.ai/install | bash; then
  echo "✓ OpenCode CLI installed"
else
  echo "⚠ Failed to install OpenCode CLI - you may need to install manually"
fi

# ─── GitHub Copilot CLI ────────────────────────────────────────────
if command -v npm &>/dev/null; then
  echo "▸ Installing @github/copilot (prerelease)..."
  # Try without sudo first (npm may be user-installed)
  if npm install -g @github/copilot@prerelease 2>/dev/null || sudo -E npm install -g @github/copilot@prerelease; then
    COPILOT_BIN="$(npm prefix -g)/bin"
    export PATH="$COPILOT_BIN:$PATH"
    if command -v copilot &>/dev/null; then
      echo "✓ Copilot installed"
    else
      echo "⚠ Copilot installed but 'copilot' is not on PATH"
      echo "  Ensure $COPILOT_BIN is in your PATH"
    fi
  else
    echo "⚠ Failed to install @github/copilot - you may need to install manually"
  fi
else
  echo "⚠ npm not found - skipping Copilot install"
fi

# ─── Cosign ─────────────────────────────────────────────────────────
echo "▸ Installing Cosign..."
if curl -fsSL https://raw.githubusercontent.com/sigstore/cosign/main/install.sh | sh; then
  # Move to proper location
  sudo mv ./cosign /usr/local/bin/cosign 2>/dev/null || mv ./cosign "$HOME/.local/bin/cosign"
  echo "✓ Cosign installed"
else
  echo "⚠ Failed to install Cosign - you may need to install manually"
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

copy_dir_with_path_adjustments() {
  local src_dir="$1"
  local dest_dir="$2"
  local label="$3"
  local temp_dir

  temp_dir=$(mktemp -d)
  cp -r "$src_dir/." "$temp_dir/"
  while IFS= read -r -d '' f; do
    if grep -Iq . "$f" 2>/dev/null; then
      sed -i "s|sandriaas|$TARGET_USER|g; s|/home/sandriaas|/home/$TARGET_USER|g" "$f" 2>/dev/null || true
    fi
  done < <(find "$temp_dir" -type f -print0)
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  cp -r "$temp_dir/." "$dest_dir/"
  rm -rf "$temp_dir"

  echo "✓ $label copied with user paths adjusted"
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

if [ -d "$ORIGINAL_PWD" ] && [ -w "$ORIGINAL_PWD" ]; then
  echo "▸ Copying AGENTS.md and CLAUDE.md to current directory: $ORIGINAL_PWD"
  replace_and_copy "$SRC/.claude/AGENTS.md" "$ORIGINAL_PWD/AGENTS.md"
  replace_and_copy "$SRC/.claude/CLAUDE.md" "$ORIGINAL_PWD/CLAUDE.md"
else
  echo "ℹ Current directory is not writable - skipping AGENTS.md/CLAUDE.md copy"
fi

if [ -d "$SRC/.claude/skills" ]; then
  echo "▸ Copying Claude skills with path adjustments..."
  copy_dir_with_path_adjustments "$SRC/.claude/skills" "$HOME/.claude/skills" "Claude skills"
else
  echo "ℹ Claude skills folder not found in dotfiles - skipping ~/.claude/skills"
fi

# ─── CAAM (AI Account Manager) ─────────────────────────────────────
echo "▸ Installing CAAM (AI Account Manager)..."
mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
CAAM_BUNDLED="$SRC/.local/bin/caam"

# Install bundled CAAM binary from dotfiles first
if [ -f "$CAAM_BUNDLED" ]; then
  echo "▸ Installing bundled CAAM binary from dotfiles..."
  if as_root install -m 0755 "$CAAM_BUNDLED" /usr/local/bin/caam 2>/dev/null; then
    echo "✓ CAAM installed to /usr/local/bin/caam"
  else
    install -m 0755 "$CAAM_BUNDLED" "$HOME/.local/bin/caam"
    echo "✓ CAAM installed to $HOME/.local/bin/caam"
  fi
elif ! command -v caam &>/dev/null; then
  echo "▸ Bundled CAAM binary not found; downloading from official installer..."
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
  copy_dir_with_path_adjustments "$SRC/.local/share/caam" "$HOME/.local/share/caam" "CAAM vault"
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
echo '  uvx --from git+https://github.com/oraios/serena serena start-mcp-server --transport streamable-http --host 127.0.0.1 --port 8080 --context agent --project . &'
