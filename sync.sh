#!/usr/bin/env bash
set -euo pipefail

# ─── Sync Script: Update git repo with current system state ───
# Usage: ./sync.sh [message]

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MESSAGE="${1:-"sync system configs"}"
REPO_URL="https://github.com/sandriaas/_dotfiles.git"

echo "🔄 Syncing system configs to git repo..."

# ─── Clone fresh copy to avoid conflicts ──────────────────────────
TMPDIR=$(mktemp -d)
echo "📥 Cloning fresh copy from $REPO_URL..."
git clone "$REPO_URL" "$TMPDIR/dotfiles"
cd "$TMPDIR/dotfiles"

echo "📁 Working in: $TMPDIR/dotfiles"

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
  [ -f ~/.copilot/mcp-server.json ] && mkdir -p "$target_dir/.copilot" && cp ~/.copilot/mcp-server.json "$target_dir/.copilot/"
  [ -f ~/.codex/config.toml ] && mkdir -p "$target_dir/.codex" && cp ~/.codex/config.toml "$target_dir/.codex/"
  
  # Claude configs
  if [ -d ~/.claude ]; then
    mkdir -p "$target_dir/.claude"
    [ -f ~/.claude/settings.json ] && cp ~/.claude/settings.json "$target_dir/.claude/"
    [ -f ~/.claude/CLAUDE.md ] && cp ~/.claude/CLAUDE.md "$target_dir/.claude/"
    [ -f ~/.claude/AGENTS.md ] && cp ~/.claude/AGENTS.md "$target_dir/.claude/"
    if [ -d ~/.claude/skills ]; then
      rm -rf "$target_dir/.claude/skills"
      cp -r ~/.claude/skills "$target_dir/.claude/"
      echo "  ✓ Claude skills updated"
    elif [ -d "$target_dir/.claude/skills" ]; then
      rm -rf "$target_dir/.claude/skills"
      echo "  ✓ Claude skills removed (not found locally)"
    fi
  fi
  
  # CAAM vault (but not binary)
  if [ -d ~/.local/share/caam ]; then
    mkdir -p "$target_dir/.local/share/caam"
    if command -v rsync &>/dev/null; then
      rsync -a --delete ~/.local/share/caam/ "$target_dir/.local/share/caam/"
    else
      rm -rf "$target_dir/.local/share/caam"
      cp -r ~/.local/share/caam "$target_dir/.local/share/"
    fi
    echo "  ✓ CAAM vault updated"
  elif [ -d "$target_dir/.local/share/caam" ]; then
    rm -rf "$target_dir/.local/share/caam"
    echo "  ✓ CAAM vault removed (not found locally)"
  fi
  
  echo "  ✓ $profile configs updated"
}

# ─── Detect current user and update local/ profile ──────────────
CURRENT_USER=$(whoami)
echo "🎯 Detected $CURRENT_USER user - updating local/ profile as source of truth"

update_configs "local" "local"

# Always normalize paths back to sandriaas in the git repo (source of truth)
if [ "$CURRENT_USER" != "sandriaas" ]; then
  echo "▸ Normalizing paths back to sandriaas for git storage..."
  find local -type f -exec sed -i "s|/home/$CURRENT_USER|/home/sandriaas|g; s|$CURRENT_USER|sandriaas|g" {} + 2>/dev/null || true
  echo "  ✓ Paths normalized to sandriaas in local/ folder"
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

# ─── Cleanup ────────────────────────────────────────────────────────
cd /
rm -rf "$TMPDIR"

echo "✅ Sync complete! System configs updated in git repo."
echo ""
echo "📊 Latest commits:"
git --no-pager log --oneline -3 2>/dev/null || echo "Check: git log --oneline -3"
