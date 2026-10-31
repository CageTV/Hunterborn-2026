/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// The Hunterborn 2026 installer offers an ESL edition of Hunterborn.esp: its records were renumbered into the light range. The ids this plugin knows are those of the
// regular Hunterborn.esp; Fix turns one into the id the loaded plugin really uses (unchanged for the regular plugin and for every other plugin).
namespace HbIds
{
	unsigned Fix(const char* a_plugin, unsigned a_local);
	bool     LightEdition();  // the loaded Hunterborn.esp is the ESL edition
}
