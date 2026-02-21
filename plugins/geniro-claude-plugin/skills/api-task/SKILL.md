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

### Step 1: Run full-check
```bash
cd geniro && pnpm run full-check
```
Fix any issues and re-run until it passes.

### Step 2: Write and run integration tests (MANDATORY for new features)
- Create integration tests (`.int.ts`) in `src/__tests__/integration/<feature>/`
- Test the complete business workflow through direct service calls: happy path + 2-3 edge/error cases
- Follow existing patterns in `src/__tests__/integration/` (use `createTestModule` from `setup.ts`)
- Run each integration test individually:
```bash
cd geniro && pnpm test:integration src/__tests__/integration/<feature>/<test>.int.ts
```
- **The task is NOT done until integration tests pass.**

### Report back with:
- Files created/modified
- Key decisions made
- Unit test results (`pnpm run full-check` pass/fail + test count)
- Integration test results (exact command run + pass/fail)
- Any issues or follow-ups
