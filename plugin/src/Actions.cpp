/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "Actions.h"
#include "Settings.h"

#include "SKSEMenuFramework.h"

namespace Actions
{
	namespace
	{
		constexpr const char* kPlugin = "Hunterborn.esp";

		// FormIDs in Hunterborn.esp (from the SE MCM quest properties)
		constexpr unsigned kMainQuest = 0x003367;  // _DS_Hunterborn: carries _DS_HB_MAIN, _DS_HB_Animals, _DS_HB_Monsters, _ds_hb_knives, _DS_HB_Actions ...
		constexpr unsigned kMcmQuest = 0x001D89;   // _DS_HunterbornMCM: owns the hotkey events
		constexpr unsigned kConfigSpell = 0x1B2F4B, kForagingSpell = 0x014225, kScrimshawSpell = 0x025C0C, kSenseDirSpell = 0x044ED1,
						   kTrackingSpell = 0xDA5E9B, kPrimCookingSpell = 0x073D95, kTaxonomySpell = 0x0215DA;
		constexpr unsigned kBotanyPerk = 0x14DA0E, kBountyPerk = 0x14DA0D, kSavagePerk = 0x1D1597, kMonsterPerk = 0x024BDB;

		constexpr const char* kHotkeys[] = { "gHotkeyDress", "gHotkeySkin", "gHotkeyHarvest", "gHotkeyButcher", "gHotkeyProcess", "gHotkeyForage",
											 "gHotkeyScrimshaw", "gHotkeyTaxonomy", "gHotkeySenseDirection", "gHotkeyTracking", "gHotkeyPrimitiveCooking" };

		std::mutex mu;
		unsigned   pending = 0;
		float      quiet = 0.0f;  // seconds to wait before running

		template <class T>
		T* Form(unsigned a_id)
		{
			auto* dh = RE::TESDataHandler::GetSingleton();
			return dh ? dh->LookupForm<T>(a_id, kPlugin) : nullptr;
		}

		float G(std::string_view a_name) { return Settings::GetByName(a_name); }
		bool  On(std::string_view a_name) { return G(a_name) > 0.5f; }

		// Papyrus functions of Hunterborn's own scripts are called exactly as the MCM called them, so the game state stays what Hunterborn expects.
		template <class... Args>
		void Call(RE::TESForm* a_form, const char* a_script, const char* a_function, Args... a_args)
		{
			if (!a_form) {
				SKSE::log::warn("Cannot call {}.{}: the form is missing", a_script, a_function);
				return;
			}
			auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
			if (!vm) {
				return;
			}
			const auto policy = vm->GetObjectHandlePolicy();
			if (!policy) {
				return;
			}
			const auto handle = policy->GetHandleForObject(static_cast<RE::VMTypeID>(a_form->GetFormType()), a_form);
			RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> none;
			vm->DispatchMethodCall2(handle, a_script, a_function, RE::MakeFunctionArguments(std::move(a_args)...), none);
			SKSE::log::info("Called {}.{}", a_script, a_function);
		}

		RE::TESForm* MainQuest() { return Form<RE::TESQuest>(kMainQuest); }

		void Spell(unsigned a_id, bool a_add)
		{
			auto* spell = Form<RE::SpellItem>(a_id);
			auto* player = RE::PlayerCharacter::GetSingleton();
			if (!spell || !player) {
				return;
			}
			if (a_add) {
				Call(player, "Actor", "AddSpell", spell, false);
			} else {
				Call(player, "Actor", "RemoveSpell", spell);
			}
		}

		void Perk(unsigned a_id, bool a_add)
		{
			auto* perk = Form<RE::BGSPerk>(a_id);
			auto* player = RE::PlayerCharacter::GetSingleton();
			if (!perk || !player) {
				return;
			}
			Call(player, "Actor", a_add ? "AddPerk" : "RemovePerk", perk);
		}

		bool HasPerk(unsigned a_id)
		{
			auto* perk = Form<RE::BGSPerk>(a_id);
			auto* player = RE::PlayerCharacter::GetSingleton();
			return perk && player && player->HasPerk(perk);
		}

