# Jade Valley Chronicles: art and music prompt sheet

One file for every image, sound and piece of music the game needs. Everything in the build today is a placeholder (art drawn in code by `ChibiRig` and `StageBackground`; music synthesised by `scripts/gen_music.py`). Replace a placeholder by dropping a file with the same name in the folder shown; no code change is needed unless a note says so.

Contents: 0 How to use · 1 Global art style · 2 Characters · 3 Backgrounds · 4 Key art and endings · 5 UI icons and emblems · 6 Battle art · 7 Music · 8 Sound effects · 9 Delivery checklist

---

## 0. How to use this sheet

1. Paste **the global block** (section 1.1 for art, 7.1 for music) in front of every item prompt. Items below only describe what is different.
2. Generate each character once as a **reference sheet** first (2.2). Reuse that image as a style/character reference for every later pose and expression of the same character so faces and outfits stay stable.
3. Names in `backticks` are the file names the game expects. Sizes are minimums; larger is fine if the aspect ratio is kept.
4. The game is **portrait first** (phones, 9:16 and 3:4), with landscape supported. Backgrounds need a safe centre (see 3.1).
5. All content is original IP. Never ask a generator for "in the style of" a named living artist, studio or an existing game, film or novel. The style words below are descriptive on purpose.
6. Tone limits (from the style guide): stylised, no gore; romance tasteful and non-explicit; the cast is adult except Xia Zhi (17), who is drawn youthful and never sexualised.

---

## 1. Global art style

### 1.1 Global block (paste before every art prompt)

> Original illustration for a Chinese wuxia role-playing game set in a fictional river-and-mountain province (a loose Song-dynasty feel, not a real place). Soft hand-painted look: clean dark-brown ink outlines of even weight, flat colour with gentle watercolour gradients and subtle paper grain, muted jade green, indigo, ochre and vermilion palette, warm light, soft mist. Chibi proportions for characters (about 2.5 heads tall, large expressive eyes, small hands and feet, simple readable silhouettes). Mobile-friendly: bold shapes, no tiny detail, high contrast between figure and background. No text, no logos, no watermark, no signature, no real people, no existing characters or brands.

### 1.2 Global negative (use where the tool supports it)

> photo-realistic, 3D render, anime screenshot, copied character, gore, blood, nudity, text, letters, watermark, frame, border, extra fingers, extra limbs, deformed hands, blurry, low resolution, modern clothing, guns, neon

### 1.3 Colour language

| Place or idea | Palette |
|---|---|
| Jade Valley (home) | bamboo green, mist white, warm thatch ochre |
| Linjiang (trade city) | river teal, lantern red, timber brown, bustling gold |
| Mount Cangwu (sect) | pine green, grey granite, cloud white, solemn indigo |
| Sunken-Star Marsh | grey-green, fog silver, cold teal, faint star-gold |
| Yanmen (north, later) | slate, snow white, iron black, banner red |
| Penglai (sea, later) | sea turquoise, coral pink, pearl white, lighthouse amber |
| The Faceless Gate | ash grey, bone white, one cold accent of violet |

---

## 2. Characters

### 2.1 Technical spec for all characters

- Format: PNG with transparent background. Full body, facing three-quarter front, feet visible, a little empty margin.
- Reference sheet: 2048×2048. Pose and expression exports: 1024×1536 portrait for full body, 768×768 for bust portraits.
- The game draws characters from a "look" (hair style, hair colour, outfit colour, skin colour, weapon), so a final art set per character should follow `res://art/characters/<id>/<id>_<pose>.png` and `<id>_face_<face>.png` for later swapping in `ChibiSkin`.
- **Poses the game uses:** `idle`, `walk`, `bow`, `laugh`, `cry`, `angry`, `think`, `hit`, `victory`, `kneel`, `train`, `sword`, `fish`, `mine`, `music`, `chess`.
- **Faces (expressions):** `neutral`, `happy`, `sad`, `angry`, `surprised`.

### 2.2 Reference sheet prompt (template, generate one per character)

> [GLOBAL BLOCK] Character reference sheet on a plain pale background. Same chibi character shown four times: front view, three-quarter view, side view, back view, in a neutral standing pose; plus a row of five face close-ups (neutral, happy, sad, angry, surprised). [CHARACTER DESCRIPTION]. Consistent proportions and colours across all views. No background scenery.

### 2.3 Pose sheet prompt (template)

> [GLOBAL BLOCK] Using the supplied character reference, draw the same character in 8 poses on a plain pale background in a grid: idle, walk, bow (greeting, hands joined), laugh, cry, angry, think (hand on chin), hit (flinching, hurt). Same outfit, same proportions. [CHARACTER ACTION NOTES]

