# M6 report: all activities

## What changed
- Activities can have **approaches** (data-driven `options` in `activities.json`): cost extras, check difficulty shift,
  replacement rewards, and extra stamina lost on a failed risky check. 10 of 12 activities have them; meditation and rest are plain.
- **Buffs**: cooking grants a timed attribute bonus (next 3 slots). Buffs count in skill checks, are listed on the hero panel, and expire with a message.
- **Strategy tokens** from chess; **affinity** per chosen NPC from music and social visits (gift option costs coins).
- UI: pressing Execute on an activity with approaches opens a chooser showing reward, cost, success chance and why something is blocked; Cancel changes nothing.
- Save schema **v3** (adds buffs) with v2 -> v3 migration; content validator checks options and buffs.

## Evidence
- Unit: 481 checks pass, including risk variance (safe > balanced > risky chance), buff expiry timing, token and affinity deltas,
  and a 156-case activity matrix (every activity x approach x 6 starting states: no crashes, no negatives, refusals change nothing).
- UI smoke and browser run (4 viewports) pass; chooser screenshot: `docs/spike/screens/m6_chooser.png`.
- Relevance table: `docs/design/activity_relevance.md`.

## Notes
- Interactions are button choices, not mini-games (matches M6-14 placeholder scope).
- Several outputs (herbs, ore, tokens, affinity) have no consumer until M7/M9/M12; see the relevance doc.
