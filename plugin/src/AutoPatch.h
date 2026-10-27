/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// Hunterborn AutoPatch: finds the animals other mods add and works out which of Hunterborn's animal types each one is, from the game's own data
// (the loot list it already uses, its race, skeleton and voice, its names), so Hunterborn can treat them like the vanilla animals without a patch
// plugin. This part only READS and writes a report (SKSE\HunterbornNative_AutoPatch.txt); it changes nothing in the game.
//
// Your own rules go in Data\SKSE\Plugins\HunterbornNative\autopatch.ini:
//   [Map]          tiger = Sabrecat          a word in the creature's names or race, and the Hunterborn type it is (see the report for the type names)
//   [Skip]         koi                       a word that marks a creature to leave alone
//   [SkipPlugins]  SomeMod.esp               every creature this plugin adds is left alone
namespace AutoPatch
{
	void OnDataLoaded();  // scans every NPC once the game's data is loaded and writes the report
}
