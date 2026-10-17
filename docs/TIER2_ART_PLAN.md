# Tier 2 art plan and prompts

Goal: make the game look *ready*: the hero and every speaking character appear as painted full-body figures in the main screen and in story scenes, the most-used places are painted, and the interface stops looking like a prototype. Tier 1 (busts, 7 backgrounds, title art) is already in the game.

## 1. Decisions that change what you generate

### 1.1 Character creation: how painted art and 'pick your look' fit together
Painted art is one fixed picture per character. The old creator mixed a hair style, hair colour, outfit colour and skin colour in code, which only works with code-drawn figures. Painted art cannot do that unless you commission every hair x outfit combination (or a layered paper-doll set, which is a large job).

**Recommendation: for now the creator offers only name + male/female.** You generate `hero_m` and `hero_f` once (full-body, plus the busts you already have). The hair/outfit/skin code and data stay in the project, hidden, so a layered system can be added later without losing saves. Players keep a real choice through the story, not the costume.

This is a small code change (hide those rows, fix the look to default per gender, use the painted hero everywhere). Say "go" and I will do it with the next build.

### 1.2 How the full-body art is used
The stage and the main screen currently draw a code-posed chibi. A painted sprite is a static picture, so: **one `idle` full-body image per character** is enough for Tier 2. The game keeps animating it from code (gentle breathing bob, slide in and out, mirror on the right side, dim when not speaking, shake on hits). Expressions are shown by the bust portrait next to the speaker's name, which you already have. Extra poses (battle, victory, sad) are Tier 3.

Because the game cannot make the figure change pose, ask the generator for a calm, neutral, front-facing idle with both feet visible. Remove the background to transparent afterwards: ask for a plain flat white background and I will cut it out in a script (flood-fill from the edges plus feathering), so do not worry if your generator cannot export transparency.

### 1.3 The interface (the 'too green' problem)
The look today is dark teal panels with jade-green borders and bright jade text. That reads as a tool or a sci-fi UI, not wuxia. Proposed direction, all done in code, no art needed:

| Element | Now | Proposed |
|---|---|---|
| Panel fill | dark teal glass | warm ink-black brown `#1c1712` at 85%, with a faint paper grain |
| Text | cool off-white | parchment `#eadfc6`; headings antique gold `#d6b25e` |
| Accent / primary button | jade `#5fd1a5` | vermilion seal red `#b8382d` for primary, gold outline for hover |
| Borders | thin jade line | double thin gold line with small corner brackets (like a scroll frame) |
| Buttons | rounded dark teal | slightly squared plaque, gold edge, red seal-stamp when pressed |
| Progress bars | jade fill | gold fill for experience, vermilion for health, jade only for healing/positive |
| Headings font | sans | a calligraphic serif for titles (Noto Serif SC, OFL), body stays sans for readability |
| Non-story screens | code-drawn night mountains | a painted background (from your set) under a dark warm scrim |

Jade stays as a small accent (heal numbers, 'success') so the game's name still shows. Say "go" for the restyle and I will build it, take screenshots at phone sizes and send them before publishing.

Optional UI art (section 5): a seamless paper texture and a brush-stroke plate; everything else is drawn in code.

## 2. Priority order (stop after any group)

| Group | What | Count | Why |
|---|---|---|---|
| **2A** | Full-body `idle` for the hero (m, f) and the 8 companions | 10 | The main interface, every dialogue and the party all show painted people |
| **2B** | Full-body `idle` for Elder Mo, Wanderer, Villager, Bandit, Qian Man, Master Gu; backgrounds `valley_dawn`, `city_docks`, `city_night`, `cangwu_night` | 10 | The most frequent non-companion speakers, the opening scene and the busiest locations |
| **2C** | Full-body for Lei Zhenyue, the three Masks, Guild Master, Bandit lieutenant; backgrounds `yanmen_fort`, `penglai_sea`, `shrine_night`, `riverside_day`; the 5 ending illustrations; the 2 UI plates | 6 + 4 + 5 + 2 | Year 2 and 3 story, the endings, polish |

Total 37, but **2A + 2B is the 20 that matter**; the game falls back to the code-drawn figure or background for anything missing, so you can add files in any order.

