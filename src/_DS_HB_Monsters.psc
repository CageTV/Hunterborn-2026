Scriptname _DS_HB_Monsters extends Quest
;
; Hunterborn 2026: this script contains the Process Hotkey Fix by Gasil (Nexus 73571, used with credit; modification is allowed by the author): adds the monster token property and GetCarcassType (fixes the Process hotkey on monsters).
;

_DS_HB_Globals Property dsGlobals Auto


; PROPERTIES --------------------------------------------------------------------------------------

int Property INDEX_CHAURUS			= 0		AutoReadOnly
int Property INDEX_SPIDER			= 1		AutoReadOnly
int Property INDEX_SPIDERGIANT		= 2		AutoReadOnly
int Property INDEX_SPRIGGAN			= 3		AutoReadOnly ; Removed. May be added back later...
int Property INDEX_TROLL			= 4		AutoReadOnly
int Property INDEX_TROLLFROST		= 5		AutoReadOnly
int Property INDEX_WEREWOLF			= 6		AutoReadOnly
int Property INDEX_DRAGON			= 7		AutoReadOnly
int Property INDEX_CHAURUS_HUNTER	= 8		AutoReadOnly
int Property INDEX_WEREBEAR	        = 9     AutoReadOnly
int Property INDEX_SPRIGGANBURNT    = 10    AutoReadOnly

FormList Property flDeathItems Auto
GlobalVariable[] Property ActiveMonsterSwitches Auto
LeveledItem[] Property DeathItemLI Auto
FormList[] Property SharedDeathItems Auto
String[] Property MonsterIndex Auto
LeveledItem Property DragonCorporealLI Auto

FormList Property flCarcassesFresh Auto
FormList Property flCarcassObjects Auto
MiscObject Property moTokenCarcass_Monster Auto
MiscObject Property _DS_Token_Carcass_Monster Auto ;Gasil: This non-playable item is added to every monster, used for a check.
int[] Property CarcassSizes Auto
;float[] Property CarcassWeights Auto
FormList Property flDeathItemTokens Auto
Keyword Property kwDeathItemToken Auto

ObjectReference Property SpawnMarker Auto

Potion[] Property VenomTypes Auto

Potion[] Property BloodTypes Auto

FormList Property flPeltLists Auto
int[] Property MultiPelts Auto
int[] Property DefaultPeltValues Auto

FormList Property flMatLists Auto
FormList Property flMatsDragonCorporeal Auto
FormList Property flPerfectMats Auto

Potion[] Property MeatTypes Auto
float[] Property AllMeatWeights Auto

FormList[] Property NegativeTreasure Auto

; DLC stuff...


; FUNCTIONS ---------------------------------------------------------------------------------------

; -- InitDeathItems
;
; Same deal as in _DS_HB_Animals.
;
Function InitDeathItems(bool abRevertAll = False)

	DebugMode("Monster InitDeathItems abRevertAll = " + abRevertAll)

	int i
	int j
	FormList fl
	FormList share
	LeveledItem di	
	LeveledItem dragon_di

	; Shares not currently compatible with dragons.
	DebugMode("Configuring Shared FormLists.")
	i = SharedDeathItems.Length
	While i
		i -= 1
		DebugMode("Index " + i + "...")
		share = SharedDeathItems[i]
		If share
			DebugMode("Share = " + share)
			di = DeathItemLI[i]
			If MonsterIndex[i] == "Dragon" && dsGlobals.gDragonsCorporeal
				DebugMode("[Corporeal Dragon] Shared with " + DragonCorporealLI)
				di = DragonCorporealLI
			EndIf
			If abRevertAll
				If share.HasForm(moTokenCarcass_Monster)
					DebugMode("RemoveAddedForm " + moTokenCarcass_Monster)
					share.RemoveAddedForm(moTokenCarcass_Monster)
				EndIf
				If share.HasForm(flDeathItemTokens.GetAt(i))
					DebugMode("RemoveAddedForm " + flDeathItemTokens.GetAt(i))
					share.RemoveAddedForm(flDeathItemTokens.GetAt(i))
				EndIf
				If share.HasForm(di)
					DebugMode("RemoveAddedForm " + di)
					share.RemoveAddedForm(di)
				EndIf
			Else
				If !share.HasForm(moTokenCarcass_Monster)
					DebugMode("AddForm " + moTokenCarcass_Monster)
					share.AddForm(moTokenCarcass_Monster)
				EndIf
				If !share.HasForm(flDeathItemTokens.GetAt(i))
					DebugMode("AddForm " + flDeathItemTokens.GetAt(i))
					share.AddForm(flDeathItemTokens.GetAt(i))
				EndIf
				If !share.HasForm(di)
					DebugMode("AddForm " + di)
					share.AddForm(di)
				EndIf
			EndIf
		EndIf
	EndWhile

	DebugMode("Init death items.")
	i = flDeathItems.GetSize()
	While (i)
		i -= 1
		DebugMode("Index " + i + "...")
		di = flDeathItems.GetAt(i) as LeveledItem
		di.Revert()
		share = SharedDeathItems[i]
		If (!abRevertAll && IsActiveMonster(i))
			If share
				DebugMode("This death item is shared.")
				j = share.GetSize()
				While j
					j -= 1
					DebugMode("AddForm " + share.GetAt(j))
					di.AddForm( share.GetAt(j), 1, 1 )
				EndWhile
			Else
				DebugMode("AddForm " + moTokenCarcass_Monster)
				di.AddForm(moTokenCarcass_Monster, 1, 1)
				DebugMode("AddForm " + flDeathItemTokens.GetAt(i))
				di.AddForm(flDeathItemTokens.GetAt(i), 1, 1)
				If (MonsterIndex[i] == "Dragon" && dsGlobals.gDragonsCorporeal)
					DebugMode("[Corporeal Dragon] AddForm " + DragonCorporealLI)
					di.AddForm(DragonCorporealLI, 1, 1)
				Else
					DebugMode("AddForm " + DeathItemLI[i])
					di.AddForm(DeathItemLI[i], 1, 1)
				EndIf
			EndIf
		EndIf
	EndWhile
	
	; Hunterborn 2026 AutoPatch: the same for the monsters other mods add (see _DS_HB_Animals).
	i = flDeathItems.GetSize()
	While i
		i -= 1
		LeveledItem[] extra = HunterbornNative.GetLists(True, i)
		If extra
			j = extra.Length
			While j
				j -= 1
				extra[j].Revert()
				If !abRevertAll && IsActiveMonster(i)
					extra[j].AddForm(moTokenCarcass_Monster, 1, 1)
					extra[j].AddForm(flDeathItemTokens.GetAt(i), 1, 1)
					If (MonsterIndex[i] == "Dragon" && dsGlobals.gDragonsCorporeal)
						extra[j].AddForm(DragonCorporealLI, 1, 1)
					Else
						extra[j].AddForm(DeathItemLI[i], 1, 1)
					EndIf
				EndIf
			EndWhile
		EndIf
	EndWhile

	DebugMode("Monster InitDeathItems done!")
	
