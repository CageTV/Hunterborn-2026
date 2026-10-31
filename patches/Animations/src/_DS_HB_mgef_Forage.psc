; Hunterborn 2026 - Animations patch. Hunterborn Animations (Nexus 80677) by Elsawirr (animations) and GiraPomba (scripts) is the source of the animation calls
; in this script; the author allows modifying the files with credit, and asks that patches require the mod. Their version, unchanged (it already contains a Process hotkey fix for monsters).
; Needs Hunterborn - Animations installed (the animation calls look its quest up at run time and do nothing without it).
Scriptname _DS_HB_mgef_Forage extends activemagiceffect  

_DS_HB_Globals Property dsGlobals Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Player Property dsPlayer Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Tracks_Finder Property dsTracksFinder Auto

Actor Property PlayerRef Auto

Spell Property spelRegionDetect Auto
MagicEffect Property mgefForager Auto
MagicEffect Property mgefTracker Auto

int[] Property ForageRollModifiers Auto

FormList Property flForageAnything Auto
LeveledItem Property liForageFirewood Auto
LeveledItem Property liForageBones Auto
LeveledItem Property liForageBones_Superior Auto
LeveledItem Property liForageEdibles Auto
LeveledItem Property liForageEdibles_Superior Auto
FormList Property flForageIngredients Auto
FormList Property flForageIngredients_Superior Auto
MiscObject Property moSharpRock Auto
MiscObject Property moSnow Auto
MiscObject Property moTreeBark Auto
Potion Property foodSoupWater Auto

LeveledItem Property liAggregator Auto

Keyword Property kwLocTypeCity Auto
;FormList Property flForageLocsInvalid Auto
FormList Property flForageLocsHolds Auto

Spell Property spellHircinesVigil Auto
MiscObject Property moHeartwood Auto

Message Property MsgErrorCantInCombat Auto
Message Property MsgMustBeOutdoors Auto
Message Property MsgErrorCantForageHere Auto
Message Property MsgForageFailed Auto
Message Property MsgBoxForageChoice Auto
Message Property MsgBoxForageLevelUp Auto

