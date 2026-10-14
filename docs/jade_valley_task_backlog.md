# Jade Valley Chronicles: Plan Completion and Full Task Backlog (v2.1)

This file continues *MVP Orchestrator Plan v2* from section 15 (M6, where the source was cut off) and decomposes every milestone, M0 to M14, into tasks of 30 minutes or less for Claude subagents.

Decisions applied from clarification:
- Scope: complete the plan and produce a full backlog.
- Executors: Claude subagents working in a Linux workspace.
- Environment: Godot, export templates and Android tooling are **not installed yet**.
- Format: markdown.

---

## A. How the orchestrator uses this backlog

1. Dispatch one task at a time per agent role, only after all tasks in **Needs** are `complete`.
2. Give the subagent the task block from this file plus the "Standing rules" below. Subagents start cold, so every task must be self-contained.
3. Verify the handoff against **Acceptance** before marking complete. Do not accept "done" without the stated evidence.
4. If a task would exceed 30 minutes, split it and record the split in the milestone log.
5. A milestone passes only when every task is complete and the milestone exit criteria are demonstrated.

### Standing rules (attach to every task)

- Out of scope by default: any file not listed under the task's scope; any other agent's domain.
- No hard-coded player-visible strings in scripts. Use translation keys.
- No business rules in scene scripts. Rules live in `scripts/domain/` and are testable without nodes.
- Stable English IDs in code and data; Mandarin only in locale files.
- Stop and report if requirements conflict.
- Handoff format:

```text
Task ID:
Agent role:
Status: complete | blocked | partial
Files changed:
Behavior implemented:
Tests run:
Manual verification:
Known limitations:
Follow-up task suggestions:
```

### Agent roles

ENG engine, DOM domain, UI, CMB combat, CNT content, LOC localization, QA, BLD build.

### Environment constraints to plan around

- The workspace shell reaches only an allowlist (package registries and GitHub). Godot releases and export templates are published on GitHub, so they should download. The Android SDK and JDK come from non-GitHub hosts and may be blocked. Task M0-02 checks this first; if blocked, Android export becomes a human-assisted step and M0-09 records that.
- Headless export (`godot --headless --export-release`) is the standard route in a no-display workspace. Visual and touch checks may need a human or a browser pass.
- GUT or GdUnit4 for tests is assumed available via GitHub. M0-04 confirms.

---

## B. Plan completion (continuation from M6)

### M6: All activity stubs (as in v2)

Exit criteria: every activity is selectable, resolves safely, produces a visible result, and shares one activity interface. Full mini-games are deferred.

### M7: Relationships and companions

Goal: three recruitable companions with relationship scores, join, refuse, leave and unavailable states.
Exit criteria: a test run can recruit, lose and re-evaluate each companion through rules only, and the state serializes.

### M8: Menu-based exploration

Goal: data-driven branching nodes with skill checks, resource changes, NPC encounters, recruitment hooks, battle triggers and clues.
Exit criteria: one complete route (Bamboo Pass) playable from node data with no hard-coded text.

### M9: Combat rules core

Goal: deterministic 6 x 8 grid model, initiative, movement, attack, techniques, guard, break/resolve, statuses, terrain.
Exit criteria: scripted battles run headless and produce identical results for the same seed.

### M10: Combat presentation

Goal: landscape battle scene with range previews, telegraphs, projected damage, status icons, log and fast-forward.
Exit criteria: a human can complete the training match by touch and by mouse.

### M11: Battle scenarios and companion in battle

Goal: training match, rescue battle, final crisis; one active companion with two battle abilities.
Exit criteria: all three scenarios winnable and losable; each lasts 3 to 7 turns in balance simulation.

### M12: Story, endings and final crisis

Goal: dialogue nodes for the seven-day arc, day hooks wired, at least three endings from cultivation, relationships and choices.
Exit criteria: three distinct endings reachable in automated playthroughs.

### M13: Localization, accessibility and polish

Goal: full key coverage, English fallback verified, font checks, readable sizes, balance pass, placeholder art and audio.
Exit criteria: zero missing Mandarin keys; English fallback shown for any missing English key; no string literals in scripts.

### M14: Platform QA and release candidate

Goal: Windows, Web and Android builds pass the full smoke suite, with save persistence verified.
Exit criteria: release-candidate checklist signed off by QA with evidence for each platform.

---

## C. Task backlog

Format per row: **ID | Role | Goal and scope | Needs | Acceptance and evidence**. Time budget is 30 minutes or less each.

