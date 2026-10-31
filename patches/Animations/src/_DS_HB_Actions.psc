; Hunterborn 2026 - Animations patch. Hunterborn Animations (Nexus 80677) by Elsawirr (animations) and GiraPomba (scripts) is the source of the animation calls
; in this script; the author allows modifying the files with credit, and asks that patches require the mod. Merged with Hunterborn 2026's version (Hunting in Skyrim bridge kept).
; Needs Hunterborn - Animations installed (the animation calls look its quest up at run time and do nothing without it).
Scriptname _DS_HB_Actions extends Quest  

Import Debug
			 
; PROPERTIES --------------------------------------------------------------------------------------

Actor Property PlayerRef Auto

_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Monsters Property dsMonsters Auto
_DS_HB_Globals Property dsGlobals Auto
_GP_HB_AnimFunctions Property gpAnimFunctions Auto Hidden


GlobalVariable Property gGameTime Auto

ImageSpaceModifier Property ismFadeIn Auto
ImageSpaceModifier Property ismFadeOut Auto
ImageSpaceModifier Property ismBlack Auto

Message Property MsgBoxNoHuntingKnife Auto
Message Property MsgBoxSkinCritFail Auto
Message Property MsgBoxSkinCritFail2 Auto
Message Property MsgBoxSkinLevelUp Auto
Message Property MsgBoxHarvestCritFail Auto
Message Property MsgBoxHarvestCritFail2 Auto
Message Property MsgBoxHarvestLevelUp Auto
Message Property MsgBoxFinishSkinSection Auto
Message Property MsgBoxFinishButcherSection Auto
Message Property MsgBoxBoneKnifeBroken Auto
Message Property MsgSpiritAppears Auto
Message Property MsgGoatAteRocks Auto
Message Property MsgVenomFail Auto

MiscObject Property moPeltRuined Auto
MiscObject Property moTokenPelt Auto
MiscObject Property moTokenMat Auto
MiscObject Property moTokenMeat Auto
MiscObject Property moTokenMeat_Fresh Auto
MiscObject Property moTokenVenom Auto
MiscObject Property moTokenBlood Auto
Keyword Property kwAnimalHide Auto

LeveledItem Property liAggregator Auto

FormList Property flHuntingKnives Auto
FormList Property flHkefLists Auto
FormList Property flSkinBonuses Auto
FormList Property flHarvestBonuses Auto
MiscObject Property moSharpRock Auto
Weapon Property weapKnifeBone Auto
Keyword Property kwHuntingKnife Auto
Keyword Property kwHkDoubleHarvest Auto
Keyword Property kwHkDoubleMeat Auto
Keyword Property kwHkCurseOfEbony Auto
Keyword Property kwHkCurseOfDaedra Auto

;Race Property KhajiitRace Auto
;Race Property KhajiitVampireRace Auto
;Race Property ArgonianRace Auto
;Race Property ArgonianVampireRace Auto
FormList Property flClawRaces Auto
Race Property WerewolfRace Auto
Race Property BearBlackRace Auto
Race Property BearBrownRace Auto
Race Property BearSnowRace Auto
Race Property CartHorseRace Auto
Race Property CowRace Auto
Race Property DeerRace Auto
Race Property ElkRace Auto
Race Property FoxRace Auto
Race Property GoatDomesticsRace Auto
Race Property GoatRace Auto
Race Property HareRace Auto
Race Property HISSabreCatBlackRace Auto
Race Property HISTrollBossRace Auto
Race Property HISWolfTimberRace Auto
Race Property HISWolfWhiteRace Auto
Race Property HorkerRace Auto
Race Property HorseRace Auto
Race Property MammothRace Auto
Race Property SabreCatRace Auto
Race Property SabreCatSnowyRace Auto
Race Property TrollFrostRace Auto
Race Property TrollRace Auto
Race Property WolfRace Auto								
						   

Spell Property spellSummonEbonySpirit Auto
Spell Property spellSummonDaedricSpirit Auto
Spell Property spellVenomFail Auto

MagicEffect Property mgefHarvester Auto
MagicEffect Property mgefStrangeBrew Auto

Idle Property idleCarcassAnim Auto
Idle Property idleVenomAnim Auto
Idle Property idleBloodAnim Auto
Idle Property idleSearchAnim Auto
Idle Property idle_Stop Auto

ObjectReference Property SpawnMarker Auto
ActorBase Property ContainerWolf Auto
ObjectReference Property Dumpster Auto
ObjectReference Property MeatGrinder Auto

Armor Property HISSkinnedBearSkinAll Auto
Armor Property HISSkinnedCowSkinAll Auto
Armor Property HISSkinnedDeerSkinAll Auto
Armor Property HISSkinnedElkSkinAll Auto
Armor Property HISSkinnedFoxSkinAll Auto
Armor Property HISSkinnedGoatSkinAll Auto
Armor Property HISSkinnedHorkerSkinAll Auto
Armor Property HISSkinnedHorseSkinAll Auto
Armor Property HISSkinnedMammothSkinAll Auto
Armor Property HISSkinnedRabbitSkinAll Auto
Armor Property HISSkinnedSabreSkinAll Auto
Armor Property HISSkinnedTrollSkinAll Auto
Armor Property HISSkinnedWolfSkinAll Auto											 
MiscObject Property AnimalFat Auto

Keyword Property kwRiteRing Auto
FormList Property flRiteBones Auto
; CK props will make these ref's persistent. Otherwise IsNearPlayer won't work on them.
; They will show up in Tes5Edit, but should be considered "clean".
; An array makes them easier to manage (via CK UI) than a FormList.
ObjectReference[] Property RiteRingSites Auto

Potion Property foodWatermelon Auto
Ingredient Property ingrMoonMoonSugar Auto

ObjectReference Property CurrentCarcass Auto Hidden
Potion Property CurrentMeatType Auto Hidden

faction property BearFaction auto
faction property GoatFaction auto
faction property HorkerFaction auto
faction property MammothFaction auto
faction property SabreCatFaction auto
faction property TrollFaction auto
faction property WolfFaction auto


; PRIVATE VARIABLES -------------------------------------------------------------------------------

int		_KNIFE_IRON			= 2
int		_KNIFE_BONE			= 1
int		_KNIFE_STONE		= 0
int		_KNIFE_NONE			= -1
int		_KNIFE_CLAWS		= -3
int		_KNIFE_SHARPROCK	= -4

Bool doSkipAnim

; FUNCTIONS ---------------------------------------------------------------------------------------


