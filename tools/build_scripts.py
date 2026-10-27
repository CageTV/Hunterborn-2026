"""Compile the Hunterborn 2026 scripts with the official Papyrus compiler.

  python tools/build_scripts.py            src/*.psc          -> build/
  python tools/build_scripts.py check      reference/semcm/_DS_HB_Player.psc -> build-check/ (toolchain sanity check)

Import order: the scripts being built, the SE MCM sources, the original Hunterborn sources (types the SE MCM set does not repeat),
SkyUI, powerofthree's Papyrus Extender, SKSE, then vanilla.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = r"E:\Tabula Rasa\Stock Game"
MODS = r"E:\Tabula Rasa\mods"
check = len(sys.argv) > 1 and sys.argv[1] == "check"
SRC = os.path.join(HERE, "src")
OUT = os.path.join(HERE, "build-check" if check else "build")
COMPILER = os.path.join(GAME, "Papyrus Compiler", "PapyrusCompiler.exe")
FLAGS = os.path.join(GAME, "Data", "Source", "Scripts", "TESV_Papyrus_Flags.flg")
IMPORTS = [
    SRC,
    os.path.join(HERE, "reference", "semcm"),
    os.path.join(HERE, "reference", "base"),
    r"E:\WorkSpace\HuntingInSkyrim-analysis\scripts\source",  # Hunting in Skyrim's own sources: SE MCM's Actions casts to its types
    r"E:\WorkSpace\Frostfall-Modernized\imports\skyui",  # SkyUI sources: the SkyUI menu script extends SKI_ConfigBase
    os.path.join(MODS, "FileAccess Interface for Skyrim SE Scripts - FISSES", "scripts", "source"),  # FISS: the SkyUI menu script saves profiles with it
    os.path.join(MODS, "powerofthree's Papyrus Extender", "Source", "scripts"),
    os.path.join(MODS, "Skyrim Script Extender (SKSE64)", "Scripts", "Source"),
    os.path.join(GAME, "Data", "Source", "Scripts"),
]
for p in [COMPILER, FLAGS, SRC] + IMPORTS:
    if not os.path.exists(p):
        raise SystemExit(f"missing: {p}")
if os.path.exists(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT)
if check:
    names = ["_DS_HB_Player.psc", "_DS_HB_Monsters.psc"]
    work = os.path.join(HERE, "reference", "semcm")
else:
    names = sorted(n for n in os.listdir(SRC) if n.lower().endswith(".psc"))
    work = SRC
log, rc = "", 0
for name in names:
    r = subprocess.run([COMPILER, name, f"-f={FLAGS}", "-i=" + ";".join(IMPORTS), f"-o={OUT}"], capture_output=True, text=True, cwd=work, timeout=180)
    log += (r.stdout or "") + (r.stderr or "")
    rc = rc or r.returncode
open(os.path.join(OUT, "compile.log"), "w", encoding="utf-8").write(log)
errors = [l for l in log.splitlines() if ".psc(" in l]
print(f"compiler exit {rc}: {len([n for n in os.listdir(OUT) if n.endswith('.pex')])} .pex; {len(errors)} error lines")
for l in errors[:25]:
    print("  " + l)
sys.exit(0 if rc == 0 and not errors else 1)
