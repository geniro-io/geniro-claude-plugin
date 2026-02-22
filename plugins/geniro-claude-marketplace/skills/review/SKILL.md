---
name: review
description: "Review code changes in the Geniro codebase before they ship. Catches bugs, AI-generated code anti-patterns, architectural drift, missing tests, and requirements gaps. Use after implementing a feature, before committing, or to review a specific branch."
context: fork
agent: reviewer-agent
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
argument-hint: "[what to review — e.g., 'recent changes', 'the graph revision service', branch name]"
---

# Code Review

Review the following in the Geniro codebase:

$ARGUMENTS

## Context

The Geniro platform consists of two repositories:
- **geniro/** — NestJS API backend (TypeORM, Vitest, Zod DTOs)
- **geniro-web/** — React frontend (Vite, Ant Design, Refine, Socket.io)

## Your Task

1. **Identify what changed** — use `git diff`, `git status`, or read the specific files/areas mentioned.
2. **Read the project standards** — check `geniro/docs/code-guidelines.md`, `geniro/docs/testing.md`, and `geniro-web/claude.md`.
3. **Review every changed file** against correctness, architecture fit, code quality, and the AI-generated code anti-patterns checklist.
4. **Run `pnpm run full-check`** in the relevant repo(s) to independently verify builds and tests pass.
5. **Deliver a structured review** with verdict, required changes, and minor improvements.

Be thorough but pragmatic. Catch real problems, propose practical fixes, approve when it's good enough to ship.