; -- FieldDress
;
; Change the body on the ground into a "prepared" version which can be harvested.
;
Function FieldDress(Actor akCarcassRef, int aiIndex)

	int knife = GetHuntingKnife()
	
	DebugMode("FieldDress akCarcassRef = " + akCarcassRef + " ; aiIndex = " + aiIndex + " ; knife = " + knife)
	
	; -- GP
	; Checks for arrows stuck on the carcass
	gpAnimFunctions.CheckForArrows(akCarcassRef, liAggregator)
																			  
							   
	; Performs animation
	If dsGlobals.gUseAnimation
		gpAnimFunctions.DoAnim(1, akCarcassRef, aiIndex)
	EndIf
	
	; A comment explaining why the heck wolves can drop these things really belongs here. -- unuroboros
	If dsAnimals.AnimalIndex[aiIndex] == "Wolf" && PlayerRef.HasMagicEffect(mgefStrangeBrew)
		If Utility.RandomInt() > 75
			PlayerRef.AddItem(foodWatermelon)
		EndIf
		If Utility.RandomInt() > 50
			PlayerRef.AddItem(ingrMoonMoonSugar)
		EndIf
	EndIf
	; Those derpy wolves...
	
	If (dsGlobals.gDressTimed)
		float time = GetDressTime(aiIndex, knife)
		time = time * dsGlobals.gAlterTime
		FadeToBlack()
		AdvanceGameTime(time)
	EndIf

	; Increment Total Cleans.
	dsGlobals.gTotalCleans += 1

	If (dsGlobals.gDressTimed)
		FadeFromBlack()
	EndIf
	
	;
	; Convert carcass inventory for skinning / harvesting / butchering.
	;

	
	; First remove the original inventory, so it doesn't interfere with functions.
	;
	int i
	Form f
	If (!dsGlobals.gUseCustomPelts && !dsGlobals.gUseCustomMats && !dsGlobals.gUseCustomMeats)
		; "Custom textures" are really just equipped armor. Need to avoid removing them.
		If (dsGlobals.gUseCustomTextures)
			i = akCarcassRef.GetNumItems()
			While (i)
				i -= 1
				f = akCarcassRef.GetNthForm(i)
				;MessageBox(f.GetName() + " = " + f.GetType())
				If (!f.HasKeyword(dsAnimals.kwDeathItemToken) && f.GetType() != 26) ; Armor
					DebugMode("(UseCustomTextures) Removing " + f.GetName())
					akCarcassRef.RemoveItem(f, akCarcassRef.GetItemCount(f))
				EndIf
			EndWhile
		Else
			DebugMode("Removing all items")
			akCarcassRef.RemoveAllItems()
		EndIf
	ElseIf (!dsGlobals.gUseCustomMeats)
		DebugMode("Removing meat only")
		akCarcassRef.RemoveItem(dsAnimals.flDefaultMeats, akCarcassRef.GetItemCount(dsAnimals.flDefaultMeats))
	EndIf
	akCarcassRef.RemoveItem(dsAnimals.moTokenCarcass_Fresh)
	
	; Now add back the Hunterborn "token" items.
	;
	; AddItem with a LeveledItem will (Skyrim hard-coded?) reset armor. The LI needs to be added one item at a time if gUseCustomTextures.
	; Iterating over inventory requires SKSE GetNumItems, which needs an ObjectReference... hence, ContainerWolf!
	
	If (dsGlobals.gUseCustomTextures)
		Actor a = SpawnMarker.PlaceActorAtMe(ContainerWolf)
		DebugMode("(UseCustomTextures) Adding death item " + dsAnimals.DeathItemLI[aiIndex])
		a.AddItem(dsAnimals.DeathItemLI[aiIndex])
		; RemoveAllItems() to pass to a destination container won't work with "hidden" items, which most HB tokens are.
		i = a.GetNumItems()
		While (i)
			i -= 1
			f = a.GetNthForm(i)
			DebugMode("(UseCustomTextures) Removing " + f.GetName())
			a.RemoveItem(f, a.GetItemCount(f), False, akCarcassRef)
		EndWhile
		a.Disable()
		a.Delete()
	Else
		DebugMode("Adding death item " + dsAnimals.DeathItemLI[aiIndex])
		akCarcassRef.AddItem(dsAnimals.DeathItemLI[aiIndex])
	EndIf
	
	;
	; Finished converting inventory.
	;
	
EndFunction

; -- ProcessCarcass
;
; Combines all of the actions below: Skin, Harvest, Butcher.
; This doesn't save the character any time, just removes some repetitive button clicking.
;
Function ProcessCarcass(Actor akCarcassRef, bool abIsMonster = False)

	bool doSkin = akCarcassRef.GetItemCount(moTokenPelt) > 0
	bool doHarvest = akCarcassRef.GetItemCount(moTokenMat) > 0
	bool doButcher = akCarcassRef.GetItemCount(moTokenMeat) > 0
	dsGlobals.gMonsterHasVenom = akCarcassRef.GetItemCount(moTokenVenom) > 0
	dsGlobals.gMonsterHasBlood = akCarcassRef.GetItemCount(moTokenBlood) > 0
	
	DebugMode("ProcessCarcass akCarcassRef = " + akCarcassRef + " ; doSkin = " + doSkin + " ; doHarvest = " + doHarvest + " ; doButcher = " + doButcher + ";dsGlobals.gMonsterHasVenom = " + dsGlobals.gMonsterHasVenom + "; dsGlobals.gMonsterHasBlood = " + dsGlobals.gMonsterHasBlood)
	
	If (!doSkin && !doHarvest && !doButcher && !abIsMonster)
		If dsGlobals.gUseAnimation	
			gpAnimFunctions.StandUp(2)
		EndIf	
		akCarcassRef.SetCriticalStage(akCarcassRef.CritStage_DisintegrateEnd)
		Return
	ElseIf (!doSkin && !doHarvest && !doButcher && !dsGlobals.gMonsterHasVenom && !dsGlobals.gMonsterHasBlood && CheckPlayableInventory(akCarcassRef))
		SearchTreasure(akCarcassRef)
		Return
	ElseIf (abIsMonster && !doSkin && !doHarvest && !doButcher && !dsGlobals.gMonsterHasVenom && !dsGlobals.gMonsterHasBlood && !CheckPlayableInventory(akCarcassRef) && dsGlobals.gMonsterCanDispose)
		If dsGlobals.gUseAnimation	
			gpAnimFunctions.StandUp(2)
		EndIf	
		akCarcassRef.SetCriticalStage(akCarcassRef.CritStage_DisintegrateEnd)
		Return	
	EndIf
	
	int knife = GetHuntingKnife()
	int index = GetCarcassIndex(akCarcassRef, abIsMonster)
	
	DebugMode("knife = " + knife + " ; index = " + index)

	; Calc needed before anim
	bool firstcut
	int meatcount
	int section
	float time
	If (doButcher)
		bool simple_loot = dsGlobals.gUseCustomMeats
		bool combined_loot = dsGlobals.gUseCustomMeats && dsGlobals.gUseCombinedCustomMeats
		firstcut = akCarcassRef.GetItemCount(moTokenMeat_Fresh) > 0
		Potion meattype = GetMeatType(index, abIsMonster)
		float meatweight = meattype.GetWeight()
		If ( (simple_loot && !combined_loot) || !meattype )
			ButcherPrep_Simple(akCarcassRef)
			section = 0
			meattype = None
			If (dsGlobals.gButcherTimed)
				time += GetButcherTime(-1, knife)
			EndIf
		Else
			meatcount = ButcherPrep_MeatCount(akCarcassRef, firstcut, meattype, index, abIsMonster)
			;float meatweight = dsAnimals.AllMeatWeights[index]
			int totalweight = Math.Ceiling(meatweight * meatcount)
			float butcherpenalty = GetStandardPenalty(knife, 15)
			int totalpenalty = Math.Floor(butcherpenalty)
			totalpenalty += Utility.RandomInt(0, 15)
			int limit = 100 - totalpenalty
			section = ButcherPrep_SectionSize(totalweight, limit, knife)
			If (dsGlobals.gButcherTimed)
				butcherpenalty += ButcherPrep_SectionTime(totalweight, limit, knife, section)
				time += butcherpenalty / 60
			EndIf
		EndIf
	EndIf
	
	; -- GP --
	; More than one action is being processed, plays an animation that's a combination of skinning and butchering and do all actions in one go. Otherwise plays the first animation found.
	If doSkin && (doHarvest || doButcher) || (doHarvest && doButcher)
		If dsGlobals.gUseAnimation
			If doButcher
				gpAnimFunctions.fHuntingMaterial = GetMeatType(index, False) ; Gets type of meat here
			ElseIf doHarvest
				gpAnimFunctions.fHuntingMaterial = (GetMatList(index, False).GetAt(0) as LeveledItem).GetNthForm(0) ; Gets the first item from the first leveled list available for the carcass
			EndIf
			gpAnimFunctions.DoAnim(isProcess = True)
		EndIf
		doSkipAnim = True
	EndIf
	
	If (doSkin && dsGlobals.gSkinTimed)
		time += GetSkinTime(index, knife, abIsMonster)
	EndIf
	
	If (doHarvest && dsGlobals.gHarvestTimed)
		time += GetHarvestTime(index, knife, abIsMonster)
	EndIf
	    
	If (doSkin)
		SkinCarcass(akCarcassRef, abIsMonster, True, knife, index)
		doSkipAnim = True
	EndIf
	
	If (doHarvest)
		HarvestCarcass(akCarcassRef, abIsMonster, True, knife, index)
		doSkipAnim = True
	EndIf
	
	If (doButcher)
		ButcherCarcass(akCarcassRef, abIsMonster, True, knife, index, firstcut, meatcount, section)
		doSkipAnim = True
	EndIf
	
	If (dsGlobals.gMonsterHasVenom)
		ExtractVenom(akCarcassRef, True)
	EndIf
	
	If (dsGlobals.gMonsterHasBlood)
		ExtractBlood(akCarcassRef, True)
	EndIf
	
	If (time > 0)
		time = time * dsGlobals.gAlterTime
		FadeToBlack()
		AdvanceGameTime(time)
		FadeFromBlack()
	EndIf
	
	doSkipAnim = False			   
 
	DegradeHuntingKnife(knife)

