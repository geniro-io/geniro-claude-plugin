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
- **Frequency**: 3 (updated 2026-02-23)
- **Description**: Empty `catch {}` blocks with only comments hide debugging information. Also flagged in `execGhCommand` token resolution (api-agent) and `GraphRevisionNotificationHandler.handle()` which returned `[]` on any error with a generic message, causing WebSocket notifications to silently drop.
- **Correct approach**: At minimum add `console.warn()` or `logger.debug()` for non-critical errors. Include context (event type, entity ID) in error messages. If no logger is available, document why the catch is intentionally silent.
- **Agents affected**: both

### [2026-02-22] Issue: Unused constructor injections in services
- **Frequency**: 1 (7 instances found in single audit)
- **Description**: Services had `private readonly` constructor params that were never referenced as `this.<param>` anywhere in the class. Found in controllers, services, templates, and handlers.
- **Correct approach**: After any refactoring that removes method calls, verify all constructor injections are still used. Remove unused ones along with their import statements and spec mocks.
- **Agents affected**: api-agent

### [2026-02-23] Issue: Dead code from alternative API designs
- **Frequency**: 1
- **Description**: `createRedisIoAdapter` helper function was exported but never called (the sync callback constraint forced a different pattern). The unused function and its `environment` import remained as dead code.
- **Correct approach**: After choosing between alternative implementation approaches, delete the unused approach's code immediately. Don't leave exported-but-unused functions.
- **Agents affected**: api-agent

### [2026-02-24] Issue: Upsert ON CONFLICT overwrites set-once columns with null
- **Frequency**: 1
- **Description**: `ON CONFLICT DO UPDATE SET source = EXCLUDED.source` nulls out existing `source` when the new INSERT didn't provide a value. Caught in review before shipping.
- **Correct approach**: Only include columns in `ON CONFLICT ... DO UPDATE SET` that should ALWAYS be refreshed (e.g., `status`, `lastRunId`). Set-once columns (`source`, `metadata`, `createdBy`, `name`) must be excluded from the update list.
- **Agents affected**: api-agent

## Quality Trends

### [2026-02-23] Trend: Notification system complexity reduced
- **Details**: 8-hop chain → 4-hop chain, 9 handlers → 6, removed BullMQ (for notifications), removed EventEmitter, removed duplicate enum, removed serialization layer. Clean first-pass reviewer approval on the restructuring.
- **Action**: Continue applying this approach — periodically audit infrastructure choices (BullMQ, EventEmitter, etc.) to verify they still justify their complexity
