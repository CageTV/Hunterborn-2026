"""Map every Hunterborn global (property name -> FormKey, EditorID, type, default) from the Spriggit export of SE MCM's Hunterborn.esp.

  python tools/gen_globals_map.py <spriggit-export-folder>      writes docs/globals_map.json

The SE MCM script _DS_HB_Globals exposes each setting as `gX` (a Hidden property with Get/Set) backed by a GlobalVariable property
(_DS_Hunterborn_*). This joins: gX -> backing property (from the .psc) -> FormKey (from the quest's script properties) -> GLOB record.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
exp = sys.argv[1]
psc = open(os.path.join(HERE, "reference", "semcm", "_DS_HB_Globals.psc"), encoding="utf-8", errors="replace").read().replace("\r", "")

# gX -> backing GlobalVariable property, access kind (int/float/bool) from the Get/Set bodies
g2back = {}
for m in re.finditer(r"^(bool|int|float)\s+Property\s+(g\w+)\s+Hidden\s*\n(.*?)^EndProperty", psc, re.M | re.S | re.I):
    typ, name, body = m.group(1).lower(), m.group(2), m.group(3)
    b = re.search(r"(\w+)\.Set(?:Value)?(Int)?\(", body)
    kind = "int" if (b and b.group(2)) else ("float" if typ == "float" else typ)
    if b:
        g2back[name] = {"type": typ, "backing": b.group(1), "set": "int" if b.group(2) else "float"}

# quest properties: backing property name -> FormKey (the _DS_HB_Globals script on quest 003367)
qdir = os.path.join(exp, "Quests")
qf = [f for f in os.listdir(qdir) if "_DS_Hunterborn - 003367" in f][0]
q = open(os.path.join(qdir, qf), encoding="utf-8").read().replace("\r", "")
i = q.index("Name: _DS_HB_Globals")
rest = q[i:]
j = rest.find("  - Name: ", 20)
block = rest if j < 0 else rest[:j]
props = {}
for m in re.finditer(r"Name:\s*(\S+)\s*\n\s*Object:\s*([0-9A-F]{6}):(\S+)", block):
    props[m.group(1)] = (m.group(2), m.group(3))

# GLOB records: FormKey -> editorid, type, value
glob = {}
gdir = os.path.join(exp, "Globals")
for f in os.listdir(gdir):
    t = open(os.path.join(gdir, f), encoding="utf-8").read().replace("\r", "")
    fk = re.search(r"^FormKey:\s*([0-9A-F]{6}):(\S+)", t, re.M)
    ed = re.search(r"^EditorID:\s*(\S+)", t, re.M)
    typ = re.search(r"^(Short|Long|Float)\b|MutagenObjectType:\s*(Global\w+)", t, re.M)
    val = re.search(r"^Data:\s*(\S+)", t, re.M)
    glob[fk.group(1)] = {"editor_id": ed.group(1) if ed else None, "record": re.search(r"^MutagenObjectType:\s*(\w+)", t, re.M).group(1) if re.search(r"^MutagenObjectType:\s*(\w+)", t, re.M) else None,
                         "data": val.group(1) if val else None, "file": f}

out = {}
missing = []
for g, info in g2back.items():
    p = props.get(info["backing"])
    if not p:
        missing.append(g)
        continue
    rec = glob.get(p[0], {})
    out[g] = {"backing": info["backing"], "formid": p[0], "plugin": p[1], "editor_id": rec.get("editor_id"), "record": rec.get("record"),
              "data": rec.get("data"), "type": info["type"], "set": info["set"]}
json.dump(out, open(os.path.join(HERE, "docs", "globals_map.json"), "w", encoding="utf-8"), indent=1)
print(f"gX properties: {len(g2back)}; mapped: {len(out)}; backing property not in quest VMAD: {len(missing)} {missing[:8]}")
print("records:", {k: sum(1 for v in out.values() if v['record'] == k) for k in set(v['record'] for v in out.values())})
print("sample:", list(out.items())[:3])
