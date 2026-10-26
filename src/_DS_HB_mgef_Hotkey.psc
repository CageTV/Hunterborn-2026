Scriptname _DS_HB_mgef_Hotkey extends activemagiceffect  
;
; Hunterborn 2026: this script contains the Process Hotkey Fix by Gasil (Nexus 73571, used with credit; modification is allowed by the author): the Process hotkey handles monsters.
;

_DS_HB_MAIN Property dsMain Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Globals Property dsGlobals Auto
_DS_HB_Monsters Property dsMonsters Auto ;Gasil: To be able to use this script's functions.

Actor Property PlayerRef Auto

int Property HotkeyAction Auto

Message Property MsgErrorCantInCombat Auto
Message Property MsgErrorWeaponDrawn Auto

;Spell Property ForageSpell Auto
;Spell Property ScrimshawSpell Auto
;Spell Property TaxonomySpell Auto
;Spell Property SenseDirectionSpell Auto

int Property ACTION_DRESS			= 0		AutoReadOnly
int Property ACTION_SKIN			= 1		AutoReadOnly
int Property ACTION_HARVEST			= 2		AutoReadOnly
int Property ACTION_BUTCHER			= 3		AutoReadOnly
int Property ACTION_PROCESS			= 4		AutoReadOnly
;int Property ACTION_FORAGE			= 5		AutoReadOnly
;int Property ACTION_SCRIMSHAW		= 6		AutoReadOnly
;int Property ACTION_TAXONOMY		= 7		AutoReadOnly
;int Property ACTION_SENSEDIRECTION	= 8		AutoReadOnly


Event OnEffectStart(Actor akTarget, Actor akCaster)

	;Debug.MessageBox("Target: " + akTarget + "\nCaster: " + akCaster)

	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	EndIf
	
	;Gasil: Check if player pressed Process hotkey.
	If (HotkeyAction == ACTION_PROCESS)

		;Gasil: Check if target is a monster using a custom function of mine in _DS_HB_Monster
		bool animalMonster = dsMonsters.GetCarcassType(akTarget)
		if(animalMonster == true)

			;Gasil: If player is in combat and has mcm settings as in "prevent in combat = enabled", show message and exit this function returning nothing.
			If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
				MsgErrorCantInCombat.Show()
				Return
			;Gasil: If player has weapon drawn and has mcm settings as in "use animation = enabled", show message and exit this function returning nothing.
			ElseIf (dsGlobals.gUseAnimation && PlayerRef.IsWeaponDrawn())
				MsgErrorWeaponDrawn.Show()
				Return
			EndIf

			;Gasil: This gets the hardcoded (by the original author) carcass index of the monster to check if it is enabled on MCM. 
			int index = dsMonsters.GetCarcassIndex(akTarget)
			If (dsMonsters.isActiveMonster(index))

					;Gasil: Using Process carcass setting "is a monster" argument as true, this was the culprit of hotkey not working as expected.
					;ProcessCarcass function was called only once at the bottom of this function, with the argument as false, thus disabling the hotkey functionality for monsters.
					dsActions.ProcessCarcass(akTarget, True)
			EndIf
		endIf
	;Gasil: If player didn't press Process hotkey, proceed normally.
	endIf


	int aiIndex

	; "Empty" carcass or non-valid target?
	bool fresh = akTarget.GetItemCount(dsAnimals.moTokenCarcass_Fresh) > 0
	bool clean = akTarget.GetItemCount(dsAnimals.moTokenCarcass_Clean) > 0
	If (!fresh && !clean)
		Race r = akTarget.GetRace()
		If (!r)
			Return
		EndIf
		aiIndex = dsMain.GetIndexFromRace(r)
		If (aiIndex == -1)
			Return
		EndIf
		akTarget.AddItem(dsAnimals.moTokenCarcass_Fresh)
		akTarget.AddItem(dsAnimals.flDeathItemTokens.GetAt(aiIndex))
		fresh = True
	Else	
		aiIndex = dsAnimals.GetCarcassIndex(akTarget)
	EndIf
	
	If (aiIndex == -1 || !dsAnimals.IsActiveAnimal(aiIndex))
		Return
	EndIf
	
	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	ElseIf (dsGlobals.gUseAnimation && PlayerRef.IsWeaponDrawn())
		MsgErrorWeaponDrawn.Show()
		Return
	EndIf
	
	If (HotkeyAction == ACTION_DRESS && fresh)
		dsActions.FieldDress(akTarget, aiIndex)
	ElseIf (fresh)
		Return
	ElseIf (HotkeyAction == ACTION_SKIN && akTarget.GetItemCount(dsActions.moTokenPelt) > 0)
		dsActions.SkinCarcass(akTarget, False)
	ElseIf (HotkeyAction == ACTION_HARVEST && akTarget.GetItemCount(dsActions.moTokenMat) > 0)
		dsActions.HarvestCarcass(akTarget, False)
	ElseIf (HotkeyAction == ACTION_BUTCHER && akTarget.GetItemCount(dsActions.moTokenMeat) > 0)
		dsActions.ButcherCarcass(akTarget, False)
	ElseIf (HotkeyAction == ACTION_PROCESS)
		dsActions.ProcessCarcass(akTarget, False)
	EndIf

EndEvent