### M0: Scope and engine spike

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M0-01 | ENG | Write one-page product decision record at `docs/decisions/0001-product.md` from section 2 of the plan | none | File lists all 20 confirmed decisions; no new decisions invented |
| M0-02 | BLD | Probe network allowlist: try downloading Godot 4.x stable and export templates from GitHub releases; test reachability of Android SDK and JDK hosts; write `docs/spike/network.md` | none | Table of host, result, workaround; command output pasted |
| M0-03 | ENG | Install Godot 4.x stable (pin exact version) into `tools/godot/`; record version and checksum in `docs/spike/toolchain.md` | M0-02 | `godot --version` output captured |
| M0-04 | QA | Install a unit-test runner (GUT or GdUnit4) in `addons/`; add one passing placeholder test; document the command | M0-03 | Headless test command exits 0; output captured |
| M0-05 | ENG | Create blank Godot project with landscape 1280x720 base, `canvas_items` stretch, `expand` aspect; commit `project.godot` and folder skeleton from section 13 | M0-03 | Project opens headless without errors; folder tree matches plan |
| M0-06 | LOC | Select and add a CJK font strategy (bundled open-licensed font plus fallback); add `docs/spike/fonts.md` with licence | M0-05 | Licence recorded; font file within size budget noted |
| M0-07 | ENG | Build minimal spike scene: Mandarin label, button, mouse/touch/keyboard echo, orientation readout | M0-06 | Scene runs headless; screenshot or log shows Mandarin glyphs rendered |
| M0-08 | BLD | Configure and export spike scene to Windows (headless); document command | M0-07 | `.exe` and `.pck` produced; export command saved in `docs/spike/build.md` |
| M0-09 | BLD | Configure and export spike scene to Web; serve locally; verify load and Mandarin text in a browser | M0-07 | Web build files produced; browser check noted; cross-origin/threading caveats recorded |
| M0-10 | BLD | Configure Android export (SDK, keystore for debug); export APK | M0-02, M0-07 | APK produced, or blocker documented with exact failing step and human-assist instructions |
| M0-11 | QA | Run spike input matrix (mouse, keyboard, touch) and landscape behavior per platform; record pass/fail | M0-08, M0-09 | Matrix table with evidence; touch result may be marked "needs human device" |
| M0-12 | ENG | Write the engine decision gate result: accept Godot or list triggered blockers from section 3 decision rule | M0-11 | Decision recorded; each of four blocker conditions marked hit/not hit |

### M1: Project shell and navigation

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M1-01 | ENG | Boot scene that loads services and routes to title; `scenes/boot/` | M0-12 | Headless run reaches title scene; log line proves it |
| M1-02 | LOC | LocalizationService autoload with locale files `content/localization/zh_CN` and `en`; key lookup with fallback to Mandarin; named placeholders | M1-01 | Unit tests: hit, missing English falls back, placeholder substitution |
| M1-03 | UI | Title screen (new game, load game, settings) using keys only | M1-02 | No literals in scene scripts (grep check); renders Mandarin |
| M1-04 | UI | Responsive landscape layout container and 16:9 reference scaling helper in `scenes/shared/` | M1-03 | Screenshots at 1280x720, 1920x1080, 2400x1080 show no clipping |
| M1-05 | UI | New game button routes to placeholder hub; load button disabled with key-based tooltip text | M1-03 | Navigation test passes |
| M1-06 | UI | Settings placeholder with language toggle (zh/en) | M1-02 | Toggle switches visible strings; fallback verified |
| M1-07 | QA | Smoke test: boot to title to hub, headless | M1-05 | Smoke script exits 0 |

### M2: State and persistence

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M2-01 | DOM | `PlayerState` with attributes, path, techniques; serialize/deserialize | M1-07 | Round-trip unit test |
| M2-02 | DOM | `CalendarState` (day 1-7, slot 1-2) with serialization | M2-01 | Unit tests for bounds |
| M2-03 | DOM | `ResourceState` (coins, food, herbs, ore, medicine, items) | M2-01 | Unit tests: add, spend, cannot go negative |
| M2-04 | DOM | `CultivationState` (path progress, practice counters) | M2-01 | Round-trip test |
| M2-05 | DOM | `RelationshipState` (score per NPC, recruitment status, flags) | M2-01 | Round-trip test |
| M2-06 | DOM | `GameState` aggregate plus versioned schema (`schema_version`) and migration stub | M2-02..05 | Unknown version returns a typed error, not a crash |
| M2-07 | DOM | SaveService write: one manual slot plus autosave file; atomic write (temp then rename) | M2-06 | Interrupted-write test leaves prior save intact |
| M2-08 | DOM | SaveService read with corrupt-save fallback returning a key for the Mandarin error message | M2-07 | Corrupt, empty and wrong-version fixtures each handled |
| M2-09 | UI | Wire load button to SaveService; show corrupt-save message via key | M2-08 | Manual test with a corrupt fixture shows the message |
| M2-10 | QA | Full round-trip and restart test: save, quit process, relaunch, load | M2-09 | Evidence log; run on at least one platform |

