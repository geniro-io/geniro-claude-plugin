# Architecture Decisions

Record of significant architecture decisions made during development. Each entry captures the context, decision, and rationale so future tasks can build on past choices consistently.

---

### [2026-02-21] Decision: GitHubTokenResolverService as token abstraction layer
- **Task**: GitHub App + PAT dual-auth for git operations
- **Context**: Tools needed a way to get the right token per-owner (org/user), with GitHub App preferred over PAT
- **Decision**: Created `GitHubTokenResolverService` that sits between graph resource config and tool invocation. Tools receive a `resolveTokenForOwner(owner)` callback via config.
- **Alternatives considered**: (1) Store App token on git_repositories entity — rejected (tokens are short-lived). (2) Generic credentials table — overengineering for single provider. (3) Fully lazy resolution — partially adopted, but init script needs a token at startup.
- **Rationale**: Keeps all existing tool code unchanged. Resolver injected at template layer (natural boundary). Can extend to GitLab/Bitbucket later.
- **Consequences**: New auth providers follow same pattern. `patToken` field is optional. Users can have both PAT and App tokens.

### [2026-02-22] Decision: Per-command env injection for short-lived tokens (not init script)
- **Task**: Fix GitHub App auth for shell-based git tools
- **Context**: GitHub App installation tokens are short-lived (~1hr) and owner-specific. Init script runs once at container start.
- **Decision**: Inject `GH_TOKEN` as env var per-command via `execGhCommand`, combined with a git credential helper in the init script that reads `GH_TOKEN` at runtime.
- **Alternatives considered**: (1) Resolve token in init script — rejected (expires, can't serve different owners). (2) URL rewriting per push (`git remote set-url`) — rejected (mutates repo state, token visible in `git remote -v`). (3) Per-command `--config credential.helper` flag — feasible but overly complex.
- **Rationale**: `GH_TOKEN` is idiomatic for both `gh` CLI and git credential helpers. Per-command injection means fresh tokens per operation. PAT flow (`gh auth login` in init) and App flow (credential helper + `GH_TOKEN`) are mutually exclusive and don't interfere.
- **Consequences**: All future tools using `execGhCommand` automatically benefit. Third auth method would need careful credential helper separation.

### [2026-02-21] Decision: Frontend callback page instead of API-side redirect for OAuth
- **Task**: Auto-link GitHub App installations after user installs the app
- **Context**: API uses bearer tokens (not session cookies), so API-side redirect wouldn't have auth context
- **Decision**: GitHub redirects to frontend `/github-app/callback` page, which reads `installation_id` from query params and calls the existing link API
- **Alternatives considered**: (1) API-side redirect with 302 — would need Fastify reply injection, no auth context. (2) Poll-based detection — fragile, slow UX.
- **Rationale**: SPA already has Keycloak auth in memory. Existing `link` endpoint does all verification. Callback page is thin orchestration.
- **Consequences**: GitHub App's "Setup URL" must point to frontend origin. Auth survives navigation because Keycloak stores tokens persistently.

### [2026-02-21] Decision: Settings subpages via Refine sidebar nesting
- **Task**: Settings page needed subpage navigation (Integrations, future sections)
- **Context**: Initially implemented as inline Menu within the page — user wanted subpages in the app sidebar instead
- **Decision**: Use Refine's `meta.parent` on resources for automatic sidebar nesting. Parent `Settings` resource has no `list` (pure container). Child `Integrations` has `meta.parent: 'Settings'` and `list: '/settings/integrations'`. Routes use `<Navigate>` for `/settings` → `/settings/integrations` redirect.
- **Alternatives considered**: (1) Inline Menu within page — rejected by user, wants subpages in app sidebar. (2) Custom sidebar rendering — rejected, Refine handles nesting natively. (3) Ant Design Tabs — rejected, doesn't scale to many settings sections.
- **Rationale**: Zero custom sidebar code. Adding future subpages = one resource + one route + one component. Refine auto-handles selected state, menu expansion, and collapsed sidebar popups.
- **Consequences**: `Settings` is not directly navigable (clicking it expands the submenu). Future subpages follow the same pattern.

### [2026-02-21] Decision: System settings endpoint for feature flags
- **Task**: Conditionally show/hide GitHub App UI based on server configuration
- **Context**: Frontend needs to know if GitHub App env vars are set without exposing raw config
- **Decision**: `GET /system/settings` returns `{ githubAppEnabled: boolean }`. New `SystemModule` imports feature modules and checks `isConfigured()`.
- **Alternatives considered**: (1) Add flag to existing endpoint — rejected, feature availability is cross-cutting. (2) Public endpoint — rejected, unnecessary exposure.
- **Rationale**: Clean home for future feature flags. Authenticated. Frontend caches result via `useSystemSettings` hook.
- **Consequences**: Future optional features add their flag to `SystemSettingsResponseDto`.
