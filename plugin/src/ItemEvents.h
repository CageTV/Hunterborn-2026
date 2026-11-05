/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// The player's item events, forwarded from C++ for the few items Hunterborn reacts to.
//
// _DS_HB_Player used OnItemAdded / OnItemRemoved, which the game sends for EVERY item the player gets or loses: one
// Papyrus stack per item, whatever it is. A big Take All / Store All (a container mod, a sort mod, the game's own Take All
// on a full chest) queued one stack per item and froze the script VM ("Suspended stack count is over our warning
// threshold", _ds_hb_player.OnItemAdded x69..x117 in the stack dump summary). The script now has no item events; the DLL
// listens to the game's container-change event in C++ (cheap) and calls HB_ItemAdded / HB_ItemRemoved on the player
// alias only for carcasses, hunting knives, the Bone Divining Knife, pets, pet lures and soup - the items the script
// actually handles.
namespace ItemEvents
{
	void OnDataLoaded();
}
