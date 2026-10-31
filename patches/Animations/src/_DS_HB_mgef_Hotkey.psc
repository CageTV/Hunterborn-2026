; Hunterborn 2026 - Animations patch. Hunterborn Animations (Nexus 80677) by Elsawirr (animations) and GiraPomba (scripts) is the source of the animation calls
; in this script; the author allows modifying the files with credit, and asks that patches require the mod. Their version, unchanged (it already contains a Process hotkey fix for monsters).
; Needs Hunterborn - Animations installed (the animation calls look its quest up at run time and do nothing without it).
Scriptname _DS_HB_mgef_Hotkey extends activemagiceffect  

_DS_HB_MAIN Property dsMain Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Globals Property dsGlobals Auto

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

	dsMain.gpAnimFunctions.CheckWeaponsDrawn()
	
	If (dsGlobals.gPreventInCombat && PlayerRef.IsInCombat())
		MsgErrorCantInCombat.Show()
		Return
	ElseIf (dsGlobals.gUseAnimation && PlayerRef.IsWeaponDrawn())
		MsgErrorWeaponDrawn.Show()
		Return
	EndIf

	int aiIndex
	bool isAnimal = True
	bool isMonster
	
	; -- GP -- 
	; Rewrote the code a little bit to set isAnimal to False instead of exiting the script.
	; "Empty" carcass or non-valid target?
	bool fresh = akTarget.GetItemCount(dsAnimals.moTokenCarcass_Fresh) > 0
	bool clean = akTarget.GetItemCount(dsAnimals.moTokenCarcass_Clean) > 0
	If (!fresh && !clean)
		Race r = akTarget.GetRace()
		If (!r)
			isAnimal = False
		Else
			aiIndex = dsMain.GetIndexFromRace(r)
			If (aiIndex == -1)
				isAnimal = False
			Else
				akTarget.AddItem(dsAnimals.moTokenCarcass_Fresh)
				akTarget.AddItem(dsAnimals.flDeathItemTokens.GetAt(aiIndex))
				fresh = True
			EndIf
		EndIf
	Else	
		aiIndex = dsAnimals.GetCarcassIndex(akTarget)
	EndIf

	If (aiIndex == -1 || !dsAnimals.IsActiveAnimal(aiIndex))
		isAnimal = False
	EndIf
	
	; -- GP -- 
	; If it's not an animal, checks if it's a monster.
	If !isAnimal
		isMonster = akTarget.GetItemCount(dsMain.dsMonsters.moTokenCarcass_Monster) > 0
	EndIf

	If !isAnimal && !isMonster
		Return
	EndIf
	
	If (HotkeyAction == ACTION_DRESS && fresh)
		If dsGlobals.gUseAnimation 
			dsMain.gpAnimFunctions.doAnim()	; Plays check carcass animation first
		EndIf
		dsActions.FieldDress(akTarget, aiIndex)
	ElseIf (fresh)
		Return
	EndIf
	
	; -- GP -- 
	; Functions can now trigger for monsters too.
	If (HotkeyAction == ACTION_SKIN && akTarget.GetItemCount(dsActions.moTokenPelt) > 0)
		If dsGlobals.gUseAnimation 
			dsMain.gpAnimFunctions.doAnim() 
		EndIf
		dsActions.SkinCarcass(akTarget, isMonster) 
	ElseIf (HotkeyAction == ACTION_HARVEST && akTarget.GetItemCount(dsActions.moTokenMat) > 0)
		If dsGlobals.gUseAnimation 
			dsMain.gpAnimFunctions.doAnim() 
		EndIf
		dsActions.HarvestCarcass(akTarget, isMonster)
	ElseIf (HotkeyAction == ACTION_BUTCHER && akTarget.GetItemCount(dsActions.moTokenMeat) > 0)
		If dsGlobals.gUseAnimation
			dsMain.gpAnimFunctions.doAnim()
		EndIf
		dsActions.ButcherCarcass(akTarget, isMonster)
	ElseIf (HotkeyAction == ACTION_PROCESS)
		If dsGlobals.gUseAnimation 
			dsMain.gpAnimFunctions.doAnim()
		EndIf
		dsActions.ProcessCarcass(akTarget, isMonster)
	EndIf

EndEvent
