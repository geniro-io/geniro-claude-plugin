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
└── plugins/geniro-claude-marketplace/      # The actual plugin
    ├── .claude-plugin/plugin.json     # Plugin manifest
    ├── CLAUDE.md                      # This file
    ├── agents/                        # Agent definitions (.md)
    ├── skills/                        # Skill definitions (SKILL.md)
    ├── hooks/hooks.json               # Hook configurations
    ├── knowledge/                     # Persistent knowledge base
    ├── settings.json                  # Permission settings
    └── README.md                      # Documentation
```

## Key Conventions

- **Orchestrator** (sonnet) — coordinates only, never explores code. Delegates all exploration to the architect.
- **Architect** (opus) — explores codebases, produces specs, implements minor improvements directly.
- **API/Web agents** (opus) — implement code following the architect's spec.
- **Reviewer** (opus) — reviews code, loops with implementing agents until approved.
- **Knowledge base** — files in `knowledge/` persist across sessions. Paths in skills reference `geniro-claude-marketplace/plugins/geniro-claude-marketplace/knowledge/` (relative to the project root CWD).
