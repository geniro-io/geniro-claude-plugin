# API Learnings

Accumulated knowledge about the Geniro API codebase (`geniro/`). Updated automatically after each task.

---

## Patterns Discovered

### [2026-02-21] Pattern: Optional feature modules with system settings
- **Context**: GitHub App feature needed to be conditionally available based on env vars
- **Pattern**: Create a `SystemModule` with `GET /system/settings` endpoint returning feature flags. The module imports the feature module and calls `isConfigured()` on the service. Frontend uses a `useSystemSettings` hook to gate UI.
- **Where**: `v1/system/system.controller.ts`, `v1/github-app/services/github-app.service.ts`
- **Usage**: Any new optional feature that depends on env var configuration

### [2026-02-21] Pattern: Token resolver abstraction for multi-auth
- **Context**: Needed to support both GitHub App tokens and PAT tokens for git operations
- **Pattern**: `GitHubTokenResolverService` sits between graph resource config and tool invocation. `resolveTokenForOwner(owner, userId, patToken)` tries App token first, falls back to PAT, returns null if neither available. Tools receive a `resolveTokenForOwner` callback via config.
- **Where**: `v1/github-app/services/github-token-resolver.service.ts`, `agent-tools/tools/common/github/gh-base.tool.ts`
- **Usage**: When adding new auth providers for git operations (e.g., GitLab, Bitbucket)

## Gotchas & Pitfalls

### [2026-02-21] Gotcha: `getEnv()` without default returns `undefined` at runtime but `string` in TypeScript
- **What happened**: `getEnv('GITHUB_APP_ID')` has TS overload returning `string`, but returns `undefined` when env var is unset
- **Root cause**: The `getEnv(env: string): string` overload signature lies — it can return `undefined`
- **Fix/Workaround**: Use `Boolean()` checks before consuming the value. Don't chain `.replace()` or `.split()` on values that might be `undefined`
- **Prevention**: Always guard with `Boolean(val)` or `val || ''` before string operations on optional env vars

### [2026-02-21] Gotcha: `DefaultLogger` uses `log()` not `info()`
- **What happened**: Called `this.logger.info()` which doesn't exist
- **Root cause**: The Pino-based `DefaultLogger` from `@packages/common` exposes `log`, `warn`, `error`, `debug` but not `info`
- **Fix/Workaround**: Use `this.logger.log()` instead
- **Prevention**: Check `DefaultLogger` interface before using

## Useful Commands & Shortcuts

<!-- Non-obvious commands or workflows discovered. Format:
### [date] <command/workflow name>
- **Command**: `exact command`
- **When to use**: context
- **Notes**: any caveats
-->

## Test Patterns

### [2026-02-21] Controller unit tests with direct instantiation
- **For**: Controllers using `@OnlyForAuthorized()` decorator
- **Approach**: Instantiate controller directly with `new Controller(mockDep1, mockDep2)` instead of `TestingModule`. Avoids DI issues with auth guards. Mock `AuthContextStorage` as `{ userId: '...' } as any`.
- **Example file**: `v1/github-app/controllers/github-app.controller.spec.ts`

### [2026-02-21] Zod schema with `.default()` requires explicit values in test code
- **For**: Testing code that uses Zod schemas with default values
- **Approach**: When constructing config objects inline (not via `.parse()`), the TypeScript output type makes defaulted fields required. Use `authMethod: 'pat' as const` in test objects.
- **Example file**: `v1/graph-templates/templates/resources/github-resource.template.spec.ts`
