# M20a Report - Ascension foundations

Delivered
- 7 realms (content/cultivation/realms.json): attribute cap 12 -> 99, HP/TP bonuses, breakthrough costs 8 stamina and one slot.
- Breakthrough requirements: path progress, attribute total, technique-level total. Hero sheet scene (Cultivation > "xiu wei" button) shows realm, requirements, technique levels, life skills.
- Technique levels 1-10 (XP from battles and technique practice); level adds damage/heal in battle.
- Life skills (fishing, mining, medicine, music, chess, cooking) level with use and add reward bonus.
- Cultivation hero panel now shows the hero's chibi look and realm name.
- Save schema tolerant: new fields technique_xp, realm, attr_cap, tech_levels.

Verification
- Unit: 1883 checks, 0 failures. Headless smoke: SMOKE_OK.
- tests/sim_progress.gd: steady player reaches realm 6 around week 170 of 180 (realm 3 ~week 23, realm 5 ~week 75). Listening Rain path is slower (realm 4 by 100), to be balanced in M23.

Next: M20b manuals, skill trees, equipment; M20c party of 3 and duo techniques.
