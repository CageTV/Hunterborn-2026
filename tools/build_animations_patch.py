"""Compile the Hunterborn 2026 - Animations patch scripts (patches/Animations/src) -> patches/Animations/build.
Imports: the patch sources, Hunterborn 2026's own src (types), the Hunterborn Animations sources (compile-time types only, never shipped), then the usual ones.
Usage: python tools/build_animations_patch.py"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = r"E:\Tabula Rasa\Stock Game"
MODS = r"E:\Tabula Rasa\mods"
ANIM = r"H:\Modlists\Tabula\mods\Hunterborn - Animations\Source\Scripts"
SRC = os.path.join(HERE, "patches", "Animations", "src")
OUT = os.path.join(HERE, "patches", "Animations", "build")
COMPILER = os.path.join(GAME, "Papyrus Compiler", "PapyrusCompiler.exe")
FLAGS = os.path.join(GAME, "Data", "Source", "Scripts", "TESV_Papyrus_Flags.flg")
IMPORTS = [
    SRC,
    os.path.join(HERE, "src"),
    ANIM,
    os.path.join(HERE, "tools", "stubs"),
    r"H:\Modlists\Tabula\mods\Immersive Equipment Displays\Scripts\Source",
    os.path.join(HERE, "reference", "semcm"),
    os.path.join(HERE, "reference", "base"),
    r"E:\WorkSpace\HuntingInSkyrim-analysis\scripts\source",
    r"E:\WorkSpace\Frostfall-Modernized\imports\skyui",
    os.path.join(MODS, "FileAccess Interface for Skyrim SE Scripts - FISSES", "scripts", "source"),
    os.path.join(MODS, "powerofthree's Papyrus Extender", "Source", "scripts"),
    os.path.join(MODS, "Skyrim Script Extender (SKSE64)", "Scripts", "Source"),
    os.path.join(MODS, "PapyrusUtil SE - Modders Scripting Utility Functions", "Scripts", "Source"),
    os.path.join(GAME, "Data", "Source", "Scripts"),
]
for p in [COMPILER, FLAGS, SRC, ANIM] + IMPORTS:  # all must exist
    if not os.path.exists(p):
        raise SystemExit(f"missing: {p}")
if os.path.exists(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT)
log, rc = "", 0
for name in sorted(n for n in os.listdir(SRC) if n.lower().endswith(".psc")):
    r = subprocess.run([COMPILER, name, f"-f={FLAGS}", "-i=" + ";".join(IMPORTS), f"-o={OUT}"], capture_output=True, text=True, cwd=SRC, timeout=180)
    log += (r.stdout or "") + (r.stderr or "")
    rc = rc or r.returncode
open(os.path.join(OUT, "compile.log"), "w", encoding="utf-8").write(log)
errors = [l for l in log.splitlines() if ".psc(" in l]
print(f"compiler exit {rc}: {len([n for n in os.listdir(OUT) if n.endswith('.pex')])} .pex; {len(errors)} error lines")
for l in errors[:25]:
    print("  " + l)
sys.exit(0 if rc == 0 and not errors else 1)
