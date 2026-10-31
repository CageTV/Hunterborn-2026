/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "Actions.h"
#include "Hotkeys.h"
#include "Menu.h"
#include "Settings.h"

#include "SKSEMenuFramework.h"

namespace Menu
{
	namespace
	{
		using namespace ImGuiMCP;

		bool registered = false;

		// The generated page indexes that are drawn by hand instead of from the table.
		constexpr int kStatsPage = 4;
		constexpr int kProfilePage = 7;

		constexpr const char* kLogoPath = "Data\\Interface\\HunterbornNative\\hunterborn_logo.png";
		constexpr float       kLogoAspect = 275.0f / 1000.0f;

		void Logo()
		{
			static ImTextureID tex = SKSEMenuFramework::LoadTexture(kLogoPath);
			if (!tex) {
				return;
			}
			const float avail = GetContentRegionAvail().x;
			const float w = std::min(avail, 460.0f);
			SetCursorPosX(GetCursorPosX() + (avail - w) * 0.5f);
			Image(tex, ImVec2(w, w * kLogoAspect));
			Spacing();
		}

		struct Detected
		{
			const char* name;
			const char* plugin;
		};

		// Mods Hunterborn reads, patches or has a patch for. Only the ones in the load order are shown.
		constexpr Detected kDetected[] = {
			{ "Soups and Stews", "Hunterborn - Soups and Stews.esp" },
			{ "Leather Tanning", "Hunterborn - Leather Tanning.esp" },
			{ "Campfire", "Campfire.esm" },
			{ "Campfire patch", "Hunterborn - Campfire Patch.esp" },
			{ "Frostfall", "Frostfall.esp" },
			{ "Last Seed", "LastSeed.esp" },
			{ "Last Seed patch", "Hunterborn - LastSeed Patch SE.esp" },
			{ "Complete Alchemy & Cooking Overhaul", "complete alchemy & cooking overhaul.esp" },
			{ "CACO patch", "Hunterborn_CACO-SE_Patch.esp" },
			{ "Simple Hunting Overhaul", "Simple Hunting Overhaul.esp" },
			{ "Skills of the Wild", "SkillsOfTheWild.esp" },
			{ "Hunting in Skyrim", "Hunting in Skyrim.esp" },
			{ "Eating Animations and Sounds patch", "EASHunterbornPatch.esp" },
			{ "Immersive Hunting Animations", "ImmersiveHunting.esp" },
		};

		void Tip(const char* a_text)
		{
			if (a_text && a_text[0] && IsItemHovered()) {
				BeginTooltip();
				PushTextWrapPos(420.0f);
				TextUnformatted(a_text);
				PopTextWrapPos();
				EndTooltip();
			}
		}

		bool Guard()
		{
			if (!Settings::Loaded()) {
				TextColored(ImVec4(1.0f, 0.45f, 0.4f, 1.0f), "Hunterborn.esp is not loaded.");
				return false;
			}
			return true;
		}

		// What will happen when the menu closes.
		void PendingNotice()
		{
			if (Actions::Pending()) {
				char buffer[256];
				Actions::Describe(Actions::PendingFlags(), buffer, sizeof(buffer));
				TextColored(ImVec4(0.95f, 0.8f, 0.4f, 1.0f), "When you close this menu Hunterborn will: %s.", buffer);
				Separator();
			}
		}

		bool Disabled(const Settings::Def& a_d)
		{
			const std::string_view id = a_d.id ? a_d.id : "";
			if (id.starts_with("gIncludeMonster")) {
				return Settings::GetByName("gMonsterHunter") < 0.5f;
			}
			if (id == "gDragonsCorporeal") {
				return Settings::GetByName("gMonsterHunter") < 0.5f || Settings::GetByName("gIncludeMonsterDragons") < 0.5f;
			}
			if (id == "gMeatYieldCustom") {
				return static_cast<int>(Settings::GetByName("gMeatYield")) != 4;  // only the "Custom" preset uses the slider
			}
			return false;
		}

