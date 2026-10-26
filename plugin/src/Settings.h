/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// Every setting of Hunterborn 2026's pages. A setting is one global variable of Hunterborn SE MCM (the same ones its menu writes), so the pages
// and the mod always agree. The values are also kept in Data/SKSE/Plugins/HunterbornNative/settings.ini so they follow you to a new character
// and are applied again on every game load. The tables are generated from the MCM script (tools/gen_options.py).
namespace Settings
{
	enum class Kind { Toggle, Slider, Combo, Key };

	struct Def
	{
		const char*        id;     // key in settings.ini (the name of the setting in Hunterborn's own scripts: gDressTimed ...)
		const char*        label;
		const char*        tip;
		Kind               kind;
		unsigned int       local;  // FormID of the global in Hunterborn.esp
		float              def, min, max, step;
		const char*        fmt;    // slider display format (printf, one float)
		const char* const* options;
		int                optionCount;
		unsigned           after;  // Actions::Act flags queued when the value changes
		int                slot;   // hotkeys: slot number for the key capture
	};

	struct Page
	{
		const char* title;
		const Def*  defs;
		int         count;  // headers are defs with a null id
	};

	int         PageCount();
	const Page& PageAt(int a_index);
	bool        IsHeader(const Def& a_d);

	const Def* Find(std::string_view a_id);
	bool       Available(const Def& a_d);  // the global is there
	float      Get(const Def& a_d);
	void       Set(const Def& a_d, float a_value);  // writes the global, the file, and queues the menu-close work
	int        KeyOf(const Def& a_d);
	void       SetKey(const Def& a_d, int a_key);

	// Raw access to any Hunterborn global by its script name (gMonsterHunter, gSkinLevel ...). NaN when it does not exist.
	float GetByName(std::string_view a_name);
	bool  SetByName(std::string_view a_name, float a_value);
	bool  Loaded();  // Hunterborn.esp is in the load order

	// Game load / new game: applies settings.ini to the globals (or writes the file from the globals the first time).
	void OnGameLoaded();
	bool ApplyOnLoad();
	void SetApplyOnLoad(bool a_on);
	void SaveNow();  // write settings.ini from the current globals
	void LoadNow();  // apply settings.ini to the globals now
	void ResetDefaults();
	void Tick(float a_dt);  // flushes the file a moment after the last change
	const char* FilePath();
}
