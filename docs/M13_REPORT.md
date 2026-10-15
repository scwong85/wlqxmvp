# M13 report: localization, accessibility and polish

## Localization (M13-01 to M13-05)
- `docs/M13_LOCALIZATION_REPORT.md` (regenerate with `godot --headless --path game -s res://tests/lint_keys.gd -- <file>`): 471 Mandarin keys, 470 English (the one gap is the deliberate `spike.fallback_only_zh` that proves the fallback). Zero missing Mandarin keys, zero placeholder mismatches between languages, zero unused keys (18 stale keys from before M12 were removed), zero content keys pointing nowhere.
- Hard-coded text: a scan of every `.text/.tooltip_text/.placeholder_text` assignment in `scenes/` and `scripts/` finds no literal with letters or CJK (format characters like `%s` and `\n` are allowed). It runs in the unit tests, together with the older CJK-in-scripts scan.
- English fallback: a test removes an English key and shows the Mandarin text; an unknown key renders as `[key]` so gaps are visible. No key renders as `[key]` in either language.
- Fonts: every character of both languages is drawn by the bundled subset font. Rare characters outside it are detected (`Loc.missing_glyphs`, tested with 𠮷) and the font carries a system-font fallback (Noto Sans CJK, YaHei, PingFang, WenQuanYi) for desktop. A browser has no system CJK fonts, so there a rare glyph would show as a box; the subset is rebuilt from the locale files on every build, so game text never hits this.

## Accessibility (M13-06)
- Every screen's layout audit (font ≥ 22, buttons ≥ 44 high, everything inside the viewport) runs in the UI smoke at 390x844, 360x640, 768x1024, 1280x720 and 2400x1080 in both languages, including the new settings and pause screens, and in the browser at six sizes. All clean.
- Contrast (WCAG ratio, worst-case backdrop, tested): body text 8.8:1, buttons 13.1:1 (hover 11.7, pressed 7.3), panel text 14.1:1, accent text 11.5:1, disabled text 6.4:1. Required 4.5:1 (3:1 for disabled and the focus ring).
- Screenshots for every size are produced by the browser smoke run.

## Pause menu, audio (M13-07, M13-08)
- The "Menu" button (or Esc) opens Resume / Save / Settings / Back to title. Save works mid-day. Settings opened from the pause menu return to the game.
- Music and effects buses, a generated click sound and a soft looping pad (no audio files). Two volume sliders in Settings (0 mutes). Volumes are saved in the settings file next to the language, which is no longer overwritten when one of them changes.

## Assets (M13-09)
`docs/ASSETS.md` lists everything: only the OFL-licensed subset font is external; portraits, frames, board, sounds are drawn or synthesised in code. A test fails if another asset file appears.

## Performance (M13-10)
- Headless, no rendering (`tests/perf_battle.gd`): the battle screen builds in about 100 ms, an enemy turn costs about 1–2 ms, steady-state script cost per frame is about 1 ms or less, 22 nodes.
- In a browser with software rendering (SwiftShader in a container, so far slower than any phone GPU), the battle screen runs at roughly 4–5 frames/s at 1280x720 (214 ms average), 12–14 frames/s at phone sizes (72–82 ms). The numbers are in the web smoke output (`perf`) and only useful as a regression guard; a real device is needed for true frame rates.

## Tests
1,354 unit checks, 0 failures; headless UI smoke and browser smoke at six sizes pass with no console errors.

## Not done
- Real-device checks of touch, fullscreen, orientation and audio start-up after the first tap.
- Placeholder art is still simple medallions and colour panels.
