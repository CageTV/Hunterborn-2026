/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// Hunterborn shows some purely informational messages as pop-up boxes that stop the game until you click them. The community patch "Hunterborn -
// Messages to Notifications" turns 55 of them into on-screen notifications. This does the same to Hunterborn SE MCM's own messages while the game
// runs (the message list is generated from the patch), can be switched on and off without a restart, and replaces a plugin.
namespace Notifications
{
	void Apply(bool a_on);  // converts the messages (or puts them back)
	bool Applied();
	int  Count();  // how many messages it changes
}
