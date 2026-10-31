/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "HunterbornIds.h"

namespace HbIds
{
	namespace
	{
#include "HunterbornEslMap.inc"
	}

	bool LightEdition()
	{
		static int state = -1;  // -1 not looked at yet
		if (state < 0) {
			auto* dh = RE::TESDataHandler::GetSingleton();
			if (!dh) {
				return false;
			}
			const auto* file = dh->LookupModByName("Hunterborn.esp");
			if (!file) {
				return false;  // Hunterborn.esp is not in the load order (or not known yet): ask again later
			}
			state = file->IsLight() ? 1 : 0;
			if (state == 1) {
				SKSE::log::info("Hunterborn.esp is the ESL edition: its record ids are translated");
			}
		}
		return state == 1;
	}

	unsigned Fix(const char* a_plugin, unsigned a_local)
	{
		if (!a_plugin || _stricmp(a_plugin, "Hunterborn.esp") != 0 || !LightEdition()) {
			return a_local;
		}
		const auto* end = std::end(kEslMap);
		const auto* it = std::lower_bound(std::begin(kEslMap), end, a_local, [](const auto& e, unsigned v) { return e.first < v; });
		return it != end && it->first == (a_local & 0xFFFFFF) ? it->second : a_local;
	}
}