### M3: Seven-day calendar loop

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M3-01 | DOM | Day/slot counters with advance rules (2 slots per day) | M2-10 | Unit tests: slot 2 to next day, day 7 end |
| M3-02 | DOM | Activity availability rules (stamina, resources, day gates) as pure functions | M3-01 | Table-driven tests |
| M3-03 | DOM | Slot consumption API: spend slot plus cost, returns result object | M3-02 | Tests for insufficient resources |
| M3-04 | DOM | End-of-day transition: recovery, autosave trigger, day-start event query | M3-03 | Test shows autosave called once per transition |
| M3-05 | DOM | Event hook registry; register day 3, day 6, day 7 hooks (stub payloads) | M3-04 | Hooks fire on correct day only |
| M3-06 | QA | Calendar playthrough test: advance day 1 to 7 with no combat | M3-05 | Test passes; final state is "crisis pending" |
| M3-07 | QA | Calendar edge tests: save mid-day, load, continue | M3-06 | Slot and day restore exactly |

### M4: Cultivation data model

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M4-01 | DOM | Five attributes definition and bounds in data plus `CultivationRules` | M3-07 | Tests for min/max and growth clamp |
| M4-02 | DOM | Derived values per section 6 formulas (health, stamina, initiative, technique points) | M4-01 | Tests match formulas for sample inputs |
| M4-03 | DOM | Three cultivation paths as data with attribute affinities | M4-01 | Schema validation test |
| M4-04 | DOM | Technique unlock conditions as data and evaluator | M4-03 | Table-driven tests |
| M4-05 | DOM | Activity reward schema and applier (attribute, resource, relationship deltas) | M4-01 | Tests incl. negative and capped rewards |
| M4-06 | DOM | Deterministic skill-check utility with injected seed | M4-05 | Same seed same result; distribution sanity test |
| M4-07 | QA | Cultivation serialization and determinism suite | M4-06 | All pass; evidence attached |

### M5: Cultivation screen

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M5-01 | UI | Cultivation hub scene shell: left hero, center activities, right stats (per section 11) | M4-07 | Layout screenshot at three resolutions |
| M5-02 | UI | Hero summary panel bound to state | M5-01 | Values change when state changes (test) |
| M5-03 | UI | Attribute panel with Mandarin labels and derived values | M5-01 | Keys only; screenshot |
| M5-04 | UI | Resource panel | M5-01 | Screenshot plus binding test |
| M5-05 | UI | Cultivation-path panel | M5-01 | Shows chosen path and unlocked techniques |
| M5-06 | UI | Activity-slot and day display | M5-01 | Updates after slot consumption |
| M5-07 | UI | Activity card list and selection (tap select plus confirm; no hover reliance) | M5-06 | Works with mouse and touch events in test |
| M5-08 | UI | Activity result panel | M5-07 | Shows deltas from result object |
| M5-09 | QA | Landscape usability check on small and large viewports | M5-08 | No clipped text; minimum font size verified |

### M6: All activity stubs