EndFunction

; -- SkinCarcass
;
Function SkinCarcass(Actor akCarcassRef, bool abIsMonster, bool abPartOfProcess = False, int aiKnife = -1, int aiIndex = 0)

	DebugMode("SkinCarcass akCarcassRef = " + akCarcassRef + " ; abIsMonster = " + abIsMonster + " ; abPartOfProcess = " + abPartOfProcess + " ; aiKnife = " + aiKnife + " ; aiIndex = " + aiIndex)

	bool simple_loot = dsGlobals.gUseCustomPelts
	bool combined_loot = dsGlobals.gUseCustomPelts && dsGlobals.gUseCombinedCustomPelts
	
	DebugMode("simple_loot = " + simple_loot + "; combined_loot = " + combined_loot)

	; Determine which knife is used to skin.
	; Which animal is this?
	;
	int knife = aiKnife
	int index = aiIndex
	If (!abPartOfProcess)
		knife = GetHuntingKnife()
		if (knife == _KNIFE_NONE && (!simple_loot || combined_loot))
			int button = MsgBoxNoHuntingKnife.Show()
			if (button != 0)
				Return
			EndIf
		EndIf
		index = GetCarcassIndex(akCarcassRef, abIsMonster)
		DebugMode("knife = " + knife + " ; index = " + index)
	EndIf

	; Setup...
	;
	FormList peltlist = GetPeltList(index, abIsMonster)
	DebugMode("peltlist = " + peltlist)
	int peltcount
	MiscObject skin
	int skinlevel
	bool critfail
	bool levelup

	; Stock, or enumerate remaining, pelts on the carcass
	;
	If (!simple_loot || combined_loot)
		peltcount = akCarcassRef.GetItemCount(moTokenPelt)
		DebugMode("peltcount = " + peltcount)
	EndIf
	
	; -- GP --
	If abIsMonster && !doSkipAnim
		; Checks for arrows stuck in the carcass.
		gpAnimFunctions.CheckForArrows(akCarcassRef, liAggregator)
	EndIf
		
	;
	; Calculate results
	;
	
	; Determine the skinning bonus
	;
	skinlevel = dsGlobals.gSkinLevel
	int skillbonus = (skinlevel * 10) + dsGlobals.gTotalCleans
	int knifebonus = GetHuntingKnifeSkinBonus(knife)
	int bonus = skillbonus + knifebonus
	
	; Make a roll...
	;
	int baseroll = Utility.RandomInt()
	int totalroll = baseroll + bonus
	DebugMode("baseroll = " + baseroll + " ; totalroll = " + totalroll)
	critfail = baseroll == 0
	bool perfect = skinlevel == 10 && baseroll >= 90
	
	; Experience / level up
	;
	levelup = False
	If (skinlevel < 10)
		int skinexp = dsGlobals.gSkinExp
		skinexp += baseroll
		If ( \
			(skinlevel == 0 && skinexp > 99) || \
			(skinlevel == 1 && skinexp > 299) || \
			(skinlevel == 2 && skinexp > 599) || \
			(skinlevel == 3 && skinexp > 799) || \
			(skinlevel == 4 && skinexp > 999) || \
			(skinlevel == 5 && skinexp > 1349) || \
			(skinlevel == 6 && skinexp > 1849) || \
			(skinlevel == 7 && skinexp > 2499) || \
			(skinlevel == 8 && skinexp > 3499) || \
			(skinlevel == 9 && skinexp > 4999) \
		)
			levelup = True
		ElseIf (skinlevel == 10)
			skinexp = 5000 ; cap to prevent wrapping
		EndIf
		dsGlobals.gSkinExp = skinexp
	EndIf
		
	; Quality of pelt
	if (critfail || totalroll < 51)
		skin = moPeltRuined
	; Perfect
	ElseIf perfect && peltlist.GetSize() > 4 && knifebonus > 20
		DebugMode("Perfect skinning result!")
		skin = peltlist.GetAt(4) as MiscObject
	; Poor
	ElseIf (totalroll < 101)
		skin = peltlist.GetAt(0) as MiscObject
	; Normal
	ElseIf (totalroll < 171)
		skin = peltlist.GetAt(1) as MiscObject
	; Flawless
	ElseIf (skinlevel > 8 && peltlist.GetSize() > 3 && knifebonus > 20 && baseroll > 96)
		skin = peltlist.GetAt(3) as MiscObject
	ElseIf (skinlevel > 9 && peltlist.GetSize() > 3 && knifebonus > 20 && baseroll > 90)
		skin = peltlist.GetAt(3) as MiscObject
	; Fine
	Else
		skin = peltlist.GetAt(2) as MiscObject
	EndIf
	DebugMode("skin = " + skin)
	
	; -- GP --
	If dsGlobals.gUseAnimation
		If !doSkipAnim 
			gpAnimFunctions.DoAnim(2, akCarcassRef, index, abIsMonster, critfail)
		EndIf
	EndIf
	
	If (!abPartOfProcess)
		  
		if (dsGlobals.gSkinTimed)
			float time = GetSkinTime(index, knife, abIsMonster)
			time = time * dsGlobals.gAlterTime
			FadeToBlack()
			AdvanceGameTime(time)
			FadeFromBlack()
		EndIf
	EndIf
 
						 
	SkinAnimalHIS(akCarcassRef, skin)
	
	;
	; Finished calculating
	;
	
	; Must defer any MessageBox's for after FadeFromBlack

	If (peltcount > 1)
		MsgBoxFinishSkinSection.Show()
	EndIf	
	If (critfail)
		if (knife > _KNIFE_NONE)
			MsgBoxSkinCritFail2.Show()
		Else
			MsgBoxSkinCritFail.Show()
		EndIf
	ElseIf (levelup)
		MsgBoxSkinLevelUp.Show()
		dsGlobals.gSkinLevel = skinlevel + 1
	EndIf
	
	; Special results (summons)
	;
	If (GetHkKw(knife, kwHkCurseOfEbony) && Utility.RandomInt() < 10)
		DebugMode("Ebony spirit summoned!")
		MsgSpiritAppears.Show()
		spellSummonEbonySpirit.Cast(PlayerRef)
	ElseIf (GetHkKw(knife, kwHkCurseOfDaedra) && Utility.RandomInt() < 5)
		DebugMode("Daedric spirit summoned!")
		MsgSpiritAppears.Show()
		spellSummonDaedricSpirit.Cast(PlayerRef)
	EndIf

	; Give player skin(s)
	;
	int count
	If (simple_loot)
		int n = akCarcassRef.GetNumItems()
		Form f
		While (n)
			n -= 1
			f = akCarcassRef.GetNthForm(n)
			If (f.HasKeyword(kwAnimalHide))
				count = akCarcassRef.GetItemCount(f)
				DebugMode("(simple_loot) Giving player " + f.GetName() + " x " + count)
				PlayerRef.AddItem(f, count)
				akCarcassRef.RemoveItem(f, count)
			EndIf
		EndWhile
	EndIf
	If (!simple_loot || combined_loot)
		count = 1
		; Chance for double with the malachite knife is a flat 50%.
		if (GetHkKw(knife, kwHkDoubleHarvest) && Utility.RandomInt() > 50)
			count = 2
		EndIf
		DebugMode("Giving player " + skin + " x " + count)
		; -- GP --
		; Sets pelt model next to the player
		If dsGlobals.gUseAnimation && gpAnimFunctions._GP_HunterbornAnim_PeltDisplay.GetValue() && PlayerRef.GetAnimationVariableBool("bAnimationDriven") && skin != moPeltRuined
			If abIsMonster
				index += 100
			EndIf
			gpAnimFunctions.fHuntingMaterial = skin
			gpAnimFunctions.iPeltCount += count
			gpAnimFunctions.CreateDisplay(7, "HuntingPelt", index)
			gpAnimFunctions.EnableDisplay("HuntingPelt")
		Else
			PlayerRef.AddItem(skin, count)
		EndIf
	EndIf

	; Degrade knife
	;
	If (!abPartOfProcess)
		DegradeHuntingKnife(knife)
	EndIf

	; Mark off skinning as done
	;
	akCarcassRef.RemoveItem(moTokenPelt)
	
