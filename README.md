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
```

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
│   └── .copilot/
├── sprites/            # Config profile: sprite
│   ├── .claude.json
│   ├── .mcp.json
│   ├── .claude/
│   ├── .codex/
│   └── .copilot/
└── README.md
```
