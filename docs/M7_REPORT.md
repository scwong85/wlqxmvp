# M7 report: relationships and companions

## What exists
- Companion data (`content/companions/companions.json`): 沈青禾 (support), 陆沉舟 (striker), 白砚 (control), each with stats,
  portrait reference, preferred activities, recruit and departure conditions, two battle abilities and one bond ability. All text in zh_CN and en.
  A validator test proves broken data (missing field, bad role, wrong ability count, unknown activity) is reported.
- Rules (pure, no UI): `RelationshipRules` (preferred-activity +1 bond, meeting by day, recruit evaluator returning ready / refuse / unavailable with reasons,
  departure by low bond or story flag, decline) and `PartySystem` (one active companion, swap, dismiss).
- Screens: companion panel (button in the top bar) with bond, status, likes, abilities and Invite / Make active / Ask to leave;
  a day-3 invitation dialog (accept or "maybe later"); results show who was met or left.
- Saves: the active companion is stored; older saves load fine; an active companion who is not in the party is cleared on load.

## Evidence
- Unit: 602 checks pass, including each companion's join / refuse (bond, day, attribute) / unavailable cases, leave-and-rejoin,
  story-flag departure, party swap rules, and a scripted week (join, leave through a story flag, rejoin, exact save round trip).
- UI smoke: opens the panel, accepts the day-3 invitation, dismisses and re-invites. Browser test passes at 4 sizes; screenshot `docs/spike/screens/m7_party.png`.

## Notes
- Recruit thresholds (bond 6 / 6 / 8) are first guesses; M12 balancing should tune them.
- Story flags (`lu_confined`, `shen_betrayed_patients`, `bai_expelled`) exist as data but no story event sets them yet (M8/M12).
- Battle and bond abilities are names and descriptions only until M9 and M8.
- Portraits are placeholder medallions.
