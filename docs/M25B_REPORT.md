# M25b report: Year 3, quarter 10 "The Nine Stars Gather" (weeks 136 to 150)

- **Sunken vault** (3 areas in the marsh region, open from week 136 with the second-gate lead): the stair, the star hall and the tally door; the hall and door open when the second gate is open. Two new backgrounds (vault_stair, vault_hall) with music mapping.
- **y3b_fragments** (wk 136-140): the star count with Bai Yan.
- **Stars of the companions** (wk 138-148, each needs bond 8): Su Dai's song (not if she sold it), Li Shan's forge mark (not if he took the gold), Bai Yan's script. Flags star_song, star_forge, star_pattern.
- **y3b_second_gate** (wk 138-144): fit the tally, or break the door (battle y3_vault_guardian); either opens the gate (a lost fight still opens it, so there is no dead end).
- **y3b_xuan_mask** (wk 142-148): the Xuan-Mask's offer (accept, refuse or deceive: flags xuan_pact / xuan_refused / xuan_deceived).
- **y3b_ninth_star** (wk 144-150): the ninth fragment is read, the Hui-Mask speaks (lead manual_truth).
- **y3b_vault_collapse** (wk 146-150): hold the door (battle) or run with the fragment (star_lost).
- **Stage 4** for Su Dai (wk 138-150), Li Shan (wk 134-146) and Xiao Hanchuan (wk 140-152): friend / sworn / romance (gated by bond) / rival; a lost arc gets a farewell and sets su_returns / li_returns / xiao_returns. All eight arcs now have four stages.
- 8 random templates (ry10_*), 2 battles, 1 new unit (vault_guardian, 24 unit types in total), look mask_xuan.
- **Balance** (sim_year1, realm 5): the guardian and the collapse win at about 55% of the realm cap.
- Generator scripts/gen_year3_q10.py (after gen_year3_q9; its events use the id prefix y3b_ so that a rerun of M25a does not remove them). Tests: tests/unit/m25b_tests.gd (areas, stars, gate, Xuan-Mask, ninth star, collapse, six stage-4 branches plus three farewells, 150-week walk).