EndFunction

Function InitTaxonomized(Actor akCarcassRef, int aiIndex)

  akCarcassRef.AddItem(moTokenCarcass_Monster)
  akCarcassRef.AddItem(flDeathItemTokens.GetAt(aiIndex))
  If (MonsterIndex[aiIndex] == "Dragon" && dsGlobals.gDragonsCorporeal)
    akCarcassRef.AddItem(DragonCorporealLI)
  Else
    akCarcassRef.AddItem(DeathItemLI[aiIndex])
  EndIf

EndFunction


; -- IsActiveMonster
;
bool Function IsActiveMonster(int aiIndex)

	GlobalVariable g = ActiveMonsterSwitches[aiIndex]
	Return (g == None || g.GetValueInt() == 1)

EndFunction


; -- SpawnNew
;
Actor Function SpawnNew(MiscObject akPlaceholder)
;	Return SpawnMarker.PlaceActorAtMe( flCarcassesFresh.GetAt( flCarcassObjects.Find(akPlaceholder) ) as ActorBase )
	Return None
EndFunction


; -- GetCarcassToken
;
MiscObject Function GetCarcassToken(MiscObject akPlaceholder)
	Return (flDeathItemTokens.GetAt( flCarcassObjects.Find(akPlaceholder) ) as MiscObject)
EndFunction

; -- GetCarcassIndex
;
int Function GetCarcassIndex(Actor akCarcassRef)

	Form f
	
	; SKSE method
	int n = akCarcassRef.GetItemCount(kwDeathItemToken)
	If (n)
		n = akCarcassRef.GetNumItems()
	EndIf
	While (n)
		n -= 1
		f = akCarcassRef.GetNthForm(n)
		If (f.HasKeyword(kwDeathItemToken))
			Return flDeathItemTokens.Find(f)
		EndIf
	EndWhile
	;/
	int n = flDeathItemTokens.GetSize()
	While n
		n -= 1
		f = flDeathItemTokens.GetAt(n)
		If (akCarcassRef.GetItemCount(f) > 0)
			Return n
		EndIf
	EndWhile
	/;
	Return -1

EndFunction

;Gasil: with this function I can check if the carcass upon you press the process hotkey is a monster or else.
Bool Function GetCarcassType(Actor akCarcassRef)

	;Initialize.
	Form theItem
	Int n

	;Get the number of items in the corpse.
	n = akCarcassRef.GetNumItems()

	;Iterate through all the items.
	While (n > 0)

		;Get the form of the item in turn.
		theItem = akCarcassRef.GetNthForm(n)

		;Check if the item in question is a monster token. (Every "monster" is provided with this item by this mod on initialization - hardcoded)
		If (theItem == _DS_Token_Carcass_Monster)

			;Return positive to "true, this corpse is a monster's"
			Return true
		EndIf
		n -= 1
	EndWhile

	;Loop failed to find monster token, return "false, this is an animal or else corpse."
	Return false
EndFunction


; -- GetMeatWeight
;

float Function GetMeatWeight(int aiIndex)
	If (aiIndex < 0)
		Return 1
	Else
		Return AllMeatWeights[aiIndex]
	EndIf
EndFunction



; -- PrepForDLC
;
; Dynamically load in DLC resources if they're available.
;
Function PrepForDLC()
	
	; Dawnguard
	;
	
	; Hearthfire
	;
	
	; Dragonborn
	;

EndFunction


; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Debug.Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
