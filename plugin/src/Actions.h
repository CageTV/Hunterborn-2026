/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

// What Hunterborn SE MCM's menu does when it CLOSES (its OnConfigClose): add or remove the powers and perks, rebuild the animals' death-item
// lists, restock the knives... The pages here queue the same work as flags while you change settings, and run it once the menu is closed and
// nothing else is changing. The heavy parts stay in Hunterborn's own scripts and are called, not copied.
namespace Actions
{
	enum Act : unsigned
	{
		ActNone = 0,
		ActSmallGame = 1u << 0,       // _DS_HB_Animals.InitDeathItems
		ActCorpDragons = 1u << 1,     // _DS_HB_Monsters.InitDeathItems
		ActMonsterHunter = 1u << 2,   // same, plus the Monster Hunter perk
		ActKnifeSales = 1u << 3,      // _ds_hb_knives.SetKnifeSales
		ActKnife = 1u << 4,           // _DS_HB_Actions.GetHuntingKnife
		ActSpellConfig = 1u << 5,
		ActSpellForaging = 1u << 6,
		ActSpellScrimshaw = 1u << 7,
		ActSpellPrimCooking = 1u << 8,
		ActSpellSenseDir = 1u << 9,
		ActSpellTracking = 1u << 10,
		ActSpellTaxonomy = 1u << 11,
		ActPerkBotany = 1u << 12,
		ActPerkBounty = 1u << 13,
		ActPerkSavage = 1u << 14,
		ActHideAbilities = 1u << 15,  // the "hide abilities" switch: removes or re-adds every power
		ActInit = 1u << 16,           // pelt / meat value presets: _DS_HB_MAIN.DoInitStuff
		ActStart = 1u << 17,          // Start Hunterborn
		ActStop = 1u << 18,           // Stop Hunterborn
	};

	void Queue(unsigned a_flags);
	void Hold(float a_seconds);  // nothing queued runs for at least this long (used right after a game load)
	void Tick(float a_dt);  // from the every-frame callback: runs the queued work when it is safe
	bool Pending();
	unsigned PendingFlags();

	// A hotkey changed: the MCM script owns the key events, so the key is registered on it.
	void RebindKey(int a_old, int a_new);

	bool Active();  // Hunterborn is running (its global _DS_Hunterborn__Active)

	// The experience reset presets of the Stats page (1 Novice .. 5 Master): sets total cleans, skin / harvest / forage level and experience.
	void ResetExperience(int a_preset);

	// What is queued, for the pages (so the player can see that something will happen when the menu closes).
	const char* Describe(unsigned a_flags, char* a_buffer, std::size_t a_size);
}
