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
