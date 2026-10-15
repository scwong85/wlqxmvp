# Companion arcs and endings

## Arc structure (all companions)
Three stages, each gated by bond and by time windows; every stage is one or two scenes plus a task.
1. **Meet / Trust:** first meeting (existing for Shen, Lu, Bai), recruit, a personal errand.
2. **Burden:** their hidden problem surfaces; a quest across areas; a battle or minigame.
3. **Test:** a decision with consequences, set at a story-critical moment (usually year 2 or 3). The player can be present or absent (absent means the arc resolves without the player: usually the worse outcome).

**Outcome tags** (stored as flags `arc_<id>_<tag>`): `redeemed` (best), `parted` (they leave on their own path), `fallen` (worst; may become an enemy or die offstage). Relationship branch flags: `bond_friend`, `bond_sworn`, `bond_romance`, `bond_rival`; chosen in stage 3, decided by earlier choices and bond score. Anyone can take any branch if its conditions are met.

## The eight arcs
| Companion | Burden | Quest places | Test | Redeemed | Parted | Fallen |
|---|---|---|---|---|---|---|
| 沈清禾 | Her master was poisoned; the poison matches a medicine the Accord's houses share | herb terraces, Listening-Rain Hall, Linjiang alleys | Choose between exposing the poisoner (a house elder) and protecting the Accord's truce | Becomes healer-head of Listening-Rain, unlocks the antidote ending line | Leaves to heal the border | Takes revenge, joins the Gate's shadow |
| 陆沉舟 | A lost letter proves a betrayal in the escort bureau | docks, escort bureau, caravan road | Deliver the letter to the right hand or sell it | Reforms the bureau; gives travel shortcuts | Retires to the road alone | Sells the letter; the bureau burns |
| 白砚 | Decoding the manual fragments; his teacher hid one | library, academy, sunken temple | Burn a dangerous fragment or keep knowledge alive | Writes the true history; unlocks manual endings | Withdraws to the academy | Obsessed; the Gate uses his work |
| 谢无咎 | Framed at Cangwu for a theft | courts, library, cliff cave | Prove innocence publicly (humiliating the master) or quietly | Returns as an honoured teacher or founds a school with the hero | Walks away from sects | Becomes an enemy champion |
| 苏黛 | A song passed down in her family hides a map | market, teahouse, coral cave | Play the song for the Gate or hide it forever | Song becomes the key to the ninth fragment | Travels on as a bard | The song is stolen |
| 厉山 | His forge was burned to hide ore from the mine | iron-hill mine, docks, forge | Rebuild with Gate gold or with the hero's help | Master smith; legendary weapons | Retires to the forge | Works for the Gate |
| 夏芷 | Raised by the Gate; ordered to steal the hero's tally | night alleys, market, vault gate | Complete the theft or defect | Defects; informs on the Gate; strong "Breaker" line | Disappears | Becomes the Gate's lieutenant |
| 萧寒川 | The garrison's orders versus the villages below the fort | fort, snow pass, battlefield | Obey the order or break ranks to protect people | Leads the garrison for the alliance | Resigns, becomes a wanderer | Dies holding the pass |

Companion deaths are possible in the *fallen* outcome only, and always offstage or in a chosen scene; there is no permadeath in battle.

## Hero stats that feed endings
Realm reached, signature skill (highest-level technique), life-skill titles, faction standing (pavilion / couriers / scribes / neutral), wealth bracket, hometown fate (valley saved / rebuilt / lost), Elder Wen's fate.

## The five big endings
Evaluated at the end of year 3 (or earlier if the finale triggers). The first matching row wins.

| # | Ending | Core condition | Feel |
|---|---|---|---|
| 1 | **盟主之路 Path of the Alliance Head** | Fragments gathered and Accord kept (≥ 6 of 8 companion outcomes not `fallen`; alliance standing high) | The hero holds the Accord and leads the gathering |
| 2 | **隐世宗师 Recluse Grandmaster** | Hero refuses the seat, realm ≥ 宗师 or signature skill maxed, valley saved | A school in the valley, the world at peace from afar |
| 3 | **破局者 The Breaker** | Hero destroys the manual (needs Bai Yan's or Xia Zhi's `redeemed`), or the Gate dismantled | The Accord ends; the province must find a new peace |
| 4 | **暗潮 The Undertow** | Hero takes the Gate (needs the Hui-Mask contact and Xia Zhi `fallen` or Xuan-Mask alliance) | Order by hidden hands; companions diverge |
| 5 | **江湖远行 The Long Road** | Fallback: no gathering holds; the hero leaves | Bittersweet wandering, companions' own ends |

## Epilogue composer (M26)
The ending screen is a sequence: headline ending; hero summary (realm, signature skill, titles); one snippet per companion (outcome + relationship branch + something small); faction line; hometown line; wealth line; a final image line. About 150 snippets of ~80 characters, written as tagged fragments with conditions, composed by a rules table (like the endings table) and covered by tests.

## Flags used by the prologue (already in the game)
`bandits_defeated`, `villager_saved`, `faction_pavilion|couriers|scribes|neutral`, `crisis_warned`, `scouts_won|scouts_beaten`, `scout_done|rested_before_crisis|trained_before_crisis` (names may differ in data; M16 tooling generates `flags.md`).
