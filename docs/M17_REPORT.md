# M17 — Map tab and Journal

**Status:** done (unit 1604 checks; browser smoke covers opening the Map from training and returning, at all 6 sizes, with the layout audit).

- New **Map** screen (button next to Explore on the training screen). Areas grouped by region, each marked *Open*, *Something due*, *Locked* or *Closed*. Selecting one shows its description, travel cost, and — if not open — why (season, lead, week, story). **Go** spends the travel time and plays the due fixed event, a random one, or a short wander with a small reward; battles and dialogue scenes open as usual.
- **Journal** tab: leads (name + hint), events that happened (with week), and missed ones.
- Validator now also checks event titles and lead texts. Event titles and lead texts added in zh/en via `scripts/gen_world.py`.
- Existing Explore (bamboo pass) is unchanged; it remains the prologue route.

Next: M18 — story board (backgrounds, chibi characters, dialogue) and the hero creation screen.
