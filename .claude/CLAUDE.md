# CLAUDE.md - Team Orchestration System

> **Unified Multi-Agent Framework** combining claude-sneakpeek + OMO + OMC

---

## Quick Start

```
Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer and tech lead.
```

**Team members are defined inside the `.claude/team` directory, in markdown files.**

---

## Magic Keywords

Say these keywords anywhere in your prompt to activate special modes:

| Keyword | Aliases | Effect |
|---------|---------|--------|
| **ultrawork** | `ulw`, `uw` | Parallel execution, background tasks, strict TODO tracking |
| **ralph** | `don't stop`, `must complete`, `until done` | Self-loop until task verified complete |
| **autopilot** | `autonomous`, `full auto`, `fullsend` | Full autonomous mode - minimal intervention |
| **ultrapilot** | `parallel build`, `swarm build` | Parallel swarm build mode |
| **swarm** | `swarm N agents`, `coordinated agents` | Launch N coordinated agents |
| **pipeline** | `chain agents` | Sequential agent chain |
| **ecomode** | `eco`, `efficient`, `budget` | Token-efficient mode |
| **plan** | `plan this`, `plan the` | Planning mode before execution |
| **ralplan** | - | Ralph + planning combined |
| **tdd** | `test first`, `red green` | Test-driven development |
| **research** | `analyze data`, `statistics` | Research/analysis mode |
| **ultrathink** | `think hard`, `think deeply` | Extended reasoning mode |
| **deepsearch** | `search codebase`, `find in code` | Deep codebase search |
| **analyze** | `deep analyze`, `investigate`, `debug` | Deep analysis/debugging |
| **cancel** | `stop`, `abort` | Stop current operation |

### Phrase Triggers (activate autopilot)
- "build me a..." / "create me a..." / "make me a..."
- "I want a..." / "I want an..."
- "handle it all" / "end to end" / "e2e this"

---

## Spawn Commands

### Single Agent
```
Spawn the backend engineer
Spawn architect to review this design
```

### Multiple Agents
```
Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer
Spawn: architect, executor, qa-tester
```

### Swarm Mode
```
swarm 4 agents to implement the authentication feature
ultrapilot: build the entire API
```

### With Model Tier
```
Spawn architect-high for complex system design
Spawn explore-low for quick file search
```

---

## Team Directory

All team member expertise files are in `.claude/team/`:

### Core Team
| File | Role | Model |
|------|------|-------|
| `tech-lead.md` | Team coordination, decisions | OPUS |
| `architect.md` | System design, architecture | OPUS |
| `backend.md` | Backend/API development | SONNET |
| `frontend.md` | Frontend/UI development | SONNET |
| `db-expert.md` | Database design, queries | SONNET |

### Specialists
| File | Role | Model |
|------|------|-------|
| `executor.md` | Task implementation | SONNET |
| `researcher.md` | Documentation research | HAIKU |
| `explore.md` | Fast codebase search | HAIKU |
| `designer.md` | UI/UX design | SONNET |
| `writer.md` | Technical documentation | HAIKU |
| `vision.md` | Image/screenshot analysis | SONNET |
| `critic.md` | Critical review | OPUS |
| `analyst.md` | Requirements analysis | OPUS |
| `planner.md` | Strategic planning | OPUS |
| `qa-tester.md` | Testing, quality assurance | SONNET |
| `scientist.md` | Data analysis, experiments | OPUS |

### Model Tiers
- **`-low`** suffix → HAIKU (fast, cheap, simple tasks)
- **`-medium`** suffix → SONNET (balanced)
- **`-high`** suffix → OPUS (complex reasoning)

Example: `architect-low.md`, `executor-high.md`

---

## Working Modes

### Ultrawork Mode (`ulw`)

Activated by: `ultrawork`, `ulw`, `uw`