		// The work the MCM did in OnConfigClose, in the same order.
		void Run(unsigned a_flags)
		{
			SKSE::log::info("Running queued Hunterborn work (flags {:#x})", a_flags);
			if (a_flags & ActStop) {
				if (Active()) {
					Call(MainQuest(), "_DS_HB_MAIN", "StopHunterborn");
				}
				return;
			}
			if (a_flags & ActStart) {
				if (!Active()) {
					Call(MainQuest(), "_DS_HB_MAIN", "StartHunterborn");
				}
				return;
			}
			if (!Active()) {
				return;
			}
			auto* main = MainQuest();
			if (a_flags & ActSmallGame) {
				Call(main, "_DS_HB_Animals", "InitDeathItems", false);
			}
			if (a_flags & ActCorpDragons) {
				Call(main, "_DS_HB_Monsters", "InitDeathItems", !On("gMonsterHunter"));
			}
			if (a_flags & ActKnifeSales) {
				Call(main, "_ds_hb_knives", "SetKnifeSales", 0);  // this prevents accidentally adding stock
				const int sales = static_cast<int>(G("gKnifeSales"));
				if (sales > 0) {
					Call(main, "_ds_hb_knives", "SetKnifeSales", sales);
				}
			}
			if (a_flags & (ActKnife | ActKnifeSales)) {
				Call(main, "_DS_HB_Actions", "GetHuntingKnife", true);
			}
			if (a_flags & ActMonsterHunter) {
				Call(main, "_DS_HB_Monsters", "InitDeathItems", !On("gMonsterHunter"));
				if (On("gMonsterHunter") && !HasPerk(kMonsterPerk)) {
					Perk(kMonsterPerk, true);
				} else if (!On("gMonsterHunter") && HasPerk(kMonsterPerk)) {
					Perk(kMonsterPerk, false);
				}
			}
			if (a_flags & ActHideAbilities) {
				const bool hide = On("gHotkey_HideAbilities");
				for (unsigned id : { kConfigSpell, kForagingSpell, kScrimshawSpell, kSenseDirSpell, kTrackingSpell, kPrimCookingSpell }) {
					Spell(id, !hide);
				}
				Spell(kTaxonomySpell, !hide && On("gAddTaxonomy"));
			}
			struct SpellToggle { unsigned flag; unsigned id; const char* global; };
			for (const SpellToggle& t : { SpellToggle{ ActSpellConfig, kConfigSpell, "gEnableConfig" }, { ActSpellForaging, kForagingSpell, "gEnableForaging" },
										  { ActSpellPrimCooking, kPrimCookingSpell, "gEnablePrimitiveCooking" }, { ActSpellScrimshaw, kScrimshawSpell, "gEnableScrimshaw" },
										  { ActSpellSenseDir, kSenseDirSpell, "gEnableSenseDirection" }, { ActSpellTracking, kTrackingSpell, "gEnableTracking" },
										  { ActSpellTaxonomy, kTaxonomySpell, "gAddTaxonomy" } }) {
				if (a_flags & t.flag) {
					Spell(t.id, On(t.global));
				}
			}
			if (a_flags & ActPerkBotany) {
				Perk(kBotanyPerk, On("gEnableBotanyPerk"));
			}
			if (a_flags & ActPerkBounty) {
				Perk(kBountyPerk, On("gEnableBountyPerk"));
			}
			if (a_flags & ActPerkSavage) {
				Perk(kSavagePerk, On("gEnableSavageArrows"));
			}
			if (a_flags & (ActInit | ActReapply)) {
				Notify("Hunterborn is reapplying its templates...");
				if (a_flags & ActReapply) {
					Settings::SetByName("gDoInitStuff", 1.0f);  // the extra resets in DoInitStuff only run while this is set; the script clears it
				}
				Call(main, "_DS_HB_MAIN", "DoInitStuff");
			}
		}
	}

	bool Active() { return On("gHunterbornActive"); }

	void Queue(unsigned a_flags)
	{
		if (!a_flags) {
			return;
		}
		std::lock_guard lock(mu);
		pending |= a_flags;
		quiet = std::max(quiet, 1.5f);
	}

	bool     Pending() { std::lock_guard lock(mu); return pending != 0; }
	unsigned PendingFlags() { std::lock_guard lock(mu); return pending; }

	void Hold(float a_seconds)
	{
		std::lock_guard lock(mu);
		quiet = std::max(quiet, a_seconds);
	}

