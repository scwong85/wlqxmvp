# Portrait layout report

## Decisions (from the clarifying questions)
- Follow the device: tall windows get the portrait layout, wide or square ones the landscape layout. A fullscreen button (web only, on the title and settings screens)
  also asks Android browsers to lock portrait. iPhone Safari does not allow orientation locks or canvas fullscreen, so there the layout simply follows how the phone is held.
- All current screens, including every pop-up.
- Training screen in portrait: stamina strip always visible, tabs for Hero / Train / Status (a new game opens on Hero so the path choice is seen first).
- Combat (M9-M10) will be designed portrait-first with a landscape variant.

## How it works
- `Layout` autoload (`scripts/services/layout_service.gd`): chooses the mode from the window shape, sets the stretch base size (landscape 1280x720, portrait 540x960),
  and emits `mode_changed`. Rotating or resizing re-arranges screens live; state is kept (selected activity, tab, resources).
- Portrait base width is 540 so a 390 px phone shows text at 0.72x (22 px font = about 16 CSS px).
- Screens re-arrange the same nodes (no duplicate scenes): top bar becomes two rows, the three panels become tabs, action buttons stack, activity cards stay 3 per row,
  party rows stack their buttons under the text, pop-ups cap their width to the screen, the approach chooser shows 4 short lines per option.
- A rotation closes the approach chooser (nothing had been chosen yet); other pop-ups re-fit.

## Evidence
- Unit: 807 checks (includes the shape rule: 390x844 portrait, 844x390 landscape, square = landscape).
- Headless UI test simulating a 390x844 phone: title, settings, training tabs, chooser with 4 options, companion panel, exploration, invitation prompt, English strings, and rotating
  portrait -> landscape -> portrait with state preserved. All pass the layout audit (font >= 22, buttons >= 44 px, nothing outside the screen).
- Real Chromium at 390x844, 360x640, 768x1024 (portrait) and 1280x720, 1920x1080, 2400x1080 (landscape): layout audit clean at all; full touch flow at 390x844
  (tabs, chooser, companions, rest into day 2, exploration, invitation prompt). Screenshots: `docs/spike/screens/portrait_*.png`.

## Not covered
- No real phone yet: touch, address-bar resizing, notch safe-areas and the fullscreen/orientation lock need a real-device check.
- Landscape on a phone (e.g. 844x390) shows the existing landscape layout scaled down (text about 12 CSS px); portrait is the intended phone mode.
- 360x640 is the tightest case (only ~37 logical px of spare height on the Train tab); adding a row to that screen will need another tab or scrolling.
