Scriptname _DS_HB_HiSBridge Hidden

; Hunting in Skyrim compatibility, moved out of _DS_HB_Actions by Hunterborn 2026 so that Actions loads without HiS installed.
; Code from Hunterborn SE MCM (Hazado), unchanged apart from the act. prefixes and the guards that skip the HiS stats until HiS has been started.

Function DisableHiSSkinning() global
	Quest HISStatsQuest1 = Game.GetFormFromFile(0x000356BD, "Hunting in Skyrim.esp") as Quest
	If !HISStatsQuest1 || !HISStatsQuest1.IsRunning()
		Return
	EndIf
	HISModOptionsScript HISModOptions = (HISStatsQuest1 as Quest) as HISModOptionsScript
	HISModOptions.HISRealisticSkinningEnabled.SetValue(0)
EndFunction

Function SkinAnimalHIS(_DS_HB_Actions act, Actor akActorRef, MiscObject skin) global

	;/	Compatibilty for Hunting in Skyrim
		Adds Double Skin perk from HiS
		Adds HiS Skinning XP and Skin tracking system
		Adds Option to use the Realistic skinning system
	/;
		

	Quest HISHBQuest = Game.GetFormFromFile(0x0013F719, "Hunting in Skyrim.esp") as Quest
	Quest HISStatsQuest1 = Game.GetFormFromFile(0x000356BD, "Hunting in Skyrim.esp") as Quest
	If HISHBQuest; Is Hunting in Skyrim (normal) present, and object 0x0013F719 available?
		If !HISHBQuest.IsRunning()
			HISHBQuest.Start()
		EndIf
		HISHBSkinningScript HISScript = (HISHBQuest as Quest) as HISHBSkinningScript
		If act.dsGlobals.gUseHiSCompatibility && HISStatsQuest1 && HISStatsQuest1.IsRunning()
			HISStatsNoteScript1 StatsScript = (HISStatsQuest1 as Quest) as HISStatsNoteScript1
			HISRealisticSkinningScript RealSkin = (HISStatsQuest1 as Quest) as HISRealisticSkinningScript
			HISModOptionsScript HISModOptions = (HISStatsQuest1 as Quest) as HISModOptionsScript
			
			DisableHiSSkinning()
			
			act.DebugMode("SkinCarcass akActorRef = " + akActorRef + " ; Actor Race = " + akActorRef.GetRace() + " ; HIS = " + HISHBQuest + " ; HISScript = " + HISScript + " ; StatsScript = " + StatsScript + " ; RealSkin = " + RealSkin + " ; ")

			If akActorRef.GetRace() == HISScript.BearBlackRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsBearCave)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.BearSnowRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsBearSnow)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.BearBrownRace || aKActorRef.GetFactionRank(act.BearFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsBear)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.CowRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsCow)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.DeerRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsDeer)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.ElkRace
				if akActorRef.GetActorBase().GetSex() == 0
					StatsScript.AnimalSkinned(RealSkin.HISSkinsElk)
				elseIf akActorRef.GetActorBase().GetSex() == 1
					StatsScript.AnimalSkinned(RealSkin.HISSkinsElkFem)
				else
					StatsScript.AnimalSkinned(RealSkin.HISSkinsElk)
				endIf
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.FoxRace
				if akActorRef.GetItemCount(RealSkin.FoxPelt) >= 1
					StatsScript.AnimalSkinned(RealSkin.HISSkinsFox)
				elseif akActorRef.GetItemCount(RealSkin.FoxPeltSnow) >= 1
					StatsScript.AnimalSkinned(RealSkin.HISSkinsFoxSnow)
				else
					StatsScript.AnimalSkinned(RealSkin.HISSkinsFox)
				endIf
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == (RealSkin.GoatRace || RealSkin.GoatDomesticsRace) || aKActorRef.GetFactionRank(act.GoatFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsGoat)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HareRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsHare)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HorkerRace || aKActorRef.GetFactionRank(act.HorkerFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsHorker)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HorseRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsHorse)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.MammothRace || aKActorRef.GetFactionRank(act.MammothFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsMammoth)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HISSabreCatBlackRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsSabreBlack)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.SabreCatSnowyRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsSabreSnow)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.SabreCatRace || aKActorRef.GetFactionRank(act.SabreCatFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsSabre)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.TrollFrostRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsTrollFrost)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == (RealSkin.TrollRace || RealSkin.HISTrollBossRace) || aKActorRef.GetFactionRank(act.TrollFaction) >= 0
				StatsScript.AnimalSkinned(RealSkin.HISSkinsTroll)
				if RealSkin.HISSkinDblEnable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HISWolfTimberRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsWolfTimber)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.HISWolfWhiteRace
				StatsScript.AnimalSkinned(RealSkin.HISSkinsWolfWhite)
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			elseIf akActorRef.GetRace() == HISScript.WolfRace || aKActorRef.GetFactionRank(act.WolfFaction) >= 0
				if akActorRef.GetItemCount(RealSkin.WolfPelt) >= 1
					StatsScript.AnimalSkinned(RealSkin.HISSkinsWolf)
				elseif akActorRef.GetItemCount(RealSkin.WolfIcePelt) >= 1
					StatsScript.AnimalSkinned(RealSkin.HISSkinsWolfIce)
				else
					StatsScript.AnimalSkinned(RealSkin.HISSkinsWolf)
				endIf
				if RealSkin.HISSkinDblLevel1Enable.value == 1
					act.PlayerRef.AddItem(skin, 1)
				endIf
			endif
				
			Float XP = RealSkin.GetSkinXPTotal(akActorRef)
			StatsScript.AddXP(XP, "skin")
			StatsScript.UpdateCraftingStats()
		EndIf
		If act.dsGlobals.gUseHiSTextures
			HISScript.SkinAnimalActual(akActorRef)
		EndIf
		Return
	EndIf

EndFunction
