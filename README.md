# _dotfiles

Dotfiles & tool installer for dev machines (Ubuntu / Fedora / Windows).

## Quick Start

### Linux (Ubuntu / Fedora)

**🚀 Fresh System Setup (one-liner):**
```bash
sudo rm -f /etc/apt/sources.list.d/yarn.list; curl -fsSL "https://raw.githubusercontent.com/sandriaas/_dotfiles/main/install.sh?$(date +%s)" | DOTFILES_APT_UPDATE=1 bash
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

### Windows (PowerShell)

**⚙️ Install MCP Configs Only (one-liner):**
```powershell
git clone --depth 1 https://github.com/sandriaas/_dotfiles.git "$env:TEMP\_dotfiles-mcp"; & "$env:TEMP\_dotfiles-mcp\install-mcp-windows.ps1" -Force; Remove-Item -Recurse -Force "$env:TEMP\_dotfiles-mcp"
```

## What Gets Installed

| Tool | Method |
|------|--------|
| git, python3, tmux (+ micro via apt/dnf or standalone fallback) | apt / dnf + official micro installer |
| GitHub CLI (gh) | Official GitHub CLI repo (apt/dnf) |
| Node.js LTS + npm | NodeSource |
| Bun | Official installer |
| [uv / uvx](https://github.com/astral-sh/uv) | Official installer |
| [superfile](https://superfile.dev) | Official installer |
| [Claude Code CLI](https://claude.ai) | Official installer |
| [@openai/codex](https://www.npmjs.com/package/@openai/codex) | npm global |
| [OpenCode CLI](https://opencode.ai) | Official installer |
| [@github/copilot](https://www.npmjs.com/package/@github/copilot) | npm global (prerelease) |
| [Cosign](https://github.com/sigstore/cosign) | Official installer |
| **CAAM** (AI Account Manager) | Bundled binary from `local/.local/bin/caam` (fallback: official installer) |
| **claude (worktree fix)** | Bundled script from `local/.local/bin/claude` — re-enables `--worktree`/`-w` when `tengu_worktree_mode` FF is off |

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
~/.claude/settings.json.copilotapi
~/.claude/CLAUDE.md
~/.claude/AGENTS.md
~/.claude/hooks/subagent-start-marker.js
~/.claude/skills/                 # Claude skills (full folder tree)
~/.opencode/plugins/subagent-marker.js
~/.local/bin/caam                # Bundled CAAM binary (Linux x86_64)
~/.local/bin/claude             # claude --worktree fix wrapper
```

## Scripts

### `install.sh` - Fresh System Setup (Linux)
Installs all tools and deploys your config files:
```bash
./install.sh
```
Also restores the full `~/.claude/skills/` folder tree (with username/path normalization).

Debian/Ubuntu note:
- Recommended before install:
```bash
sudo rm -f /etc/apt/sources.list.d/yarn.list
```
- To run with refreshed package indexes:
```bash
DOTFILES_APT_UPDATE=1 ./install.sh
```

### `install-mcp-windows.ps1` - MCP Config Setup (Windows)
Deploys only MCP server configurations to Windows:
```powershell
.\install-mcp-windows.ps1 -Force    # Overwrites existing (creates backups)
.\install-mcp-windows.ps1 -DryRun   # Preview changes without writing
```
Deploys:
- `~\.copilot\mcp-config.json` (GitHub Copilot CLI)
- `~\.mcp.json` (Claude Code)
- `~\.claude\settings.json` (Claude environment)
- `~\.codex\config.toml` (OpenAI Codex)

### `sync.sh` - Update Git Repo (Linux)
Syncs current system configs back to git with timestamp:
```bash
./sync.sh                           # Default commit message
./sync.sh "updated copilot config"   # Custom commit message
```
The sync script:
- **Clones fresh copy** from GitHub to avoid conflicts
- Copies current configs from ~/.* to local/ folder  
- Copies `~/.claude/skills/` recursively into `local/.claude/skills/` (keeps parent directories)
- Copies `~/.local/bin/caam` into `local/.local/bin/caam` to bundle CAAM in repo
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

## claude `--worktree` fix wrapper

The `--worktree` / `-w` flag is gated behind a remote feature flag (`tengu_worktree_mode`)
that defaults to off. `local/.local/bin/claude` is a thin shim that implements the
worktree lifecycle in shell — version-independent, no binary patching required.

Deploy (one-time):

```bash
[ -x ~/.local/bin/claude ] && mv ~/.local/bin/claude ~/.local/bin/claude.real
install -m 755 local/.local/bin/claude ~/.local/bin/claude
```

Usage is identical to the intended built-in flag:

```bash
claude --worktree          # anonymous worktree (HEAD)
claude -w my-feature       # named worktree
```

The wrapper creates a `git worktree` in `~/.cache/claude-worktrees/<name>`,
runs claude inside it, and removes the worktree on exit. All other `claude` invocations
pass through unchanged via `exec`.

## Copilot API Proxy (`@jeffreycao/copilot-api`)