		void DrawDef(const Settings::Def& a_d)
		{
			if (Settings::IsHeader(a_d)) {
				Spacing();
				SeparatorText(a_d.label);
				return;
			}
			const bool available = Settings::Available(a_d);
			const bool off = !available || Disabled(a_d);
			PushID(a_d.id);
			if (off) {
				BeginDisabled();
			}
			switch (a_d.kind) {
			case Settings::Kind::Toggle:
				{
					bool on = Settings::Get(a_d) > 0.5f;
					if (Checkbox(a_d.label, &on)) {
						Settings::Set(a_d, on ? 1.0f : 0.0f);
					}
					Tip(a_d.tip);
				}
				break;
			case Settings::Kind::Slider:
				{
					float v = Settings::Get(a_d);
					SetNextItemWidth(260.0f);
					if (SliderFloat(a_d.label, &v, a_d.min, a_d.max, a_d.fmt)) {
						Settings::Set(a_d, v);
					}
					Tip(a_d.tip);
				}
				break;
			case Settings::Kind::Combo:
				{
					int index = static_cast<int>(Settings::Get(a_d));
					SetNextItemWidth(260.0f);
					if (Combo(a_d.label, &index, a_d.options, a_d.optionCount)) {
						Settings::Set(a_d, static_cast<float>(index));
					}
					Tip(a_d.tip);
				}
				break;
			case Settings::Kind::Key:
				{
					int picked = 0;
					if (Hotkeys::CapturingSlot() == a_d.slot && Hotkeys::TakeCaptured(a_d.slot, picked)) {
						Settings::SetKey(a_d, picked);
					}
					if (Hotkeys::CapturingSlot() == a_d.slot) {
						if (Button("Press a key...  (Esc cancels, Delete clears)")) {
							Hotkeys::CancelCapture();
						}
					} else {
						const std::string text = std::string(Hotkeys::KeyName(Settings::KeyOf(a_d))) + "##key";
						if (Button(text.c_str(), ImVec2(180.0f, 0.0f))) {
							Hotkeys::BeginCapture(a_d.slot);
						}
					}
					SameLine();
					Text("%s", a_d.label);
					Tip(a_d.tip);
				}
				break;
			}
			if (off) {
				EndDisabled();
			}
			PopID();
		}

		void DrawPage(int a_page)
		{
			if (!Guard()) {
				return;
			}
			PendingNotice();
			if (!Actions::Active()) {
				TextDisabled("Hunterborn is not running in this game. Start it on the Overview page; your choices here are kept either way.");
				Separator();
			}
			const auto& page = Settings::PageAt(a_page);
			for (int i = 0; i < page.count; ++i) {
				DrawDef(page.defs[i]);
			}
			if (a_page == 3) {
				Spacing();
				TextWrapped("Click a key button, then press the key. Escape cancels, Delete clears it. The hotkeys work in the open game, not in menus, "
							"and are handled by Hunterborn's own script, as before.");
			}
		}

		template <int N>
		void __stdcall RenderGenericPage()
		{
			DrawPage(N);
		}

		void ValueRow(const char* a_label, const char* a_global)
		{
			const float v = Settings::GetByName(a_global);
			if (std::isnan(v)) {
				TextDisabled("%s: not available", a_label);
			} else {
				Text("%s: %.0f", a_label, v);
			}
		}

		void __stdcall RenderOverview()
		{
			if (!Guard()) {
				return;
			}
			Logo();
			PendingNotice();
			const bool active = Actions::Active();
			TextColored(active ? ImVec4(0.65f, 0.9f, 0.5f, 1.0f) : ImVec4(0.95f, 0.8f, 0.4f, 1.0f), active ? "Hunterborn is running." : "Hunterborn is not running.");
			Spacing();
			TextWrapped("Hunterborn changes looting animals into a process of dressing, skinning, harvesting and butchering. These pages replace the SkyUI "
						"menu of Hunterborn SE MCM: every option writes the same Hunterborn global variable as before, so the mod and the pages always agree.");
			Spacing();
			SeparatorText("Hunterborn");
			if (active) {
				if (Button("Stop Hunterborn")) {
					Actions::Queue(Actions::ActStop);
				}
				SameLine();
				TextDisabled("Takes effect when you close this menu.");
			} else {
				if (Button("Start Hunterborn")) {
					Actions::Queue(Actions::ActStart);
				}
				SameLine();
				TextDisabled("Takes effect when you close this menu.");
			}
			if (active) {
				Spacing();
				if (Button("Reapply templates")) {
					Actions::Queue(Actions::ActReapply);
				}
				Tip("Reapplies the changes Hunterborn makes when first started, including animals. This may help if adding another mod has broken "
					"Hunterborn. You won't lose your Hunterborn items or experience, but it is not as thorough as a clean save. Runs when you close this menu.");
			}
			Spacing();
			SeparatorText("Your experience");
			ValueRow("Carcasses cleaned", "gTotalCleans");
			ValueRow("Skinning level", "gSkinLevel");
			ValueRow("Harvesting level", "gHarvestLevel");
			ValueRow("Foraging level", "gForageLevel");
			Spacing();
			SeparatorText("Detected in your load order");
			auto* dh = RE::TESDataHandler::GetSingleton();
			int shown = 0;
			for (const auto& d : kDetected) {
				if (dh && dh->LookupModByName(d.plugin)) {
					TextColored(ImVec4(0.65f, 0.9f, 0.5f, 1.0f), "%s", d.name);
					++shown;
				}
			}
			if (!shown) {
				TextDisabled("None of the mods Hunterborn works with were found.");
			}
			if (dh && dh->LookupModByName("SimpleHunterborn.esp")) {
				Spacing();
				TextColored(ImVec4(0.95f, 0.6f, 0.35f, 1.0f), "Simple Hunterborn is installed.");
				TextWrapped("These settings pages and the native plugin replace what Simple Hunterborn did, and its older copies of Hunterborn's scripts "
							"can conflict with this mod. You can remove it. If you keep it, load Hunterborn2026.esp after SimpleHunterborn.esp.");
			}
			Spacing();
			TextDisabled("Hunterborn by unuroboros, the SE MCM version by Hazado. Settings pages by CageTV.");
		}

