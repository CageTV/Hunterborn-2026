Scriptname _DS_HB_MAIN extends Quest  

; PROPERTIES --------------------------------------------------------------------------------------

Actor Property PlayerRef  Auto  

_DS_HB_Actions Property dsActions Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Monsters Property dsMonsters Auto
_DS_HB_Knives Property dsKnives Auto
_DS_HB_Globals Property dsGlobals Auto
_DS_HB_CarcassArray Property dsCarcassArray Auto
Import Debug


Message[] Property FreshCarcassMsgBoxes Auto

Message Property MsgBoxCleanCarcass Auto
Message Property MsgBoxMonsterCarcass Auto
Message Property MsgBoxSkyReGathererBug Auto
Message Property MsgErrorCantInCombat Auto
Message Property MsgErrorWeaponDrawn Auto
Message Property MsgErrorCarryingTooMuch Auto
Message Property MsgErrorCarcassTooHeavy Auto

Race Property DogRace Auto
Race Property DogCompanionRace Auto
Race Property GoatRace Auto
Race Property GoatDomesticsRace Auto
Race Property HareRace Auto
Race Property HorseRace Auto
Race Property CartHorseRace Auto
Race Property DragonRace Auto
Race Property UndeadDragonRace Auto
Race Property DLC1UndeadDragonRace Auto

ObjectReference Property SpawnMarker Auto

; Hircine's stuff
Spell Property spellHircinesVigil Auto
Spell Property spellHealthBurst Auto
Spell Property spellStaminaBurst Auto
Perk Property perkHeartwoodBow Auto
FormList Property flRiteSpells Auto
FormList Property flRitePowers Auto
FormList Property flRiteStageVars Auto
Activator Property SummonTargetFXActivator Auto
ActorBase Property abSpiritWolf Auto
ActorBase Property abDMD Auto
ObjectReference Property DmdSpawnRef Auto

; SkyRe (not needed for PerMa) dyna-DLC stuff
;ConstructibleObject Property coSkyReQLBoots Auto
;ConstructibleObject Property coSkyReQLCuirass Auto
;ConstructibleObject Property coSkyReQLGauntlets Auto
;ConstructibleObject Property coSkyReQLHelmet Auto

; Frostfall dyna-DLC stuff
FormList Property flWarmFoods5 Auto
FormList Property flWarmFoods10 Auto
FormList Property flWarmFoods15 Auto
FormList Property flWarmBooze10 Auto
FormList Property flWarmBooze15 Auto
FormList Property flWarmBooze20 Auto


; Startup stuff...

Spell Property ConfigSpell Auto
Perk Property CarcassStartupPerk Auto
Quest Property StartupQuest Auto
Message Property MsgBoxCarcassStartup Auto
Message Property MsgBoxStartedFromCarcass Auto

Actor Property SolafRef Auto

LeveledItem Property HunterLootLItem Auto

Perk Property CarcassEmptyPerk Auto
Perk Property CarcassFreshPerk Auto
Perk Property CarcassCleanPerk Auto
Perk Property CarcassMonsterPerk Auto
Perk Property HircinesSightPerk Auto
Perk Property BotanyPerk Auto
Perk Property BountyPerk Auto
Perk Property SavageArrowsPerk Auto

Spell Property ForageSpell Auto
Spell Property PrimitiveCookingSpell Auto
Spell Property ScrimshawSpell Auto
Spell Property SenseDirectionSpell Auto
Spell Property TaxonomySpell Auto
Spell Property TrackingSpell Auto

Book Property LyartCairnBook Auto
Book Property DruidicRitesBook Auto
Potion Property StrangeBrew Auto

; Hotkey shortcut "spells"
Spell Property hkFieldDress Auto
Spell Property hkSkin Auto
Spell Property hkHarvest Auto
Spell Property hkButcher Auto
Spell Property hkProcess Auto

LeveledItem Property FirewoodLItem Auto
MiscObject Property Firewood Auto


; PRIVATE VARIABLES -------------------------------------------------------------------------------

Bool		CritSection


; EVENTS ------------------------------------------------------------------------------------------

Event OnInit()

	; Used to test save games, since OnInit won't run again unless on a clean save.
	dsGlobals.gVersion = 1.6
	
	; Check for MCM here...
	
	PlayerRef.AddSpell(ConfigSpell, False)
	dsGlobals.gStartupPrompted = False
	RegisterForSingleUpdate(6)

EndEvent

Event OnUpdate()
	; Block startup during game's opening scene.
	If ( StartupQuest.GetStage() < 10 && !Game.IsFightingControlsEnabled() )
		RegisterForSingleUpdate(6)
		Return
	EndIf

	If StartupQuest.GetStage() == 0
		StartupQuest.SetStage(10)
		PlayerRef.AddPerk(CarcassStartupPerk)
	EndIf
	
EndEvent


