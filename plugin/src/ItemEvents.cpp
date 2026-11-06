/*
 * Hunterborn 2026
 * Copyright (c) 2026 CageTV
 *
 * Released under the MIT License; see LICENSE.txt.
 */
#include "PCH.h"
#include "ItemEvents.h"
#include "HunterbornIds.h"

namespace
{
	constexpr const char* kHB = "Hunterborn.esp";

	// what _DS_HB_Player's item handlers test (its properties): kwHuntingKnife, kwPet, kwPetLure, kwSoup,
	// weapBoneDiviningKnife, flCarcassObjects (+ the monsters' carcass list)
	struct Watch
	{
		std::vector<RE::BGSKeyword*>  keywords;
		std::vector<RE::BGSListForm*> lists;
		RE::TESForm*                  divining = nullptr;
	} g_watch;

	RE::TESQuest*     g_quest = nullptr;    // _DS_Hunterborn (003367), the player alias carries _DS_HB_Player
	RE::VMHandle      g_handle = 0;         // that alias, once found
	bool              g_searched = false;
	std::atomic<long> g_forwarded{ 0 };

	template <class T>
	T* HB(unsigned a_local)
	{
		auto* dh = RE::TESDataHandler::GetSingleton();
		return dh ? dh->LookupForm<T>(HbIds::Fix(kHB, a_local), kHB) : nullptr;
	}

	bool Watched(RE::TESForm* a_base)
	{
		if (!a_base) return false;
		if (a_base == g_watch.divining) return true;
		for (auto* l : g_watch.lists)
			if (l->HasForm(a_base)) return true;
		if (auto* kf = a_base->As<RE::BGSKeywordForm>())
			for (auto* k : g_watch.keywords)
				if (kf->HasKeyword(k)) return true;
		return false;
	}

	// The player alias's script object: the alias of _DS_Hunterborn that has _DS_HB_Player bound.
	RE::VMHandle PlayerAliasHandle()
	{
		if (g_searched) return g_handle;
		auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
		if (!vm || !g_quest) return 0;
		auto* policy = vm->GetObjectHandlePolicy();
		for (auto* alias : g_quest->aliases) {
			if (!alias) continue;
			const auto h = policy->GetHandleForObject(RE::BGSRefAlias::VMTYPEID, alias);
			RE::BSTSmartPointer<RE::BSScript::Object> obj;
			if (h && vm->FindBoundObject(h, "_DS_HB_Player", obj) && obj) {
				g_handle = h;
				break;
			}
		}
		g_searched = g_handle != 0;   // not bound yet (very early in a new game): look again next time
		if (g_searched) SKSE::log::info("ItemEvents: player alias found, forwarding item events for Hunterborn's items only");
		return g_handle;
	}

	class Sink final : public RE::BSTEventSink<RE::TESContainerChangedEvent>
	{
	public:
		static Sink* Get()
		{
			static Sink s;
			return &s;
		}

		RE::BSEventNotifyControl ProcessEvent(const RE::TESContainerChangedEvent* a_e, RE::BSTEventSource<RE::TESContainerChangedEvent>*) override
		{
			if (!a_e) return RE::BSEventNotifyControl::kContinue;
			constexpr RE::FormID kPlayer = 0x14;
			const bool added = a_e->newContainer == kPlayer, removed = a_e->oldContainer == kPlayer;
			if (!added && !removed) return RE::BSEventNotifyControl::kContinue;
			auto* base = RE::TESForm::LookupByID(a_e->baseObj);
			if (!Watched(base)) return RE::BSEventNotifyControl::kContinue;   // everything else: no Papyrus at all

			const auto handle = PlayerAliasHandle();
			auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
			if (!handle || !vm) return RE::BSEventNotifyControl::kContinue;
			auto* item = a_e->reference.get().get();   // the dropped / picked-up reference, if there is one
			auto* other = RE::TESForm::LookupByID<RE::TESObjectREFR>(added ? a_e->oldContainer : a_e->newContainer);
			RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> none;
			auto* args = RE::MakeFunctionArguments(static_cast<RE::TESForm*>(base), static_cast<std::int32_t>(a_e->itemCount),
				static_cast<RE::TESObjectREFR*>(item), static_cast<RE::TESObjectREFR*>(other));
			vm->DispatchMethodCall(handle, "_DS_HB_Player", added ? "HB_ItemAdded" : "HB_ItemRemoved", args, none);
			if (++g_forwarded <= 5) SKSE::log::info("ItemEvents: {} {} x{} -> _DS_HB_Player", added ? "added" : "removed", base->GetName(), a_e->itemCount);
			return RE::BSEventNotifyControl::kContinue;
		}
	};
}

namespace ItemEvents
{
	void OnDataLoaded()
	{
		g_quest = HB<RE::TESQuest>(0x003367);
		for (unsigned id : { 0x01B47Fu, 0x0923C0u, 0x09C5CBu, 0x28CD32u })   // _DS_KW_HuntingKnife, _Pet, _PetLure, _Food_Soup
			if (auto* k = HB<RE::BGSKeyword>(id)) g_watch.keywords.push_back(k);
		for (unsigned id : { 0x006EB9u, 0x027771u })   // _DS_FL_CarcassObjects, _DS_FL_CarcassObjects_Monsters
			if (auto* l = HB<RE::BGSListForm>(id)) g_watch.lists.push_back(l);
		g_watch.divining = HB<RE::TESObjectWEAP>(0x0D925A);   // _DS_Misc_BoneDiviningKnife (a WEAP: the typed lookup returns nothing for plain TESForm)
		if (auto* src = RE::ScriptEventSourceHolder::GetSingleton()) src->AddEventSink<RE::TESContainerChangedEvent>(Sink::Get());
		SKSE::log::info("ItemEvents: watching {} keywords, {} carcass lists{}{} (quest {})", g_watch.keywords.size(), g_watch.lists.size(),
			g_watch.divining ? ", the Bone Divining Knife" : "", HbIds::LightEdition() ? " - ESL edition ids" : "", g_quest ? "found" : "NOT FOUND");
	}
}
