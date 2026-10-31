/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "Actions.h"
#include "Animallica.h"
#include "AutoPatch.h"
#include "Menu.h"
#include "Settings.h"

namespace
{
	void SetupLog()
	{
		const auto dir = SKSE::log::log_directory();
		if (!dir) {
			return;
		}
		auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>((*dir / "HunterbornNative.log").string(), true);
		auto log = std::make_shared<spdlog::logger>("HunterbornNative", std::move(sink));
		log->set_level(spdlog::level::info);
		log->flush_on(spdlog::level::info);
		log->set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] %v");
		spdlog::set_default_logger(std::move(log));
	}

	void OnMessage(SKSE::MessagingInterface::Message* a_msg)
	{
		switch (a_msg->type) {
		case SKSE::MessagingInterface::kPostLoad:
			Menu::Register();  // SKSE Menu Framework loads after us alphabetically, so register once everything is loaded
			break;
		case SKSE::MessagingInterface::kDataLoaded:
			Settings::OnDataLoaded();
			AutoPatch::OnDataLoaded();  // the animals other mods add: a report only, nothing is changed yet
			break;
		case SKSE::MessagingInterface::kPostLoadGame:
		case SKSE::MessagingInterface::kNewGame:
			Settings::OnGameLoaded();
			Animallica::Apply();  // after every other mod has edited the spawn lists
			Actions::ResetStartWatch();
			Actions::Queue(Actions::ActSmallGame | Actions::ActCorpDragons);  // the loot lists AutoPatch made are new every launch and not saved: fill them again (does nothing until Hunterborn is running)
			Actions::Hold(12.0f);  // let the game and Hunterborn's own load scripts settle before any queued work runs
			break;
		default:
			break;
		}
	}
}

SKSEPluginLoad(const SKSE::LoadInterface* a_skse)
{
	SKSE::Init(a_skse);
	SetupLog();
	SKSE::log::info("HunterbornNative.dll 0.6.0, game {}", REL::Module::get().version().string());
	SKSE::GetMessagingInterface()->RegisterListener(OnMessage);
	SKSE::GetPapyrusInterface()->Register(AutoPatch::RegisterPapyrus);
	return true;
}
