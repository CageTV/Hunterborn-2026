/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "AutoPatch.h"

#include <set>

namespace AutoPatch
{
	namespace
	{
		constexpr unsigned kActorTypeAnimal = 0x013798;  // Skyrim.esm keyword every animal race carries

		struct Type
		{
			bool                     monster;
			int                      index;   // the position in Hunterborn's list (_DS_FL_DeathItems / _DS_FL_DeathItems_Monsters)
			const char*              plugin;  // the plugin that defines the vanilla loot list of this type
			unsigned                 local;
			const char*              name;
			std::vector<std::string> words;   // lower case; found in a creature's race or names
		};

		// Hunterborn's own types, in its own order (the first 28 are the animals, then the 9 monsters). The loot list is the one the vanilla animal of that type uses.
		const std::vector<Type>& Types()
		{
			static const std::vector<Type> t = {
				{ false, 0, "Skyrim.esm", 0x03AD77, "Bear", { "bear", "grizzly" } },
				{ false, 1, "Skyrim.esm", 0x03AD78, "BearCave", { "cavebear", "bearcave", "cave bear" } },
				{ false, 2, "Skyrim.esm", 0x03AD79, "BearSnow", { "snowbear", "bearsnow", "snow bear", "polarbear", "polar bear" } },
				{ false, 3, "Skyrim.esm", 0x106AEC, "Chicken", { "chicken", "rooster", "chick", "hen", "pheasant", "goose", "geese", "duck", "turkey", "quail", "grouse", "partridge" } },
				{ false, 4, "Skyrim.esm", 0x03AD7B, "Cow", { "cow", "calf", "cattle", "ox", "rhino" } },
				{ false, 5, "Skyrim.esm", 0x0D284C, "Deer", { "deer", "whitetail", "blacktail", "fawn", "stag", "reindeer", "caribou", "gazelle", "roe" } },
				{ false, 6, "Skyrim.esm", 0x03AD7D, "Dog", { "dog", "hound", "husky" } },
				{ false, 7, "Skyrim.esm", 0x10FF79, "ElkFemale", { "elkfemale", "femaleelk", "elk female", "female elk" } },
				{ false, 8, "Skyrim.esm", 0x03AD7C, "ElkMale", { "elk", "moose" } },
				{ false, 9, "Skyrim.esm", 0x1072C3, "Fox", { "fox", "raccoon", "coon" } },
				{ false, 10, "Skyrim.esm", 0x1072C4, "FoxIce", { "snowfox", "icefox", "foxsnow", "foxice", "snow fox", "ice fox" } },
				{ false, 11, "Skyrim.esm", 0x03AD8D, "Goat", { "goat", "sheep", "lamb", "ibex" } },
				{ false, 12, "Skyrim.esm", 0x09A772, "Hare", { "hare", "rabbit", "bunny" } },
				{ false, 13, "Skyrim.esm", 0x03AD92, "Horker", { "horker", "walrus" } },
				{ false, 14, "Skyrim.esm", 0x03AD94, "Horse", { "horse", "pony", "stallion", "donkey", "mule" } },
				{ false, 15, "Skyrim.esm", 0x03AD96, "Mammoth", { "mammoth", "elephant" } },
				{ false, 16, "Skyrim.esm", 0x1017B8, "MudCrab01", { "mudcrab", "crab" } },
				{ false, 17, "Skyrim.esm", 0x1017B9, "MudCrab02", { "largemudcrab", "mudcrablarge", "mudcrab02", "large mudcrab" } },
				{ false, 18, "Skyrim.esm", 0x1017BA, "MudCrab03", { "giantmudcrab", "mudcrabgiant", "mudcrabking", "crabking", "mudcrab03", "giant mudcrab" } },
				{ false, 19, "Skyrim.esm", 0x03AD97, "Sabrecat", { "sabrecat", "sabercat", "tiger", "lion", "panther", "lynx", "cougar", "leopard", "jaguar", "cheetah", "puma" } },
				{ false, 20, "Skyrim.esm", 0x03AD98, "SabrecatSnow", { "sabrecatsnow", "snowsabre", "snowysabre", "snowy sabre", "snow sabre" } },
				{ false, 21, "Skyrim.esm", 0x03AD99, "Skeever", { "skeever" } },
				{ false, 22, "Skyrim.esm", 0x03AD9A, "Slaughterfish", { "slaughterfish" } },
				{ false, 23, "Skyrim.esm", 0x03AD9E, "Wolf", { "wolf", "hyena", "jackal", "coyote" } },
				{ false, 24, "Skyrim.esm", 0x03AD9F, "WolfIce", { "icewolf", "wolfice", "snowwolf", "ice wolf", "snow wolf" } },
				{ false, 25, "Dawnguard.esm", 0x013E25, "DeerVale", { "deervale", "valedeer" } },
				{ false, 26, "Dawnguard.esm", 0x013E24, "SabrecatVale", { "sabrecatvale", "valesabre" } },
				{ false, 27, "Dragonborn.esm", 0x032C7B, "Bristleback", { "boar", "bristleback", "pig", "hog", "swine" } },
				{ true, 0, "Skyrim.esm", 0x03ADA1, "Chaurus", { "chaurus" } },
				{ true, 1, "Skyrim.esm", 0x03AD89, "Spider", { "frostbitespider", "spider" } },
				{ true, 2, "Skyrim.esm", 0x03AD8A, "SpiderGiant", { "giantspider", "spidergiant", "frostbitespidergiant", "giant spider" } },
				{ true, 3, "Skyrim.esm", 0x03AD9B, "Spriggan", { "spriggan" } },
				{ true, 4, "Skyrim.esm", 0x03AD9C, "Troll", { "troll" } },
				{ true, 5, "Skyrim.esm", 0x03ADA6, "TrollFrost", { "trollfrost", "frosttroll", "frost troll" } },
				{ true, 7, "Skyrim.esm", 0x03ADA5, "Dragon", { "dragon" } },
				{ true, 8, "Dawnguard.esm", 0x00D6F8, "ChaurusHunter", { "chaurushunter", "hunterchaurus" } },
			};
			return t;
		}