## 3. How to run it
1. For every full-body prompt below, attach the character's bust sheet (the Tier 1 image) as the reference image. For NPCs without a sheet, generate the full-body first and keep it as their reference.
2. Use the global negative where supported: *photo-realistic, 3D render, anime screenshot, copied character, gore, blood, nudity, text, letters, watermark, frame, border, extra fingers, extra limbs, deformed hands, blurry, low resolution, modern clothing, guns, neon*.
3. Save as `art_src/fullbody/<id>.png` (any format is fine, I convert). Tell me the batch and I will cut out backgrounds, wire it in, build and show screenshots.
4. Keep scale consistent: all characters about the same head size; Li Shan taller and wider. If a figure comes out realistic, add "chibi, 2.5 heads tall" again at the end of the prompt.

## 4. Group 2A: full-body figures (10)

### The hero (2)

### `hero_m`: The young male hero, 19

**File:** `art_src/fullbody/hero_m.png` (1024x1536)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Simple undyed linen tunic with a jade-green sash, a travelling pack sewn with the valley crest (a bamboo leaf inside a circle), half of a jade tally hanging at the hip on a red cord, short dark topknot, a plain sword at the hip. Determined and slightly shy.

### `hero_f`: The young female hero, 19

**File:** `art_src/fullbody/hero_f.png` (1024x1536)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Same outfit logic: undyed linen tunic with a jade-green sash, travelling pack with the valley crest, half of a jade tally on a red cord, dark hair in a high ponytail with a green ribbon, a plain sword at the hip. Determined and slightly shy.

### Companions (8)

### `shen_qinghe`: Shen Qinghe, 22, herbalist-swordswoman

**File:** `art_src/fullbody/shen_qinghe.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Sage-green layered robe with white trim, hair in a low braid over one shoulder, herb satchel at the hip, a thin straight sword on the back. Small knowing smile.

### `lu_chenzhou`: Lu Chenzhou, 24, courier

**File:** `art_src/fullbody/lu_chenzhou.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Travel-worn blue coat with rolled sleeves, wide straw hat hanging on his back, courier cloth bundle across the chest, light boots with leg wraps, messy brown hair, cheeky grin, a coin between his fingers.

### `bai_yan`: Bai Yan, 26, scribe

**File:** `art_src/fullbody/bai_yan.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Ink-stained white robe with grey cuffs, scholar's headband, long loose black hair, scroll tubes and a brush case on his back, ink smudge on one sleeve, a folding brush staff in hand. Gentle worried eyes.

### `su_dai`: Su Dai, 20, street musician

**File:** `art_src/fullbody/su_dai.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Teal dress with small silver bells on the hem and sleeves, orange scarf, pipa on her back, hair in two loose buns with a bell hairpin, bright grin.

### `li_shan`: Li Shan, 35, blacksmith

**File:** `art_src/fullbody/li_shan.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Very broad gentle giant: soot-dark leather apron over a short grey tunic, thick bare forearms with burn scars, short cropped hair, a heavy hammer-axe on the shoulder, soft shy smile. Drawn taller and wider than the others (still chibi).

### `xie_wujiu`: Xie Wujiu, 25, disgraced sect prodigy

**File:** `art_src/fullbody/xie_wujiu.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Dark-red robe cut from an old sect uniform (badge torn off, a pale patch where it was), black bracers, long loose-tied black hair, a long spear taller than he is held beside him. Sharp eyes, half-sneer.

### `xia_zhi`: Xia Zhi, 17, young thief

**File:** `art_src/fullbody/xia_zhi.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Grey-purple hood with a torn edge, short dark hair under it, two daggers at the hip, bandage-wrapped hands, light crouching posture. Youthful, never sexualised.

### `xiao_hanchuan`: Xiao Hanchuan, 28, border general's son

**File:** `art_src/fullbody/xiao_hanchuan.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Black-and-silver lamellar jacket, red scarf of the Yanmen garrison, heavy sabre at the hip, upright posture, short hair in a warrior's knot, rare soft eyes.

## 5. Group 2B (10)

### NPC full-body figures (6)

### `elder`: Elder Mo, valley teacher, 70s

