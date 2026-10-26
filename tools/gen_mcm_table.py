"""Turn Hunterborn SE MCM's _DS_HB_MCM.psc into a settings table (docs/mcm_table.json + docs/mcm_table.md).

  python tools/gen_mcm_table.py

For every option on every page: type, label, hint, the dsGlobals variable it edits, default, range / menu entries, and whether its
handlers do anything BEYOND setting that variable (a "side effect": toggling a spell or perk, applying a preset, starting Hunterborn...).
The SKSE Menu Framework pages are generated from this table; the side-effect options need hand-written native behaviour.
"""
import json
import os
import re
from collections import Counter

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(HERE, "reference", "semcm", "_DS_HB_MCM.psc")
TRANS = r"C:\Modlists\Tabula\mods\Hunterborn SE MCM\Interface\Translations\Hunterborn_ENGLISH.txt"

text = open(SRC, encoding="utf-8", errors="replace").read().replace("\r", "")
lines = text.split("\n")

# ---- translations ------------------------------------------------------------------------------------------------------------------
tr = {}
for l in open(TRANS, encoding="utf-16").read().replace("\r", "").split("\n"):
    if "\t" in l:
        k, v = l.split("\t", 1)
        tr[k.strip()] = v.strip()


def T(s):
    s = (s or "").strip().strip('"')
    return tr.get(s, s)


# ---- event bodies ------------------------------------------------------------------------------------------------------------------
def event_body(name):
    start = None
    for i, l in enumerate(lines):
        if re.match(r"\s*event\s+" + name + r"\b", l, re.I):
            start = i
            break
    if start is None:
        return []
    for j in range(start + 1, len(lines)):
        if re.match(r"\s*endevent\b", lines[j], re.I):
            return lines[start + 1:j]
    return []


def branches(body):
    """Split an if/elseIf chain on 'a_option == X' into {oid: [lines]}."""
    out, cur = {}, None
    for l in body:
        m = re.match(r"\s*(?:if|elseif)\s*\(\s*a_option\s*==\s*(\w+)\s*\)", l, re.I)
        if m:
            cur = m.group(1)
            out.setdefault(cur, [])
            continue
        if cur is not None:
            out[cur].append(l)
    return out


def clean(ls):
    keep = []
    for l in ls:
        s = l.strip()
        if not s or s.startswith(";") or re.match(r"(endif|else)\b", s, re.I):
            continue
        keep.append(s)
    return keep


NOISE = re.compile(r"^(Set(Toggle|Slider|Menu|Text|KeyMap|Input)OptionValue|SetOptionFlags|DebugMode|SetInfoText|ForcePageReset|int disableFlag|disableFlag\s*=|If \(|Else|EndIf)", re.I)


# ---- pages -------------------------------------------------------------------------------------------------------------------------
pages = {}
for l in lines:
    m = re.match(r"\s*Pages\[(\d+)\]\s*=\s*\"([^\"]+)\"", l)
    if m:
        pages[int(m.group(1))] = T(m.group(2))

# ---- OnPageReset: options in order, by page ----------------------------------------------------------------------------------------
ADD = re.compile(r"^\s*(?:(\w+)\s*=\s*)?Add(Toggle|Slider|Menu|KeyMap|Text|Header|Empty)Option\((.*)\)\s*$", re.I)


def split_args(s):
    args, depth, cur, q = [], 0, "", False
    for ch in s:
        if ch == '"':
            q = not q
        if not q:
            if ch in "([":
                depth += 1
            elif ch in ")]":
                depth -= 1
            elif ch == "," and depth == 0:
                args.append(cur.strip())
                cur = ""
                continue
        cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args


body = event_body("OnPageReset")
cur_page = None
options = []
for l in body:
    m = re.match(r"\s*(?:if|elseif)\s*\(\s*a_page\s*==\s*Pages\[(\d+)\]\s*\)", l, re.I)
    if m:
        cur_page = int(m.group(1))
        continue
    m = ADD.match(l)
    if m and cur_page is not None:
        oid, kind, rest = m.group(1), m.group(2).lower(), split_args(m.group(3))
        label = T(rest[0]) if rest else ""
        value = rest[1] if len(rest) > 1 else ""
        options.append({"page": cur_page, "page_name": pages.get(cur_page, str(cur_page)), "oid": oid, "type": kind,
                        "label_key": rest[0].strip('"') if rest else "", "label": label, "value_expr": value, "args": rest})

by_oid = {o["oid"]: o for o in options if o["oid"]}

# ---- global variable behind each option --------------------------------------------------------------------------------------------
G = re.compile(r"dsGlobals\.(\w+)")
for o in options:
    m = G.search(o["value_expr"] or "")
    o["global"] = m.group(1) if m else None

# ---- highlight (hint) ---------------------------------------------------------------------------------------------------------------
for oid, b in branches(event_body("OnOptionHighlight")).items():
    for l in b:
        m = re.search(r'SetInfoText\("([^"]+)"', l)
        if m and oid in by_oid:
            by_oid[oid]["hint"] = T(m.group(1))

# ---- defaults ------------------------------------------------------------------------------------------------------------------------
for oid, b in branches(event_body("OnOptionDefault")).items():
    for l in clean(b):
        m = re.match(r"dsGlobals\.(\w+)\s*=\s*(.+)$", l)
        if m and oid in by_oid:
            by_oid[oid]["default"] = m.group(2).strip()
            by_oid[oid]["default_global"] = m.group(1)

# ---- select (toggle) ----------------------------------------------------------------------------------------------------------------
sel_extra = {}
for oid, b in branches(event_body("OnOptionSelect")).items():
    c = clean(b)
    extra = [l for l in c if not NOISE.match(l) and not re.match(r"dsGlobals\.\w+\s*=\s*!dsGlobals\.\w+$", l)]
    if oid in by_oid:
        by_oid[oid]["select_side_effects"] = extra
        by_oid[oid]["select_lines"] = len(c)

