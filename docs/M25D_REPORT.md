# M25d report: Year 3, quarter 12 "The Gathering" (weeks 166 to 180) and the end of the campaign

- **The platform top** (area pg_platform, open from week 166).
- **y3d_arrivals** (wk 166-170): three openings by the pledge (orthodox / trade / free).
- **y3d_platform_open** (wk 171-172): the bracket (battle y3_bracket) or the stands; staying out is allowed.
- **y3d_returned** (wk 172-176): an old companion whose arc was lost comes back (Xie, Xia, Su Dai, Li Shan or Xiao, by the "returns" flags): fight them (battle y3_returned) or speak; if nobody returns, a quiet scene. No permadeath.
- **y3d_solstice** (wk 173-174): the last gift scene on the platform (bond +2 to a group).
- **y3d_gate_raid** (wk 174-176): defend the steps (battle y3_platform_raid, 6 enemies) or cover the guests' retreat.
- **y3d_masks** (wk 175-177): the Masks take the platform (battle y3_masks: Xuan-Mask, Chi-Mask and an escort); those who took the Xuan-Mask's offer may talk instead.
- **y3d_the_choice** (wk 177-178): take the seat / refuse and go home / destroy the manual / take the Gate (only after the Xuan-Mask's offer) / walk away. Flags finale_seat, finale_refuse, finale_break, finale_gate, finale_walk plus finale_decided; a missed choice resolves to finale_walk.
- **y3d_ending** (wk 178-179): the finale scene, one of five (by the finale flag); sets finale_done. It needs finale_decided and resolves before the last week so no fixed event is left open. M26 turns these flags (plus arc outcomes and relationship branches) into the ending screen.
- 6 random templates, 4 battles, 1 new unit (xuan_mask).
- **Balance** (sim_year1): the bracket wins from about 45% of the realm-5 cap, the night raid and the Masks from 55% (the Masks last 15 of 16 rounds, a deliberate boss). Earlier Year 3 fights (Q9 to Q11) are fought before the sixth realm, so they were re-checked at the fifth realm's cap of 46: they win at 60 to 70 percent of it, about 28 to 32 points per attribute, which a player who has just entered the fifth realm (attribute total 118 or more) reaches shortly after. The guild hall and vault collapse were softened by one enemy for this.
- **Whole campaign walk** (m25d_tests): a seeded random walk over all 180 weeks (360 slots) finishes without error and meets year-3 scenes; the m16 fixed-event sweep passes for every seed.
- Generator scripts/gen_year3_q12.py (after gen_year3_q11). Tests: tests/unit/m25d_tests.gd.
- **Year 3 totals**: about 35 fixed scenes, 28 random templates, 13 battles, 6 new areas (3 vault, 3 platform), 8 arcs at four stages, 3 new backgrounds (two vault, the platform reuses Cangwu's).
