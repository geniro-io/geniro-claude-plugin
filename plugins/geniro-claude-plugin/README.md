# Geniro Claude Plugin

Multi-agent orchestrator plugin for the Geniro platform. Provides a full development pipeline with **self-improving knowledge**: architect designs the plan, engineers implement it, reviewer catches problems, and the system learns from every task.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    /orchestrate                           │
│                (Pipeline Controller)                      │
│                                                          │
│  0. Load knowledge base (past learnings)                 │
│  1. Architect analyzes & designs spec                    │
│  2. User reviews & approves the plan                     │
│  3. Engineers implement (API + Web in parallel)           │
│  4. Reviewer checks quality before shipping              │
│  5. Fix loop if needed, then deliver summary             │
│  6. Extract & save learnings to knowledge base           │
└───┬──────────┬──────────────┬──────────┬─────────────────┘
    │          │              │          │
┌───▼────┐ ┌──▼───────┐ ┌────▼─────┐ ┌──▼───────────┐
│architect│ │ api-agent │ │web-agent │ │reviewer-agent│
│ (opus) │ │  (opus)   │ │  (opus)  │ │   (opus)     │
│        │ │           │ │          │ │              │
│ Explore│ │ NestJS    │ │ React    │ │ Code review  │
│ Design │ │ TypeORM   │ │ AntDesign│ │ AI patterns  │
│ Plan   │ │ Vitest    │ │ Refine   │ │ Architecture │
│ Specify│ │ geniro/   │ │geniro-web│ │ Test quality │
└────────┘ └───────────┘ └──────────┘ └──────────────┘
                    │
              ┌─────▼─────┐
              │ knowledge/ │  Persistent learnings
              │            │  fed back into every
              │ Patterns   │  future task
              │ Gotchas    │
              │ Decisions  │
              │ Feedback   │
              └────────────┘
```

## Installation

From the parent directory containing both `geniro/` and `geniro-web/`:

```bash
claude plugin add ./geniro-claude-plugin
```

## Available Commands

### `/geniro-claude-plugin:orchestrate [feature description]`

The main entry point. Runs the full pipeline: load knowledge → architect → user approval → implement → review → deliver → save learnings.

**Example:**
```
/geniro-claude-plugin:orchestrate Add a GraphRevisionProgress WebSocket event that shows per-node rebuild progress during live updates
```

### `/geniro-claude-plugin:plan [task description]`

Run just the architect to produce an implementation-ready specification without executing it.

**Example:**
```
/geniro-claude-plugin:plan Add per-graph concurrency with locks to the revision queue
```

### `/geniro-claude-plugin:api-task [task description]`

Directly run a backend-only task in `geniro/`. Skips architect and reviewer.

**Example:**
```
/geniro-claude-plugin:api-task Add retention pruning to graph-revision.service.ts — delete revisions older than the last 50 per graph
```

### `/geniro-claude-plugin:web-task [task description]`

Directly run a frontend-only task in `geniro-web/`. Skips architect and reviewer.

**Example:**
```
/geniro-claude-plugin:web-task Add a progress bar to the revision applying toast that shows completedNodes/totalNodes
```

### `/geniro-claude-plugin:review [what to review]`

Run the reviewer on any changes.

**Examples:**
```
/geniro-claude-plugin:review recent changes to the graph revision service
/geniro-claude-plugin:review all uncommitted changes
```

### `/geniro-claude-plugin:learn [add/view/search/cleanup/stats]`

Manage the knowledge base manually. View accumulated learnings, add entries, search, or clean up stale knowledge.

**Examples:**
```
/geniro-claude-plugin:learn view
/geniro-claude-plugin:learn add TypeORM migrations must be run before integration tests when schema changes
/geniro-claude-plugin:learn search WebSocket
/geniro-claude-plugin:learn cleanup
/geniro-claude-plugin:learn stats
```

## Model Configuration

| Component | Model | Rationale |
|-----------|-------|-----------|
| Orchestrator | Sonnet | Coordination logic — fast and cost-effective |
| Architect | Opus | Deep analysis and design require strongest reasoning |
| API Agent | Opus | Complex implementation with strict quality bar |
| Web Agent | Opus | Complex implementation with strict quality bar |
| Reviewer | Opus | Thorough code review requires deep understanding |
| Learn Manager | Sonnet | Knowledge CRUD — straightforward operations |

## Self-Improvement System

The plugin maintains a persistent knowledge base in `geniro-claude-plugin/knowledge/` that grows with every task.

### How It Works

1. **Before each task** (Phase 0) — the orchestrator reads all knowledge files and extracts entries relevant to the current task
2. **During delegation** — relevant knowledge is passed to agents as "Knowledge Context" so they can avoid known pitfalls and follow proven patterns
3. **After each task** (Phase 6) — the orchestrator reviews the full execution (architect spec, engineer reports, reviewer feedback) and extracts new learnings
4. **Agents contribute** — engineers and reviewer report discoveries in their output, which the orchestrator saves

### What Gets Captured

- **Patterns** — reusable approaches for specific feature areas (API and Web separately)
- **Gotchas** — things that went wrong, with root cause and prevention
- **Architecture decisions** — significant design choices with context and rationale
- **Review feedback** — recurring issues with frequency tracking
- **Useful commands** — non-obvious CLI workflows
- **Test patterns** — effective testing approaches for specific scenarios
- **Component patterns** — reusable UI patterns (Web)

### Knowledge Files

| File | Contents |
|------|----------|
| `api-learnings.md` | API patterns, gotchas, test patterns, commands |
| `web-learnings.md` | Web patterns, gotchas, component patterns, commands |
| `architecture-decisions.md` | Design choices with rationale and consequences |
| `review-feedback.md` | Recurring reviewer findings, quality trends |

## Agents

| Agent | Role | Works In | Specialization |
|-------|------|----------|---------------|
| `architect-agent` | Design | Both repos | Codebase analysis, implementation specs, risk assessment, test scenarios |
| `api-agent` | Implement | `geniro/` | NestJS services, TypeORM entities, Zod DTOs, Vitest tests, migrations |
| `web-agent` | Implement | `geniro-web/` | React components, Refine hooks, Ant Design UI, Socket.io events |
| `reviewer-agent` | Quality gate | Both repos | Code review, AI-pattern detection, architecture fit, test quality |

## Full Pipeline Flow

```
You describe a feature
        │
        ▼