Uses your GitHub Copilot subscription as a local Anthropic-compatible API proxy, routing Claude Code (and OpenCode) requests through Copilot's backend instead of the Anthropic API.

**Start the proxy:**
```bash
npx @jeffreycao/copilot-api@latest start --claude-code --github-token
```

Runs on `http://localhost:4141`. The included `settings.json` is pre-configured to point there (`ANTHROPIC_BASE_URL=http://localhost:4141`, `ANTHROPIC_AUTH_TOKEN=dummy`).

**Usage dashboard:**
[https://ericc-ch.github.io/copilot-api?endpoint=http://localhost:4141/usage](https://ericc-ch.github.io/copilot-api?endpoint=http://localhost:4141/usage)

### Subagent Marker Integration

The `SubagentStart` hook in `settings.json` injects an agent-identity marker into each subagent's context so multi-agent orchestration (team spawning, swarms) works correctly when routed through the proxy. An equivalent plugin is provided for OpenCode.

- **Claude Code hook:** `~/.claude/hooks/subagent-start-marker.js`
- **OpenCode plugin:** `~/.opencode/plugins/subagent-marker.js`

A standalone copilot-api-only settings preset is also included at `~/.claude/settings.json.copilotapi` for reference.

**References:**
- [npm: `@jeffreycao/copilot-api`](https://npmx.dev/package/@jeffreycao/copilot-api)
- [copilot-api: subagent marker integration](https://github.com/caozhiyuan/copilot-api/tree/all?tab=readme-ov-file#subagent-marker-integration-optional)
- [opencode issue #8030 — subagent marker context](https://github.com/anomalyco/opencode/issues/8030#issuecomment-3744968418)

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
    │   ├── settings.json       # Environment, permissions, model settings (copilot-api preset)
    │   ├── settings.json.copilotapi  # Standalone copilot-api settings reference
    │   ├── CLAUDE.md          # Team orchestration system docs
    │   ├── AGENTS.md          # Agent definitions and workflows
    │   ├── hooks/             # Claude Code event hooks
    │   │   └── subagent-start-marker.js  # Injects agent identity for proxied subagents
    │   └── skills/            # Synced Claude skills (full folder tree)
    ├── .opencode/              # OpenCode configurations
    │   └── plugins/           # OpenCode plugins
    │       └── subagent-marker.js  # Subagent marker plugin for OpenCode
    ├── .codex/                 # OpenAI Codex configurations
    │   └── config.toml        # Model, features, project trust levels
    ├── .copilot/               # GitHub Copilot CLI configs
    │   └── mcp-config.json    # MCP server definitions & tools
    └── .local/                 # Local application data
        └── bin/
            ├── caam            # Bundled CAAM binary (Linux x86_64)
            └── claude          # claude --worktree fix wrapper
```

## Folder Explanation

| Path | Purpose | Deployed To | Contains |
|------|---------|-------------|----------|
| **`install.sh`** | System installer | N/A | Installs tools, replaces `sandriaas`→username, deploys configs |
| **`sync.sh`** | Config synchronizer | N/A | Pulls latest, syncs ~/.* (including `~/.claude/skills/`) → local/, normalizes paths |  
| **`local/`** | Source of truth | `~/` | All config files with sandriaas paths (template) |
| **`.claude.json`** | Claude Code profile | `~/.claude.json` | Project settings, costs, usage stats, model preferences |
| **`.mcp.json`** | MCP server registry | `~/.mcp.json` | Server definitions for exa, context7, playwriter, serena |
| **`.claude/settings.json`** | Claude environment | `~/.claude/settings.json` | Auth tokens, model overrides, enabled plugins; pre-configured for copilot-api proxy |
| **`.claude/settings.json.copilotapi`** | Copilot-API preset | `~/.claude/settings.json.copilotapi` | Standalone reference config for copilot-api mode |
| **`.claude/hooks/`** | Claude Code hooks | `~/.claude/hooks/` | `subagent-start-marker.js` — injects agent identity into subagent contexts |
| **`.claude/CLAUDE.md`** | Team docs | `~/.claude/CLAUDE.md` | Multi-agent orchestration system documentation |
| **`.claude/AGENTS.md`** | Agent definitions | `~/.claude/AGENTS.md` | Specialized agent roles and capabilities |
| **`.claude/skills/`** | Claude skills library | `~/.claude/skills/` | Synced skills and parent directory structure |
| **`.opencode/plugins/`** | OpenCode plugins | `~/.opencode/plugins/` | `subagent-marker.js` — subagent marker plugin for OpenCode sessions |
| **`.codex/config.toml`** | Codex preferences | `~/.codex/config.toml` | Model settings, features, project trust levels |
| **`.copilot/mcp-config.json`** | Copilot MCP | `~/.copilot/mcp-config.json` | MCP server tools and startup configurations |
| **`.local/bin/caam`** | CAAM binary | `~/.local/bin/caam` | Bundled CAAM binary for Linux x86_64 |

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
