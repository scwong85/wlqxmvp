# Timeline

## Calendar
- Slot → week → month → year. 2 slots a week, 5 weeks a month, 12 months a year, 3 years: 360 slots, 180 weeks.
- Display: 第N年 M月 第W周. Seasons: months 1 to 3 spring (春), 4 to 6 summer (夏), 7 to 9 autumn (秋), 10 to 12 winter (冬).
- **Festivals** (fixed weeks every year): 春社 Spring Fair (month 2, week 1), 端阳 Dragon-Boat (month 5, week 1), 中秋 Mid-Autumn (month 8, week 3), 冬至 Winter Solstice (month 11, week 3). Each opens a special market/area event.
- **The gathering:** the 论剑台 gathering is held in year 3, month 11 (absolute week 171 onward). The finale scenes run weeks 171 to 180. The Winter Solstice (month 11, week 3) falls in the middle of it.
- Absolute week = (year−1)×60 + (month−1)×5 + week-in-month.

## Opening month (prologue, year 1 month 1, weeks 1 to 5; already implemented as playable content)
| Week | Beat |
|---|---|
| 1 | Welcome and tutorial (Elder Wen); choose a path (or later) |
| 2 | Shen Qinghe's invitation; Bamboo Pass opens |
| 3 | Bandit raid: the rescue battle (alone or with a companion) |
| 4 | Three visitors ask the hero to side with them (factions) |
| 5 | Preparation (scout, rest, train), the warning; after the last slot, the fight with Chief Kuang. The game continues into month 2 whatever the result |

## Main plot by quarter (12 chapters)
**Year 1: Roots**
- Q1 (months 1 to 3) **玉谷风起 Winds over Jade Valley:** prologue; the aftermath; the first leads; Spring Fair; Lu and Bai join. Elder Wen gives the hero the tally and a first name for the ninth house.
- Q2 (months 4 to 6) **临江风云 Storm in Linjiang:** the hero travels to the city; guilds, pawnshop, night alleys; Su Dai and Li Shan; the first star fragment is traced to the barge guild.
- Q3 (months 7 to 9) **苍梧山门 The Cangwu Gate:** the sect tournament; Xie Wujiu's frame; Mid-Autumn; the Hui-Mask's first appearance.
- Q4 (months 10 to 12) **沉星泽初探 First into the Marsh:** the marsh and the ferryman; the first vault gate; year-end: an ambush, Elder Wen's fate fork.

**Year 2: Cracks**
- Q5 **暗河浮出 The Undertow Surfaces:** the Faceless Gate shows itself; Xia Zhi joins; a house is replaced.
- Q6 **北境烽火 Border Fire:** Yanmen; Xiao Hanchuan joins; a battle for a pass.
- Q7 **海上仙踪 Traces on the Sea:** Penglai; a star fragment; hermit trials; high realm breakthroughs.
- Q8 **裂隙 The Rift:** companion tests; betrayals and rescues; the alliance splits; winter.

**Year 3: Gathering**
- Q9 (year 3, months 1 to 3) **山河动荡 The Province Shakes:** consequences of year 2; the Gate's open moves.
- Q10 **九曜聚合 The Nine Stars Gather:** fragments converge; the vault's second gate; last companion arcs.
- Q11 **论剑台前夜 Eve of the Platform:** preparing the gathering; alliances; Mid-Autumn of year 3.
- Q12 **论剑大会 The Gathering:** the platform, the final battles, the choice, the ending.

## Scene types and how they are scheduled (M16)
- **Fixed event:** id, area, window (start week to end week), requires, outcomes, follow-ups. Cannot be postponed past its window.
- **Random event:** pooled per area; weights, cooldowns, requirements.
- **Follow-up:** an event schedules another within N to M weeks.
- **Lead:** a clue that unlocks an area or event; listed in the journal.
- The player may miss fixed events; missing changes the story (flags), never blocks the plot.

## Year-1 vertical slice (M22) scope
Weeks 1 to 60: prologue, Q1 to Q4, regions 玉谷 / 临江城 / 苍梧山 and the marsh entrance; companions 1 to 6 met (Shen, Lu, Bai, Su, Li, Xie) with stage 1 arcs; about 40 fixed events, 30 random templates, 12 battles; festival events; the year-end fork.
