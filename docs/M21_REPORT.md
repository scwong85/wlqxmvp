# M21 Report - Companion arc framework

- Arc = four ordinary world events chained with `schedule`: stage 1 (meet, wide window), 2 (trust), 3 (test; decides the outcome redeemed / alternate / lost), 4 (closing scene; relationship type friend / sworn / romance / rival).
- Bond gates: each stage needs a minimum bond (4 / 8 / 12 / 6); relationship choices need 10 / 14 / 16 (rival is always open). Missing a scene (window passes or bond too low) closes the arc as "lost" and the relationship as "friend": never a dead end.
- Record per companion in `relationships.arcs` {stage, outcome, bond}; new world effects `arc_stage`, `arc_outcome`, `arc_bond`; new requirement `arc_min`; `ArcRules.tags()` hands outcome tags to the future ending composer.
- Template arcs written for Shen Qinghe (herb terraces: her master's poison), Lu Chenzhou (river bend: the unsigned letter, includes a battle) and Bai Yan (old shrine: the stele manual). 12 scenes in Chinese and English.
- UI: the party panel shows "Bond story n/4", the outcome and the relationship type.
- Tests: 2242 unit checks, including full playthroughs of all three arcs. Content order for generators: gen_world, gen_arts, gen_arcs.
