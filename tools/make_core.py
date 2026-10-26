"""Builds the core plugin Hunterborn2026.esp (Spriggit source in patches/Core/, compiled to an ESL-flagged plugin).

  python tools/make_core.py <spriggit-export-of-SE-MCM-Hunterborn.esp> <spriggit-export-of-the-Process-Hotkey-Fix>

Records (all overrides of Hunterborn.esp, so the plugin is a light plugin):
  Quest _DS_Hunterborn (003367)          the SE MCM quest with the Process Hotkey Fix's one extra property on _DS_HB_Monsters
  MagicEffect _DS_MGEF_Hotkey_Process     the Hotkey Fix's effect (binds the fixed hotkey script)
  Quest _DS_Hunterborn_Pet_Finder (09C5D3) SE MCM's own record again: Simple Hunterborn empties it (no aliases, no script), which breaks pets and lures
The Process Hotkey Fix is by Gasil (Nexus 73571, open permissions, credit required). Load after Simple Hunterborn.
"""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEMCM, HKFIX = sys.argv[1], sys.argv[2]
NAME = "Hunterborn2026.esp"
SRC = os.path.join(HERE, "patches", "Core")
NL = chr(10)


def find(folder, sub, needle):
    d = os.path.join(folder, sub)
    return os.path.join(d, [f for f in os.listdir(d) if needle in f][0])


if os.path.exists(SRC):
    shutil.rmtree(SRC)
for sub in ("Quests", "MagicEffects"):
    os.makedirs(os.path.join(SRC, sub))

jobs = [
    (find(HKFIX, "Quests", "003367"), "Quests"),
    (find(HKFIX, "MagicEffects", "045438"), "MagicEffects"),
    (find(SEMCM, "Quests", "_DS_Hunterborn_Pet_Finder"), "Quests"),
]
for src, sub in jobs:
    shutil.copyfile(src, os.path.join(SRC, sub, os.path.basename(src)))

open(os.path.join(SRC, "spriggit-meta.json"), "w", encoding="utf-8", newline=NL).write(NL.join([
    "{", '  "PackageName": "Spriggit.Yaml.Skyrim",', '  "Version": "0.41.0",', '  "Release": "SkyrimSE",', f'  "ModKey": "{NAME}"', "}", ""]))

masters = ["Skyrim.esm", "Update.esm", "Dawnguard.esm", "HearthFires.esm", "Dragonborn.esm", "Hunterborn.esp"]
lines = ["SpriggitSource:", "  PackageName: Spriggit.Yaml.Skyrim", "  Version: 0.41", f"ModKey: {NAME}", "GameRelease: SkyrimSE", "ModHeader:",
         "  Flags:", "  - Small", "  Stats:", "    Version: 1.7", "  Author: CageTV",
         "  Description: Hunterborn 2026 core records - the Process Hotkey Fix by Gasil, and Pet Finder restored after Simple Hunterborn. Load after SimpleHunterborn.esp.",
         "  MasterReferences:"]
for m in masters:
    lines += [f"  - Master: {m}", "    FileSize: 0"]
lines += ["  INTV: 1", ""]
open(os.path.join(SRC, "RecordData.yaml"), "w", encoding="utf-8", newline=NL).write(NL.join(lines))
print("source written:", SRC, "-", len(jobs), "records")
