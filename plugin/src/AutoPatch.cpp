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
		constexpr unsigned kActorTypeAnimal = 0x013798;    // Skyrim.esm keywords the races of animals ...
		constexpr unsigned kActorTypeCreature = 0x013795;  // ... and of other creatures carry

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
				{ false, 0, "Skyrim.esm", 0x03AD77, "Bear", { "bear", "grizzly", "panda" } },
				{ false, 1, "Skyrim.esm", 0x03AD78, "BearCave", { "cavebear", "bearcave", "cave bear" } },
				{ false, 2, "Skyrim.esm", 0x03AD79, "BearSnow", { "snowbear", "bearsnow", "snow bear", "polarbear", "polar bear" } },
				{ false, 3, "Skyrim.esm", 0x106AEC, "Chicken", { "chicken", "rooster", "chick", "chicklin", "hen", "pheasant", "tragopan", "goose", "geese", "duck", "turkey", "quail", "grouse", "partridge", "owl" } },
				{ false, 4, "Skyrim.esm", 0x03AD7B, "Cow", { "cow", "calf", "cattle", "ox", "oxen", "bull", "yak", "rhino", "rhinoceros" } },
				{ false, 5, "Skyrim.esm", 0x0D284C, "Deer", { "deer", "whitetail", "blacktail", "fawn", "stag", "reindeer", "caribou", "gazelle", "roe", "antelope", "eland", "kob", "nyala", "muntjac" } },
				{ false, 6, "Skyrim.esm", 0x03AD7D, "Dog", { "dog", "hound", "husky" } },
				{ false, 7, "Skyrim.esm", 0x10FF79, "ElkFemale", { "elkfemale", "femaleelk", "elk female", "female elk" } },
				{ false, 8, "Skyrim.esm", 0x03AD7C, "ElkMale", { "elk", "moose" } },
				{ false, 9, "Skyrim.esm", 0x1072C3, "Fox", { "fox", "raccoon", "coon", "badger" } },
				{ false, 10, "Skyrim.esm", 0x1072C4, "FoxIce", { "snowfox", "icefox", "foxsnow", "foxice", "snow fox", "ice fox" } },
				{ false, 11, "Skyrim.esm", 0x03AD8D, "Goat", { "goat", "sheep", "lamb", "ibex" } },
				{ false, 12, "Skyrim.esm", 0x09A772, "Hare", { "hare", "rabbit", "bunny" } },
				{ false, 13, "Skyrim.esm", 0x03AD92, "Horker", { "horker", "walrus" } },
				{ false, 14, "Skyrim.esm", 0x03AD94, "Horse", { "horse", "pony", "stallion", "donkey", "mule" } },
				{ false, 15, "Skyrim.esm", 0x03AD96, "Mammoth", { "mammoth", "elephant" } },
				{ false, 16, "Skyrim.esm", 0x1017B8, "MudCrab01", { "mudcrab", "crab" } },
				{ false, 17, "Skyrim.esm", 0x1017B9, "MudCrab02", { "largemudcrab", "mudcrablarge", "mudcrab02", "large mudcrab" } },
				{ false, 18, "Skyrim.esm", 0x1017BA, "MudCrab03", { "giantmudcrab", "mudcrabgiant", "mudcrabking", "crabking", "mudcrab03", "giant mudcrab" } },
				{ false, 19, "Skyrim.esm", 0x03AD97, "Sabrecat", { "sabrecat", "sabercat", "tiger", "lion", "lioness", "panther", "lynx", "bobcat", "cougar", "leopard", "jaguar", "cheetah", "puma", "taiga" } },
				{ false, 20, "Skyrim.esm", 0x03AD98, "SabrecatSnow", { "sabrecatsnow", "snowsabre", "snowysabre", "snowy sabre", "snow sabre", "snowleopard", "snow leopard" } },
				{ false, 21, "Skyrim.esm", 0x03AD99, "Skeever", { "skeever" } },
				{ false, 22, "Skyrim.esm", 0x03AD9A, "Slaughterfish", { "slaughterfish" } },
				{ false, 23, "Skyrim.esm", 0x03AD9E, "Wolf", { "wolf", "wolves", "hyena", "jackal", "coyote", "durzog" } },
				{ false, 24, "Skyrim.esm", 0x03AD9F, "WolfIce", { "icewolf", "wolfice", "snowwolf", "ice wolf", "snow wolf" } },
				{ false, 25, "Dawnguard.esm", 0x013E25, "DeerVale", { "deervale", "valedeer" } },
				{ false, 26, "Dawnguard.esm", 0x013E24, "SabrecatVale", { "sabrecatvale", "valesabre" } },
				{ false, 27, "Dragonborn.esm", 0x032C7B, "Bristleback", { "boar", "bristleback", "pig", "piglet", "hog", "swine" } },
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
			static const std::vector<std::string> w = { "familiar", "summon", "summoned", "companion", "mount", "battleform", "spebf", "spirit", "spectral", "ghost", "undead", "zombie",
														"koi", "raven", "crow", "hatchling", "spiderling", "elytra", "follower", "daedric", "dwarven", "automaton" };
			return w;
		}

		// Creatures that are not animals only count for a monster type when nothing in them says they are something else: a Dragon Priest is not a dragon.
		const std::vector<std::string>& NotMonsterWords()
		{
			static const std::vector<std::string> w = { "priest", "acolyte", "lich", "draman", "draugr", "skeleton", "dreugh", "daedroth", "daedra", "griffin", "vampire", "knight",
														"mechanic", "stormcloak", "giant", "mage", "warrior", "kwama", "ogrim", "shade" };
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

		// A text is cut into lower-case words at spaces, punctuation, digits and capital letters ("BearSnowRace2" -> bear snow race).
		std::vector<std::string> Words(std::string_view a_text)
		{
			std::vector<std::string> out;
			std::string              cur;
			auto flush = [&]() { if (!cur.empty()) { out.push_back(cur); cur.clear(); } };
			char prev = 0;
			for (const char c : a_text) {
				const bool alpha = std::isalpha(static_cast<unsigned char>(c)) != 0;
				if (!alpha) { flush(); prev = 0; continue; }
				if (std::isupper(static_cast<unsigned char>(c)) && std::islower(static_cast<unsigned char>(prev))) { flush(); }
				cur.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
				prev = c;
			}
			flush();
			return out;
		}

		// A word counts when it is a word of the text, ends one ("packwolf" has "wolf"; "mountain" does not have "mount"), or is two or three neighbouring
		// words written together ("mudcrabking" in "Mud Crab King"). A phrase ("snow bear") needs its words next to each other in that order.
		bool HasWord(const std::vector<std::string>& a_words, const std::string& a_word)
		{
			if (a_word.empty()) { return false; }
			if (a_word.find(' ') != std::string::npos) {
				const auto parts = Words(a_word);
				for (std::size_t i = 0; i + parts.size() <= a_words.size(); ++i) {
					bool ok = true;
					for (std::size_t j = 0; j < parts.size() && ok; ++j) { ok = a_words[i + j] == parts[j]; }
					if (ok) { return true; }
				}
				return false;
			}
			const bool tail = a_word.size() >= 3 && a_word != "hen" && a_word != "roe" && a_word != "hog";
			for (std::size_t i = 0; i < a_words.size(); ++i) {
				const auto& w = a_words[i];
				if (w == a_word || (tail && w.size() > a_word.size() && w.ends_with(a_word))) { return true; }
				std::string joined = w;
				for (std::size_t k = 1; k <= 2 && i + k < a_words.size(); ++k) {
					joined += a_words[i + k];
					if (joined == a_word) { return true; }
				}
			}
			return false;
		}

		// The longest word of a type's list found in the words, so "mudcrabking" beats "mudcrab".
		const Type* BestType(const std::vector<std::string>& a_words, std::string& a_found, bool a_monstersOnly = false)
		{
			const Type* best = nullptr;
			std::size_t len = 0;
			for (const auto& t : Types()) {
				if (a_monstersOnly && !t.monster) { continue; }
				for (const auto& w : t.words) {
					if (w.size() > len && HasWord(a_words, w)) { len = w.size(); best = &t; a_found = w; }
				}
			}
			return best;
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

		// The loot lists of other mods' creatures that Hunterborn treats like a vanilla animal, by [monster][Hunterborn's index]. Hunterborn's scripts ask for them (GetLists) when they set up the death items.
		std::map<std::pair<bool, int>, std::vector<RE::TESLevItem*>> exported;

		std::map<std::pair<bool, int>, std::vector<RE::TESLevItem*>> originals;  // parallel to exported: the loot list each one stands in for

		std::vector<RE::TESLevItem*> GetOriginals(RE::StaticFunctionTag*, bool a_monster, std::int32_t a_index)
		{
			const auto it = originals.find({ a_monster, a_index });
			return it == originals.end() ? std::vector<RE::TESLevItem*>{} : it->second;
		}

		std::vector<RE::TESLevItem*> GetLists(RE::StaticFunctionTag*, bool a_monster, std::int32_t a_index)
		{
			const auto it = exported.find({ a_monster, a_index });
			return it == exported.end() ? std::vector<RE::TESLevItem*>{} : it->second;
		}

		bool NameHas(const RE::TESForm* a_form, std::string_view a_word)
		{
			const char* n = a_form ? a_form->GetName() : nullptr;
			return n && Lower(n).find(a_word) != std::string::npos;
		}

		// The older CommonLib has no TESCondition::Copy: there a recipe with conditions is left alone (its twin could not carry them).
		template <class Cond>
		bool CopyConditions(Cond& a_to, const Cond& a_from, RE::TESForm* a_owner)
		{
			if constexpr (requires { a_to.Copy(&a_from, a_owner); }) {
				a_to.Copy(&a_from, a_owner);
				return true;
			} else {
				return a_from.head == nullptr;
			}
		}

		// Fat patch: every recipe of another mod that uses Troll Fat gets an Animal Fat twin (Animal Fat x3 in place of the Troll Fat), as Hunterborn's own fat patcher did, so soap,
		// supplies and replicas can be made from the fat Hunterborn gives. The twin is a recipe of its own, so the original keeps working. Recipes about trolls are left alone.
		int PatchFat(RE::TESDataHandler* a_dh)
		{
			constexpr std::int32_t kMultiplier = 3;
			auto*                  troll = a_dh->LookupForm(0x03AD72, "Skyrim.esm") ? a_dh->LookupForm(0x03AD72, "Skyrim.esm")->As<RE::TESBoundObject>() : nullptr;
			auto*                  animal = a_dh->LookupForm(0x0AB90C, "Hunterborn.esp") ? a_dh->LookupForm(0x0AB90C, "Hunterborn.esp")->As<RE::TESBoundObject>() : nullptr;
			auto*                  factory = RE::IFormFactory::GetConcreteFormFactoryByType<RE::BGSConstructibleObject>();
			if (!troll || !animal || !factory) {
				SKSE::log::warn("AutoPatch fat: Troll Fat {}, Animal Fat {}, recipe factory {}; no Animal Fat recipes added", troll ? "found" : "MISSING", animal ? "found" : "MISSING", factory ? "found" : "MISSING");
				return 0;
			}
			auto&                                    all = a_dh->GetFormArray<RE::BGSConstructibleObject>();
			std::vector<RE::BGSConstructibleObject*> sources;
			for (auto* r : all) {
				if (!r || r->IsDeleted() || !r->createdItem || Lower(FileOf(r)) == "hunterborn.esp" || NameHas(r->createdItem, "troll")) {
					continue;
				}
				bool        hasTroll = false, otherTroll = false;
				std::string otherName;
				r->requiredItems.ForEachContainerObject([&](RE::ContainerObject& o) {
					if (o.obj == troll) { hasTroll = true; } else if (NameHas(o.obj, "troll")) { otherTroll = true; otherName = o.obj->GetName(); }  // a troll skull or the like: not a recipe to substitute
					return RE::BSContainer::ForEachResult::kContinue;
				});
				if (hasTroll && !otherTroll) {
					sources.push_back(r);
				} else if (hasTroll) {
					SKSE::log::info("AutoPatch fat: {:08X} {} ({}) left alone: it also needs '{}'", r->GetFormID(), FileOf(r), r->createdItem->GetName(), otherName);
				}
			}
			for (auto* src : sources) {
				auto* twin = factory->Create();
				if (!twin) {
					continue;
				}
				twin->createdItem = src->createdItem;
				twin->benchKeyword = src->benchKeyword;
				twin->data = src->data;
				if (!CopyConditions(twin->conditions, src->conditions, twin)) {
					SKSE::log::info("AutoPatch fat: {:08X} {} has conditions this build cannot copy; left alone", src->GetFormID(), FileOf(src));
					continue;
				}
				src->requiredItems.ForEachContainerObject([&](RE::ContainerObject& o) {
					if (o.obj == troll) {
						twin->requiredItems.AddObjectToContainer(animal, o.count * kMultiplier, twin);
					} else {
						twin->requiredItems.AddObjectToContainer(o.obj, o.count, twin);
					}
					return RE::BSContainer::ForEachResult::kContinue;
				});
				all.push_back(twin);
				SKSE::log::info("AutoPatch fat: {:08X} {} -> Animal Fat recipe {:08X} ({})", src->GetFormID(), FileOf(src), twin->GetFormID(), src->createdItem->GetName());
			}
			SKSE::log::info("AutoPatch fat: {} Animal Fat recipes added", sources.size());
			return static_cast<int>(sources.size());
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

	bool RegisterPapyrus(RE::BSScript::IVirtualMachine* a_vm)
	{
		a_vm->RegisterFunction("GetLists", "HunterbornNative", GetLists);
		a_vm->RegisterFunction("GetOriginals", "HunterbornNative", GetOriginals);
		return true;
	}

	void OnDataLoaded()
	{
		auto* dh = RE::TESDataHandler::GetSingleton();
		if (!dh) {
			return;
		}
		const auto started = std::chrono::steady_clock::now();
		PatchFat(dh);
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

		int otherCreatures = 0;  // creatures with a loot list that are neither animals nor one of Hunterborn's monster types: nothing for Hunterborn to do

		// Several types can share a race, skeleton or voice (both elks, both foxes): the one the vanilla game uses far more is the answer, otherwise there is none.
		auto pick = [&](const std::vector<const Type*>& a_list) -> const Type* {
			if (a_list.size() == 1) { return a_list[0]; }
			const Type* top = nullptr;
			int         topN = 0, second = 0;
			for (const auto* t : a_list) {
				const int n = handledCount.contains(t) ? handledCount[t] : 0;
				if (n > topN) { second = topN; topN = n; top = t; } else if (n > second) { second = n; }
			}
			return (top && topN >= 3 && topN >= 3 * second) ? top : nullptr;
		};

		for (auto* npc : npcs) {
			if (!npc || !npc->race || npc->IsDeleted() || !npc->deathItem) {
				continue;
			}
			auto*      race = npc->race;
			const bool isAnimal = race->HasKeywordID(kActorTypeAnimal);
			if (!isAnimal && !race->HasKeywordID(kActorTypeCreature)) {
				continue;
			}
			if (typeOfList.contains(npc->deathItem)) {
				if (isAnimal) { handled++; }
				continue;  // Hunterborn already handles it
			}
			const std::string plugin = FileOf(npc);
			const std::string raceId = race->GetFormEditorID() ? race->GetFormEditorID() : "";
			const std::string raceName = race->GetName() ? race->GetName() : "";
			const std::string npcName = npc->GetName() ? npc->GetName() : "";
			const auto        nameW = Words(npcName);
			const auto        raceW = Words(raceId + " " + raceName);
			auto              allW = nameW;
			allW.insert(allW.end(), raceW.begin(), raceW.end());
			const auto skelW = Words(Skeleton(race));
			allW.insert(allW.end(), skelW.begin(), skelW.end());

			Found f{ npc, nullptr, {}, plugin, raceId.empty() ? raceName : raceId };

			// creatures that are not for hunting
			const std::string lp = Lower(plugin);
			bool              skip = false;
			std::string       skipWhy;
			for (const auto& p : DefaultSkipPlugins()) { if (lp == p) { skip = true; skipWhy = "plugin is on the skip list"; } }
			for (const auto& p : rules.skipPlugins) { if (lp == p) { skip = true; skipWhy = "plugin is on your skip list"; } }
			if (!skip) {
				for (const auto& w : DefaultSkipWords()) {
					if (HasWord(allW, w)) { skip = true; skipWhy = "name or race says '" + w + "'"; break; }
				}
			}
			if (!skip && !isAnimal) {
				for (const auto& w : NotMonsterWords()) {
					if (HasWord(allW, w) && !HasWord(nameW, "spider") && !HasWord(nameW, "chaurus") && !HasWord(nameW, "troll")) { skip = true; skipWhy = "not an animal or monster '" + w + "'"; break; }
				}
			}
			if (!skip) {
				for (const auto& w : rules.skip) {
					if (HasWord(allW, w)) { skip = true; skipWhy = "your skip word '" + w + "'"; break; }
				}
			}
			if (skip) {
				if (isAnimal) {
					considered++;
					f.reason = "skipped: " + skipWhy;
					skipped[skipWhy]++;
					perPlugin[plugin]["skipped"]++;
					found.push_back(std::move(f));
				}
				continue;
			}

			const Type* chosen = nullptr;
			std::string word;

			// 1. your own rules come first
			for (const auto& [w, typeName] : rules.map) {
				if (HasWord(allW, w)) {
					if (const auto* t = FindTypeByName(typeName)) { chosen = t; f.reason = "your rule '" + w + "'"; break; }
				}
			}

			// 2. what the creature calls itself: "Pig" on a cow's skeleton is a pig
			if (!chosen) {
				if (const auto* t = BestType(nameW, word, !isAnimal)) { chosen = t; f.reason = "its name says '" + word + "'"; }
			}

			// 3. what the creature is built on: a race, skeleton or voice a vanilla animal of a type already has
			if (!chosen) {
				std::vector<const Type*> byRace, bySkeleton, byVoice;
				for (const auto& [type, sg] : sig) {
					if (sg.races.contains(race)) { byRace.push_back(type); }
					if (!Skeleton(race).empty() && sg.skeletons.contains(Skeleton(race))) { bySkeleton.push_back(type); }
					if (npc->voiceType && sg.voices.contains(npc->voiceType)) { byVoice.push_back(type); }
				}
				const Type* t = nullptr;
				if ((t = pick(byRace))) { f.reason = "race of a vanilla " + std::string(t->name); }
				else if (!isAnimal) { /* a creature that is not an animal needs the race of a vanilla monster */ }
				else if ((t = pick(bySkeleton))) { f.reason = "same skeleton as a vanilla " + std::string(t->name); }
				else if ((t = pick(byVoice))) { f.reason = "same voice as a vanilla " + std::string(t->name); }
				if (t && (isAnimal ? !t->monster : t->monster)) { chosen = t; } else { f.reason.clear(); }
			}

			// 4. what the race is called
			if (!chosen) {
				if (const auto* t = BestType(raceW, word, !isAnimal)) { chosen = t; f.reason = "its race says '" + word + "'"; }
			}

			if (!isAnimal) {
				if (chosen) { considered++; f.type = chosen; perPlugin[plugin]["typed"]++; found.push_back(std::move(f)); } else { otherCreatures++; }
				continue;
			}
			considered++;
			f.type = chosen;
			perPlugin[plugin][chosen ? "typed" : "unknown"]++;
			found.push_back(std::move(f));
		}

		// ---- the lists Hunterborn's scripts will add their tokens to
		// A creature's own loot list can be shared with creatures of another type (Animallica's tigers, rhinos and deer all use one list), and it may not drop all of its entries.
		// So each (loot list, type) gets a small list of its own that drops everything it holds, and the typed creatures are pointed at it. The scripts put the original list and
		// Hunterborn's tokens into it (GetOriginals / GetLists); creatures of other types, and everything else that uses the original list, are not touched.
		{
			auto* factory = RE::IFormFactory::GetConcreteFormFactoryByType<RE::TESLevItem>();
			if (!factory) {
				SKSE::log::warn("AutoPatch: cannot create loot lists");
				return;
			}
			exported.clear();
			originals.clear();
			std::map<std::pair<RE::TESLevItem*, const Type*>, RE::TESLevItem*> wrappers;
			int                                                                 nCreatures = 0;
			for (const auto& f : found) {
				if (!f.type || !f.npc->deathItem) {
					continue;
				}
				auto*& wrapper = wrappers[{ f.npc->deathItem, f.type }];
				if (!wrapper) {
					wrapper = factory->Create();
					if (!wrapper) {
						continue;
					}
					wrapper->llFlags = RE::TESLeveledList::kUseAll;
					wrapper->chanceNone = 0;
					exported[{ f.type->monster, f.type->index }].push_back(wrapper);
					originals[{ f.type->monster, f.type->index }].push_back(f.npc->deathItem);
				}
				f.npc->deathItem = wrapper;
				nCreatures++;
			}
			SKSE::log::info("AutoPatch: {} creatures now drop through {} loot lists of their own (Hunterborn's tokens go into these)", nCreatures, wrappers.size());
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