;Message Property MsgScavenged
FormList Property flScavengeMessages Auto
FormList Property flScavengeArchetypes Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)

	DebugMode("_DS_HB_mgef_Forage OnEffectStart")
	
	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		DebugMode("Failed: IsInCombat")
		MsgErrorCantInCombat.Show()
		Return
	EndIf

	If (PlayerRef.IsInInterior())
		DebugMode("Failed: IsInInterior")
		MsgMustBeOutdoors.Show()
		Return
	EndIf
	
	int i

	; Determine player's region
	;
	dsGlobals.gRegionIndex = -1
	int region = GetForageRegion()
	;Debug.Notification("Forage region: " + region)
	If (region < 0)
		MsgErrorCantForageHere.Show()
		Return
	EndIf
	
	int foragelevel = dsGlobals.gForageLevel
	DebugMode("foragelevel = " + foragelevel)
	
	; Selective foraging
	; 0 Anything
	; 1 Firewood
	; 2 Edibles
	; 3 Bones
	; 4 Ingredients
  ; 5 Scavenge
	; 6 Cancel
	;
	int actionToTake = 0
	If (foragelevel > 0)
		int button = MsgBoxForageChoice.Show()
		If (button == 6)
			Return
		EndIf
		actionToTake = button
	EndIf
	
	If dsGlobals.gUseAnimation
		dsActions.gpAnimFunctions.CheckWeaponsDrawn()
		If !PlayerRef.isWeaponDrawn()
			dsActions.gpAnimFunctions.doAnim(9)
		EndIf
	EndIf

	DebugMode("actionToTake = " + actionToTake)
	
	LeveledItem forageitems
	LeveledItem forageitems_superior
	If (actionToTake == 0)
		forageitems = flForageAnything.GetAt(region) as LeveledItem
		forageitems_superior = forageitems
	ElseIf (actionToTake == 1)
		forageitems = liForageFirewood
		forageitems_superior = forageitems
	ElseIf (actionToTake == 2)
		forageitems = liForageEdibles
		forageitems_superior = liForageEdibles_Superior
	ElseIf (actionToTake == 3)
		forageitems = liForageBones
		forageitems_superior = liForageBones_Superior
	ElseIf (actionToTake == 4)
		forageitems = flForageIngredients.GetAt(region) as LeveledItem
		forageitems_superior = flForageIngredients_Superior.GetAt(region) as LeveledItem
	EndIf
	DebugMode("forageitems = " + forageitems + " ; forageitems_superior = " + forageitems_superior)
	
	; Determine the foraging bonus / penalty
	;
	int bonus = (foragelevel * 5)
	bool hasforager = PlayerRef.HasMagicEffect(mgefForager)
	bool haspet_rabbit = dsPlayer.HasPetHare()
	bool haspet_fox = dsPlayer.HasPetFox()
	DebugMode("hasforager = " + hasforager + " ; haspet_rabbit = " + haspet_rabbit + " ; haspet_fox = " + haspet_fox)
	
	If hasforager
		bonus += 5 ; Nerfed in 1.6!
	EndIf
	If haspet_rabbit
		bonus += 10
	EndIf
	If haspet_fox
		bonus += 10
	EndIf
	bool getwood = PlayerRef.HasSpell(spellHircinesVigil) && bonus >= 55 && Utility.RandomInt() >= 85
	bonus += ForageRollModifiers[region]
	
	; Foraging for Firewood is trivial [changed 1.6.2]
	If actionToTake == 1
		bonus += 50
	EndIf
	
	; Superior foraging results if there's enough accumulated bonus
	;
	If bonus >= 70 ; || (foragelevel > 4 && bonus >= 50) ; Nerfed in 1.6!
		DebugMode("Player qualifies for superior results.")
		forageitems = forageitems_superior
	EndIf
	
	; Make a roll...
	;
	int baseroll = Utility.RandomInt()
	int totalroll = baseroll + bonus
	DebugMode("baseroll = " + baseroll + " ; bonus = " + bonus)
	
	; Experience / level up
	;
	bool levelup = False
	If (foragelevel < 10)
		int forageexp = dsGlobals.gForageExp
		forageexp += baseroll
		If ( \
			(foragelevel == 0 && forageexp > 99) || \
			(foragelevel == 1 && forageexp > 449) || \
			(foragelevel == 2 && forageexp > 899) || \
			(foragelevel == 3 && forageexp > 1199) || \
			(foragelevel == 4 && forageexp > 1499) || \
			(foragelevel == 5 && forageexp > 2024) || \
			(foragelevel == 6 && forageexp > 2774) || \
			(foragelevel == 7 && forageexp > 3749) || \
			(foragelevel == 8 && forageexp > 5149) || \
			(foragelevel == 9 && forageexp > 6199) \
		)
			levelup = True
		ElseIf (foragelevel == 10)
			forageexp = 6200 ; cap to prevent wrapping
		EndIf
		dsGlobals.gForageExp = forageexp
	EndIf
	
	; Results
	;
	bool success = totalroll > 75 && actionToTake != 5
	
	bool rockin = (dsActions.GetHuntingKnife() < 0) && (PlayerRef.GetItemCount(moSharpRock) == 0 && Utility.RandomInt() > 55)
	
	bool treebark = actionToTake == 1 && dsGlobals.isTanningLoaded
	int bark_count = 0
	If treebark
		baseroll = Utility.RandomInt()
		If hasforager || foragelevel > 1
			baseroll += 15
		EndIf
		If region == 0 && baseroll > 25
			bark_count = 2
		ElseIf region == 1 && baseroll > 15
			bark_count = 4
		ElseIf region == 2 && baseroll > 30
			bark_count = 3
		ElseIf region == 3 && baseroll > 20
			bark_count = 3
		ElseIf region == 4 && baseroll > 35
			bark_count = 3
		ElseIf region == 5 && baseroll > 30
			bark_count = 1
		ElseIf region == 6 && baseroll > 15
			bark_count = 4
		ElseIf region == 7 && baseroll > 25
			bark_count = 2
		ElseIf region == 8 && baseroll > 30
			bark_count = 2
		ElseIf region == 9 && baseroll > 25
			bark_count = 2
		Else
			treebark = False
		EndIf
		If baseroll > 80
			bark_count += 1
		EndIf
	EndIf
	
	; This is a bypass. It's for those not running a needs mod, just making soup for fun.
	bool soupwater = actionToTake == 2 && dsGlobals.gEnableSoupsStews && !dsGlobals.isINEEDLoaded
	int water_count = 3
	
	bool snow = actionToTake == 2 && dsGlobals.isRNDLoaded
	int snow_count = 0
	If snow
		If (region == 0 && Utility.RandomInt() > 65)
			snow_count = 1
		ElseIf (region == 1 && Utility.RandomInt() > 80)
			snow_count = 1
		ElseIf (region == 2 && Utility.RandomInt() > 25)
			snow_count = 2
		ElseIf (region == 3 && Utility.RandomInt() > 25)
			snow_count = 2
		ElseIf (region == 4 && Utility.RandomInt() > 10)
			snow_count = 3
		ElseIf (region == 5 && Utility.RandomInt() > 65)
			snow_count = 1
		ElseIf (region == 6 && Utility.RandomInt() > 80)
			snow_count = 1
		ElseIf (region == 7 && Utility.RandomInt() > 80)
			snow_count = 1
		ElseIf (region == 8 && Utility.RandomInt() > 5)
			snow_count = 3
		Else
			snow = False
		EndIf
	EndIf
	
	liAggregator.Revert()
	
	; Scavenging system - added 1.6.1
	; 1.6.2 = Nerfed chance under level 7
	bool scavenged = (foragelevel < 7 && Utility.RandomInt() > 85 || foragelevel > 6 && Utility.RandomInt() > 75) && (actionToTake == 0 || actionToTake == 5)
