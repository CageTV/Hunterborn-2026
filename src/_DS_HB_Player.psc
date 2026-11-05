Scriptname _DS_HB_Player extends ReferenceAlias

; PROPERTIES --------------------------------------------------------------------------------------

Actor Property PlayerRef Auto

_DS_HB_MAIN Property dsMain Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Monsters Property dsMonsters Auto
_DS_HB_Items Property dsItems Auto
_DS_HB_Pet_Finder Property dsPetFinder Auto
_DS_HB_SoupManager Property dsSoupMgr Auto
_DS_HB_Globals Property dsGlobals Auto
_DS_HB_CarcassArray Property dsCarcassArray Auto

FormList Property flCarcassObjects Auto
FormList Property flPetItems Auto
FormList Property flPetActors Auto
FormList Property flPetLures Auto
FormList Property flMeatsRaw Auto
FormList Property flBoneArrows Auto

Keyword Property kwUseItem Auto
Keyword Property kwHuntingKnife Auto
Keyword Property kwPet Auto
Keyword Property kwPetLure Auto
Keyword Property kwSoup Auto
Keyword Property kwColdSoup Auto

Potion Property foodSmellyMeat Auto
ActorBase Property npcHungryWolf Auto
ActorBase Property npcFoxArctic Auto

Weapon Property weapBoneDiviningKnife Auto
Spell Property spellBoneDiviningKnife Auto

MiscObject Property miscKettle Auto
MiscObject Property miscPot1 Auto
MiscObject Property miscPot2 Auto
MiscObject Property miscWoodBowl Auto

Spell Property spellSoupsStews Auto

Message Property MsgErrorNoStashing Auto
Message Property MsgDontEatIt Auto
Message Property MsgTastySnack Auto
Message Property MsgGotOne Auto
Message Property MsgGotNone Auto
Message Property MsgGotWolf Auto


; PRIVATE VARIABLES -------------------------------------------------------------------------------

Actor[] CurrentPets

int		_PET_HARE		= 0
int		_PET_FOX		= 1
int		_PET_FOX_ARCTIC	= 2


; INITIALIZATION ----------------------------------------------------------------------------------

Event OnInit()

	CurrentPets = new Actor[16]
	
EndEvent

; EVENTS ------------------------------------------------------------------------------------------

