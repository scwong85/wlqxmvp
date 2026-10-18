# Jade Valley Chronicles: release notes and QA checklist

## What is in the build
- Three in-game years (180 weeks, 360 slots), open world, 8 companions with four-stage arcs and relationship branches, battles with up to two companions, minigames, music and sound (web), Mandarin default with English.
- Five endings (Alliance Head, Recluse Grandmaster, Breaker, Undertow, Long Road) and a composed epilogue of about 96 snippets.
- Saves: autosave plus slots, versioned and migrated. No game over.

## How to reach each ending (for testers)
Choose at the platform (weeks 177–178). Each also needs earlier play:
1. Alliance Head: take the token; at least 6 of 8 companions not lost; a pledge to a faction; realm 4 (Integrated) or higher.
2. Recluse: refuse the seat; keep the valley (Elder Mo's fate scene); realm 5 (Pure Flame) or higher.
3. Breaker: destroy the manual; Bai Yan or Xia Zhi redeemed.
4. Undertow: take the Gate's hand (needs the Xuan-Mask offer); Xuan-Mask pact or Xia Zhi lost.
5. Long Road: the walk, or any choice whose conditions do not hold (a line explains why).

## Art (Tier 1 + Tier 2)
- Painted: 15 backgrounds (+3 borrowed by alias), title key art, 10 companion/hero bust sets, 22 full-body figures (hero m/f, 8 companions, 12 NPCs), 5 ending illustrations, paper texture and brush plate.
- Figures are static paintings animated in code (breathing, bounce, lean, squash). Anything without a file keeps the code-drawn fallback (e.g. Isle Yun, the masked rider).
- Character creation: name and male/female only; the painted hero is fixed. The hair/outfit/skin data is still saved and the rows can be re-enabled with `SHOW_LOOK_OPTIONS` in `hero_creation.gd`.
- Interface: ink-brown scroll panels with paper grain, gold lines, vermilion seal buttons, serif headings, painted backdrops under a warm veil.

## Known limits
- Music is synthesised placeholder (see ART_AND_MUSIC_PROMPTS.md).
- Audio fix verified in headless Chromium only; check on a real phone and desktop browser.
- Real-device layout and touch checks pending.

## Release checklist
- [ ] Build passes (`bash scripts/build_web.sh`).
- [ ] Play on a phone (portrait) and a desktop browser: title, a week, a battle, a minigame, the ending.
- [ ] Switch language mid-run; reload the page and continue from autosave.
- [ ] Audition each music theme; check volume controls.
