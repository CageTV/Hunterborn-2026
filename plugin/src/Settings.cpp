/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "HunterbornIds.h"
#include "Actions.h"
#include "Notifications.h"
#include "Settings.h"

namespace Settings
{
	namespace
	{
		using namespace Actions;

		constexpr const char* kPlugin = "Hunterborn.esp";
		constexpr const char* kSoupsPlugin = "Hunterborn - Soups and Stews.esp";
		constexpr const char* kFile = "Data/SKSE/Plugins/HunterbornNative/settings.ini";
		constexpr float       kWriteDelay = 0.6f;

		// ---- the pages (generated) -----------------------------------------------------------------------------------------------------
#define HEADER(l) { nullptr, l, "", Kind::Slider, 0, 0, 0, 0, 0, "", nullptr, 0, 0, 0 }
#define TOG(id, l, tip, loc, d, aft) { id, l, tip, Kind::Toggle, loc, d, 0, 1, 1, "", nullptr, 0, aft, 0 }
#define SLD(id, l, tip, loc, d, mn, mx, st, f, aft) { id, l, tip, Kind::Slider, loc, d, mn, mx, st, f, nullptr, 0, aft, 0 }
#define CMB(id, l, tip, loc, d, opts, aft) { id, l, tip, Kind::Combo, loc, d, 0, 0, 1, "", opts, static_cast<int>(std::size(opts)), aft, 0 }
#define KEY(id, l, tip, loc, sl) { id, l, tip, Kind::Key, loc, 0, 0, 0, 0, "", nullptr, 0, 0, sl }
#include "Tables.inc"
#undef HEADER
#undef TOG
#undef SLD
#undef CMB
#undef KEY

#include "Globals.inc"

		// Settings of this plugin that are not Hunterborn globals (FormID 0): they live only in settings.ini.
		constexpr const char* kShoModeId = "hunt_mode";
		constexpr const char* kShoPlugin = "Simple Hunting Overhaul.esp";
		constexpr const char* kAnimalliModes[] = { "All creatures", "Lore friendly", "Lore friendly (stricter)" };
		constexpr const char* kHuntModes[] = { "Hunterborn's menus", "One click: kneel, dress, skin, harvest, butcher", "Simple Hunting Overhaul loot window" };

		constexpr Def kExtras[] = {
			{ nullptr, "Start", "", Kind::Slider, 0, 0, 0, 0, 0, "", nullptr, 0, 0, 0 },
			{ "auto_start", "Start Hunterborn automatically",
			  "On a new game Hunterborn waits until you click your first carcass and asks whether to start. With this on it starts by itself once the opening is over: "
			  "no prompt, no message, and the powers, perks and animals' loot lists are set up as if you had said yes. Only when it has never been started in this "
			  "game: if you stop Hunterborn yourself it stays stopped.",
			  Kind::Toggle, 0, 1, 0, 1, 1, "", nullptr, 0, 0, 0 },
			{ "start_logo", "Show the logo when Hunterborn starts",
			  "Shows the Hunterborn logo for a few seconds when Hunterborn starts (instead of any message), like Frostfall 2026 and Last Seed 2026 do. "
			  "Only when it starts: a game where it is already running shows nothing. Takes effect at once.",
			  Kind::Toggle, 0, 1, 0, 1, 1, "", nullptr, 0, 0, 0 },
			{ nullptr, "Hunting", "", Kind::Slider, 0, 0, 0, 0, 0, "", nullptr, 0, 0, 0 },
			{ kShoModeId, "How a click on a kill works",
			  "One click (recommended): a click on a fresh kill kneels, field dresses, skins, harvests and butchers it in one sequence (with Hunterborn Animations: "
			  "the kneel, the knife work and taking the parts), takes everything and passes the time. No menus and no loot window. Without a hunting knife you get "
			  "less, and better knives give better quality, as in Hunterborn. Sneak-clicking picks the carcass up to carry it.\n"
			  "Hunterborn's menus: the original prompts (field dress, skin, harvest, butcher).\n"
			  "Simple Hunting Overhaul loot window: the click opens the loot window and Simple Hunting Overhaul skins when you take the pelt (needs Simple Hunting "
			  "Overhaul and Simple Hunterborn).\n"
			  "One click and the loot window set \"Click on fresh kill\" and \"Click fresh kill (sneaking)\" on every game load.",
			  Kind::Combo, 0, 1, 0, 0, 1, "", kHuntModes, 3, 0, 0 },
			{ nullptr, "Animallica", "", Kind::Slider, 0, 0, 0, 0, 0, "", nullptr, 0, 0, 0 },
			{ "animallica_lore", "Animallica creatures",
			  "Animallica fills Skyrim's animal spawn lists with creatures that do not belong in Tamriel: tigers, lions, hyenas, rhinos, pandas and others. The two lore editions of "
			  "Animallica remove some of them from the plugin; this does the same at run time on the plugin you have installed, so you do not need either lore edition.\n"
			  "All: every Animallica creature spawns.\n"
			  "Lore friendly: the creatures the Lore Friendly edition removes are taken out of every spawn list.\n"
			  "Lore friendly (stricter): the creatures the Lore Edition Redux removes (it also drops tigers, sabertooths and the exotic pheasants).\n"
			  "Takes effect at the next game load. Animals already placed in the world by earlier play stay as they are. Needs Animallica.esp.",
			  Kind::Combo, 0, 0, 0, 0, 1, "", kAnimalliModes, 3, 0, 0 },
			{ nullptr, "Messages", "", Kind::Slider, 0, 0, 0, 0, 0, "", nullptr, 0, 0, 0 },
			{ "messages_as_notifications", "Show informational messages as notifications",
			  "Hunterborn shows some purely informational messages (a broken knife, a level-up, a failed skinning ...) as pop-up boxes that stop the game until you click them. "
			  "This turns those into on-screen notifications instead, like the community patch \"Hunterborn - Messages to Notifications\" (do not use both). "
			  "Messages that ask you to choose are left alone. Takes effect at once and needs no restart.",
			  Kind::Toggle, 0, 0, 0, 1, 1, "", nullptr, 0, 0, 0 },
		};
		constexpr Page kExtraPage = { "Extras", kExtras, static_cast<int>(std::size(kExtras)) };
		constexpr const char* kNotifyId = "messages_as_notifications";

