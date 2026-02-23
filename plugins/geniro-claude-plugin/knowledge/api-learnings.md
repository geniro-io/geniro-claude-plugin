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

### [2026-02-23] Pattern: SimpleEnrichmentHandler for structurally identical notification handlers
- **Context**: 3 notification handlers (graph, graph-node-update, agent-state-update) had identical logic: look up owner, spread event, add scope
- **Pattern**: Single `SimpleEnrichmentHandler` with `pattern = [Event1, Event2, Event3]` array. Uses `resolveExternalThreadId()` for the one handler that needed `parentThreadId` resolution. All others pass through unchanged.
- **Where**: `v1/notification-handlers/services/event-handlers/simple-enrichment-handler.ts`
- **Applies to**: When 3+ handlers share identical structure, consolidate into one configurable handler with a pattern array

### [2026-02-23] Pattern: Synchronous in-process notification dispatch (no BullMQ)
- **Context**: BullMQ was used as in-process pub/sub for notifications with concurrency 1 and a single subscriber — overkill
- **Pattern**: Simple `NotificationsService` with a `subscribers[]` array. `emit()` calls subscribers sequentially with per-subscriber error isolation. No Redis connection, no serialization overhead.
- **Where**: `v1/notifications/services/notifications.service.ts`
- **Applies to**: In-process event dispatch where you don't need distributed processing, retry, or persistence. BullMQ should be reserved for actual distributed job queues (like `GraphRevisionQueueService`).

### [2026-02-23] Gotcha: `buildHttpServerExtension` callback is synchronous
- **Context**: Tried to `await createRedisIoAdapter(app)` inside the `appChangeCb` in `main.ts`
- **Detail**: The `buildHttpServerExtension` callback signature is `(app: INestApplication) => INestApplication` — synchronous. Cannot use `async/await` directly.
- **Fix/Workaround**: Fire-and-forget with `void adapter.connectToRedis()`. Document the race window (single-instance mode until Redis connects).
- **Applies to**: Any async initialization that needs to happen in the `appChangeCb` callback

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

### [2026-02-22] Pattern: Eliminating unnecessary forwardRef in NestJS modules
- **Context**: Refactored all `forwardRef` and `ModuleRef` usage across the codebase
- **Detail**: Many `forwardRef(() => SomeModule)` imports exist from earlier code but are no longer needed. Check if Module A actually DI-injects providers from Module B at the NestJS level (not just TypeScript type imports). If only types/static methods/`new` are used, the module import is unnecessary. `ModuleRef.resolve(X, ..., { strict: false })` works globally without needing the provider's module imported.
- **Applies to**: Any module cleanup or circular dependency investigation

### [2026-02-22] Pattern: Replace ModuleRef.create() with constructor injection for singletons
- **Context**: Notification handlers used `moduleRef.create(ThreadsService)` to get a service instance per call
- **Detail**: `ModuleRef.create()` instantiates a new instance each invocation — wasteful for singletons. If the service has no request-scoped dependencies in its constructor chain, use direct constructor injection instead. The module already imports the provider's module, so DI works.
- **Applies to**: Any handler or service using `moduleRef.create()` or `moduleRef.resolve()` for singleton-scoped providers

### [2026-02-22] Gotcha: Unused constructor injections accumulate silently
- **Context**: Found 7 unused `private readonly` injections across the codebase during refactoring audit
- **Detail**: TypeScript/NestJS don't warn about injected-but-unused constructor params. These add unnecessary DI overhead and confuse readers about actual dependencies. Common after refactoring methods out of a service.
- **Prevention**: After removing method calls from a service, check if the injected dependency is still used. Grep for `this.<paramName>` in the class body.

### [2026-02-23] Gotcha: Docker runtime containers are lazy-started, not during graph.run()
- **Context**: Resources integration test timed out because `beforeAll` included a warmup that started Docker
- **Detail**: `graph.run()` only compiles the graph and registers nodes. Docker containers start lazily when the first thread triggers `runtimeProvider.provide()`. Any "warmup" that starts Docker must happen as a trigger execution, not during graph setup. Keep `beforeAll` lightweight (module + graph creation only) and let the test itself handle Docker cold-start within its own timeout.
- **Applies to**: Any integration test that uses Docker runtimes

### [2026-02-23] Gotcha: Suppressing init script output hides failures
- **Context**: Docker runtime init script used `>/dev/null 2>&1`, causing "Init failed:" with no diagnostic info
- **Detail**: `docker-runtime.ts` `runInitScript` reports `"Init failed: ${res.stderr || res.stdout}"`. If both are suppressed, the error is just "Init failed:" with zero context.
- **Prevention**: Never suppress stdout/stderr in test init scripts. Remove `>/dev/null 2>&1` redirects during testing.
- **Applies to**: Writing or debugging Docker runtime init scripts in integration tests

### [2026-02-23] Pattern: Use pre-built Docker images + binary downloads in integration tests
- **Context**: `python:3.11-slim` + 7-step `apt-get` gh install took 60-90s; switched to `node:20` + `curl | tar` (~3s)
- **Detail**: For integration tests needing CLI tools, use a Docker image with prerequisites pre-installed (`node:20` has `curl`, `git`, `tar`) and download binaries directly from GitHub releases. Avoids apt repo setup overhead entirely. Test time dropped from ~130s to ~23s.
- **Applies to**: Any integration test that installs tools inside Docker containers

### [2026-02-23] Gotcha: Notification emissions inside uncommitted transactions silently fail
- **What happened**: WebSocket revision notifications never arrived at the frontend despite correct wiring
- **Root cause**: `notificationsService.emit()` was called inside `typeorm.trx()`. The enrichment handler queries the DB outside the transaction, gets null/stale results, and silently returns `[]` — dropping the notification.
- **Fix**: Move `notificationsService.emit()` calls to AFTER `typeorm.trx()` returns (transaction committed). Return post-commit data from the transaction callback so the caller can emit outside.
- **Prevention**: Never emit notifications inside `typeorm.trx()`. If a method is called from inside a transaction, return data and let the outermost caller emit after commit.

### [2026-02-23] Pattern: Post-commit notification emission via return values
- **Context**: `queueRevision()` is called both standalone and from within outer transactions (`graphs.service.ts update()`)
- **Pattern**: When no outer `entityManager` is provided, `queueRevision` owns its transaction and emits after commit. When an outer `entityManager` is passed, it returns post-commit data and the caller emits after their outer transaction commits. Use structured return values (`{ response, postCommit }`) to flow data out of transactions.
- **Where**: `graph-revision.service.ts`, `graphs.service.ts`
- **Applies to**: Any notification emission that might be nested inside transactions
