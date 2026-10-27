"""Slims the SkyUI menu: one page that points to the SKSE Menu Framework and lists the detected mods.

The SKSE pages (HunterbornNative.dll) now hold every setting. The SkyUI script cannot be dropped - it owns the hotkey events and
the on-close work - so only its pages change: OnConfigInit registers a single page, OnPageReset draws it, and OnVersionUpdate no
longer re-draws pages that do not exist.

  python tools/make_slim_mcm.py      reference/semcm/_DS_HB_MCM.psc -> src/_DS_HB_MCM.psc
"""
import os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
text = open(os.path.join(HERE, "reference", "semcm", "_DS_HB_MCM.psc"), encoding="utf-8", errors="surrogateescape", newline="").read()
nl = "\r\n" if "\r\n" in text else "\n"
text = text.replace("\r\n", "\n")


def swap(old, new, count=1):
    global text
    assert text.count(old) == count, (old[:60], text.count(old))
    text = text.replace(old, new)


swap("Return 168", "Return 169")

swap('''	Pages = new string[8]
	Pages[0] = "$_DS_HB_Page0"
	Pages[1] = "$_DS_HB_Page1"
	Pages[2] = "$_DS_HB_Page2"
	Pages[3] = "$_DS_HB_Page3"
	Pages[4] = "$_DS_HB_Page4"
	Pages[5] = "$_DS_HB_Page5"
	Pages[6] = "$_DS_HB_Page6"
  Pages[7] = "$_DS_HB_Page7"
''', '''	Pages = new string[1]
	Pages[0] = "Hunterborn"
''')

import re
T = chr(9)
pat = re.compile(T + T + r"If \(dsGlobals\.gHunterbornActive\)\n" + T + T + T + r"OnConfigInit\(\).*?dsMain\.DoInitStuff\(\)\n" + T + T + r"EndIf\n", re.S)
assert len(pat.findall(text)) == 1
repl = (T + T + "; Hunterborn 2026: the pages are now the single one set in OnConfigInit, which an older save still holds as eight.\n"
        + T + T + "OnConfigInit()\n" + T + T + "If (dsGlobals.gHunterbornActive)\n" + T + T + T + "dsMain.DoInitStuff()\n" + T + T + "EndIf\n")
text = pat.sub(lambda m: repl, text)


swap('''	Else
		UnloadCustomContent()
	EndIf

	int disableFlag
''', '''	Else
		UnloadCustomContent()
	EndIf

	; Hunterborn 2026: every setting is in the SKSE Menu Framework now; this page only points there.
	If (a_page == Pages[0])
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("Hunterborn 2026")
		AddTextOption("Version", GetHBVersion(), OPTION_FLAG_DISABLED)
		AddEmptyOption()
		AddHeaderOption("Settings have moved")
		AddTextOption("Open the SKSE Menu Framework", "", OPTION_FLAG_DISABLED)
		AddTextOption("and choose Hunterborn.", "", OPTION_FLAG_DISABLED)
		AddEmptyOption()
		If (dsGlobals.gHunterbornActive)
			AddTextOption("Hunterborn", "running", OPTION_FLAG_DISABLED)
		Else
			AddTextOption("Hunterborn", "not running", OPTION_FLAG_DISABLED)
		EndIf

		SetCursorPosition(1)
		AddHeaderOption("Detected in your load order")
		AddDetected("Soups and Stews", "Hunterborn - Soups and Stews.esp")
		AddDetected("Leather Tanning", "Hunterborn - Leather Tanning.esp")
		AddDetected("Campfire", "Campfire.esm")
		AddDetected("Campfire patch", "Hunterborn - Campfire Patch.esp")
		AddDetected("Frostfall", "Frostfall.esp")
		AddDetected("Last Seed", "LastSeed.esp")
		AddDetected("Last Seed patch", "Hunterborn - LastSeed Patch SE.esp")
		AddDetected("CACO", "complete alchemy & cooking overhaul.esp")
		AddDetected("CACO patch", "Hunterborn_CACO-SE_Patch.esp")
		AddDetected("Simple Hunting Overhaul", "Simple Hunting Overhaul.esp")
		AddDetected("Skills of the Wild", "SkillsOfTheWild.esp")
		AddDetected("Hunting in Skyrim", "Hunting in Skyrim.esp")
		AddDetected("Eating Animations patch", "EASHunterbornPatch.esp")
		AddDetected("Immersive Hunting Anims", "ImmersiveHunting.esp")
		If (Game.IsPluginInstalled("SimpleHunterborn.esp"))
			AddEmptyOption()
			AddHeaderOption("Simple Hunterborn is installed")
			AddTextOption("Not needed with Hunterborn 2026;", "", OPTION_FLAG_DISABLED)
			AddTextOption("it can conflict. Load", "", OPTION_FLAG_DISABLED)
			AddTextOption("Hunterborn2026.esp after it.", "", OPTION_FLAG_DISABLED)
		EndIf
		Return
	EndIf

	int disableFlag
''')

swap('''string Function GetHBVersion()
''', '''Function AddDetected(string asName, string asPlugin)
	If (Game.IsPluginInstalled(asPlugin))
		AddTextOption(asName, "installed", OPTION_FLAG_DISABLED)
	EndIf
EndFunction

string Function GetHBVersion()
''')

open(os.path.join(HERE, "src", "_DS_HB_MCM.psc"), "w", encoding="utf-8", errors="surrogateescape", newline="").write(text.replace("\n", nl))
print("written src/_DS_HB_MCM.psc")