		std::map<std::string, float> file;  // settings.ini as read, plus what has been written since
		std::mutex                   mu;
		std::atomic<bool>            applyOnLoad{ true };
		bool                         dirty = false;
		float                        timer = -1.0f;
		bool                         fileRead = false;

		RE::TESGlobal* Lookup(unsigned a_local)
		{
			auto* dh = RE::TESDataHandler::GetSingleton();
			return dh ? dh->LookupForm<RE::TESGlobal>(HbIds::Fix(kPlugin, a_local), kPlugin) : nullptr;
		}

		RE::TESGlobal* Glob(const Def& a_d) { return a_d.local ? Lookup(a_d.local) : nullptr; }

		// Simple Hunting Overhaul runs the hunt: a click on a fresh kill opens the loot window (Hunterborn's "Manual loot"), whatever settings.ini
		// or the old menu said. The caller holds mu and has read the file.
		void EnforceShoMode()
		{
			const auto it = file.find(kShoModeId);
			auto*      dh = RE::TESDataHandler::GetSingleton();
			const int  mode = it != file.end() ? static_cast<int>(it->second + 0.5f) : 1;
			if (mode == 0 || !dh) {
				return;
			}
			if (mode == 2 && !dh->LookupModByName(kShoPlugin)) {
				return;
			}
			constexpr unsigned kFresh = 0x0038ca, kFreshSneak = 0x0038cb, kClean = 0x0256a2, kCleanSneak = 0x0256a3, kRemoveManualLoot = 0x0355bd;
			if (auto* g = Lookup(kFresh)) {
				g->value = mode == 2 ? 3.0f : 4.0f;  // 3 manual loot (the loot window); 4 field dress and process in one go
			}
			if (auto* g = Lookup(kFreshSneak)) {
				g->value = 1.0f;  // sneaking: pick the carcass up (the carry display)
			}
			if (mode == 1) {
				if (auto* g = Lookup(kClean)) {
					g->value = 1.0f;  // an already dressed kill: process it (skin, harvest, butcher)
				}
				if (auto* g = Lookup(kCleanSneak)) {
					g->value = 1.0f;
				}
			}
			if (auto* g = Lookup(kRemoveManualLoot)) {
				g->value = 0.0f;
			}
			SKSE::log::info("Hunting mode {}: {}", mode, kHuntModes[std::clamp(mode, 0, 2)]);
		}