;	bool scavenged = True ; Debugging
	DebugMode("Scavenged something = " + scavenged)
	Message scavengemessage
	Form scavengeitem
	If scavenged
		i = flScavengeMessages.GetSize() - 1
		int scenario = Utility.RandomInt(0, i)
		; Scenario 0 is "buried under a foot of snow". Swap it to "under a cover of leaves" for non-snowy regions.
		If scenario == 0 && region != 4 && region != 8
			scenario = 1
		; Scenario 9 is "inside a crate overgrown with moss". Swap to snow for snowy regions.
		ElseIf scenario == 9 && (region == 4 || region == 8)
			scenario = 0
		EndIf
		scavengemessage = flScavengeMessages.GetAt(scenario) as Message
		i = flScavengeArchetypes.GetSize() - 1
		int archetype = Utility.RandomInt(0, i)
		scavengeitem = flScavengeArchetypes.GetAt(archetype)
		liAggregator.AddForm(scavengeitem, 1, 1)
		DebugMode("Scavenge scenario = " + scenario + " ; archetype = " + archetype)
	EndIf

	If dsGlobals.gForageTimed
		dsActions.FadeToBlack()
    float time = 1.0 * dsGlobals.gAlterTime
		dsActions.AdvanceGameTime(time)
		dsActions.FadeFromBlack()
	EndIf
	
	If levelup
		MsgBoxForageLevelUp.Show()
		dsGlobals.gForageLevel = foragelevel + 1
	EndIf
	
	If success
		int extras = 1