Second pose sheet: `victory` (arms raised), `kneel`, `train` (practising the character's fighting stance), `sword` (drawing/using the signature weapon), `fish` (holding a rod), `mine` (swinging a pick), `music` (playing an instrument or humming), `chess` (leaning over a board).

### 2.4 The hero (player-made; two defaults)

The player picks the look in the game. For marketing and the default sprites:

- **Hero, young man** (`hero_m`): 19, orphan from Jade Valley. Simple undyed linen tunic with a jade-green sash, travelling pack sewn with the valley crest (a bamboo leaf inside a circle), **half of a jade tally** hanging at the hip on a red cord. Tousled dark hair tied in a short topknot, determined and slightly shy.
- **Hero, young woman** (`hero_f`): same outfit logic, hair in a high ponytail with a green ribbon, same tally and pack.
- Variation sheet: one image showing 6 hair styles × 6 outfit colours so the in-game picker can be redrawn.

### 2.5 Companions

**沈清禾 Shen Qinghe** (`shen_qinghe`) — 22, herbalist-swordswoman, healer-support
> Calm, precise, dry humour. Sage-green layered robe with white trim, hair in a low braid over one shoulder, a herb satchel at the hip, a thin straight sword on the back. Small knowing smile, half-lidded eyes. Colours: sage green, cream, pale blue ribbon. Extra poses: `fish` is replaced by gathering herbs; `music` is quiet humming.

**陆沉舟 Lu Chenzhou** (`lu_chenzhou`) — 24, courier, speed attacker
> Quick, cheerful, hates being trapped. Travel-worn blue coat with rolled sleeves, a wide straw hat hanging on his back, a courier's cloth bundle across the chest, light boots with leg wraps. Messy brown hair, cheeky grin, always mid-motion. Colours: faded blue, straw yellow, brown. A coin tucked in his fingers (he cannot refuse a bet).

**白砚 Bai Yan** (`bai_yan`) — 26, scribe, debuffs and clue-finder
> Earnest, anxious, brilliant with texts. Ink-stained white robe with grey cuffs, a scholar's headband, long loose black hair, carries scroll tubes and a brush case, ink smudge on one sleeve. Gentle worried eyes. Colours: white, grey, ink black, a touch of indigo. Weapon: a folding brush staff.

**谢无咎 Xie Wujiu** (`xie_wujiu`) — 25, disgraced sect prodigy, frontline
> Proud, wounded, secretly kind. Dark-red robe cut from an old sect uniform (the badge torn off, a pale patch where it was), black bracers, long loose-tied black hair, a long spear taller than he is, leans on it. Sharp eyes, half-sneer. Colours: dark red, black, bone white.

**苏黛 Su Dai** (`su_dai`) — 20, street musician, buffer
> Warm, loud, observant, never stays still. Teal dress with small silver bells on the hem and sleeves, a pipa on her back, hair in two loose buns with a bell hairpin, bright grin, wink. Colours: teal, silver, warm orange scarf. Extra pose: `music` playing the pipa, the signature pose.

**厉山 Li Shan** (`li_shan`) — 35, blacksmith, tank
> Gentle giant, few words. Very broad, soot-dark leather apron over a short grey tunic, thick bare forearms with burn scars, short cropped hair, a heavy hammer-axe, soft shy smile. Colours: charcoal, rust orange, steel grey. Drawn taller and wider than the others (still chibi). Extra pose: `mine` is his best pose.

**夏芷 Xia Zhi** (`xia_zhi`, year 2) — 17, young thief, evasion and burst
> Sharp, restless, fiercely loyal once trusted. Grey-purple hood with a torn edge, short dark hair under it, two daggers at the hip, wrapped hands, light crouching posture. Colours: grey-purple, black, a thread of mustard. Youthful and never sexualised.

**萧寒川 Xiao Hanchuan** (`xiao_hanchuan`, year 2) — 28, border general's son, command buffs and counters
> Disciplined, dutiful, lonely. Black-and-silver lamellar jacket, a heavy sabre, a red scarf of the Yanmen garrison, upright posture, short hair in a warrior's knot, rare soft eyes. Colours: black, silver, red.

### 2.6 Antagonists and recurring characters

| id | Prompt description |
|---|---|
| `mask_hui` 灰面 Hui-Mask | Tall figure in layered ash-grey robes, a plain smooth grey mask with no features except two small eye slits, one ink-stained sleeve (a former scribe), hands clasped behind the back. Tired, regretful posture. Violet accent on the cuff only. |
| `mask_xuan` 玄面 Xuan-Mask | Same family as the Hui-Mask but in deep black-blue robes with silver embroidery of proverb characters (abstract marks, no readable text), a mask with a calm smiling curve. Composed, hands in sleeves. |
| `mask_chi` 赤面 Chi-Mask | Red-trimmed charcoal robes, a mask with a mocking half-smile, one gloved hand twirling a coin, relaxed, dangerous. |
| `chief_kuang` 狂刀 Kuang | Bandit chief, heavy build, fur-trimmed brown coat, scarred jaw, a huge broad sabre, bared teeth. Menacing but cartoonish, no gore. |
| `head_lei` 盟主 Lei Zhenyue | Aging Alliance Head, silver beard, rich dark-green robe with a jade belt, a ceremonial staff, weary dignity. |
| `elder` 墨长老 Elder Mo | Valley teacher, 70s, white beard and hair, patched pale-blue scholar robe, a bamboo cane, kind crinkled eyes. Four moods: `neutral` (default), warm smile, worried, and a final grave look for the fork scene. |
| `villager` 村民 (generic) | Friendly generic villager in plain brown hemp clothes, headcloth. Make three variants (man, woman, child) for crowds. |
| `villager_afu` 阿福 A-Fu | Cheerful young villager, apron, wooden bucket. Later version: innkeeper with a cloth over his shoulder. |
| `wanderer` 过路人 | Generic wanderer with a bamboo hat and a travelling cloak. Three variants. |
| `bandit` 山贼 | Generic bandit in mismatched brown-and-red leather, bandana. Three variants with club, short sword, bow. |
| `leader` 头目 | A tougher bandit lieutenant, bigger, with a banner on the back. |
| `qian_man` 钱满 | Pawnshop keeper, round, shrewd smile, abacus in hand, rich maroon robe with coin motifs, little round cap. |
| `guild_master` 漕帮帮主 | Barge Guild master, weathered broad man, dark teal robe with rope-knot embroidery, a heavy jade thumb ring. |
| `masked_rider` 蒙面骑手 | A rider in a dark cloak with a simple cloth mask on a lean horse (draw the horse), pale token at the belt. |
| `master_gu` 顾行舟 Gu Xingzhou | Cangwu Master, 50, severe, upright, grey-green robe with a pine-branch crest, long grey beard tied, hands behind back. |
| `ferryman` 老船夫 | The old ferryman, tiny and weathered, huge straw hat, a long pole, a knowing grin. Fog around his boat. |
| `isle_yun` 云眠 Yun Mian (later) | Island Mistress of Penglai, calm, pearl-white and sea-turquoise robe with shell ornaments, long wave-like hair, amber lantern. |
| `cangwu_disciple` 苍梧弟子 | Cangwu student in a plain grey-green uniform with the pine crest and a practice sword. Make male and female variants. |
| `gate_scout` / `gate_blade` / `gate_captain` 九曜 | Faceless Gate soldiers in ash-grey wraps with featureless cloth face masks; the captain adds a bone-white shoulder plate and a violet cord. Marsh mud on boots. |

### 2.7 Bust portraits (dialogue boxes, character list)

> [GLOBAL BLOCK] Bust portrait of [CHARACTER], 768×768, head and shoulders, three-quarter view, soft rim light, a plain muted gradient background in the character's colour. Five expressions in the same pose: neutral, happy, sad, angry, surprised. Same face and outfit in all five.

Do one sheet per companion, plus the hero (both), Elder Mo and the Hui-Mask.

---

## 3. Backgrounds

### 3.1 Technical spec

- Landscape master 2560×1440 **and** portrait master 1440×2560 for each (or a landscape image that crops safely to 9:16 around the centre).
- Characters stand in the lower-middle third: keep the **centre 60% width** and the **lower 40% height** simple, calm and mid-tone so figures read. Put detail at the edges and in the upper half.
- No characters and no text in the image. Soft depth: far hills lighter and bluer, near objects darker.
- File names: `res://art/backgrounds/<id>.png`. Ids match the game exactly.

### 3.2 Prompts (paste after the global block)

| id | Where it is used | Prompt |
|---|---|---|
| `valley_dawn` | Opening, first morning | Jade Valley at sunrise, layered bamboo hills in blue-green mist, thatched roofs below, a thin river catching pink light, a few birds. Hopeful, gentle. |
| `valley_day` | The valley in daylight | The same valley at midday, bright sky with small clouds, terraced fields, bamboo groves, a dirt path, warm sun. Clear and friendly. |
| `village_dusk` | Village scenes, evenings, the Solstice | A small mountain village at dusk, lit paper lanterns, smoke from chimneys, wooden houses with tiled roofs, a village shrine with a lamp. Orange and lavender sky. |
| `riverside_day` | River bend | A calm river bend lined with reeds and willows, flat stones, a small wooden bridge, bright reflective water. |
| `terraces_green` | Herb terraces | Stepped green herb terraces on a hillside, bamboo baskets, wooden fences, drying racks of herbs, soft morning light. |
| `shrine_night` | Old shrine | An old mountain shrine at night, moss-covered stone steps, two stone lanterns glowing, a pale moon, fireflies. Quiet and a little eerie. |
| `ferry_dusk` | Ferry dock | A wooden ferry landing at dusk, a flat boat with a pole, orange-pink sky on still water, distant hills. |
| `bamboo_mist` | Bamboo pass | A narrow path through tall bamboo with heavy mist, pale green light, a distant bend, a sense of ambush. |
| `city_docks` | Linjiang docks | A busy river-trade dock: barges with sails, stacked crates, rope coils, workers (as small silhouettes only), tall warehouse eaves, daylight on teal water. |
| `city_market` | Linjiang market | A crowded market street with striped awnings, hanging lanterns, stalls of cloth, fruit and pots, tiled roofs, warm gold light. No readable signs. |
| `city_night` | Alleys, night in the city | Narrow stone alleys at night, hanging red lanterns, wet paving reflecting light, shuttered windows, deep blue shadows, a single warm window. |
| `cangwu_day` | Cangwu gate, courts, library | A mountain sect on a cliff: a long stone stairway lined with pines, a grey-roofed gate, training courts of blue stone, clouds below. Solemn and clean. |
| `cangwu_night` | Cliff cave, hot spring | The same mountain at night: steam rising from a hot spring among pines, lanterns on posts, a cliff with a dark cave mouth, a bright moon. |
| `marsh_day` | Marsh flats and reed maze | A wide marsh of tall reeds, shallow silver water, a wooden ferry pole, soft grey fog, a pale sun, very still. |
| `marsh_night` | Sunken temple | A half-sunken stone temple in black water, faint star-gold light rising from carved walls, fog, fireflies. Mysterious. |
| `night_camp` | Camp scenes | A small campfire under a tree on a hillside, a night sky full of stars, a bedroll, quiet warm light. |
| `default` | Fallback | A soft jade-green misty hills gradient with a faint paper texture. Neutral and calm. |

### 3.3 Backgrounds needed for later content (generate when the region is written)

| id | Region | Prompt |
|---|---|---|
| `forge_day`, `forge_night` | Linjiang / Iron-Hill | A blacksmith's open forge, glowing coals, anvil, hanging tools, soot, warm orange firelight; the night version is lit only by the forge. |
| `teahouse_day` | Linjiang | A two-storey teahouse interior with carved wood screens, tea tables, a stage at one end, afternoon light through lattice windows. |
| `pawnshop_in` | Linjiang | A cluttered pawnshop interior, a high counter with an abacus, shelves of curios, jade pieces under glass, dim lantern light. |
| `escort_yard` | Linjiang | A courtyard of an escort bureau, flags, stacked crates, a wooden training dummy, horses. |
| `cangwu_library` | Cangwu | Inside a three-storey scripture library, tall shelves of scrolls, an ink desk, dust in sunbeams. |
| `cangwu_platform` | Cangwu | The Sword-Debate Platform: a huge round stone platform among clouds with nine tablet pillars around it. (Used in the finale and the Alliance ending.) |
| `marsh_vault` | Marsh | The vault gate: a vast carved stone door half in water with nine star carvings (one lit), mist and cold light. |
| `ym_fort`, `ym_road`, `ym_pass`, `ym_field` | Yanmen | Border fort in snow with red banners; a caravan road with wagons; a narrow snowy pass with a frozen stream; a trampled battlefield at dawn with broken spears (no bodies). |
| `pd_harbour`, `pd_cave`, `pd_monastery` | Penglai | A harbour of curved wooden boats and shell lanterns; a glowing coral cave with a sea-lit ceiling; a white lighthouse monastery on a cliff above the waves. |
| `inn_in`, `home_in` | Anywhere | A rustic inn interior with a wooden counter and benches; the hero's simple home with a sleeping mat and a window. |
| `festival_night` | Festivals | A festival street at night with floating lanterns and paper dragons, a river with candles. |
| `road_day`, `road_snow` | World map road | A trade road between hills in daylight; the same road under snow. |

---

## 4. Key art and endings

### 4.1 Title screen key art (`art/title_key.png`, 1440×2560 portrait, with a landscape crop)

> [GLOBAL BLOCK] The hero and two companions (Shen Qinghe and Lu Chenzhou) seen from behind or three-quarters, standing on a mountain path looking over a misty valley at sunrise; the hero holds up the half jade tally and it catches light; faint nine-star constellation drawn in the sky in gold lines. Wide sky area at the top left empty for a title. Epic but warm.

Also generate a **logo background plate** (empty brush-stroke cloud shape) for the title: `title_logo_plate.png`, transparent.

### 4.2 Five ending illustrations (`art/endings/ending_<n>.png`, 1440×2560)

1. **Path of the Alliance Head** — the hero stands on the Sword-Debate Platform at dawn with the nine tablet pillars, companions beside, crowds in small silhouettes, golden light.
2. **Recluse Grandmaster** — a small mountain school in Jade Valley, the hero teaching children in a courtyard, bamboo, peaceful morning.
3. **The Breaker** — the hero holding a broken glowing jade tablet while pieces fall like snow, the platform behind them cracked, uncertain but free.
4. **The Undertow** — the hero in a grey mask-less robe in a dim hall, shadowy figures kneeling, one violet lantern, cold and ambiguous.
5. **The Long Road** — the hero from behind, small, walking a winding road toward a distant sea of clouds, a travelling pack, companions as tiny silhouettes at different points on the road.

Epilogue vignettes (small, 1024×1024 each, for the epilogue composer): one per companion outcome (friend, sworn sibling, romance, rival, parted, fallen — drawn gently, no gore) and one for each faction standing.

### 4.3 Cinematic stills (optional, 1440×2560)

The raid on the valley; Elder Mo giving the tally; the masked rider on the bamboo pass; the first sight of Linjiang from the river; the Hui-Mask in the cave; the temple door lighting its first star; the ambush on the marsh flats; Elder Mo at the doorway (the fork scene, quiet and sad).

---

## 5. UI icons and emblems

### 5.1 Spec

Square PNG with transparent background, 256×256 (drawn so they are readable at 48 px). Flat bold shapes with the same ink outline, one accent colour each. Folder `res://art/ui/`.

### 5.2 Prompts (each icon: "[GLOBAL BLOCK] A single game icon, centred, of …")

| Group | Icons |
|---|---|
| Attributes | `attr_power` a clenched fist; `attr_body` a standing iron bell or turtle shell; `attr_agility` a swallow in flight; `attr_insight` an open eye over a scroll; `attr_spirit` a lotus flower with a small flame |
| Resources | `res_coins` a string of square-holed copper coins; `res_food` a rice bowl with steam; `res_herbs` three green herb leaves tied; `res_ore` a rough ore chunk with sparks; `res_stamina` a small gourd; `res_strategy` a black and a white chess stone |
| Paths (emblems, 512×512) | `path_xuan_fist` a swirling fist inside a circle; `path_green_sword` a sword with a paulownia leaf; `path_listening_rain` raindrops falling on an ear-shaped cloud |
| Realms | seven emblems `realm_1`…`realm_7`: a small candle, a doorway, a growing sprout, a closed circle, a pure flame, a plain white stone (the "simple return"), a nine-star crown. Gradually richer and more golden |
| Activities | `act_training`, `act_technique`, `act_meditation`, `act_fishing`, `act_herbs`, `act_mining`, `act_hunting`, `act_cooking`, `act_music`, `act_chess`, `act_social`, `act_rest` — one simple object each (stick figure fist, sword, seated figure, fishing rod and fish, herb basket, pickaxe and ore, bow, pot, pipa, go board, two teacups, pillow) |
| Equipment | `eq_iron_sword`, `eq_steel_blade`, `eq_jade_saber`, `eq_cloth_vest`, `eq_leather_coat`, `eq_scale_armor`, `eq_jade_pendant`, `eq_wind_charm`, `eq_dragon_charm` (a progression from plain iron to jade and gold) |
| Manuals | `manual_<id>` a closed string-bound book with a distinct coloured cord and a symbol on the cover for each manual: iron palm, wind step, herb hymn, thunder palm, ember fist, jade shield, pine sutra |
| Skill-tree nodes | a round medallion in three states (locked grey, available outlined, learned filled gold), a small version per path colour |
| Technique icons | one per technique (50 in total; group by weapon): fist waves, sword arcs, healing leaves, bells, spear sweeps, hammer blows, music notes, etc. Same frame, different glyph |
| Companion roles | `role_support` a heart leaf, `role_striker` a crossed spear and fist, `role_control` a knot |
| Bond types | `bond_friend` two cups, `bond_sworn` two crossed incense sticks, `bond_romance` a red thread knot, `bond_rival` two crossed swords |
| Factions | `crest_pavilion` Green-Robe Pavilion (a green robe over a tower), `crest_couriers` (a horse head and a bundle), `crest_scribes` (an egret and a scroll), `crest_neutral` (a plain circle), plus the nine houses' crests (see WORLD): Cangwu (pine), Barge Guild (rope knot and boat), Green-Robe, Iron-Hill (anvil and hill), Yanmen (a banner), Penglai (a wave and a shell), Listening-Rain (a raindrop and a bell), White-Egret (an egret), Jade Valley (a bamboo leaf in a circle) |
| Map | region medallions for Jade Valley, Linjiang, Cangwu, the Marsh, Yanmen, Penglai; small map pins for "story", "side", "locked", "new" |
| Minigame | `mg_fishing`, `mg_mining`, `mg_music` icons and the vein/fish/note sprites (a glowing ore vein, a fish, a musical note ball) |
| General | `ui_settings` a gear/pinwheel, `ui_back` an arrow, `ui_save` a scroll, `ui_sound` a bell, `ui_party` two figures, `ui_arts` a lotus scroll, `ui_sheet` a seal |

### 5.3 Panels and frames

> [GLOBAL BLOCK] A 9-slice dialogue panel, a rice-paper rectangle with a thin ink border and rounded corners, a faint cloud corner ornament, semi-transparent warm white. No text. 512×256, plus a button set (normal, pressed, disabled) in jade green, and a name-plate ribbon.

---

## 6. Battle art

### 6.1 Terrain tiles (`art/battle/tile_<kind>.png`, 256×256, top-down three-quarter, tileable)

`plain` packed earth with grass tufts; `cover` a low stone wall or crates; `hazard` thorny brambles or thin ice (readable as "avoid"); `water`; `road` flagstones; plus tile highlights: a move range, an attack range, a selected cell, a threatened cell (soft translucent shapes, 256×256).

### 6.2 Units

Use the character poses above in battle sizes (512×512, three-quarter view, with an `attack`, `hurt`, `defeated` (sitting, dazed, no gore) pose). Enemy templates (new art needed): `cangwu_disciple`, `cangwu_senior`, `gate_scout`, `gate_blade`, `gate_captain`, `bandit` ×3 variants, `bandit_leader`, `masked_rider`, and later Yanmen soldiers and island guards.

### 6.3 Effects (sprite sheets, 8 frames each, 512×512)

> [GLOBAL BLOCK] A short 8-frame effect sprite sheet on a transparent background: [EFFECT].

Effects: ink-brush slash arcs (3 colours), fist shock ring, sword flash, healing leaves swirling up, a bell shock wave, music notes floating, a spear sweep, hammer impact dust, a guard shield of jade light, a duo-technique burst (gold), breakthrough aura (rising lotus petals and gold light), a level-up sparkle.

---

## 7. Music

### 7.1 Global music block (paste before every track prompt)

> Original instrumental music for a Chinese-fantasy wuxia role-playing game, no vocals. Authentic Chinese instrumentation rendered cleanly: guzheng, pipa, dizi and xiao flutes, erhu, guqin, yangqin, small temple bells, wooden fish (muyu), frame drums and large drums, gong, with a soft string or pad bed. Pentatonic melodies with grace notes, warm and human, not cinematic Hollywood and not electronic. Mix for phone speakers: clear mid-range, little deep bass. Seamless loop: the ending leads back to the beginning with no fade-out and no sudden stop, no intro silence. Length 60 to 120 seconds unless stated. Export 44.1 kHz stereo, normalised to about -16 LUFS (music sits under dialogue and sound effects). Original composition only: do not imitate any existing game, film or song.

Negative: vocals, lyrics, spoken voice, electric guitar, synth leads, heavy EDM drums, orchestral brass fanfare, silence at the start or end, sudden key changes at the loop point.

### 7.2 Where each track plays (the game picks automatically)

Rules live in `game/content/audio/music.json`. Priority: event override → battle kind → dialogue background → screen → region.

| Track id | Plays when |
|---|---|
| `title_theme` | boot, title, hero creation, settings |
| `practice_theme` | the cultivation/practice screen, hero sheet, arts screen |
| `valley_theme` | exploring Jade Valley; dialogues on valley backgrounds; default fallback |
| `road_theme` | the map screen; dialogues at the ferry and the bamboo pass |
| `linjiang_theme` | exploring Linjiang; dialogues at the docks and market |
| `cangwu_theme` | exploring Cangwu; dialogues in the day on the mountain |
| `marsh_theme` | exploring the marsh; marsh daytime dialogues |
| `night_theme` | night dialogues (shrine, camp, city night, Cangwu night) |
| `battle_theme` | ordinary battles |
| `duel_theme` | duels and tournament bouts, training matches |
| `boss_theme` | the year's big fights (final crisis, the marsh ambush, the tournament final, the guild night) |
| `minigame_theme` | fishing, mining, music minigames |
| `festival_theme` | festival scenes (Spring Fair, Dragon-Boat, Mid-Autumn, Winter Solstice) |
| `mystery_theme` | the Hui-Mask, the sunken temple, the ferryman, the first shrine, the marsh at night |
| `sorrow_theme` | the theft scene and Elder Mo's fate |
| `ending_theme` | the ending screen (and the epilogue) |
| `yanmen_theme`, `penglai_theme` | year 2 and 3 regions (placeholders exist already) |
| `victory_sting`, `defeat_sting` | played once over the music when a battle ends (not looped, 3 to 5 seconds) |

### 7.3 Track prompts (paste after the global music block)

**`title_theme`** — 72 BPM, D pentatonic (gong), 70–90 s.
> Opening theme. A slow guzheng arpeggio over a soft string pad, a dizi flute carrying a longing, hopeful melody that rises on the second phrase, a single temple bell at the start of each phrase. Mood: a young traveller at the edge of a wide world; nostalgic, warm, quietly heroic.

**`practice_theme`** — 60 BPM, G pentatonic (zhi), 60–90 s.
> Calm study and training music for a courtyard at morning. Sparse plucked guqin or guzheng notes with long rests, a warm sustained pad, an occasional soft xiao flute. Mood: patience, focus, breathing. Must stay unobtrusive because the player hears it for hours.

**`valley_theme`** — 84 BPM, E pentatonic (gong), 70–100 s.
> Home theme. A friendly dizi melody over plucked guzheng arpeggios and a soft plucked bass, light wooden-fish ticks. Mood: village mornings, bamboo, mist, safety. Simple, singable, gentle.

**`road_theme`** — 96 BPM, D pentatonic (zhi), 60–90 s.
> Travelling music. A steady walking pulse on a plucked pipa and a soft wood block, a hopeful pipa melody, a faint pad. Mood: leaving home with a pack on your back, open air, curiosity.

**`linjiang_theme`** — 108 BPM, F pentatonic (shang), 70–100 s.
> A lively river-trade city. Pipa and yangqin with a bouncing rhythm, a small frame drum, wood blocks, a bright bass line, cheerful ornaments. Mood: crowded markets, haggling, boats, many stories, with a hint of intrigue in the minor-ish turns.

**`cangwu_theme`** — 66 BPM, A minor pentatonic (yu), 70–100 s.
> A strict mountain sect. A deep sustained drone, slow solemn dizi phrases, occasional temple bell and low plucked bass, a feeling of wind through pine trees. Mood: discipline, tradition, quiet pride; not gloomy.

**`marsh_theme`** — 54 BPM, Bb pentatonic (jue), 60–90 s.
> A foggy marsh. A low breathing pad, sparse high plucked notes like dripping water, distant bells, a hollow xiao flute whisper. Mood: eerie stillness, hidden things under the water, slow curiosity.

**`night_theme`** — 58 BPM, E minor pentatonic (yu), 60–90 s.
> Quiet night. Soft pad, very few high plucked notes, a lonely flute far away, crickets implied by faint high ticks. Mood: lanterns, secrets, calm before something.

**`battle_theme`** — 132 BPM, A minor pentatonic, 60–90 s.
> Fast skirmish music. Driving pipa and guzheng rhythm figures, taiko-like frame drums with a strong pulse, wood-block accents, a fierce short dizi motif that repeats. Mood: tense, agile, exciting. Moderate bass, leave room for sound effects.

**`duel_theme`** — 120 BPM, G pentatonic (shang), 60–90 s.
> A formal duel. Sparse and sharp: a plucked pipa line, a strong drum on the downbeats, wood-block clicks, tension pad. Mood: two opponents circling, honour and pride.

**`boss_theme`** — 144 BPM, E minor pentatonic (jue), 70–100 s.
> The big fight. Heavy low drums, taiko-style hits, a fast repeating guzheng ostinato, pipa tremolo, urgent erhu cries over the top, a gong at each phrase start, a rising pad. Mood: danger, stakes, the whole party at risk, with a trace of grandeur. Must loop cleanly.

**`minigame_theme`** — 100 BPM, G pentatonic (gong), 60–90 s.
> Playful focus music for fishing, mining and playing music. Bouncy plucked melody, light percussion, a steady pulse the player can tap along to. Mood: light, relaxed, a little cheeky.

**`festival_theme`** — 116 BPM, F pentatonic (gong), 70–100 s.
> A festival. Bright suona or dizi lead, clapping frame drums, gongs, bells, plucked guzheng runs, a dance rhythm. Mood: lanterns, crowds, joy, firecrackers far away.

**`mystery_theme`** — 50 BPM, Ab pentatonic (jue), 60–90 s.
> Mystery and secrets. A low drone, slow-decaying bells, irregular sparse plucked notes, a distant bowed erhu harmonic. Mood: something watching, a door that might open.

**`sorrow_theme`** — 52 BPM, A minor pentatonic (yu), 60–90 s.
> Loss and farewell. A solo erhu or xiao melody, slow and fragile, over a soft pad and sparse plucks. Mood: grief held in dignity, bittersweet; no melodrama.

**`ending_theme`** — 66 BPM, D pentatonic (gong), 90–150 s.
> The ending. It starts with a gentle solo guzheng, builds with dizi and erhu carrying the title theme's melody in a fuller, more resolved form, ends on a hopeful, open chord that loops back to the quiet start. Mood: looking back on a long road, thankful, bittersweet, warm.

**`yanmen_theme`** — 76 BPM, G pentatonic (shang), 70–100 s.
> The northern border. Wide cold pad, a lonely horse-head-fiddle (morin khuur-like erhu) melody, deep slow drums, a sparse plucked bass. Mood: wind on snow, duty and distance.

**`penglai_theme`** — 70 BPM, F# pentatonic (gong), 70–100 s.
> The sea isles. Shimmering harp-like yangqin and guzheng arpeggios, wave-like pad swells, glassy bells, a floating dizi. Mood: the sea, mystery, calm beauty.

**`victory_sting`** — 100 BPM, D pentatonic, 3–4 s, **not looped**.
> A short bright victory flourish: a rising guzheng run, a dizi note, a bell, resolving on a clear major chord with a natural decay.

**`defeat_sting`** — 60 BPM, A minor pentatonic, 3–4 s, **not looped**.
> A short soft defeat figure: a falling erhu phrase with a low pad and a quiet bell. Not harsh; the game has no game over and the player simply tries again.

### 7.4 Additional tracks to commission later

| Track | Use | Brief |
|---|---|---|
| `theme_hero` | Main motif, used in many cues | 30 s solo dizi + guzheng statement of the hero's motif; the other tracks quote it |
| `theme_romance` | Romance beats | Tender pipa and erhu duet, 60 BPM, warm |
| `theme_bond` | Sworn sibling beats | Strong, loyal, mid-tempo, drums and plucks |
| `theme_gate` | The Faceless Gate | Cold, patient, low drone, whispered high strings, slow bell |
| `theme_alliance` | The Alliance ending | Grand but human: gongs, full ensemble, major mode |
| `theme_undertow` | The Undertow ending | Dark, slow, violet-feeling pad, single plucked line |
| `theme_breaker` | The Breaker ending | Uncertain but free: sparse notes then an opening bright chord |
| `theme_recluse` | Recluse ending | Peaceful, bamboo flute and soft strings |
| `theme_road` | The Long Road ending | Gentle walking pulse that gradually thins to one flute |
| Companion leitmotifs (8) | Played softly during each companion's arc scenes | A 20 to 30 s motif per companion on their instrument: Shen (guqin), Lu (bouncy pipa), Bai (soft yangqin), Xie (lone spear-like erhu), Su Dai (pipa with bells), Li Shan (low drum and bass dizi), Xia Zhi (fast muted plucks), Xiao (military drum and horn) |
| Seasonal variants | Spring, summer, autumn, winter versions of the valley and road themes (same melody, different instrument colours) | optional polish |

---

## 8. Sound effects

### 8.1 Global SFX block

> Short original sound effect for a Chinese-fantasy mobile game, clean, dry, no reverb tail beyond what is stated, mono or narrow stereo, 44.1 kHz, peak at -3 dBFS, no music, no voice. File as `res://audio/sfx/<id>.ogg`.

### 8.2 List

| id | Length | Prompt |
|---|---|---|
| `ui_click` | 0.1 s | A soft wooden tap with a tiny bell overtone (replaces the current synthesised click) |
| `ui_confirm` | 0.3 s | Two quick rising plucked notes on a guzheng |
| `ui_back` | 0.2 s | One short falling plucked note |
| `ui_error` | 0.25 s | A dull wood block knock |
| `page_turn` | 0.4 s | Paper scroll unrolling with a light rustle |
| `dialogue_tick` | 0.05 s | A tiny soft wood tick for each text character (very quiet, optional) |
| `coin` | 0.4 s | A few copper coins dropped into a hand |
| `item_get` | 0.6 s | A bright three-note rising chime on a small bell |
| `level_up` | 1.0 s | A rising guzheng run ending in a bell shimmer |
| `breakthrough` | 2.5 s | A deep gong, then a rising shimmer of bells and a soft wind swell resolving into a clear chord |
| `learn_technique` | 1.0 s | A brush stroke whoosh followed by a soft bell |
| `forge_hit` | 0.5 s | A hammer on an anvil, ring, short |
| `mine_hit` | 0.4 s | A pickaxe on rock, crisp |
| `mine_perfect` | 0.5 s | A pickaxe hit followed by a bright crystal chime |
| `fish_cast` | 0.6 s | A rod whip and a small splash |
| `fish_catch` | 0.8 s | A splash and a happy bell |
| `note_perfect` / `note_good` / `note_miss` | 0.3 s | A bright pipa pluck / a softer pluck / a dull muted thud |
| `hit_light` | 0.25 s | A cloth-wrapped fist impact |
| `hit_heavy` | 0.4 s | A heavy impact with a short low boom |
| `crit` | 0.5 s | A sharp impact with a gong tick |
| `slash` | 0.3 s | A quick blade swish |
| `spear` | 0.3 s | A long whoosh and a thud |
| `block` | 0.3 s | A hard clank of wood and metal |
| `heal` | 0.8 s | A soft gentle chime with leaves rustling |
| `buff` | 0.6 s | A rising sparkle of tiny bells |
| `debuff` | 0.6 s | A falling muted pluck with a faint buzz |
| `duo_attack` | 1.0 s | Two impacts in rapid succession then a bright shimmer |
| `defeat_unit` | 0.5 s | A soft thud and a falling breath (no gore) |
| `step_grass` / `step_stone` / `step_wood` | 0.2 s | Single footstep on grass / stone / wooden boards (several variants each) |
| `door_wood` | 0.5 s | A wooden door sliding open |
| `lantern` | 0.4 s | A paper lantern flicker |
| `water_drop` | 0.3 s | A single drop in a still pond |
| `gong` | 2.0 s | A large gong strike with a long natural decay (scene start for tournament and the fork) |
| `bell_temple` | 2.5 s | A distant temple bell |
| `star_light` | 1.5 s | A soft rising glassy tone as a star carving lights up (the temple door) |
| `ambience_valley` | 30 s loop | Birds, a distant stream, light wind in bamboo |
| `ambience_city` | 30 s loop | Murmur of a crowd, distant hawkers, water lapping, no readable speech |
| `ambience_mountain` | 30 s loop | Wind through pines, a distant bell, birds |
| `ambience_marsh` | 30 s loop | Frogs, insects, water movement, soft wind through reeds |
| `ambience_night` | 30 s loop | Crickets, a distant owl, faint breeze |
| `ambience_rain` | 30 s loop | Steady rain on tiles and leaves |

---

## 9. Delivery checklist

1. Folders: `game/art/characters/`, `game/art/backgrounds/`, `game/art/ui/`, `game/art/battle/`, `game/art/endings/`, `game/audio/music/`, `game/audio/sfx/`.
2. Music files must keep the **exact id** as the file name (`valley_theme.ogg`); the game loops them and cross-fades between tracks (1.2 s). Ogg Vorbis mono or stereo, 44.1 or 22.05 kHz, about 96 to 128 kbps; keep the full set under about 15 MB for web.
3. Images: PNG for sprites (alpha), WebP or PNG for backgrounds; budget the whole art set under about 40 MB for web; keep single files under 2 MB where possible.
4. After replacing placeholders run the build; the browser smoke test checks layout at six screen sizes and the unit tests check that every catalog track file exists and every stage background has a track.
5. `python3 scripts/gen_music.py` only creates missing placeholder files and rewrites the catalog; it never overwrites an existing file unless you pass `--force` or name a track id.
