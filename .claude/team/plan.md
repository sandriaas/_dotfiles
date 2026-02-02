# Claude TeamSwarms - Unified Multi-Agent Orchestration System

**Created:** 2026-01-29
**Status:** Planning Phase
**Sources:** claude-sneakpeek, OMO, OMC, claude-flow/teammate-plugin

---

## Vision

Merge the power of three systems into one unified "god-tier" multi-agent framework:

1. **claude-sneakpeek** → Team Mode architecture (`.claude/team/` folder, Team Lead + Workers, task management)
2. **OMO (oh-my-claudecode)** → 32 specialized agents, SQLite swarm coordination, skills system
3. **OMC (oh-my-opencode)** → Atlas orchestrator, mailbox communication, background agents

**End Result:** A centralized teams-based system where OMO's 32 agents operate as team members under `.claude/team/` with expertise markdown files, enhanced with OMC's superior patches.

---

## Folder Structure (Matching Images)

```
.claude/
└── team/
    ├── backend.md              # Backend Engineer expertise
    ├── db-expert.md            # Database Expert expertise
    ├── frontend.md             # Frontend Engineer expertise
    ├── architect.md            # From OMO - architecture/debugging
    ├── architect-low.md        # Haiku tier
    ├── architect-medium.md     # Sonnet tier
    ├── executor.md             # From OMO - task implementation
    ├── executor-low.md         # Haiku tier
    ├── executor-high.md        # Opus tier
    ├── designer.md             # UI/UX specialist
    ├── designer-low.md         # Haiku tier
    ├── designer-high.md        # Opus tier
    ├── qa-tester.md            # QA specialist
    ├── qa-tester-high.md       # Opus tier
    ├── security-reviewer.md    # Security specialist (Opus)
    ├── security-reviewer-low.md # Haiku tier
    ├── code-reviewer.md        # Code review specialist (Opus)
    ├── code-reviewer-low.md    # Haiku tier
    ├── researcher.md           # Documentation research
    ├── researcher-low.md       # Haiku tier
    ├── explore.md              # Fast codebase search (Haiku)
    ├── explore-medium.md       # Sonnet tier
    ├── explore-high.md         # Opus tier
    ├── writer.md               # Technical documentation (Haiku)
    ├── vision.md               # Image/screenshot analysis
    ├── critic.md               # Critical plan review (Opus)
    ├── analyst.md              # Requirements analysis (Opus)
    ├── planner.md              # Strategic planning (Opus)
    ├── scientist.md            # Data analysis
    ├── scientist-low.md        # Haiku tier
    ├── scientist-high.md       # Opus tier
    ├── build-fixer.md          # Build error fixing
    ├── build-fixer-low.md      # Haiku tier
    ├── tdd-guide.md            # Test-driven development
    └── tdd-guide-low.md        # Haiku tier
```

**Total: 32 agents from OMO + 3 core team roles = unified team folder**

---

## How It Works (From Images)

### Swarm Mode = WHOLE TEAM

1. **Team Lead** (you - always spawned) - manages the rest of the team
2. **Database Expert** - reads `.claude/team/db-expert.md`
3. **Backend Engineer** - reads `.claude/team/backend.md`
4. **Frontend Engineer** - reads `.claude/team/frontend.md`
5. **...any other team members you want**

### Team's Expertise

Team members get expertise through:
- **Prompts** - direct instructions
- **Markdown files** - `.claude/team/{role}.md` defines each member's expertise and skills

### Team Communication = EXCELLENT

- Whole team talks through a **communication channel**
- Everyone has their **own inbox** (send/receive messages)
- **No task overlaps** - everyone stays in sync
- **Queued teammate messages** visible in UI

### Swarm Mode <-> Subagents

- Sub-agents work **in parallel**
- Goal: **speed up** while staying **fully in sync** and **keeping context**

---

## Agent Expertise File Format

