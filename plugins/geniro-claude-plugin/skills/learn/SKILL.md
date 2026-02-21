---
name: learn
description: "Manage the Geniro knowledge base. View accumulated learnings, add new entries manually, search for specific knowledge, or clean up stale entries. Use after discovering something useful about the codebase, or to review what the system has learned."
model: sonnet
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
argument-hint: "[add/view/search/cleanup] [details]"
---

# Knowledge Base Manager

You manage the Geniro agents' accumulated knowledge stored in `geniro-claude-plugin/knowledge/`.

## Knowledge Files

- `api-learnings.md` — API backend patterns, gotchas, test patterns, useful commands
- `web-learnings.md` — Web frontend patterns, gotchas, component patterns, useful commands
- `architecture-decisions.md` — Significant design choices with context and rationale
- `review-feedback.md` — Recurring reviewer feedback patterns and quality trends

## Commands

Parse `$ARGUMENTS` to determine the action:

### `view` (or no arguments)
Read and summarize all knowledge files. Present a concise overview:
- Total entries per file
- Most recent entries (last 5)
- Most impactful entries (high-frequency gotchas, critical decisions)

### `add <description>`
Interactively add a new knowledge entry:
1. Determine the best file based on the description
2. Determine the appropriate section within that file
3. Get today's date via `date +%Y-%m-%d`
4. Format the entry following the file's template
5. Append using the Edit tool

### `search <query>`
Search across all knowledge files for entries matching the query:
```bash
grep -in -B2 -A5 "<query>" geniro-claude-plugin/knowledge/*.md
```
Present results grouped by file. Show the full entry (from `### [` header to the next `###` or end of section) for each match.

### `cleanup`
Review all knowledge files and:
1. Remove entries that are no longer accurate (check against current codebase)
2. Merge duplicate or overlapping entries
3. Update frequency counts on recurring issues
4. Archive entries older than 6 months that haven't been referenced
5. Report what was cleaned up

### `stats`
Provide analytics on the knowledge base:
- Entries per file and section
- Most common gotcha categories
- Architecture decisions timeline
- Review feedback frequency analysis
- Knowledge growth over time

## Entry Quality Rules

When adding entries:
- Be specific and actionable — vague entries waste context
- Include file paths and concrete details
- Use today's date for timestamping
- Keep entries to 3-5 lines max
- If a similar entry exists, update it instead of duplicating
- For gotchas, always include the prevention/fix

## Format

Always use the section's comment template. Example for a gotcha:

```markdown
### [2025-01-15] Gotcha: TypeORM migration ordering
- **What happened**: Migration failed because column was referenced before creation
- **Root cause**: Two migrations generated in wrong order due to entity circular dependency
- **Fix/Workaround**: Manually reorder migration timestamps
- **Prevention**: Always check migration order after generating multiple related migrations
```
