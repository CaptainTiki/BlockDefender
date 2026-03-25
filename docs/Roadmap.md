# Development Roadmap & Milestones
**Version**: v0.1 — March 2026  

**Project**: Tower Defense Roguelite (working title) 
**Engine**: Godot 4.6  
**Goal**: Reach **Vertical Slice 1.0** — a complete, playable mini-game that demonstrates the entire core loop with limited but polished content.  
**Vertical Slice Definition** (what “done” looks like):
- Persistent upgrade tree (4–6 unlocks)
- Build phase with real-time stability preview
- 3 block types (basic ranged, basic melee, Anchor)
- 1–2 arenas (flat safe ground + one with simple hazards)
- 3–5 waves with basic enemies
- Full collapse system + slow-mo replay
- Block loss / repurchase economy
- Load previous layout + Clear All
- Free 3D camera in both phases
- End-of-run summary screen
- The game feels fun and “just one more run” even with limited content

## Milestone 0: Project Foundation & Setup 
- Create Godot 4.6 project with proper folder structure (`/scenes/`, `/scripts/`, `/blocks/`, `/arenas/`, `/assets/`, etc.).
- Import basic low-poly block placeholder (Blender → .glb).
- Set up version control (Git) and commit initial structure.
- Basic main menu scene that launches directly into Build Phase.
- Basic camera modes (God Mode free-fly + Spectator cinematic).
- **Done when**: You can run the game and see an empty 3D arena with free camera movement.

## Milestone 1: Core Building System 
- Grid-based 3D placement (1×1×1 snap).
- Left-click = place selected block, Right-click = remove & return to inventory.
- Block inventory UI (simple list GUI buttons to select).
- Persistent block inventory (saved between runs).
- “Keep Previous Layout” / “Clear All” buttons.
- **Done when**: You can freely build and delete blocks in an empty arena. Previous layout auto-loads on next run.

## Milestone 2: Stability & Collapse System
- Flood-fill grounding + bond calculation (face = 1 bond, diagonal = 0.5).
- Height limit + overhang rules (configurable via `@export`).
- Real-time stability overlay (green/yellow/red per block/group).
- Mid-run collapse propagation + rigid-group falling (simple velocity + spin).
- Falling blocks can damage enemies or other blocks.
- Hazard zone detection (blocks that fall in are permanently lost).
- Auto slow-motion on major collapses.
- **Done when**: Placing illegal structures shows red preview; destroyed blocks cause realistic chain-reaction collapses with visual wobble.

## Milestone 3: Defense Phase & Basic Combat
- Wave spawner (3–5 waves, increasing difficulty).
- Generic enemies (rusher, fast scout, flyer) with simple pathing toward grounded blocks.
- Block auto-attack system:
  - Melee: contact range only
  - Ranged: distance + visual range indicator in build phase
- Enemy damage to blocks (health + destruction).
- Wave end detection (win/lose).
- **Done when**: Enemies spawn, path, attack, and get destroyed by your blocks while you watch in 3D.

## Milestone 4: Economy, Persistence & Block Loss
- Scrap currency earned from kills + wave survival.
- End-of-run summary: “Lost X blocks — repurchase cost Y”.
- Repurchase system (full price or 50% auto-repair for critical blocks).
- Missing blocks create visible holes in next layout.
- Simple SaveSystem (layout + inventory + upgrades).
- **Done when**: Destroyed blocks are gone from inventory until repurchased; you can continue to next run with gaps.

## Milestone 5: Upgrade Tree Lite + Progression
- Simple upgrade tree scene (4–6 nodes).
- Unlocks: new block types, +damage, +fire-rate, extra tape bonds, basic Anchor upgrades.
- Tree is persistent across all runs.
- Respec button (costs scrap).
- Upgrade Phase screen between runs.
- **Done when**: You can spend scrap to unlock new blocks and stats that actually change the next run.

## Milestone 6: Polish, Second Arena & Vertical Slice Delivery
- Add second arena with simple hazard zones + anchor opportunities.
- UI polish (stability meter, damage numbers, end screen recap).
- Camera auto-swoops on big moments.
- Sound placeholders + particle effects for tape/collapse.
- Playtest the full loop 10+ times and fix major pain points.
- Build executable + short “how to play” screen.
- **Done when**: You can hand the build to someone and they understand and enjoy the full loop without explanation.

## Vertical Slice 1.0 – Release Criteria
- All 6 milestones complete.
- Core fantasy is clearly visible: fragile self-supporting structures, dramatic collapses, creative building, “just one more run”.
- Zero crashes, no major bugs.
- Playtime: 8–15 min per run.
- Documented in a short README (“How to test the vertical slice”).

---

**Next Phase After Vertical Slice** (high-level only):
- Phase 2: 6 block types + synergies + 3 more arenas
- Phase 3: Full upgrade tree + boss waves + blueprint saves
- Phase 4: Polish, audio, multiple themes, shipping 