Each `.claude/team/{role}.md` file:

```markdown
# Backend Engineer

## Identity
You are the Backend Senior Engineer on this team.

## Expertise
- REST API design and implementation
- Database integration (PostgreSQL, MongoDB)
- Authentication/authorization (JWT, OAuth2)
- Microservices architecture
- Performance optimization
- Error handling and logging

## Skills to Load
- executor (primary implementation)
- security-reviewer (for auth code)
- build-fixer (for errors)

## Model Tier
sonnet (default) | opus (complex architecture)

## Communication
- Reports to: Team Lead
- Collaborates with: DB Expert, Frontend Engineer
- Inbox: .claude/team/inboxes/backend/

## Working Style
- Write clean, documented code
- Follow existing patterns in codebase
- Write tests for new functionality
- Verify with build before completing
```

---

## Integration Plan

### Phase 1: Create Team Folder with All 32 Agents
- [ ] Create `.claude/team/` structure
- [ ] Migrate all 32 OMO agent definitions to markdown files
- [ ] Add 3 core team roles (backend, frontend, db-expert)
- [ ] Each file defines expertise, skills, model tier

### Phase 2: Communication System (From OMC Mailbox)
- [ ] Create inbox folders: `.claude/team/inboxes/{role}/`
- [ ] Implement message protocol from OMC
- [ ] Add queued teammate messages feature
- [ ] Create team communication channel log

### Phase 3: Swarm Coordination (From OMO)
- [ ] Port SQLite swarm system
- [ ] Implement atomic task claiming
- [ ] Add heartbeat monitoring
- [ ] Create task storage: `.claude/team/tasks/`

### Phase 4: Team Lead / Orchestrator
- [ ] Merge Atlas (OMC) + Conductor (claude-sneakpeek)
- [ ] Always spawned, manages team
- [ ] Reads all agent expertise files
- [ ] Assigns tasks based on expertise
- [ ] Verifies completion

### Phase 5: OMC Patches Integration
- [ ] todo-continuation-enforcer (forces completion)
- [ ] comment-checker (clean code)
- [ ] ralph-loop (persistence until verified)
- [ ] context-injector (auto-inject expertise)
- [ ] session-recovery (resume interrupted work)
- [ ] delegate-task-retry (retry failures)

### Phase 6: Skills System
- [ ] Port all 37 OMO skills
- [ ] Map skills to team roles
- [ ] Skills loaded per-agent based on `.md` file

### Phase 7: Model Routing
- [ ] Haiku (-low suffix) - simple/fast tasks
- [ ] Sonnet (default) - standard implementation
- [ ] Opus (-high suffix) - complex reasoning

### Phase 8: Testing & Documentation
- [ ] Test multi-agent scenarios
- [ ] Verify communication channel
- [ ] Document usage

---

## Spawn Command

```
Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer
```

This triggers:
1. Team Lead spawns (always)
2. Reads `.claude/team/db-expert.md` → spawns DB Expert
3. Reads `.claude/team/backend.md` → spawns Backend Engineer
4. Reads `.claude/team/frontend.md` → spawns Frontend Engineer
5. Opens communication channel
6. Team works in parallel, stays in sync

---

## Additional Understanding from claude-flow/teammate-plugin

The teammate-plugin provides the **TeammateToolBridge** - the native API for Claude Code v2.1.19+ swarm/team mode:

### Core TeammateTool Operations (13 operations)
| Operation | Description |
|-----------|-------------|
| `spawnTeam` | Create a new team |
| `discoverTeams` | List existing teams |
| `requestJoin` | Request to join a team |
| `approveJoin` / `rejectJoin` | Handle join requests |
| `write` | Send direct message to teammate |
| `broadcast` | Send message to all teammates |
| `requestShutdown` | Request teammate termination |
| `approveShutdown` / `rejectShutdown` | Handle shutdown |
| `approvePlan` / `rejectPlan` | Vote on plans |
| `cleanup` | Clean up resources |