		void __stdcall RenderStats()
		{
			if (!Guard()) {
				return;
			}
			PendingNotice();
			SeparatorText("Proficiency");
			ValueRow("Carcasses cleaned", "gTotalCleans");
			ValueRow("Skinning level", "gSkinLevel");
			ValueRow("Skinning experience", "gSkinExp");
			ValueRow("Harvesting level", "gHarvestLevel");
			ValueRow("Harvesting experience", "gHarvestExp");
			ValueRow("Foraging level", "gForageLevel");
			ValueRow("Foraging experience", "gForageExp");
			Spacing();
			SeparatorText("Reset experience to");
			static const char* kPresets[] = { "Novice", "Apprentice", "Adept", "Expert", "Master" };
			static int         chosen = 0;
			static float       confirm = 0.0f;
			SetNextItemWidth(220.0f);
			Combo("Level", &chosen, kPresets, 5);
			if (confirm > 0.0f) {
				confirm -= GetIO()->DeltaTime;
				TextWrapped("Set your carcasses cleaned, skinning, harvesting and foraging to %s? This replaces your progress.", kPresets[chosen]);
				if (Button("Yes, set it")) {
					Actions::ResetExperience(chosen + 1);
					confirm = 0.0f;
				}
				SameLine();
				if (Button("Cancel")) {
					confirm = 0.0f;
				}
			} else if (Button("Set experience")) {
				confirm = 10.0f;
			}
			Spacing();
			TextDisabled("Your experience is progress, not a setting: it is never saved to the settings file.");
		}

		void __stdcall RenderProfile()
		{
			bool apply = Settings::ApplyOnLoad();
			if (Checkbox("Apply these settings on every game load", &apply)) {
				Settings::SetApplyOnLoad(apply);
			}
			Tip("Your choices are kept in the settings file and put back whenever a game loads, so they follow you to a new character. "
				"Turn this off to let each save keep its own values.");
			Spacing();
			TextWrapped("Settings file: %s", Settings::FilePath());
			Spacing();
			if (Button("Save current settings now")) {
				Settings::SaveNow();
			}
			SameLine();
			if (Button("Load the file now")) {
				Settings::LoadNow();
			}
			Spacing();
			static float confirm = 0.0f;
			if (confirm > 0.0f) {
				confirm -= GetIO()->DeltaTime;
				TextWrapped("Reset every setting to what Hunterborn ships with? Your hotkeys and your experience are left alone.");
				if (Button("Yes, reset")) {
					Settings::ResetDefaults();
					confirm = 0.0f;
				}
				SameLine();
				if (Button("Cancel")) {
					confirm = 0.0f;
				}
			} else if (Button("Reset all settings to default")) {
				confirm = 10.0f;
			}
		}

		constexpr float   kStartFadeIn = 0.8f;
		constexpr float   kStartHold = 2.6f;
		constexpr float   kStartFadeOut = 1.2f;
		std::atomic<bool> startLogoRequested{ false };
		float             startLogoTime = -1.0f;  // seconds since the logo started, -1 = not showing

