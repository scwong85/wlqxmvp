# Assets and licences (M13)

| Asset | Where | Source | Licence |
|---|---|---|---|
| Noto Sans SC, subset to the characters the game uses | `game/fonts/NotoSansSC-subset.otf` (built by `scripts/make_font_subset.py`) | Google Noto CJK | SIL Open Font License 1.1 (modification and embedding allowed) |
| Hero and companion portraits (medallions with a character) | drawn in code: `scenes/shared/hero_portrait.gd`, `companion_portrait.gd` | original | none needed |
| Backdrop, panels, buttons, frames, board and unit tokens | drawn in code: `scenes/shared/backdrop.gd`, `scripts/ui/ui_kit.gd`, `scenes/battle/board_view.gd` | original | none needed |
| Click sound and background pad | synthesised sine tones in `scripts/services/audio_service.gd` | original | none needed |
| Story, names, places, techniques | `game/content/**` | original (no existing franchise names, characters or text) | project's own |

A unit test (`m13: the only external asset is the subset font`) fails if any image, audio or other font file is added without updating this list.

Real art and audio can later replace the code-drawn placeholders behind the same screens.
