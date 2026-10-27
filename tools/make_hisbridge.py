"""Splits the Hunting in Skyrim code out of _DS_HB_Actions into a bridge script, so Actions still loads when HiS is not installed.

SE MCM's Actions casts to HiS script types (HISHBSkinningScript ...). With HiS missing, the engine cannot link those types and
the WHOLE Actions script fails to load: every property on the main quest comes back empty (Track, Items, MeatGrinder ...).
The HiS code now lives in _DS_HB_HiSBridge (global functions); Actions keeps thin wrappers that call it. If HiS is missing only
the bridge fails, and only when called (already gated by isHiSLoaded).

  python tools/make_hisbridge.py      reads reference/semcm/_DS_HB_Actions.psc, writes src/_DS_HB_Actions.psc and src/_DS_HB_HiSBridge.psc
"""
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(HERE, "reference", "semcm", "_DS_HB_Actions.psc")
text = open(SRC, encoding="utf-8", errors="surrogateescape", newline="").read()
nl = "\r\n" if "\r\n" in text else "\n"
lines = text.split(nl)

start = next(i for i, l in enumerate(lines) if l.startswith("Function DisableHiSSkinning"))
skin = next(i for i, l in enumerate(lines) if l.startswith("Function SkinAnimalHIS"))
end = next(i for i in range(skin, len(lines)) if lines[i].startswith("EndFunction"))
block = lines[start:end + 1]

body = nl.join(block)
body = body.replace("Function DisableHiSSkinning()", "Function DisableHiSSkinning() global")
body = body.replace("Function SkinAnimalHIS(Actor akActorRef, MiscObject skin)", "Function SkinAnimalHIS(_DS_HB_Actions act, Actor akActorRef, MiscObject skin) global")
body = body.replace("DisableHiSSkinning()" + nl + nl + "\t\t\tDebugMode", "DisableHiSSkinning()" + nl + nl + "\t\t\tact.DebugMode")
for name in ("dsGlobals", "PlayerRef", "BearFaction", "GoatFaction", "HorkerFaction", "MammothFaction", "SabreCatFaction", "TrollFaction", "WolfFaction"):
    body = re.sub(r"(?<![\w.])" + name + r"\b", "act." + name, body)
body = re.sub(r"(?<![\w.])DebugMode\(", "act.DebugMode(", body)
body = body.replace("act.act.", "act.")

# Hunterborn 2026: HiS's stats, skills and options live on its stats quest, which exists only once Hunting in Skyrim has been started (by Path of the
# Woodsman, or by Hunting in Skyrim 2026's automatic start). Before that every call below hit a None object and wrote an error per skinned animal.
old = "\tHISModOptionsScript HISModOptions = (HISStatsQuest1 as Quest) as HISModOptionsScript" + nl + "\tHISModOptions.HISRealisticSkinningEnabled.SetValue(0)"
assert body.count(old) == 1
body = body.replace(old, "\tIf !HISStatsQuest1 || !HISStatsQuest1.IsRunning()" + nl + "\t\tReturn" + nl + "\tEndIf" + nl + old)
old = "\t\tIf act.dsGlobals.gUseHiSCompatibility"
assert body.count(old) == 1
body = body.replace(old, "\t\tIf act.dsGlobals.gUseHiSCompatibility && HISStatsQuest1 && HISStatsQuest1.IsRunning()")

bridge = nl.join([
    "Scriptname _DS_HB_HiSBridge Hidden",
    "",
    "; Hunting in Skyrim compatibility, moved out of _DS_HB_Actions by Hunterborn 2026 so that Actions loads without HiS installed.",
    "; Code from Hunterborn SE MCM (Hazado), unchanged apart from the act. prefixes and the guards that skip the HiS stats until HiS has been started.",
    "",
    body,
    "",
])

wrappers = [
    "Function DisableHiSSkinning()",
    "\t_DS_HB_HiSBridge.DisableHiSSkinning()",
    "EndFunction",
    "",
    "Function SkinAnimalHIS(Actor akActorRef, MiscObject skin)",
    "\t_DS_HB_HiSBridge.SkinAnimalHIS(self, akActorRef, skin)",
    "EndFunction",
]
new = lines[:start] + wrappers + lines[end + 1:]

open(os.path.join(HERE, "src", "_DS_HB_HiSBridge.psc"), "w", encoding="utf-8", errors="surrogateescape", newline="").write(bridge)
open(os.path.join(HERE, "src", "_DS_HB_Actions.psc"), "w", encoding="utf-8", errors="surrogateescape", newline="").write(nl.join(new))
print("moved lines", start + 1, "-", end + 1, "->", len(block), "lines into the bridge")
for n in ("dsGlobals", "PlayerRef", "DebugMode"):
    print(n, "uses in bridge:", len(re.findall(r"act\." + n, bridge)))