		// The logo fades in near the top of the screen, holds, and fades out: what Frostfall 2026 and Last Seed 2026 show when they start.
		void DrawStartLogo(ImDrawList* a_dl, float a_dt)
		{
			// A logo that was asked for waits until you are in control: Hunterborn can start while the opening, a menu or a dialogue is still on screen, and the
			// overlay is not visible then.
			static bool waiting = false;
			if (startLogoRequested.exchange(false)) {
				waiting = true;
			}
			if (waiting && startLogoTime < 0.0f) {
				auto*       ui = RE::UI::GetSingleton();
				auto*       player = RE::PlayerCharacter::GetSingleton();
				const bool free = ui && player && player->Is3DLoaded() && !ui->GameIsPaused() && !ui->IsMenuOpen(RE::MainMenu::MENU_NAME) && !ui->IsMenuOpen(RE::LoadingMenu::MENU_NAME) &&
				                  !ui->IsMenuOpen(RE::RaceSexMenu::MENU_NAME) && !ui->IsMenuOpen(RE::DialogueMenu::MENU_NAME) && !ui->IsMenuOpen(RE::MessageBoxMenu::MENU_NAME) &&
				                  !ui->IsMenuOpen(RE::MapMenu::MENU_NAME) && !ui->IsMenuOpen(RE::InventoryMenu::MENU_NAME) && !SKSEMenuFramework::IsAnyBlockingWindowOpened();
				if (free) {
					waiting = false;
					startLogoTime = 0.0f;
					SKSE::log::info("Start-up logo shown");
				}
			}
			if (startLogoTime < 0.0f) {
				return;
			}
			startLogoTime += a_dt;
			const float total = kStartFadeIn + kStartHold + kStartFadeOut;
			if (startLogoTime >= total) {
				startLogoTime = -1.0f;
				return;
			}
			float a = 1.0f;
			if (startLogoTime < kStartFadeIn) {
				a = startLogoTime / kStartFadeIn;
			} else if (startLogoTime > kStartFadeIn + kStartHold) {
				a = 1.0f - (startLogoTime - kStartFadeIn - kStartHold) / kStartFadeOut;
			}
			a = a * a * (3.0f - 2.0f * a);  // smoothstep

			static ImTextureID tex = SKSEMenuFramework::LoadTexture(kLogoPath);
			if (!tex) {
				static bool said = false;
				if (!said) {
					said = true;
					SKSE::log::warn("The start-up logo ({}) could not be loaded", kLogoPath);
				}
				return;
			}
			const auto* io = GetIO();
			const float w = std::min(io->DisplaySize.x * 0.34f, 900.0f);
			const float h = w * kLogoAspect;
			const float x = (io->DisplaySize.x - w) * 0.5f;
			const float y = io->DisplaySize.y * 0.24f;
			const float drift = (1.0f - a) * 6.0f;  // settles upward slightly as it fades in
			const ImU32 shadow = IM_COL32(0, 0, 0, static_cast<int>(165 * a));
			const ImU32 white = IM_COL32(255, 255, 255, static_cast<int>(255 * a));
			ImDrawListManager::AddImage(a_dl, tex, ImVec2(x + 2, y + 3 + drift), ImVec2(x + w + 2, y + h + 3 + drift), ImVec2(0, 0), ImVec2(1, 1), shadow);
			ImDrawListManager::AddImage(a_dl, tex, ImVec2(x, y + drift), ImVec2(x + w, y + h + drift), ImVec2(0, 0), ImVec2(1, 1), white);
		}

		// Drawn every frame whether or not the menu is open: runs the queued work and writes the settings file a moment after the last change.
		void __stdcall Frame()
		{
			const float dt = GetIO()->DeltaTime;
			Settings::Tick(dt);
			Actions::Tick(dt);
			DrawStartLogo(GetForegroundDrawList(), std::clamp(dt, 0.0f, 0.1f));
		}
	}

	bool Registered() { return registered; }

	void ShowStartLogo()
	{
		startLogoRequested = true;
		SKSE::log::info("Start-up logo requested");
	}

	void Register()
	{
		if (!SKSEMenuFramework::IsInstalled()) {
			SKSE::log::warn("SKSE Menu Framework is not installed: the Hunterborn settings pages are not available");
			return;
		}
		SKSEMenuFramework::SetSection("Hunterborn");
		SKSEMenuFramework::AddSectionItem("Overview", RenderOverview);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(0).title, RenderGenericPage<0>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(1).title, RenderGenericPage<1>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(2).title, RenderGenericPage<2>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(3).title, RenderGenericPage<3>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(kStatsPage).title, RenderStats);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(5).title, RenderGenericPage<5>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(6).title, RenderGenericPage<6>);
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(8).title, RenderGenericPage<8>);  // Extras: settings of this plugin that are not Hunterborn globals
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(kProfilePage).title, RenderProfile);
		SKSEMenuFramework::AddHudElement(Frame);
		registered = true;
		SKSE::log::info("Registered with SKSE Menu Framework {}", SKSEMenuFramework::GetMenuFrameworkVersion());
	}
}
