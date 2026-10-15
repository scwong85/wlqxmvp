# Story expansion: scope and plan (draft, nothing implemented)

## 1. Where we are
- One 7-day week, 9 dialogues (20 nodes, about 1,500 Chinese characters), 4 endings, 1 story battle chain (scouts, rescue, final), 3 paths, 3 companions with only recruitment-level story.
- The systems (dialogue runner with gates and effects, hook calendar, flags, endings table, save v6, validator, bot playthroughs) are generic, so most expansion is content plus a few structural features.

## 2. What "massive" could mean (pick a tier)
| Tier | Content | Rough size | Effort |
|---|---|---|---|
| A. Deep week | Same week, but 3 to 4 scenes per day, companion arcs, 8 endings | about 15k characters, 8 battles | about 3 milestones |
| B. Three-chapter season | Week 1 (today) becomes chapter 1; chapters 2 and 3 add a new region, new enemies, a growth carry-over, 10 to 12 endings | about 60k characters, 20 battles | about 7 milestones |
| C. Full campaign | 6 to 8 chapters, faction storylines, a town hub with quests | about 150k+ characters, 45+ battles | 15+ milestones, needs real art/audio |

Recommendation: build the structure for B, ship chapter 2 as the proof, then decide whether to continue.

## 3. Structural features needed (engine)
1. Chapters: a chapter file (days, hooks, region, battle set), chapter-end summary screen, carry-over of the hero, companions, flags and a "legacy" bundle; save v7 stores `chapter`. Today `calendar.finished` ends the run; it would end the chapter instead.
2. Quest and journal log: active leads, completed events, clue counts, recap of "what happened"; also the answer to "what do I do next" on mobile.
3. Dialogue upgrades: portraits and expressions per speaker, speaker side, history/backlog, skip-seen, auto-advance, variables and simple text substitution (hero name, companion name), conditional lines inside a node (not only whole nodes), choice memory ("you chose X on day 3").
4. Companion arcs: per companion 3 to 5 bond-gated scenes (unlock at bond thresholds), personal quest, battle ability unlocks tied to the arc, loyalty or conflict flags that change later scenes.
5. Story-battle variety: new objective types (escort, hold, ambush, retreat), scripted events (reinforcements at round N), terrain, boss phases, a pre-battle party picker if more than one active companion is ever allowed.
6. Hub and side content: town screen with locations that open per day, repeatable shops or training, side quests as short routes.
7. Content tooling: a story-graph exporter (Mermaid) so writers can see branches, a coverage report (which nodes/endings the bots reached), a word/character counter per language, a missing-English list.

## 4. Writing and localization workflow
- Write Mandarin first, English second (same as now); each dialogue is a JSON file with keys, so a writer edits text in the locale files and structure in the dialogue file.
- Add a style guide (voice per character, wuxia vocabulary list, names glossary) and a continuity bible (timeline, who knows what) before bulk writing.
- Every milestone ends with the key-lint, glyph check and layout audits we already have; long English lines get a portrait-layout check.
- Font subset grows with new characters automatically (rebuilt from the locale files).

## 5. Quality gates
- Validator: every node reachable, every flag that is read is set somewhere (new check), every ending reachable.
- Bot playthroughs: one per ending plus a random-walk fuzzer (hundreds of seeded runs choosing random available options) asserting no dead end, no stuck dialogue, save/reload equality at every scene boundary.
- Balance simulator extended to all story battles and growth curves across chapters.
- Pacing target: 20 to 30 minutes per chapter; a "story only" mode is not planned.

## 6. Proposed milestones (after M14 release candidate)
| ID | Goal | Main tasks |
|---|---|---|
| M15 | Story bible and structure | World/timeline/character bible, chapter outline for chapters 2 to 3, ending map, style guide; chapters + save v7 + chapter summary screen |
| M16 | Dialogue and journal upgrades | Portraits/expressions, backlog, variables, conditional lines, quest log, story-graph exporter, new validator checks |
| M17 | Companion arcs | Arc scenes for Shen, Lu, Bai (bond-gated), personal quests, ability unlocks, tests |
| M18 | Battle variety | New objectives, scripted events, terrain, boss phases; 6 to 8 new scenarios; balance sim extension |
| M19 | Chapter 2 content | Region, hub, 7 days of scenes, side routes, battles, endings 5 to 8; bot coverage |
| M20 | Chapter 3 and finale | Same, plus final endings matrix and epilogues |
| M21 | Polish and QA | Translation pass, pacing pass, balance pass, fuzzer, performance, release candidate |
Each milestone is split into tasks of 30 minutes or less, as before, about 12 to 15 tasks each.

## 7. Risks
- Volume of writing and translation is the main cost; quality of Mandarin prose needs the user's review (I draft, you approve tone).
- Branch explosion: keep a small set of persistent flags (about 15) and merge branches at chapter ends.
- Placeholder art will feel thin against more story; portraits/expressions are the biggest perceived upgrade (code-drawn medallions are not enough for a story-heavy game; consider commissioning or generating original art later).
- Mobile text length: long scenes need paging and the backlog.

## 8. Decisions needed from you
1. Tier A, B or C (or "B, but pause after chapter 2")?
2. Setting and tone: keep the valley/bandits premise, or open a bigger world (sects, a rival school, a hidden-ruin mystery)?
3. Protagonist: fixed named hero or player-named? Gender neutral, as now?
4. Romance or rivalry options for companions, or friendship only?
5. Ending style: a few big divergent endings, or many small variants?
6. Do you want to supply story outlines/characters, or should I propose them for you to edit?
7. Art direction for portraits (ink style, anime, realistic) if we add them.
