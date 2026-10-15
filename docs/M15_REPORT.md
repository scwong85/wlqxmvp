# M15 report: story bible and the 3-year calendar

## What changed
- **Calendar v2:** 3 years × 12 months × 5 weeks, 2 slots a week (180 weeks, 360 slots). `CalendarState` gained `year()`, `month()`, `week_in_month()`, `season()`, `slots_used()` and rollover flags (new week/month/year). The unit of time is the week (`calendar.week`); every gate in content (`min_week`, `week_min`, `meet_week`, hook `week`) uses it.
- **Opening month:** the old seven-day story is now the prologue, weeks 1 to 5 (intro and path choice week 1, recruitment week 2, rescue week 3, factions week 4, preparation and warning week 5). After the last slot of the opening month the climax fight with the bandit chief plays, and the game goes on into month 2 whatever the result (no game over).
- **Ending:** no longer after the first month. The ending is chosen when the last slot of week 180 is used (placeholder rules until M25/M26).
- **Save schema 7:** old saves migrate (day 1..7 becomes week 1,1,2,3,4,5,5; a finished seven-day save returns to the end of the opening month so its climax still happens).
- **UI:** the top bar shows "第N年 M月 · 第W周" (English "Y1 · Month 1 · Wk 1"); the load hint on the title screen shows the same.
- **Texts:** intro, preparation and epilogue lines no longer say "seven days".
- **Story bible:** `docs/bible/` (world, characters, arcs and endings, timeline, style guide and glossary).
- **Robustness:** the UI smoke test now fails if the run stops early on a script error.

## Evidence
- Unit tests: 1,396 checks, 0 failures. New: calendar over all 360 slots (rollovers, seasons, clamping), migration of every old day, opening-month hooks, climax then month 2, ending at the end of year 3.
- Headless UI smoke: plays the opening month with the real buttons, the climax, jumps to week 180 and reaches the ending screen.

## Known interim state
Months 2 to 36 contain only activities, the Bamboo Pass route and random nothing: the event engine (M16) and the map tab (M17) fill them. Balance of the economy over 360 slots (stamina, coins, attribute caps) is untuned until the ascension milestone (M20).
