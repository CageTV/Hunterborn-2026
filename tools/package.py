"""Lays out the Hunterborn 2026 package (staging in package/, nothing outside the workspace is touched).

  package/Hunterborn 2026 - Installer(.zip)   FOMOD: always installs the core (SE MCM plugin, scripts, translations, core ESL, logo),
                                              then the DLL build (new / older) and the four optional patches

Needs plugin/build/release/HunterbornNative.dll (older, plugin/build.cmd), E:/WorkSpace/ng-build/build/release/out/HunterbornNative/HunterbornNative.dll
(new, ng-build/build.cmd HunterbornNative), build/*.pex (tools/build_scripts.py), package/Hunterborn2026.esp (tools/make_core.py) and the four patch plugins
from the Hunterborn 2026 Patches mod folder of the test list. No mesh, texture or sound of Hunterborn is packaged: the original mod is a requirement.

Usage: python tools/package.py [version]
"""
import os
import shutil
import sys
import xml.dom.minidom
import zipfile

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
OLD = os.path.join(HERE, "plugin", "build", "release", "HunterbornNative.dll")
NEW = r"E:\WorkSpace\ng-build\build\release\out\HunterbornNative\HunterbornNative.dll"
SEMCM = os.path.join(HERE, "reference", "semcm-mod")
PATCHES = r"H:\Modlists\Tabula\mods\Hunterborn 2026 Patches"
ANIM_BUILD = os.path.join(HERE, "patches", "Animations", "build")  # tools/build_animations_patch.py
ANIM_SRC = os.path.join(HERE, "patches", "Animations", "src")
ANIM_SCRIPTS = ["_DS_HB_Actions", "_DS_HB_MAIN", "_DS_HB_mgef_Forage", "_DS_HB_mgef_Hotkey", "_DS_HB_mgef_Track", "_GP_HB_AnimFunctions"]
VOLS = r"H:\Modlists\Tabula\mods\Immersive Hunting Animations PBR"  # the Vols cloak PBR textures (CageTV's PBR Conversion Hub, Nexus 175588)
PATCH_FILES = [
    ("Hunterborn - Campfire Patch.esp", "Campfire patch", "For Campfire. Adds Hunterborn's meats and pelts to Campfire's cooking and crafting."),
    ("Hunterborn - Leather Tanning.esp", "Leather tanning", "Adds tanning recipes for Hunterborn's pelts. Needs nothing else."),
    ("Hunterborn_CACO-SE_Patch.esp", "CACO patch", "For Complete Alchemy and Cooking Overhaul. Makes Hunterborn's foods and ingredients work with CACO."),
    ("Hunterborn - Soups and Stews.esp", "Soups and Stews", "Adds soups and stews, cooked from Hunterborn's meats. Large (7 MB, 30,000 records): install it only if you want it."),
]
CORE_ESL = os.path.join(HERE, "package", "Hunterborn2026.esp")
LOGO = os.path.join(HERE, "assets", "hunterborn_logo.png")
NAME = "Hunterborn 2026"
for p in [OLD, NEW, CORE_ESL, LOGO, VOLS] + [os.path.join(PATCHES, f) for f, _, _ in PATCH_FILES] + [os.path.join(ANIM_BUILD, n + ".pex") for n in ANIM_SCRIPTS]:
    assert os.path.exists(p), f"missing {p}"


def put(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)


dest = os.path.join(HERE, "package", NAME + " - Installer")
if os.path.exists(dest):
    shutil.rmtree(dest)

# core: SE MCM's files, then ours on top (build/ holds the five scripts changed here, src/ their sources)
core = os.path.join(dest, "core")
for sub in ("Scripts", "Interface"):
    shutil.copytree(os.path.join(SEMCM, sub), os.path.join(core, sub))
shutil.copytree(os.path.join(SEMCM, "Source"), os.path.join(core, "Source"))
put(os.path.join(SEMCM, "Hunterborn.esp"), os.path.join(core, "Hunterborn.esp"))
put(CORE_ESL, os.path.join(core, "Hunterborn2026.esp"))
put(LOGO, os.path.join(core, "Interface", "HunterbornNative", "hunterborn_logo.png"))
OURS = ["HunterbornNative", "_DS_HB_Animals", "_DS_HB_Actions", "_DS_HB_HiSBridge", "_DS_HB_MAIN", "_DS_HB_MCM", "_DS_HB_Monsters", "_DS_HB_QF_StartupHelper", "_DS_HB_mgef_Hotkey", "HIS_QF_HISHBSkinningQuest_0213F719"]
for n in OURS:
    put(os.path.join(HERE, "build", n + ".pex"), os.path.join(core, "Scripts", n + ".pex"))
    put(os.path.join(HERE, "src", n + ".psc"), os.path.join(core, "Source", "Scripts", n + ".psc"))
for n in os.listdir(os.path.join(core, "Source")):
    if n != "Scripts":
        raise SystemExit("unexpected Source layout: " + n)

put(NEW, os.path.join(dest, "new", "SKSE", "Plugins", "HunterbornNative.dll"))
put(OLD, os.path.join(dest, "older", "SKSE", "Plugins", "HunterbornNative.dll"))
for f, _, _ in PATCH_FILES:
    put(os.path.join(PATCHES, f), os.path.join(dest, "patches", f))
# optional: the Hunterborn - Animations integration (scripts only: none of its animations or meshes are packaged, it is a requirement)
for n in ANIM_SCRIPTS:
    put(os.path.join(ANIM_BUILD, n + ".pex"), os.path.join(dest, "animations", "Scripts", n + ".pex"))
    put(os.path.join(ANIM_SRC, n + ".psc"), os.path.join(dest, "animations", "Source", "Scripts", n + ".psc"))
