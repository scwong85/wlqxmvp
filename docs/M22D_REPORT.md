# M22d report: the marsh, the ambush and the Elder Mo fork (weeks 46 to 60)

- 3 marsh areas (fishing flats, reed maze, sunken temple). Opened by the Linjiang rumor (q4_marsh_rumor, weeks 46-52); the temple opens after the ferryman.
- 7 scenes: rumor, ferryman, reed maze (three routes, small bond beats), Winter Solstice (week 53), temple (Nine-Star Gate reacts to the tally), ambush, Elder Mo fork.
- 6 random templates; 1 new battle: the year's hardest (5 Gate enemies incl. a captain, hero + 2 companions).
- Elder Mo fork (weeks 59-60, one scene, three openings): ambush lost -> he falls (seal inherited); won + villager saved -> he stays (valley_kept); won otherwise -> he retires with you (advisor lead). A missed fork resolves as retired, so the year always closes.
- Two new backgrounds (marsh_day, marsh_night).
- Tests: m22d_tests.gd, including three fork outcomes and a 2-seed random walk through year 1 (no hangs or errors).
- Generator: scripts/gen_year1_q4.py (run order: gen_world, gen_arts, gen_arcs, gen_year1, gen_year1_q3, gen_year1_q4).
- Not built yet: music and mining minigames (planned for M23), a realm gate on the tournament.
