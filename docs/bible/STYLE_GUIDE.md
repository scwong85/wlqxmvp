# Style guide

## Language
- Mandarin first (简体), English second. English is natural, not literal; keep proper names in pinyin with the Chinese shown on first use or in the glossary.
- Register: classical flavour in moderation (成语 and short proverbs welcome), plain enough for a phone screen. Sentences short; one idea per line.
- No modern slang or internet words in Mandarin text. Companions with slang (Lu Chenzhou, Xia Zhi) use period-appropriate street speech.
- Address the player as 你; no gendered pronouns for the hero in text lines. Use the hero's name through a variable ({hero}); titles like 少侠 / 女侠 only through gender-aware variants when chosen.
- Length: a dialogue line ≤ 60 characters; a screen of text ≤ 3 lines of dialogue; choices ≤ 16 characters.

## Voice per character
| Character | Mandarin voice | English voice |
|---|---|---|
| Hero | player's choice of tone | follows the tone |
| Shen Qinghe | 短句，克制，偶尔冷幽默 | terse, dry |
| Lu Chenzhou | 口语化，爱反问，赌性 | quick, playful, rhetorical questions |
| Bai Yan | 书面语，长句，常道歉 | formal, hedged, apologetic |
| Xie Wujiu | 简短带刺，偶有真诚 | clipped, sarcastic, rare warmth |
| Su Dai | 俏皮，歌词碎片，爱起外号 | teasing, song fragments, nicknames |
| Li Shan | 慢，具体，工艺比喻 | slow, concrete, craft metaphors |
| Xia Zhi | 街头快语，突然沉默 | fast street talk, sudden silence |
| Xiao Hanchuan | 军令式，慢慢解冻 | formal, military, thaws slowly |
| Elder Mo | 温和，老式，留白 | gentle, old-fashioned, leaves things unsaid |
| Faceless Gate | 平静，格言，不威胁 | calm, proverbs, never threatens openly |

## Glossary (use these exact forms)
| 中文 | Pinyin | English |
|---|---|---|
| 青岚州 | Qīnglán Zhōu | Qinglan Province |
| 玉谷 / 青玉谷 | Yù Gǔ | Jade Valley |
| 玉契 | Yù Qì | the Jade Accord |
| 论剑台 | Lùnjiàn Tái | the Sword-Debate Platform |
| 盟主 | Méngzhǔ | Alliance Head |
| 九曜残卷 | Jiǔyào Cánjuàn | the Nine-Star Manual |
| 无相门 | Wúxiàng Mén | the Faceless Gate |
| 内功 | nèigōng | inner power |
| 境界 | jìngjiè | realm |
| 招式 | zhāoshì | technique |
| 秘籍 | mìjí | manual |
| 江湖 | jiānghú | the martial world |
| 玄拳 / 青桐剑 / 听雨法 | | Mystic-Flow Fist / Green-Paulownia Sword / Listening-Rain Method |

## Content limits
- Violence: stylised; no gore. Romance: tasteful, non-explicit. No real-world politics, no real people, no copying of existing wuxia text, names or characters (original IP only).
- Every scene must work with the player absent from optional events (no required reading of side content).
- Every scene's text goes through localization keys; no hard-coded strings; both languages for every key before merging.

## Writing checklist per scene
1. Which flags does it read and set? 2. Which window? 3. Which speakers and poses (stage commands)? 4. Mandarin, then English. 5. Key-lint, glyph and layout audits pass.
