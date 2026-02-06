#!/usr/bin/env bash
set -euo pipefail

# ─── Sync Script: Update git repo with current system state ───
# Usage: ./sync.sh [message]

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MESSAGE="${1:-"sync system configs"}"

cd "$DOTFILES_DIR"

echo "🔄 Syncing system configs to git repo..."
echo "📁 Dotfiles dir: $DOTFILES_DIR"

# ─── Update config files from system ──────────────────────────────
update_configs() {
  local profile="$1"
  local target_dir="$2"
  
  echo "▸ Updating $profile profile..."
  
  # Core config files
  [ -f ~/.mcp.json ] && cp ~/.mcp.json "$target_dir/"
  [ -f ~/.claude.json ] && cp ~/.claude.json "$target_dir/"
  
  # Directory configs
  [ -f ~/.copilot/mcp-config.json ] && mkdir -p "$target_dir/.copilot" && cp ~/.copilot/mcp-config.json "$target_dir/.copilot/"
  [ -f ~/.codex/config.toml ] && mkdir -p "$target_dir/.codex" && cp ~/.codex/config.toml "$target_dir/.codex/"
  
  # Claude configs
  if [ -d ~/.claude ]; then
    mkdir -p "$target_dir/.claude"
    [ -f ~/.claude/settings.json ] && cp ~/.claude/settings.json "$target_dir/.claude/"
    [ -f ~/.claude/CLAUDE.md ] && cp ~/.claude/CLAUDE.md "$target_dir/.claude/"
    [ -f ~/.claude/AGENTS.md ] && cp ~/.claude/AGENTS.md "$target_dir/.claude/"
  fi
  
  # CAAM vault (but not binary)
  if [ -d ~/.local/share/caam ]; then
    mkdir -p "$target_dir/.local/share"
    cp -r ~/.local/share/caam "$target_dir/.local/share/"
    echo "  ✓ CAAM vault updated"
  fi
  
  echo "  ✓ $profile configs updated"
}

# ─── Detect current user and update appropriate profile ───────────
CURRENT_USER=$(whoami)

if [ "$CURRENT_USER" = "sprite" ]; then
  echo "🎯 Detected sprite user - updating sprites/ profile"
  update_configs "sprites" "sprites"
  
  # Replace any sandriaas paths that might have leaked in
  find sprites -type f -exec sed -i 's|/home/sandriaas|/home/sprite|g; s|sandriaas|sprite|g' {} + 2>/dev/null || true
  
else
  echo "🎯 Detected $CURRENT_USER user - updating local/ profile"
  update_configs "local" "local"
fi

# ─── Git operations ────────────────────────────────────────────────
echo "▸ Staging changes..."
git add -A

if git diff --cached --quiet; then
  echo "✅ No changes to commit"
  exit 0
fi

echo "▸ Changes to commit:"
git --no-pager diff --cached --stat

echo "▸ Committing changes..."
git commit -m "$TIMESTAMP: $MESSAGE"

echo "▸ Pushing to origin main..."
git push origin main

echo "✅ Sync complete! System configs updated in git repo."
echo ""
echo "📊 Latest commits:"
git --no-pager log --oneline -3