┌─────────────────┐
│  0. KNOWLEDGE    │  Load accumulated learnings. Pass relevant
│                  │  context to all downstream agents.
└────────┬────────┘
         ▼
┌─────────────────┐
│  1. ARCHITECT    │  Explores both codebases, designs minimal changes,
│                  │  produces file-level spec with test scenarios.
│                  │  References past architecture decisions.
└────────┬────────┘
         ▼
┌─────────────────┐
│  2. USER REVIEW  │  You see the plan: scope, risk, files, approach.
│                  │  Approve, request changes, or reject.
└────────┬────────┘
         ▼
┌─────────────────┐
│  3. IMPLEMENT    │  api-agent + web-agent work from the spec.
│                  │  Receive relevant knowledge context.
│                  │  Each runs pnpm run full-check before reporting.
│                  │  Report new learnings discovered during work.
└────────┬────────┘
         ▼
┌─────────────────┐
│  4. REVIEW       │  reviewer-agent checks all changes against spec,
│                  │  coding standards, and AI anti-pattern checklist.
│                  │  Flags recurring issues from past feedback.
│                  │  ❌ Changes required → fix loop back to step 3
│                  │  ✅ Approved → proceed
└────────┬────────┘
         ▼
┌─────────────────┐
│  5. DELIVER      │  Final build verification, summary report with
│                  │  files changed, decisions, manual steps, risks.
└────────┬────────┘
         ▼
┌─────────────────┐
│  6. LEARN        │  Extract patterns, gotchas, decisions, and
│                  │  feedback from the entire execution. Save to
│                  │  knowledge base for future tasks.
└─────────────────┘
```

## Plugin Structure

```
geniro-claude-plugin/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/
│   ├── architect-agent.md       # Architect: analyze & design specs
│   ├── api-agent.md             # Engineer: API backend
│   ├── web-agent.md             # Engineer: Web frontend
│   └── reviewer-agent.md        # Reviewer: quality gate
├── hooks/
│   └── hooks.json               # Lifecycle hooks (empty — agents self-enforce)
├── knowledge/                   # Persistent self-improvement knowledge base
│   ├── api-learnings.md         # API patterns, gotchas, commands
│   ├── web-learnings.md         # Web patterns, gotchas, components
│   ├── architecture-decisions.md # Design choices with rationale
│   └── review-feedback.md       # Recurring reviewer findings
├── skills/
│   ├── orchestrate/
│   │   └── SKILL.md             # Full pipeline command
│   ├── plan/
│   │   └── SKILL.md             # Architect-only command
│   ├── api-task/
│   │   └── SKILL.md             # Direct API task command
│   ├── web-task/
│   │   └── SKILL.md             # Direct Web task command
│   ├── review/
│   │   └── SKILL.md             # Direct review command
│   └── learn/
│       └── SKILL.md             # Knowledge base management
├── settings.json                # Default permissions
└── README.md
```
