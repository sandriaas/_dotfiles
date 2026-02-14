#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_PWD="$(pwd)"

# ─── Interactive Token Input (Visible) ─────────────────────────────
echo "---------------------------------------------------"
echo "ACTION REQUIRED: Please paste your GitHub Token below."
echo "Note: Input is VISIBLE for verification."
echo "---------------------------------------------------"
printf "Enter GH Token: "
read -r MY_TOKEN

if [ -z "$MY_TOKEN" ]; then
    echo "❌ Error: No token provided. Script cannot continue."
    exit 1
fi
echo "✅ Token accepted."

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
else
  echo "Unsupported distro" && exit 1
fi

# ─── Core Utilities ────────────────────────────────────────────────
update_packages
install_packages git python3 python3-pip tmux unzip curl gawk procps

# ─── GitHub CLI (DNF 5 compatible) ──────────────────────────────────
if ! command -v gh &>/dev/null; then
  if [ "$PM" = "apt" ]; then
    as_root mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | as_root dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    as_root apt-get update
  else
    if dnf --version | grep -q "dnf5"; then
      as_root dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
    else
      install_packages 'dnf-command(config-manager)'
      as_root dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    fi
  fi
  install_packages gh
fi

# ─── Node, NPM, Bun, uv ────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  [ "$PM" = "apt" ] && curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash - || curl -fsSL https://rpm.nodesource.com/setup_lts.x | as_root bash -
  install_packages nodejs
fi

if command -v npm &>/dev/null; then
  as_root npm install -g @openai/codex || echo "⚠ Codex failed"
  as_root npm install -g @github/copilot@prerelease || echo "⚠ Copilot failed"
fi

! command -v bun &>/dev/null && { curl -fsSL https://bun.sh/install | bash; export PATH="$HOME/.bun/bin:$PATH"; }
! command -v uv &>/dev/null && { curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }

# ─── Bashrc Cleanup & "Unset & Force" Logic ───────────────────────
echo "▸ Cleaning up old token logic and applying Unset & Force strategy..."

# Clean out all previous logic variations
sed -i '/gh() {/,/}/d' "$HOME/.bashrc"
sed -i '/git() {/,/}/d' "$HOME/.bashrc"
sed -i '/export SANDRIAAS_TOKEN/d' "$HOME/.bashrc"
sed -i '/export -f gh/d' "$HOME/.bashrc"
sed -i '/export -f git/d' "$HOME/.bashrc"
sed -i '/export GH_TOKEN=/d' "$HOME/.bashrc"
sed -i '/export GITHUB_TOKEN=/d' "$HOME/.bashrc"
sed -i '/unset GH_TOKEN/d' "$HOME/.bashrc"
sed -i '/unset GITHUB_TOKEN/d' "$HOME/.bashrc"

cat << EOF >> "$HOME/.bashrc"

# --- GitHub Identity Isolation (Sandriaas) ---
export SANDRIAAS_TOKEN="$MY_TOKEN"

gh() {
    # Forcefully unset any agent-inherited tokens, then use sandriaas token
    (unset GH_TOKEN GITHUB_TOKEN; export GH_TOKEN="\$SANDRIAAS_TOKEN"; command gh "\$@")
}

git() {
    # Forcefully unset any agent-inherited tokens, then use sandriaas token via header
    (unset GH_TOKEN GITHUB_TOKEN; export GH_TOKEN="\$SANDRIAAS_TOKEN"; \\
     command git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic \$(echo -n x-access-token:\$SANDRIAAS_TOKEN | base64)" "\$@")
}

# Export functions so sub-processes (like the agent's shells) can see them
export -f gh
export -f git
EOF

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
echo "✅ Deployment finished with Unset & Force logic."

echo "🚀 Setup complete. Run 'source ~/.bashrc' and restart your agent session."
