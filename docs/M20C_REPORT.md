# M20c Report - Party of three and duo techniques

- Party: the hero plus up to two joined companions fight together (`relationships.active` and `relationships.second`). A third companion replaces the second place; "Step out" removes someone from the party without dismissing them. Recruiting fills the first free place.
- Duo techniques: one per companion (Shen Qinghe, Lu Chenzhou, Bai Yan), unlocked in battle for the hero when that companion is in the party and the bond is 12 or more. The partner adds power/2 + 2 to the hit; if the partner has fallen the technique cannot be used.
- UI: the party panel shows both fighters, a "step out" button and whether the duo is ready or what bond it needs.
- Save: `second` added to the relationships (older saves load with one companion).
- Tests: 2110 unit checks; smoke passes.