### Team Storage Structure (~/.claude/teams/)
```
~/.claude/teams/
├── my-team/
│   ├── config.json        # Team configuration
│   ├── state.json         # Team state (teammates, plans)
│   ├── remote.json        # Remote session info
│   ├── mailbox/
│   │   ├── teammate-1.json
│   │   └── teammate-2.json
│   └── memory/
│       ├── teammate-1.json
│       └── teammate-2.json
```

### Key Types
```typescript
interface TeammateSpawnConfig {
  name: string;
  role: string;
  prompt: string;
  model?: 'sonnet' | 'opus' | 'haiku';
  allowedTools?: string[];
  mode?: 'acceptEdits' | 'bypassPermissions' | 'default' | 'delegate' | 'dontAsk' | 'plan';
  teamName?: string;
  runInBackground?: boolean;
}

interface TeamConfig {
  name: string;
  topology: 'flat' | 'hierarchical' | 'mesh';
  maxTeammates: number;
  planModeRequired: boolean;
  autoApproveJoin: boolean;
  delegationEnabled: boolean;
}
```

### Features We Can Use
- **Delegation**: Delegate authority between teammates
- **Team Context**: Shared variables, permissions, environment
- **Session Memory**: Persist context across sessions
- **Teleport**: Resume teams across terminal instances
- **Plan Control**: Pause, resume, modify plans mid-execution
- **Mailbox**: Per-teammate inbox with message types (task, result, status, plan, approval)

---

## Updated Architecture

### Final Folder Structure (combining all sources)
```
.claude/
├── team/                           # Team member expertise (from images)
│   ├── backend.md                  # Backend engineer
│   ├── db-expert.md                # Database expert
│   ├── frontend.md                 # Frontend engineer
│   ├── architect.md                # From OMO
│   ├── executor.md                 # From OMO
│   ├── ... (all 32 OMO agents)
│   └── plan.md                     # This file
│
├── teams/                          # Active teams (from teammate-plugin)
│   └── {team-name}/
│       ├── config.json             # Team config
│       ├── state.json              # Team state
│       ├── mailbox/                # Per-teammate mailboxes
│       │   ├── team-lead.json
│       │   ├── backend.json
│       │   └── frontend.json
│       └── memory/                 # Session memory
│
└── settings.local.json             # Claude Code settings
```

### How Team Spawning Works

1. **User says**: "Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer"

2. **Team Lead spawns** (always first) with `spawnTeam`:
   ```typescript
   bridge.spawnTeam({
     name: 'project-team',
     topology: 'hierarchical',
     maxTeammates: 6,
     planModeRequired: true,
   });
   ```

3. **Read expertise files** from `.claude/team/`:
   - `.claude/team/db-expert.md` → database expert prompt
   - `.claude/team/backend.md` → backend engineer prompt
   - `.claude/team/frontend.md` → frontend engineer prompt

4. **Spawn each teammate** with expertise:
   ```typescript
   bridge.spawnTeammate({
     name: 'backend-engineer',
     role: 'coder',
     prompt: readFile('.claude/team/backend.md'),
     model: 'sonnet',
     allowedTools: ['Edit', 'Write', 'Read', 'Bash'],
     teamName: 'project-team',
   });
   ```

5. **Communication channel opens** - each teammate gets mailbox
6. **Team works in parallel** - no task overlaps, stays in sync

---

## Success Criteria

1. ✅ `.claude/team/` folder with all agent expertise files
2. ✅ Team Lead always spawned, manages others
3. ✅ Each team member has inbox for messages
4. ✅ Communication channel for team coordination
5. ✅ Swarm coordination - no task overlaps
6. ✅ All 32 OMO agents available as team members
7. ✅ OMC patches working (persistence, recovery, etc.)
8. ✅ Model tiering (Haiku/Sonnet/Opus) based on task

---

## Current State

