# _dotfiles

Dotfiles & tool installer for dev machines (Ubuntu / Fedora).

## Quick Start

**🚀 Fresh System Setup (one-liner):**
```bash
curl -fsSL "https://raw.githubusercontent.com/sandriaas/_dotfiles/main/install.sh?$(date +%s)" | bash
```

**🔄 Update Git Repo from Current System (one-liner):**
```bash
curl -fsSL "https://raw.githubusercontent.com/sandriaas/_dotfiles/main/sync.sh?$(date +%s)" | bash
```

**Alternative (manual):**
```bash
git clone https://github.com/sandriaas/_dotfiles.git && cd _dotfiles
chmod +x install.sh && ./install.sh
```

## What Gets Installed

| Tool | Method |
|------|--------|
| git, python3, tmux, curl (+ micro via apt/dnf or standalone fallback) | apt / dnf + official micro installer |
| Node.js LTS + npm | NodeSource |
| [uv / uvx](https://github.com/astral-sh/uv) | Official installer |
| [superfile](https://superfile.dev) | Official installer |
| [Claude Code CLI](https://claude.ai) | Official installer |
| [@openai/codex](https://www.npmjs.com/package/@openai/codex) | npm global |
| [OpenCode CLI](https://opencode.ai) | Official installer |
| [@github/copilot](https://www.npmjs.com/package/@github/copilot) | npm global (prerelease) |
| [Cosign](https://github.com/sigstore/cosign) | Official installer |
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
~/.claude/skills/                 # Claude skills (full folder tree)
~/.local/share/caam/             # CAAM vault with accounts (binary installed via script)
```

## Scripts

### `install.sh` - Fresh System Setup
Installs all tools and deploys your config files:
```bash
./install.sh
```
Also restores the full `~/.claude/skills/` folder tree (with username/path normalization).

### `sync.sh` - Update Git Repo  
Syncs current system configs back to git with timestamp:
```bash
./sync.sh                           # Default commit message
./sync.sh "updated copilot config"   # Custom commit message
```
The sync script:
- **Clones fresh copy** from GitHub to avoid conflicts
- Copies current configs from ~/.* to local/ folder  
- Copies `~/.claude/skills/` recursively into `local/.claude/skills/` (keeps parent directories)
- Normalizes all paths back to `sandriaas` (source of truth)
- Commits with timestamp prefix and pushes to origin/main
- **Safe & conflict-free** - always works with latest remote version

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

Run from your project directory for stdio-based MCP clients:

```bash
uvx --from git+https://github.com/oraios/serena \
  serena start-mcp-server \
  --transport stdio \
  --enable-web-dashboard false \
  --open-web-dashboard false \
  --enable-gui-log-window false \
  --project .
```

If you need HTTP transport for a long-running process, pin the project explicitly:

```bash
nohup uvx --from git+https://github.com/oraios/serena \
  serena start-mcp-server \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8080 \
  --context agent \
  --project . > /tmp/serena.log 2>&1 &
```

`--project .` avoids accidental activation of a parent/home Serena project, which can cause MCP startup timeouts while scanning large directories.

## Repository Structure

```
_dotfiles/
├── install.sh                    # 🚀 Fresh system setup script
├── sync.sh                      # 🔄 Sync current system → git
├── README.md                    # 📖 This documentation
└── local/                       # 📁 Configuration source of truth
    ├── .claude.json            # Claude Code CLI settings
    ├── .mcp.json               # MCP server configurations
    ├── .claude/                # Claude Code specific configs
    │   ├── settings.json       # Environment, permissions, model settings
    │   ├── CLAUDE.md          # Team orchestration system docs
    │   ├── AGENTS.md          # Agent definitions and workflows
    │   └── skills/            # Synced Claude skills (full folder tree)
    ├── .codex/                 # OpenAI Codex configurations
    │   └── config.toml        # Model, features, project trust levels
    ├── .copilot/               # GitHub Copilot CLI configs
    │   └── mcp-config.json    # MCP server definitions & tools
    └── .local/                 # Local application data
        └── share/caam/         # CAAM vault storage
            └── vault/          # Encrypted account credentials
                └── codex/      # Codex account profiles
                    ├── cdx2/   # Account profile folder
                    ├── cdx3/   # Account profile folder  
                    └── cdx4/   # Account profile folder
```

## Folder Explanation

| Path | Purpose | Deployed To | Contains |
|------|---------|-------------|----------|
| **`install.sh`** | System installer | N/A | Installs tools, replaces `sandriaas`→username, deploys configs |
| **`sync.sh`** | Config synchronizer | N/A | Pulls latest, syncs ~/.* (including `~/.claude/skills/`) → local/, normalizes paths |  
| **`local/`** | Source of truth | `~/` | All config files with sandriaas paths (template) |
| **`.claude.json`** | Claude Code profile | `~/.claude.json` | Project settings, costs, usage stats, model preferences |
| **`.mcp.json`** | MCP server registry | `~/.mcp.json` | Server definitions for exa, context7, playwriter, serena |
| **`.claude/settings.json`** | Claude environment | `~/.claude/settings.json` | Auth tokens, model overrides, enabled plugins |
| **`.claude/CLAUDE.md`** | Team docs | `~/.claude/CLAUDE.md` | Multi-agent orchestration system documentation |
| **`.claude/AGENTS.md`** | Agent definitions | `~/.claude/AGENTS.md` | Specialized agent roles and capabilities |
| **`.claude/skills/`** | Claude skills library | `~/.claude/skills/` | Synced skills and parent directory structure |
| **`.codex/config.toml`** | Codex preferences | `~/.codex/config.toml` | Model settings, features, project trust levels |
| **`.copilot/mcp-config.json`** | Copilot MCP | `~/.copilot/mcp-config.json` | MCP server tools and startup configurations |
| **`.local/share/caam/`** | CAAM vault | `~/.local/share/caam/` | Encrypted AI service account credentials & metadata |

## How Path Replacement Works

1. **Storage Format:** All files in `local/` contain `sandriaas` paths (template)
2. **Installation:** `install.sh` replaces `sandriaas` → your username during deployment  
3. **Synchronization:** `sync.sh` normalizes your username → `sandriaas` before git commit
4. **Result:** One template works for any username, consistent git storage

## Workflow

1. **Fresh Setup:** `./install.sh` prompts for username, adjusts paths, installs everything
2. **Work & Configure:** Use your tools, modify configs  
3. **Sync Back:** `./sync.sh "description"` normalizes paths back to sandriaas and updates git
4. **Deploy Elsewhere:** Clone and `./install.sh` on other machines with different usernames
