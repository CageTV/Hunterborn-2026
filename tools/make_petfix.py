"""Builds the Pet_Finder repair patch as Spriggit source (patches/PetFix/) and compiles it to an ESL-flagged plugin.

  python tools/make_petfix.py <spriggit-export-of-SE-MCM-Hunterborn.esp>

Simple Hunterborn overrides the quest _DS_Hunterborn_Pet_Finder (09C5D3:Hunterborn.esp) with an empty one (no aliases, no script, flags 0), which
leaves Hunterborn's pets and lures without the quest their Player script talks to. This patch carries SE MCM's own record again, so it
has to load after SimpleHunterborn.esp.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPORT = sys.argv[1]
NAME = "Hunterborn2026_PetFix.esp"
SRC = os.path.join(HERE, "patches", "PetFix")
NL = chr(10)

rec = [f for f in os.listdir(os.path.join(EXPORT, "Quests")) if "_DS_Hunterborn_Pet_Finder" in f][0]
if os.path.exists(SRC):
    shutil.rmtree(SRC)
os.makedirs(os.path.join(SRC, "Quests"))
shutil.copyfile(os.path.join(EXPORT, "Quests", rec), os.path.join(SRC, "Quests", rec))

open(os.path.join(SRC, "spriggit-meta.json"), "w", encoding="utf-8", newline=NL).write(NL.join([
    "{", '  "PackageName": "Spriggit.Yaml.Skyrim",', '  "Version": "0.41.0",', '  "Release": "SkyrimSE",', f'  "ModKey": "{NAME}"', "}", ""]))

masters = ["Skyrim.esm", "Update.esm", "Dawnguard.esm", "HearthFires.esm", "Dragonborn.esm", "Hunterborn.esp"]
lines = ["SpriggitSource:", "  PackageName: Spriggit.Yaml.Skyrim", "  Version: 0.41", f"ModKey: {NAME}", "GameRelease: SkyrimSE", "ModHeader:",
         "  Flags:", "  - Small", "  Stats:", "    Version: 1.7", "  Author: CageTV",
         "  Description: Restores Hunterborn's Pet Finder quest after Simple Hunterborn empties it. Load after SimpleHunterborn.esp.",
         "  MasterReferences:"]
for m in masters:
    lines += [f"  - Master: {m}", "    FileSize: 0"]
lines += ["  INTV: 1", ""]
open(os.path.join(SRC, "RecordData.yaml"), "w", encoding="utf-8", newline=NL).write(NL.join(lines))
print("source written:", SRC)