```
D:\claude_teamswarms\
├── .claude/
│   └── team/           ← CREATED (matches images!)
│       └── plan.md     ← This file
├── claude-sneakpeek/   ← Cloned
├── OMO/                ← Cloned (oh-my-claudecode)
└── OMC/                ← Cloned (oh-my-opencode)
```

---

## Next Steps

1. Start implementing Phase 1 - create all 32 agent `.md` files
2. Copy OMO agent prompts into team folder format
3. Set up communication inboxes

---

## CLAUDE.md Implementation Plan

### Primary Deliverable: `CLAUDE.md` at Project Root

**Location:** `D:\claude_teamswarms\CLAUDE.md`

This file instructs Claude how to use the unified team system.

### CLAUDE.md Structure

```markdown
# CLAUDE.md - Team Orchestration System

## Quick Start
"Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer and tech lead."

Team members are defined inside the `.claude/team` directory, in markdown files.

## Magic Keywords
[table of all 15 keywords]

## Spawn Commands
[syntax for spawning]

## Communication
[mailbox protocol]

## Working Modes
[ultrawork, ralph, autopilot, swarm, etc.]
```

---

## Magic Keywords (from OMO keyword-detector)

| Priority | Keyword | Pattern | Effect |
|----------|---------|---------|--------|
| 1 | `cancel` | stop, cancel, abort | Stop current operation |
| 2 | `ralph` | ralph, don't stop, must complete, until done | Self-loop until completion |
| 3 | `autopilot` | autopilot, autonomous, full auto, fullsend | Full autonomous mode |
| 4 | `ultrapilot` | ultrapilot, parallel build, swarm build | Parallel swarm build |
| 5 | `ultrawork` | ultrawork, ulw, uw | Parallel + TODO tracking |
| 6 | `ecomode` | eco, ecomode, efficient, budget | Token-efficient mode |
| 7 | `swarm` | swarm N agents, coordinated agents | Launch N coordinated agents |
| 8 | `pipeline` | pipeline, chain agents | Sequential agent chain |
| 9 | `ralplan` | ralplan | Ralph + planning |
| 10 | `plan` | plan this, plan the | Planning mode |
| 11 | `tdd` | tdd, test first, red green | Test-driven development |
| 12 | `research` | research, analyze data, statistics | Research mode |
| 13 | `ultrathink` | ultrathink, think hard, think deeply | Deep thinking |
| 14 | `deepsearch` | deepsearch, search codebase | Deep codebase search |
| 15 | `analyze` | deep analyze, investigate, debug | Deep analysis |

### Phrase Patterns (trigger autopilot)
- "build me a..." / "create me a..." / "make me a..."
- "I want a/an..."
- "handle it all" / "end to end" / "e2e this"

---

## Ultrawork Mode Rules (from OMO)

When `ultrawork` or `ulw` detected:

1. **PARALLEL**: Fire independent calls simultaneously - NEVER wait sequentially
2. **BACKGROUND FIRST**: Use Task(run_in_background=true) for exploration (10+ concurrent)
3. **TODO**: Track EVERY step. Mark complete IMMEDIATELY after each
4. **VERIFY**: Check ALL requirements met before done
5. **NO Premature Stopping**: ALL TODOs must be complete

Persistence: State stored at `.omc/state/ultrawork-state.json` and `~/.claude/ultrawork-state.json`

---

## Ralph Loop Rules (from OMC)

When `ralph` detected:

1. Self-referential work loop
2. Continues until `<promise>{completion_promise}</promise>` detected in output
3. Max iterations configurable (default: infinite until done)
4. Tracks iteration count
5. Can link with ultrawork mode

---

## All 32 Agent Expertise Files

