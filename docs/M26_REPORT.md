# M26: five endings and the epilogue composer
- `scripts/gen_endings.py` writes `story/endings.json` (alliance_head, recluse, breaker, undertow, long_road; first match wins, long_road is the fallback) and `story/epilogue.json` (96 tagged snippets, English + Mandarin).
- `EndingRules` gained flags_any, realm_min, kept_min, outcome_any, skill_min, coins_min; `EpilogueRules.compose` picks the first matching snippet per section (why, realm, skill, one paragraph per companion, faction, pledge, deeds, hometown, wealth, final image).
- The ending screen shows the composed epilogue. Tests: `m26_tests.gd` (table, priority, composer, text in both languages); m12/m15 updated.
- Notes: the final-choice flags decide the route, and a choice whose conditions don't hold falls to the Long Road with an explanation line. Prologue endings removed.