EndFunction

Function DisableHiSSkinning()
	_DS_HB_HiSBridge.DisableHiSSkinning()
EndFunction


Function SkinAnimalHIS(Actor akActorRef, MiscObject skin)
	_DS_HB_HiSBridge.SkinAnimalHIS(self, akActorRef, skin)
EndFunction

; -- HarvestCarcass
;
Function HarvestCarcass(Actor akCarcassRef, bool abIsMonster, bool abPartOfProcess = False, int aiKnife = -1, int aiIndex = 0)

	DebugMode("HarvestCarcass akCarcassRef = " + akCarcassRef + " ; abIsMonster = " + abIsMonster + " ; abPartOfProcess = " + abPartOfProcess + " ; aiKnife = " + aiKnife + " ; aiIndex = " + aiIndex)

	bool simple_loot = dsGlobals.gUseCustomMats
	bool combined_loot = dsGlobals.gUseCustomMats && dsGlobals.gUseCombinedCustomMats

	DebugMode("simple_loot = " + simple_loot + "; combined_loot = " + combined_loot)

	; Determine which knife is used to harvest.
	; Which animal is this?
	;
	int knife = aiKnife
	int index = aiIndex
	If (!abPartOfProcess)
		knife = GetHuntingKnife()
		If (knife == _KNIFE_NONE && (!simple_loot || combined_loot))
			int button = MsgBoxNoHuntingKnife.Show()
			If (button != 0)
				Return
			EndIf
		EndIf
		index = GetCarcassIndex(akCarcassRef, abIsMonster)
		DebugMode("knife = " + knife + " ; index = " + index)
	EndIf

	; Setup...
	;
	liAggregator.Revert()
	FormList matlist = GetMatList(index, abIsMonster)
	DebugMode("matlist = " + matlist)
	LeveledItem mats
	int harvestlevel
	int skillbonus
	int totalroll
	bool critfail
	bool levelup
	bool goatrocks
	
	;
	; Calculate results
	;
	
	; Determine the harvesting bonus
	;
	harvestlevel = dsGlobals.gHarvestLevel
	skillbonus = (harvestlevel * 5) + dsGlobals.gTotalCleans
	int knifebonus = GetHuntingKnifeHarvestBonus(knife)
	int bonus = skillbonus + knifebonus
	
	; Make a roll...
	;
	int baseroll = Utility.RandomInt()
	totalroll = baseroll + bonus
	DebugMode("baseroll = " + baseroll + " ; totalroll = " + totalroll)
	critfail = baseroll == 0
	bool perfect = harvestlevel == 10 && baseroll >= 90
	
	; Experience / level up
	;
	levelup = False
	If (harvestlevel < 10)
		int harvestexp = dsGlobals.gHarvestExp
		harvestexp += baseroll
		If ( \
			(harvestlevel == 0 && harvestexp > 99) || \
			(harvestlevel == 1 && harvestexp > 599) || \
			(harvestlevel == 2 && harvestexp > 999) || \
			(harvestlevel == 3 && harvestexp > 1499) || \
			(harvestlevel == 4 && harvestexp > 1999) || \
			(harvestlevel == 5 && harvestexp > 2699) || \
			(harvestlevel == 6 && harvestexp > 3599) || \
			(harvestlevel == 7 && harvestexp > 4699) || \
			(harvestlevel == 8 && harvestexp > 5999) || \
			(harvestlevel == 9 && harvestexp > 7499) \
		)
			levelup = True
		EndIf
		dsGlobals.gHarvestExp = harvestexp
	EndIf
		
	If (simple_loot && !combined_loot)
		; No calculation, using whatever is on the carcass right now.
	Else
		; Quality of mats
		;
		If (critfail)
			; Nothing, absolutely nothing!
		ElseIf (totalroll < 51)
			mats = matlist.GetAt(0) as LeveledItem
		ElseIf (totalroll < 121)
			mats = matlist.GetAt(1) as LeveledItem
		Else
			mats = matlist.GetAt(2) as LeveledItem
		EndIf
		; Rocks in a goat stomach
		goatrocks = !abIsMonster && dsAnimals.AnimalIndex[index] == "Goat" && baseroll > 95
	EndIf
	DebugMode("mats = " + mats)
	
	;
	; Finished calculating
	;
	
	; -- GP --
	; Changed order of messages and fade to black because of the new animations
	If !critfail ; Calculate materials if it's not a critical failure
 
		; Give player mats
		;
		int count
		If (simple_loot)
			int n = akCarcassRef.GetNumItems()
			Ingredient ing
			While (n)
				n -= 1
				ing = akCarcassRef.GetNthForm(n) as Ingredient
				If (ing)
					count = akCarcassRef.GetItemCount(ing)
					DebugMode("(simple_loot) Adding " + ing.GetName() + " x " + count)
					liAggregator.AddForm(ing, 1, count)
					akCarcassRef.RemoveItem(ing, count)
				EndIf
			EndWhile
		EndIf
		
		If (!simple_loot || combined_loot)
			count = 1
			; Chance for double with the malachite knife is a flat 50%.
			If (GetHkKw(knife, kwHkDoubleHarvest) && Utility.RandomInt() > 50)
				count += 1
			EndIf
			If (PlayerRef.HasMagicEffect(mgefHarvester) && Utility.RandomInt() > 85)
				count += 1
			EndIf
			DebugMode("Adding mats (" + mats + ") x " + count)
			liAggregator.AddForm(mats, 1, count)
			; Additional mats from MCM option.
			count = dsGlobals.gMatAmount + 1
			mats = matlist.GetAt(3) as LeveledItem
			DebugMode("Adding addtl mats (" + mats + ") x " + count)
			liAggregator.AddForm(mats, 1, count)
			; Animal fat
			; -> Moved to Butchering in 1.6 / SE
			; "High level" mats.
			If (harvestlevel > 3 && matlist.GetSize() > 4)
				count = 0
				baseroll = Utility.RandomInt()
				totalroll = baseroll + skillbonus
				If (totalroll > 150)
					count = 2
				ElseIf (totalroll > 100)
					count = 1
				EndIf
				mats = matlist.GetAt(4) as LeveledItem
				DebugMode("Adding hi mats (" + mats + ") x " + count)
				liAggregator.AddForm(mats, 1, count)
				; "Strange" mats.
				If (baseroll > 96 && matlist.GetSize() > 5)
					mats = matlist.GetAt(5) as LeveledItem
					DebugMode("Adding strange mats (" + mats + ")")
					liAggregator.AddForm(mats, 1, 1)
				EndIf
			EndIf
			; Ritual bones
			If (PlayerRef.HasMagicEffectWithKeyword(kwRiteRing))
				int ring = dsGlobals.gRiteRing_Wearing
				If (ring > -1)
					ObjectReference site = RiteRingSites[ring]
					DebugMode("Checking for ritual site " + site)
					If (site.IsNearPlayer())
						MiscObject bone = flRiteBones.GetAt(ring) as MiscObject
						If (PlayerRef.GetItemCount(bone) == 0)
							DebugMode("Adding ritual bone " + bone)
							liAggregator.AddForm(bone, 1, 1)
						EndIf
					EndIf
				EndIf
			EndIf
			; "Perfect" mats
			If perfect
				 mats = GetPerfectMats(index, abIsMonster)
				 If mats
					DebugMode("Adding perfect mats (" + mats + ")")
					liAggregator.AddForm(mats, 1, 1)
				EndIf
			EndIf
		EndIf
		; -- GP --
		; Calls function to determine harvested material
		If !doSkipAnim 
			If goatrocks ; If goat has a rock, use it instead
				gpAnimFunctions.CheckforMats(dsAnimals.liGoatRocks)
			Else ; else, searchs for mats in the LeveledItem list
				gpAnimFunctions.CheckforMats(liAggregator)
			EndIf
		EndIf
	EndIf
	
	; -- GP --
	; Anim triggers after knowing the material list/crit fail.
	If dsGlobals.gUseAnimation
		If !doSkipAnim 
			gpAnimFunctions.DoAnim(3, akCarcassRef, index, abIsMonster, critfail)
		EndIf
	EndIf
	
	If (!abPartOfProcess)
		If (dsGlobals.gHarvestTimed)
			float time = GetHarvestTime(index, knife, abIsMonster)
			time = time * dsGlobals.gAlterTime
			FadeToBlack()
			AdvanceGameTime(time)
			FadeFromBlack()
		EndIf
		
	EndIf
	
	; -- GP --
	; ----- Moved some messages here
	If critfail
		If (knife > -1)
			MsgBoxHarvestCritFail2.Show()
		Else
			MsgBoxHarvestCritFail.Show()
		EndIf
	Else
		If (levelup)
			MsgBoxHarvestLevelUp.Show()
			dsGlobals.gHarvestLevel = harvestlevel + 1
		EndIf
		
		; Clarify why rocks are mats
		If (goatrocks)
			liAggregator.AddForm(dsAnimals.liGoatRocks, 1, 1)
			MsgGoatAteRocks.Show()
		EndIf
		
		; Special results
		If (GetHkKw(knife, kwHkCurseOfDaedra) && Utility.RandomInt() < 5)
			DebugMode("Daedric spirit summoned!")
			MsgSpiritAppears.Show()
			spellSummonDaedricSpirit.Cast(PlayerRef)
		EndIf
		
		; Yield the aggregate
		;
		DebugMode("Giving player aggregate")
		PlayerRef.AddItem(liAggregator)
	EndIf
	
	; Mark off harvesting as done
	;
	akCarcassRef.RemoveItem(moTokenMat)
	