### Base Agents (16)
| File | Purpose | Default Model |
|------|---------|---------------|
| `architect.md` | System architecture, debugging | OPUS |
| `executor.md` | Task implementation | SONNET |
| `researcher.md` | Documentation research | HAIKU |
| `explore.md` | Fast codebase search | HAIKU |
| `designer.md` | UI/UX design | SONNET |
| `writer.md` | Technical documentation | HAIKU |
| `vision.md` | Image/screenshot analysis | SONNET |
| `critic.md` | Critical review | OPUS |
| `analyst.md` | Requirements analysis | OPUS |
| `planner.md` | Strategic planning | OPUS |
| `qa-tester.md` | Testing, quality | SONNET |
| `scientist.md` | Data analysis, experiments | OPUS |
| `backend.md` | Backend/API development | SONNET |
| `frontend.md` | Frontend/UI development | SONNET |
| `db-expert.md` | Database design, queries | SONNET |
| `tech-lead.md` | Team coordination | OPUS |

### Tiered Variants (16+)
- `*-low.md` → HAIKU tier (fast/cheap)
- `*-medium.md` → SONNET tier (balanced)
- `*-high.md` → OPUS tier (premium reasoning)

Examples:
- `architect-low.md`, `architect-medium.md` (architect-high = default architect)
- `executor-low.md`, `executor-high.md` (executor = medium)
- etc.

---

## Implementation Status: ✅ COMPLETE

### Phase 1: CLAUDE.md ✅
- [x] Create `D:\claude_teamswarms\CLAUDE.md`
- [x] Quick start section with spawn example
- [x] Magic keywords table (all 15)
- [x] Spawn commands syntax
- [x] Communication protocol
- [x] Ultrawork rules
- [x] Ralph loop behavior
- [x] Model tiers explanation

### Phase 2: Agent Expertise Files ✅ (37 files created)
- [x] `architect.md` + `architect-low.md` + `architect-high.md`
- [x] `executor.md` + `executor-low.md` + `executor-high.md`
- [x] `researcher.md` + `researcher-low.md`
- [x] `explore.md` + `explore-medium.md` + `explore-high.md`
- [x] `designer.md` + `designer-low.md` + `designer-high.md`
- [x] `writer.md`
- [x] `vision.md`
- [x] `critic.md`
- [x] `analyst.md`
- [x] `planner.md`
- [x] `qa-tester.md` + `qa-tester-high.md`
- [x] `scientist.md` + `scientist-low.md` + `scientist-high.md`
- [x] `code-reviewer.md` + `code-reviewer-low.md`
- [x] `security-reviewer.md` + `security-reviewer-low.md`
- [x] `build-fixer.md` + `build-fixer-low.md`
- [x] `tdd-guide.md` + `tdd-guide-low.md`
- [x] `backend.md`
- [x] `frontend.md`
- [x] `db-expert.md`
- [x] `tech-lead.md`

### Phase 3: Communication System
- [ ] Create `.claude/teams/` structure (runtime - created on first spawn)
- [ ] Mailbox folders (runtime)
- [ ] Memory persistence (runtime)

---

## 🎉 IMPLEMENTATION COMPLETE

### Files Created Summary:

| Category | Count | Files |
|----------|-------|-------|
| Core Team | 4 | backend, frontend, db-expert, tech-lead |
| OMO Agents | 16 | architect, executor, researcher, explore, designer, writer, vision, critic, analyst, planner, qa-tester, scientist, code-reviewer, security-reviewer, build-fixer, tdd-guide |
| Tiered Variants | 17 | *-low, *-medium, *-high versions |
| **Total** | **37** | agent expertise files |

### Usage

```bash
# Spawn the core team
"Spawn the whole team: database expert, back-end senior engineer, front-end senior engineer and tech lead"

# Use magic keywords
"ultrawork: implement feature X"
"ralph: keep going until complete"
"swarm 4 agents to build the dashboard"

# Use specific agents
"Spawn architect to review the design"
"Spawn executor-low for quick task"
"Spawn scientist-high for deep analysis"
```

### System is ready for use!
