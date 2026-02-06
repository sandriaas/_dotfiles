# _dotfiles

Dotfiles & tool installer for dev machines (Ubuntu / Fedora).

## Quick Start

**🚀 Fresh System Setup:**
```bash
git clone https://github.com/sandriaas/_dotfiles.git && cd _dotfiles
chmod +x install.sh && ./install.sh
```

**🔄 Update Git Repo from Current System:**
```bash
./sync.sh "updated config after new setup"
```

## What Gets Installed

| Tool | Method |
|------|--------|
| git, python3, tmux, micro, curl | apt / dnf |
| Node.js LTS + npm | NodeSource |
| [uv / uvx](https://github.com/astral-sh/uv) | Official installer |
| [superfile](https://superfile.dev) | Official installer |
| [Claude Code CLI](https://claude.ai) | Official installer |
| [@openai/codex](https://www.npmjs.com/package/@openai/codex) | npm global |
| [@github/copilot](https://www.npmjs.com/package/@github/copilot) | npm global (prerelease) |
| **CAAM** (AI Account Manager) | [Official installer](https://github.com/Dicklesworthstone/coding_agent_account_manager) |

## How It Works

The `local/` folder contains the source configs with `sandriaas` paths. During installation:

1. **Auto-detects your username** or prompts if needed
2. **Dynamically replaces** all `sandriaas` references with your actual username  
3. **Deploys adjusted configs** to your `~/` directory

This means one set of config files works for any username!

Config files deployed to `~/`:

```
~/.copilot/mcp-config.json
~/.codex/config.toml
~/.mcp.json
~/.claude.json
~/.claude/settings.json
~/.claude/CLAUDE.md
~/.claude/AGENTS.md
~/.local/share/caam/             # CAAM vault with accounts (binary installed via script)
```

## Scripts

### `install.sh` - Fresh System Setup
Installs all tools and deploys your config files:
```bash
./install.sh
```

### `sync.sh` - Update Git Repo  
Syncs current system configs back to git with timestamp:
```bash
./sync.sh                           # Default commit message
./sync.sh "updated copilot config"   # Custom commit message
```
The sync script:
- Copies current configs from ~/.* to local/ folder
- Normalizes all paths back to `sandriaas` (source of truth)
- Commits with timestamp prefix
- Pushes to origin/main

## CAAM (AI Account Manager)

CAAM manages multiple AI service accounts with automatic switching, rate limiting, and session management.

**Installation:**
CAAM is installed automatically by the install script using:
```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_account_manager/main/install.sh?$(date +%s)" | bash
```

**Key Features:**
- **Multi-account management** for Codex, Claude, Gemini
- **Automatic profile switching** when rate limits hit
- **Secure vault storage** with OAuth token management
- **Usage tracking** and cost monitoring

**Common Commands:**
```bash
caam add                    # Add a new AI service account
caam ls                     # List all profiles
caam status                 # Show active profiles and health
caam activate <profile>   # Switch to specific profile
caam run codex "prompt"   # Run with automatic account switching
caam limits               # Check real-time rate limits
```

The installer copies your existing CAAM profiles and vault, so your accounts will be ready to use immediately.

## Serena MCP Server

Run in the background from your project directory:

```bash
uvx --from git+https://github.com/oraios/serena \
  serena start-mcp-server \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8080 \
  --context agent \
  --project-from-cwd &
```

To keep it running across sessions, use `tmux` or `nohup`:

```bash
nohup uvx --from git+https://github.com/oraios/serena \
  serena start-mcp-server \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8080 \
  --context agent \
  --project-from-cwd > /tmp/serena.log 2>&1 &
```

## Structure

```
├── install.sh          # Fresh system setup script  
├── sync.sh             # Sync current system → git
├── local/              # Source of truth (sandriaas paths, adjusted during install)
│   ├── .claude.json
│   ├── .mcp.json
│   ├── .claude/
│   ├── .codex/
│   ├── .copilot/
│   └── .local/
│       └── share/caam/ # CAAM vault (binary installed via script)
└── README.md
```

## Workflow

1. **Fresh Setup:** `./install.sh` prompts for username, adjusts paths, installs everything
2. **Work & Configure:** Use your tools, modify configs  
3. **Sync Back:** `./sync.sh "description"` normalizes paths back to sandriaas and updates git
4. **Deploy Elsewhere:** Clone and `./install.sh` on other machines with different usernames
