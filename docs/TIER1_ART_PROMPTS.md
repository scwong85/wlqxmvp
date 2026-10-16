# Tier 1 art prompts (paste-ready)

The smallest art set that makes the game look finished: 1 key art, 2 hero busts, 8 companion busts, 6 backgrounds (17 generations, though the bust sheets give you 5 faces each). Built from `ART_AND_MUSIC_PROMPTS.md` (sections 1, 2.4, 2.5, 2.7, 3, 4.1). Every prompt below already includes the global style block, so you can paste it as is.

## How to run this
1. Do the **title key art** first; it sets the look. Then the two heroes, then reuse the hero and key art as style references for everything else.
2. For each bust, generate the sheet once; if your tool makes one expression per image, run the prompt five times changing only the expression. Keep the same seed or reference image.
3. Use the **negative prompt** wherever your tool supports one:

> photo-realistic, 3D render, anime screenshot, copied character, gore, blood, nudity, text, letters, watermark, frame, border, extra fingers, extra limbs, deformed hands, blurry, low resolution, modern clothing, guns, neon

4. Save as shown in the *File* lines. The busts become `res://art/characters/<id>/<id>_face_<face>.png`; the game falls back to its code-drawn art for anything missing, so you can add files one at a time.
5. Original IP only. Never add "in the style of" a named artist, studio or game.

---

## A. Title key art (1 image)

**File:** `art/title_key.png`, 1440x2560 portrait (crop a landscape version later)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. The hero (seen from behind or three-quarters, simple linen tunic with a jade-green sash, half of a jade tally held up and catching the light) and two companions, Shen Qinghe (sage-green layered robe, low braid, herb satchel, thin sword on her back) and Lu Chenzhou (faded blue coat, straw hat on his back, courier bundle), stand on a mountain path looking over a misty valley at sunrise. A faint nine-star constellation is drawn in the sky in thin gold lines. Wide empty sky at the top left, left clear for a title. Epic but warm. Portrait 1440x2560.

---

## B. Hero busts (2 sheets)

### Hero, young male hero `hero_m`

**Files:** `res://art/characters/hero_m/hero_m_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of the young male hero (19, orphan from Jade Valley), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in muted jade green. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Simple undyed linen tunic with a jade-green sash, a travelling pack sewn with the valley crest (a bamboo leaf inside a circle), half of a jade tally hanging at the hip on a red cord. Tousled dark hair tied in a short topknot. Determined and slightly shy.

### Hero, young female hero `hero_f`

**Files:** `res://art/characters/hero_f/hero_f_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of the young female hero (19, orphan from Jade Valley), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in muted jade green. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Simple undyed linen tunic with a jade-green sash, a travelling pack sewn with the valley crest (a bamboo leaf inside a circle), half of a jade tally hanging at the hip on a red cord. Dark hair in a high ponytail with a green ribbon. Determined and slightly shy.

---

## C. Companion busts (8 sheets)

### Shen Qinghe `shen_qinghe`

**Files:** `res://art/characters/shen_qinghe/shen_qinghe_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Shen Qinghe (22, herbalist-swordswoman, healer), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in sage green. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Calm, precise, dry humour. Sage-green layered robe with white trim, hair in a low braid over one shoulder, a herb satchel at the hip, a thin straight sword on the back. Small knowing smile, half-lidded eyes. Colours: sage green, cream, pale blue ribbon.

### Lu Chenzhou `lu_chenzhou`

**Files:** `res://art/characters/lu_chenzhou/lu_chenzhou_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Lu Chenzhou (24, courier, speed attacker), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in faded blue. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Quick, cheerful, hates being trapped. Travel-worn blue coat with rolled sleeves, a wide straw hat hanging on his back, a courier's cloth bundle across the chest. Messy brown hair, cheeky grin. A coin tucked in his fingers. Colours: faded blue, straw yellow, brown.

### Bai Yan `bai_yan`

**Files:** `res://art/characters/bai_yan/bai_yan_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Bai Yan (26, scribe, clue-finder), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in soft grey with a touch of indigo. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Earnest, anxious, brilliant with texts. Ink-stained white robe with grey cuffs, a scholar's headband, long loose black hair, scroll tubes and a brush case, an ink smudge on one sleeve. Gentle worried eyes. Colours: white, grey, ink black, a touch of indigo.

### Su Dai `su_dai`

**Files:** `res://art/characters/su_dai/su_dai_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Su Dai (20, street musician, buffer), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in warm teal. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Warm, loud, observant, never still. Teal dress with small silver bells on the hem and sleeves, a pipa on her back, hair in two loose buns with a bell hairpin, bright grin, a wink. Colours: teal, silver, warm orange scarf.