Shared prerequisite: M6-00.

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M6-00 | DOM | Common `Activity` interface: id, cost, preview, resolve(state, seed) returning result | M5-09 | Interface test with a dummy activity |
| M6-01 | DOM | Training (根骨/力道) resolver | M6-00 | Reward tests |
| M6-02 | DOM | Technique practice with safe/balanced/risky drill | M6-00 | Risk affects variance in tests |
| M6-03 | DOM | Meditation (悟性, stamina recovery) | M6-00 | Reward tests |
| M6-04 | DOM | Fishing resolver (timing check abstracted to a seeded check) | M6-00 | Reward tests |
| M6-05 | DOM | Herb gathering route choice check | M6-00 | Reward tests |
| M6-06 | DOM | Mining risk-reward check | M6-00 | Reward tests incl. failure |
| M6-07 | DOM | Hunting target selection | M6-00 | Reward tests |
| M6-08 | DOM | Cooking recipe choice plus resource check, creates temporary buff | M6-00 | Buff expiry test |
| M6-09 | DOM | Music (NPC affinity, Spirit) | M6-00 | Affinity delta test |
| M6-10 | DOM | Chess (Insight, strategy token) | M6-00 | Token grant test |
| M6-11 | DOM | Social visit via dialogue choice delta | M6-00 | Relationship delta test |
| M6-12 | DOM | Rest recovery | M6-00 | Recovery cap test |
| M6-13 | CNT | Activity data files and translation keys for all 12 activities | M6-00 | Every activity has name, description and result keys; key-lint passes |
| M6-14 | UI | Generic activity interaction screen (button-based placeholder interaction) used by all stubs | M6-13 | Each activity selectable and shows result |
| M6-15 | QA | Activity matrix test: each activity resolves safely from several states, including empty resources | M6-12, M6-14 | No crashes; table of outcomes |
| M6-16 | QA | Relevance audit: each activity maps to a use (combat, recruitment, dialogue, economy, ending) | M6-15 | Table in `docs/design/activity_relevance.md`; zero decorative activities |

### M7: Relationships and companions

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M7-01 | CNT | Companion data schema and file template | M6-16 | Schema validated by a test |
| M7-02 | CNT | Three companion definitions (沈青禾, 陆沉舟, 白砚), stats, preferences, conditions | M7-01 | Validation passes; all fields from section 7 present |
| M7-03 | LOC | Translation keys for companion names, bios and abilities | M7-02 | Key coverage test |
| M7-04 | DOM | `RelationshipRules`: score change, preferred-activity bonus, clamping | M7-02 | Table-driven tests |
| M7-05 | DOM | Recruitment condition evaluator | M7-04 | Tests per companion: join, refuse, unavailable |
| M7-06 | DOM | Departure condition evaluator | M7-04 | Tests incl. story-flag departure |
| M7-07 | DOM | `PartySystem`: one active companion, swap rules, availability | M7-05, M7-06 | Cannot have two active; swap test |
| M7-08 | UI | Relationship summary panel | M7-04 | Shows scores and status keys |
| M7-09 | UI | Recruitment prompt dialog | M7-05 | Accept and refuse paths update state |
| M7-10 | QA | Companion lifecycle test across seven days | M7-07..09 | Join, leave and rejoin cases pass; save round-trip |

### M8: Menu-based exploration

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M8-01 | DOM | Exploration node schema (choices, checks, effects, next, battle trigger, clue) | M7-10 | Schema validator test |
| M8-02 | DOM | `ExplorationSystem` traversal and effect application | M8-01 | Traversal tests |
| M8-03 | DOM | Choice gating by attribute, item, relationship or flag | M8-02 | Table-driven tests |
| M8-04 | DOM | Skill check integration with seeded checker | M8-02 | Deterministic outcomes |
| M8-05 | DOM | Exploration flag and clue persistence in save | M8-02 | Round-trip test |
| M8-06 | CNT | Bamboo Pass node graph (6 to 10 nodes) as data | M8-01 | Graph validator: no dead ends, no orphans |
| M8-07 | CNT | Exploration text in Mandarin plus keys | M8-06 | Key-lint passes; no literals in data scripts |
| M8-08 | UI | Exploration screen: narrative panel plus choice buttons | M8-02 | Touch and mouse selection works |
| M8-09 | UI | Check result and effect feedback display | M8-08 | Shows deltas and outcomes |
| M8-10 | CNT | Recruitment hook and NPC encounter nodes | M8-06, M7-09 | Encounter triggers recruitment prompt |
| M8-11 | QA | Route playthrough tests covering all branches | M8-10 | Branch coverage report |