; FUNCTIONS ---------------------------------------------------------------------------------------


; -- CarcassStartup
;
; Invoke Hunterborn startup by clicking on a carcass.
;
Function CarcassStartup(ObjectReference akCarcassRef)

	int prompt = MsgBoxCarcassStartup.Show()
	; 0 Yes
	; 1 No
	; 2 Stop asking
	If (prompt == 0)
		MsgBoxStartedFromCarcass.Show()
		;akCarcassRef.RemoveAllItems()
		; Initialize globals ...?
		;dsGlobals.ResetToDefaults()
		StartHunterborn()
	ElseIf (prompt == 1)
		dsGlobals.gStartupPrompted = True
		akCarcassRef.Activate(PlayerRef)
	ElseIf (prompt == 2)
		PlayerRef.RemovePerk(CarcassStartupPerk)
		akCarcassRef.Activate(PlayerRef)
	EndIf

EndFunction

; -- StartHunterborn
;
; Bootstrap stuff migrated from MCM for SE version.
;
Function StartHunterborn()

	; Hunterborn 2026: no "is starting" notification (Hunterborn starts by itself now, see HunterbornNative auto start).

	If !self.IsRunning()
		self.Start()
	EndIf

	; Hunterborn2026.esp clears the Complete Quest flag of this stage, so no "Completed: Hunterborn" banner (the logo is shown instead).
	StartupQuest.SetStage(20)
	Utility.Wait(2.0)
	
	PlayerRef.RemovePerk(CarcassStartupPerk)
	
	PlayerRef.AddPerk(CarcassEmptyPerk)
	PlayerRef.AddPerk(CarcassFreshPerk)
	PlayerRef.AddPerk(CarcassCleanPerk)
	PlayerRef.AddPerk(CarcassMonsterPerk)
	PlayerRef.AddPerk(HircinesSightPerk)
	
	If dsGlobals.gEnableBotanyPerk
		PlayerRef.AddPerk(BotanyPerk)
	EndIf
	If dsGlobals.gEnableBountyPerk
		PlayerRef.AddPerk(BountyPerk)
	EndIf
	If dsGlobals.gEnableSavageArrows
		PlayerRef.AddPerk(SavageArrowsPerk)
	EndIf

	If dsGlobals.gEnableForaging
		PlayerRef.AddSpell(ForageSpell)
	EndIf
	If dsGlobals.gEnablePrimitiveCooking
		PlayerRef.AddSpell(PrimitiveCookingSpell)
	EndIf
	If dsGlobals.gEnableScrimshaw
		PlayerRef.AddSpell(ScrimshawSpell)
	EndIf
	If dsGlobals.gEnableSenseDirection
		PlayerRef.AddSpell(SenseDirectionSpell)
	EndIf
	If dsGlobals.gEnableTracking
		PlayerRef.AddSpell(TrackingSpell)
	EndIf
	
	; Init stuff - templates, everything that makes the mod work
	DoInitStuff()
	
	; Give Solaf a copy of "The Lyart Cairn" to sell.
	SolafRef.AddItem(LyartCairnBook)
	; Set up Hunter loot - booze and... books?
	; These are repeated to provide higher chances. Roughly 40 forms in this LItem, vanilla.
	HunterLootLItem.AddForm(DruidicRitesBook, 1, 1)
	HunterLootLItem.AddForm(DruidicRitesBook, 1, 1)
	HunterLootLItem.AddForm(DruidicRitesBook, 1, 1)
	HunterLootLItem.AddForm(DruidicRitesBook, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	HunterLootLItem.AddForm(StrangeBrew, 1, 1)
	
	; This is new in 1.6. Give back Rite spells in the case of a Stop / Start
	int i = flRitePowers.GetSize()
	GlobalVariable g
	Spell s
	While (i)
		i -= 1
		g = flRiteStageVars.GetAt(i) as GlobalVariable
		int days = g.GetValueInt()
		If (days >= 3)
			s = flRitePowers.GetAt(i) as Spell
			PlayerRef.AddSpell(s)
		EndIf
	EndWhile
	
	dsGlobals.gHunterbornActive = True
	
	; Hunterborn 2026: no "started" notification either.
	
EndFunction

Function StopHunterborn()

	Debug.Notification("Hunterborn SE is stopping...")
	
	If self.IsRunning()
		self.Stop()
	EndIf

;	PlayerRef.RemoveSpell(ConfigSpell)
	
	PlayerRef.RemovePerk(CarcassEmptyPerk)
	PlayerRef.RemovePerk(CarcassFreshPerk)
	PlayerRef.RemovePerk(CarcassCleanPerk)
	PlayerRef.RemovePerk(CarcassMonsterPerk)
	PlayerRef.RemovePerk(HircinesSightPerk)
	PlayerRef.RemovePerk(BotanyPerk)
	PlayerRef.RemovePerk(BountyPerk)
	PlayerRef.RemovePerk(SavageArrowsPerk)
	
	PlayerRef.RemoveSpell(ForageSpell)
	PlayerRef.RemoveSpell(PrimitiveCookingSpell)
	PlayerRef.RemoveSpell(ScrimshawSpell)
	PlayerRef.RemoveSpell(SenseDirectionSpell)
  PlayerRef.RemoveSpell(TrackingSpell)
	PlayerRef.RemoveSpell(TaxonomySpell)
	
	int i = flRiteSpells.GetSize()
	Spell s
	While (i)
		i -= 1
		s = flRiteSpells.GetAt(i) as Spell
		PlayerRef.RemoveSpell(s)
	EndWhile
	
	; Take away the book, if Solaf still has it.
	SolafRef.RemoveItem(LyartCairnBook, SolafRef.GetItemCount(LyartCairnBook))
	
	; Revert hunter LI.
	HunterLootLItem.Revert()
	
	; Clear arrays.
	dsCarcassArray.ClearArray()
	
	; Revert DI's.
	dsAnimals.InitDeathItems(True)
	dsMonsters.InitDeathItems(True)
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsAnimals.flPeltLists, dsAnimals.DefaultPeltValues)
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsMonsters.flPeltLists, dsMonsters.DefaultPeltValues)
;	dsAnimals.SetMeatValues(dsGlobals.gMeatValue)
;	dsAnimals.ReweighMeat(True)

	; Take knives off of merchants AND change the setting to reflect.
	dsKnives.SetKnifeSales(0)
	dsGlobals.gKnifeSales = 0
	
	; Back out of DLC.
	RevertDLC()
	
	; Stop quest scripts
	Stop()

	dsGlobals.gHunterbornActive = False
	
	Debug.Notification("Hunterborn SE has stopped.")
		
