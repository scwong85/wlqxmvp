# M2 report: state and persistence

Date: 2026-10-15. Status: **complete** for the Web target (native headless also verified).

| Task | Result | Evidence |
|---|---|---|
| M2-01..05 State classes (player, calendar, resources, cultivation, relationships) | Done | `scripts/domain/`; each has clamping rules and a lossless JSON round trip test |
| M2-06 GameState + versioned schema + migration stub | Done | `SCHEMA_VERSION = 1`; tolerant loader (junk, partial data, unknown keys give defaults, never crash) |
| M2-07 Save write | Done | Temp file, read-back verification, swap, previous save kept as `.bak`; manual slot + autosave |
| M2-08 Save read and corrupt-save fallback | Done | Main file, then `.bak`, then typed error key; checksum catches edited contents; version 0 / newer versions rejected |
| M2-09 UI wiring | Done | Load enabled when a save exists, title shows "存档：第 N 天 · 时段 N", corrupt saves explained in Mandarin/English; hub has a test advance button and Save |
| M2-10 Restart test | Done | Two separate processes (write, then read) pass; browser reload test passes |

## Evidence
- Unit tests: 156 checks, 0 failures (`tests/unit/`).
- Headless navigation and persistence smoke: pass, including destroying both saves and checking the error message.
- Restart across processes: `PERSIST_WRITE_OK` then `PERSIST_READ_OK`.
- Browser (headless Chromium): advance, save, **page reload**, Load enabled, loaded run at slot 2, 0 console errors at 4 viewport sizes.
- Screenshots: `docs/spike/screens/m2_*.png`.

## Decisions and notes
- Language choice now persists in `settings.json` and is applied at boot. The save file also records the locale but does not override the setting.
- On Web, `user://` is browser storage (IndexedDB). Saves are per browser and per site address, and are lost if the user clears site data. Worth telling testers.
- JSON parsing uses `JSON.new().parse()` so damaged files are handled quietly instead of logging engine errors.
- The hub's "[Test] Advance one slot" button is temporary scaffolding. M3 replaces it with real activities and the day-end transition.
- Not yet covered: saving mid-battle (M11-09), Android storage behaviour, save slots beyond manual + auto.
