"""Builds the Hunterborn 2026 ESL edition: Hunterborn.esp renumbered into the light range (header 1.71, 4096 records), and every plugin / json / ini that
points at it repointed. Uses tools/eslcompact (Mutagen). Nothing in the game folders is touched; the personal copies for the test list go to one new mod folder.

  esl/out/            what the installer ships: Hunterborn.esp, Hunterborn2026.esp and the four patches, all for the ESL edition
  esl/work/map.tsv    old local id -> new local id (also compiled into the DLL: plugin/src/HunterbornEslMap.inc)
  PERSONAL            the third-party plugins and files of the test list that reference Hunterborn.esp, repointed, in one mod folder

Usage: python tools/make_esl.py [personal]
"""
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(HERE, "tools", "eslcompact", "bin", "Release", "net9.0", "EslCompact.dll")
MODS = r"H:\Modlists\Tabula\mods"
SRC_ESP = os.path.join(HERE, "reference", "semcm-mod", "Hunterborn.esp")
CORE_ESL = os.path.join(HERE, "package", "Hunterborn2026.esp")
PATCHES = os.path.join(MODS, "Hunterborn 2026 Patches")
PATCH_FILES = ["Hunterborn - Campfire Patch.esp", "Hunterborn - Leather Tanning.esp", "Hunterborn_CACO-SE_Patch.esp", "Hunterborn - Soups and Stews.esp"]
WORK = os.path.join(HERE, "esl", "work")
OUT = os.path.join(HERE, "esl", "out")
MAP = os.path.join(WORK, "map.tsv")
TARGET = "Hunterborn.esp"

# the test list's own copies: (mod folder, relative path)
PERSONAL_PLUGINS = [
    ("Carry Your Carcasses", "CarryYourCarcasses.esp"),
    ("CYC Animations - Hunterborn version", "CYC_Anim1.esp"),
    ("Eating Animations and Sounds - Hunterborn Patche", "EASHunterbornPatch.esp"),
    ("Hunterborn - Animations", "Hunterborn - Animations.esp"),
    ("Hunterborn - Animations", "Hunterborn - Animations_Primitive Cooking.esp"),
    ("Hunterborn Extender", "HunterbornAdvancedTaxonomy.esp"),
    ("Last Seed 2026 - Patches", "Hunterborn - LastSeed Patch SE.esp"),
    ("Skills of the Wild and CACO Patch", "SOTW_CACO Patch.esp"),
    ("Trading and NPC reactions for Hunterborn", "SHO for Hunterborn.esp"),
]
PERSONAL_JSON = [
    ("Carry Your Carcasses", r"SKSE\Plugins\IED\Profiles\Custom\Carry Your Carcasses.json"),
    ("Carry Your Carcasses", r"SKSE\Plugins\IED\Profiles\Custom\Carry Your Carcasses [horse].json"),
    ("Carry Your Carcasses", r"SKSE\Plugins\IED\Profiles\Custom\Carry Your Carcasses [with pelts].json"),
    ("Hunterborn - Animations", r"SKSE\Plugins\IED\Profiles\Custom\Hunterborn - Hunting Knives.json"),
    ("Hunterborn - Animations", r"SKSE\Plugins\IED\Profiles\Custom\Hunterborn - Hunting Pelts.json"),
]
PERSONAL_INI = [("Hunterborn Descriptions", "Hunterborn_DESC.ini")]


def run(*args):
    r = subprocess.run(["dotnet", TOOL] + list(args), capture_output=True, text=True)
    out = (r.stdout + r.stderr).strip()
    if r.returncode != 0:
        raise SystemExit(f"FAILED {args[0]} {os.path.basename(args[1])}: {out}")
    return out


def load_map():
    m = {}
    for line in open(MAP):
        a, b = line.split()
        m[int(a, 16)] = int(b, 16)
    return m


os.makedirs(WORK, exist_ok=True)
os.makedirs(os.path.join(OUT, "patches"), exist_ok=True)

# 1. the plugin itself (the source copy keeps the name Hunterborn.esp so the map is in terms of that plugin)
stage = os.path.join(WORK, "src")
os.makedirs(stage, exist_ok=True)
shutil.copyfile(SRC_ESP, os.path.join(stage, TARGET))
print(run("compact", os.path.join(stage, TARGET), os.path.join(OUT, TARGET), MAP))
print(run("verify", os.path.join(stage, TARGET), os.path.join(OUT, TARGET), MAP))

# 2. the plugins that ship with the ESL edition
for src, dst in [(CORE_ESL, os.path.join(OUT, "Hunterborn2026.esp"))] + [(os.path.join(PATCHES, f), os.path.join(OUT, "patches", f)) for f in PATCH_FILES]:
    print(run("repoint", src, dst, MAP, TARGET))
    print(run("check", dst, dst, MAP, TARGET))

if len(sys.argv) > 1 and sys.argv[1] == "personal":
    pdir = os.path.join(MODS, "Hunterborn 2026 - ESL Edition (remapped plugins)")
    os.makedirs(pdir, exist_ok=True)
    for mod, rel in PERSONAL_PLUGINS:
        src = os.path.join(MODS, mod, rel)
        dst = os.path.join(pdir, rel)
        print(run("repoint", src, dst, MAP, TARGET))
        print(run("check", dst, dst, MAP, TARGET))
    m = load_map()
    for mod, rel in PERSONAL_JSON:
        s = open(os.path.join(MODS, mod, rel), encoding="utf-8", newline="").read()
        n = [0]

        def sub(mo):
            old = int(mo.group(1))
            n[0] += 1
            return f'"id":{m[old & 0xFFFFFF]},"plugin":"Hunterborn.esp"' if (old & 0xFFFFFF) in m else mo.group(0)
        s2 = re.sub(r'"id":(\d+),"plugin":"Hunterborn\.esp"', sub, s)
        dst = os.path.join(pdir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, "w", encoding="utf-8", newline="").write(s2)
        print(f"{rel}: {n[0]} item references")
    for mod, rel in PERSONAL_INI:
        s = open(os.path.join(MODS, mod, rel), encoding="utf-8", newline="").read()
        n = [0]

        def subi(mo):
            old = int(mo.group(1), 16)
            n[0] += 1
            return f"0x{m[old]:X}~Hunterborn.esp|" if old in m else mo.group(0)
        s2 = re.sub(r"0x([0-9A-Fa-f]+)~Hunterborn\.esp\|", subi, s)
        open(os.path.join(pdir, rel), "w", encoding="utf-8", newline="").write(s2)
        print(f"{rel}: {n[0]} lines")
    print("personal copies in", pdir)
print("done")