# ---- sliders -------------------------------------------------------------------------------------------------------------------------
for oid, b in branches(event_body("OnOptionSliderOpen")).items():
    s = " ".join(b)
    d = by_oid.get(oid)
    if not d:
        continue
    m = re.search(r"SetSliderDialogDefaultValue\(([^)]+)\)", s)
    d["default"] = m.group(1).strip() if m else d.get("default")
    m = re.search(r"SetSliderDialogRange\(([^,]+),\s*([^)]+)\)", s)
    if m:
        d["min"], d["max"] = m.group(1).strip(), m.group(2).strip()
    m = re.search(r"SetSliderDialogInterval\(([^)]+)\)", s)
    d["step"] = m.group(1).strip() if m else None
    m = re.search(r"SetSliderDialogStartValue\(dsGlobals\.(\w+)\)", s)
    d["global"] = m.group(1) if m else d.get("global")
for oid, b in branches(event_body("OnOptionSliderAccept")).items():
    c = clean(b)
    fmt = None
    for l in c:
        m = re.search(r'SetSliderOptionValue\([^,]+,[^,]+,\s*"([^"]*)"', l)
        if m:
            fmt = m.group(1)
    if oid in by_oid:
        by_oid[oid]["format"] = fmt
        by_oid[oid]["accept_side_effects"] = [l for l in c if not NOISE.match(l) and not re.match(r"dsGlobals\.\w+\s*=", l)]

# ---- menus ----------------------------------------------------------------------------------------------------------------------------
arr = {}
for l in lines:
    m = re.match(r"\s*(\w+Strings)\s*=\s*new string\[(\d+)\]", l)
    if m:
        arr[m.group(1)] = {"n": int(m.group(2)), "items": {}}
    m = re.match(r"\s*(\w+Strings)\[(\d+)\]\s*=\s*\"([^\"]*)\"", l)
    if m and m.group(1) in arr:
        arr[m.group(1)]["items"][int(m.group(2))] = T(m.group(3))
for oid, b in branches(event_body("OnOptionMenuOpen")).items():
    s = "\n".join(b)
    d = by_oid.get(oid)
    if not d:
        continue
    m = re.search(r"SetMenuDialogOptions\((\w+)\)", s)
    if m:
        d["menu_array"] = m.group(1)
        a = arr.get(m.group(1))
        if a:
            d["menu_items"] = [a["items"].get(i, "") for i in range(a["n"])]
    m = re.search(r"SetMenuDialogStartIndex\(dsGlobals\.(\w+)\)", s)
    if m:
        d["global"] = m.group(1)
    m = re.search(r"SetMenuDialogDefaultIndex\((\d+)\)", s)
    if m:
        d["default"] = m.group(1)
for oid, b in branches(event_body("OnOptionMenuAccept")).items():
    c = clean(b)
    if oid in by_oid:
        by_oid[oid]["accept_side_effects"] = [l for l in c if not NOISE.match(l) and not re.match(r"dsGlobals\.\w+\s*=", l)]

# ---- keymaps -------------------------------------------------------------------------------------------------------------------------
kb = event_body("OnOptionKeyMapChange")
cur = None
for l in kb:
    m = re.match(r"\s*(?:if|elseif)\s*\(\s*a_option\s*==\s*(\w+)\s*\)", l, re.I)
    if m:
        cur = m.group(1)
        continue
    m = re.match(r"\s*dsGlobals\.(\w+)\s*=\s*a_keyCode", l)
    if m and cur in by_oid:
        by_oid[cur]["global"] = m.group(1)

# ---- summary ---------------------------------------------------------------------------------------------------------------------------
for o in options:
    o["side_effects"] = (o.get("select_side_effects") or []) + (o.get("accept_side_effects") or [])
interactive = [o for o in options if o["type"] in ("toggle", "slider", "menu", "keymap")]
plain = [o for o in interactive if not o["side_effects"] and o.get("global")]
special = [o for o in interactive if o["side_effects"] or not o.get("global")]

os.makedirs(os.path.join(HERE, "docs"), exist_ok=True)
json.dump({"pages": pages, "options": options}, open(os.path.join(HERE, "docs", "mcm_table.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)

md = ["# Hunterborn SE MCM settings table (generated by tools/gen_mcm_table.py)", "",
      f"pages: {len(pages)}; options: {len(options)} ({Counter(o['type'] for o in options)})",
      f"interactive options: {len(interactive)}; plain (only set one global): {len(plain)}; need special handling: {len(special)}", ""]
for p in sorted(pages):
    md.append(f"## Page {p}: {pages[p]}")
    for o in [x for x in options if x["page"] == p]:
        if o["type"] in ("empty",):
            continue
        extra = f"  **SIDE EFFECTS:** {' / '.join(o['side_effects'])[:160]}" if o["side_effects"] else ""
        rng = f" [{o.get('min')}..{o.get('max')} step {o.get('step')}]" if o["type"] == "slider" else ""
        mi = f" {o.get('menu_items')}" if o.get("menu_items") else ""
        md.append(f"- {o['type']:7s} {o['label'][:46]:46s} -> {o.get('global') or '(none)'}  default={o.get('default')}{rng}{mi}{extra}")
    md.append("")
open(os.path.join(HERE, "docs", "mcm_table.md"), "w", encoding="utf-8").write("\n".join(md))
print(f"pages {len(pages)}, options {len(options)} {dict(Counter(o['type'] for o in options))}")
print(f"interactive {len(interactive)}: plain {len(plain)}, special {len(special)}")
