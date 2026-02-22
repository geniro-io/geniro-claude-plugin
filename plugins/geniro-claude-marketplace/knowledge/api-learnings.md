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

### [2026-02-21] Pattern: Always use enums for option/type fields
- **Context**: `authMethod` was initially `'pat' | 'github_app'` string union — user flagged this should be an enum
- **Rule**: Any field that represents a fixed set of options (auth methods, statuses, modes, kinds) **must** use a TypeScript `enum` with explicit string values, not inline string literals or union types
- **How**: Create enum in a shared types file (e.g., `<feature>.types.ts`), use `z.nativeEnum(MyEnum)` in Zod schemas, reference `MyEnum.Value` everywhere instead of `'value'`
- **Naming**: Enum members use PascalCase per project lint rules (e.g., `GithubApp`, not `GITHUB_APP`), string values stay lowercase for serialization
- **Applies to**: Every new feature with categorical/option fields — auth methods, resource kinds, statuses, modes, strategies

### [2026-02-22] Pattern: Per-command GH_TOKEN injection via execGhCommand
- **Context**: GitHub App tokens are short-lived and owner-specific; can't be set once at init time
- **Pattern**: `execGhCommand` resolves a token via `resolveToken(config, owner)` and injects it as `GH_TOKEN` env var per-command. Combined with a git credential helper (configured in init script) that reads `GH_TOKEN` at runtime for `git push`.
- **Where**: `agent-tools/tools/common/github/gh-base.tool.ts`, `graph-resources/services/github-resource.ts`
- **Usage**: Any new shell-based GitHub tool that needs auth should pass `owner` to `execGhCommand` — token injection happens automatically

### [2026-02-22] Pattern: Extract owner from git remote URL for token resolution
- **Context**: `gh_push` tool doesn't have `owner` in its schema, but needs it for GitHub App token resolution
- **Pattern**: Run `git remote get-url <remote>` to get the URL, parse owner with regex matching both HTTPS (`github.com/owner/`) and SSH (`github.com:owner/`) formats. Run in `Promise.all` with other pre-checks to avoid sequential latency.
- **Where**: `agent-tools/tools/common/github/gh-push.tool.ts`
- **Usage**: Any tool that operates on a git repo and needs to resolve owner dynamically

## Gotchas & Pitfalls

### [2026-02-21] Gotcha: `getEnv()` without default returns `undefined` at runtime but `string` in TypeScript
- **What happened**: `getEnv('GITHUB_APP_ID')` has TS overload returning `string`, but returns `undefined` when env var is unset
- **Root cause**: The `getEnv(env: string): string` overload signature lies — it can return `undefined`
- **Fix/Workaround**: Use `Boolean()` checks before consuming the value. Don't chain `.replace()` or `.split()` on values that might be `undefined`
- **Prevention**: Always guard with `Boolean(val)` or `val || ''` before string operations on optional env vars

### [2026-02-22] Gotcha: `resolveToken` vs `resolveTokenForOwner` — silent failures
- **What happened**: `resolveToken` in `gh-base.tool.ts` can throw when neither App token nor PAT is available. In `execGhCommand`, this is caught silently so local git ops still work.
- **Root cause**: The base tool class has no logger — can't log warnings about token resolution failures
- **Fix/Workaround**: The catch block is intentional. If auth-required commands fail, the runtime error message from `gh`/`git` is clear enough. Future improvement: add a logger to `GhBaseTool`.
- **Prevention**: When adding new tools, be aware that `execGhCommand` may proceed without `GH_TOKEN` — don't assume auth is always available

### [2026-02-22] Gotcha: `resolveTokenForOwner` only matches exact `accountLogin` — misses cross-account access
- **What happened**: Clone of `geniro-io/geniro` failed even with GitHub App configured, because the only installation in the DB was for `RazumRu` (personal), not `geniro-io` (org)
- **Root cause**: `resolveTokenForOwner(owner)` filtered by `accountLogin = owner`. When no exact match, returned null, so no `GH_TOKEN` was set.
- **Fix**: Added fallback in `resolveTokenForOwner` — if no exact `accountLogin` match, try ANY active installation for the user. GitHub's API enforces actual repo access permissions, so the fallback token either works or fails with a clear 403.
- **Prevention**: When resolving tokens by owner, always have a fallback strategy. Don't assume 1:1 mapping between installation `accountLogin` and repo owner.

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
