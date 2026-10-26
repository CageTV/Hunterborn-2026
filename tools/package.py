"""Lays out the Hunterborn 2026 packages (staging in package/, nothing outside the workspace is touched).

  package/Hunterborn 2026                    the layer for a quick install: new HunterbornNative.dll + README + LICENSE
  package/Hunterborn 2026 - Installer(.zip)  FOMOD: pick the DLL build (new / older)

Needs plugin/build/release/HunterbornNative.dll (older, plugin/build.cmd) and E:/WorkSpace/ng-build/build/release/out/HunterbornNative/HunterbornNative.dll
(new, ng-build/build.cmd HunterbornNative). No script, mesh, texture or plugin of Hunterborn is packaged.

Usage: python tools/package.py [version]
"""
import os
import shutil
import sys
import xml.dom.minidom
import zipfile

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION = sys.argv[1] if len(sys.argv) > 1 else "0.1.0"
OLD = os.path.join(HERE, "plugin", "build", "release", "HunterbornNative.dll")
NEW = r"E:\WorkSpace\ng-build\build\release\out\HunterbornNative\HunterbornNative.dll"
for p in (OLD, NEW):
    assert os.path.exists(p), f"missing {p}"
NAME = "Hunterborn 2026"


def put(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)


quick = os.path.join(HERE, "package", NAME)
if os.path.exists(quick):
    shutil.rmtree(quick)
put(NEW, os.path.join(quick, "SKSE", "Plugins", "HunterbornNative.dll"))
put(os.path.join(HERE, "docs", "README.txt"), os.path.join(quick, NAME + " README.txt"))
put(os.path.join(HERE, "LICENSE.txt"), os.path.join(quick, NAME + " LICENSE.txt"))

dest = os.path.join(HERE, "package", NAME + " - Installer")
if os.path.exists(dest):
    shutil.rmtree(dest)
put(NEW, os.path.join(dest, "new", "SKSE", "Plugins", "HunterbornNative.dll"))
put(OLD, os.path.join(dest, "older", "SKSE", "Plugins", "HunterbornNative.dll"))
put(os.path.join(HERE, "docs", "README.txt"), os.path.join(dest, "README.txt"))
put(os.path.join(HERE, "LICENSE.txt"), os.path.join(dest, "LICENSE.txt"))
NEW_VER = "1.6.1170.0"
config = f"""<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
  <moduleName>{NAME}</moduleName>
  <requiredInstallFiles>
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
  </installSteps>
</config>
"""
info = (f"<fomod>\n  <Name>{NAME}</Name>\n  <Author>CageTV (Hunterborn by unuroboros, Hunterborn SE MCM by Hazado)</Author>\n  <Version>{VERSION}</Version>\n"
        "  <Website>https://github.com/CageTV/Hunterborn-2026</Website>\n"
        "  <Description>Hunterborn SE MCM's settings in SKSE Menu Framework, replacing the use of its SkyUI menu, with the same work done when the menu closes.</Description>\n</fomod>\n")
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