EndFunction

Function DoInitStuff()

	Debug.Trace(" >>=======> Hunterborn DoInitStuff running...")
	;dsGlobals.gDebugMode = True
	dsAnimals.InitDeathItems()
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsAnimals.flPeltLists, dsAnimals.DefaultPeltValues)
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsMonsters.flPeltLists, dsMonsters.DefaultPeltValues)
;	dsAnimals.ReweighMeat(!dsGlobals.gReweighMeat)
	If dsGlobals.gMonsterHunter
		dsMonsters.InitDeathItems()
	EndIf
	dsGlobals.gHuntingKnife = -1
	dsActions.GetHuntingKnife(True)
	
	If (dsGlobals.gDoInitStuff)
		;dsGlobals.gFrostfallAdded = False
		dsGlobals.isSkyReLoaded = False
		dsGlobals.isPerMaLoaded = False
	EndIf

	PrepForDLC()
	
	dsGlobals.gDoInitStuff = False
		
EndFunction

Function FakeUpdate()

	If !dsGlobals.gFakeUpdate
		Return
	EndIf

	Debug.Trace(" >>=======> Hunterborn FakeUpdate running...")
	
	; Not testing anything in here right now.

	dsGlobals.gFakeUpdate = False

EndFunction


; -- PrepForDLC
;
Function PrepForDLC()

	Trace(" >>=======> Hunterborn is running compatibility checks.")
	Trace(" >>=======> Ignore Papyrus errors about missing files, immediately below.")
	
	dsGlobals.isSKSELoaded = SKSE.GetVersion()
	
	dsGlobals.isMCMLoaded = Game.GetFormFromFile(0x000814, "SkyUI_SE.esp")
	
;	dsGlobals.isRNDLoaded = Game.GetFormFromFile(0x046497, "RealisticNeedsandDiseases.esp") ; Waterskin (empty) Potion (Ingestible)
	dsGlobals.isRNDLoaded = False

	dsGlobals.isINEEDLoaded = Game.GetFormFromFile(0x001DAF, "iNeed.esp") ; Mild Fatigue (Spell)
	
	dsGlobals.isTanningLoaded = Game.GetFormFromFile(0x800, "Hunterborn - Leather Tanning.esp") ; RecipeLeatherGoatHide_TreeBark [COBJ:05000800]

	; Campfire and Frostfall - more complex set of checks and changes
	CheckForCFFF()
	
;/ Disabled here in SE because supporting them is such a hassle... and PerMa hasn't been ported yet anyway.
	If (dsGlobals.gBlockSkyRe)
		Trace(" >>=======> SkyRe is configured to be BLOCKED.")
		dsGlobals.isSkyReLoaded = False
		dsGlobals.gSkyReAddLeather = False
		dsGlobals.gSkyReLevelWayfarer = False
	Else
		CheckForSkyRe(True)
	EndIf	
	CheckForPerMa(True)
/;

