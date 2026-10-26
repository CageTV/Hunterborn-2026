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
			PendingNotice();
			const bool active = Actions::Active();
			TextColored(active ? ImVec4(0.65f, 0.9f, 0.5f, 1.0f) : ImVec4(0.95f, 0.8f, 0.4f, 1.0f), active ? "Hunterborn is running." : "Hunterborn is not running.");
			Spacing();
			TextWrapped("Hunterborn changes looting animals into a process of dressing, skinning, harvesting and butchering. These pages replace the SkyUI "
						"menu of Hunterborn SE MCM and are generated from it: every option writes the same Hunterborn global variable as before, so the mod "
						"and the pages always agree.");
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
			SeparatorText("Installed");
			auto* dh = RE::TESDataHandler::GetSingleton();
			auto row = [&](const char* a_name, const char* a_plugin) {
				const bool on = dh && dh->LookupModByName(a_plugin);
				Text("%s: %s", a_name, on ? "yes" : "no");
			};
			row("Soups and Stews", "Hunterborn - Soups and Stews.esp");
			row("Leather Tanning", "Hunterborn - Leather Tanning.esp");
			row("Simple Hunting Overhaul", "Simple Hunting Overhaul.esp");
			row("Simple Hunterborn", "SimpleHunterborn.esp");
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

		// Drawn every frame whether or not the menu is open: runs the queued work and writes the settings file a moment after the last change.
		void __stdcall Frame()
		{
			const float dt = GetIO()->DeltaTime;
			Settings::Tick(dt);
			Actions::Tick(dt);
		}
	}

	bool Registered() { return registered; }

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
		SKSEMenuFramework::AddSectionItem(Settings::PageAt(kProfilePage).title, RenderProfile);
		SKSEMenuFramework::AddHudElement(Frame);
		registered = true;
		SKSE::log::info("Registered with SKSE Menu Framework {}", SKSEMenuFramework::GetMenuFrameworkVersion());
	}
}
