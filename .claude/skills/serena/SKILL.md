---
name: serena
description: Prefer Serena MCP semantic tools (symbols/editing) over grep/rg/manual file scanning.
---

# Serena (Prefer Semantic Tools)

Use this skill whenever you need to **find code** or **edit code** in a non-trivial codebase.

## Core rule

Prefer Serena MCP tools (symbol-aware) over:
- grep/rg/mgrep keyword hunting
- reading whole files to find a function/class
- doing manual string replacements

Only fall back to grep/rg/mgrep when Serena cannot find the target (e.g. generated files, config formats not supported, or missing language server support).

## What to use (in order)

### Discovery / navigation
- `get_symbols_overview` (fast structure)
- `find_symbol` (go to the exact function/class/type)
- `find_referencing_symbols` (who calls/uses it)

### Searching
- `search_for_pattern` (when you truly need text/pattern search)
- `find_file` (when you need a file by name)

### Editing (prefer symbol edits)
- `replace_symbol_body` (change implementation safely)
- `insert_before_symbol` / `insert_after_symbol` (add helpers/import-adjacent code)
- `replace_regex` (only when symbol edits are impossible)

### File ops
- `read_file`, `list_dir`, `create_text_file`

## Operating guidelines

1. Start by locating the symbol with `find_symbol` instead of searching for a filename.
2. When changing code, use `replace_symbol_body` (or insert-before/after) rather than editing arbitrary line ranges.
3. When you need callsites or impact analysis, use `find_referencing_symbols` before making edits.
4. If a Serena call fails because the project isn’t active, activate the current project (when applicable).
