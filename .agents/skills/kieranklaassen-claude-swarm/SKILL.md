---
name: kieranklaassen-claude-swarm
description: Master multi-agent orchestration using Claude Code's TeammateTool and Task system. Use when coordinating multiple agents, running parallel code reviews, creating pipeline workflows with dependencies, building self-organizing task queues, or any task benefiting from divide-and-conquer patterns.
---

# Claude Code Swarm Orchestration

Master multi-agent orchestration using Claude Code's TeammateTool and Task system.

---

## Primitives

| Primitive | What It Is | File Location |
|-----------|-----------|---------------|
| **Agent** | A Claude instance that can use tools. You are an agent. Subagents are agents you spawn. | N/A (process) |
| **Team** | A named group of agents working together. One leader, multiple teammates. | `~/.claude/teams/{name}/config.json` |
| **Teammate** | An agent that joined a team. Has a name, color, inbox. Spawned via Task with `team_name` + `name`. | Listed in team config |
| **Leader** | The agent that created the team. Receives teammate messages, approves plans/shutdowns. | First member in config |
| **Task** | A work item with subject, description, status, owner, and dependencies. | `~/.claude/tasks/{team}/N.json` |
| **Inbox** | JSON file where an agent receives messages from teammates. | `~/.claude/teams/{name}/inboxes/{agent}.json` |
| **Message** | A JSON object sent between agents. Can be text or structured (shutdown_request, idle_notification, etc). | Stored in inbox files |
| **Backend** | How teammates run. Auto-detected: `in-process` (same Node.js, invisible), `tmux` (separate panes, visible), `iterm2` (split panes in iTerm2). | Auto-detected based on environment |

---

## Two Ways to Spawn Agents

### Method 1: Task Tool (Subagents)

Use Task for **short-lived, focused work** that returns a result:

```javascript
Task({
  subagent_type: "Explore",
  description: "Find auth files",
  prompt: "Find all authentication-related files in this codebase",
  model: "haiku"
})
```

### Method 2: Task Tool + team_name + name (Teammates)

```javascript
Teammate({ operation: "spawnTeam", team_name: "my-project" })

Task({
  team_name: "my-project",
  name: "security-reviewer",
  subagent_type: "general-purpose",
  prompt: "Review all authentication code for vulnerabilities. Send findings to team-lead.",
  run_in_background: true
})
```

---

## Orchestration Patterns

### Pattern 1: Parallel Specialists
Multiple specialists review code simultaneously — spawn all in one message.

### Pattern 2: Pipeline (Sequential Dependencies)
```javascript
TaskCreate({ subject: "Research" })   // #1
TaskCreate({ subject: "Implement" })  // #2
TaskCreate({ subject: "Test" })       // #3
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
TaskUpdate({ taskId: "3", addBlockedBy: ["2"] })
```

### Pattern 3: Swarm (Self-Organizing)
Workers grab available tasks from a shared pool — naturally load-balance.

### Pattern 4: Plan Approval Workflow
```javascript
Task({ team_name: "...", name: "architect", subagent_type: "Plan", mode: "plan", run_in_background: true })
// Receive plan_approval_request, then:
Teammate({ operation: "approvePlan", target_agent_id: "architect", request_id: "plan-xxx" })
```

---

## Shutdown Sequence

Always follow this order:
1. `requestShutdown` for all teammates
2. Wait for `shutdown_approved` messages
3. `cleanup` team resources

---

## Quick Reference

| Want to... | Do... |
|------------|-------|
| Spawn subagent (no team) | `Task({ subagent_type: "Explore", ... })` |
| Spawn teammate | `Teammate({ spawnTeam })` then `Task({ team_name, name, ... })` |
| Message teammate | `Teammate({ write, target_agent_id, value })` |
| Create pipeline | `TaskCreate` + `TaskUpdate({ addBlockedBy })` |
| Shutdown | `requestShutdown` → wait → `cleanup` |

---

*Source: https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea*
*Based on Claude Code v2.1.19 — verified 2026-01-25*