**Rules:**
1. **PARALLEL** - Fire independent calls simultaneously, NEVER wait sequentially
2. **BACKGROUND FIRST** - Use `Task(run_in_background=true)` for exploration (10+ concurrent)
3. **TODO** - Track EVERY step, mark complete IMMEDIATELY after each
4. **VERIFY** - Check ALL requirements met before declaring done
5. **NO PREMATURE STOP** - ALL TODOs must be complete

**State persisted at:** `.omc/state/ultrawork-state.json`

### Ralph Loop Mode

Activated by: `ralph`, `don't stop`, `must complete`, `until done`

**Behavior:**
- Self-referential work loop
- Continues until completion verified
- Outputs `<promise>TASK COMPLETE</promise>` when truly done
- Tracks iteration count
- Can combine with ultrawork: `ralph ultrawork`

### Autopilot Mode

Activated by: `autopilot`, `autonomous`, `fullsend`

**Behavior:**
- Minimal user intervention
- Makes decisions autonomously
- Completes entire task end-to-end
- Only asks for critical clarifications

### Swarm Mode

Activated by: `swarm N agents`, `coordinated agents`

**Behavior:**
- Spawns N parallel agents
- Each agent works on subtask
- Coordination via communication channel
- No task overlaps - stays in sync

---

## Team Communication

### How It Works
1. **Team Lead** always spawned first - coordinates others
2. Each teammate has **own inbox** (send/receive messages)
3. **Communication channel** keeps everyone in sync
4. **No task overlaps** - work is distributed cleanly

### Message Types
- `task` - Assign work to teammate
- `result` - Report completed work
- `status` - Progress update
- `plan` - Proposed plan for approval
- `approval` - Vote on plans

### Mailbox Location
```
.claude/teams/{team-name}/mailbox/{teammate}.json
```

---

## Agent Expertise Format

Each `.claude/team/{role}.md` file contains:

```markdown
# {Role Name}

## Identity
You are the {Role} on this team.

## Expertise
- Skill 1
- Skill 2
- ...

## Model Tier
HAIKU | SONNET | OPUS

## Allowed Tools
Edit, Write, Read, Bash, Glob, Grep, ...

## Working Style
- How this agent approaches tasks
- Communication preferences
- Quality standards
```

---

## Quick Reference

| Want to... | Say... |
|------------|--------|
| Spawn full team | "Spawn the whole team: X, Y, Z" |
| Work until done | "ralph: implement feature X" |
| Parallel execution | "ultrawork: build the API" |
| Autonomous mode | "autopilot: create login system" |
| Multi-agent swarm | "swarm 4 agents: refactor codebase" |
| Quick search | "Spawn explore-low to find auth files" |
| Complex design | "Spawn architect-high for system design" |
| Token-efficient | "ecomode: fix this bug" |
| Test-driven | "tdd: implement user service" |

---

## File Structure

```
.claude/
├── team/                    # Agent expertise files
│   ├── architect.md
│   ├── backend.md
│   ├── frontend.md
│   ├── db-expert.md
│   ├── tech-lead.md
│   ├── executor.md
│   ├── ... (32 total)
│   └── plan.md              # Implementation plan
│
├── teams/                   # Active team sessions
│   └── {team-name}/
│       ├── config.json
│       ├── state.json
│       └── mailbox/
│
└── settings.local.json
```

---

## Examples

### Example 1: Build a Feature
```
ralph ultrawork: Build user authentication with JWT, including login, register, 
password reset, and email verification. Spawn backend and db-expert.
```

### Example 2: Review and Refactor
```
Spawn the whole team: architect, critic, qa-tester
Review the payment module for security issues and refactor for better performance.
```

### Example 3: Quick Exploration
```
Spawn explore-low to find all API endpoints in the codebase
```

### Example 4: Full Autonomous Build
```
autopilot: Build me a REST API for a todo app with PostgreSQL, 
including CRUD operations, user auth, and tests.
```

---

*Team members defined in `.claude/team/` • Magic keywords activate special modes • Ralph loops until done*
