# Hunterborn 2026 - what happens to every patch

Rule of thumb: **behaviour goes in the DLL, our own records go in one tiny ESL, and a patch that needs someone else's plugin stays a separate optional
file in the installer.** Merging patches only helps when they share the same masters; these do not, and every optional patch is already light (ESL).

## Into the DLL (no plugin needed)
| Was | Now |
|---|---|
| Hunterborn - Messages to Notifications (252 messages, 55 different from SE MCM's: 51 lose the message-box flag, 13 reworded) | `Notifications.cpp`: an "Extras" toggle that converts the 51 informational pop-ups at runtime and can be switched back. The old patch was built on base 1.6.2 and would undo SE MCM's own message changes. Rewording of 13 messages not done (localized text). |
| SkyUI menu, hotkeys, menu-close work | `Settings` / `Actions` / `Menu` (done) |
| Pelt / meat value presets applied by script loops | later: at kDataLoaded in one native pass |

## Into the core script set (one merged `_DS_HB_*` set, guarded so it does nothing when the other mod is absent)
| Was | Now |
|---|---|
| Hunterborn - Immersive Start (`_DS_HB_MAIN`: one line, `StartupQuest.SetStage(10)` commented out) | a switch read by the merged MAIN |
| Hunterborn - ARBR scripts (`_DS_HB_Actions` +25 lines, `_DS_HB_MAIN` +12: needs an empty bottle to extract blood/venom) | same logic, guarded by `EmptyBottleKeyword != None`; the ARBR plugin only fills the properties |
| Older add-on copies of Player / Actions / Monsters / mgef_Hotkey / mgef_Forage / mgef_Scrimshaw | folded into the SE MCM versions |

## Into one tiny core plugin `Hunterborn2026.esp` (ESL, always installed, loads after Simple Hunterborn)
- the Pet_Finder quest record (identical to SE MCM's, so it does nothing unless Simple Hunterborn empties it) - built today as `Hunterborn2026_PetFix.esp`
- the globals the merged scripts read (Immersive Start ...)

## Separate optional patches in the installer (a third-party master each)
| Patch | Master | Size | Notes |
|---|---|---|---|
| Hunterborn - Campfire Patch | Campfire.esm | 3.7 KB ESL | from SE MCM |
| Hunterborn - Leather Tanning | Hunterborn.esp only | 12.9 KB ESL | from SE MCM |
| Hunterborn_CACO-SE_Patch | Complete Alchemy & Cooking Overhaul | 113 KB ESL | from SE MCM |
| Hunterborn - Soups and Stews | Hunterborn.esp | 7.4 MB, 30,223 records | from SE MCM; the one that needs real work (see below) |
| ARBR (hunterborn ARBR.esp) | Alchemy Requires Bottles Redux | 18.6 KB ESL | plugin only; scripts live in the merged set |
| Hunterborn Apothecary Patch | Apothecary.esp | 21.9 KB ESL | |
| Animal Blood Potion Sacrosanct Patch | Animal Blood Potions + Sacrosanct | 14.9 KB ESL | needs AnimalBloodPotionsSSE.esp |
| Forbidden Prey - Sacrosanct Patch | Hunterborn - Forbidden Prey + Sacrosanct | 8.8 KB ESL | |
| Hunterborn Survival Patch | ccqdrsse001-survivalmode.esl | 54.7 KB, 190 records | candidate to ESL-flag |
| HB-Surv + Eating Anim | TaberuAnimation.esp | 37.9 KB, 121 records | |
| Hunterborn - iNeed Patch | iNeed.esp | 0.9 KB | |

## To investigate before deciding
- `hunterbornQLblockmonster.esp` (8 vanilla DeathItem leveled lists, for Quick Loot) and `Hunterborn - Food Base.esp` (7 vanilla food records): Hunterborn's own scripts
  rewrite the death-item lists at runtime, so these may be stale.
- Soups and Stews: 24,662 recipes + 5,560 soups generated as ingredient combinations. Check the official "ESL-Flagged" variant, then consider a native replacement.

## Not ours
- Simple Hunterborn (Monops) and its 50 compatibility plugins. Permissions not checked; the plan is to generate equivalents (Synthesis patcher fork).