;	dsGlobals.isRequiemLoaded = Game.GetFormFromFile(0x41AB31, "Requiem.esp") ; Troll hide MiscObject
	dsGlobals.isRequiemLoaded = False
	
	dsGlobals.isIALoaded = Game.GetFormFromFile(0x014836, "Hothtrooper44_ArmorCompilation.esp") ; IAAdminQuest "IA Admin" [QUST:03014836] 
;	dsGlobals.isIALoaded = False
	
;	dsGlobals.isDraugnarokLoaded = Game.GetFormFromFile(0x000D63, "Draugnarok.esp") ; _DS_Draugnarok_Main "Draugnarok" [QUST:02000D63]
	dsGlobals.isDraugnarokLoaded = False
	
	dsGlobals.isHiSLoaded = Game.GetFormFromFile(0x07686F, "Hunting in Skyrim.esp") ; HISSkinningTutorialQuest "There's More Than One Way To Skin A..." [QUST:0507686F]
	
	dsGlobals.isSkillsOfTheWildLoaded = Game.GetFormFromFile(0x01007B, "SkillsOfTheWild.esp") ;_CCCookingScript [QUST: 0501007B]
	
	dsAnimals.PrepForDLC()
	dsMonsters.PrepForDLC()

	Trace(" >>=======> Hunterborn compatibility checks are complete.")

EndFunction

; -- CheckForCFFF
;
; Check and prepare for Campfire, and Frostfall
;
Function CheckForCFFF()

	;; CAMPFIRE

	Bool CFAlreadyLoaded = dsGlobals.isCampfireLoaded
;	Bool CFAlreadyLoaded = False
	
	Form f = Game.GetFormFromFile(0x02564C, "Campfire.esm") ; Branches
	
	MiscObject CFbranches
	MiscObject CFdeadwood
	
	dsGlobals.isCampfireLoaded = f
	
	; CF just added
	If !CFAlreadyLoaded && dsGlobals.isCampfireLoaded
		dsGlobals.gEnableFurPlate = True
		CFbranches = f as MiscObject
		CFdeadwood = Game.GetFormFromFile(0x02E68E, "Campfire.esm") as MiscObject
		FirewoodLItem.Revert()
		FirewoodLItem.AddForm(CFbranches, 1, 2)
;		FirewoodLItem.AddForm(CFdeadwood, 1, 1)

	; CF just removed
	ElseIf CFAlreadyLoaded && !dsGlobals.isCampfireLoaded	
		CFAlreadyLoaded = False
		FirewoodLItem.Revert()
		FirewoodLItem.AddForm(Firewood, 1, 1)
		
	ElseIf !dsGlobals.isCampfireLoaded
		FirewoodLItem.Revert()
		FirewoodLItem.AddForm(Firewood, 1, 1)
		
	EndIf
	
	;; FROSTFALL
	
EndFunction

; -- RevertDLC
;
; Anything that must be removed when stopping Hunterborn from MCM.
;
Function RevertDLC()

	;RemoveFrostfall()

EndFunction


; -- FillExternalFormList
;
; Need to add some forms to a FormList in another mod. This can be done with a "patch" (ESP) of course,
; but then there's all the complication of bash patching, end user support, etc. This method does the
; same thing via script. However, it is ONLY safe if the complementary function DrainExternalFormList
; is called later. Otherwise there will be invalid forms on the FormList left stranded in the savegame!
;
Function FillExternalFormList(int aiExternalFormList, string asModFileName, FormList flInternalFormList)

	DebugMode("Filling external FormList " + aiExternalFormList + " in " + asModFileName + " with " + flInternalFormList + " ...")
	Form f = Game.GetFormFromFile(aiExternalFormList, asModFileName)
	If (!f)
		DebugMode("Failed to fill FormList, resource not found!")
		Return
	EndIf
	
	FormList flExternalFormList = f as FormList
	int i = flInternalFormList.GetSize()
	
	If (i == 0)
		DebugMode("FormList is size " + flExternalFormList.GetSize() + ". Fill list is empty, nothing to do.")
		Return
	EndIf
	
	DebugMode("FormList is size " + flExternalFormList.GetSize() + ", " + i + " forms to be added.")
	While (i)
		i -= 1
		f = flInternalFormList.GetAt(i)
		flExternalFormList.AddForm(f)
	EndWhile
	DebugMode("Fill complete, new FormList size is " + flExternalFormList.GetSize())

EndFunction