# optional: the Vols cloak PBR textures (only the PBR files; the original cloak mesh and textures come from Hunterborn - Animations)
for sub in ("PBRNifPatcher", "textures"):
    shutil.copytree(os.path.join(VOLS, sub), os.path.join(dest, "volspbr", sub))
put(os.path.join(HERE, "docs", "README.txt"), os.path.join(dest, "README.txt"))
put(os.path.join(HERE, "LICENSE.txt"), os.path.join(dest, "LICENSE.txt"))

NEW_VER = "1.6.1170.0"
patch_plugins = "".join(
    f"""            <plugin name="{label}">
              <description>{desc}</description>
              <files><file source="patches\\{f}" destination="{f}"/></files>
              <typeDescriptor><type name="Optional"/></typeDescriptor>
            </plugin>
"""
    for f, label, desc in PATCH_FILES)
config = f"""<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
  <moduleName>{NAME}</moduleName>
  <requiredInstallFiles>
    <folder source="core" destination=""/>
    <file source="README.txt" destination="{NAME} README.txt"/>
    <file source="LICENSE.txt" destination="{NAME} LICENSE.txt"/>
  </requiredInstallFiles>
  <installSteps order="Explicit">
    <installStep name="Game version">
      <optionalFileGroups order="Explicit">
        <group name="HunterbornNative.dll" type="SelectExactlyOne">
          <plugins order="Explicit">
            <plugin name="New (Skyrim 1.6.1170 and newer)">
              <description>The new build. Works on Skyrim SE/AE 1.6.1170 and on every later version, including 1.7.x. Pre-selected when the installer sees 1.6.1170 or newer.</description>
              <files><folder source="new" destination=""/></files>
              <typeDescriptor><dependencyType><defaultType name="Optional"/><patterns>
                <pattern><dependencies><gameDependency version="{NEW_VER}"/></dependencies><type name="Recommended"/></pattern>
              </patterns></dependencyType></typeDescriptor>
            </plugin>
            <plugin name="Older (Skyrim VR and 1.6.1130 and older)">
              <description>The older build, for Skyrim VR and SE/AE 1.6.1130 and older. On 1.6.1170 either build works.</description>
              <files><folder source="older" destination=""/></files>
              <typeDescriptor><dependencyType><defaultType name="Optional"/><patterns>
                <pattern><dependencies><gameDependency version="{NEW_VER}"/></dependencies><type name="Optional"/></pattern>
              </patterns></dependencyType></typeDescriptor>
            </plugin>
          </plugins>
        </group>
      </optionalFileGroups>
    </installStep>
    <installStep name="Patches">
      <optionalFileGroups order="Explicit">
        <group name="Patches (install the ones for mods you use)" type="SelectAny">
          <plugins order="Explicit">
{patch_plugins}          </plugins>
        </group>
      </optionalFileGroups>
    </installStep>
    <installStep name="Animations and extras">
      <optionalFileGroups order="Explicit">
        <group name="Animations and extras" type="SelectAny">
          <plugins order="Explicit">
            <plugin name="Hunterborn Animations integration">
              <description>One click on a fresh kill kneels, field dresses, skins, harvests and butchers it with the animations of Hunterborn - Animations, then stands up. With a hunting knife it plays the dress cut and the stab-and-pull; with bare hands the claw dress and the harvest-fail pull. Sneak-click carries the animal, with a pose by size. Needs Hunterborn - Animations (Nexus 80677) installed first; none of its files are included. Set the click action on the Tweaks page.</description>
              <files><folder source="animations" destination=""/></files>
              <typeDescriptor><type name="Optional"/></typeDescriptor>
            </plugin>
            <plugin name="Vols Cloak PBR (Community Shaders only)">
              <description>PBR textures (with PGPatcher json files) for the Vols fur cloaks of Hunterborn - Animations / Immersive Hunting Animations: the cloak, black, brown, snow sabre and vale sabre variants. Needs Community Shaders and PGPatcher, and the cloak mesh and textures from Hunterborn - Animations. Conversions by CageTV (Nexus 175588) of the original textures, with credit to their authors.</description>
              <files><folder source="volspbr" destination=""/></files>
              <typeDescriptor><type name="Optional"/></typeDescriptor>
            </plugin>
          </plugins>
        </group>
      </optionalFileGroups>
    </installStep>
  </installSteps>
</config>
"""
info = (f"<fomod>\n  <Name>{NAME}</Name>\n  <Author>CageTV (Hunterborn by unuroboros, Hunterborn SE MCM by Hazado, Process Hotkey Fix by Gasil)</Author>\n"
        f"  <Version>{VERSION}</Version>\n  <Website>https://github.com/CageTV/Hunterborn-2026</Website>\n"
        "  <Description>Hunterborn SE MCM with its menu in SKSE Menu Framework, a native plugin that applies the settings, and fixes. Replaces Hunterborn SE MCM and the Process Hotkey Fix.</Description>\n</fomod>\n")
xml.dom.minidom.parseString(config)
xml.dom.minidom.parseString(info)
os.makedirs(os.path.join(dest, "fomod"), exist_ok=True)
open(os.path.join(dest, "fomod", "ModuleConfig.xml"), "w", encoding="utf-8", newline=chr(10)).write(config)
open(os.path.join(dest, "fomod", "info.xml"), "w", encoding="utf-8", newline=chr(10)).write(info)
zpath = dest + ".zip"
if os.path.exists(zpath):
    os.remove(zpath)
with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
    for dp, _, fs in os.walk(dest):
        for fn in fs:
            p = os.path.join(dp, fn)
            z.write(p, os.path.relpath(p, dest))
    names = z.namelist()
print(f"{zpath}: {len(names)} entries, {os.path.getsize(zpath)//1024} KB")
for n in sorted(names):
    print("  ", n)
