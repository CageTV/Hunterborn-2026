Hunterborn 2026
Based on Hunterborn SE (Nexus 7900) by unuroboros and Hunterborn SE MCM (Nexus 17993) by Hazado. Needs both of them. Part of the 2026 series with Campfire 2026,
Frostfall 2026, Last Seed 2026, Simple Hunting Overhaul 2026, Immersive Death Cycle 2026 and Stress and Fear 2026.

WHAT IT DOES
------------
Hunterborn SE MCM has a 2,500-line SkyUI menu. This adds one "Hunterborn" section to SKSE Menu Framework with all of its options, so Hunterborn can be set up
without opening the SkyUI menu:

  Overview        is Hunterborn running, your experience, what is installed, and a Start / Stop button
  Features        what takes game time, the time multiplier, and which small game counts as huntable
  Tweaks          default actions for fresh and dressed kills, the pelt / material / meat / knife presets, realism options
  Enable          the powers and perks: Config, Foraging, Scrimshaw, Primitive Cooking, Sense Direction, Tracking, Taxonomy, Botany, Bounty,
                  Savage Arrows, Soups and Stews crafting
  Hotkeys         the eleven hunting hotkeys (click a key button, press the key)
  Stats           your carcasses cleaned and skinning / harvesting / foraging levels, and the experience reset presets
  Monster Hunter  which monsters can be processed
  Compatibility   the patch options for Frostfall, iNeed, SkyRe, PerMa and the other mods Hunterborn knows
  Profile         the settings file, applying it on every load, saving, loading and resetting

Every option is the same Hunterborn global variable the SkyUI menu writes, so the mod and the pages always agree, and the SkyUI menu can still be used.

WHEN THINGS TAKE EFFECT
-----------------------
The SkyUI menu did its real work when it closed (adding and removing powers and perks, rebuilding the animals' loot lists, restocking hunting knives).
These pages do the same: they list what will happen at the top, and run it once you have closed the menu and the game is idle. The heavy parts stay in
Hunterborn's own scripts; this plugin calls them, it does not copy them.

Your choices are kept in Data/SKSE/Plugins/HunterbornNative/settings.ini and applied on every game load, so they follow you to a new character. The first
time you load a game, whatever the game already has is taken into that file, so nothing resets. Your experience is progress, not a setting: it can be changed on
the Stats page but is never saved in the file.

HOTKEYS
-------
Hunterborn SE MCM's own script receives the key presses. When you change a key here, this plugin tells that script to release the old key and listen for the
new one, so the hotkeys keep working exactly as before.

REQUIREMENTS
------------
- Hunterborn SE (Nexus 7900) and Hunterborn SE MCM 1.6.8 (Nexus 17993), with the requirements they list (SkyUI)
- SKSE Menu Framework 3
- SKSE (Address Library for the build you use)

BUILDS
------
The installer asks which HunterbornNative.dll: "new" for Skyrim 1.6.1170 and newer, "older" for Skyrim VR and 1.6.1130 and older.

CREDITS AND LICENSE
-------------------
Hunterborn by unuroboros. Hunterborn SE MCM by Hazado, who allows modification and redistribution with credit. The settings pages and HunterbornNative.dll are
by CageTV, MIT licensed (see LICENSE.txt); they contain none of the original mods' code, scripts, meshes, textures, sounds or plugins.