; -- DrainExternalFormList
;
; The important thing here is to NOT use Revert, since that will remove any forms added to the FormList
; by someone else's scripts, maybe even that mod's own scripts! Instead, manually remove every form
; that was added originally.
;
Function DrainExternalFormList(int aiExternalFormList, string asModFileName, FormList flInternalFormList)

	DebugMode("Draining external FormList" + aiExternalFormList + " in " + asModFileName + " of " + flInternalFormList + " ...")
	Form f = Game.GetFormFromFile(aiExternalFormList, asModFileName)
	If (!f)
		DebugMode("Failed to drain FormList, resource not found!")
		Return
	EndIf
	
	FormList flExternalFormList = f as FormList
	int i = flInternalFormList.GetSize()
	
	If (i == 0)
		DebugMode("FormList is size " + flExternalFormList.GetSize() + ". Fill list is empty, nothing to do.")
		Return
	EndIf
	
	DebugMode("FormList is size " + flExternalFormList.GetSize() + ", " + i + " forms to be added.")
	While (i)
		i -= 1
		f = flInternalFormList.GetAt(i)
		flExternalFormList.RemoveAddedForm(f)
	EndWhile
	DebugMode("Drain complete, new FormList size is " + flExternalFormList.GetSize())

EndFunction

; -- ReassignHotKeys
;
; Called from OnPlayerLoadGame because these may get reverted by other mods.
;
Function ReassignHotKeys()

	ReassignHotkey(dsGlobals.gHotkeyDress, "HotkeyDress")
	ReassignHotkey(dsGlobals.gHotkeySkin, "HotkeySkin")
	ReassignHotkey(dsGlobals.gHotkeyHarvest, "HotkeyHarvest")
	ReassignHotkey(dsGlobals.gHotkeyButcher, "HotkeyButcher")
	ReassignHotkey(dsGlobals.gHotkeyProcess, "HotkeyProcess")
	ReassignHotkey(dsGlobals.gHotkeyForage, "HotkeyForage")
	ReassignHotkey(dsGlobals.gHotkeyScrimshaw, "HotkeyScrimshaw")
	ReassignHotkey(dsGlobals.gHotkeyTaxonomy, "HotkeyTaxonomy")
	ReassignHotkey(dsGlobals.gHotkeySenseDirection, "HotkeySenseDirection")
  ReassignHotkey(dsGlobals.gHotkeyTracking, "HotkeyTracking")
	ReassignHotkey(dsGlobals.gHotkeyPrimitiveCooking, "HotkeyPrimitiveCooking")

EndFunction

Function ReassignHotkey(int aiKeyCode, string akName)

	If aiKeyCode
		RegisterForKey(aiKeyCode)
		DebugMode("Hotkey " + aiKeyCode + " registrationg refresh for " + akName + ".")
	EndIf

EndFunction


; -- ActivateFreshCarcass
;
; Fired when player "clicks" (activates) a dead animal, to begin the cleaning process.
; This script could also fire if the player picked up a carcass and dropped it somewhere else.
; Activate intercept handled by the Perk, _DS_PerkCarcassFresh.
;
Function ActivateFreshCarcass(ObjectReference akCarcassRef, int aiIndex = -1)

	DebugMode("ActivateFreshCarcass on " + akCarcassRef + " ; aiIndex = " + aiIndex)
	
	If CritSection
		DebugMode("Locked out by unfinished Activate event.")
		Return
	EndIf

;/	
	If (dsGlobals.isSkyReLoaded && !dsGlobals.gSkyReGathererWarned && HasSkyReGatherer())
		dsGlobals.gSkyReGathererWarned = True
		MsgBoxSkyReGathererBug.Show()
		Return
	EndIf
/;
	
	If (dsGlobals.gHotkey_HideMenu)
		Return
	EndIf

	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	EndIf

	Actor a = akCarcassRef as Actor
	DebugMode("Actor = " + a)

	If (aiIndex == -1)
		aiIndex = dsAnimals.GetCarcassIndex(a)
		DebugMode("Lookup on aiIndex = " + aiIndex)
		If (aiIndex == -1)
			a = None
		EndIf
	EndIf
	
	; Loophole to handle already-dead 'small game' that have been deactivated.
	If (!dsAnimals.IsActiveAnimal(aiIndex))
		DebugMode("This is a deactivated small-game critter. Exiting ActivateFreshCarcass.")
		a.RemoveItem(dsAnimals.moTokenCarcass_Fresh)
		a = None
	EndIf

	if (!a)
		DebugMode("None Actor. Bypassing ActivateFreshCarcass and activating normally.")
		akCarcassRef.Activate(PlayerRef)
		Return
	EndIf

	int actionToTake
	if (PlayerRef.IsSneaking())
		actionToTake = dsGlobals.gActionFreshCarcassSneak
	Else
		actionToTake = dsGlobals.gActionFreshCarcass
	EndIf
	
	CritSection = True
	Message msgbox = FreshCarcassMsgBoxes[aiIndex]

	; 0	Prompt
	; 1	Pick up
	; 2	Field dress
	; 3	Manual loot
	if (actionToTake == 0)
		int button = msgbox.Show()
		if (button == 0)
			actionToTake = 1
		ElseIf (button == 1)
			actionToTake = 2
		ElseIf (button == 2)
			actionToTake = 3
		Else
			CritSection = False
			Return
		EndIf
	EndIf
	
	DebugMode("actionToTake = " + actionToTake)

	if (actionToTake == 1)
		PickUpCarcass(a, aiIndex)
	ElseIf (actionToTake == 2)
		If (PlayerRef.IsWeaponDrawn() && dsGlobals.gUseAnimation)
			MsgErrorWeaponDrawn.Show()
		Else
			dsActions.FieldDress(a, aiIndex)
		EndIf
	ElseIf (actionToTake == 3)
		akCarcassRef.Activate(PlayerRef)
	ElseIf (actionToTake == 4)
		; Hunterborn 2026: field dress and process (skin, harvest, butcher) in one go.
		If (PlayerRef.IsWeaponDrawn() && dsGlobals.gUseAnimation)
			MsgErrorWeaponDrawn.Show()
		Else
			dsActions.FieldDress(a, aiIndex)
			dsActions.ProcessCarcass(a)
		EndIf
	EndIf

	CritSection = False

