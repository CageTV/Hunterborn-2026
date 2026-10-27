"""Builds LICENSE.txt from Stress and Fear 2026's (same MIT + third-party notices), with Hunterborn's own header.

  python tools/make_license.py
"""
import os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(r"E:/WorkSpace/Stress-and-Fear-2026/LICENSE.txt", encoding="utf-8", newline="").read().replace(chr(13) + chr(10), chr(10))
lines = src.split(chr(10))
# the header paragraph ends at the first blank line after the "original mod, and this plugin only..." sentence
end = next(i for i, l in enumerate(lines) if l.startswith("original mod, and this plugin only"))
header = [
    "Hunterborn 2026",
    "Copyright (c) 2026 CageTV",
    "",
    "Released under the MIT License. Source code: https://github.com/CageTV/Hunterborn-2026",
    "",
    "This license covers the files written for this repository (HunterbornNative.dll, the settings pages, the Hunting in Skyrim bridge script and",
    "the changes made to the scripts below). It does not cover plugin/include/SKSEMenuFramework.h (the SKSE Menu Framework 3 project's SDK header,",
    "under that project's terms).",
    "",
    "CREDITS - the work this builds on, used with its authors' permission and credited here and on the download page",
    "  Hunterborn, by unuroboros. A REQUIREMENT, not part of this download: its meshes, textures, sounds and original plugin are not included.",
    "  Hunterborn SE MCM 1.6.8, by Hazado, who allows modification and redistribution with credit. Its plugin, Papyrus scripts, translations and",
    "    patches are included, modified as described in the README. The settings table of the SKSE pages was generated from its SkyUI menu.",
    "  Process Hotkey Fix, by Gasil, open permissions with credit. Folded into _DS_HB_Monsters and _DS_HB_mgef_Hotkey.",
    "  Hunting in Skyrim and Fishing in Skyrim, by Rich Webster, who has given permission to update them; only the bridge to Hunting in Skyrim's",
    "    own script types is written here.",
    "  The original authors keep their copyright in their work; it is redistributed under the permission they gave, and it is not re-licensed.",
    "",
    "The files written for this repository are released under the MIT License below, and the \"new\" HunterbornNative.dll is also under the GNU General",
    "Public License as described at the end of this file.",
]
body = lines[end + 1:]
text = chr(10).join(header + body)
open(os.path.join(HERE, "LICENSE.txt"), "w", encoding="utf-8", newline=chr(10)).write(text)
print("LICENSE.txt:", len(text), "chars")
