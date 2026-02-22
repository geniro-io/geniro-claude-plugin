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

### Step 2: Discover, write, and run ALL related integration tests
- **Discover related tests** — search `src/__tests__/integration/` for existing test files that cover the feature modules you modified:
  ```bash
  find src/__tests__/integration/ -name "*.int.ts" | grep -i "<feature>"
  grep -rl "YourChangedService\|YourChangedDao" src/__tests__/integration/
  ```
- **Create/update integration tests** (`.int.ts`) in `src/__tests__/integration/<feature>/` if none exist or existing tests don't cover the new/changed behavior
- Test the complete business workflow through direct service calls: happy path + 2-3 edge/error cases
- Follow existing patterns in `src/__tests__/integration/` (use `createTestModule` from `setup.ts`)
- **Run EVERY related integration test file individually** — not just the ones you created:
  ```bash
  cd geniro && pnpm test:integration src/__tests__/integration/<feature>/<test>.int.ts
  ```
- **The task is NOT done until ALL related integration tests pass.**

### Report back with:
- Files created/modified
- Key decisions made
- Unit test results (`pnpm run full-check` pass/fail + test count)
- Integration tests: ALL related test files discovered, which were run, which were created/updated, and pass/fail results for each
- Any issues or follow-ups
