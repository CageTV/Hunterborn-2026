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
    "This license covers the files written for this repository (HunterbornNative.dll and the settings pages). It does not cover plugin/include/",
    "SKSEMenuFramework.h (the SKSE Menu Framework 3 project's SDK header, under that project's terms).",
    "",
    "Hunterborn is by unuroboros and is a REQUIREMENT, not part of this download. Hunterborn SE MCM is by Hazado, who allows modification and",
    "redistribution with credit; the settings table and the Papyrus knowledge this plugin relies on were read from it. Nothing of Hunterborn's",
    "plugin, scripts, meshes, textures or sounds is included: this plugin only reads and changes Hunterborn's global variables and calls its own",
    "Papyrus functions while the game runs.",
]
body = lines[end + 1:]
text = chr(10).join(header + body)
open(os.path.join(HERE, "LICENSE.txt"), "w", encoding="utf-8", newline=chr(10)).write(text)
print("LICENSE.txt:", len(text), "chars")