EndFunction


; -- ButcherCarcass
;
Function ButcherCarcass(Actor akCarcassRef, bool abIsMonster, bool abPartOfProcess = False, int aiKnife = -1, int aiIndex = 0, bool abFirstCut = False, int aiMeatCount = 0, int aiSection = 0)

	bool simple_loot = dsGlobals.gUseCustomMeats
	bool combined_loot = dsGlobals.gUseCustomMeats && dsGlobals.gUseCombinedCustomMeats

	DebugMode("ButcherCarcass akCarcassRef = " + akCarcassRef + " ; abIsMonster = " + abIsMonster + " ; abPartOfProcess = " + abPartOfProcess + " ; aiKnife = " + aiKnife + " ; aiIndex = " + \
		aiIndex + "; abFirstCut = " + abFirstCut + "; aiMeatCount = " + aiMeatCount + "; aiSection = " + aiSection)

	DebugMode("simple_loot = " + simple_loot + "; combined_loot = " + combined_loot)
	; Determine which knife is used to butcher.
	; Which animal is this?
	;
	int knife = aiKnife
	int index = aiIndex
	bool firstcut = abFirstCut
	If (!abPartOfProcess)
		knife = GetHuntingKnife()
		index = GetCarcassIndex(akCarcassRef, abIsMonster)
		firstcut = akCarcassRef.GetItemCount(moTokenMeat_Fresh) > 0
		DebugMode("knife = " + knife + "; index = " + index + "; firstcut = " + firstcut)
	EndIf
	
	; Setup...
	;
	Potion meattype = GetMeatType(index, abIsMonster)
	float meatweight = meattype.GetWeight()
