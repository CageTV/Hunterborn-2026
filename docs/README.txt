Hunterborn 2026
A modernised Hunterborn: Hunterborn SE MCM (Hazado) with its menu moved to SKSE Menu Framework, its settings applied by a native SKSE plugin, and the
fixes found while measuring it. Part of the 2026 series with Campfire 2026, Frostfall 2026, Last Seed 2026, Simple Hunting Overhaul 2026, Immersive Death
Cycle 2026 and Stress and Fear 2026.

WHAT YOU GET
------------
Hunterborn SE MCM already replaces the plugin and 14 scripts of the original Hunterborn. This replaces Hunterborn SE MCM: install the original Hunterborn
(Nexus 7900) first, then this on top. Do not also install Hunterborn SE MCM or the Process Hotkey Fix, both are included.

  SKSE Menu Framework pages   every option of the old SkyUI menu, in eight pages plus Extras and Profile. The SkyUI menu keeps one page that points there
                              and lists the mods it detected.
  HunterbornNative.dll        applies your settings on every game load, runs the work the SkyUI menu did when it closed, rebinds the hotkeys, and can turn
                              Hunterborn's 51 informational message boxes into notifications (Extras page, off by default).
  Hunterborn2026.esp          a small light plugin: the hotkey fix's records, the Pet Finder quest restored for when Simple Hunterborn empties it, and the
                              startup quest without its "Completed: Hunterborn" banner.
  Scripts                     the SE MCM scripts, with the Process Hotkey Fix folded in, and the Hunting in Skyrim code moved to its own script so Hunterborn
                              works with or without that mod (before, its absence stopped the whole Actions script loading: no tracking, broken loot).

STARTS BY ITSELF
----------------
Hunterborn starts on its own when you load a game (Overview page: "Start automatically"). The Hunterborn logo fades in for a few seconds instead of the
start-up message boxes (Extras page, "Show the logo when Hunterborn starts").

AUTOPATCH: CREATURES FROM OTHER MODS
------------------------------------
Hunterborn works with the animals other mods add, without a patch plugin. When the game's data has loaded, HunterbornNative.dll looks at every creature that
uses a loot list of its own and works out which of Hunterborn's types it is: from your own rules, its name, its race, skeleton and voice compared with the
vanilla animals, and its race name. Summons, spirits, pets, mounts and creatures that are not animals are left alone. A creature that is found is treated like
the vanilla animal of its type: it leaves a Hunterborn carcass that is skinned, harvested and butchered, and its meat, pelts and animal parts come from
Hunterborn. Whatever else is on its loot list (gold, special drops, gear) stays. When Hunterborn is stopped, the original loot is back.

A report of what was found, and why, is written to Documents\My Games\Skyrim Special Edition\SKSE\HunterbornNative_AutoPatch.txt every time the game starts.
Your own rules go in Data\SKSE\Plugins\HunterbornNativeutopatch.ini (type names are in the report):
  [Map]          tiger = Sabrecat           a word in a creature's name, race or skeleton, and the Hunterborn type it counts as
  [Skip]         koi                        a word that marks a creature to leave alone
  [SkipPlugins]  SomeMod.esp                every creature this plugin adds is left alone

It also gives every recipe of another mod that uses Troll Fat a twin recipe with Animal Fat (three times as much) in its place, so soap, supplies and the like
can be made from the fat Hunterborn gives. The original recipe is unchanged. Recipes about trolls are left alone.

PAGES
-----
  Overview        is Hunterborn running, the logo, your experience, the mods it found in your load order, and Start / Stop / Reapply templates
  Features        what takes game time, the time multiplier, and which small game counts as huntable
  Tweaks          default actions for fresh and dressed kills, the pelt / material / meat / knife presets, realism options
  Enable          the powers and perks: Config, Foraging, Scrimshaw, Primitive Cooking, Sense Direction, Tracking, Taxonomy, Botany, Bounty,
                  Savage Arrows, Soups and Stews crafting
  Hotkeys         the eleven hunting hotkeys (click a key button, press the key)
  Stats           your carcasses cleaned and skinning / harvesting / foraging levels, and the experience reset presets
  Monster Hunter  which monsters can be processed
  Compatibility   the patch options for Frostfall, iNeed, SkyRe, PerMa and the other mods Hunterborn knows
  Extras          messages as notifications
  Profile         the settings file, applying it on every load, saving, loading and resetting

Every option is the same Hunterborn global variable the SkyUI menu wrote, so the mod and the pages always agree.

WHEN THINGS TAKE EFFECT
-----------------------
The SkyUI menu did its real work when it closed (adding and removing powers and perks, rebuilding the animals' loot lists, restocking hunting knives).
These pages do the same: they list what will happen at the top, and run it once you have closed the menu and the game is idle.

Your choices are kept in Data/SKSE/Plugins/HunterbornNative/settings.ini and applied on every game load, so they follow you to a new character. The first
time you load a game, whatever the game already has is taken into that file, so nothing resets. Your experience is progress, not a setting: it can be changed on
the Stats page but is never saved in the file.

PATCHES
-------
The installer offers the four patches from Hunterborn SE MCM as options: Campfire Patch, Leather Tanning, CACO-SE Patch and Soups and Stews (large, 7 MB,
30,000 records). All are small light plugins except Soups and Stews. Install the ones for mods you use.

SIMPLE HUNTERBORN
-----------------
Not needed. If it is installed, the Overview page says so, and load Hunterborn2026.esp after SimpleHunterborn.esp.

REQUIREMENTS
------------
- Hunterborn SE (Nexus 7900)
- SkyUI, SKSE (Address Library for the build you use), SKSE Menu Framework 3

BUILDS
------
The installer asks which HunterbornNative.dll: "new" for Skyrim 1.6.1170 and newer, "older" for Skyrim VR and 1.6.1130 and older.

CREDITS AND LICENSE
-------------------
Hunterborn by unuroboros. Hunterborn SE MCM 1.6.8 by Hazado (Nexus 17993), who allows modification and redistribution with credit: its plugin, scripts,
translations and patches are included here, with the changes above. Process Hotkey Fix by Gasil (Nexus 73571), open permissions with credit: folded into
_DS_HB_Monsters and _DS_HB_mgef_Hotkey. HunterbornNative.dll, the settings pages, the Hunting in Skyrim bridge script and the SKSE logic are by CageTV, MIT
licensed (see LICENSE.txt). Hunterborn's meshes, textures and sounds come from the original mod and are not included.
