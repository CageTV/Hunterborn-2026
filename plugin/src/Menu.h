/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

namespace Menu
{
	void Register();  // adds the "Hunterborn" section to SKSE Menu Framework
	bool Registered();
	void ShowStartLogo();  // the Hunterborn logo fades in on the screen for a few seconds (called when Hunterborn starts)
}