; -- OnItemRemoved
;
; Trapped because OnContainerChanged is practically useless!
; - It doesn't handle dropping a stack correctly.
; - It won't have the object reference on a container change (only if the object is dropped).
;
; Hunterborn 2026: no OnItemRemoved / OnItemAdded events any more. The game sends those for EVERY item the player gets or
; loses (one script call each), so a big Take All / Store All froze the script VM. HunterbornNative.dll (ItemEvents.cpp)
; watches the game's container changes in C++ and calls these two functions only for the items they handle: carcasses,
; hunting knives, the Bone Divining Knife, pets, pet lures and soup. Same parameters, same bodies as the events had.
Function HB_ItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)

	; Carcasses
	;
	If flCarcassObjects.HasForm(akBaseItem)
		DebugMode("Player.OnItemRemoved akBaseItem = " + akBaseItem + "; aiItemCount = " + aiItemCount + "; akItemReference = " + akItemReference + "; akDestContainer = " + akDestContainer)
		DebugMode("CarcassObject...")
	
		; You dropped a carcass. Make the real body appear here.
		If (!akDestContainer)
			dsMain.DropCarcass(akItemReference, aiItemCount)

		; You're selling one or more carcasses.
		; That's fine, but the carcass is "wiped" to keep array bloat down. If it gets bought back, dropping it spawns an entirely new corpse. Any unique loot (like ammo) is lost.
		; Also: Thank god for SKSE. Thank you jeeeezus
		ElseIf (UI.IsMenuOpen("BarterMenu"))
			dsCarcassArray.DeleteCarcass(akBaseItem as MiscObject, aiItemCount)

		; Trying to stash the carcass in some other container.
		; Allowed for smaller corpses, though it gets "wiped" as above. [Optionally] Not allowed for bigger corpses because... cmon. A bear in a barrel?
		Else

			If (akItemReference.GetWeight() > 50.0 && dsGlobals.gPreventBearStash)
				MsgErrorNostashing.Show()
				akDestContainer.RemoveItem(akBaseItem, aiItemCount, True, PlayerRef)
			Else
				dsCarcassArray.DeleteCarcass(akBaseItem as MiscObject, aiItemCount)
			EndIf
							
		EndIf
		
	; Hunting knives
	;
	ElseIf akBaseItem.HasKeyword(kwHuntingKnife)	
		DebugMode("Player.OnItemRemoved akBaseItem = " + akBaseItem + "; aiItemCount = " + aiItemCount + "; akItemReference = " + akItemReference + "; akDestContainer = " + akDestContainer)
		DebugMode("HuntingKnife...")
		dsGlobals.gHuntingKnife = -1
		dsActions.GetHuntingKnife(True)
		
	; Bone Divining Knife
	ElseIf akBaseItem == weapBoneDiviningKnife
		DebugMode("Player.OnItemRemoved akBaseItem = " + akBaseItem + "; aiItemCount = " + aiItemCount + "; akItemReference = " + akItemReference + "; akDestContainer = " + akDestContainer)
		DebugMode("BoneDiviningKnife...")
		Game.DisablePlayerControls()
		Game.EnablePlayerControls()
		akItemReference.Disable(True)
		spellBoneDiviningKnife.Cast(PlayerRef)
		
	; Pets and pet lures
	;
	ElseIf akBaseItem.HasKeyword(kwPet) && !akDestContainer
		DebugMode("Player.OnItemRemoved akBaseItem = " + akBaseItem + "; aiItemCount = " + aiItemCount + "; akItemReference = " + akItemReference + "; akDestContainer = " + akDestContainer)
		DebugMode("Pet...")
		int index = flPetItems.Find(akBaseItem)
		If index > -1
			Actor pet = PlayerRef.PlaceActorAtMe( flPetActors.GetAt(index) as ActorBase )
			pet.SetAV("Lockpicking", 0)
			pet.SetRelationshipRank(Game.GetPlayer(), 3)
			pet.SetPlayerTeammate(abCanDoFavor = false)
			CurrentPets[index] = pet
		EndIf
		akItemReference.Disable(True)
		;akItemReference.DeleteWhenAble()
	ElseIf akBaseItem.HasKeyword(kwPetLure) && !akDestContainer
		DebugMode("Player.OnItemRemoved akBaseItem = " + akBaseItem + "; aiItemCount = " + aiItemCount + "; akItemReference = " + akItemReference + "; akDestContainer = " + akDestContainer)
		DebugMode("PetLure...")
		; Since this is food, check whether it was dropped or eaten:
		If akItemReference == None
			MsgDontEatIt.Show()
			Return
		EndIf
		Game.DisablePlayerControls()
		Game.EnablePlayerControls()
		akItemReference.Disable(True)
		;akItemReference.DeleteWhenAble()
		If akBaseItem == foodSmellyMeat
			dsPetFinder.Start()
			Actor found = dsPetFinder.Result_Wolf.GetActorRef()
			DebugMode("found = " + found)
			If found != None
				Actor wolf = found.PlaceActorAtMe(npcHungryWolf)
				found.Disable();
				found.SetCriticalStage(found.CritStage_DisintegrateEnd)
				MsgGotWolf.Show()
			Else
				MsgGotNone.Show()
			EndIf
			dsPetFinder.Stop()
			dsPetFinder.Reset()
			Return
		EndIf
		int index = flPetLures.Find(akBaseItem)
		DebugMode("index = " + index)
		If index > -1
			; Blargh...
			If index == _PET_FOX
				If CurrentPets[_PET_FOX_ARCTIC] != None && CurrentPets[_PET_FOX_ARCTIC].IsDead()
					CurrentPets[_PET_FOX] = None
					CurrentPets[_PET_FOX_ARCTIC] = None
				EndIf
				If CurrentPets[_PET_FOX_ARCTIC] != None || PlayerRef.GetItemCount( flPetItems.GetAt(_PET_FOX_ARCTIC) ) > 0
					CurrentPets[_PET_FOX_ARCTIC].MoveTo(PlayerRef)
					DebugMode("A tasty snack for " + CurrentPets[_PET_FOX_ARCTIC])
					MsgTastySnack.Show()
					Return
				EndIf
			EndIf
			If CurrentPets[index] != None && CurrentPets[index].IsDead()
				CurrentPets[index] = None
			EndIf
			If CurrentPets[index] != None || PlayerRef.GetItemCount( flPetItems.GetAt(index) ) > 0
				CurrentPets[index].MoveTo(PlayerRef)
				DebugMode("A tasty snack for " + CurrentPets[index])
				MsgTastySnack.Show()
				Return
			EndIf
			dsPetFinder.Start()
			Actor found = dsPetFinder.Results[index].GetActorRef()
			DebugMode("found = " + found + "; ActorBase = " + found.GetActorBase())
			;Debug.Notification("Found: " + found)
			If found != None
				; Crude hack for snow fox.
				DebugMode("npcFoxArctic = " + npcFoxArctic)
				If index == _PET_FOX && found.GetActorBase() == npcFoxArctic
					index = _PET_FOX_ARCTIC
					DebugMode("Updated index for PET_FOX_ARCTIC")
				EndIf
				Actor pet = found.PlaceActorAtMe( flPetActors.GetAt(index) as ActorBase )
				DebugMode("Spawned pet = " + pet)
				pet.SetAV("Lockpicking", 0)
				pet.SetRelationshipRank(Game.GetPlayer(), 3)
				pet.SetPlayerTeammate(abCanDoFavor = false)
				CurrentPets[index] = pet
				found.Disable()
				found.SetCriticalStage(found.CritStage_DisintegrateEnd)
				MsgGotOne.Show()
			Else
				MsgGotNone.Show()
			EndIf
			dsPetFinder.Stop()
			dsPetFinder.Reset()
		EndIf
	
	; Hot Soup - inform the soup manager
	;
	ElseIf akBaseItem.HasKeyword(kwSoup) && !akBaseItem.HasKeyword(kwColdSoup)
		dsSoupMgr.RemoveHotSoup(akBaseItem, aiItemCount, akItemReference, akDestContainer)
		
	EndIf

