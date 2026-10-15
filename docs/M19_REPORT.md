# M19 — Activity clips, minigame framework, fishing

- **Activity clips:** choosing an activity plays a 2.4 s clip of your chibi hero doing it (training punches, sword drills, meditating, fishing, gathering, mining, hunting, cooking, music, weiqi, visiting, resting), then performs it. Tap, click or Enter/Space/Esc skips. Clips are data (`content/clips.json`: background, duration, pose timeline), validated for every activity; sprite-sheet clips can reuse the same ids later. Setting: "Animations: on/off".
- **Minigame framework:** `Minigame` interface (pure logic: start(params, seed), set_input, step, snapshot, result), registry `content/minigames.json` (activity → minigame), `MinigameRules` (score → grade → reward multiplier: poor ×0.5, ok ×1, good ×1.25, perfect ×1.5; seed from run/week/slot), generic `MinigameHost` screen (intro with Start and Quick resolve, play, graded result, Collect), and a perform path that takes the play record in place of the skill check. Quick resolve pays like an average attempt; setting "Minigames: on/off".
- **Fishing:** hold (mouse, touch, Space/Enter/Up/W) to lift the hook bar, release to sink; keep the fish inside the bar to fill the catch meter before 20 s. Approach "Rapids" is harder (faster fish, shorter bar). Deterministic per seed; tests replay it with scripted input (a simple bot catches easy fish ≥80%, nothing-input never catches).
- Browser test: `?noanim=1` disables clips/minigames for the scripted flow; `?demo=minigame` opens fishing directly for screenshots and the layout audit.
- Tuning is by bot, not human; real play will tell whether the bar speed feels right (constants at the top of `fishing_game.gd`).

Next: M20 ascension (realms, technique levels, manuals, skill trees, equipment, life skills, combat integration).
