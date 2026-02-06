# _dotfiles

Dotfiles & tool installer for dev machines (Ubuntu / Fedora).

## Quick Start

```bash
git clone https://github.com/sandriaas/_dotfiles.git && cd _dotfiles
chmod +x install.sh && ./install.sh
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
| **CAAM** (AI Account Manager) | Binary + vault from dotfiles |

## Profiles

The installer auto-detects the current username:

- **`local/`** — configs for `sandriaas` (default)
- **`sprites/`** — configs for `sprite` (paths rewritten)

Config files deployed to `~/`:

```
~/.copilot/mcp-config.json
~/.codex/config.toml
~/.mcp.json
~/.claude.json
~/.claude/settings.json
~/.claude/CLAUDE.md
~/.claude/AGENTS.md
~/.local/bin/caam                # CAAM binary
~/.local/share/caam/             # CAAM vault with accounts
```

## CAAM (AI Account Manager)

CAAM manages multiple AI service accounts with automatic switching, rate limiting, and session management.

**Key Features:**
- **Multi-account management** for Codex, Claude, Gemini
- **Automatic profile switching** when rate limits hit
- **Secure vault storage** with OAuth token management
- **Usage tracking** and cost monitoring

**Common Commands:**
```bash
caam ls                    # List all profiles
caam status               # Show active profiles and health
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
├── install.sh          # Full installer script
├── local/              # Config profile: sandriaas
│   ├── .claude.json
│   ├── .mcp.json
│   ├── .claude/
│   ├── .codex/
│   ├── .copilot/
│   └── .local/
│       ├── bin/caam    # CAAM binary
│       └── share/caam/ # CAAM vault
├── sprites/            # Config profile: sprite
│   ├── .claude.json
│   ├── .mcp.json
│   ├── .claude/
│   ├── .codex/
│   ├── .copilot/
│   └── .local/
│       ├── bin/caam    # CAAM binary
│       └── share/caam/ # CAAM vault
└── README.md
```