;	float meatweight = dsAnimals.AllMeatWeights[index]
	int meatcount
	int section
	float penalty = -1
	
	DebugMode("meattype = " + meattype + "; meatweight = " + meatweight)
	
	;
	; Calculate results
	;
	
	If (abPartOfProcess)
	
		meatcount = aiMeatCount
		section = aiSection
		If ( (simple_loot && !combined_loot) || !meattype )
		
			ButcherPrep_Simple(akCarcassRef)
			section = 0
			meattype = None
		EndIf
	ElseIf ( (simple_loot && !combined_loot) || !meattype )
	
		ButcherPrep_Simple(akCarcassRef)
		section = 0
		meattype = None
		
	Else

		meatcount = ButcherPrep_MeatCount(akCarcassRef, firstcut, meattype, index, abIsMonster)
		
		; How much can be butchered at once? Including the experience penalty?
		; Capped at 100 pounds (minutes) to prevent AdvanceGameTime for long time spans.
		; Small change in SE: Additional random penalty for every butchering, for more variability, less sameness.
		int totalweight = Math.Ceiling(meatweight * meatcount)
		penalty = GetStandardPenalty(knife, 15)
		penalty += Utility.RandomInt(0, 15)
		int limit = 100 - Math.Floor(penalty)
		section = ButcherPrep_SectionSize(totalweight, limit, knife)
		penalty += ButcherPrep_SectionTime(totalweight, limit, knife, section)
		
		DebugMode("totalweight = " + totalweight + "; penalty = " + penalty + "; limit = " + limit)
	
	;
	; Finished calculating
	;
	EndIf
	
	DebugMode("meatcount = " + meatcount + "; section = " + section)
	
	; -- GP --
	If dsGlobals.gUseAnimation
		If !doSkipAnim 
			If meattype
				gpAnimFunctions.fHuntingMaterial = meattype
			Else ; meatype is equal to none, most likely "Use custom meat" option is enabled, search for meat items in the carcass instead.
				gpAnimFunctions.fHuntingMaterial = None
				Int iCarcassIndex = akCarcassRef.GetNumItems()
				While iCarcassIndex
					iCarcassIndex -= 1
					Potion pMeatItem = akCarcassRef.GetNthForm(iCarcassIndex) as Potion
					If pMeatItem && pMeatItem.isFood()
						gpAnimFunctions.fHuntingMaterial = akCarcassRef.GetNthForm(iCarcassIndex)
						iCarcassIndex = 0
					EndIf
				EndWhile
			EndIf
			gpAnimFunctions.DoAnim(4, akCarcassRef, index, abIsMonster)
		EndIf
	EndIf
	
	If (!abPartOfProcess)
		if (dsGlobals.gButcherTimed)
			float time = GetButcherTime(penalty, knife)
			time = time * dsGlobals.gAlterTime
			FadeToBlack()
			AdvanceGameTime(time)
			FadeFromBlack()
		EndIf
		
	EndIf

	; Butcher section
	;
	int sectioncount
	If ( (!simple_loot || combined_loot) && section != 0 )
		sectioncount = Math.Ceiling(section / meatweight)
		If (sectioncount >= meatcount)
			sectioncount = meatcount
		Else
			MsgBoxFinishButcherSection.Show()
		EndIf
		DebugMode("Giving player " + meattype + " x " + sectioncount)
		PlayerRef.AddItem(meattype, sectioncount)
		akCarcassRef.RemoveItem(moTokenMeat, sectioncount)
		sectioncount = Math.Ceiling(sectioncount / 2)
		DebugMode("Giving player animal fat x " + sectioncount)
		PlayerRef.AddItem(AnimalFat, sectioncount)
	EndIf
	
	; All of the invariable kinds (legs, snout) are yielded on first cut.
	; For 'simple' (custom, non-combined) loot, all meat is yielded here.
	;
	If ( !abIsMonster && (simple_loot || firstcut) )
	
		; SKSE method
		int n = akCarcassRef.GetNumItems()
		int AnimalFatCount = 0
		Potion p
		While (n)
			n -= 1
			p = akCarcassRef.GetNthForm(n) as Potion
			If (p && p != meattype)
				sectioncount = akCarcassRef.GetItemCount(p)
				If (simple_loot)
					DebugMode("(simple_loot) Giving player " + p.GetName() + " x " + sectioncount)
				Else 
					DebugMode("Giving player " + p.GetName() + " x " + sectioncount)
				EndIf
				PlayerRef.AddItem(p, sectioncount)
				akCarcassRef.RemoveItem(p, sectioncount)
				AnimalFatCount += sectioncount
			EndIf
		EndWhile
		DebugMode("Giving player animal fat x " + AnimalFatCount)
		PlayerRef.AddItem(AnimalFat, AnimalFatCount)
		;/
		; Non-SKSE hack... push through the MeatGrinder and look for keywords VendorItemFood, VendorItemFoodRaw
		CurrentCarcass = akCarcassRef
		CurrentMeatType = meattype
		akCarcassRef.RemoveAllItems(MeatGrinder)
		/;
	EndIf

EndFunction

Function ButcherPrep_Simple(Actor akCarcassRef)
	akCarcassRef.RemoveItem(moTokenMeat_Fresh)
	akCarcassRef.RemoveItem(moTokenMeat)
EndFunction

int Function ButcherPrep_MeatCount(Actor akCarcassRef, bool abFirstCut, Potion akMeatType, int aiIndex, bool abIsMonster)
	int result
	If (abFirstCut)
		float carcassweight
		float meatweight
		int size
		If (abIsMonster)
			size = dsMonsters.CarcassSizes[aiIndex]
		Else
			size = dsAnimals.CarcassSizes[aiIndex]
		EndIf
		result = dsAnimals.GetMeatCount(size)
		If (result > 1)
			akCarcassRef.AddItem(moTokenMeat, result - 1)
		EndIf
		akCarcassRef.RemoveItem(moTokenMeat_Fresh)
	Else
		result = akCarcassRef.GetItemCount(moTokenMeat)
	EndIf
	Return result
EndFunction

int Function ButcherPrep_SectionSize(int aiWeight, int aiLimit, int aiKnife)
	int result
	If (aiWeight <= aiLimit)
		result = aiWeight
	ElseIf (GetHkKw(aiKnife, kwHkDoubleMeat))
		result = aiLimit * 2
	Else
		result = aiLimit
	EndIf
	Return result
EndFunction

int Function ButcherPrep_SectionTime(int aiWeight, int aiLimit, int aiKnife, int aiSectionSize)
	int result
	If (aiWeight <= aiLimit)
		result = aiSectionSize
	ElseIf (GetHkKw(aiKnife, kwHkDoubleMeat))
		result = aiLimit
	Else
		result = aiSectionSize
	EndIf
	result -= Math.Floor((result / 13.33) * dsGlobals.gHarvestLevel)
	Return result ; IN MINUTES
EndFunction


; -- GetCarcassIndex
;
int Function GetCarcassIndex(Actor akCarcassRef, bool abIsMonster)
	If (abIsMonster)
		Return dsMonsters.GetCarcassIndex(akCarcassRef)
	Else
		Return dsAnimals.GetCarcassIndex(akCarcassRef)
	EndIf
EndFunction

; -- GetPeltList
;
FormList Function GetPeltList(int aiIndex, bool abIsMonster)
	If (abIsMonster)
		Return dsMonsters.flPeltLists.GetAt(aiIndex) as FormList
	Else
		Return dsAnimals.flPeltLists.GetAt(aiIndex) as FormList
	EndIf
EndFunction

; -- GetMatList
;
FormList Function GetMatList(int aiIndex, bool abIsMonster)
	If (!abIsMonster)
		Return dsAnimals.flMatLists.GetAt(aiIndex) as FormList
	ElseIf (dsMonsters.MonsterIndex[aiIndex] == "Dragon" && dsGlobals.gDragonsCorporeal)
		Return dsMonsters.flMatsDragonCorporeal
	Else
		Return dsMonsters.flMatLists.GetAt(aiIndex) as FormList
	EndIf