		// Creatures that are not for hunting: summons, pets, mounts, a transformation of the player ...
		const std::vector<std::string>& DefaultSkipWords()
		{
			static const std::vector<std::string> w = { "familiar", "summon", "companion", "mount", "battleform", "spebf", "spirit", "ghost", "undead", "zombie",
														"koi", "raven", "crow", "hatchling", "spiderling", "elytra", "follower", "puppet", "dummy", "test" };
			return w;
		}

		const std::vector<std::string>& DefaultSkipPlugins()
		{
			static const std::vector<std::string> p = { "ccvsvsse002-pets.esl", "ccbgssse035-petnhound.esl", "ccbgssse036-petbwolf.esl", "ccbgssse010-petdwarvenarmoredmudcrab.esl" };
			return p;
		}

		struct Rules
		{
			std::vector<std::pair<std::string, std::string>> map;  // word -> type name, as the user wrote them (lower case)
			std::vector<std::string>                         skip;
			std::vector<std::string>                         skipPlugins;
		};

		std::string Lower(std::string_view a_text)
		{
			std::string s(a_text);
			std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
			return s;
		}

		std::string Trim(std::string a_text)
		{
			const auto a = a_text.find_first_not_of(" \t\r\n");
			if (a == std::string::npos) {
				return {};
			}
			const auto b = a_text.find_last_not_of(" \t\r\n");
			return a_text.substr(a, b - a + 1);
		}

		Rules ReadRules()
		{
			Rules r;
			std::ifstream in("Data/SKSE/Plugins/HunterbornNative/autopatch.ini");
			if (!in) {
				return r;
			}
			std::string section, line;
			while (std::getline(in, line)) {
				line = Trim(line);
				if (line.empty() || line[0] == ';' || line[0] == '#') {
					continue;
				}
				if (line.front() == '[' && line.back() == ']') {
					section = Lower(line.substr(1, line.size() - 2));
					continue;
				}
				const auto eq = line.find('=');
				const auto key = Lower(Trim(eq == std::string::npos ? line : line.substr(0, eq)));
				const auto val = eq == std::string::npos ? std::string() : Trim(line.substr(eq + 1));
				if (key.empty()) {
					continue;
				}
				if (section == "map" && !val.empty()) {
					r.map.emplace_back(key, Lower(val));
				} else if (section == "skip") {
					r.skip.push_back(key);
				} else if (section == "skipplugins") {
					r.skipPlugins.push_back(key);
				}
			}
			return r;
		}

		bool Contains(const std::string& a_text, const std::string& a_word)
		{
			return !a_word.empty() && a_text.find(a_word) != std::string::npos;
		}

		const Type* FindTypeByName(const std::string& a_lowerName)
		{
			for (const auto& t : Types()) {
				if (Lower(t.name) == a_lowerName) {
					return &t;
				}
			}
			return nullptr;
		}

		struct Signature
		{
			std::set<RE::TESRace*>      races;
			std::set<std::string>       skeletons;
			std::set<RE::BGSVoiceType*> voices;
		};

		std::string Skeleton(const RE::TESRace* a_race)
		{
			if (!a_race) {
				return {};
			}
			const char* m = const_cast<RE::TESRace*>(a_race)->skeletonModels[RE::SEXES::kMale].GetModel();
			return m ? Lower(m) : std::string();
		}

		std::string FileOf(const RE::TESForm* a_form)
		{
			const auto* file = a_form ? a_form->GetFile(0) : nullptr;
			return file ? std::string(file->GetFilename()) : std::string("?");
		}

