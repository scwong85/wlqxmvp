# M23 report: Year 1 balance, minigames, polish

- **Minigames:** mining ("tap the vein", 5 strikes) and music (12 notes on a beat line) join fishing. Both are deterministic for a seed, use one input (press), have quick-resolve and grade multipliers like fishing, and use a shared tap view. Scripted-play tests: perfect play scores high, idle play scores 0 and ends.
- **Tournament realm gate:** event requirement `realm_min` (new, with reason text); the first bout needs realm 2. Players below it skip the bouts but the story (theft, Hui-Mask) still runs.
- **Battle balance (tests/sim_year1.gd, auto-AI, hero at a ratio of the realm attribute cap):** Cangwu enemies were far too weak (2-round fights) and were raised (disciple hp 50, senior hp 120); the ambush units were tuned so a hero at 50 to 70 percent of the realm cap wins in 6 to 8 rounds. The AI is deterministic, so results are all-or-nothing around the edge; at 40 percent of the cap the results are listed below.
- **Cultivation pace (tests/sim_progress.gd):** full-time training reaches realm 3 at week 23 and realm 4 at week 36 (fist, sword); a player spending about half their slots on story is about 45 and 72, matching the "realm 3 by about week 45" target.
- Tests: m23_tests.gd (2767 checks in total).

## Ratio 0.4 of the realm cap
| caravan_escort | 2 | lu_chenzhou | 100 | 4.4 |
| xie_duel | 3 | bai_yan | 100 | 4.3 |
| cw_bout_1 | 3 | bai_yan | 100 | 4.4 |
| cw_bout_2 | 3 | bai_yan,li_shan | 100 | 4.6 |
| cw_bout_3 | 3 | bai_yan | 100 | 7.0 |
| q4_ambush | 3 | lu_chenzhou,xie_wujiu | 0 | 7.0 |

## M23b: music and the art/music prompt sheet
- `docs/ART_AND_MUSIC_PROMPTS.md`: one merged sheet with the global style blocks, prompts for all characters (reference and pose sheets, bust portraits), backgrounds (current and future), key art, endings, UI icons, battle art, 20 music tracks, 4 later themes, companion leitmotifs and a sound-effect list.
- Placeholder music: `scripts/gen_music.py` synthesises 20 tracks (18 loops, 2 stingers, 1.2 MB total) to `game/audio/music/*.ogg` and writes `game/content/audio/music.json` (catalog plus the rules).
- In game: `MusicRules` (pure) picks a track from the screen, the region of the last visited area, the dialogue background, event overrides and the battle kind; `Audio` polls every 0.4 s, cross-fades 1.2 s, plays victory/defeat stingers; missing files fall back to the old soft pad. World state now remembers `last_area`.
- Tests: m23b_tests.gd (catalog files, every mapping valid, rule cases).
