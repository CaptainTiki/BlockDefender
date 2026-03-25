# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tower Defense Roguelite — a Godot 4.6 game where players build fragile self-supporting 3D block structures that autonomously defend against waves of enemies. Structures can dynamically collapse in chain reactions.

- **Engine:** Godot 4.6 (stable only, no custom forks)
- **Physics:** Jolt Physics
- **Rendering:** Forward Plus (D3D12 on Windows)
- **3D Assets:** Blender 5, exported as `.glb`
- **2D Assets/Textures:** `.png` (lossless)

## Running the Game

Open `project.godot` in Godot 4.6 and press F5 to run. There are no custom build scripts — development happens entirely within the Godot editor. Use Godot's built-in profiler for performance work.

## Architecture

### Core Systems

**Four game phases loop per run:**
1. **Upgrade Phase** — Spend scrap in a persistent skill tree (survives across runs)
2. **Build Phase** — Free 3D block placement with real-time stability preview
3. **Defense Phase** — Hands-off wave defense; blocks auto-attack enemies
4. **Resolution Phase** — Tally destroyed blocks, repurchase, save layout

**Key architectural constraint:** Only two autoloads are allowed:
- `GameEvents.gd` — Signal bus only, no state
- `SaveSystem.gd` — Load/save only, instantiated on demand

Never use autoloads for gameplay state or managers. Pass references explicitly or use a SceneManager that loads/unloads systems on demand.

### Scene Structure

- One scene per major system: `BuildPhase.tscn`, `DefensePhase.tscn`, `UpgradeTree.tscn`
- Arena variations inherit from `BaseArena.tscn` (scene inheritance)
- Never hard-code node paths deeper than 2–3 levels; use `@onready var`
- **Never construct objects, meshes, or visuals in code** — build a `.tscn` instead so the node tree is editable in the inspector. Code instantiates scenes (`preload()` + `instantiate()`), it doesn't construct them. Exception: transient debug-draw helpers in debug mode only.

### Script Architecture

Scripts are **small and single-responsibility** (max ~150–200 lines excluding comments). Reusable behavior is implemented as **Component nodes** attached as children:

- `HealthComponent.gd`
- `AttackComponent.gd`
- `TapeBondComponent.gd`
- `AnchorComponent.gd`

Core system scripts (planned):
- `BlockPlacement.gd` — Grid-based 3D placement (1×1×1 unit blocks)
- `StabilityChecker.gd` — Flood-fill grounding and bond calculation
- `CollapsePropagator.gd` — Chain-reaction collapse
- `BlockHealth.gd` — Block damage and destruction

### Stability & Collapse System ("Cardboard Physics")

The stability system is a **grid-based flood-fill algorithm** — never a full physics simulation. Performance target: **collapse flood-fill must stay under 2ms**.

- Bond calculation: shared face = 1 bond, diagonal = 0.5 bonds
- Stability states: green (stable) / yellow (wobbles under attack) / red (collapses imminently)
- On destruction: flood-fill checks remaining blocks → 0.5s warning wobble → failing sections fall as rigid groups

### Signals

Use signals over direct calls between unrelated systems. Route game-wide signals through `GameEvents.gd`.

## Coding Standards

- **`@export`** variables heavily — inspector tweaking is preferred over code changes
- **No `_process()` or `_physics_process()`** on nodes that don't need per-frame updates; use timers and signals instead
- **Object pooling required** for blocks and enemies (pre-instantiate pools)
- **Component header comments** — every component script must have a short comment stating its single responsibility
- Comments explain *why*, not *what*
- Use Godot's built-in formatter (Editor Settings → Text Editor → Format on Save)

## Asset Naming Conventions

```
block_gun_01.glb
texture_tape_normal.png
arena_grass_01.tscn
```

Top-level asset folders: `/blocks/`, `/enemies/`, `/ui/`, `/shaders/`, `/sounds/`, `/assets/textures/`

Blender export settings: Apply Modifiers on, Embed Textures off. Textures must be power-of-2 sizes. Import with lossless compression for the crisp low-poly look.

## Version Control

- Branches: `main` (stable) → `develop` (integration) → `feature/feature-name`
- Commit style: `feat: add stability preview`, `fix: collapse flood-fill edge case`
- No committed binaries except small textures and `.glb` files under 5 MB
- Never manually create or copy `.uid` files — let Godot generate them

## Key Design Docs

- `docs/Architecure.md` — Development standards and coding practices (authoritative)
- `docs/Tower_Defense_GDD.md` — Full game design document
- `docs/New Text Document.txt` — Development roadmap with 6 milestones to Vertical Slice 1.0
