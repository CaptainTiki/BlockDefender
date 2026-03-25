# Game Design Document – Stripped-Down Core (v0.1)

**Genre**: Hands-off spectator tower-defense roguelite with modular 3D construction and structural fragility.  
**Core Fantasy**: You design a fragile, self-supporting structure out of modular blocks, then sit back and watch it automatically defend against waves of enemies. The structure can collapse in spectacular ways if poorly built or damaged.  
**Player Role**: Architect / Observer. You build and upgrade between runs. During runs you only watch, pan the camera, and learn.  
**Win Condition**: Survive all waves on the current level.  
**Loss Condition**: Structure loses all grounded connections or falls entirely into hazard zones.  
**Target Loop Length**: 8–15 minute runs + 3–5 minute build/upgrade phases. High replayability via roguelite progression.

**Key Differentiator**: The structure is 100 % self-contained. Blocks only connect to other blocks. The world is an obstacle course, never a foundation.

## 1. Core Loop (One Full Run)
1. **Upgrade Phase** – Spend currency in a persistent skill tree to unlock new block types and stat boosts.  
2. **Build Phase** – Load previous structure (or start fresh). Place/remove blocks freely. Stability preview in real time.  
3. **Defense Phase** – Hands-off. Enemies spawn and path toward the structure. Blocks auto-attack (melee at contact range, ranged at distance). Watch the fight in 3D.  
4. **Resolution Phase** – Destroyed blocks are tallied. Pay to repurchase lost blocks or accept permanent gaps. Save current layout. Return to Upgrade.

Repeat. Each successful run gives more currency and tree progression.

## 2. Building System
- Grid-based 3D placement (1×1×1 unit blocks).  
- Left-click = place selected block type.  
- Right-click = remove block and return it to inventory (free, instant).  
- Blocks can **only** connect face-to-face with other blocks. No direct attachment to terrain, walls, or obstacles ever.  
- Minimum 0.2-unit visible gap required between any block and terrain (visual + rule enforcement).  
- **Anchor Blocks** (special unlock): Only block type allowed to touch terrain. Limited to 2 connection faces total (1 anchor face + 1 normal face). Anchor face snaps to valid terrain surfaces only.  
- Inventory is persistent across runs. Blocks you own stay owned unless permanently lost (see Destruction).

**Build-Phase UI**:
- Real-time stability overlay (green/yellow/red per block and per connected group).  
- “Keep Previous Layout” / “Clear All” / “Load Saved Blueprint” buttons.  
- Undo stack + multi-select delete.

## 3. Stability & Collapse Rules (The “Cardboard Physics” Simulation)
All checks are block-to-block only — fast flood-fill, no full physics engine required.

**Grounding Rule**  
- At least one block in the entire connected structure must be on safe ground or anchored.

**Support & Overhang Rules**  
- Max stable height starts low and upgrades via tree.  
- Overhang distance limited (starts at 2 blocks horizontally from nearest vertical support).  
- Each shared face = 1 connection bond. Diagonal/corner touches = 0.5 bond.  
- Total bonds per block determine structural integrity.

**Real-Time Preview**  
- Green = stable forever.  
- Yellow = will wobble under attack.  
- Red = guaranteed collapse within seconds once combat starts.

**Collapse Propagation (Mid-Run)**  
1. Destroyed block removed.  
2. Flood-fill checks every remaining block for valid grounding + bond count.  
3. Any block failing rules gets 0.5-second warning wobble.  
4. Failing sections fall as rigid groups (simple velocity + spin).  
5. Falling blocks can crush enemies or other blocks on impact.  
6. Blocks that land in hazard zones are permanently destroyed (no repurchase).

**Edge Cases Handled**:
- Floating islands → instant collapse on placement if unanchored.  
- Bridge across gaps → valid only if ends are anchored.  
- Chain-reaction collapses → dramatic and readable (slow-mo auto-trigger on major breaks).

## 4. Levels / Arenas
Multiple arenas per campaign. Each arena forces different structural solutions because of safe zones and hazards.

