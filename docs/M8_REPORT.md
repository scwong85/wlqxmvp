# M8 report: menu-based exploration (Bamboo Pass)

## What exists
- **Data-driven routes** (`content/exploration/routes.json`): nodes with text keys, choices (gates, costs, seeded skill checks with
  success/failure outcomes, effects, next node), on-enter effects, end nodes and companion encounter hooks. No story text in scripts.
- **Bamboo Pass**: 10 nodes, 3 starting paths (old road / stream / ridge), 4 clues, 2 endings, 2 companion encounters (Lu at the courier, Bai at the lookout),
  a gate on body, a clue gate on the final door, and a failed sneak that sets up a bandit battle (stub until M9).
- **Rules** (`ExplorationSystem`): gating by attribute, item, bond, flag and clue count; deterministic checks (seeded by run seed + route/node/choice);
  effects (rewards, clues, flags, battle trigger); the route costs 4 stamina and **one slot when it ends**; a route can be done once.
- **Screens**: "Explore: Bamboo Pass" button next to Execute (from day 2); exploration screen with story text, choices (success chance or the reason a choice is locked),
  feedback box (check roll, costs, changes, clues), invitation prompt on encounters (shared with the day-3 prompt), return button.
- **Saves**: schema v4. Every step autosaves; reloading mid-route returns to the same node. v3 saves migrate.

## Evidence
- Unit: 790 checks, 0 failures. Graph validator proven to catch orphans, dead ends, loops without exit, missing targets, missing keys, bad checks, bad effects, no open choice.
- Branch coverage: **20/20** (every node x choice x outcome executed). Two full scripted playthroughs.
- UI smoke: opens the route, gated ridge, invitation prompt, finishing uses a slot, route marked done, reload resumes on the saved node.
- Browser (Chromium, 4 sizes): layout clean; real trek in the browser; screenshots `docs/spike/screens/m8_explore_*.png`.

## Notes
- Clues are stored for the final crisis (M12/M13); nothing consumes them yet. The `battle` effect sets `exploration.pending_battle`; M9/M10 will run it.
- Story flags set by this route: `helped_courier`, `pass_secret_known`. The departure flags from M7 are still not set by any story event.
- Only one route exists; the explore button is hard-wired to Bamboo Pass until more routes exist.