### M9: Combat rules core

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M9-01 | CMB | `Grid` model 6x8 with cells, occupancy, bounds | M4-07 | Unit tests |
| M9-02 | CMB | Terrain cells: cover and hazard effects | M9-01 | Effect tests |
| M9-03 | CMB | Unit model from derived values (health, initiative, break/resolve) | M9-01, M4-02 | Construction tests |
| M9-04 | CMB | Initiative ordering with deterministic tie-break | M9-03 | Tie tests |
| M9-05 | CMB | Movement points and reachable-cell computation | M9-02 | Pathfinding tests incl. blocked cells |
| M9-06 | CMB | Action points and action validation | M9-03 | Invalid action tests |
| M9-07 | CMB | Basic attack range and damage formula | M9-05 | Table-driven damage tests |
| M9-08 | CMB | Technique data schema and resolver (damage, push, status) | M9-07 | Per-technique tests |
| M9-09 | CMB | Guard action and damage reduction | M9-07 | Tests |
| M9-10 | CMB | Break/Resolve meter and stagger | M9-07 | Tests: break triggers and recovers |
| M9-11 | CMB | Status effects framework (duration, stack rule) with two to four statuses | M9-08 | Tests per status |
| M9-12 | CMB | Combo/follow-up opportunity rule | M9-08 | Tests incl. prevented loops |
| M9-13 | CMB | Turn loop and victory, defeat and objective checks | M9-04..12 | Scripted battle completes |
| M9-14 | CMB | Projected damage and preview functions (pure, used later by UI) | M9-08 | Preview equals actual damage in tests |
| M9-15 | CMB | Simple enemy AI: choose move and attack by priority rules | M9-13 | Deterministic with seed |
| M9-16 | QA | Seed determinism suite: 20 seeded battles twice, outputs identical | M9-15 | Hash comparison pass |

### M10: Combat presentation

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M10-01 | CMB | Battle scene shell with grid drawing, left/center board, right panel, bottom log (section 8) | M9-16 | Screenshot at three resolutions |
| M10-02 | CMB | Unit sprites (placeholder) and selection | M10-01 | Tap/click selects unit |
| M10-03 | CMB | Movement range overlay | M10-02 | Matches `reachable cells` from rules |
| M10-04 | CMB | Attack range overlay and target selection | M10-03 | Matches rules |
| M10-05 | CMB | Skill telegraph and confirm/cancel | M10-04 | No action without confirm |
| M10-06 | CMB | Projected damage display | M10-05 | Equals preview function |
| M10-07 | UI | Action panel (move, attack, technique, guard, support, item, end turn) | M10-01 | Each button invokes a rule action |
| M10-08 | UI | Status icons and break/resolve bars | M10-02 | Bound to unit state |
| M10-09 | CMB | Battle log with outcome reasons | M10-07 | Each major outcome has a log entry key |
| M10-10 | CMB | Fast-forward toggle | M10-09 | Speeds animation only; results unchanged |
| M10-11 | LOC | Combat keys (actions, statuses, log lines) | M10-09 | Key-lint passes |
| M10-12 | QA | Touch-only and mouse-only battle completion check | M10-10 | Evidence per input type; hover not required |

### M11: Battle scenarios

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M11-01 | CMB | Enemy unit definitions (max six types) | M10-12 | Data validation |
| M11-02 | CMB | Scenario 1: training match (two simple enemies) | M11-01 | Winnable by test bot |
| M11-03 | CMB | Scenario 2: rescue battle (protect NPC five turns) | M11-01 | Both outcomes reachable |
| M11-04 | CMB | Scenario 3: final crisis (defeat leader or survive condition) | M11-01 | Both objectives work |
| M11-05 | CMB | Companion battle integration (active companion as ally unit) | M11-02, M7-07 | Companion appears only when active |
| M11-06 | CNT | Two battle abilities per companion as technique data | M11-05 | Each executes in tests |
| M11-07 | CMB | Relationship ability usable per companion | M11-06 | Effect tests |
| M11-08 | DOM | Battle result application to state (rewards, flags, relationship) | M11-02 | Round-trip with save |
| M11-09 | DOM | Battle progress save/resume where needed | M11-08 | Interrupted battle restores |
| M11-10 | QA | Balance simulation: 100 seeded runs per scenario with several cultivation builds; 3 to 7 turns target | M11-04, M11-07 | Report with turn counts; out-of-range cases flagged |
| M11-11 | CMB | Balance tuning pass from report (data changes only) | M11-10 | Re-run shows target met or exceptions noted |