EndFunction

LeveledItem Function GetPerfectMats(int aiIndex, bool abIsMonster)
	If abIsMonster
		Return dsMonsters.flPerfectMats.GetAt(aiIndex) as LeveledItem
	Else
		Return dsAnimals.flPerfectMats.GetAt(aiIndex) as LeveledItem
	EndIf
EndFunction

; -- GetMeatType
;
Potion Function GetMeatType(int aiIndex, bool abIsMonster)
	If (abIsMonster)
		Return dsMonsters.MeatTypes[aiIndex]
	Else
		Return dsAnimals.MeatTypes[aiIndex]
	EndIf
EndFunction


; -- ExtractVenom
;
Function ExtractVenom(Actor akCarcassRef, bool abPartOfProcess = False)

	; -- GP --
	; Alchemy Requires Bottles function
	If !gpAnimFunctions.CheckForBottles()
		Return
	EndIf		
	
	int index = dsMonsters.GetCarcassIndex(akCarcassRef)

	; -- GP --
	If dsGlobals.gUseAnimation
		If !doSkipAnim
			gpAnimFunctions.fHuntingMaterial = dsMonsters.VenomTypes[index]
			gpAnimFunctions.doAnim(5)
		EndIf
	EndIf
	
	; Makes a check vs. Harvest level. Fail = player poisoned.
	;
	int roll = Utility.RandomInt()
	roll += dsGlobals.gHarvestLevel * 5
	
	If (roll < 25)
		MsgVenomFail.Show()
		spellVenomFail.Cast(PlayerRef, PlayerRef)
	Else
		PlayerRef.AddItem(dsMonsters.VenomTypes[index])
	EndIf
	
	; Mark off extraction as done
	;
	akCarcassRef.RemoveItem(moTokenVenom)

EndFunction

; -- ExtractBlood
;
Function ExtractBlood(Actor akCarcassRef, bool abPartOfProcess = False)

	; -- GP --
	; Alchemy Requires Bottles function
	If !gpAnimFunctions.CheckForBottles()
		Return
	EndIf	
	
	int index = dsMonsters.GetCarcassIndex(akCarcassRef)

	; -- GP --
	If dsGlobals.gUseAnimation
		If !doSkipAnim
			gpAnimFunctions.fHuntingMaterial = dsMonsters.BloodTypes[index]
			gpAnimFunctions.doAnim(5, iCarcassIndex = index)
		EndIf
	EndIf
	
	PlayerRef.AddItem(dsMonsters.BloodTypes[index])
	
	akCarcassRef.RemoveItem(moTokenBlood)

EndFunction

; -- SearchTreasure
;
Function SearchTreasure(Actor akCarcassRef)

	; Remove normal drops on the monster that other actions (Harvest) will remit instead.
	int index = GetCarcassIndex(akCarcassRef, True)
	FormList fl = dsMonsters.NegativeTreasure[index]
	If (fl)
		int i = akCarcassRef.GetItemCount(fl)
		akCarcassRef.RemoveItem(fl, i)
	EndIf
	
	akCarcassRef.Activate(PlayerRef)
	
	; -- GP --
	; Removes extra arrows on the carcass.
	akCarcassRef.ClearExtraArrows()
	
	gpAnimFunctions.RegisterForCancel()
	gpAnimFunctions.RegisterForMovement()
	
EndFunction


; -- GetDressTime
;
; IN HOURS.
;
float Function GetDressTime(int aiIndex, int aiKnife)

	float penalty = GetStandardPenalty(aiKnife, 30)
	float result = (dsAnimals.CarcassSizes[aiIndex] * 5) + penalty
	result = result / 60

	Return result

EndFunction

; -- GetSkinTime
;
; IN HOURS.
;
float Function GetSkinTime(int aiIndex, int aiKnife, bool abIsMonster)

	float penalty = GetStandardPenalty(aiKnife, 30)
	int level = 11 - dsGlobals.gSkinLevel
	int size
	If (abIsMonster)
		size = dsMonsters.CarcassSizes[aiIndex]
	Else
		size = dsAnimals.CarcassSizes[aiIndex]
	EndIf
	float result = (size * level) + penalty
	result = result / 60

	Return result

EndFunction

; -- GetHarvestTime
;
; IN HOURS.
;
float Function GetHarvestTime(int aiIndex, int aiKnife, bool abIsMonster)

	float penalty = GetStandardPenalty(aiKnife, 30)
	int level = 11 - dsGlobals.gHarvestLevel
	int size
	If (abIsMonster)
		size = dsMonsters.CarcassSizes[aiIndex]
	Else
		size = dsAnimals.CarcassSizes[aiIndex]
	EndIf
	float result = (size * level) + penalty
	result = result / 60

	Return result

EndFunction

; -- GetButcherTime
;
; IN HOURS.
;
float Function GetButcherTime(float afTime, int aiKnife)

	float result = afTime
	If (result == -1)
		result = GetStandardPenalty(aiKnife, 15)
	EndIf
	result = result / 60
	
	Return result

EndFunction

; -- ApproxButcherTime
;
; For modeling (as on MCM Stats page).
;
; IN HOURS.
;
;/
float Function ApproxButcherTime(int aiIndex, int aiKnife, bool abIsMonster)

	float result = GetStandardPenalty(aiKnife, 15)
	Potion meattype
	float carcassweight
	If (abIsMonster)
		meattype = dsMonsters.MeatTypes[aiIndex]
		carcassweight = (dsMonsters.flCarcassObjects.GetAt(aiIndex) as MiscObject).GetWeight() as Float
	Else
		meattype = dsAnimals.MeatTypes[aiIndex]
		carcassweight = (dsAnimals.flCarcassObjects.GetAt(aiIndex) as MiscObject).GetWeight() as Float
	EndIf
	float meatweight = meattype.GetWeight()
	float meatcount = dsAnimals.GetMeatCount(meattype, carcassweight)
	int totalweight = Math.Ceiling(meatweight * meatcount)
	int limit = 100 - Math.Floor(result)
	int section = ButcherPrep_SectionSize(totalweight, limit, aiKnife)
	result += ButcherPrep_SectionTime(totalweight, limit, aiKnife, section)
	
	result = result / 60
	
	Return result

EndFunction
/;

; -- GetStandardPenalty
;
; The "lack of experience" penalty that applies to many actions. Increased if you have no knife or only a sharp rock.
;
; IN MINUTES.
;
float Function GetStandardPenalty(int aiKnife, int aiBasePenalty)

	float penalty = (20 - dsGlobals.gTotalCleans) * 3
	If (penalty < 0)
		penalty = 0
	EndIf
	If (aiKnife == _KNIFE_SHARPROCK)
		penalty += aiBasePenalty
	ElseIf (aiKnife == _KNIFE_NONE)
		penalty += aiBasePenalty + 15
	EndIf
	
	Return penalty
	
EndFunction