		struct Found
		{
			RE::TESNPC*  npc;
			const Type*  type;  // null = no type found
			std::string  reason;
			std::string  plugin;
			std::string  race;
		};
	}

	void OnDataLoaded()
	{
		auto* dh = RE::TESDataHandler::GetSingleton();
		if (!dh) {
			return;
		}
		const auto started = std::chrono::steady_clock::now();
		const auto rules = ReadRules();

		// The loot list of each type, and the creatures that already use it: these say what each type looks like in this game.
		std::map<const Type*, RE::TESLevItem*> lists;
		std::map<RE::TESLevItem*, const Type*> typeOfList;
		for (const auto& t : Types()) {
			if (auto* li = dh->LookupForm<RE::TESLevItem>(t.local, t.plugin)) {
				lists[&t] = li;
				typeOfList[li] = &t;
			}
		}
		if (lists.size() < 20) {
			SKSE::log::warn("AutoPatch: only {} of {} Hunterborn type loot lists were found; no report written", lists.size(), Types().size());
			return;
		}

		const auto& npcs = dh->GetFormArray<RE::TESNPC>();
		std::map<const Type*, Signature> sig;
		std::map<const Type*, int>        handledCount;
		for (auto* npc : npcs) {
			if (!npc || !npc->deathItem) {
				continue;
			}
			const auto it = typeOfList.find(npc->deathItem);
			if (it == typeOfList.end() || !npc->race) {
				continue;
			}
			auto& s = sig[it->second];
			s.races.insert(npc->race);
			s.skeletons.insert(Skeleton(npc->race));
			if (npc->voiceType) {
				s.voices.insert(npc->voiceType);
			}
			handledCount[it->second]++;
		}

		std::vector<Found>                       found;
		std::map<std::string, std::map<std::string, int>> perPlugin;  // plugin -> outcome -> count
		std::map<std::string, int>               skipped;             // reason -> count
		int                                      handled = 0;
		int                                      considered = 0;

		for (auto* npc : npcs) {
			if (!npc || !npc->race || npc->IsDeleted()) {
				continue;
			}
			auto* race = npc->race;
			if (!race->HasKeywordID(kActorTypeAnimal) || !npc->deathItem) {
				continue;
			}
			if (typeOfList.contains(npc->deathItem)) {
				handled++;
				continue;  // Hunterborn already handles it
			}
			considered++;
			const std::string plugin = FileOf(npc);
			const std::string raceId = race->GetFormEditorID() ? race->GetFormEditorID() : "";
			const std::string raceName = race->GetName() ? race->GetName() : "";
			const std::string npcName = npc->GetName() ? npc->GetName() : "";
			const std::string text = Lower(raceId + " | " + raceName + " | " + npcName + " | " + Skeleton(race));

			Found f{ npc, nullptr, {}, plugin, raceId.empty() ? raceName : raceId };

			const std::string lp = Lower(plugin);
			bool skip = false;
			for (const auto& p : DefaultSkipPlugins()) {
				skip = skip || lp == p;
			}
			for (const auto& p : rules.skipPlugins) {
				skip = skip || lp == p;
			}
			std::string skipWhy = skip ? "plugin is on the skip list" : "";
			if (!skip) {
				for (const auto& w : DefaultSkipWords()) {
					if (Contains(text, w)) { skip = true; skipWhy = "name or race says '" + w + "'"; break; }
				}
			}
			if (!skip) {
				for (const auto& w : rules.skip) {
					if (Contains(text, w)) { skip = true; skipWhy = "your skip word '" + w + "'"; break; }
				}
			}
			if (skip) {
				f.reason = "skipped: " + skipWhy;
				skipped[skipWhy]++;
				perPlugin[plugin]["skipped"]++;
				found.push_back(std::move(f));
				continue;
			}

			// 1. what the creature is built on: a race, skeleton or voice a vanilla animal of a type already has
			std::vector<const Type*> byRace, bySkeleton, byVoice;
			for (const auto& [type, s] : sig) {
				if (s.races.contains(race)) { byRace.push_back(type); }
				if (!Skeleton(race).empty() && s.skeletons.contains(Skeleton(race))) { bySkeleton.push_back(type); }
				if (npc->voiceType && s.voices.contains(npc->voiceType)) { byVoice.push_back(type); }
			}
			const Type* chosen = nullptr;
			if (byRace.size() == 1) { chosen = byRace[0]; f.reason = "race of a vanilla " + std::string(chosen->name); }
			else if (bySkeleton.size() == 1) { chosen = bySkeleton[0]; f.reason = "same skeleton as a vanilla " + std::string(chosen->name); }
			else if (byVoice.size() == 1) { chosen = byVoice[0]; f.reason = "same voice as a vanilla " + std::string(chosen->name); }

			// 2. your own words
			if (!chosen) {
				for (const auto& [word, typeName] : rules.map) {
					if (Contains(text, word)) {
						if (const auto* t = FindTypeByName(typeName)) { chosen = t; f.reason = "your rule '" + word + "'"; break; }
					}
				}
			}

			// 3. words in the names: the longest word that matches wins, so "mudcrabking" beats "mudcrab"
			if (!chosen) {
				std::size_t best = 0;
				std::string bestWord;
				for (const auto& t : Types()) {
					for (const auto& w : t.words) {
						if (w.size() > best && Contains(text, w)) { best = w.size(); chosen = &t; bestWord = w; }
					}
				}
				if (chosen) { f.reason = "name or race says '" + bestWord + "'"; }
			}

			f.type = chosen;
			perPlugin[plugin][chosen ? "typed" : "unknown"]++;
			found.push_back(std::move(f));
		}

		// ---- the report
		std::error_code ec;
		auto            dir = SKSE::log::log_directory();
		if (!dir) {
			return;
		}
		const auto path = *dir / "HunterbornNative_AutoPatch.txt";
		std::ofstream out(path, std::ios::trunc);
		if (!out) {
			return;
		}
		int typed = 0, unknown = 0, skippedCount = 0;
		for (const auto& f : found) {
			(f.type ? typed : (f.reason.starts_with("skipped") ? skippedCount : unknown))++;
		}
		out << "Hunterborn AutoPatch report (read only: nothing in the game was changed)\n";
		out << "=========================================================================\n";
		out << "NPCs scanned: " << npcs.size() << "\n";
		out << "Animals Hunterborn already handles (their loot list is one of its own): " << handled << "\n";
		out << "Animals from other mods that use their own loot list: " << considered << "\n";
		out << "   with a Hunterborn type found: " << typed << "\n";
		out << "   left alone (summons, pets, mounts ...): " << skippedCount << "\n";
		out << "   no type found: " << unknown << "\n\n";

		out << "BY TYPE\n-------\n";
		for (const auto& t : Types()) {
			std::vector<const Found*> list;
			for (const auto& f : found) {
				if (f.type == &t) { list.push_back(&f); }
			}
			if (list.empty()) { continue; }
			out << (t.monster ? "[monster] " : "") << t.name << " (" << list.size() << ")\n";
			for (const auto* f : list) {
				out << std::format("   {:08X}  {:<28} race {:<34} {:<30} {}\n", f->npc->GetFormID(), std::string("\"") + (f->npc->GetName() ? f->npc->GetName() : "") + "\"",
					f->race, f->plugin, f->reason);
			}
		}

		out << "\nNO TYPE FOUND (add a line under [Map] in autopatch.ini: a word from the name or race = a type name from this report)\n";
		out << "----------------------------------------------------------------------------------------------------------------\n";
		for (const auto& f : found) {
			if (f.type || f.reason.starts_with("skipped")) { continue; }
			out << std::format("   {:08X}  {:<28} race {:<34} {:<30} skeleton {}\n", f.npc->GetFormID(), std::string("\"") + (f.npc->GetName() ? f.npc->GetName() : "") + "\"",
				f.race, f.plugin, Skeleton(f.npc->race));
		}

		out << "\nLEFT ALONE\n----------\n";
		for (const auto& f : found) {
			if (!f.reason.starts_with("skipped")) { continue; }
			out << std::format("   {:08X}  {:<28} race {:<34} {:<30} {}\n", f.npc->GetFormID(), std::string("\"") + (f.npc->GetName() ? f.npc->GetName() : "") + "\"",
				f.race, f.plugin, f.reason);
		}

		out << "\nBY PLUGIN\n---------\n";
		for (const auto& [plugin, counts] : perPlugin) {
			out << "   " << std::format("{:<44}", plugin);
			for (const auto& [k, n] : counts) { out << " " << k << " " << n; }
			out << "\n";
		}

		out << "\nWHAT EACH TYPE LOOKS LIKE IN THIS GAME (vanilla creatures that already use its loot list)\n";
		out << "----------------------------------------------------------------------------------------\n";
		for (const auto& t : Types()) {
			const auto it = handledCount.find(&t);
			out << std::format("   {:<14}{:>4} creature(s)  {} race(s)  {} skeleton(s)  {} voice(s)\n", t.name, it == handledCount.end() ? 0 : it->second,
				sig[&t].races.size(), sig[&t].skeletons.size(), sig[&t].voices.size());
		}

		const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - started).count();
		SKSE::log::info("AutoPatch report: {} animals from other mods, {} typed, {} left alone, {} unknown; {} ms; written to {}", considered, typed, skippedCount, unknown, ms,
			path.string());
	}
}
