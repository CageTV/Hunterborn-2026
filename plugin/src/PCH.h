/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#pragma once

#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>

#include <spdlog/sinks/basic_file_sink.h>

#include <Windows.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <format>
#include <fstream>
#include <map>
#include <mutex>
#include <sstream>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

using namespace std::literals;

// One on-screen message, whichever way this CommonLib spells it.
inline void Notify(const char* a_text)
{
#if __has_include(<RE/S/SendHUDMessage.h>)
	RE::SendHUDMessage::ShowHUDMessage(a_text);
#else
	RE::DebugNotification(a_text);
#endif
}