;		If (hasforager)
;			extras += 1
;		EndIf
		If (haspet_rabbit || haspet_fox)
			extras += 1
		EndIf
		If (actionToTake == 1) ; Firewood bonuses are much higher
			extras += foragelevel
		ElseIf (foragelevel > 8 && Utility.RandomInt() > 25)
			extras += 1
		ElseIf (foragelevel > 6 && foragelevel < 9 && Utility.RandomInt() > 50)
			extras += 1
		ElseIf (foragelevel > 4 && foragelevel < 7 && Utility.RandomInt() > 75)
			extras += 1
		EndIf
		DebugMode("extras = " + extras)
		While (extras)
			extras -= 1
			DebugMode("Giving player " + forageitems)
			liAggregator.AddForm(forageitems, 1, 1)
		EndWhile
	EndIf
	
	If rockin
		DebugMode("Giving player sharp rock.")
		liAggregator.AddForm(moSharpRock, 1, 1)
	EndIf
	
	If snow
		DebugMode("Giving player snow x " + snow_count)
		liAggregator.AddForm(moSnow, 1, snow_count)
	EndIf
	
	If getwood
		DebugMode("Giving player heartwood.")
		liAggregator.AddForm(moHeartwood, 1, 1)
	EndIf
	
	If treebark
		DebugMode("Give player tree bark x " + bark_count)
		liAggregator.AddForm(moTreeBark, 1, bark_count)
	EndIf
	
	If soupwater
		DebugMode("Give player soup water.")
		liAggregator.AddForm(foodSoupWater, 1, water_count)
	EndIf

	If scavenged
		scavengemessage.Show()
		PlayerRef.AddItem(liAggregator)
;		PlayerRef.AddItem(scavengeitem) ; Debugging
	ElseIf success || rockin || snow || getwood || soupwater
		PlayerRef.AddItem(liAggregator)
	Else
		MsgForageFailed.Show()
	EndIf

EndEvent


; Regions:
; 0 Eastmarch
; 1 Falkreath
; 2 Haafingar
; 3 Hjaalmarch
; 4 Pale
; 5 Reach
; 6 Rift
; 7 Whiterun
; 8 Winterhold
; 9 Solstheim

int Function GetForageRegion()

	int region = -1

	; Try Location first, which is most accurate. Also prevent foraging in cities.
	;
	region = GetRegionFromLocation()
	;Debug.MessageBox("RegionFromLocation: " + region)
	
	; Try WorldSpace regions (including weather), generally accurate.
	;
	If (region == -1)
		region = GetRegionFromWorld()
		;Debug.MessageBox("RegionFromWorld: " + region)
	EndIf
	
	; Last resort, try to use nearby flora / trees as clues.
	;
	If (region == -1)
		region = GetRegionFromFlora()
		;Debug.MessageBox("RegionFromFlora: " + region)
	EndIf
	
	DebugMode("GetForageRegion = " + region)
	Return region

EndFunction

int Function GetRegionFromLocation()

	int i
	Location loc
	
	; Prevent foraging in cities:
	loc = PlayerRef.GetCurrentLocation()
	If (loc && loc.HasKeyword(kwLocTypeCity))
		DebugMode("GetRegionFromLocation = -2")
		Return -2
	EndIf
;	i = flForageLocsInvalid.GetSize()
;	While (i)
;		i -= 1
;		loc = flForageLocsInvalid.GetAt(i) as Location
;		If (PlayerRef.IsInLocation(loc))
;			Return -2
;		EndIf
;	EndWhile
	
	; These are specific locations (on the map) within each Hold:
	i = flForageLocsHolds.GetSize()
	While (i)
		i -= 1
		loc = flForageLocsHolds.GetAt(i) as Location
		If (PlayerRef.IsInLocation(loc))
			DebugMode("GetRegionFromLocation = " + i)
			Return i
		EndIf
	EndWhile
	
	DebugMode("GetRegionFromLocation = -1")
	Return -1

EndFunction

int Function GetRegionFromWorld()

	dsGlobals.gRegionIndex = -1
	spelRegionDetect.Cast(PlayerRef)
	int ticks = 8
	While (dsGlobals.gRegionIndex == -1 && ticks > 0)
		Utility.Wait(0.25)
		ticks -= 1
	EndWhile
	
	DebugMode("GetRegionFromWorld = " + dsGlobals.gRegionIndex)

	Return dsGlobals.gRegionIndex
	
EndFunction

int Function GetRegionFromFlora()

	DebugMode("GetRegionFromFlora = 2")

	; Default to Haafingar... fuzzy fix for Dawnguard
	Return 2

EndFunction


; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Debug.Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
