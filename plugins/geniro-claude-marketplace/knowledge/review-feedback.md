# Review Feedback Patterns

Recurring reviewer feedback. When the same issue appears multiple times, it becomes a rule for engineers to check proactively.

---

## Recurring Issues

### [2026-02-21] Issue: Cross-repo API response shape mismatch
- **Frequency**: 1
- **Description**: API returned `{ installations: [...] }` but web expected raw array `[...]`. The table received an object instead of array, breaking render.
- **Correct approach**: Always check the API controller return shape and match it exactly in the frontend types. Wrapped responses (`{ data: [...] }`) vs raw arrays are a common source of bugs.
- **Agents affected**: both

### [2026-02-21] Issue: Business logic in controllers
- **Frequency**: 1
- **Description**: Webhook handler had DB queries and iteration logic directly in the controller method
- **Correct approach**: Controllers should be thin — extract business logic into service methods. Controller parses input, service handles logic.
- **Agents affected**: api-agent

### [2026-02-21] Issue: Silent error swallowing in catch blocks
- **Frequency**: 2 (updated 2026-02-22)
- **Description**: Empty `catch {}` blocks with only comments hide debugging information. Also flagged in `execGhCommand` token resolution catch block (api-agent).
- **Correct approach**: At minimum add `console.warn()` or `logger.debug()` for non-critical errors so developers can see failures during development. If no logger is available, document why the catch is intentionally silent.
- **Agents affected**: both

## Quality Trends

<!-- High-level observations about code quality over time. Format:
### [date] Trend: <observation>
- **Details**: what's improving or declining
- **Action**: what to focus on
-->
