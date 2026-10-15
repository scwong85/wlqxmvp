# Jade Valley Chronicles: full campaign design and plan (v2, draft for approval)

Replaces `STORY_EXPANSION_PLAN.md`. Nothing here is implemented yet. Decisions already made by you are marked **[decided]**.

## 0. Decisions so far
- **[decided]** Full campaign, 3 in-game years. Time: 1 month = 5 weeks, 1 week = 2 action slots, 12 months a year → 36 months, 180 weeks, 360 slots.
- **[decided]** Open, bigger world; style of 武林群侠传 (free exploration, many people to meet, learn skills, recruit companions, several big endings). All names, places and text are original.
- **[decided]** Hero named by the player, plus gender and a chibi look (a few hair/outfit choices). Dialogue stays gender-neutral where possible.
- **[decided]** 8 recruitable companions, each with a story arc whose result decides outcomes. Every companion offers all relationship options (friendship, sworn bond, romance, rivalry) when their conditions are met.
- **[decided]** Few big endings plus small variations for accomplishments (realm reached, skills mastered, each companion's fate, life-skill titles, faction standing, wealth).
- **[decided]** Chibi art: code-drawn now, replaceable by sprite sheets later without code changes.
- **[decided]** Battles: hero + up to 2 companions. Events can start battles.
- **[decided]** No game over: losses and missed events change the story; the run always reaches an ending.
- **[decided]** Fishing is the first real minigame; other activities (mining, chess, music, cooking, ...) use the same framework, text plus short animation until their minigame exists.
- **[decided]** Build order: foundations, then a complete year-1 vertical slice, then years 2 and 3. M14 (release QA) is skipped for now.

## 1. World (proposal, please edit)
**Setting:** 青岚州 (Qinglan Province) in the 景昭 era. The martial world (江湖) keeps its balance through the 玉契 (Jade Accord): every three years the sects meet at the 论剑台 (Sword-Debate Platform) and choose a 盟主 (Alliance Head) who holds the Accord.

**Hero:** an orphan raised in 玉谷 (Jade Valley), carrying half of an old jade tally. At the start the village is raided; the trail leads out of the valley.

**Overarching story (3 years):**
- A hidden group, 无相门 (the Faceless Gate), wants the nine fragments of the 九曜残卷 (Nine-Star Manual) to force a new order. The jade tally is a key to the lost vault under 沉星泽.
- Year 1, "Roots": learn the trade of the martial world, find out the raid was a probe, the first star fragment, the first alliance.
- Year 2, "Cracks": the Faceless Gate surfaces; sects split; companion arcs deepen and are tested (betrayals, rescues); the vault's second gate; war on the border and a sea expedition.
- Year 3, "Gathering": the fragments converge; every choice (and companion fate) shapes who stands on the 论剑台; final confrontation and the endings.

**Regions and areas (about 25 areas, opened over time by events):**
| Region | Flavour | Example areas |
|---|---|---|
| 玉谷 | home valley | village, bamboo pass, old shrine, river bend, herb terraces |
| 临江城 | river trade city | docks, market, teahouse, escort bureau, pawnshop, night alleys |
| 苍梧山 | orthodox sect mountain | gate steps, training courts, library, cliff cave, hot spring |
| 沉星泽 | marsh and ruins | reed maze, sunken temple, fishing flats, vault gate |
| 北境雁门 | border fortress | fort, caravan road, snow pass, battlefield |
| 东海蓬岛 | island hermits | harbour, coral cave, lighthouse monastery |

## 2. Companions (8) and arcs
Each arc is 5 to 6 scenes (3 stages: meet, trust, test) with a personal quest, a battle, a bond-gated relationship branch, and 3 outcomes (redeemed, lost, or an alternate path). Outcome tags feed the ending composer.
| # | Name | Role | Arc in one line |
|---|---|---|---|
| 1 | 沈清禾 (exists) | herbalist-swordswoman, healer | her master's poison case; the Accord's secret medicine |
| 2 | 陆沉舟 (exists) | courier, speed | a lost letter that proves a betrayal; loyalty vs. money |
| 3 | 白砚 (exists) | scribe, insight | decoding the manual fragments; knowledge vs. safety |
| 4 | 谢无咎 | disgraced sect prodigy, spear | clearing his name; rivalry that becomes friendship or enmity |
| 5 | 苏黛 | street musician, support | a song that hides a map; music minigame ties |
| 6 | 厉山 | blacksmith, shield | a lost forge, ore and legendary weapons; mining minigame ties |
| 7 | 夏芷 | young thief, agility | she was raised by the Faceless Gate; torn between families |
| 8 | 萧寒川 | border general's son, saber | duty to the army vs. the hero; the border war |

Relationship options per companion (when conditions are met): friend, sworn sibling, romance, rival. Each has a different last arc scene and ending tag.

## 3. Endings
Five big endings, chosen by the final alliance state plus the main choices:
1. **盟主之路** (Alliance Head): unite the sects and hold the Accord.
2. **隐世宗师** (Recluse Grandmaster): refuse the seat, found a school in Jade Valley.
3. **破局者** (Breaker): destroy the manual and dissolve the Accord's power.
4. **暗潮** (Shadow Path): take over the Faceless Gate.
5. **江湖远行** (Wanderer): the fragile fallback when the alliance fails.

**Epilogue composer** adds small variations: realm reached, signature skill, each companion's outcome (8 tags), relationship result, life-skill titles (fishing master, ...), faction standing, wealth, hometown fate. About 150 short snippets (80 characters each).

## 4. Calendar and the event system (core of the game)
- Time index 1 to 360 (slot). Display: "第1年 三月 第2周 上半 / 下半".
- Seasons (3 months each) and festivals at fixed weeks; some areas are seasonal (snow pass in winter).
- **Event definition (data):** id, area, window (start week, end week), requires (flags, bond, realm, items, leads, season), priority, once or repeatable, follow-ups (spawn event X within N to M weeks), outcomes (attribute gains, skill/manual, items, bond, flags, battle, minigame, scheduled events, area unlock/lock), scene reference.
- **Fixed events:** happen in a window, cannot be postponed past it (missing them is a story choice, never a dead end). About 150.
- **Random events:** weighted pools per area with conditions and cooldowns; templates with variable text. About 120.
- **Follow-ups and companion quests:** an event can open a quest line that appears as new events later; companion quests are normal events with bond gates.
- **Leads (线索):** clues unlock areas and events; the journal lists active leads and "next hints".
- **Outcomes can raise attributes** (training grounds, hidden manuals, tonic, spiritual springs), as you asked.
- **Validator and fuzzer:** every event reachable, no flag read but never set, windows consistent, random-walk bots (hundreds of seeded runs) check no dead end, save/reload equality at every scene boundary.

## 5. Exploration tab (map)
- A new **Map tab** next to Hero / Activities / Stats (portrait: tab bar; landscape: a panel). It shows regions and areas as cards (and a simple painted map backdrop later).
- Each area shows: open / closed / locked-with-reason, number of known events (with "!" for fixed events due soon), travel cost (1 slot, long trips 2).
- Which areas can be explored depends on events and leads. Some are open only during certain weeks (festival market) or only after a quest.
- Visiting an area runs: fixed event due → else a random event from the area pool → else a "wander" result (small gain). The player can choose to keep exploring or leave.
- Existing Bamboo Pass route and its choices are converted into the first area events.

## 6. Story board (cinematic scenes)
A reusable **StageView** used by dialogues and event scenes:
- Layers: background (code-drawn scene by id, e.g. "valley_dawn", "teahouse_night"), up to 4 character slots (left / centre / right), foreground effects, dialogue box with nameplate and portrait bust.
- **Chibi characters:** a code-drawn rig (head, hair, eyes, body, outfit colour, weapon). Poses: idle, walk, bow, laugh, cry, angry, think, hit, victory, kneel, train, sword, fish, mine, music, chess. Expressions swap eyes/mouth.
- **Scene commands** inside a dialogue node: `bg`, `show` (who, slot, pose, face), `hide`, `move`, `pose`, `shake`, `flash`, `fade`, `sfx`, `music`, `wait`, then the line and choices. The existing dialogue format is extended, so our current scenes keep working.
- Rig is a skin interface (`ChibiSkin`): swap the code rig for sprite-sheet skins (PNG sheet + JSON) per character with no engine change.
- Backlog (history), skip-seen, auto-advance and reduced-motion option.

## 7. Training and hobby animations ("gif")
- A GIF file cannot play in the web build, so every activity gets a 2 to 3 second animation clip: the hero's chibi performing the action (training: punches; fishing: casting; meditation: sitting with qi glow; ...), tap to skip, option "play activity animations" in Settings.
- Clips are data (timelines of pose keys); real artists can later supply sprite sheets for the same clip ids.

## 8. Minigame framework
- `MinigameHost` scene and a `Minigame` interface: `start(params, rng)` → result `{score 0..1, grade, bonus}`; registry `content/minigames.json` mapping activity ids to minigame ids; activities keep a text/animation fallback.
- The result scales the activity rewards (grade multiplier); a "quick resolve" option uses an expected value so players can skip.
- Touch, mouse and keyboard supported; deterministic seeds so headless tests can replay a scripted input.
- First: **fishing** (timing and tension bar, fish table by area/season/rod, rewards food and money). Mining, music (rhythm), chess and cooking later.

## 9. Skill and power ascension (deeper)
1. **Realms (境界)** for inner power, 7 steps: 初窥门径 → 登堂入室 → 小有所成 → 融会贯通 → 炉火纯青 → 返璞归真 → 宗师. Each breakthrough needs attribute thresholds, a manual or insight event, sometimes an item or a trial battle; it raises attribute caps and combat stats and adds technique slots.
2. **Techniques (招式)** level 1 to 10 by practice and use in battle; tier-ups change effects; at level 5 and 10 choose an evolution branch.
3. **Manuals (秘籍)** found by events, taught by people (bond or favour needed), or bought; some are mutually exclusive.
4. **Path skill trees:** three paths, about 12 nodes each, ending in a signature 绝学.
5. **Duo techniques (合璧)** with each companion at high bond; they use the two-companion party.
6. **Equipment:** weapon, armour, charm; blacksmith upgrades with mined ore (tie to 厉山).
7. **Life skills:** fishing, mining, medicine, music, chess, cooking levels that give passive benefits and ending titles.
Combat rules gain: more technique slots by realm, party of 3, duo techniques, new objectives.

## 10. Hero creation and chibi
New-game screen: name entry (Chinese or English, 1 to 8 characters), gender, hair and outfit colour. The same data drives the chibi rig everywhere (map, stage, battle token, ending).

## 11. Scale (estimates)
About 25 areas, 150 fixed events, 120 random templates, 8 companion arcs (about 48 scenes), 12 main chapters (about 70 scenes), about 45 battles, 5 endings plus about 150 epilogue snippets. Roughly 170k Chinese characters, then English. This is a very large writing job: I draft everything, and you review tone and plot at each milestone.

## 12. Plan (replaces M14 onward)
**Phase F, foundations (every item ships with tests and published builds):**
| ID | Goal | Main tasks |
|---|---|---|
| M15 | Bible and calendar | World/character/arc/ending bible docs; calendar v2 (5-week months, 3 years, windows); save v7 with migration; time display; first month = prologue (current week content reworked) |
| M16 | Event engine | Event data model, fixed/random/follow-up scheduler, leads, area states, outcomes, validator, fuzzer bots |
| M17 | Map tab | Area cards, locks and reasons, travel cost, event cards, journal and leads log, portrait and landscape |
| M18 | Story board | StageView, chibi rig, backgrounds, scene commands, dialogue integration, backlog, hero creation screen |
| M19 | Animations and minigames | Activity clips, settings option, minigame host and registry, fishing, tests with scripted input |
| M20 | Ascension | Realms, technique levels, manuals, skill trees, equipment, life skills; combat integration (party of 3, duo techniques) |
| M21 | Companions framework | Arc engine (stages, relationship branches, outcome tags), 3 existing companions' arcs as the template |
**Phase Y1, vertical slice:**
| M22 | Year 1 content | Prologue month, 4 chapters, regions 玉谷 / 临江城 / 苍梧山 first areas, events, battles, arcs of companions 1 to 4 (stage 1), Year-1 festival |
| M23 | Year 1 balance and release | Balance sim for the year-1 curve, fuzzer coverage, polish, published build for your review |
**Phase Y2/Y3:**
| M24 | Year 2 | Chapters 5 to 8, 沉星泽, 北境, arcs continue, new companions 5 to 8 recruited |
| M25 | Year 3 and finale | Chapters 9 to 12, 蓬岛, final gathering, 5 endings |
| M26 | Epilogue composer | Accomplishment tags, snippets, ending screen sequences |
| M27 | Translation, polish, QA | English pass, pacing, balance, performance, platform smoke, release candidate |
Each milestone is split into tasks of 30 minutes or less (about 12 to 18 per milestone, roughly 200 in total).

## 13. Risks and mitigations
- **Writing volume:** write in vertical slices and keep a continuity bible; you approve the bible and each year outline before bulk writing.
- **Placeholder chibi art:** a code-drawn rig will look simple; the skin interface lets real art replace it without rework.
- **Balance across 360 slots:** simulator-based curve checks per quarter.
- **Branch explosion:** about 20 persistent flags, companion outcomes as small tags, branches merge at chapter ends.
- **Mobile text and map usability:** every screen keeps the layout audit (font, 44 px, viewport) and portrait-first design.

## 14. Please confirm or edit
1. World name, factions and the main plot above (青岚州, 玉契, 无相门, 九曜残卷).
2. The 5 new companions (谢无咎, 苏黛, 厉山, 夏芷, 萧寒川) and their arcs.
3. The 5 endings.
4. Romance content rating: keep it tasteful and non-explicit.
5. Whether to start with M15 (bible plus calendar) next.
