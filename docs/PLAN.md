# Hunterborn 2026 - plan

Base: Hunterborn SE MCM 1.6.8 (Hazado, open permissions) on top of Hunterborn 1.6.2 (unuroboros, required, never redistributed).

## Findings that drive the order of work
- Hunterborn's own Papyrus is light (about 3.8 calls/s while hunting). The measured hot spots were other mods (Frostfall item handler, Last Seed compatibility scan), both fixed.
- The script lineage is mixed: six core scripts are overridden by older add-on copies (Player, Actions, Monsters, mgef_Hotkey, mgef_Forage, mgef_Scrimshaw).
- Simple Hunterborn guts the Pet_Finder quest (no aliases, no script), so pets cannot work.
- The SkyUI MCM is 2,492 lines: 89 interactive options (66 toggles, 11 key bindings, 9 menus, 3 sliders) on 8 pages, generated into docs/mcm_table.json.
  56 only set one dsGlobals variable; 31 set a deferred flag that OnConfigClose applies (spells, perks, DeathItem lists, knife stock, experience
  presets); 2 have inline logic (custom meat yield, Soups and Stews token check).

## Stages
1. (done) tools/gen_mcm_table.py -> docs/mcm_table.json / .md
2. DLL HunterbornNative.dll (SKSE Menu Framework): pages generated from the table; globals read/written directly; close-apply mirrors OnConfigClose natively
   (AddSpell/RemoveSpell/AddPerk/RemovePerk, experience presets) and calls the Papyrus functions that stay in script (StartHunterborn, StopHunterborn, InitDeathItems...).
3. Merged script set (SE MCM base + Player dialogue guard + Forage/Scrimshaw/Hotkey/Monsters folded in), cached config reads in Actions.
4. Pet_Finder repair patch for Simple Hunterborn; SHO quest override check.
5. Native preset application (pelt values, meat weights) at kDataLoaded instead of loops at every load.
6. Synthesis patcher fork (HunterbornExtender) and the old zEdit patchers.
7. Carry Your Carcasses + animation versions; Hunting in Skyrim / Fishing in Skyrim (Rich Webster's go-ahead).
