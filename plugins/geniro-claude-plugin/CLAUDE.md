# Geniro Claude Plugin — Development Guidelines

## Scripts (use these, don't do it manually)

Three scripts in `scripts/` automate versioning, building, and releasing:

### `./scripts/bump-version.sh [patch|minor|major]`
Bumps version in `marketplace.json` (the single source of truth for versioning).
Note: `plugin.json` does NOT contain a version field — per Claude docs, relative-path plugins must manage version only via marketplace.json.

```bash
./scripts/bump-version.sh patch   # 1.2.1 → 1.2.2 (bug fixes, wording)
./scripts/bump-version.sh minor   # 1.2.1 → 1.3.0 (new features, behavior changes)
./scripts/bump-version.sh major   # 1.2.1 → 2.0.0 (breaking changes)
```

### `./scripts/build.sh`
Packages the plugin into a `.zip` file (zip archive) in `dist/` for local upload via Claude Desktop.

```bash
./scripts/build.sh
# → dist/geniro-claude-marketplace-1.3.0.zip
```

### `./scripts/release.sh [patch|minor|major] "commit message"`
Full release pipeline: bumps version → builds .zip → commits → pushes.

```bash
./scripts/release.sh minor "feat: add Playwright visual verification"
# Bumps version, builds .zip, commits, pushes to origin/main
```

## Plugin Structure

```
geniro-claude-marketplace/
├── .claude-plugin/marketplace.json    # Marketplace catalog (root)
├── scripts/                           # Build & release scripts
│   ├── build.sh                       # Package .zip file
│   ├── bump-version.sh                # Bump version in marketplace.json
│   └── release.sh                     # Full release pipeline
├── dist/                              # Build output (gitignored)
└── plugins/geniro-claude-plugin/      # The actual plugin
    ├── .claude-plugin/plugin.json     # Plugin manifest
    ├── CLAUDE.md                      # This file
    ├── agents/                        # Agent definitions (.md)
    │   ├── architect-agent.md         # Design & exploration
    │   ├── api-agent.md               # Backend implementation
    │   ├── web-agent.md               # Frontend implementation
    │   ├── reviewer-agent.md          # Code review & quality gate
    │   ├── skeptic-agent.md           # Spec validation (mirage detection)
    │   ├── security-auditor-agent.md  # OWASP security review
    │   ├── completeness-validator-agent.md  # Requirements traceability
    │   └── test-reviewer-agent.md     # Test quality evaluation
    ├── skills/                        # Skill definitions (SKILL.md)
    │   ├── orchestrate/               # Full pipeline command
    │   ├── plan/                      # Architect-only command
    │   ├── api-task/                  # Direct API task command
    │   ├── web-task/                  # Direct Web task command
    │   ├── review/                    # Direct review command
    │   ├── learn/                     # Knowledge base management
    │   ├── spec/                      # Requirements interview
    │   ├── skeptic/                   # Standalone spec validation
    │   ├── security-audit/            # Standalone security audit
    │   └── validate-knowledge/        # Knowledge base health check
    ├── hooks/hooks.json               # Hook configurations
    ├── knowledge/                     # Persistent knowledge base
    ├── settings.json                  # Permission settings
    └── README.md                      # Documentation
```

## Key Conventions

- **Orchestrator** (sonnet) — coordinates only, never explores code. Delegates all exploration to the architect.
- **Architect** (opus) — explores codebases, produces specs with execution waves, implements minor improvements directly.
- **API/Web agents** (opus) — implement code following the architect's spec.
- **Reviewer** (opus) — reviews code with security checklist, loops with implementing agents until approved.
- **Skeptic** (opus) — validates architect specs against real codebase before user sees them. Catches hallucinated paths/functions.
- **Security Auditor** (opus) — OWASP Top 10 review during Phase 4, runs alongside reviewer.
- **Completeness Validator** (opus) — requirements traceability check during Phase 1b, runs alongside skeptic.
- **Test Reviewer** (opus) — test quality evaluation during Phase 4, runs alongside reviewer.
- **Knowledge base** — files in `knowledge/` persist across sessions. Paths in skills reference `geniro-claude-marketplace/plugins/geniro-claude-plugin/knowledge/` (relative to the project root CWD).