EndFunction


; -- ActivateCleanCarcass
;
; Show a prompt for various harvest actions to be taken on a "cleaned" carcass.
; Like ActivateFreshCarcass, called when activating, via Perk _DS_PerkCarcassClean.
;
Function ActivateCleanCarcass(ObjectReference akCarcassRef)

	DebugMode("ActivateCleanCarcass on " + akCarcassRef)

	If CritSection
		DebugMode("Locked out by unfinished Activate event.")
		Return
	EndIf
	
	If (dsGlobals.gHotkey_HideMenu)
		Return
	EndIf

	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	ElseIf (PlayerRef.IsWeaponDrawn() && dsGlobals.gUseAnimation)
		MsgErrorWeaponDrawn.Show()
		Return
	EndIf

	Actor a = akCarcassRef as Actor
	DebugMode("Actor = " + a)
	
	; Determine which actions are available using tokens on the corpse.
	dsGlobals.gSkinningDone = a.GetItemCount(dsActions.moTokenPelt) == 0
	dsGlobals.gHarvestingDone = a.GetItemCount(dsActions.moTokenMat) == 0
	dsGlobals.gButcheringDone = a.GetItemCount(dsActions.moTokenMeat) == 0
	
	int actionToTake
	if (PlayerRef.IsSneaking())
		actionToTake = dsGlobals.gActionCleanCarcassSneak
	Else
		actionToTake = dsGlobals.gActionCleanCarcass
	EndIf
	
	CritSection = True

	; 0 Prompt
	; 1 Process completely
	; 2	Skin
	; 3	Harvest
	; 4	Butcher
	; 5	Dispose
	; 6	Cancel
	If (actionToTake == 0)
		int button = MsgBoxCleanCarcass.Show()
		If (button == 0)
			actionToTake = 2
		ElseIf (button == 1)
			actionToTake = 3
		ElseIf (button == 2)
			actionToTake = 4
		ElseIf (button == 3)
			actionToTake = 5
		Else
			CritSection = False
			Return
		EndIf
	EndIf

	DebugMode("actionToTake = " + actionToTake)

	If (actionToTake == 1)
		dsActions.ProcessCarcass(a)
	ElseIf (actionToTake == 2 && !dsGlobals.gSkinningDone)
		dsActions.SkinCarcass(a, False)
	ElseIf (actionToTake == 3 && !dsGlobals.gHarvestingDone)
		dsActions.HarvestCarcass(a, False)
	ElseIf (actionToTake == 4 && !dsGlobals.gButcheringDone)
		dsActions.ButcherCarcass(a, False)
	ElseIf (actionToTake == 5)
		a.SetCriticalStage(a.CritStage_DisintegrateEnd)
	EndIf
	
	CritSection = False

EndFunction

