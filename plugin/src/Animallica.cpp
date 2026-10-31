/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "Animallica.h"
#include "Settings.h"

namespace Animallica
{
	namespace
	{
		constexpr const char* kPlugin = "Animallica.esp";

#include "AnimalliLore.inc"  // kAnimalliLoreFriendly, kAnimalliLoreRedux: { editor ID, local form ID in Animallica.esp }

		template <std::size_t N>
		void Collect(const AnimalliEntry (&a_table)[N], std::set<RE::FormID>& a_out)
		{
			auto* dh = RE::TESDataHandler::GetSingleton();
			for (const auto& e : a_table) {
				if (auto* npc = dh->LookupForm<RE::TESNPC>(e.local, kPlugin)) {
					a_out.insert(npc->GetFormID());
				}
			}
		}
	}

	void Apply()
	{
		const auto* def = Settings::Find("animallica_lore");
		const int   mode = def ? static_cast<int>(Settings::Get(*def) + 0.5f) : 0;
		if (mode <= 0) {
			return;
		}
		auto* dh = RE::TESDataHandler::GetSingleton();
		if (!dh || !dh->LookupModByName(kPlugin)) {
			return;
		}
		std::set<RE::FormID> remove;
		if (mode == 1) {
			Collect(kAnimalliLoreFriendly, remove);
		} else {
			Collect(kAnimalliLoreRedux, remove);
		}
		if (remove.empty()) {
			SKSE::log::warn("Animallica lore filter: none of the creatures to remove were found in {}", kPlugin);
			return;
		}
		int lists = 0, removed = 0, kept = 0;
		for (auto* list : dh->GetFormArray<RE::TESLevCharacter>()) {
			if (!list || list->numEntries == 0) {
				continue;
			}
			std::uint8_t out = 0;
			int          gone = 0;
			for (std::uint8_t i = 0; i < list->numEntries; ++i) {
				if (list->entries[i].form && remove.contains(list->entries[i].form->GetFormID())) {
					++gone;
					continue;
				}
				if (out != i) {
					list->entries[out] = list->entries[i];
				}
				++out;
			}
			if (gone == 0) {
				continue;
			}
			if (out == 0) {  // a list that would be left empty is left as it was (nothing was moved: every entry matched)
				++kept;
				continue;
			}
			list->numEntries = out;
			++lists;
			removed += gone;
		}
		SKSE::log::info("Animallica lore filter ({}): {} creature(s) taken out of {} spawn list(s), {} entries; {} list(s) left alone because they would be empty",
			mode == 1 ? "Lore Friendly" : "Lore Edition Redux", remove.size(), lists, removed, kept);
	}
}
