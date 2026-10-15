# M18 — Story board and hero creation

- **Hero creation** (Start → new screen): name (1–8 characters; braces/brackets/control characters stripped), gender, hair style (4), hair colour (5), outfit colour (5), skin tone (3), live chibi preview. The name becomes the `{hero}` text variable available in every string. Name and look are saved with the run (older saves load with the default hero).
- **Chibi rig** (`ChibiRig` + `ChibiSkin` interface + built-in code skin): 16 poses (idle, walk, bow, laugh, cry, angry, think, hit, victory, kneel, train, sword, fish, mine, music, chess), 5 expressions, blinking, props (sword, staff, herb basket, fan, rod, pickaxe, flute, stone). A sprite-sheet skin can replace the code skin by implementing `draw` — no screen changes.
- **Stage view**: 9 code-drawn backgrounds, 4 character slots (left, centre, right, far), speaker highlight (others dim), shake / flash / fade effects.
- **Scene commands** inside dialogue nodes (`stage`: bg, show, hide, pose, face, move, focus, clear; transient: shake, flash, fade, sfx). Stage state is part of the saved dialogue, so reloading mid-scene restores it. Validator checks every command.
- **Backlog**: every line and choice is logged (last 60); a Log button on the dialogue screen opens it.
- Prologue dialogues and all valley event scenes now use the stage. Settings gets an "Animations: on/off" option (used by the stage now, activity clips in M19).
- Glyph note: the bundled font has no ▶ ◀, so ASCII `<` `>` are used.

Next: M19 activity clips, minigame host and fishing.
