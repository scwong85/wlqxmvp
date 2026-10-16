# M25a report: Year 3, quarter 9 "The Province Shakes" (weeks 121 to 135)

Year 3 outline approved with defaults (docs/bible/YEAR3_OUTLINE.md). Note: Shen, Lu and Bai already have a stage-4 relationship scene from M21, so the remaining five stage-4 scenes are spread over M25a (Xie, Xia) and M25b (Su Dai, Li Shan, Xiao).

- **y3_new_year** (wk 121-123): three openings by the council flags (orthodox, trade, free).
- **y3_gate_opens** (wk 122-128): the Gate takes the old guild hall openly; storm it (battle y3_guild_hall) or warn the houses.
- **y3_house_summons** (wk 124-130): pick the orthodox, trader or empty seat (flags seat_*).
- **y3_valley_returns** (wk 126-132): by Elder Mo's fate (fallen, kept, away); the ninth house is named (lead ninth_house).
- **y3_chi_mask** (wk 128-134): the Chi-Mask's challenge; duel (boss battle) or slip away.
- **y3_border_burns / y3_border_choice** (wk 130-135): Yanmen again; the opening depends on whether the ranks were broken; then hold the wall (battle) or cover the retreat.
- **Stage 4 for Xie Wujiu (wk 124-136) and Xia Zhi (wk 128-140):** the relationship scene (friend 10, sworn 14, romance 16, rival always open, gated by bond). A lost arc gets a short farewell and sets xie_returns / xia_returns (a possible later boss or rescue target). A missed stage 4 closes the arc. To tell the outcomes apart, the stage-3 events of year 2 now also set flags arcout_<companion>_<outcome> (gen_year2_q8 patched).
- 8 random templates (ry9_*), 3 battles, 2 new units (chi_mask, gate_elite), look mask_chi, 4 leads.
- **Balance** (sim_year1, realm 5): guild hall, Chi-Mask duel and the border defence win at about 55% of the realm cap and fail at 45%.
- Generator scripts/gen_year3_q9.py (after gen_year2_q8). Tests: tests/unit/m25a_tests.gd (every opening, both battle choices, all relationship branches, lost-arc farewells, a 135-week walk).