; -- ActivateEmptyCarcass
;
; This only happens for some animals (Dog, Goat, Hare, Horse) who have DeathItem LI's that have a chance of none.
; The Hunterborn token won't land on the carcass. An additional Perk, _DS_PerkCarcassEmpty, then calls this function.
; The carcass has keyword ActorTypeAnimal, but it remains to be determined if Hunterborn should be handling it.
;
; Addendum: In SE, this can happen for ANY kind of animal if it was used as the carcass to originally activate the mod.
; Therefore this function now needs to be comprehensive.
;
Function ActivateEmptyCarcass(ObjectReference akCarcassRef)

	DebugMode("ActivateEmptyCarcass on " + akCarcassRef)

	If CritSection
		DebugMode("Locked out by unfinished Activate event.")
		Return
	EndIf
	
	Race r = (akCarcassRef as Actor).GetRace()
	DebugMode("Race = " + r)
	int index
	
	If (!r)
		akCarcassRef.Activate(PlayerRef)
		Return
	EndIf
	
	;index = GetIndexFromRace(r)
	;DebugMode("GetIndexFromRace = " + index)
	;If (index == -1)
	
		; For the sake of carcass activation starting the mod, we'll dig a little deeper... using this clever hack!
		DebugMode("Attempting to cast to ActorBase and spawn...")
		Actor a = akCarcassRef as Actor
		ActorBase ab = a.GetActorBase()
		If (ab)
			Actor proxy = SpawnMarker.PlaceActorAtMe(ab)
			proxy.KillSilent()
			index = dsAnimals.GetCarcassIndex(proxy)
			proxy.SetCriticalStage(proxy.CritStage_DisintegrateEnd)
			DebugMode("Proxy GetCarcassIndex = " + index)
			If (index == -1)
				DebugMode("Can't figure out what this is. Giving up.")
				akCarcassRef.Activate(PlayerRef)
				Return
			EndIf
		EndIf
	;EndIf
	
	akCarcassRef.AddItem(dsAnimals.moTokenCarcass_Fresh)
	akCarcassRef.AddItem(dsAnimals.flDeathItemTokens.GetAt(index))
	ActivateFreshCarcass(akCarcassRef, index)
	
EndFunction


; -- ActivateMonsterCarcass
;
; For Monster Hunter.
;
Function ActivateMonsterCarcass(ObjectReference akCarcassRef)

	DebugMode("ActivateMonsterCarcass on " + akCarcassRef)

	If CritSection
		DebugMode("Locked out by unfinished Activate event.")
		Return
	EndIf
	
	Actor a = akCarcassRef as Actor
	Race r = a.GetRace()
	DebugMode("Actor = " + a + " ; Race = " + r)
	
	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	EndIf

	dsGlobals.gMonsterHasVenom = a.GetItemCount(dsActions.moTokenVenom) > 0
	dsGlobals.gMonsterHasBlood = a.GetItemCount(dsActions.moTokenBlood) > 0
	dsGlobals.gMonsterHasSkin = a.GetItemCount(dsActions.moTokenPelt) > 0
	dsGlobals.gMonsterHasMats = a.GetItemCount(dsActions.moTokenMat) > 0
	dsGlobals.gMonsterHasMeat = a.GetItemCount(dsActions.moTokenMeat) > 0
	dsGlobals.gMonsterCanDispose = NotDragonRace(r)
	
	CritSection = True

	int actionToTake
	
	if (PlayerRef.IsSneaking())
		actionToTake = dsGlobals.gActionCleanCarcassSneak
	Else
		actionToTake = dsGlobals.gActionCleanCarcass
	EndIf

	If (actionToTake == 0)
		int button = MsgBoxMonsterCarcass.Show()
		If (button == 0)
			actionToTake = 6 ;Venom
		ElseIf (button == 1)
			actionToTake = 7 ;Blood
		ElseIf (button == 2)
			actionToTake = 2 ;Skin
		ElseIf (button == 3)
			actionToTake = 3 ;Harvest
		ElseIf (button == 4)
			actionToTake = 4 ;Butcher
		ElseIf (button == 5)
			actionToTake = 8 ;Search
		ElseIf (button == 6)
			actionToTake = 5 ;Dispose
		Else
			CritSection = False
			Return
		EndIf
	EndIf
	
	DebugMode("actionToTake = " + actionToTake + "; dsGlobals.gMonsterCanDispose = " + dsGlobals.gMonsterCanDispose)
	
	If (PlayerRef.IsWeaponDrawn() && actionToTake < 7 && dsGlobals.gUseAnimation)
		MsgErrorWeaponDrawn.Show()
	ElseIf (actionToTake == 1)
		dsActions.ProcessCarcass(a, True)
	ElseIf (actionToTake == 2)
		dsActions.SkinCarcass(a, True)
	ElseIf (actionToTake == 3)
		dsActions.HarvestCarcass(a, True)
	ElseIf (actionToTake == 4)
		dsActions.ButcherCarcass(a, True)
	ElseIf (actionToTake == 5 && dsGlobals.gMonsterCanDispose)
		a.SetCriticalStage(a.CritStage_DisintegrateEnd)
	ElseIf (actionToTake == 6)
		dsActions.ExtractVenom(a, False)
	ElseIf (actionToTake == 7)
		dsActions.ExtractBlood(a, False)
	ElseIf (actionToTake == 8)
		dsActions.SearchTreasure(a)
	EndIf
	
	CritSection = False

EndFunction


; -- PickUpCarcass
;
; Add a placeholder item to player's inventory, make the body on the ground disappear.
;
Function PickUpCarcass(Actor akCarcassRef, int aiIndex)

	If (dsGlobals.gPreventOverburden && PlayerRef.GetAV("InventoryWeight") >= PlayerRef.GetAV("CarryWeight"))
		MsgErrorCarryingTooMuch.Show()
		Return
	EndIf
	
	MiscObject mo = dsAnimals.flCarcassObjects.GetAt(aiIndex) as MiscObject

	;/
	If (dsGlobals.gPreventOverburden && PlayerRef.GetAV("CarryWeight") * 1.5 < mo.GetWeight())
		MsgErrorCarcassTooHeavy.Show()
		Return
	EndIf
	/;
	