**File:** `art_src/fullbody/elder.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. White beard and hair, patched pale-blue scholar robe, a bamboo cane, kind crinkled eyes, slightly stooped.

### `wanderer`: Wanderer (generic traveller)

**File:** `art_src/fullbody/wanderer.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Bamboo hat, a travelling cloak in slate grey, a walking staff, a small pack, face half in shadow, calm.

### `villager`: Villager (generic)

**File:** `art_src/fullbody/villager.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Friendly man in plain brown hemp clothes with a headcloth, simple sandals, hands open.

### `bandit`: Bandit (generic)

**File:** `art_src/fullbody/bandit.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Mismatched brown-and-red leather, a bandana, a short club over the shoulder, cocky stance. Menacing but cartoonish, no gore.

### `qian_man`: Qian Man, pawnshop keeper

**File:** `art_src/fullbody/qian_man.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Round and shrewd, rich maroon robe with coin motifs, little round cap, an abacus in hand, a knowing smile.

### `master_gu`: Gu Xingzhou, Cangwu Master, 50

**File:** `art_src/fullbody/master_gu.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Severe and upright, grey-green robe with a pine-branch crest, long grey beard tied, hands behind the back.

### Backgrounds (4)

**Spec for every background:** Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `valley_dawn` (Opening, first morning)

**File:** `art_src/backgrounds/valley_dawn.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Jade Valley at sunrise, layered bamboo hills in blue-green mist, thatched roofs below, a thin river catching pink light, a few birds. Hopeful, gentle. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `city_docks` (Linjiang docks (20 scenes))

**File:** `art_src/backgrounds/city_docks.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A busy river-trade dock: barges with sails, stacked crates, rope coils, workers as tiny silhouettes only, tall warehouse eaves, daylight on teal water. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `city_night` (Linjiang alleys at night (17 scenes))

**File:** `art_src/backgrounds/city_night.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Narrow stone alleys at night, hanging red lanterns, wet paving reflecting light, shuttered windows, deep blue shadows, a single warm window. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `cangwu_night` (Cangwu at night (13 scenes))

**File:** `art_src/backgrounds/cangwu_night.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. The same mountain sect at night: steam rising from a hot spring among pines, lanterns on posts, a cliff with a dark cave mouth, a bright moon. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

## 6. Group 2C

### NPC full-body figures (6)

### `head_lei`: Lei Zhenyue, the Alliance Head

**File:** `art_src/fullbody/head_lei.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Aging, silver beard, rich dark-green robe with a jade belt, a ceremonial staff, weary dignity.

### `mask_hui`: The Hui-Mask

**File:** `art_src/fullbody/mask_hui.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Tall in layered ash-grey robes, a plain smooth grey mask with only two small eye slits, one ink-stained sleeve, hands clasped behind the back, tired regretful posture, a violet accent on the cuff only.

### `mask_xuan`: The Xuan-Mask

**File:** `art_src/fullbody/mask_xuan.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Deep black-blue robes with silver embroidery of abstract proverb marks (no readable text), a mask with a calm smiling curve, composed, hands in sleeves.

### `mask_chi`: The Chi-Mask

**File:** `art_src/fullbody/mask_chi.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Red-trimmed charcoal robes, a mask with a mocking half-smile, one gloved hand twirling a coin, relaxed and dangerous.

### `guild_master`: Barge Guild master

**File:** `art_src/fullbody/guild_master.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Weathered broad man, dark teal robe with rope-knot embroidery, a heavy jade thumb ring, arms folded.

### `leader`: Bandit lieutenant

**File:** `art_src/fullbody/leader.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Full-body character sprite, based on the supplied character reference image (keep face, hair, outfit and colours identical). Relaxed standing idle pose, three-quarter front view, the whole body from head to feet visible with a little margin, any weapon or prop shown. Isolated on a plain flat pure white background: no ground, no shadow, no scenery, no frame, no text. Portrait 1024x1536. Bigger than a normal bandit, a banner on his back, scarred jaw, a broad sabre, bared teeth. Menacing but cartoonish, no gore.

### Backgrounds (4)

### `yanmen_fort` (Yanmen border fort (19 scenes))