**Level Design Rules**:
- Floor divided into placeable safe zones and non-placeable hazard zones.  
- Hazards (lava/river/mud/electric/etc.) — Blocks falling in = permanent loss. Enemies interact differently per hazard.  
- Terrain obstacles (walls, pillars, slopes, gaps) cannot be built on or against except via Anchor Blocks.  
- Each arena has unique geometry that changes optimal tower shapes (tall spire vs wide base vs bridged islands vs low bunkers).  
- No arena allows the exact same layout to be optimal — player must adapt or rebuild.

**Progression**: Levels unlock sequentially. Later arenas introduce moving hazards, narrower safe zones, and higher enemy spawn pressure.

## 5. Enemies & Waves
- Waves spawn in sequence. Number and difficulty scale with player progress.  
- Enemies move toward the structure’s base (or any grounded block).  
- Pathing respects hazards and terrain (some can fly, jump, or cross specific hazards).  
- No pathing through player blocks — enemies must destroy or go around.  
- Types (generic): basic rushers, fast scouts, armored tanks, flyers, specials (suicide bombers, reflectors, bond-cutters).  
- Boss waves every 5–7 waves with unique destruction patterns.

Blocks auto-respond:
- Melee blocks attack only on contact.  
- Ranged blocks attack at distance (visual range indicators in build phase).

## 6. Economy & Persistence
**Currency**: Scrap/bits earned from kills and wave survival.  

**Block Loss Rule**:
- Destroyed blocks are removed from inventory until repurchased at end-of-run.  
- If player cannot afford full repurchase, game auto-repairs cheapest version of critical grounding blocks at 50 % discount. Remaining missing blocks stay missing (holes in next layout).  
- Permanent loss only on hazard-zone falls.

**Tower Persistence**:
- Exact layout from end of previous run auto-loads next build phase.  
- Player can keep/improve, clear all (full refund of deleted blocks), or load saved blueprints (up to 3 slots later).

**Upgrade Tree** (persistent across all runs):
- Branches: Offense (new block types + damage/fire-rate), Defense (health, repair, shields), Utility (conveyors, launchers, teleporters), Specialization (elemental effects, legendary blocks).  
- New blocks, stat multipliers, and Anchor Block variants unlock here.  
- Respec available at scrap cost.

## 7. Camera & Observer Experience
- **Build Phase**: Free 3D orbit, pan, zoom.  
- **Defense Phase**:  
  - God Mode (free fly).  
  - Spectator Mode (cinematic auto-follow with dramatic swoops).  
- Auto slow-motion on major collapses, first kills, and boss moments.  
- Optional focus-click to zoom on any block or enemy.

## 8. Scope & Prototype Priorities (MVP → Full)
**Phase 1 MVP (1 weekend)**  
- 1 arena (flat safe ground).  
- 3 block types (basic ranged, basic melee, Anchor).  
- 3 waves.  
- Simple tree (4 unlocks).  
- Stability + collapse system.  
- Load previous layout + clear button.

**Phase 2**  
- 3 arenas with hazards.  
- 6 block types + basic synergies.  
- Repurchase system + partial auto-repair.  
- Full camera modes.

**Phase 3**  
- Full tree + legendary blocks.  
- 6+ arenas.  
- Enemy variety + boss waves.  
- Blueprint saves + prestige slots.

## 9. Balance & Feel Pillars
- Creativity rewarded over spam (synergies, map-specific shapes).  
- Risk/reward on tall vs wide vs bridged designs.  
- Learning through failure (collapse replay shows exact weak point).  
- “Just one more run” via cheap iteration + persistent upgrades.  
- Zero frustration on controls; all tension comes from structural decisions.

---

**Document Status**: Theme-agnostic core complete. Ready to be skinned as cardboard kid bedroom, sci-fi space station, fantasy citadel, etc.  
**Version**: 0.1 — March 2026  
**Next Steps**: Block stats spreadsheet, full upgrade tree diagram, or arena template pack.
