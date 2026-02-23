# Web Learnings

Accumulated knowledge about the Geniro Web codebase (`geniro-web/`). Updated automatically after each task.

---

## Patterns Discovered

### [2026-02-21] Pattern: Threading feature flags to RJSF forms via FormContext
- **Context**: Needed to conditionally show/hide fields and filter enum options based on system settings
- **Pattern**: Pass `githubAppEnabled` through `GraphPage → NodeEditSidebar → TemplateConfigForm` via `formContext`. In `FieldTemplate`, check `formContext.formData` to conditionally hide fields. In `SelectWidget`, filter enum options based on `formContext.githubAppEnabled`.
- **Where**: `pages/graphs/components/TemplateConfigForm.tsx`, `pages/graphs/components/NodeEditSidebar.tsx`
- **Usage**: Any time a template form field needs to be conditionally visible based on system config or sibling field values

## Gotchas & Pitfalls

### [2026-02-21] Gotcha: React Compiler lint rules stricter than standard hooks rules
- **What happened**: Synchronous `setState` inside `useEffect` triggers `react-hooks/set-state-in-effect` warning
- **Root cause**: Project uses React Compiler lint rules which are stricter than standard React hooks rules
- **Fix/Workaround**: Use `useState` initializer functions for synchronous state, keep only async work in effects
- **Prevention**: Always check lint after adding useEffect with setState

### [2026-02-21] Gotcha: Global axios instance inherits auth headers automatically
- **What happened**: Expected to need explicit auth config for API calls
- **Root cause**: `auth.tsx` sets `axios.defaults.headers.common` with Keycloak token — all `import axios from 'axios'` calls inherit it
- **Fix/Workaround**: Just use `import axios from 'axios'` directly — no special auth setup needed
- **Prevention**: Use the global axios instance for authenticated API calls, don't create new instances

### [2026-02-21] Pattern: Refine `meta.parent` for nested sidebar navigation
- **Context**: Settings page needed subpages (Integrations, future General/Notifications) as nested items in the app sidebar
- **Pattern**: Parent resource has no `list` (pure submenu container). Child resources use `meta.parent: 'ParentName'`. Refine's `useMenu` → `createTree` auto-renders `Menu.SubMenu` in the sidebar. `defaultOpenKeys` auto-expands when a child is active. No custom sidebar code needed.
- **Where**: `App.tsx` resources config, `components/layout/CustomSider.tsx` (unchanged — works automatically)
- **Usage**: Any top-level section that needs expandable sub-navigation in the sidebar

### [2026-02-23] Gotcha: useEffect handler instability causes missed WebSocket events
- **What happened**: WebSocket revision events were never received despite correct backend emission
- **Root cause**: `useWebSocket` hook's `useEffect` depended on `handlers` — a new object every render. This caused constant handler teardown/setup, creating windows where events were missed.
- **Fix**: Use `useRef` forwarding pattern: store handlers in a ref, create stable wrapper functions that delegate to `handlersRef.current`. Depend on `JSON.stringify(Object.keys(handlers))` instead of `handlers`.
- **Where**: `hooks/useWebSocket.ts`
- **Prevention**: Never depend on object/function references in effects that register external listeners. Always use ref forwarding.

### [2026-02-23] Pattern: Status rank guard for monotonic state transitions
- **Context**: HTTP response could overwrite WebSocket-delivered terminal status (Applied → Pending)
- **Pattern**: Define a `STATUS_RANK` map with numeric values. In `upsertRevision`, only update if `incomingRank >= existingRank`. Terminal states (Applied, Failed) share the highest rank.
- **Where**: `pages/graphs/hooks/useGraphRevisions.tsx`
- **Applies to**: Any client-side state that can be updated from multiple sources (WebSocket + HTTP)

### [2026-02-23] Pattern: Polling fallback with graph state refresh
- **Context**: Polling fallback detected revision completion but didn't update `graph.version`, causing VERSION_CONFLICT on next save
- **Pattern**: Add an `onRevisionComplete` callback to the polling hook. The caller defines a refresh function that fetches latest graph data and rebuilds state. Use a ref for the callback to avoid interval restarts.
- **Where**: `pages/graphs/hooks/useGraphRevisions.tsx`, `pages/graphs/details.tsx`
- **Applies to**: Any polling fallback that detects state changes — must refresh ALL dependent state, not just the polled entity

## Component Patterns

<!-- Reusable UI patterns discovered. Format:
### [date] <component pattern name>
- **For**: what kind of UI
- **Approach**: components/hooks used
- **Example file**: path to reference
-->

## Useful Commands & Shortcuts

<!-- Non-obvious commands or workflows discovered. Format:
### [date] <command/workflow name>
- **Command**: `exact command`
- **When to use**: context
- **Notes**: any caveats
-->
