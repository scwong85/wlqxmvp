# M9 report: combat rules core

Status: done. Rules run headless, no UI yet (the board and presentation come in M10).

## What exists
- `scripts/domain/combat/`: `combat_grid` (6x8 board, terrain, reachability), `combat_unit`, `combat_rules` (damage
  arithmetic shared by preview and real actions), `battle` (turns, actions, statuses, objectives, log),
  `battle_ai` (deterministic AI, also used to auto-play the player side in tests), `battle_setup` (scenario + seed + hero/party).
- `content/combat/`: 15 techniques, 3 statuses, medicine item, 6 unit types, 3 scenarios. All text via translation keys.
- Content validation covers techniques, statuses, units (max 6 types), scenarios (cells, objectives, round limits).

## Rules in one page
- Board: 6 columns x 8 rows (portrait-first). Manhattan range. Units block movement. Neighbour order up, left, right, down.
- Terrain: `cover` (damage taken -25%) and `hazard` (3 damage at the end of the turn; entering costs 2 mp).
- Turn: initiative by agility (ties: player side first, then creation order). 1 action + movement per turn.
  mp = 3 + agility/5 (Slow -2, minimum 1). Actions: attack, technique, support, guard, item.
- Damage (integers, no randomness): power + technique damage - body/2, then Weaken -25%, Broken +50%, Cover -25%,
  Guard -50%, minimum 1. Blocked push adds 2. Ambush strike adds 4 against Broken.
- Resolve: techniques reduce it (halved by Guard). At 0 the target is Broken: loses its next turn, then resolve refills.
- Follow-up: when an attack Breaks a target, adjacent allies may make one free basic attack (once per unit per round;
  a follow-up never offers another, so no chains).
- Statuses: bleed (2 damage at turn start), slow, weaken. No stacking; the longer duration wins.
- Objectives: defeat all, defeat leader, survive N rounds, protect a unit. Defeat if the party falls, the protected unit
  dies or the round limit passes.
- The seed only chooses enemy start cells among each scenario's candidates. Everything else is deterministic.
- Every log entry records damage, technique and the modifier list, so each number can be explained.

## Tests (968 unit checks, 0 failures)
Grid and terrain, bounds, reachability with blocking and hazards, unit model, initiative tie-breaks, action validation,
the full damage table with stacked modifiers, each technique kind, guard, break and recovery, bleed/slow/hazard,
follow-ups (adjacent only, once per round, no loops, expire at turn end), all objectives, three scripted scenarios with
three party sizes, preview equals actual for every attack technique, and 20 seeded battles run twice with identical hashes.

## Balance (auto-played, default stats, no hero techniques)
- Training match: hero + 1 companion wins in 4-5 rounds; bare hero alone wins in about 9.
- Rescue battle: hero + 2 companions wins in 5-6 rounds (the 5-round survival goal); alone it is meant to be lost.
- Final crisis: hero + 2 companions wins in 6-7 rounds; alone it is lost.
`game/tests/tune_combat.gd` prints this table (`godot --headless --path game -s res://tests/tune_combat.gd`).

## Not done yet (M10)
Board rendering and touch controls (portrait board, landscape variant), animations, battle result screen, wiring
`pending_battle` from exploration and syncing medicine use back to the save.