; -- GetHuntingKnife
;
; This has been greatly simplified as of 1.2. The current system depends solely on keywords.
; Daggers don't count as a substitute HK any more, because (due to GetItemCount bugs),
; that requires looping over entire player inventory. Equipped is also ignored.
;
int Function GetHuntingKnife(bool abRescan = False)

	; Always scan if 
	If (!abRescan)
		Return dsGlobals.gHuntingKnife
	EndIf
	
	If (!dsGlobals.gRequireHuntingKnife)
		dsGlobals.gHuntingKnife = _KNIFE_IRON
		Return _KNIFE_IRON
	EndIf
	
	; Scan for best knife
	If (PlayerRef.GetItemCount(kwHuntingKnife) > 0)
		int n = flHuntingKnives.GetSize()
		Weapon w
		While (n)
			n -= 1
			w = flHuntingKnives.GetAt(n) as Weapon
			If (PlayerRef.GetItemCount(w) > 0)
				dsGlobals.gHuntingKnife = n
				Return n
			EndIf
		EndWhile
	EndIf
	
	; Claws?
	If (dsGlobals.gClawsAsHuntingKnife)
		Race r = PlayerRef.GetRace()
		;If (r == KhajiitRace || r == KhajiitVampireRace || r == ArgonianRace || r == ArgonianVampireRace)
		If (flClawRaces.Find(r) > -1)
			dsGlobals.gHuntingKnife = _KNIFE_CLAWS
			Return _KNIFE_CLAWS
		EndIf
	EndIf
	
	; Sharp rock?
	If (PlayerRef.GetItemCount(moSharpRock) > 0)
		dsGlobals.gHuntingKnife = _KNIFE_SHARPROCK
		Return _KNIFE_SHARPROCK
	EndIf
	
	dsGlobals.gHuntingKnife = _KNIFE_NONE
	Return _KNIFE_NONE
	
EndFunction

Function SetHuntingKnife(Form akBaseItem)

	int myknife = dsGlobals.gHuntingKnife
	int newknife
	If (akBaseItem == moSharpRock)
		newknife = _KNIFE_SHARPROCK
	Else
		newknife = flHuntingKnives.Find(akBaseItem)
	EndIf
	
	;Trace("OIA HK prev: " + myknife)
	;Trace("OIA HK find: " + newknife)
	
	If (myknife == _KNIFE_NONE || newknife > myknife)
		dsGlobals.gHuntingKnife = newknife
		;Trace("OIA HK update: " + dsGlobals.gHuntingKnife)
	EndIf
	
	;Trace("OIA HK result: " + dsGlobals.gHuntingKnife)
	
EndFunction

; -- CanScrimshaw
;
; This is a modified GetHuntingKnife that informs the Scrimshaw script of whether a qualifying tool is possessed.
;
bool Function CanScrimshaw()

	; Shortcut: Always yes if HK requirement is off
	; Shortcut: Sharp rock
	If (!dsGlobals.gRequireHuntingKnife || PlayerRef.GetItemCount(moSharpRock) > 0)
		Return True
	Else
		GetHuntingKnife(True)
		Return dsGlobals.gHuntingKnife > _KNIFE_NONE
	EndIf
	
EndFunction

; -- GetHuntingKnifeSkinBonus
;
; Bonus chance to skin a higher quality pelt provided by the type of hunting knife the player has.
;
int Function GetHuntingKnifeSkinBonus(int aiIndex)

	If (aiIndex > -1)
		FormList fl = flHkefLists.GetAt(aiIndex) as FormList
		Keyword kw = fl.GetAt(0) as Keyword
		int result = flSkinBonuses.Find(kw)
		Return result * 10
	ElseIf (aiIndex == _KNIFE_CLAWS)
		Return 10
	ElseIf (aiIndex == _KNIFE_SHARPROCK)
		Return 0
	Else
		Return -50
	EndIf

EndFunction

; -- GetHuntingKnifeHarvestBonus
;
; Bonus chance to harvest bones and organs provided by the type of hunting knife the player has.
;
int Function GetHuntingKnifeHarvestBonus(int aiIndex)

	If (aiIndex > -1)
		FormList fl = flHkefLists.GetAt(aiIndex) as FormList
		Keyword kw = fl.GetAt(1) as Keyword
		int result = flHarvestBonuses.Find(kw)
		Return result * 10
	ElseIf (aiIndex == _KNIFE_SHARPROCK || aiIndex == _KNIFE_CLAWS)
		Return 0
	Else
		Return -50
	EndIf

EndFunction

; -- GetHkKw
;
; Does this hunting knife (by index) have a certain keyword (effect)?
;
bool Function GetHkKw(int aiIndex, Keyword akKeyword)
	If (aiIndex > -1)
		FormList fl = flHkefLists.GetAt(aiIndex) as FormList
		int result = fl.Find(akKeyword)
		Return result > -1
	Else
		Return False
	EndIf
EndFunction

; -- DegradeHuntingKnife
;
; Hunting knife loses a little of its edge every time it's used.
;
; This is NYI because Papyrus (the game itself, actually) doesn't really keep track of individual objects.
; 3 knives in your inventory aren't 3 different objects, they're a stack of 3 of the same Form.
; Enchanting and sharpening (grindstone) aren't viable methods to track a knife's "dullness":
; These either work on the base Form, or give you a completely new Form - how other mods pull this off.
; May have to implement this using 24 different knife Forms... meh.
;
Function DegradeHuntingKnife(int aiIndex)

	If (aiIndex == _KNIFE_BONE && Utility.RandomInt() < 25)
		MsgBoxBoneKnifeBroken.Show()
		PlayerRef.RemoveItem(weapKnifeBone)
	EndIf

EndFunction


; -- DoAnim
;
; Plays an animation to go along with dress / skin / harvest / butcher.
; This is a built-in animation, not custom, the same one Namira's Ring (cannibalism) uses.
;
Function DoAnim()

	If (dsGlobals.gUseAnimation)
		PlayerRef.PlayIdle(idleCarcassAnim)
		Utility.Wait(1.5)
	EndIf

EndFunction


; -- FadeToBlack
;
; Fade to black, to connote AdvanceTime.
;
Function FadeToBlack()
	If dsGlobals.gFadeOuts
		Game.DisablePlayerControls(True, False, False, False, False, True, True)
		ismFadeOut.Apply()
		ismBlack.ApplyCrossFade(1.0)
		Utility.Wait(1.0)
		ismFadeOut.PopTo(ismBlack)
		;Game.FadeOutGame(True, True, 0.0, 1.5) ; Trying cross-fades in 1.6.1, instead
	EndIf
EndFunction

; -- FadeFromBlack
;
; Back from black, after whatever got done.
;
Function FadeFromBlack()
	If dsGlobals.gFadeOuts
		Game.EnablePlayerControls()
		Utility.Wait(1)
		ismBlack.PopTo(ismFadeIn)
		ImageSpaceModifier.RemoveCrossFade(1.0)
		Utility.Wait(1)
		;Game.FadeOutGame(False, True, 2.0, 1.5)
	EndIf
EndFunction


; -- AdvanceTime
;
; Advance the game time by this many hours, which can be fractional: 0.5 for half an hour.
;
Function AdvanceGameTime(float afHours)
	DebugMode("AdvanceGameTime: " + afHours)
	if (afHours > 0)
		float t = gGameTime.GetValue()
		gGameTime.SetValue(t + afHours)
	EndIf
EndFunction

Bool Function CheckPlayableInventory( Actor akCarcassRef )
	int i = akCarcassRef.GetNumItems()
	While (i > 0)
		Form item = akCarcassRef.GetNthForm(i)
		if (item != None)
			If (item.IsPlayable())
				Return True
			EndIf
		EndIf
		i -= 1
	EndWhile
	Return False
EndFunction

; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