EndFunction

; -- OnItemAdded
;
Function HB_ItemAdded(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)

	; Hunting knives
	;
	If akBaseItem.HasKeyword(kwHuntingKnife)
		dsActions.SetHuntingKnife(akBaseItem)
		
	; Hot Soup - goes cold in 5 minutes
	;
	ElseIf akBaseItem.HasKeyword(kwSoup) && !akBaseItem.HasKeyword(kwColdSoup)
		dsSoupMgr.AddHotSoup(akBaseItem, aiItemCount)

	EndIf

EndFunction

; -- OnObjectEquipped
;
; For anything that can be 'used', like Scrimshaw's MiscObjects.
;
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)

	If (akBaseObject.HasKeyword(kwUseItem))
		dsItems.UseItem(akBaseObject, akReference)
		
	; 1.6 experimental feature: Bleeding damage on arrows.
	; Currently needs no scripting...
;	ElseIf (akBaseObject as Ammo)
;		int index = flBoneArrows.Find(akBaseObject)
;		If index > -1
;			Debug.Notification("HB ammo equipped: " + index)
;		Else
;			Debug.Notification("Non-HB ammo equipped.")
;		EndIf

;	Using Perks instead. LearnEffect doesn't update the UI.
;		
;	ElseIf (akBaseObject.GetType() == 30 && !akReference)
;		Ingredient ing = akBaseObject as Ingredient
;		If !ing
;			Return
;		EndIf
;		int ForageLevel = dsGlobals.gForageLevel
;		If ForageLevel >= 8
;			ing.LearnEffect(1)
;		EndIf
;		If ForageLevel >= 9
;			ing.LearnEffect(2)
;		EndIf
;		If ForageLevel >= 10
;			ing.LearnEffect(3)
;		EndIf

	; Soups and Stews, kicked off with generic items
	ElseIf dsGlobals.gEnableSoupsStews && (akBaseObject == miscKettle || akBaseObject == miscPot1 || akBaseObject == miscPot2)
		; Close the inventory screen
		Game.DisablePlayerControls()
		Game.EnablePlayerControls()
		; mgef script handles all the checks like heat source and water
		spellSoupsStews.Cast(PlayerRef)

	; Consumed soup
	ElseIf akBaseObject.HasKeyword(kwSoup) && dsGlobals.gSoupReturnBowl
		PlayerRef.AddItem(miscWoodBowl, 1)
		
	EndIf

EndEvent

; -- OnPlayerLoadGame
;
; Bootstrap stuff, like dyna-DLC scripts and SKSE changes that don't persist across saves.
;
Event OnPlayerLoadGame()

	Utility.Wait(1.0)

	If (!dsGlobals.gHunterbornActive)
		Return
	EndIf
	
	dsMain.PrepForDLC()
	dsMain.ReleaseCritSection()
	
	dsMain.ReassignHotKeys()
	
	; Reinstate non-persistent SKSE changes to Forms.
	;

	Utility.Wait(3.0)
;	dsAnimals.ReweighMeat()
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsAnimals.flPeltLists, dsAnimals.DefaultPeltValues)
	dsAnimals.SetPeltValues(dsGlobals.gPeltValue, dsMonsters.flPeltLists, dsMonsters.DefaultPeltValues)
	
EndEvent


; FUNCTIONS ---------------------------------------------------------------------------------------

bool Function HasPet(int aiIndex)

	; In my pack?
	If PlayerRef.GetItemCount( flPetItems.GetAt(aiIndex) ) > 0
		Return True
	
	; Out for a walk?
	ElseIf CurrentPets[aiIndex] != None && !CurrentPets[aiIndex].IsDead()
		Return True
	
	EndIf
	
	Return False

EndFunction

bool Function HasPetHare()
	Return HasPet(_PET_HARE)
EndFunction

bool Function HasPetFox()
	Return HasPet(_PET_FOX)
EndFunction


; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Debug.Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
