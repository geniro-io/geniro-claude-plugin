# Geniro Claude Plugin — Development Guidelines

## Version Bumping

### `./scripts/bump-version.sh [patch|minor|major]`
Bumps version in `marketplace.json` (the single source of truth for versioning).
Note: `plugin.json` does NOT contain a version field — per Claude docs, relative-path plugins must manage version only via marketplace.json.

```bash
./scripts/bump-version.sh patch   # 1.2.1 → 1.2.2 (bug fixes, wording)
./scripts/bump-version.sh minor   # 1.2.1 → 1.3.0 (new features, behavior changes)
./scripts/bump-version.sh major   # 1.2.1 → 2.0.0 (breaking changes)
```

### IMPORTANT: Do NOT build, release, or update the plugin

The LLM must **never** run `build.sh`, `release.sh`, `update-plugin.sh`, or any command that builds, packages, releases, or reinstalls the plugin locally. Only the human operator handles plugin release and local installation. The LLM's responsibility ends at bumping the version and committing the code changes.

## Plugin Structure

```
geniro-claude-marketplace/
├── .claude-plugin/marketplace.json    # Marketplace catalog (root)
├── scripts/
│   └── bump-version.sh                # Bump version in marketplace.json
└── plugins/geniro-claude-plugin/      # The actual plugin
    ├── .claude-plugin/plugin.json     # Plugin manifest
    ├── CLAUDE.md                      # This file
    ├── agents/                        # Agent definitions (.md)
    │   ├── architect-agent.md         # Design & exploration
    │   ├── api-agent.md               # Backend implementation
    │   ├── web-agent.md               # Frontend implementation
    │   ├── dist-agent.md              # Distribution / Helm chart (geniro-dist/)
    │   ├── reviewer-agent.md          # Code review & quality gate
    │   ├── skeptic-agent.md           # Spec validation (mirage detection)
    │   ├── security-auditor-agent.md  # OWASP security review
    │   ├── completeness-validator-agent.md  # Requirements traceability
    │   ├── test-reviewer-agent.md     # Test quality evaluation
    │   └── cleanup-agent.md           # Post-pipeline garbage cleanup
    ├── skills/                        # Skill definitions (SKILL.md)
    │   ├── orchestrate/               # Full pipeline command
    │   ├── new-feature/               # Feature spec creation via interview
    │   ├── features/                  # Feature backlog management
    │   ├── plan/                      # Architect-only command
    │   ├── api-task/                  # Direct API task command
    │   ├── web-task/                  # Direct Web task command
    │   ├── dist-task/                 # Direct Dist task command
    │   ├── review/                    # Direct review command
    │   ├── learn/                     # Knowledge base management
    │   ├── spec/                      # Requirements interview (ad-hoc)
    │   ├── skeptic/                   # Standalone spec validation
    │   ├── security-audit/            # Standalone security audit
    │   └── validate-knowledge/        # Knowledge base health check
    ├── hooks/hooks.json               # Hook configurations
    ├── settings.json                  # Permission settings
    └── README.md                      # Documentation
```

## Key Conventions

- **Orchestrator** (sonnet) — coordinates only, never explores code. Delegates all exploration to the architect.
- **Architect** (opus) — explores codebases, produces specs with execution waves, implements minor improvements directly.
- **API/Web agents** (opus) — implement code following the architect's spec.
- **Dist agent** (inherit/opus) — manages Helm charts, Kubernetes deployment config, and dependency versions in `geniro-dist/`. Uses web search to verify latest versions and best practices.
- **Reviewer** (opus) — reviews code with security checklist, loops with implementing agents until approved.
- **Skeptic** (opus) — validates architect specs against real codebase before user sees them. Catches hallucinated paths/functions.
- **Security Auditor** (opus) — OWASP Top 10 review during Phase 4, runs alongside reviewer.
- **Completeness Validator** (opus) — requirements traceability check during Phase 1b, runs alongside skeptic.
- **Test Reviewer** (opus) — test quality evaluation during Phase 4, runs alongside reviewer.
- **Cleanup Agent** (haiku) — runs at the end of Phase 6, detects and removes leftover screenshots, temp files, and stops lingering servers.
- **Feature backlog** — feature specs live in `.claude/project-features/` (created on first use). Completed features are archived to `.claude/project-features/completed/`. Create with `/new-feature`, manage with `/features`, implement with `/orchestrate feature: <name>`.
- **Knowledge base** — accumulated learnings persist across sessions in `.claude/project-knowledge/`:
  - `.claude/project-knowledge/api-learnings.md` — API patterns, gotchas, commands
  - `.claude/project-knowledge/web-learnings.md` — Web patterns, gotchas, components
  - `.claude/project-knowledge/architecture-decisions.md` — Design choices with rationale
  - `.claude/project-knowledge/review-feedback.md` — Recurring reviewer findings
