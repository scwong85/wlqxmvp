# M1 report: project shell and navigation

Date: 2026-10-15. Status: **complete** for the Web target.

| Task | Result | Evidence |
|---|---|---|
| M1-01 Boot scene | Done | `scenes/boot/`; smoke: boot routes to title |
| M1-02 LocalizationService | Done | 64 unit checks: lookup, English fallback to Mandarin, placeholders, signal, unsupported locale ignored |
| M1-03 Title screen (keys only) | Done | Key-lint and "no hard-coded CJK in scripts" gates pass |
| M1-04 Responsive landscape layout | Done | `scenes/shared/safe_frame.gd`; screenshots at 1280x720, 1920x1080, 2400x1080 in `docs/spike/screens/` |
| M1-05 New game to hub; load disabled with reason | Done | Reason is shown as visible text too, since touch has no hover |
| M1-06 Settings with language toggle | Done | Toggle updates strings live |
| M1-07 Smoke test | Done | Headless navigation test plus browser run at 4 viewport sizes, 0 console errors |

## Notes
- Used a small in-project test runner instead of GUT/GdUnit4 (M0-04) to avoid an addon dependency. Revisit if tests need mocking or richer reporting.
- Autoloads: `Loc` (localization) and `Router` (scene keys). All screens go through `Router.goto(key)`.
- Placeholder art: the jade-valley backdrop is drawn in code (sky, moon, ridges, mist, bamboo). It is original and temporary.
- Language choice is not persisted yet; that arrives with SaveService in M2.
- Portrait is readable but cramped by design; the MVP is landscape-only.
- Touch was verified only by emulation. Real-device check still pending.

## Run
`bash scripts/build_web.sh` runs unit tests, headless smoke, Web export and the browser smoke test.