;	DebugMode("PickupCarcass akCarcassRef = " + akCarcassRef + " ; aiIndex = " + aiIndex + " ; CarcassObject = " + mo)
	
	akCarcassRef.Disable()
	; Try a second time
	If akCarcassRef.IsEnabled()
		akCarcassRef.Disable()
	EndIf
	If akCarcassRef.IsEnabled()
		; Workaround for an obscure bug where some dead animals do not respond to Disable/Enable/MoveTo.
		DebugMode("Uh oh, can't add this to array. Disposed instead.")
		akCarcassRef.SetCriticalStage(akCarcassRef.CritStage_DisintegrateEnd)
	Else
		DebugMode("Adding to array...")
		dsCarcassArray.AddCarcass(akCarcassRef)
	EndIf
	
	PlayerRef.AddItem(mo)

EndFunction


; -- DropCarcass
;
; Called by the Player's OnItemRemoved.
; "Drop" the carcass by deleting the MiscObject, moving / enabling the associated Actor (body).
; If the array doesn't have a matching Actor, a new one is created here for sanitation.
;
Function DropCarcass(ObjectReference akPlaceholder, int aiCount)

	MiscObject mo = akPlaceholder.GetBaseObject() as MiscObject
	Actor ref
	int i = aiCount
	While (i)
		i -= 1
		ref = dsCarcassArray.GetCarcass(mo)
		if (ref)
			ref.MoveTo(PlayerRef, 0, 0, PlayerRef.GetHeight() + 5)
			ref.Enable()
		Else
			ref = dsAnimals.SpawnNew(mo)
			ref.KillSilent()
			ref.MoveTo(PlayerRef)
		EndIf
	EndWhile

	dsCarcassArray.DeleteCarcass(mo, aiCount, False)
	akPlaceholder.Delete()

EndFunction


; -- GetIndexFromRace
;
int Function GetIndexFromRace(Race akRace)

	If ((akRace == DogRace || akRace == DogCompanionRace) && dsGlobals.gIncludeDog)
		Return dsAnimals.INDEX_DOG
	ElseIf (akRace == GoatRace || akRace == GoatDomesticsRace)
		Return dsAnimals.INDEX_GOAT
	ElseIf (akRace == HareRace && dsGlobals.gIncludeHare)
		Return dsAnimals.INDEX_HARE
	ElseIf (akRace == HorseRace || akRace == CartHorseRace)
		Return dsAnimals.INDEX_HORSE
	Else
		Return -1
	EndIf
		
EndFunction

; -- NotDragonRace
;
bool Function NotDragonRace(Race akRace)

	Return (akRace != DragonRace && akRace != UndeadDragonRace && akRace != DLC1UndeadDragonRace)

EndFunction


; -- HircinesVigil
;
; Story Manager Event KillActor fires this, if Draugnarok is also running and player killed a Draugr.
; (Draugnarok "quest" does not need to be started, just because it would be complicated to code.)
; Manages the ability-like effect "Hircine's Vigil", a secret reward of running both mods together.
;
Function HircinesVigil()

	; player.placeatme 1fe86 3
	If PlayerRef.HasSpell(spellHircinesVigil)
		; Shroud Passing
		If PlayerRef.HasSpell( flRitePowers.GetAt(0) as Spell ) && Utility.RandomInt() > 85
			If Utility.RandomInt() > 65
				spellHealthBurst.Cast(PlayerRef)
			Else
				spellStaminaBurst.Cast(PlayerRef)
			EndIf
		EndIf
		; Shepherd Beasts
		If PlayerRef.HasSpell( flRitePowers.GetAt(1) as Spell ) && Utility.RandomInt() > 85
			Actor familiar = PlayerRef.PlaceActorAtMe(abSpiritWolf)
			familiar.PlaceAtMe(SummonTargetFXActivator)
			familiar.SetRelationshipRank(PlayerRef, 3)
			familiar.SetPlayerTeammate(abCanDoFavor = false)
		EndIf
		; Uh oh...
		If PlayerRef.HasPerk(perkHeartwoodBow) && Utility.RandomInt() >= 99
			;Debug.Notification("Uh oh...")
			DebugMode("Uh oh...")
			Actor dmd = DmdSpawnRef.PlaceActorAtMe(abDMD)
		EndIf
	Else
		PlayerRef.AddSpell(spellHircinesVigil)
	EndIf

EndFunction


; -- ReleaseCritSection
;
Function ReleaseCritSection()
	CritSection = False
EndFunction

; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
