\# Development Standards \& Coding Practices (v0.1)



\*\*Project\*\*: Tower Defense Roguelite (working title)  

\*\*Engine\*\*: Godot 4.6  

\*\*3D Assets\*\*: Blender 5  

\*\*2D Assets / Textures\*\*: Krita or Gimp  

\*\*Version Control\*\*: Git (GitHub / GitLab recommended)  

\*\*Document Status\*\*: Theme-agnostic, enforceable rules for the entire team.  

\*\*Version\*\*: 0.1 — March 2026



\*\*Goal\*\*: Keep the codebase clean, maintainable, and fast to iterate. Favor simplicity and explicit control over magic and global state.



\## 1. Core Philosophy

\- \*\*Readability over Cleverness\*\* — Code must be understandable by any team member in under 30 seconds.

\- \*\*Short \& Focused\*\* — Prefer many small scripts over few large ones.

\- \*\*Reuse over Duplication\*\* — Components and composition are king.

\- \*\*Explicit Loading\*\* — Manage what is in memory instead of relying on always-on globals.

\- \*\*Godot-Native\*\* — Let the engine do what it’s good at. Never fight the engine.



\## 2. Tools \& Environment Rules

\- \*\*Godot 4.6\*\* — Use the official stable release only. No custom forks or dev builds unless approved.

\- \*\*Blender 5\*\* — All 3D models, animations, and level props must be exported as `.glb` (preferred) or `.gltf`. Use Godot’s import settings for scale and compression.

\- \*\*Krita / Gimp\*\* — All 2D textures, UI elements, and decals saved as `.png` (lossless). Organize in `/assets/textures/` with descriptive names.

\- \*\*Editor Settings\*\*:

&nbsp; - Interface → Editor → Use External Editor (optional but encouraged for larger refactors).

&nbsp; - Filesystem → Auto-Scan Changed Files: On.

&nbsp; - Version Control → Integration enabled.



\## 3. Godot-Specific Practices

\### Scene \& Node Structure

\- One main scene per major system (e.g., `BuildPhase.tscn`, `DefensePhase.tscn`, `UpgradeTree.tscn`).

\- Use \*\*Scene Inheritance\*\* for variations (e.g., different arenas inherit from `BaseArena.tscn`).

\- Never hard-code node paths longer than 2–3 levels deep. Use `@onready var` with `$` or `get\_node()` only when necessary.



\### Scenes Over Code for Visuals

\- \*\*Rule\*\*: Never create objects, meshes, or visuals purely through code when a `.tscn` file can be built instead.

\- Always prefer building a scene file so the node tree is editable in the Godot inspector.

\- Code should \*\*instantiate\*\* scenes, not construct them. Use `preload()` / `load()` + `instantiate()`.

\- Exception: purely transient debug-draw helpers (e.g., `Line3D` gizmos drawn in debug mode only) may be created in code.



\### Unique IDs (UIDs)

\- \*\*Rule\*\*: Never manually create or copy `.uid` files.

\- Always let Godot generate them automatically.

\- If a `.uid` file gets corrupted or duplicated, delete it and let Godot recreate on next load.



\### Scripts

\- \*\*Default\*\*: Many short scripts (one responsibility per script).

&nbsp; - Example: `BlockPlacement.gd`, `StabilityChecker.gd`, `CollapsePropagator.gd`, `BlockHealth.gd`.

\- Max recommended script length: ~150–200 lines (excluding comments).

\- Use `@export` variables heavily for inspector tweaking.

\- Prefer \*\*Components\*\* (separate Node scripts attached as children) for reusable behavior:

&nbsp; - `HealthComponent.gd`

&nbsp; - `AttackComponent.gd`

&nbsp; - `TapeBondComponent.gd`

&nbsp; - `AnchorComponent.gd`

\- Avoid monolithic “Manager” scripts that do everything.



\### Autoloads (Singletons)

\- \*\*Rule\*\*: Keep autoloads to an absolute minimum.

\- Only allowed autoloads (for now):

