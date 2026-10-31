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
30,000 records). All are small light plugins except Soups and Stews. Install the ones for mods you use. Each comes in a regular and an ESL form; the installer picks the one that matches your Hunterborn.esp.

ESL EDITION OF HUNTERBORN.ESP (installer option) - READ THE WARNING
--------------------------------------------------------------------
The installer asks which Hunterborn.esp. Regular is the default, and the one almost everyone should pick. The ESL edition renumbers the plugin's 2,965 records
into the light range (header 1.71, up to 4,096 records), so it takes no plugin slot. The price:
  - Every other mod made for the regular Hunterborn.esp stops working with it, because they point at the old record numbers: patches, IED profiles, animation
    and carry mods. This installer's own four patches and Hunterborn2026.esp come in ESL form. Anything else needs the regular edition or must be remade.
  - A save made with one edition cannot be loaded with the other. Start a new game; do not switch editions on a game you are playing.
  - Needs Skyrim 1.6.1130 or newer (not VR): choose the NEW build of HunterbornNative.dll. The same DLL works with both editions: when it sees the ESL
    edition it translates the record numbers it knows. Run PGPatcher again after switching.
Hunting in Skyrim has 12,594 records and would have to be split into several plugins to become ESL, so it is not offered. Mods are not split to make them ESL.

HOW A CLICK ON A KILL WORKS (Extras page)
-----------------------------------------
Three choices, saved with your settings and applied on every game load:
  One click (default)               clicking a fresh kill field dresses it and processes it (skin, harvest, butcher) in one go. Without a hunting knife you
                                    get less, and better knives give better quality, exactly as in Hunterborn. Sneak-click picks the carcass up to carry it.
  Hunterborn's menus                the original prompts: field dress, skin, harvest, butcher.
  Simple Hunting Overhaul loot window   the click opens the loot window and Simple Hunting Overhaul skins when you take the pelt (needs Simple Hunting
                                    Overhaul and Simple Hunterborn).
The "Click on fresh kill" and "Click on dressed kill" options on the Tweaks page show what is set; "Field dress and process" is the new fresh-kill action.

HUNTERBORN ANIMATIONS (optional)
--------------------------------
The installer's "Hunterborn Animations integration" is a set of merged scripts for Hunterborn - Animations (Nexus 80677, by Elsawirr and GiraPomba), which must be
installed first: none of its animations, meshes or plugins are included. With it, one click plays: kneel, the dress cut, the kneel idle, the stab-and-pull that
takes the parts, and the stand-up. With bare hands the claw dress and the harvest-fail pull play instead of the generic rock animation. Sneak-click carries the
animal in a pose that follows its size: bears across the back, wolves and deer on the left or right shoulder (at random), foxes and skeevers on the hip; a hare or
a chicken goes straight into the inventory. For the animals to look right on you, use Carry Your Carcasses (its IED profile and carcass meshes); it has no meshes
for bears, sabre cats, cows, horses, horkers, mammoths or bristlebacks, so those show nothing while carried.
Hunting in Skyrim's "HIS / HB Skinning Quest Started" message box is removed.

VOLS CLOAK PBR (optional, Community Shaders only)
-------------------------------------------------
PBR textures with PGPatcher json files for the Vols fur cloaks (cloak, black, brown, snow sabre, vale sabre) of Hunterborn - Animations / Immersive Hunting
Animations. Needs Community Shaders and PGPatcher, and the cloak mesh and textures of Hunterborn - Animations. Conversions by CageTV (Nexus 175588) of the original
textures; credit to their authors.

ANIMALLICA (Extras page)
------------------------
Animallica fills Skyrim's animal spawn lists with creatures that do not belong in Tamriel. "Animallica creatures" takes the same ones out as Animallica's lore
editions, at run time, on the Animallica plugin you already have (Animallica SE - Skyrim Wildlife Overhaul): "Lore friendly" removes what the Lore Friendly
edition removes, "Lore friendly (stricter)" what the Lore Edition Redux removes (also all tigers, sabertooths and the exotic pheasants). Neither lore plugin is
needed. It takes effect at the next game load and does not change animals already placed in your world.

SIMPLE HUNTERBORN
-----------------
Not needed. With the one-click hunt it is better left out: its loot tiers follow Simple Hunting Overhaul's experience, which no longer rises when Hunterborn does
the skinning. If it is installed, the Overview page says so, and load Hunterborn2026.esp after SimpleHunterborn.esp. (Hunterborn - Forbidden Prey calls only
functions that still exist, but has not been tested here.)

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
licensed (see LICENSE.txt). Hunterborn's meshes, textures and sounds come from the original mod and are not included. Hunterborn - Animations by Elsawirr and
GiraPomba: the "Hunterborn Animations integration" scripts are theirs merged with the Hunterborn 2026 scripts, with one change of their animation script (the
bare-hands animations and the carry poses by size); credit is also in each script's header. The Animallica lore lists were read from Animallica's own plugins
(Animallica, its Lore Friendly edition and the Lore Edition Redux, by their authors).