### Li Shan `li_shan`

**Files:** `res://art/characters/li_shan/li_shan_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Li Shan (35, blacksmith, tank), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in charcoal and rust orange. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Gentle giant, few words. Very broad, soot-dark leather apron over a short grey tunic, thick bare forearms with burn scars, short cropped hair, a heavy hammer-axe, a soft shy smile. Drawn taller and wider than the others (still chibi). Colours: charcoal, rust orange, steel grey.

### Xie Wujiu `xie_wujiu`

**Files:** `res://art/characters/xie_wujiu/xie_wujiu_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Xie Wujiu (25, disgraced sect prodigy, frontline), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in dark red and bone white. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Proud, wounded, secretly kind. Dark-red robe cut from an old sect uniform (badge torn off, a pale patch where it was), black bracers, long loose-tied black hair, a long spear taller than he is. Sharp eyes, half-sneer. Colours: dark red, black, bone white.

### Xia Zhi `xia_zhi`

**Files:** `res://art/characters/xia_zhi/xia_zhi_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Xia Zhi (17, young thief, evasion and burst), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in grey-purple. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Sharp, restless, fiercely loyal once trusted. Grey-purple hood with a torn edge, short dark hair under it, two daggers at the hip, wrapped hands, light crouching posture. Youthful and never sexualised. Colours: grey-purple, black, a thread of mustard.

### Xiao Hanchuan `xiao_hanchuan`

**Files:** `res://art/characters/xiao_hanchuan/xiao_hanchuan_face_neutral.png`, `_happy`, `_sad`, `_angry`, `_surprised` (768x768 each)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. Bust portrait of Xiao Hanchuan (28, border general's son, command buffs), head and shoulders, three-quarter view, soft rim light, plain muted gradient background in slate with a red accent. Five expressions of the same character in one sheet, in the same pose: neutral, happy, sad, angry, surprised. Same face, hair and outfit in all five. Square, 768x768 per portrait. Disciplined, dutiful, lonely. Black-and-silver lamellar jacket, a heavy sabre, a red scarf of the Yanmen garrison, upright posture, short hair in a warrior's knot, rare soft eyes. Colours: black, silver, red.

---

## D. Backgrounds (6 images)

**Spec for all six:** Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `valley_day` (The valley in daylight)

**File:** `res://art/backgrounds/valley_day.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. The same Jade Valley at midday: bright sky with small clouds, terraced fields, bamboo groves, a dirt path, thatched roofs below, a thin river, warm sun. Clear and friendly. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `village_dusk` (Village scenes, evenings, the rescue fight)

**File:** `res://art/backgrounds/village_dusk.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A small mountain village at dusk, lit paper lanterns, smoke from chimneys, wooden houses with tiled roofs, a village shrine with a lamp. Orange and lavender sky. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `city_market` (Linjiang market)

**File:** `res://art/backgrounds/city_market.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A crowded market street with striped awnings, hanging lanterns, stalls of cloth, fruit and pots, tiled roofs, warm gold light. No readable signs. Palette: river teal, lantern red, timber brown, bustling gold. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `cangwu_day` (Cangwu gate, courts, library (also the finale platform))

**File:** `res://art/backgrounds/cangwu_day.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A mountain sect on a cliff: a long stone stairway lined with pines, a grey-roofed gate, training courts of blue stone, clouds below. Solemn and clean. Palette: pine green, grey granite, cloud white, solemn indigo. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `marsh_day` (Marsh flats and reed maze)

**File:** `res://art/backgrounds/marsh_day.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A wide marsh of tall reeds, shallow silver water, a wooden ferry pole, soft grey fog, a pale sun, very still. Palette: grey-green, fog silver, cold teal, faint star-gold. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

### `ferry_dusk` (Ferry dock)

**File:** `res://art/backgrounds/ferry_dusk.png`

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands. A wooden ferry landing at dusk, a flat boat with a pole, orange-pink sky on still water, distant hills. Landscape master 2560x1440 AND portrait master 1440x2560 (or one landscape image that crops safely to 9:16 around the centre). No characters, no text. Keep the centre 60% width and lower 40% height simple, calm and mid-tone so figures read; put detail at the edges and in the upper half. Far hills lighter and bluer, near objects darker.

---

## After Tier 1
Good next picks (Tier 2): full-body `idle` and `sword`/`train` poses (prompts 2.2 and 2.3 in the main sheet), the 17 other backgrounds (3.2 and 3.3), and the five ending illustrations (4.2).
