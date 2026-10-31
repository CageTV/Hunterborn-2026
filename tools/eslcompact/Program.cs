// EslCompact: renumber a plugin's own records into the light (ESL) range and repoint other plugins at them.
//   EslCompact compact <in.esp> <out.esp> <map.tsv>
//   EslCompact repoint <in.esp> <out.esp> <map.tsv> <TargetPlugin.esp>
// The light range with header 1.71 is 0x000-0xFFF (4096 records). New ids are handed out in order of the old ids: 0x800..0xFFF first, then 0x000..
using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Binary.Parameters;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Plugins.Records.Internals;
using Mutagen.Bethesda.Skyrim;

static class P
{
    static uint NewId(int n) => n < 0x800 ? (uint)(0x800 + n) : (uint)(n - 0x800);

    static int Main(string[] a)
    {
        if (a.Length < 4) { Console.Error.WriteLine("usage: compact in out map | repoint in out map target"); return 2; }
        var rel = SkyrimRelease.SkyrimSE;
        var inPath = a[1]; var outPath = a[2]; var mapPath = a[3];
        var mod = SkyrimMod.CreateFromBinary(inPath, rel);
        var masterOrder = mod.ModHeader.MasterReferences.Select(m => m.Master).ToList();  // keep the plugin's own master order
        BinaryWriteParameters WriteParams() => new BinaryWriteParameters { ModKey = ModKeyOption.CorrectToPath, MastersListOrdering = new MastersListOrderingByLoadOrder(masterOrder), MastersListContent = MastersListContentOption.NoCheck };
        if (a[0] == "compact")
        {
            var self = mod.ModKey;
            var recs = mod.EnumerateMajorRecords().Where(r => r.FormKey.ModKey == self).OrderBy(r => r.FormKey.ID).ToList();
            if (recs.Count > 4096) { Console.Error.WriteLine($"{recs.Count} records do not fit the 4096 light range"); return 3; }
            var map = new Dictionary<FormKey, FormKey>();
            int n = 0;
            foreach (var r in recs) map[r.FormKey] = new FormKey(self, NewId(n++));
            mod.RemapLinks(map);
            foreach (var r in recs) ((IMajorRecordInternal)r).FormKey = map[r.FormKey];
            mod.ModHeader.Flags |= SkyrimModHeader.HeaderFlag.Small;
            mod.ModHeader.Stats.Version = 1.71f;
            mod.ModHeader.Stats.NextFormID = (uint)(recs.Count >= 0x800 ? recs.Count - 0x800 + 1 : 0x800 + recs.Count);
            mod.WriteToBinary(outPath, WriteParams());
            File.WriteAllLines(mapPath, map.Select(kv => $"{kv.Key.ID:X6}\t{kv.Value.ID:X6}"));
            Console.WriteLine($"compacted {recs.Count} records of {self}; map -> {mapPath}");
            return 0;
        }
        if (a[0] == "verify")
        {
            // verify <orig.esp> <new.esp> <map.tsv>: same records (type, editor id) at the mapped ids, no reference to a missing own record
            var orig = SkyrimMod.CreateFromBinary(a[1], rel);
            var neu = SkyrimMod.CreateFromBinary(a[2], rel);
            var ids = File.ReadAllLines(mapPath).Select(l => l.Split('	')).ToDictionary(p => Convert.ToUInt32(p[0], 16), p => Convert.ToUInt32(p[1], 16));
            var newRecs = neu.EnumerateMajorRecords().Where(r => r.FormKey.ModKey == neu.ModKey).ToDictionary(r => r.FormKey.ID, r => r);
            int bad = 0, ok = 0;
            foreach (var r in orig.EnumerateMajorRecords().Where(r => r.FormKey.ModKey == orig.ModKey))
            {
                if (!ids.TryGetValue(r.FormKey.ID, out var nid) || !newRecs.TryGetValue(nid, out var nr) || nr.GetType() != r.GetType() || nr.EditorID != r.EditorID) { bad++; if (bad < 10) Console.WriteLine($"MISMATCH {r.FormKey.ID:X6} {r.EditorID}"); }
                else ok++;
            }
            int dangling = 0, links = 0;
            foreach (var l in neu.EnumerateFormLinks())
            {
                links++;
                if (l.FormKey.ModKey == neu.ModKey && !l.FormKey.IsNull && !newRecs.ContainsKey(l.FormKey.ID)) { dangling++; if (dangling < 10) Console.WriteLine($"DANGLING {l.FormKey}"); }
            }
            // script properties (VMAD) are references too: all must follow the renumbering
            int props = 0, staleProps = 0;
            void CheckScripts(IEnumerable<IScriptEntryGetter> scripts)
            {
                foreach (var sc in scripts)
                    foreach (var pr in sc.Properties.OfType<IScriptObjectPropertyGetter>())
                    {
                        var fk = pr.Object.FormKey;
                        if (fk.IsNull || fk.ModKey != neu.ModKey) continue;
                        props++;
                        if (!newRecs.ContainsKey(fk.ID)) { staleProps++; if (staleProps < 6) Console.WriteLine($"STALE PROPERTY {sc.Name}.{pr.Name} -> {fk}"); }
                    }
            }
            foreach (var r in neu.EnumerateMajorRecords())
            {
                if (r is IScriptedGetter sg && sg.VirtualMachineAdapter != null) CheckScripts(sg.VirtualMachineAdapter.Scripts);
                if (r is IQuestGetter q && q.VirtualMachineAdapter != null) foreach (var al in q.VirtualMachineAdapter.Aliases) CheckScripts(al.Scripts);
            }
            Console.WriteLine($"script object properties pointing into the plugin: {props}, stale {staleProps}");
            dangling += staleProps;
            Console.WriteLine($"records ok {ok}, mismatched {bad}; links {links}, dangling to own plugin {dangling}; masters {string.Join(",", neu.ModHeader.MasterReferences.Select(m => m.Master.FileName))}");
            return bad == 0 && dangling == 0 ? 0 : 4;
        }
        if (a[0] == "check")
        {
            // check <plugin.esp> <unused> <map.tsv> <TargetPlugin.esp>: every reference to the target plugin must use one of the new ids
            var target = ModKey.FromNameAndExtension(a[4]);
            var good = new HashSet<uint>(File.ReadAllLines(mapPath).Select(l => Convert.ToUInt32(l.Split('	')[1], 16)));
            int refs = 0, bad = 0;
            foreach (var l in mod.EnumerateFormLinks().Where(l => l.FormKey.ModKey == target && !l.FormKey.IsNull))
            {
                refs++;
                if (!good.Contains(l.FormKey.ID)) { bad++; if (bad < 6) Console.WriteLine($"  stale reference {l.FormKey}"); }
            }
            foreach (var r in mod.EnumerateMajorRecords().Where(r => r.FormKey.ModKey == target))
                if (!good.Contains(r.FormKey.ID)) { bad++; if (bad < 6) Console.WriteLine($"  stale override {r.FormKey}"); }
            Console.WriteLine($"{Path.GetFileName(inPath)}: {refs} references to {target}, {bad} stale");
            return bad == 0 ? 0 : 5;
        }
        if (a[0] == "repoint")
        {
            var target = ModKey.FromNameAndExtension(a[4]);
            var map = new Dictionary<FormKey, FormKey>();
            foreach (var line in File.ReadAllLines(mapPath))
            {
                var p = line.Split('\t');
                map[new FormKey(target, Convert.ToUInt32(p[0], 16))] = new FormKey(target, Convert.ToUInt32(p[1], 16));
            }
            mod.RemapLinks(map);
            int over = 0;
            foreach (var r in mod.EnumerateMajorRecords().Where(r => r.FormKey.ModKey == target).ToList())
                if (map.TryGetValue(r.FormKey, out var nk)) { ((IMajorRecordInternal)r).FormKey = nk; over++; }
            mod.WriteToBinary(outPath, WriteParams());
            Console.WriteLine($"repointed {inPath}: {over} overriding records renumbered");
            return 0;
        }
        return 2;
    }
}