### M12: Story, endings, final crisis

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M12-01 | DOM | Dialogue node schema and runner with choices and flag effects | M11-11 | Runner tests |
| M12-02 | UI | Dialogue screen (portrait, text, choices) | M12-01 | Touch and mouse work |
| M12-03 | CNT | Day 1 intro and tutorial dialogue (Mandarin) | M12-01 | Key-lint passes |
| M12-04 | CNT | Day 2 specialization choice event | M12-01 | Path selection sets state |
| M12-05 | CNT | Day 3 recruitment event wired to hook | M12-01, M3-05 | Fires on day 3 |
| M12-06 | CNT | Day 4 serious battle event and aftermath | M12-01, M11-03 | Battle launches and returns |
| M12-07 | CNT | Day 5 relationship/faction choice event | M12-01 | Sets faction flag |
| M12-08 | CNT | Day 6 preparation and optional exploration event | M12-01, M8-11 | Exploration optional |
| M12-09 | CNT | Day 7 final crisis event and pre-battle dialogue | M12-01, M11-04 | Launches final battle |
| M12-10 | DOM | `EndingRules`: evaluate cultivation, relationships, choices to an ending ID | M12-09 | Table-driven tests |
| M12-11 | CNT | Three or more endings (text, keys) | M12-10 | Each ending has unique conditions |
| M12-12 | UI | Ending screen and return to title | M12-11 | Restart run clears state |
| M12-13 | QA | Automated playthroughs reaching each ending | M12-12 | Three distinct endings reached; evidence logs |
| M12-14 | QA | Full-run save/load at every day boundary | M12-13 | No state divergence |

### M13: Localization, accessibility, polish

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M13-01 | LOC | Key-lint script: unused keys, missing zh keys, missing en keys | M12-14 | Report; zero missing zh |
| M13-02 | QA | Hard-coded string scan across `scripts/` and `scenes/` | M13-01 | Zero violations |
| M13-03 | LOC | English translation for all UI keys | M13-01 | UI complete in English |
| M13-04 | LOC | English translation for content keys (activities, companions, endings) | M13-03 | Coverage report; gaps fall back to Mandarin |
| M13-05 | LOC | Font fallback and missing-glyph handling check | M13-01 | Test string with rare glyph shows fallback |
| M13-06 | UI | Minimum font size and contrast pass; touch target size 44 px or more | M13-02 | Checklist complete with screenshots |
| M13-07 | UI | Pause menu: manual save, settings, return to title | M12-14 | Manual save works mid-day |
| M13-08 | ENG | Placeholder art and audio hooks: music, SFX bus and volume setting | M13-07 | Volume saves and loads |
| M13-09 | CNT | Placeholder character portraits and UI frames (original) | M13-08 | No external IP; list assets with licences |
| M13-10 | QA | Performance check: frame time on battle scene (headless metrics or device) | M13-09 | Numbers recorded |

### M14: Platform QA and release candidate

| ID | Role | Goal and scope | Needs | Acceptance and evidence |
|---|---|---|---|---|
| M14-01 | BLD | Scripted Windows release export | M13-10 | One-command build; artifact checksum |
| M14-02 | BLD | Scripted Web release export plus local serve script | M13-10 | One-command build; loads in browser |
| M14-03 | BLD | Scripted Android release export (signing config documented) | M13-10, M0-10 | APK/AAB built or human-assist steps documented |
| M14-04 | QA | Smoke suite: boot to ending headless | M14-01 | Passes on Windows build or headless equivalent |
| M14-05 | QA | Web save persistence check (reload retains save) | M14-02 | Evidence recorded |
| M14-06 | QA | Android install, rotate lock and touch check | M14-03 | Needs human device; checklist handed off |
| M14-07 | QA | Regression run of full unit and integration suites | M14-04 | All pass |
| M14-08 | BLD | Known-issues and build instructions doc | M14-07 | Doc complete |
| M14-09 | QA | Release candidate checklist (all exit criteria across M0-M14) | M14-08 | Signed checklist |

---

## D. Counts and dependency summary

- Tasks: M0 12, M1 7, M2 10, M3 7, M4 7, M5 9, M6 17, M7 10, M8 11, M9 16, M10 12, M11 11, M12 14, M13 10, M14 9. Total **162**.
- Critical path: M0 gate, then M1 to M5, then M6, then M9, then M10, then M11, then M12, then M13, then M14.
- Parallel lanes once M5 completes: M6 content and DOM work, M7 companions, and M9 combat core can run concurrently since they touch different folders.
- Human-assist points: M0-10, M0-11 (touch), M14-03, M14-06.

## E. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Android SDK blocked by network allowlist | M0-02 detects early; human-assisted build documented |
| Web export threading or CJK font load failure | Covered by M0-09 and M0-12 decision gate |
| Combat scope creep | Max six unit types; two terrain effects; no real-time input |
| Content volume in Mandarin | Content agents limited to schema-validated data; key-lint gate in M13 |
| Agent drift across domains | Standing rules plus per-task scope; orchestrator verifies file lists in handoffs |
