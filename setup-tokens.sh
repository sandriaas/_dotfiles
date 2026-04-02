#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup_bashrc() {
    local bashrc="$HOME/.bashrc"
    touch "$bashrc"

    sed -i '/# Clear inherited GitHub env tokens so shell sessions can use stored gh\/git auth\./d' "$bashrc"
    sed -i '/unset SANDRIAAS_TOKEN GH_TOKEN GITHUB_TOKEN/d' "$bashrc"
    sed -i '/gh() {/,/}/d' "$bashrc"
    sed -i '/git() {/,/}/d' "$bashrc"
    sed -i '/export -f gh/d' "$bashrc"
    sed -i '/export -f git/d' "$bashrc"
    sed -i '/export SANDRIAAS_TOKEN=/d' "$bashrc"
    sed -i '/export GH_TOKEN=/d' "$bashrc"
    sed -i '/export GITHUB_TOKEN=/d' "$bashrc"
    sed -i '/unset GH_TOKEN/d' "$bashrc"
    sed -i '/unset GITHUB_TOKEN/d' "$bashrc"
    sed -i '/unset SANDRIAAS_TOKEN/d' "$bashrc"

    python - "$bashrc" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text() if path.exists() else ""
marker = "# If not running interactively, don't do anything"
block = (
    "# Clear inherited GitHub env tokens so shell sessions can use stored gh/git auth.\n"
    "unset SANDRIAAS_TOKEN GH_TOKEN GITHUB_TOKEN\n\n"
)

if block in text:
    raise SystemExit(0)

if marker in text:
    text = text.replace(marker, block + marker, 1)
else:
    text = block + text

tail = (
    "\n"
    "gh() {\n"
    "    (unset SANDRIAAS_TOKEN GH_TOKEN GITHUB_TOKEN; command gh \"$@\")\n"
    "}\n\n"
    "git() {\n"
    "    (unset SANDRIAAS_TOKEN GH_TOKEN GITHUB_TOKEN; command git \"$@\")\n"
    "}\n\n"
    "export -f gh\n"
    "export -f git\n"
)

if "gh() {\n    (unset SANDRIAAS_TOKEN GH_TOKEN GITHUB_TOKEN; command gh \"$@\")\n}\n" not in text:
    text = text.rstrip() + tail

path.write_text(text)
PY
}

cleanup_fish() {
    local fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"
    touch "$fish_config"
    sed -i '/# >>> sandriaas-token >>>/,/# <<< sandriaas-token <<</d' "$fish_config"

    cat <<'EOF' >> "$fish_config"

# >>> sandriaas-token >>>
set -e SANDRIAAS_TOKEN
set -e GH_TOKEN
set -e GITHUB_TOKEN
# <<< sandriaas-token <<<
EOF
}

install_wrappers() {
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$SCRIPT_DIR/local/.local/bin/gh" "$HOME/.local/bin/gh"
    install -m 755 "$SCRIPT_DIR/local/.local/bin/git" "$HOME/.local/bin/git"
}

ensure_gh_login() {
    if gh auth status >/dev/null 2>&1; then
        return
    fi

    if [ ! -t 0 ] || [ ! -t 1 ]; then
        echo "ℹ gh is not logged in yet."
        echo "  Run 'gh auth login' after the install finishes to enable stored GitHub auth for pushes."
        return
    fi

    echo "---------------------------------------------------"
    echo "ACTION REQUIRED: Authenticate GitHub CLI."
    echo "This flow stores credentials in gh/keyring."
    echo "No raw token will be written into your dotfiles."
    echo "---------------------------------------------------"
    gh auth login
}

echo "▸ Resetting shell GitHub token overrides..."
cleanup_bashrc

if command -v fish >/dev/null 2>&1; then
    cleanup_fish
fi

echo "▸ Installing gh/git wrappers that ignore ambient GH_TOKEN overrides..."
install_wrappers

ensure_gh_login

echo ""
echo "✅ GitHub auth configuration complete."
echo "Wrappers now ignore ambient GH_TOKEN/GITHUB_TOKEN pollution and derive git auth from gh's stored login."
echo "Run 'source ~/.bashrc' (or restart fish) and restart your agent session."
