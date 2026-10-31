/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// Animallica (Skyrim Wildlife Overhaul) fills Skyrim's animal spawn lists with creatures that do not belong to Tamriel: tigers, lions, hyenas, rhinos, pandas and more.
// The two lore editions take some of them out of the plugin. This does the same at run time on the plugin you already have, so no second Animallica plugin is
// needed: the creatures each edition removes are taken out of every spawn list once per game load. Nothing in the plugin itself is changed.
namespace Animallica
{
	// Settings "animallica_lore": 0 all of Animallica's creatures, 1 as the Lore Friendly edition, 2 as the Lore Edition Redux (stricter).
	void Apply();  // after a game load or a new game, when every other mod has finished editing the lists
}