&nbsp; - `GameEvents.gd` (signal bus only — no state).

&nbsp; - `SaveSystem.gd` (load/save only, instantiated when needed).

\- Never use autoloads for gameplay state, managers, or persistent data.

\- Instead: Pass references explicitly or use a lightweight SceneManager that loads/unloads systems on demand.



\### UI Mouse Filter

\- \*\*Rule\*\*: Layout-only containers must have `mouse\_filter = IGNORE` (value `2`).

\- Applies to: `VBoxContainer`, `HBoxContainer`, `GridContainer`, `MarginContainer`, `ScrollContainer` (when not intercepting scroll), and any other container whose sole purpose is arranging children.

\- Godot defaults all containers to `mouse\_filter = STOP`, which silently consumes every mouse event that lands inside the container's rect — none of it reaches the leaf controls (buttons, etc.) inside.

\- Only controls that \*\*intentionally handle input\*\* (buttons, line edits, a panel that must block click-through) should stay at `STOP`.

\- Note: setting `ScrollContainer` to `IGNORE` disables scroll-wheel scrolling. When the inventory grid grows large enough to need scrolling, restore `ScrollContainer` to `STOP` and ensure no sibling or ancestor container is stealing events above it.



\### Signals

\- Prefer signals over direct function calls between unrelated systems.

\- Centralize game-wide signals in `GameEvents.gd` (but still load it only when needed).



\### Performance \& Optimization

\- Use `ObjectPooling` for blocks and enemies (pre-instantiate in a pool node).

\- Profile every new system with Godot’s built-in profiler.

\- Avoid `process()` or `\_physics\_process()` on nodes that don’t need per-frame updates (use timers or signals instead).

\- Collapse flood-fill must stay under 2ms (grid-based, never full physics simulation).



\## 4. Asset Pipeline Rules

\- \*\*Blender → Godot\*\*:

&nbsp; - All models use correct scale (1 unit = 1 block).

&nbsp; - Materials use Godot’s StandardMaterial3D (or ShaderMaterial when necessary).

&nbsp; - Export with “Apply Modifiers” and “Embed Textures” disabled.

\- \*\*Textures\*\*:

&nbsp; - Power-of-2 sizes only (unless UI element).

&nbsp; - Use `lossless` compression in Godot import settings for crisp low-poly look.

\- \*\*Naming Convention\*\*:

&nbsp; - `block\_gun\_01.glb`

&nbsp; - `texture\_tape\_normal.png`

&nbsp; - `arena\_grass\_01.tscn`

&nbsp; - Prefix folders: `/blocks/`, `/enemies/`, `/ui/`, `/shaders/`, `/sounds/`



\## 5. Version Control \& Workflow

\- \*\*Branching\*\*: `main` (stable), `develop` (integration), feature branches (`feature/stability-collapse`, `feature/anchor-blocks`).

\- \*\*Commit Messages\*\*: Conventional style (`feat: add stability preview`, `fix: collapse flood-fill edge case`).

\- \*\*Pull Requests\*\*: Require at least one review. Include before/after screenshots for visual changes.

\- \*\*No committed binaries\*\* except small textures and `.glb` files under 5 MB.



\## 6. Code Style \& Comments

\- Use Godot’s built-in formatter (Editor → Editor Settings → Text Editor → Format).

\- Comments only when “why” is not obvious (never comment “what”).

\- Every new component must include a short header comment explaining its single responsibility.



\## 7. Testing \& Debugging

\- Use Godot’s built-in testing tools where possible.

\- Add temporary debug draw (Gizmos, labels, Line3D) for stability bonds during development (easy toggle with a checkbox).

\- Slow-motion and collapse replay system must be built with debug mode in mind.



---



\*\*Document Status\*\*: Enforceable baseline for all code and assets.  

\*\*Next Review\*\*: After Phase 1 MVP is complete.  

\*\*How to Update\*\*: Any team member can propose changes via PR with clear justification.



This is our shared contract for clean, fast, and fun development.