**File:** `art_src/backgrounds/yanmen_fort.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A border fort in snow with red banners on grey walls, a gate with a watchtower, pine-covered slate hills, pale winter light. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `penglai_sea` (Penglai island (12 scenes))

**File:** `art_src/backgrounds/penglai_sea.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A harbour of curved wooden boats with shell lanterns, turquoise sea, a white lighthouse monastery on a cliff above the waves, coral-pink evening light. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `shrine_night` (Old shrine)

**File:** `art_src/backgrounds/shrine_night.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. An old mountain shrine at night, moss-covered stone steps, two stone lanterns glowing, a pale moon, fireflies. Quiet and a little eerie. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `riverside_day` (River bend)

**File:** `art_src/backgrounds/riverside_day.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A calm river bend lined with reeds and willows, flat stones, a small wooden bridge, bright reflective water. Landscape master 2560x1440 AND portrait master 1440x2560 (or a landscape that crops safely to 9:16). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### Ending illustrations (5)

**Files:** `art_src/endings/ending_<n>.png`, 1440x2560 portrait. Same global block; show the hero as the painted `hero_m` or `hero_f` reference you already have (attach it).

- > Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. **1 Path of the Alliance Head:** the hero stands on the Sword-Debate Platform at dawn among nine tablet pillars, companions beside, crowds as tiny silhouettes, golden light.
- > Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. **2 Recluse Grandmaster:** a small mountain school in Jade Valley, the hero teaching children in a courtyard, bamboo, peaceful morning.
- > Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. **3 The Breaker:** the hero holds a broken glowing jade tablet while pieces fall like snow, the platform behind cracked, uncertain but free.
- > Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. **4 The Undertow:** the hero in a grey robe in a dim hall, shadowy figures kneeling, one violet lantern, cold and ambiguous.
- > Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. **5 The Long Road:** the hero from behind, small, walking a winding road towards a distant sea of clouds, a travelling pack, companions as tiny silhouettes at different points on the road.

### UI plates (2, optional)

- **Paper texture** `art_src/ui/paper.png`, 1024x1024, **seamless tile**: > Seamless tileable texture of warm aged rice paper, very subtle fibres and faint stains, low contrast, cream colour, no objects, no text.
- **Brush plate** `art_src/ui/brush_plate.png`, 1600x600, transparent or flat white: > A single horizontal ink-brush stroke shape in dark ink with dry-brush edges and soft ink-wash bleed, empty, no text, used as a title plate.


## 7. Background music: the minimum

The game already plays generated placeholder music everywhere (`game/content/audio/music.json` picks the track), and each track is replaceable one file at a time. Players hear **cultivation and the title/menu most of all**, then the valley, the road and battles. The minimum set that covers about 90% of play time:

| # | Track | Plays when | Length |
|---|---|---|---|
| 1 | `title_theme` | title, hero creation, settings | 70 to 90 s loop |
| 2 | `practice_theme` | the cultivation screen, hero sheet, arts (the most-heard track, so keep it calm) | 60 to 90 s loop |
| 3 | `valley_theme` | Jade Valley, village scenes, default fallback | 70 to 100 s loop |
| 4 | `road_theme` | the map, ferry and bamboo scenes | 60 to 90 s loop |
| 5 | `battle_theme` | ordinary battles (duel/boss tracks fall back to the same style) | 60 to 90 s loop |
| 6 | `ending_theme` | the ending and epilogue | 80 to 120 s |
| 7-8 | `victory_sting`, `defeat_sting` | a few seconds when a battle ends | 3 to 5 s, no loop |

Prompts for all of these are already written in `ART_AND_MUSIC_PROMPTS.md` section 7 (global music block, then track prompts 7.3). Make each loop cleanly (same start and end note). After these 8, the next most valuable are `linjiang_theme`, `cangwu_theme`, `night_theme` and `boss_theme`.


## 8. What I do when you upload
1. 2A arrives: cut the backgrounds out, put the hero full-body in the main interface and the stage, and show everyone painted in dialogue and the party.
2. Creator simplified to name + gender (needs your "go").
3. Interface restyle (needs your "go").
4. Each later group: wire in, build, screenshots, publish.
