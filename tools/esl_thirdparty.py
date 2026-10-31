"""The files of OTHER mods that point at Hunterborn.esp and therefore have to be renumbered for the ESL edition, grouped by mod.

Shared by tools/make_esl.py (copies the remapped files into esl/out/third-party/<folder>/) and tools/package.py (installer step "Other mods (ESL edition)").
Paths are relative to the mod folder / the Data folder and use forward slashes.

RULE: whenever Hunterborn.esp is renumbered, EVERY file that references it must be remapped and offered here. After a compaction scan the whole load order
(plugins that list Hunterborn.esp as a master, and json/ini/pex files that hold its record numbers) and add what is missing. A forgotten plugin that overrides
a Hunterborn record by its old number crashes the game at start-up (HunterbornAdvancedTaxonomy.esp did, 2026-10-31).
"""

IED = "SKSE/Plugins/IED/Profiles/Custom"
OAR = "Meshes/actors/character/animations/OpenAnimationReplacer/Carry Your Carcasses"

# (folder in esl/out/third-party, installer checkbox label, description, [files])
GROUPS = [
    ("Hunterborn - Animations", "Hunterborn - Animations (Nexus 80677)",
     "Its two plugins (Animations and Primitive Cooking) and the IED hunting knife and pelt profiles, renumbered for the ESL edition. They have the same names as the originals, so let them overwrite.",
     ["Hunterborn - Animations.esp", "Hunterborn - Animations_Primitive Cooking.esp", IED + "/Hunterborn - Hunting Knives.json", IED + "/Hunterborn - Hunting Pelts.json"]),
    ("Carry Your Carcasses", "Carry Your Carcasses and its animations",
     "CarryYourCarcasses.esp, CYC_Anim1.esp (CYC Animations - Hunterborn version) and the three IED carry profiles, renumbered for the ESL edition.",
     ["CarryYourCarcasses.esp", "CYC_Anim1.esp", IED + "/Carry Your Carcasses.json", IED + "/Carry Your Carcasses [horse].json", IED + "/Carry Your Carcasses [with pelts].json"]),
    ("Immersive Carcass Carrying", "Immersive Carcass Carrying",
     "Its IED profile and the four Open Animation Replacer configs (deer, fox, goat, wolf) whose inventory conditions point at Hunterborn items, renumbered for the ESL edition.",
     [IED + "/ICC - Hunterborn.json"] + [OAR + "/" + a + "/config.json" for a in ("Deer", "Fox", "Goat", "Wolf")]),
    ("Eating Animations", "Eating Animations and Sounds - Hunterborn patch",
     "EASHunterbornPatch.esp renumbered for the ESL edition.", ["EASHunterbornPatch.esp"]),
    ("Hunterborn Extender", "Hunterborn Extender (Advanced Taxonomy)",
     "HunterbornAdvancedTaxonomy.esp renumbered for the ESL edition. The original overrides a Hunterborn record by its old number and crashes the game at start-up with the ESL edition.",
     ["HunterbornAdvancedTaxonomy.esp"]),
    ("Last Seed Patch", "Last Seed 2026 - Hunterborn patch",
     "Hunterborn - LastSeed Patch SE.esp renumbered for the ESL edition.", ["Hunterborn - LastSeed Patch SE.esp"]),
    ("SOTW CACO Patch", "Skills of the Wild and CACO patch",
     "SOTW_CACO Patch.esp renumbered for the ESL edition.", ["SOTW_CACO Patch.esp"]),
    ("SHO for Hunterborn", "Trading and NPC reactions for Hunterborn (SHO for Hunterborn)",
     "SHO for Hunterborn.esp renumbered for the ESL edition.", ["SHO for Hunterborn.esp"]),
    ("Bathing Soaps", "Bathing in Skyrim Soaps from Hunterborn Animal Fat",
     "ES_BISRSoapsForHunterborn.esp renumbered for the ESL edition.", ["ES_BISRSoapsForHunterborn.esp"]),
    ("Hunterborn Descriptions", "Hunterborn Descriptions",
     "Hunterborn_DESC.ini with its item lines renumbered for the ESL edition.", ["Hunterborn_DESC.ini"]),
]

# Plugin whose presence (state Active in the mod manager's load order) pre-ticks that mod's checkbox in the installer. MO2 can only look at PLUGINS:
# mods without a plugin are looked up by a file they install (see the last two entries).
DETECT = {
    "Hunterborn - Animations": "Hunterborn - Animations.esp",
    "Carry Your Carcasses": "CarryYourCarcasses.esp",
    "Eating Animations": "EASHunterbornPatch.esp",
    "Hunterborn Extender": "HunterbornAdvancedTaxonomy.esp",
    "Last Seed Patch": "Hunterborn - LastSeed Patch SE.esp",
    "SOTW CACO Patch": "SOTW_CACO Patch.esp",
    "SHO for Hunterborn": "SHO for Hunterborn.esp",
    "Bathing Soaps": "ES_BISRSoapsForHunterborn.esp",
    # no plugin: MO2 finds these only when its FOMOD installer setting "allow any file" is on (otherwise they stay unticked, which is harmless)
    "Immersive Carcass Carrying": "SKSE/Plugins/IED/Profiles/Custom/ICC - Hunterborn.json",
    "Hunterborn Descriptions": "Hunterborn_DESC.ini",
}
