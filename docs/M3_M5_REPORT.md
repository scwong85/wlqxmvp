# M3–M5 report: calendar loop, cultivation data model, cultivation screen

## What exists
- **M3 calendar loop**: 7 days x 2 slots, stamina recovery on new day (half of max), autosave after every slot,
  day-3 / day-6 / day-7 story pop-ups (stubs) recorded in `calendar.events_fired`, week end state.
- **M4 data model**: attributes (根骨 力道 身法 悟性 心性), derived values (health, stamina, initiative, technique points),
  3 paths, 6 techniques, deterministic skill checks (seeded by `run_seed|activity:day:slot`).
  Save schema bumped to **v2** with a real v1 -> v2 migration.
- **M5 cultivation screen**: hero / activities / stats panels, 12 activity cards (blocked ones show the reason),
  result panel, temporary path chooser, story pop-up overlay, save / back-to-title.

## Evidence
- Unit suite: 375 checks, 0 failures (`run_unit.tscn`).
- UI smoke (`run_smoke.tscn`): 37 checks incl. full 7-day play-through, save/load, corrupt save, language toggle.
- Two-process persistence test and browser (Chromium) test at 1280x720, 1920x1080, 2400x1080 and portrait 390x844:
  reload keeps the save, 0 console errors, layout audit clean at all landscape sizes.
- Screenshots: `docs/spike/screens/m1_*_cultivation.png`, `m2_cultivation_*.png`.

## Known gaps / notes
- Data for all 12 activities exists already (pulled forward from M6); per-activity interaction screens and relevance audit remain M6.
- The path chooser is scaffolding until the M12 day-2 event.
- Relationship summary is minimal (full version M7-08).
- Art is code-drawn placeholder. Real-device touch check still pending.
- The activity description area is small at 720p (scrolls); worth a redesign pass in M6.
