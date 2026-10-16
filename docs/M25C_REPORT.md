# M25c report: Year 3, quarter 11 "Eve of the Platform" (weeks 151 to 165)

- **Platform grounds** (2 areas in the Cangwu region, open from week 151 with the Platform lead): the steps and the pavilions (they reuse the Cangwu backgrounds and music).
- **y3c_alliances** (wk 151-155): pledge to the orthodox houses, the traders, or none (flags pledge_*).
- **y3c_gate_agents** (wk 152-158): the Gate tampers with the awnings; seize them (battle y3_gate_agents) or report to Lei.
- **y3c_midautumn** (wk 157-158): the third Mid-Autumn: share the first mooncake with a group of companions (bond +2 each) or with everyone.
- **y3c_lei_head** (wk 156-160): Head Lei will not run again: take the seat, ask him to stay, or find someone else (lei_endorse / lei_stays / lei_other).
- **y3c_masks_offer** (wk 158-162): the Xuan-, Chi- and Hui-Masks make their final offers; take one or none (offer_*).
- **y3c_cliff_trial** (wk 160-165): the cliff trial with Gu Xingzhou's swordsman (battle y3_cliff_trial) or a night of sitting; either sets cliff_trial_done, **which the sixth realm (return to simplicity) now requires** (RealmRules reads a flag_key, with loc realm.req.cliff / realm.blocked.cliff).
- **y3c_vigil** (wk 162-165): the night before the platform: together or alone.
- 6 random templates, 2 battles, 1 new unit (cliff_master; unit-type limit raised to 32), look head_lei, music mapping for the cliff trial, Mid-Autumn, the Masks, Lei and the vigil.
- **Balance** (sim_year1, realm 5): the gate agents win at 50% of the realm cap; the cliff trial (a 460 HP duel boss) wins from 50%, loses at 45%.
- Generator scripts/gen_year3_q11.py (after gen_year3_q10). Tests: tests/unit/m25c_tests.gd (areas, every choice of every scene, the sixth-realm gate, 165-week walk).