	void Tick(float a_dt)
	{
		unsigned run = 0;
		{
			std::lock_guard lock(mu);
			if (!pending) {
				return;
			}
			quiet -= a_dt;
			if (quiet > 0.0f) {
				return;
			}
			// the menu is the "config" of the original: do the work only when it is closed and the game is running
			auto* player = RE::PlayerCharacter::GetSingleton();
			auto* ui = RE::UI::GetSingleton();
			if (SKSEMenuFramework::IsAnyBlockingWindowOpened() || !player || !player->Is3DLoaded() ||
				(ui && (ui->IsMenuOpen(RE::MainMenu::MENU_NAME) || ui->IsMenuOpen(RE::LoadingMenu::MENU_NAME)))) {
				quiet = 1.0f;
				return;
			}
			run = pending;
			pending = 0;
		}
		SKSE::GetTaskInterface()->AddTask([run]() { Run(run); });
	}

	void RebindKey(int a_old, int a_new)
	{
		if (a_old == a_new) {
			return;
		}
		auto* mcm = Form<RE::TESQuest>(kMcmQuest);
		if (!mcm) {
			return;
		}
		// the old key is released unless another Hunterborn hotkey still uses it
		bool stillUsed = false;
		for (const char* name : kHotkeys) {
			stillUsed = stillUsed || (a_old > 0 && static_cast<int>(G(name)) == a_old);
		}
		const int oldKey = a_old, newKey = a_new;
		SKSE::GetTaskInterface()->AddTask([mcm, oldKey, newKey, stillUsed]() {
			if (oldKey > 0 && !stillUsed) {
				Call(mcm, "_DS_HB_MCM", "UnregisterForKey", oldKey);
			}
			if (newKey > 0) {
				Call(mcm, "_DS_HB_MCM", "RegisterForKey", newKey);
			}
		});
	}

	void ResetExperience(int a_preset)
	{
		struct Row { int cleans, skinLevel, skinExp, harvestLevel, harvestExp, forageLevel, forageExp; };
		static constexpr Row rows[] = {
			{ 0, 0, 0, 0, 0, 0, 0 },          // Novice
			{ 10, 2, 500, 1, 500, 2, 500 },   // Apprentice
			{ 20, 5, 1000, 3, 1000, 3, 1000 },  // Adept
			{ 50, 8, 2500, 5, 2500, 6, 2500 },  // Expert
			{ 150, 10, 5000, 10, 7500, 10, 6200 },  // Master
		};
		if (a_preset < 1 || a_preset > 5 || !Active()) {
			return;
		}
		const Row& r = rows[a_preset - 1];
		Settings::SetByName("gTotalCleans", static_cast<float>(r.cleans));
		Settings::SetByName("gSkinLevel", static_cast<float>(r.skinLevel));
		Settings::SetByName("gSkinExp", static_cast<float>(r.skinExp));
		Settings::SetByName("gHarvestLevel", static_cast<float>(r.harvestLevel));
		Settings::SetByName("gHarvestExp", static_cast<float>(r.harvestExp));
		Settings::SetByName("gForageLevel", static_cast<float>(r.forageLevel));
		Settings::SetByName("gForageExp", static_cast<float>(r.forageExp));
		SKSE::log::info("Experience set to preset {}", a_preset);
	}

	const char* Describe(unsigned a_flags, char* a_buffer, std::size_t a_size)
	{
		std::string s;
		auto add = [&](const char* t) {
			if (!s.empty()) {
				s += ", ";
			}
			s += t;
		};
		if (a_flags & ActStart) add("start Hunterborn");
		if (a_flags & ActStop) add("stop Hunterborn");
		if (a_flags & (ActSmallGame | ActCorpDragons | ActMonsterHunter)) add("rebuild the loot lists");
		if (a_flags & (ActKnifeSales | ActKnife)) add("update hunting knives");
		if (a_flags & (ActSpellConfig | ActSpellForaging | ActSpellScrimshaw | ActSpellPrimCooking | ActSpellSenseDir | ActSpellTracking | ActSpellTaxonomy | ActHideAbilities)) add("add or remove powers");
		if (a_flags & (ActPerkBotany | ActPerkBounty | ActPerkSavage)) add("add or remove perks");
		if (a_flags & ActInit) add("reapply the value presets");
		if (a_flags & ActReapply) add("reapply Hunterborn's templates");
		std::snprintf(a_buffer, a_size, "%s", s.c_str());
		return a_buffer;
	}
}
