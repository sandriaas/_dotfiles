#!/usr/bin/env bash
set -euo pipefail

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
export SANDRIAAS_TOKEN="$MY_TOKEN"

# ─── Bashrc Cleanup & "Unset & Force" Logic ───────────────────────
echo "▸ Cleaning up old token logic and applying Unset & Force strategy..."

sed -i '/gh() {/,/}/d' "$HOME/.bashrc"
sed -i '/git() {/,/}/d' "$HOME/.bashrc"
sed -i '/export SANDRIAAS_TOKEN/d' "$HOME/.bashrc"
sed -i '/export -f gh/d' "$HOME/.bashrc"
sed -i '/export -f git/d' "$HOME/.bashrc"
sed -i '/export GH_TOKEN=/d' "$HOME/.bashrc"
sed -i '/export GITHUB_TOKEN=/d' "$HOME/.bashrc"
sed -i '/unset GH_TOKEN/d' "$HOME/.bashrc"
sed -i '/unset GITHUB_TOKEN/d' "$HOME/.bashrc"
sed -i '/# --- GitHub Identity Isolation/d' "$HOME/.bashrc"

cat << EOF >> "$HOME/.bashrc"

# --- GitHub Identity Isolation (Sandriaas) ---
export SANDRIAAS_TOKEN="$MY_TOKEN"

gh() {
    # Forcefully unset any agent-inherited tokens, then use sandriaas token
    (unset GH_TOKEN GITHUB_TOKEN; export GH_TOKEN="\$SANDRIAAS_TOKEN"; command gh "\$@")
}

git() {
    # Forcefully unset any agent-inherited tokens, then use sandriaas token
    # (extraheader is handled by the ~/.local/bin/git wrapper to avoid duplicates)
    (unset GH_TOKEN GITHUB_TOKEN; export GH_TOKEN="\$SANDRIAAS_TOKEN"; command git "\$@")
}

# Export functions so sub-processes (like the agent's shells) can see them
export -f gh
export -f git
EOF

# ─── Fish Shell Token Config ────────────────────────────────────────
if command -v fish &>/dev/null; then
  FISH_CONFIG="$HOME/.config/fish/config.fish"
  mkdir -p "$HOME/.config/fish"
  touch "$FISH_CONFIG"
  sed -i '/# >>> sandriaas-token >>>/,/# <<< sandriaas-token <<</d' "$FISH_CONFIG"

  cat << EOF >> "$FISH_CONFIG"

# >>> sandriaas-token >>>
set -gx SANDRIAAS_TOKEN "$MY_TOKEN"
# <<< sandriaas-token <<<
EOF
fi

# ─── Wrapper scripts for subprocess token isolation ────────────────
# Fish functions are NOT exported to subprocesses (unlike bash's export -f).
# These wrapper scripts in ~/.local/bin ensure that even when an agent launches
# gh/git directly (bypassing shell functions), SANDRIAAS_TOKEN is always used.
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/gh" << 'GHWRAP'
#!/usr/bin/env bash
_gh_real="$(type -P gh 2>/dev/null)"
if [ -z "$_gh_real" ] || [ "$_gh_real" = "$0" ]; then
    _gh_real="/usr/bin/gh"
fi
exec env -u GH_TOKEN -u GITHUB_TOKEN GH_TOKEN="${SANDRIAAS_TOKEN:-}" "$_gh_real" "$@"
GHWRAP
chmod +x "$HOME/.local/bin/gh"

cat > "$HOME/.local/bin/git" << 'GITWRAP'
#!/usr/bin/env bash
_git_real="$(type -P git 2>/dev/null)"
if [ -z "$_git_real" ] || [ "$_git_real" = "$0" ]; then
    _git_real="/usr/bin/git"
fi
if [ -n "${SANDRIAAS_TOKEN:-}" ]; then
    _header="$(printf 'x-access-token:%s' "$SANDRIAAS_TOKEN" | base64 -w0)"
    exec env -u GH_TOKEN -u GITHUB_TOKEN GH_TOKEN="$SANDRIAAS_TOKEN" \
        "$_git_real" -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $_header" "$@"
else
    exec "$_git_real" "$@"
fi
GITWRAP
chmod +x "$HOME/.local/bin/git"

echo ""
echo "✅ Token configuration complete."
echo "Run 'source ~/.bashrc' (or restart fish) and restart your agent session."
