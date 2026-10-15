# M12 report: story, endings and the final crisis

## What a player gets
A seven-day story told through short dialogue scenes (portrait-first, touch/mouse/keyboard):

| Day | Scene | Effect |
|---|---|---|
| 1 | Intro (3 lines) | Tutorial framing |
| 2 | Choose a path (or "later") | Sets the path; skipped automatically if already chosen |
| 3 | Shen Qinghe's invitation (existing pop-up and recruit prompt) | Companion recruitment |
| 4 | Bandits at the ford: "rush in" or "together" (needs an active companion) | Starts the rescue battle; win and lose both continue the story |
| 5 | Faction choice (pavilion, couriers, scribes, neutral) | Sets a faction flag, small bond gain; shows in the epilogue |
| 6 | Preparation: scout, rest (+6 stamina), or train | Flag/stamina; exploration stays optional |
| 7 | Warning, then after the last slot the final dialogue | Starts the final battle (the run ends) |

Endings (table-driven, first match wins, `content/story/endings.json`): **Valley Sage** (bandits defeated, villager saved, bond ≥ 8, path progress ≥ 6), **Valley Guardian** (bandits defeated, villager saved), **Lone Victor** (bandits defeated only), **Valley Falls** (fallback). The ending screen offers "New journey" (clears the run) and "Back to title".

## How it is built
- `DialogueSystem` (pure rules): entry lists with gates, nodes (linear or choices), gated choices with reasons, effects (flag, set_path, bond, resource, attribute, stamina, battle, queue). `Game.next_story_scene()` decides what opens: an interrupted battle, an open dialogue, the ending, a queued scene, a day-start hook, or the final crisis.
- Content is data: `content/story/dialogues.json`, `endings.json`, `events/day_hooks.json`. The validator checks ids, reachability, targets, text keys, at least one always-open choice per node, effects, ≥3 endings with unique conditions and a fallback.
- Save schema 6 adds `story` (open dialogue/node, queued scene, ending). v5 saves migrate with an empty story. An open dialogue, a battle and a finished run all resume exactly on reload.

## Evidence
- Unit tests: 1,333 checks, 0 failures (M12 adds dialogue runner, gates, effects, ending table with priorities, validator, migration, resume mid-dialogue).
- Bot playthroughs (log lines `PLAYTHROUGH ...` in the unit output) reach four distinct endings: valley_sage, valley_guardian, lone_victor, valley_falls.
- `DAYSAVE` lines: save and reload at every day boundary (7 reloads) gives byte-identical final state and the same ending for three policies.
- UI smoke plays the real week with the real buttons (intro → path → rescue → faction → prep → crisis → ending → load back to the ending → new run), and audits dialogue and ending screens at 390x844, 360x640, 768x1024, 1280x720 and 2400x1080 in Mandarin and English.
- Browser smoke at six sizes: intro dialogue and day-2 choice (tap on portrait, keyboard on landscape), no console errors, layout audits clean.

## Corrected balance assumption
M11's note assumed about 36 points of hero growth by the final fight. A real week yields roughly 5 / 9 / 20 points by the scouts / rescue / final fights, and the simulator now uses that. With it, every cell is 3–7 rounds. Win rates: rescue 66–89%, final fist 100 / sword 96 / rain 74 / even 91 (`docs/M11_BALANCE_TABLE.md`).

## Honest limits
- Playthrough bots force battle outcomes (battles themselves are covered by M9–M11 tests and the simulator). The sage run adds its path progress directly.
- Faction and day-6 choices only set flags, a small bond change and stamina; they do not change combat.
- Real-device checks (touch, fullscreen, orientation) are still pending.
