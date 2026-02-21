---
name: api-task
description: "Execute a backend task in the Geniro API monorepo (NestJS). Use for creating endpoints, services, DAOs, entities, DTOs, writing tests, fixing backend bugs, or modifying business logic."
context: fork
agent: api-agent
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
argument-hint: "[task description]"
---

# API Task

Execute the following task in the **geniro/** monorepo:

$ARGUMENTS

## Before Starting

1. Read `geniro/docs/code-guidelines.md` and `geniro/docs/project-structure.md` for coding standards.
2. Read `geniro/docs/testing.md` for testing rules.
3. Search for related files using Glob/Grep to understand existing patterns.

## After Completing

Run the full project check and fix any issues:

```bash
cd geniro && pnpm run full-check
```

Report back with:
- Files created/modified
- Key decisions made
- Test results
- Any issues or follow-ups