		// Callers hold mu.
		void ReadFile()
		{
			if (fileRead) {
				return;
			}
			fileRead = true;
			std::ifstream in(kFile);
			std::string   line;
			while (std::getline(in, line)) {
				if (line.empty() || line[0] == '#' || line[0] == ';') {
					continue;
				}
				const auto eq = line.find('=');
				if (eq == std::string::npos) {
					continue;
				}
				std::string key = line.substr(0, eq);
				std::string val = line.substr(eq + 1);
				while (!val.empty() && (val.back() == '\r' || val.back() == ' ')) {
					val.pop_back();
				}
				if (key == "apply_on_load") {
					applyOnLoad = val != "0";
				} else {
					file[key] = std::strtof(val.c_str(), nullptr);
				}
			}
		}

		void WriteFile()
		{
			std::error_code ec;
			std::filesystem::create_directories(std::filesystem::path(kFile).parent_path(), ec);
			std::ofstream out(kFile, std::ios::trunc);
			if (!out) {
				SKSE::log::warn("Cannot write {}", kFile);
				return;
			}
			out << "# Hunterborn 2026 settings. Edited by the SKSE Menu Framework pages; applied to the game on every load\n";
			out << "# while apply_on_load=1. Delete a line to let the game's current value take its place on the next load.\n";
			out << "apply_on_load=" << (applyOnLoad ? 1 : 0) << "\n";
			for (const auto& [k, v] : file) {
				char buf[48];
				std::snprintf(buf, sizeof(buf), "%g", static_cast<double>(v));
				out << k << "=" << buf << "\n";
			}
			SKSE::log::info("Wrote {} ({} settings)", kFile, file.size());
		}

		void Touch()
		{
			dirty = true;
			timer = kWriteDelay;
		}

		float Clamp(const Def& a_d, float a_v)
		{
			if (a_d.kind == Kind::Slider) {
				if (a_d.step > 0.0f) {
					a_v = a_d.min + std::round((a_v - a_d.min) / a_d.step) * a_d.step;
				}
				return std::clamp(a_v, a_d.min, a_d.max);
			}
			if (a_d.kind == Kind::Combo) {
				return std::clamp(a_v, 0.0f, static_cast<float>(std::max(a_d.optionCount - 1, 0)));
			}
			if (a_d.kind == Kind::Toggle) {
				return a_v > 0.5f ? 1.0f : 0.0f;
			}
			return a_v;
		}

		float Current(const Def& a_d)
		{
			if (!a_d.local) {  // a setting that lives only in settings.ini
				const auto it = a_d.id ? file.find(a_d.id) : file.end();
				return it != file.end() ? it->second : a_d.def;
			}
			auto* g = Glob(a_d);
			return g ? g->value : a_d.def;
		}

		// Writes one setting to the game (not to the file). Returns true when the value changed.
		bool Apply(const Def& a_d, float a_v)
		{
			const float before = Current(a_d);
			if (!a_d.local) {
				file[a_d.id] = a_v;
				if (std::string_view(a_d.id) == kNotifyId) {
					Notifications::Apply(a_v > 0.5f);
				} else if (std::string_view(a_d.id) == kShoModeId) {
					EnforceShoMode();
				}
				return std::abs(before - a_v) > 1e-6f;
			}
			// Soups and Stews crafting needs its own plugin: the MCM checks for its token and refuses the switch otherwise.
			if (a_d.id && std::string_view(a_d.id) == "gEnableSoupsStews" && a_v > 0.5f) {
				auto* dh = RE::TESDataHandler::GetSingleton();
				if (!dh || !dh->LookupModByName(kSoupsPlugin)) {
					Notify("Hunterborn - Soups and Stews.esp is not active: Soups and Stews stays off.");
					a_v = 0.0f;
				}
			}
			if (auto* g = Glob(a_d)) {
				g->value = a_v;
			}
			if (std::abs(before - a_v) > 1e-6f) {
				if (a_d.kind == Kind::Key) {
					Actions::RebindKey(static_cast<int>(before), static_cast<int>(a_v));
				}
				Actions::Queue(a_d.after);
				return true;
			}
			return false;
		}

		template <class F>
		void ForEachDef(F&& a_f)
		{
			for (int p = 0; p < kPageTotal; ++p) {
				for (int i = 0; i < kPages[p].count; ++i) {
					a_f(kPages[p].defs[i]);
				}
			}
			for (int i = 0; i < kExtraPage.count; ++i) {
				a_f(kExtraPage.defs[i]);
			}
		}
	}

	int         PageCount() { return kPageTotal + 1; }  // the generated pages, then Extras
	const Page& PageAt(int a_index) { return a_index >= kPageTotal ? kExtraPage : kPages[std::clamp(a_index, 0, kPageTotal - 1)]; }
	bool        IsHeader(const Def& a_d) { return a_d.id == nullptr; }

