#!/usr/bin/env python3
"""M26: the five big endings and the epilogue snippets. Run AFTER every other generator (it replaces the old
prologue endings and their translations). Writes story/endings.json, story/epilogue.json and the ending.* / epi.* text."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

# ------------------------------------------------------------------ the five endings (first match wins)
ENDINGS = [
 ("alliance_head", "盟主之路", "Path of the Alliance Head",
  "你接过盟主令，九家的旗在你身后同时升起。三年的奔走没有白费：残卷聚齐，盟约守住，你带着一群愿意同行的人，把一座分崩的江湖重新拢在一起。",
  "You took the Head's token and nine banners rose behind you. Three years on the road were not wasted: the fragments were gathered, the Accord held, and you drew a splintered world together with people who chose to walk with you.",
  {"flags_all": ["finale_seat"], "kept_min": 6, "flags_any": ["pledge_orthodox", "pledge_trade", "pledge_free"], "realm_min": 3}),
 ("recluse", "隐世宗师", "Recluse Grandmaster",
  "你把令牌放回案上，转身回了玉谷。竹林里添了一座小小的武馆，远处的江湖安静下来，偶尔有人翻山来问剑，又带着一杯茶下山。",
  "You set the token back and went home to Jade Valley. A small school grew among the bamboo; the far world quieted, and now and then someone crossed the hills to ask about the sword and went down again with a cup of tea.",
  {"flags_all": ["finale_refuse", "valley_kept"], "realm_min": 4}),
 ("breaker", "破局者", "The Breaker",
  "残卷在火盆里化成灰，盟约随之散去。没有人知道新的太平什么模样，但你让所有人从头学起，也让所有人都有机会重新选。",
  "The fragments turned to ash in the brazier and the Accord dispersed with them. Nobody knew what a new peace would look like, but you made everyone begin again, and gave everyone the chance to choose anew.",
  {"flags_all": ["finale_break"], "outcome_any": ["bai_yan:redeemed", "xia_zhi:redeemed"]}),
 ("undertow", "暗潮", "The Undertow",
  "你握住了玄面的手。无相门的灰旗悄悄升起，江湖从此静了，静得像水面下的暗流。有人感激，有人沉默，也有人一夜之间不见了。",
  "You took the Xuan-Mask's hand. The Gate's grey banner rose quietly, and the world went still, still as water above an undertow. Some were grateful, some fell silent, and some vanished overnight.",
  {"flags_all": ["finale_gate"], "flags_any": ["arcout_xia_zhi_lost", "xuan_pact"]}),
 ("long_road", "江湖远行", "The Long Road",
  "你背起行囊，走下论剑台。该有的圆满没有齐全，但路还在脚下，每一个认识你的人，都有自己的路要走。",
  "You shouldered your pack and went down from the platform. No perfect ending came together, but the road was still under your feet, and everyone who knew you had a road of their own.",
  {}),
]
endings = []
for id, tz, te, bz, be, req in ENDINGS:
    L("ending.%s.title" % id, tz, te); L("ending.%s.body" % id, bz, be)
    endings.append({"id": id, "title_key": "ending.%s.title" % id, "body_key": "ending.%s.body" % id, "requires": req})
json.dump({"endings": endings}, open(os.path.join(G, "story/endings.json"), "w"), ensure_ascii=False, indent=1)

# ------------------------------------------------------------------ epilogue snippets
snips = []
def S(section, id, z, e, req=None, companion=None):
    key = "epi." + id
    L(key, z, e)
    d = {"id": id, "section": section, "key": key, "requires": req or {}}
    if companion: d["companion"] = companion
    snips.append(d)

# why the long road: the choice that did not hold (only when the ending is long_road)
S("why", "why_seat", "你接了令牌，可愿意同行的人太少，盟约在你手里一寸寸松开，你终于放下它。", "You took the token, but too few stood with you; the Accord loosened in your hands until you set it down.", {"ending": ["long_road"], "flags_all": ["finale_seat"]})
S("why", "why_refuse", "你想回玉谷，可玉谷已不是当年的样子，你只好把行囊再背起。", "You meant to go home, but the valley was no longer the valley you knew, and you took up your pack again.", {"ending": ["long_road"], "flags_all": ["finale_refuse"]})
S("why", "why_break", "你烧了残卷，可身边没有能接住后事的人，余波只好留给时间。", "You burned the fragments, but no one near could take up what came after, and time was left to settle the rest.", {"ending": ["long_road"], "flags_all": ["finale_break"]})
S("why", "why_gate", "玄面的承诺没有人作保，你转身，把灰旗留在了台上。", "No one stood surety for the Xuan-Mask's promise, and you turned away, leaving the grey banner on the stone.", {"ending": ["long_road"], "flags_all": ["finale_gate"]})
S("why", "why_walk", "你什么也没接，天亮时就上了路。", "You took nothing, and by daylight you were on the road.", {"ending": ["long_road"], "flags_all": ["finale_walk"]})

# the hero: realm, signature skill
REALMS = [(0, "初窥门径，你仍记得第一次拉开架势时手心的汗。", "You still remember the sweat on your palms the first time you took a stance."),
          (1, "你登堂入室，招式有了自己的呼吸。", "You entered the hall, and your forms learned to breathe."),
          (2, "你已有小成，江湖里开始流传你的名字。", "Minor mastery was yours, and your name began to travel."),
          (3, "你融会贯通，拳脚与心意不再分家。", "Everything integrated; fist and intent no longer parted."),
          (4, "你修到纯火，一招一式恰如其分。", "You reached the pure flame, every move landing as it should."),
          (5, "你返璞归真，抬手之间看不出一点锋芒。", "You returned to simplicity, and no edge showed in a raised hand."),
          (6, "你已是宗师，足以开宗立派，却仍愿意蹲下来教孩子扎马步。", "A grandmaster, able to found a school, and still willing to crouch and teach a child to hold a stance.")]
for i in range(len(REALMS) - 1, -1, -1):
    _, z, e = REALMS[i]
    S("hero_realm", "realm_%d" % i, z, e, {"realm_min": i})
S("hero_skill", "skill_high", "「{skill}」被你练到了炉火纯青，说书人常拿它收尾。", "Your {skill} was honed to perfection, and storytellers like to close on it.", {"skill_min": 8})
S("hero_skill", "skill_mid", "「{skill}」是你用得最顺手的一招，用了三年，仍有新的体会。", "{skill} was the move you trusted most, and after three years it still taught you something.", {"skill_min": 4})
S("hero_skill", "skill_low", "三年里你学过的招式不少，却没有哪一样练到极处。", "You learned many moves in three years and carried none to its limit.")

# companions: outcome, then bond (per companion)
C = {
 "shen_qinghe": (("她成了听雨堂的堂主，师父的病终于有了解药。", "She became head of Listening-Rain Hall, and her master at last had his cure."),
                 ("她去了边地行医，药篓里还留着你给的那包草。", "She went to heal the border, still carrying the herbs you gave her."),
                 ("她没能等到解药，从此少有人见到她。", "The cure came too late, and she was rarely seen after."),
                 ("她常托人带药来，信里只写一行：「按时吃饭。」", "She sends medicine, and a note that reads only: \"Eat on time.\""),
                 ("你们结了异姓兄妹，每逢雨天，药庐的灯总为你留着。", "You swore as siblings, and on rainy nights a lamp stays lit in the dispensary for you."),
                 ("听雨堂的檐下，有一盏茶一直是双份。", "Under the eaves of Listening-Rain two cups of tea are always poured."),
                 ("她仍记得那一碗药，和你当时没说出口的话。", "She still remembers that bowl of medicine, and what you left unsaid.")),
 "lu_chenzhou": (("镖局在他手里清了账，渡口的货又重新上了路。", "He cleared the bureau's books, and cargo moved again along the ferry road."),
                 ("他一个人走上了商道，说那样自在。", "He took to the caravan road alone, saying it suited him."),
                 ("那封信终究换了钱，镖局烧了，他没再回渡口。", "The letter was sold in the end, the bureau burned, and he never returned to the ferry."),
                 ("他的每一趟镖，都会给你捎回一件小东西。", "Every trip he makes he brings you back some small thing."),
                 ("你们在渡口拜了把子，酒洒进了江里。", "You swore brotherhood at the ferry and poured the wine into the river."),
                 ("他说江上月色好，想与你同看，一看就是许多年。", "He said the river moon was good to share, and shared it for many years."),
                 ("你们每次碰面都要比一场，输赢从来没有定论。", "You meet to spar each time, and the score is never settled.")),
 "bai_yan": (("他写成了一部真史，墨迹未干，世人已争相传抄。", "He finished a true history, and copyists were fighting for it before the ink dried."),
             ("他回了书院，窗下的灯一夜夜亮着。", "He went back to the academy, where his lamp burned night after night."),
             ("他困在残卷里再没出来，灰衣人拿走了他的笔记。", "He lost himself in the fragments, and the grey men took his notes."),
             ("他寄来长信，一半是学问，一半是问你近来好不好。", "His long letters are half scholarship and half asking how you are."),
             ("你们结拜的那天，他把一枚刻着「义」字的小章留给了你。", "On the day you swore, he left you a small seal carved with a single character: duty."),
             ("他在史书的末页写了你的名字，又悄悄涂去，改成了「某人」。", "At the end of the history he wrote your name, rubbed it out and wrote \"a friend\" instead."),
             ("他仍旧不服，每回来信都在跟你争一条旧注。", "He is still unconvinced, and every letter argues over some old annotation.")),
 "su_dai": (("她的歌成了第九块残卷的钥匙，茶楼里天天有人唱。", "Her song became the key to the ninth fragment, and the teahouses sing it daily."),
            ("她带着琵琶走了，下一个小镇会有新的歌。", "She went off with her pipa, and the next town will hear a new song."),
            ("那首歌被人偷走了，她再没有弹过。", "The song was stolen, and she never played it again."),
            ("她每到一处都会弹你爱听的那一支。", "In every town she plays the tune you liked best."),
            ("你们结了金兰，她说兄弟姐妹是最长久的和声。", "You swore as siblings, and she calls that the longest harmony."),
            ("月下她抱着琵琶，一弦一弦，弹给你一个人听。", "Under the moon she plays her pipa string by string, for you alone."),
            ("你们隔着茶桌对唱，谁也不肯先收声。", "You answer each other across the tea table, and neither will stop first.")),
 "li_shan": (("他重起了炉，铁砧声一响，半座山都听得见。", "He rekindled the forge, and the anvil rang across half the hill."),
             ("他守着小铺，只打犁头与菜刀，说这样最踏实。", "He kept a small shop, hammering only ploughshares and kitchen knives, and called it honest work."),
             ("他替无相门打了刀，从此炉火都是灰的。", "He forged blades for the Gate, and his fires burned grey ever after."),
             ("他给你打了一把小刀，说是不为砍人，只为削苹果。", "He made you a small knife, not for fighting, he said, only for peeling apples."),
             ("你们在炉前拜了把子，火星溅在袖口，谁也没躲。", "You swore by the forge, sparks landing on your sleeves, and neither of you flinched."),
             ("他送你的那只铁镯，里面刻了一朵小小的莲。", "The iron bracelet he gave you has a tiny lotus cut inside."),
             ("他每次都说打不过你，每次都要再来一局。", "He says he can't beat you and asks for another round every time.")),
 "xie_wujiu": (("他回苍梧做了教习，门下弟子都认他是个好先生。", "He returned to Cangwu as an instructor, and his disciples called him a good teacher."),
               ("他离了门派，只带一把旧剑，说清白不必人人都懂。", "He left the sects with only an old sword, saying not everyone needs to understand his innocence."),
               ("他成了别人的拳头，擂台上再遇，他眼里已没有你。", "He became another's fist, and when you met on the stage his eyes no longer knew you."),
               ("他有空就来坐坐，不多说，只把剑放在你手边。", "He drops by when free, says little, and lays his sword beside you."),
               ("你们在崖洞前结了义，他说这一回，不再被人冤枉了。", "You swore at the cliff cave, and he said no one would wrong him again."),
               ("他不善言辞，却记得你一句话，记了三年。", "He is no talker, yet he has kept a single sentence of yours for three years."),
               ("你们打了三年的平手，谁都不肯承认是平手。", "Three years of draws, and neither will call it a draw.")),
 "xia_zhi": (("她反戈一击，为你们引出了无相门的暗线。", "She turned on the Gate and drew its hidden lines into the open."),
             ("她消失在夜巷里，只留下一枚小小的铜钱。", "She vanished into the night alleys, leaving a small copper coin."),
             ("她成了无相门的副手，灰衣人见到她都低头。", "She became the Gate's lieutenant, and grey men bowed their heads to her."),
             ("她时常翻墙进来，吃完东西又翻墙出去。", "She keeps climbing in over the wall, eating, and climbing out again."),
             ("你们结了义，她把自己从没提过的真名告诉了你。", "You swore, and she told you the true name she never gave before."),
             ("她在你窗外留下一枝夜来香，不留名字。", "She leaves a spray of night jasmine at your window, unsigned."),
             ("她仍视你为对手，每回见面都要偷你一样东西。", "She still counts you a rival, and steals something of yours at every meeting.")),
 "xiao_hanchuan": (("他领着戍军守住了关口，山下的村子又升起了炊烟。", "He led the garrison at the pass, and smoke rose again over the villages below."),
                   ("他卸了甲，做了个云游的人，说想看看关外的春天。", "He laid down his armour and became a wanderer, wanting to see spring beyond the pass."),
                   ("他死在关口，手里还握着那面破了的旗。", "He died holding the pass, the torn banner still in his hand."),
                   ("他的信总是很短，只有天气、粮价，和一句「安」。", "His letters are short: weather, grain prices and a single word, safe."),
                   ("你们在雪里结拜，手心的血很快就冻住了。", "You swore in the snow, the blood on your palms freezing at once."),
                   ("他把你的名字写在军帐的账簿最后一页，当成家人。", "He wrote your name on the last page of the camp register, among his family."),
                   ("你们每年在关口比一场，雪落满肩，谁也不肯先收。", "Every year you spar at the pass, snow gathering on your shoulders, neither yielding.")),
}
for cid, (red, alt, lost, fr, sw, ro, ri) in C.items():
    S("comp_outcome", cid + "_redeemed", "{name}：" + red[0], "{name}: " + red[1], {"outcome": "redeemed"}, cid)
    S("comp_outcome", cid + "_alternate", "{name}：" + alt[0], "{name}: " + alt[1], {"outcome": "alternate"}, cid)
    S("comp_outcome", cid + "_lost", "{name}：" + lost[0], "{name}: " + lost[1], {"outcome": "lost"}, cid)
    S("comp_bond", cid + "_friend", fr[0], fr[1], {"bond": "friend"}, cid)
    S("comp_bond", cid + "_sworn", sw[0], sw[1], {"bond": "sworn"}, cid)
    S("comp_bond", cid + "_romance", ro[0], ro[1], {"bond": "romance"}, cid)
    S("comp_bond", cid + "_rival", ri[0], ri[1], {"bond": "rival"}, cid)
S("comp_unmet", "comp_unmet", "还有些人，你只来得及擦肩而过，江湖太大，缘分有时只够一次点头。", "Some you only brushed past; the world is large and fate sometimes allows a single nod.", {"unmet_min": 1})

# faction, standing
S("faction", "faction_pavilion", "药亭的病榻与药炉仍在你身后，玉谷里再没有人饿着等死。", "The Herb Pavilion keeps its sickbeds and furnaces behind you, and no one in the valley waits to die hungry.", {"flags_all": ["faction_pavilion"]})
S("faction", "faction_couriers", "镖行的驿道通到了玉谷门口，消息和货都比从前走得快。", "The couriers' roads reach the valley gate, and news and cargo travel faster than before.", {"flags_all": ["faction_couriers"]})
S("faction", "faction_scribes", "抄书人把你的故事誊了几十份，送往四面八方。", "The scribes copied your tale dozens of times and sent it in every direction.", {"flags_all": ["faction_scribes"]})
S("faction", "faction_neutral", "你谁也没有依附，所以谁都愿意在你面前说实话。", "You bound yourself to no one, so everyone was willing to speak plainly before you.", {"flags_all": ["faction_neutral"]})
S("pledge", "pledge_orthodox", "正统诸派把你视作自己人，讲武堂的门为你而开。", "The orthodox sects count you as their own, and their lecture halls open for you.", {"flags_all": ["pledge_orthodox"]})
S("pledge", "pledge_trade", "商行与镖局的掌柜们愿意为你的话作保。", "The trade houses and escort bureaus will stand surety for your word.", {"flags_all": ["pledge_trade"]})
S("pledge", "pledge_free", "散人与游侠记得你，一壶酒就是一桩人情。", "Wanderers and free blades remember you; a jug of wine is a debt of honour.", {"flags_all": ["pledge_free"]})

# hometown, wealth
S("hometown", "valley_kept", "玉谷保住了名字，村口的灯一直亮着。", "Jade Valley kept its name, and the lamp at the village gate burns on.", {"flags_all": ["valley_kept"]})
S("hometown", "valley_elder_fell", "莫老先生没能熬过那个冬天，村里人至今念着他。", "Elder Mo did not survive that winter, and the village still speaks of him.", {"flags_all": ["elder_fallen"]})
S("hometown", "valley_away", "玉谷在你不在的那些年里自己长大了，阿福说他们没等你，只是留了一盏灯。", "The valley grew up while you were away; A-Fu says they did not wait for you, only left a lamp lit.", {"flags_none": ["valley_kept", "elder_fallen"]})
S("wealth", "wealth_rich", "你的钱袋沉得走路都响，却是被你一枚枚散给了该给的人。", "Your purse is heavy enough to jingle, though you scatter it coin by coin to those who need it.", {"coins_min": 1500})
S("wealth", "wealth_mid", "你有些积蓄，足够修一间屋子，开一间小馆。", "You have savings enough to mend a house and keep a small school.", {"coins_min": 400})
S("wealth", "wealth_low", "你囊中不丰，却没欠过任何人的账。", "Your purse is thin, but you owe nobody anything.", {"coins_min": 0})

# the nine houses, the stars, the masks
S("deeds", "deed_ninth_named", "「第九家」的名字被你写进了簿册，后来人再也抹不掉。", "You wrote the name of the Ninth House into the register, and no later hand could rub it out.", {"flags_all": ["ninth_house_named"]})
S("deeds", "deed_star_read", "第九颗星的图，被你读懂了，也留给了后人。", "You read the chart of the ninth star and left it for those who come after.", {"flags_all": ["ninth_star_read"]})
S("deeds", "deed_star_lost", "星图在地底塌了，那一页，世上再没有人见过。", "The star chart collapsed underground, and no one has seen that page since.", {"flags_all": ["star_lost"]})
S("deeds", "deed_trial", "断崖上那场试炼，成了苍梧弟子们夜里的闲话。", "The trial on the cliff became a late-night tale among the Cangwu disciples.", {"flags_all": ["cliff_trial_done"]})
S("deeds", "deed_xuan_pact", "玄面的约定你没有忘，他也没有。", "You have not forgotten your pact with the Xuan-Mask, and neither has he.", {"flags_all": ["xuan_pact"]})
S("deeds", "deed_lei", "雷盟主在山门口目送你，直到你的背影消失。", "Head Lei watched from the gate until your back was out of sight.", {"flags_any": ["lei_endorse", "lei_stays"]})

# final image
S("image", "image_alliance_head", "论剑台上，新旗在风里舒展，人群里有人笑出了声。", "On the platform the new banner unfurled and someone in the crowd laughed aloud.", {"ending": ["alliance_head"]})
S("image", "image_recluse", "玉谷的清晨，竹梢还挂着露，一个孩子在院子里练拳。", "Dawn over the valley, dew on the bamboo tips, a child practising a stance in the yard.", {"ending": ["recluse"]})
S("image", "image_breaker", "风把灰烬吹过九根石柱，天地忽然宽了。", "Wind carried the ash past the nine pillars, and the world suddenly felt wider.", {"ending": ["breaker"]})
S("image", "image_undertow", "灰旗在南角垂着，一动不动，像水下的影子。", "The grey banner hung still at the south corner, a shadow under water.", {"ending": ["undertow"]})
S("image", "image_long_road", "山路蜿蜒向远处，你走在前头，身后有人唤你的名字。", "The mountain road wound into the distance, you walked ahead, and someone behind called your name.", {"ending": ["long_road"]})

SECTIONS = ["why", "hero_realm", "hero_skill", "comp", "comp_unmet", "faction", "pledge", "deeds", "hometown", "wealth", "image"]
json.dump({"sections": SECTIONS, "companions": list(C.keys()), "snippets": snips}, open(os.path.join(G, "story/epilogue.json"), "w"), ensure_ascii=False, indent=1)

# translations: drop the prologue endings, keep the generic screen text
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp))
    for f in ["pavilion", "couriers", "scribes", "neutral"]:
        x.pop("ending.faction." + f, None)
    for old in ["valley_sage", "valley_guardian", "lone_victor", "valley_falls"]:
        x.pop("ending.%s.title" % old, None); x.pop("ending.%s.body" % old, None)
    x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(endings), "endings,", len(snips), "snippets")
