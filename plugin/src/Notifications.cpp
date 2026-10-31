/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "HunterbornIds.h"
#include "Notifications.h"

namespace Notifications
{
	namespace
	{
		constexpr const char* kPlugin = "Hunterborn.esp";

#include "Notifications.inc"

		struct Saved
		{
			RE::BGSMessage* message;
			bool            box;
			std::uint32_t   time;
		};

		std::mutex         mu;
		std::vector<Saved> saved;  // what each message was before, so it can be put back
		bool               applied = false;
	}

	int Count() { return static_cast<int>(std::size(kNotes)); }

	bool Applied()
	{
		std::lock_guard lock(mu);
		return applied;
	}

	void Apply(bool a_on)
	{
		std::lock_guard lock(mu);
		auto*           dh = RE::TESDataHandler::GetSingleton();
		if (!dh || !dh->LookupModByName(kPlugin)) {
			return;
		}
		if (a_on) {
			if (applied) {
				return;
			}
			saved.clear();
			int changed = 0;
			for (const auto& n : kNotes) {
				auto* msg = dh->LookupForm<RE::BGSMessage>(HbIds::Fix(kPlugin, n.local), kPlugin);
				if (!msg) {
					continue;
				}
				saved.push_back({ msg, msg->flags.any(RE::BGSMessage::MessageFlag::kMessageBox), msg->displayTime });
				if (n.dropBox) {
					msg->flags.reset(RE::BGSMessage::MessageFlag::kMessageBox);
				}
				if (n.time > 0) {
					msg->displayTime = static_cast<std::uint32_t>(n.time);
				}
				++changed;
			}
			applied = true;
			SKSE::log::info("Messages as notifications: {} of {} messages converted", changed, std::size(kNotes));
		} else {
			if (!applied) {
				return;
			}
			for (const auto& s : saved) {
				if (s.box) {
					s.message->flags.set(RE::BGSMessage::MessageFlag::kMessageBox);
				} else {
					s.message->flags.reset(RE::BGSMessage::MessageFlag::kMessageBox);
				}
				s.message->displayTime = s.time;
			}
			saved.clear();
			applied = false;
			SKSE::log::info("Messages as notifications: put back");
		}
	}
}