	bool Loaded()
	{
		auto* dh = RE::TESDataHandler::GetSingleton();
		return dh && dh->LookupModByName(kPlugin);
	}

	const Def* Find(std::string_view a_id)
	{
		const Def* found = nullptr;
		ForEachDef([&](const Def& d) {
			if (!found && d.id && a_id == d.id) {
				found = &d;
			}
		});
		return found;
	}

	bool Available(const Def& a_d) { return a_d.id && (a_d.local == 0 || Glob(a_d) != nullptr); }

	void OnDataLoaded()
	{
		// The message records exist now: apply the saved "messages as notifications" choice before the game starts.
		std::lock_guard lock(mu);
		ReadFile();
		const auto it = file.find(kNotifyId);
		if (it != file.end() && it->second > 0.5f) {
			Notifications::Apply(true);
		}
	}

	float Get(const Def& a_d)
	{
		std::lock_guard lock(mu);
		return Current(a_d);
	}

	void Set(const Def& a_d, float a_value)
	{
		a_value = Clamp(a_d, a_value);
		std::lock_guard lock(mu);
		ReadFile();
		Apply(a_d, a_value);
		if (a_d.id) {
			file[a_d.id] = Current(a_d);
			Touch();
		}
	}

	int  KeyOf(const Def& a_d) { return static_cast<int>(Get(a_d)); }
	void SetKey(const Def& a_d, int a_key) { Set(a_d, static_cast<float>(a_key)); }

	float GetByName(std::string_view a_name)
	{
		for (const auto& g : kGlobals) {
			if (a_name == g.name) {
				auto* gl = Lookup(g.id);
				return gl ? gl->value : std::numeric_limits<float>::quiet_NaN();
			}
		}
		return std::numeric_limits<float>::quiet_NaN();
	}

	bool SetByName(std::string_view a_name, float a_value)
	{
		for (const auto& g : kGlobals) {
			if (a_name == g.name) {
				if (auto* gl = Lookup(g.id)) {
					gl->value = a_value;
					return true;
				}
				return false;
			}
		}
		return false;
	}

	bool ApplyOnLoad() { return applyOnLoad.load(); }

	void SetApplyOnLoad(bool a_on)
	{
		std::lock_guard lock(mu);
		ReadFile();
		applyOnLoad = a_on;
		Touch();
	}

	void OnGameLoaded()
	{
		std::lock_guard lock(mu);
		ReadFile();
		int applied = 0, adopted = 0;
		ForEachDef([&](const Def& d) {
			if (!d.id || !Available(d)) {
				return;
			}
			const auto it = file.find(d.id);
			if (it == file.end()) {
				file[d.id] = Current(d);  // first time: keep what the game has, so nothing resets
				++adopted;
				dirty = true;
			} else if (applyOnLoad) {
				if (Apply(d, Clamp(d, it->second))) {
					++applied;
				}
			}
		});
		EnforceShoMode();
		if (dirty) {
			timer = kWriteDelay;
		}
		SKSE::log::info("Game loaded: {} setting(s) applied from settings.ini, {} adopted from the game", applied, adopted);
	}

	void SaveNow()
	{
		std::lock_guard lock(mu);
		ReadFile();
		ForEachDef([&](const Def& d) {
			if (d.id && Available(d)) {
				file[d.id] = Current(d);
			}
		});
		WriteFile();
		dirty = false;
		timer = -1.0f;
	}

	void LoadNow()
	{
		std::lock_guard lock(mu);
		fileRead = false;
		file.clear();
		ReadFile();
		ForEachDef([&](const Def& d) {
			if (d.id && Available(d)) {
				const auto it = file.find(d.id);
				if (it != file.end()) {
					Apply(d, Clamp(d, it->second));
				}
			}
		});
	}

	void ResetDefaults()
	{
		std::lock_guard lock(mu);
		ReadFile();
		ForEachDef([&](const Def& d) {
			if (d.id && Available(d) && d.kind != Kind::Key) {  // hotkeys are your own choice; they stay
				Apply(d, d.def);
				file[d.id] = d.def;
			}
		});
		Touch();
	}

	void Tick(float a_dt)
	{
		if (timer < 0.0f) {
			return;
		}
		timer -= a_dt;
		if (timer <= 0.0f) {
			std::lock_guard lock(mu);
			timer = -1.0f;
			if (dirty) {
				WriteFile();
				dirty = false;
			}
		}
	}

	const char* FilePath() { return kFile; }
}
