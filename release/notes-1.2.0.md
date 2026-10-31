Hunterborn 2026 1.2.0. Install over 1.1.0. Needs the original Hunterborn (Nexus 7900), SkyUI, SKSE and SKSE Menu Framework 3.

New in 1.2.0:
- ESL edition of Hunterborn.esp (installer option "Which Hunterborn.esp"; Regular stays the default). Its 2,965 records are renumbered into the light range, which frees a plugin slot. WARNING: every other mod made for the regular Hunterborn.esp stops working with it (patches, IED profiles, animation and carry mods point at the old record numbers; the four patches and Hunterborn2026.esp in this installer come in ESL form), saves are not interchangeable between the two editions (start a new game), and it needs Skyrim 1.6.1130 or newer (not VR) with the NEW build of HunterbornNative.dll. The DLL works with both editions and translates the record numbers by itself.
- The Nexus page and README explain the warning. Hunting in Skyrim is not offered as ESL (12,594 records would need splitting).
- tools/eslcompact and tools/make_esl.py (the Mutagen-based tool and script that build the ESL edition and repoint plugins, json and ini files at it) are in the repository.
