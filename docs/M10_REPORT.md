# M10 report: combat presentation

Status: done. Battles are playable with touch or mouse, in portrait and landscape.

## What you can do now
- Title screen: **Practice battle** (training match). Exploration: when a story node triggers a fight (Bamboo Pass
  "bandit scouts" on a failed sneak), the choices are replaced by one **Fight** button.
- Board: 6x8, drawn in code. Portrait shows it upright above the controls; landscape turns it a quarter turn and puts
  the controls on the right. Rotating a phone mid-battle changes only the view.
- Units: jade circles for your side, red diamonds for opponents, gold for the person you protect; first character of the
  name as a glyph, HP bar (green), resolve bar (amber), status dots (bleed red, slow blue, weaken purple), "!" when broken,
  an arc when guarding, a gold ring on the unit whose turn it is. Tapping any unit inspects it.
- Controls: Move, Attack, Support, Item, Guard, End turn. Attack/Support open the technique list (range and cost shown),
  then you tap a highlighted target and the panel shows the projected damage, resolve loss, modifiers and
  "will break" / "will defeat". **Nothing happens until Confirm**; Cancel goes back to target choice.
- Free follow-ups after a break appear as Strike / Skip.
- Opponent turns play step by step (move, attack, follow-ups) with floating numbers. **Fast** only shortens the waits.
- Log lines explain each outcome with its modifiers; the result panel gives the reason (all enemies down, leader down,
  survived, party lost, protected person lost, out of rounds).

## Rules of presentation
- The screen never computes combat itself: previews call `Battle.preview_attack/support` (same function as the real hit),
  enemy moves come from `BattleAI.decide` (same function the tests auto-play with).
- A battle is not saved mid-way. If the game is closed, the story trigger is still pending and the fight restarts.
- Finishing a battle spends medicine used in it and clears the trigger. Rewards and penalties come with M11-M12;
  right now losing has no extra cost.
- Scenario for story battle `bandit_scouts` added (2 scouts + archer).

## Tests
- Unit: 1117 checks, 0 failures (new: story trigger to scenario mapping, log text for every shown event in both languages,
  starting and finishing a battle through the game session).
- Headless UI: a full battle won with only button presses and board taps (landscape), a cancel mid-way that leaves the
  battle untouched, preview text equals the real damage, rotation keeps the battle hash, portrait and landscape layout audits
  clean, Fight button from exploration returns to the route.
- Browser (Chromium, six sizes): practice battle opens, fast toggle, move, guard, end turn, opponents act, player turn returns;
  layout audit clean at every size. Screenshots `docs/spike/screens/m10_*`.

## Touch-only and mouse-only (M10-12)
Both use the same tap/click path (`cell_tapped`, buttons). No hover is needed anywhere. The browser run uses touch contexts
for phone sizes and mouse for desktop sizes. Real-device checks are still pending.

## Known gaps
Placeholder shapes only; no sound; no animation beyond floating numbers; no undo of a move; no battle rewards.
