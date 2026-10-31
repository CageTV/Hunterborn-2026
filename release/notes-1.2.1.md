Hunterborn 2026 1.2.1. Install over 1.2.0. Needs the original Hunterborn (Nexus 7900), SkyUI, SKSE and SKSE Menu Framework 3.

New in 1.2.1:
- ESL edition: new installer step "Other mods (ESL edition)" with the files of ten other mods renumbered for the ESL Hunterborn.esp, one checkbox per mod: Hunterborn - Animations (and Primitive Cooking), Carry Your Carcasses (and CYC Animations), Immersive Carcass Carrying (IED profile and four Open Animation Replacer configs), Eating Animations and Sounds patch, Hunterborn Extender (Advanced Taxonomy), Last Seed 2026 patch, Skills of the Wild and CACO patch, SHO for Hunterborn, Bathing in Skyrim soaps patch, Hunterborn Descriptions (ini). Fixes a crash at start-up with the ESL edition when the Hunterborn Extender plugin (HunterbornAdvancedTaxonomy.esp) was installed, and the silent wrong overrides in the other plugins that point at Hunterborn.esp. Plugins, json and ini are all checked for stale record numbers (0 found).
- The installer shows the Hunterborn logo.
- tools/esl_thirdparty.py lists the files that must be renumbered with the plugin; tools/make_esl.py and tools/package.py use it, so the installer step is generated, not edited by hand.
- Regular edition: unchanged.
