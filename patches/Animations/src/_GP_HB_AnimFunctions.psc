; Hunterborn - Animations by Elsawirr and GiraPomba (Nexus 80677), modified by Hunterborn 2026 (CageTV): with no hunting knife the claw animations play.
Scriptname _GP_HB_AnimFunctions extends Quest

Import Debug
Import IED
Import Game
Import Utility

Actor Property PlayerRef Auto  

_DS_HB_Main Property dsMain Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Monsters Property dsMonsters Auto
_DS_HB_Globals Property dsGlobals Auto
_GP_HB_AnimPlayer Property gpAnimPlayer Auto

GlobalVariable Property _GP_AnimTrigger Auto

; For MCM options
GlobalVariable Property _GP_HunterbornAnim_PickupAnim Auto
GlobalVariable Property _GP_HunterbornAnim_PeltDisplay Auto
GlobalVariable Property _GP_HunterbornAnim_SheatheWeapon Auto
GlobalVariable Property _GP_HunterbornAnim_ForceThirdPerson Auto
GlobalVariable Property _GP_HunterbornAnim_DefaultAnim Auto
GlobalVariable Property _GP_HunterbornAnim_Campfire Auto
GlobalVariable Property _GP_HunterbornAnim_KnifePosition Auto
GlobalVariable Property _GP_HunterbornAnim_Extractor Auto
GlobalVariable Property _GP_HunterbornAnim_Torch Auto
GlobalVariable Property _GP_HunterbornAnim_DisposeShovel Auto
GlobalVariable Property _GP_HunterbornAnim_RequireBottle Auto
GlobalVariable Property _GP_HunterbornAnim_Display Auto
GlobalVariable Property _GP_HunterbornAnim_BloodEffects Auto

Perk Property AlchAnatomist Auto 

ImpactDataSet Property _GP_IPDS_BloodSmall Auto 
ImpactDataSet Property _GP_IPDS_BloodMedium Auto 
ImpactDataSet Property _GP_IPDS_BloodLarge Auto 

MiscObject Property _GP_WhiteFurDisplay Auto
MiscObject Property _GP_BlackFurDisplay Auto
MiscObject Property _GP_BrownFurDisplay Auto
MiscObject Property _GP_SnowFurDisplay Auto
MiscObject Property _GP_ValeFurDisplay Auto
MiscObject Property DA04Extractor Auto

Bool Property isIEDInstalled Auto Hidden

Form Property fHuntingMaterial Auto Hidden
Form Property fHuntingPelt Auto Hidden									  
Form Property fCookedFood Auto Hidden

Int Property iPeltCount Auto Hidden

Float[] fArrayPosition
Float[] fArrayRotation
Float fScale
Float fCurrentTime

Bool doPickupPelt
Bool isPlayerFemale
Bool isFirstPerson
Bool isDrawnWeapon
Bool hasTorch

Furniture ShovelAnimationMarker
ShovelBodyMCMScript ShovelBodyQuest

Form fEmptyBottle
Form fCacoExtractor
Form fLeftHandItem

Int iQueue

String sFilePath = "../StorageUtilData/ImmersiveHunting/"

; -- Stand up by moving/jumping
;
Event OnControlDown(String control)
	If control == "Forward" || control == "Back" || control == "Strafe Left" || control == "Strafe Right" || control == "Jump"
		If PlayerRef.GetAnimationVariableBool("bAnimationDriven") && control != "Jump"
			StandUp()
		Else
			SendAnimationEvent(PlayerRef, "IdleForceDefaultState")
			SendAnimationEvent(PlayerRef, "JumpLand")
			isDrawnWeapon = False
			EndAnim(True)
		EndIf
	EndIf
EndEvent

; -- Tracks if player is still in animation event. There is a possibility that the animations get interrupted with some unexpected way, this update here will cancel the process.
;
Event OnUpdate()
	If PlayerRef.GetAnimationVariableBool("bAnimationDriven")
		RegisterForSingleUpdate(4)
	Else
		EndAnim(True)
	EndIf
EndEvent

; -- Function to populate important properties/variables
;
Function StartHunterbornAnimations()
	; Checks if IED is installed and verifies player sex
	If GetScriptVersion() >= 8 
		isIEDInstalled = True
		
		If isPlayerFemale != PlayerRef.GetActorBase().GetSex()
			DeleteDisplay() ; Deletes all displays if player sex is different than before
		EndIf
		isPlayerFemale = PlayerRef.GetActorBase().GetSex()
	Else
		isIEDInstalled = False
	EndIf
	
	; Populates the gpAnimFunctions variables in dsMain and dsActions scripts if Hunterborn is already started
	If dsGlobals.gHunterbornActive
		If !dsActions.gpAnimFunctions || !dsMain.gpAnimFunctions
			dsActions.gpAnimFunctions = Self as _GP_HB_AnimFunctions
			dsMain.gpAnimFunctions = Self as _GP_HB_AnimFunctions
		EndIf
	EndIf

	; Checks if Shovel Buries Bodies is installed
	If IsPluginInstalled("ShovelBody.esp")
		ShovelAnimationMarker = GetFormFromFile(0x0000809, "ShovelBody.esp") as Furniture
		ShovelBodyQuest = (GetFormFromFile(0x0000800, "ShovelBody.esp") as Quest) as ShovelBodyMCMScript
	Else
		ShovelAnimationMarker = None
		ShovelBodyQuest = None
	EndIf
	
	; Checks if Alchemy Requires Bottles is installed
	If IsPluginInstalled("Alchemy Requires Bottles Redux.esp")
		fEmptyBottle = GetFormFromFile(0x00000800, "Alchemy Requires Bottles Redux.esp")
	Else
		fEmptyBottle = None
	EndIf
	
	; Checks if CACO is installed
	If IsPluginInstalled("Complete Alchemy & Cooking Overhaul.esp")
		fCacoExtractor = GetFormFromFile(0x107FC3, "Complete Alchemy & Cooking Overhaul.esp")
	Else
		fCacoExtractor = None
	EndIf
	
EndFunction

; -- Function to check if player is already in another animation, riding, swimming, weapon drawn, etc...
;
Bool Function CheckPlayerConditions()
	If PlayerRef.IsWeaponDrawn() || PlayerRef.IsSwimming() || PlayerRef.GetAnimationVariableBool("isStaggering") || PlayerRef.IsOnMount()
		Return False
	Else
		Return True
	EndIf
EndFunction

; -- Function to check if weapon is drawn to sheathe it 
;
Function CheckWeaponsDrawn(Bool bToggle = True)	
	While PlayerRef.GetAnimationVariableBool("IsUnequipping") || PlayerRef.GetAnimationVariableBool("IsEquipping")
		Wait(0.1)
	EndWhile
	
	If bToggle
		If PlayerRef.IsWeaponDrawn() && _GP_HunterbornAnim_SheatheWeapon.GetValue()
			;PlayerRef.SheatheWeapon()
			SendAnimationEvent(PlayerRef, "Unequip") ; Uses this instead since some mods can break the SheatheWeapon() function
			While PlayerRef.GetAnimationVariableBool("IsUnequipping")
				Wait(0.1)
			EndWhile
			isDrawnWeapon = True
		EndIf
	Else
		If isDrawnWeapon
			PlayerRef.DrawWeapon()
			isDrawnWeapon = False
		EndIf
	EndIf
EndFunction

; -- Function to check if camera is in first/third person to switch it accordingly
;
Function CheckCameraState(Bool bToggle = True)	
	If bToggle
		If GetCameraState() == 0 && _GP_HunterbornAnim_ForceThirdPerson.GetValue() > 0
			If _GP_HunterbornAnim_ForceThirdPerson.GetValue() == 1
				ForceThirdPerson()
			Else
				Input.TapKey(Input.GetMappedKey("Toggle POV"))
			EndIf
			If isDrawnWeapon
				Wait(0.4)
			EndIf
			; Only return to first person if the corresponding option is chosen.
			If _GP_HunterbornAnim_ForceThirdPerson.GetValue() == 2
				isFirstPerson = True
			Else
				isFirstPerson = False
			EndIf
		EndIf
	Else
		If isFirstPerson
			ForceFirstPerson()
			isFirstPerson = False
		EndIf
	EndIf
EndFunction

; -- Function to check if torch or shield is equipped on the left hand. Unequips the item and equips it back when animations are finished. 
Function CheckLeftHand(Bool bToggle = True)
	If bToggle
		If PlayerRef.GetEquippedItemType(0) >= 10
			fLeftHandItem = PlayerRef.GetEquippedObject(0)
			hasTorch = False
			; Checks if it's a torch. Some animations will play with torch, some will unequip it 
			If fLeftHandItem.GetType() == 31
				hasTorch = True
				Return
			EndIf
			PlayerRef.UnequipItem(fLeftHandItem, False, True)
		EndIf
	Else
		If fLeftHandItem && !PlayerRef.GetEquippedItemType(0)
			If PlayerRef.GetItemCount(fLeftHandItem) > 0 ; Equips item back
				PlayerRef.EquipItem(fLeftHandItem, False, True)
			EndIf
		EndIf
		fLeftHandItem = None
		hasTorch = False
	EndIf
EndFunction

; -- Removes torch from player and places it at the ground, if enabled
Function UnequipTorch()
	If hasTorch
		If PlayerRef.GetItemCount(fLeftHandItem) > 0
			PlayerRef.UnequipItem(fLeftHandItem, False, True)
		EndIf
		If _GP_HunterbornAnim_Torch.GetValue()
			CreateDisplay(9, "HuntingTorch")
			EnableDisplay("HuntingTorch")
		EndIf
	EndIf
EndFunction

; -- Functions to check/uncheck player for stand up or cancel animation
;
Function RegisterForCancel()
	RegisterForControl("Jump")
	RegisterForSingleUpdate(4)
	gpAnimPlayer.RegisterForHit()
	gpAnimPlayer.RegisterForWeaponDrawn()
EndFunction

Function RegisterForMovement()
	RegisterForControl("Forward")
	RegisterForControl("Back")
	RegisterForControl("Strafe Left")
	RegisterForControl("Strafe Right")
	gpAnimPlayer.RegisterForMagicEffectMov()
EndFunction

Function UnregisterForMovement()
	UnregisterForControl("Forward")
	UnregisterForControl("Back")
	UnregisterForControl("Strafe Left")
	UnregisterForControl("Strafe Right")
	gpAnimPlayer.UnregisterForMagicEffectMov()
EndFunction

Function UnregisterForCancel()
	UnregisterForControl("Forward")
	UnregisterForControl("Back")
	UnregisterForControl("Strafe Left")
	UnregisterForControl("Strafe Right")
	UnregisterForControl("Jump")
	UnregisterForUpdate()
	gpAnimPlayer.UnregisterForMagicEffectMov()
	gpAnimPlayer.UnregisterForHit()
	gpAnimPlayer.UnregisterForWeaponDrawn()
EndFunction

; -- Function responsible for all animations events along other stuff
;
Function DoAnim(Int iTypeAction = 0, Actor aCarcassRef = None, Int iCarcassIndex = 0, Bool isMonster = False, Bool abToggle = False, Bool isProcess = False)
	If CheckPlayerConditions()
		RegisterForCancel()
		UnregisterForMovement()
		Float fTimer
		Bool doEndAll
		If iTypeAction == 0 && !isProcess
		; Check carcass (initial interaction)
			If _GP_AnimTrigger.GetValue() == 0
				CheckCameraState()
				_GP_AnimTrigger.SetValue(10)
				SendAnimationEvent(PlayerRef, "IdleKneeling")
				Wait(1.2)
			EndIf
			Return
		EndIf
		CheckLeftHand()
		If iTypeAction <= 6 || iTypeAction == 8
			UnequipTorch()
		EndIf
		; Check what kind of knife player is using
		Int iTypeOfKnife = dsGlobals.gHuntingKnife
		; Hunterborn 2026: no hunting knife at all (-1) works with bare hands, so it plays the claw animations (tearing with the hands) instead of the
		; generic rock one. The yield is unchanged: no knife still gives the lowest quality.
		Bool bareHands = False
		If iTypeOfKnife == -1
			iTypeOfKnife = -3
			bareHands = True
		EndIf
		; If using processing with at least two animations from these three: Skin, Harvest or Butcher, player will perform a different animation in one go. Otherwise, the first animation found will be played.
		If isProcess
			; Animations have specific timers to when an action needs to be done, such as create a display or trigger blood splatters.
			; Also, the animations have different durations depending on the knife position.
			; These variables here will control the timers to make sure the animations end when they need to. 
			; -- First variable is the time it needs to take before creating a display for food/potion item or to trigger blood splatter.
			; -- Second variable is the time the animation needs to end, it's not the total lenght of the animation, but a bit before that. 
			; Since the script needs to tell OAR to switch the animations (by updating global variables) with a somewhat precicion, it was needed to use these functions, because scripts run differently for everyone...
			CreateDisplay(10, "HuntingMisc")
			Float fProcessTime1 = 10
			Float fProcessTime2 = 13
			If iTypeOfKnife == -3 ; processing with claws
				If bareHands ; Hunterborn 2026: bare hands pull the parts out with the "Harvest Fail" animation (2.5 s to the pull, 4.5 s in all)
					_GP_AnimTrigger.SetValue(302)
					fProcessTime1 = 2.5
					fProcessTime2 = 4.5
				Else
					_GP_AnimTrigger.SetValue(51)
					fProcessTime1 = 2.8
					fProcessTime2 = 4.1
				EndIf
			ElseIf iTypeOfKnife == -1 || iTypeOfKnife == -4; processing with no knife or a sharp rock
				If _GP_HunterbornAnim_DefaultAnim.GetValue() ; Plays default animation when not using a knife or using a sharp rock.
					dsActions.DoAnim()
					Return
				EndIf
				_GP_AnimTrigger.SetValue(52) ; generic rock animation
				fProcessTime1 = 2.5
				fProcessTime2 = 4.7
			Else ; Knife animations
				If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
					fProcessTime1 = 8.4
					fProcessTime2 = 10.5
				EndIf
				_GP_AnimTrigger.SetValue(50 + _GP_HunterbornAnim_KnifePosition.GetValue())
			EndIf
			fCurrentTime = GetCurrentRealTime()
			WaitForCancel(fProcessTime1)
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			If iTypeOfKnife > 0
				EnableDisplay("HuntingMisc") ; shows either bucthered meat or harvested item
			EndIf
			TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
			WaitForCancel(fProcessTime2 - (GetCurrentRealTime() - fCurrentTime))
			EnableDisplay("HuntingMisc", False)
			fTimer = 0.5
		ElseIf iTypeAction == 1
			; Field Dress Animation
			If iCarcassIndex == 3 ; Chicken
				_GP_AnimTrigger.SetValue(102)
				CreateDisplay(iTypeAction, "HuntingMisc")
				WaitForCancel(1.85)
				If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
					Return
				EndIf
				EnableDisplay("HuntingMisc")
				fTimer = 4.2
			Else 
				Float fDressTime1
				Float fDressTime2
				; Using claws
				If iTypeOfKnife == -3 
					fDressTime1 = 2.8
					fDressTime2 = 4.1
					_GP_AnimTrigger.SetValue(120)
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fDressTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fDressTime2 - (GetCurrentRealTime() - fCurrentTime))
				; Not using a knife or using a sharp rock
				ElseIf iTypeOfKnife == -1 || iTypeOfKnife == -4
					If _GP_HunterbornAnim_DefaultAnim.GetValue() ; Plays default animation when not using a knife or using a sharp rock.
						dsActions.DoAnim()
						Return
					EndIf
					fDressTime1 = 2.5
					fDressTime2 = 4.7
					_GP_AnimTrigger.SetValue(52) ; generic rock animation
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fDressTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fDressTime2 - (GetCurrentRealTime() - fCurrentTime))
				; Using knife
				ElseIf iCarcassIndex == 6 || iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 11 || iCarcassIndex == 12 || iCarcassIndex == 16 || iCarcassIndex == 21 ; Dog, Fox, Hare, Goat, Small Mudcrab or Skeever
					fDressTime1 = 5
					fDressTime2 = 9.4
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fDressTime1 = 3.70
						fDressTime2 = 7.6
					EndIf
					_GP_AnimTrigger.SetValue(101 + _GP_HunterbornAnim_KnifePosition.GetValue())
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fDressTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fDressTime2 - (GetCurrentRealTime() - fCurrentTime))
				ElseIf iCarcassIndex == 22 ; Slaughterfish --- Removing scales sort of animation
					fDressTime1 = 4.2
					fDressTime2 = 8.7
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fDressTime1 = 3.7
						fDressTime2 = 7.3
					EndIf
					_GP_AnimTrigger.SetValue(201 + _GP_HunterbornAnim_KnifePosition.GetValue())
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fDressTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fDressTime2 - (GetCurrentRealTime() - fCurrentTime))
				Else ; Large animals
					fDressTime1 = 4.1
					fDressTime2 = 6.5
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fDressTime1 = 5.65
						fDressTime2 = 8.6
					EndIf
					_GP_AnimTrigger.SetValue(100 + _GP_HunterbornAnim_KnifePosition.GetValue())
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fDressTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fDressTime2 - (GetCurrentRealTime() - fCurrentTime))
				EndIf
			EndIf
		ElseIf iTypeAction == 2
			Float fSkinTime1
			Float fSkinTime2
			; Skin Animation
			If abToggle ; Failed skin animation
				fSkinTime1 = 6.8
				fSkinTime2 = 10.1
				If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
					fSkinTime1 = 4.9
					fSkinTime2 = 7.9
				EndIf
				If iTypeOfKnife == -3 
					fSkinTime1 = 4.9
					fSkinTime2 = 7.9
					_GP_AnimTrigger.SetValue(220)
				ElseIf  iTypeOfKnife == -1 || iTypeOfKnife == -4
					fSkinTime1 = 4.9
					fSkinTime2 = 7.9
					_GP_AnimTrigger.SetValue(230)
				Else
					_GP_AnimTrigger.SetValue(202 + _GP_HunterbornAnim_KnifePosition.GetValue())
				EndIf
				fCurrentTime = GetCurrentRealTime()
				WaitForCancel(fSkinTime1)
				If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
					Return
				EndIf
				TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
				fCurrentTime = GetCurrentRealTime() - fCurrentTime
				WaitForCancel(fSkinTime2 - (GetCurrentRealTime() - fCurrentTime))
			Else 
				; Using claws
				If iTypeOfKnife == -3 
					fSkinTime1 = 3
					fSkinTime2 = 3.9
					_GP_AnimTrigger.SetValue(220)
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fSkinTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fSkinTime2 - (GetCurrentRealTime() - fCurrentTime))
				; Not using a knife or using a sharp rock
				ElseIf iTypeOfKnife == -1 || iTypeOfKnife == -4
					If _GP_HunterbornAnim_DefaultAnim.GetValue() ; Plays default animation when not using a knife or using a sharp rock.
						dsActions.DoAnim()
						Return
					EndIf
					fSkinTime1 = 2.5
					fSkinTime2 = 4.7
					_GP_AnimTrigger.SetValue(52) ; generic rock animation
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fSkinTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fSkinTime2 - (GetCurrentRealTime() - fCurrentTime))
				; Using knife
				ElseIf !isMonster && (iCarcassIndex == 6 || iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 11 || iCarcassIndex == 12 || iCarcassIndex == 21)   ;  Dog, Fox, Hare, Goat, or Skeever
					fSkinTime1 = 4.2
					fSkinTime2 = 8.5
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fSkinTime1 = 3.7
						fSkinTime2 = 7.1
					EndIf
					_GP_AnimTrigger.SetValue(201 + _GP_HunterbornAnim_KnifePosition.GetValue())
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fSkinTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fSkinTime2 - (GetCurrentRealTime() - fCurrentTime)) 
				Else ; Large animals
					fSkinTime1 = 5
					fSkinTime2 = 11.6
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fSkinTime1 = 3.25
						fSkinTime2 = 9.6
					EndIf
					_GP_AnimTrigger.SetValue(200 + _GP_HunterbornAnim_KnifePosition.GetValue())
					fCurrentTime = GetCurrentRealTime()
					WaitForCancel(fSkinTime1)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
					WaitForCancel(fSkinTime2 - (GetCurrentRealTime() - fCurrentTime))  
				EndIf
			EndIf
		ElseIf iTypeAction == 3
			; Harvest Animation
			If abToggle ; Failed harvest animation
				_GP_AnimTrigger.SetValue(302)
				WaitForCancel(2.5)
				fTimer = 1.5 ; Total time = 4.5
			Else ; Small animals
				CreateDisplay(iTypeAction, "HuntingMisc")
				If !isMonster && (iCarcassIndex == 6 || iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 11 || iCarcassIndex == 12 || iCarcassIndex == 16 || iCarcassIndex == 21 || iCarcassIndex == 22) ; Dog, Fox, Hare, Goat, Small Mudcrab, Skeever or Slaughterfish
					_GP_AnimTrigger.SetValue(301)
					WaitForCancel(2.05)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					EnableDisplay("HuntingMisc")
					fTimer = 2.5 ; Total time = 5.93
				Else ; Large animals
					_GP_AnimTrigger.SetValue(300)
					WaitForCancel(3.40)
					If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
						Return
					EndIf
					EnableDisplay("HuntingMisc")
					fTimer = 1.7 ; Total time = 6.46
				EndIf
			EndIf
			TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex, isMonster, abToggle) ; Call for blood splatters when the material is harvested/crit fail
		ElseIf iTypeAction == 4
			; Butcher Animation
			Float fButcherTime1
			Float fButcherTime2
			CreateDisplay(iTypeAction, "HuntingMisc")
			; Using claws
			If iTypeOfKnife == -3 
				fButcherTime1 = 4.2
				fButcherTime2 = 6.1
				_GP_AnimTrigger.SetValue(420)
				fCurrentTime = GetCurrentRealTime()
				WaitForCancel(fButcherTime1)
				If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
					Return
				EndIf
				EnableDisplay("HuntingMisc")
				TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
				WaitForCancel(fButcherTime2 - (GetCurrentRealTime() - fCurrentTime))  
			; Not using a knife or using a sharp rock
			ElseIf iTypeOfKnife == -1 || iTypeOfKnife == -4
				If _GP_HunterbornAnim_DefaultAnim.GetValue() ; Plays default animation when not using a knife or using a sharp rock.
					dsActions.DoAnim()
					Return
				EndIf
				fButcherTime1 = 2.5
				fButcherTime2 = 4
				_GP_AnimTrigger.SetValue(52) ; generic rock animation
				fCurrentTime = GetCurrentRealTime()
				WaitForCancel(fButcherTime1)
				If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
					Return
				EndIf
				TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
				WaitForCancel(fButcherTime2 - (GetCurrentRealTime() - fCurrentTime))  
			Else ; Using knife
				If !isMonster && (iCarcassIndex == 3 || iCarcassIndex == 6 || iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 11 || iCarcassIndex == 12 || iCarcassIndex == 16 || iCarcassIndex == 21 || iCarcassIndex == 22) ; Chicken, Dog, Fox, Hare, Goat, Small Mudcrab, Skeever or Slaughterfish
					fButcherTime1 = 4.4
					fButcherTime2 = 6.9
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fButcherTime1 = 4.7
						fButcherTime2 = 6.6
					EndIf
					_GP_AnimTrigger.SetValue(401 + _GP_HunterbornAnim_KnifePosition.GetValue())
				Else ; Large animals
					fButcherTime1 = 7.4
					fButcherTime2 = 10.9
					If _GP_HunterbornAnim_KnifePosition.GetValue() == 10
						fButcherTime1 = 5.7
						fButcherTime2 = 7.9
					EndIf
					_GP_AnimTrigger.SetValue(400 + _GP_HunterbornAnim_KnifePosition.GetValue())
				EndIf
				fCurrentTime = GetCurrentRealTime()
				WaitForCancel(fButcherTime1)
				If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
					Return
				EndIf
				EnableDisplay("HuntingMisc")
				TriggerBloodSplatter(aCarcassRef, iTypeAction, iCarcassIndex) ; Call for blood splatters when the cut is made
				WaitForCancel(fButcherTime2 - (GetCurrentRealTime() - fCurrentTime))    
			EndIf
			WaitForCancel(fTimer)
			EnableDisplay("HuntingMisc", False)
			fTimer = 0.5
		ElseIf iTypeAction == 5
			; Extract Animation
			Bool doExtractorAnim
			If fHuntingMaterial == dsMonsters.BloodTypes[iCarcassIndex] && _GP_HunterbornAnim_Extractor.GetValue() ; Is blood, check for extractors
				If PlayerRef.GetItemCount(DA04Extractor) > 0
					doExtractorAnim = True
				Else
					If fCacoExtractor ; Checks for CACO blood extractor
						If PlayerRef.GetItemCount(fCacoExtractor) > 0 && PlayerRef.HasPerk(AlchAnatomist)
							doExtractorAnim = True
						EndIf
					EndIf
				EndIf
			EndIf
			If doExtractorAnim ; Using extractor
				_GP_AnimTrigger.SetValue(501)
				WaitForCancel(6.3)
				If CheckForBottles(False)
					PlayerRef.AddItem(fHuntingMaterial, 1) ; Additional blood potion when using extractor
				EndIf
				fTimer = 0
			ElseIf iTypeOfKnife == -3 ; Using claws
				_GP_AnimTrigger.SetValue(120) ; same as field dress for now
				WaitForCancel(4.4)
			ElseIf iTypeOfKnife == -1 || iTypeOfKnife == -4 ; Not using a knife or using a sharp rock
				If _GP_HunterbornAnim_DefaultAnim.GetValue() ; Plays default animation when not using a knife or using a sharp rock.
					dsActions.DoAnim()
					Return
				EndIf
				_GP_AnimTrigger.SetValue(52) ; generic rock animation
				WaitForCancel(5)
			Else ; Using knife
				_GP_AnimTrigger.SetValue(500 + _GP_HunterbornAnim_KnifePosition.GetValue())
				fCurrentTime = GetCurrentRealTime()
				CreateDisplay(iTypeAction, "HuntingMisc")
				WaitForCancel(2.3)
				EnableDisplay("HuntingMisc")
				WaitForCancel(3.54)
				EnableDisplay("HuntingMisc", False)
				WaitForCancel(7.2 - (GetCurrentRealTime() - fCurrentTime))
			EndIf
		ElseIf iTypeAction == 6
			; Remove Arrows Animation
			_GP_AnimTrigger.SetValue(600)
			CreateDisplay(iTypeAction, "HuntingArrow")
			EnableDisplay("HuntingArrow")
			fTimer = 2.8 
		ElseIf iTypeAction == 7 
			; Primitive cooking
			If PlayerREF.GetSitState() != 0
				Return
			EndIf
			iQueue = 0
			CheckCameraState()
			DisablePlayerControls(False, False, False, False, False, False, True, False) ; Disable Activate option while in the cooking animation
			If iQueue == 0
				If iTypeOfKnife < 0 ; Not using a knife or using claws/sharp rock
					_GP_AnimTrigger.SetValue(720)
				Else
					_GP_AnimTrigger.SetValue(700 + _GP_HunterbornAnim_KnifePosition.GetValue())
				EndIF
				SendAnimationEvent(PlayerRef, "IdleKneeling")
				fCurrentTime = GetCurrentRealTime()
				WaitForCancel(2.5)
			EndIf
			gpAnimPlayer.CheckForCooking(True)
			While UI.IsMenuOpen("Crafting Menu") || iQueue > 0
				Wait(0.1)
			EndWhile
			gpAnimPlayer.CheckForCooking(False)
			fCurrentTime = GetCurrentRealTime() - fCurrentTime
			If fCurrentTime > 4
				fCurrentTime = 4
			EndIf
			If fCurrentTime < 4
				WaitForCancel(1.5)
			EndIf
			SendAnimationEvent(PlayerRef, "IdleStop")
			iQueue = 0
			EnablePlayerControls()
			doEndAll = True
		ElseIf iTypeAction == 8 
			; Primitive cooking (item crafted)
			If PlayerRef.GetAnimationVariableBool("bAnimationDriven") 
				iQueue += 1
				If iTypeOfKnife < 0 ; Not using a knife or using claws/sharp rock
					_GP_AnimTrigger.SetValue(721)
				Else
					_GP_AnimTrigger.SetValue(701 + _GP_HunterbornAnim_KnifePosition.GetValue())
				EndIf
				Wait(0.2)
				If !isIEDInstalled || !_GP_HunterbornAnim_Display.GetValue()
					WaitForCancel(10)
				Else
					fCurrentTime = GetCurrentRealTime()
					CreateDisplay(iTypeAction, "CookingHand")
					If iQueue <= 1
						EnableDisplay("CookingHand")
					EndIf
				EndIf
				If iQueue <= 1
					If !abToggle 
						If iTypeOfKnife < 0 ; Not using a knife or using claws/sharp rock
							_GP_AnimTrigger.SetValue(720)
						Else
							_GP_AnimTrigger.SetValue(700 + _GP_HunterbornAnim_KnifePosition.GetValue())
						EndIf
						If hasTorch
							EnableDisplay(sDisplay = "HuntingTorch", doEnable = False)
							CheckLeftHand(False)
						EndIf
					ElseIf PlayerRef.GetAnimationVariableBool("bAnimationDriven") 
						_GP_AnimTrigger.SetValue(10)
					EndIf
				EndIf
				iQueue -= 1
			EndIf
			Return
		ElseIf iTypeAction == 9 
			; Forage
			CheckCameraState()
			If hasTorch
				_GP_AnimTrigger.SetValue(801)
			Else 
				_GP_AnimTrigger.SetValue(800)
			EndIf
			SendAnimationEvent(PlayerRef, "IdlePickup_Ground")
			While PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Wait(0.1)
			EndWhile
			doEndAll = True
		ElseIf iTypeAction == 10 
			; Sense direction
			_GP_AnimTrigger.SetValue(802)
			SendAnimationEvent(PlayerRef, "OffsetCarryMQ201DrinkR")
			Wait(1.8)
			SendAnimationEvent(PlayerRef, "OffsetStop")
			doEndAll = True
		ElseIf iTypeAction == 11 
			; Track animal
			CheckCameraState()
			If hasTorch
				_GP_AnimTrigger.SetValue(804)
			Else 
				_GP_AnimTrigger.SetValue(803)
			EndIf
			SendAnimationEvent(PlayerRef, "IdlePickup_Ground")
			While PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Wait(0.1)
			EndWhile
			doEndAll = True
		EndIf
		WaitForCancel(fTimer)
		If PlayerRef.GetAnimationVariableBool("bAnimationDriven")
			EndAnim(doEndAll)
		EndIf
	EndIf
EndFunction

; -- Function to check if a "cancel" action was done (jump, getting hit, drawing weapon).
;	 Is there a good way to interrupt an ongoing function? There are several "Waits" and "Displays" functions along the animations that can be interrupted, so the loop here will only wait if the animation was not interrupted.
;	 There are also some additional checks to "Return" the function if it was interrupted. Not very elegant, but hey, as long as it works.
Function WaitForCancel(Float fTimeToWait)
	If fTimeToWait > 0
		Float fTimeFrag = fTimeToWait / 10
		While fTimeToWait && PlayerRef.GetAnimationVariableBool("bAnimationDriven")
			Wait(fTimeFrag)
			fTimeToWait -= fTimeFrag
		EndWhile
	EndIf
EndFunction

; -- Function to control when an action is complete
;
Function EndAnim(Bool doAll = False)
	; Disable some displays
	EnableDisplay("HuntingMisc", False)
	EnableDisplay("HuntingArrow", False)
	EnableDisplay("HuntingTorch", False)
	If doAll ; Considers all actions as complete
		; Disable more displays
		EnableDisplay("CookingHand", False)
		EnableDisplay("HuntingPelt", False)
		UnregisterForCancel()
		
		If doPickupPelt; Carries skinned pelt when standing up
			PlayerRef.AddItem(fHuntingPelt, iPeltCount) ; Add skinned pelt
			fHuntingPelt = None
			iPeltCount = 0
		EndIf
		doPickupPelt = False
		
		fHuntingMaterial = None
		fCookedFood = None
		While PlayerRef.GetAnimationVariableBool("bAnimationDriven")
			Wait(0.1)
		EndWhile
		; Checks for camera and weapons sheathed
		CheckCameraState(False)
		CheckWeaponsDrawn(False)
		_GP_AnimTrigger.SetValue(0)							
	Else ; Finished action while still interacting with a carcass, sends animation to "check" carcass again
		_GP_AnimTrigger.SetValue(11)
		CheckLeftHand(False)
		; Movement can now exit animation
		RegisterForMovement()
	EndIf
EndFunction

; -- Trigger Blood Splatter
; Function is responsible for the blood sprays that appear on the ground when performing an action, if enabled.
; Depending on the size of the carcass and skill level, larger, medium or smaller blood can appear on the ground.
Function TriggerBloodSplatter(Actor akCarcassRef, Int iTypeAction, Int iCarcassIndex, Bool isMonster = False, Bool isCritFail = False)
	Int iScreenBlood
	If _GP_HunterbornAnim_BloodEffects.GetValue()
		String sNode
		If akCarcassRef.HasNode("NPC Spine2 [Spn2]")
			sNode = "NPC Spine2 [Spn2]"
		ElseIf akCarcassRef.HasNode("NPC Spine2")
			sNode = "NPC Spine2"
		ElseIf akCarcassRef.HasNode("NPC Ribcage")
			sNode = "NPC Ribcage"
		ElseIf akCarcassRef.HasNode("Canine_Ribcage")
			sNode = "Canine_Ribcage"
		ElseIf akCarcassRef.HasNode("Sabrecat_Ribcage[Spn4]")
			sNode = "Sabrecat_Ribcage[Spn4]"
		ElseIf akCarcassRef.HasNode("[body]")
			sNode = "[body]"
		Else
			sNode = "NPC Spine2 [Spn2]"
		EndIf
		
		If isCritFail ; Critical failure when Skinning or Harvesting
			If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
				; Smaller animals trigger less blood
				akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
				iScreenBlood = 5
			Else
				akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodLarge, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
				iScreenBlood = 10
			EndIf
		Else
			If iTypeAction == 1 ; Field Dress
				If dsGlobals.gTotalCleans <= 50 ; Less than 50 total cleans, trigger medium-sized blood pools
					If iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22
						; Smaller animals trigger less blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 3
					ElseIf iCarcassIndex != 3
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 6
					EndIf
				Else
					If !iCarcassIndex == 9 && !iCarcassIndex == 10 && !iCarcassIndex == 12 && !iCarcassIndex == 22
						; Smaller animals won't trigger blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 4
					ElseIf iCarcassIndex != 3
						iScreenBlood = 0
					EndIf
				EndIf
			ElseIf iTypeAction == 2 || iTypeAction == 3 ; Skin or Process
				If dsGlobals.gSkinLevel <= 4 ; Beginner level, larger blood pools
					If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
						; Smaller animals trigger less blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 5
					Else
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodLarge, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 10
					EndIf
				ElseIf dsGlobals.gSkinLevel > 4 && dsGlobals.gSkinLevel <= 7 ; Intermediate level, medium-sized blood pools
					If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
						; Smaller animals trigger less blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 3
					Else
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 6
					EndIf
				ElseIf dsGlobals.gSkinLevel == 8 || dsGlobals.gSkinLevel == 9 ; Advanced level, smaller blood pools
					If !isMonster && !iCarcassIndex == 9 && !iCarcassIndex == 10 && !iCarcassIndex == 12 && !iCarcassIndex == 22
						; Smaller animals won't trigger blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 4
					Else
						iScreenBlood = 0
					EndIf
				Else ; Master level, no blood
					iScreenBlood = 0
				EndIf
			ElseIf iTypeAction == 4 ; Harvest
				If dsGlobals.gHarvestLevel <= 4 ; Beginner level, larger blood pools
					If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
						; Smaller animals trigger less blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 5
					Else
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodLarge, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 10
					EndIf
				ElseIf dsGlobals.gHarvestLevel > 4 && dsGlobals.gHarvestLevel <= 7 ; Intermediate level, medium-sized blood pools
					If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
						; Smaller animals trigger less blood
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 3
					Else
						akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
						iScreenBlood = 6
					EndIf
				Else ; Advanced and Master levels, smaller blood pools
					akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
					iScreenBlood = 2
				EndIf
			ElseIf iTypeAction == 5 ; Butcher
				If !isMonster && (iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 12 || iCarcassIndex == 22)
					; Smaller animals trigger less blood
					akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodSmall, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
					iScreenBlood = 3
				Else
					akCarcassRef.PlayImpactEffect(_GP_IPDS_BloodMedium, sNode, RandomFloat(-0.300000, 0.300000), RandomFloat(-0.300000, 0.300000), -1 as Float, 512 as Float, false, true)
					iScreenBlood = 6
				EndIf
			EndIf
		EndIf
	Else
		iScreenBlood = 7
	EndIf
	If (dsGlobals.gShowScreenBlood) && iScreenBlood > 0
		TriggerScreenBlood(iScreenBlood)
	EndIf
EndFunction

; -- Check if player has empty potion bottle from Alchemy Requires Bottles
;
Bool Function CheckForBottles(Bool doMessage = True)
	If fEmptyBottle && _GP_HunterbornAnim_RequireBottle.GetValue()
		If PlayerRef.GetItemCount(fEmptyBottle) > 0
			PlayerRef.RemoveItem(fEmptyBottle, 1)
			Return True
		Else
			If doMessage
				Notification("$_GPAnim_RequiresBottle")
				RegisterForCancel()
				RegisterForMovement()
			EndIf
			Return False
		EndIf
	Else
		Return True
	EndIf
EndFunction

; -- Check for Arrows
;
Function CheckForArrows(Actor akCarcassRef, LeveledItem liAggregator)
	; Removes extra arrows, that player can't get by looting, from the carcass
	akCarcassRef.ClearExtraArrows()
	
	; Remit any arrows that player can get by looting.
	; SKSE Method, using GetNumItems GetNthForm and GetType to enumerate in place
	Int iFormIndex = akCarcassRef.GetNumItems()
	Form fArrow
	liAggregator.Revert()
	While iFormIndex
		iFormIndex -= 1
		fArrow = akCarcassRef.GetNthForm(iFormIndex)
		If fArrow.GetType() == 42 ; Ammo
			liAggregator.AddForm(fArrow, 1, akCarcassRef.GetItemCount(fArrow))
			akCarcassRef.RemoveItem(fArrow, akCarcassRef.GetItemCount(fArrow))
			fHuntingMaterial = (fArrow as Ammo).GetProjectile() as Form ; Save this for later
		EndIf
	EndWhile
	
	If liAggregator.GetNumForms() > 0
		; Performs arrow removal animation and adds arrows to the player's inventory
		If dsGlobals.gUseAnimation
			DoAnim(6)
		EndIf
		PlayerRef.AddItem(liAggregator)				
		Wait(1)
	EndIf
EndFunction

; -- Gets a random material/ingredient from the material list pool
;
Function CheckForMats(LeveledItem liAggregator)
	If !isIEDInstalled || !_GP_HunterbornAnim_Display.GetValue()
		Return
	EndIf
	
	; Uses function from PapyrusExtender, if available
	If PO3_SKSEFunctions.GetPapyrusExtenderVersion()[0] >= 5 && PO3_SKSEFunctions.GetPapyrusExtenderVersion()[1] >= 6
		Form[] fMaterialArray = PO3_SKSEFunctions.GetContentFromLeveledItem(liAggregator, PlayerRef)
		fHuntingMaterial = fMaterialArray[RandomInt(0, fMaterialArray.Length - 1)]
		Return
	EndIf
	
	; Gets a form from liAggregator loot pool by using the Wolfy Container
	; This function will add the leveled list to the container and retrieve a random item from it.
	Actor aWolfTemp = dsActions.SpawnMarker.PlaceActorAtMe(dsActions.ContainerWolf)
	aWolfTemp.AddItem(liAggregator)
	fHuntingMaterial = aWolfTemp.GetNthForm(RandomInt(0, aWolfTemp.GetNumItems() - 1))
	aWolfTemp.Disable()
	aWolfTemp.Delete()
		
	; Using Additem(liAggregator) on the player might give different items than using in the container
	; So, the items that the player gets might not be the same from the display
EndFunction

; -- Function to make player stand up
;
Function StandUp(Int iTypeOfStandup = 0, Int iCarcassIndex = 0)
	If CheckPlayerConditions() && PlayerRef.GetAnimationVariableBool("bAnimationDriven")
		While IsInMenuMode()
			Wait(0.1)
		EndWhile
		Float fTimer
		If iTypeOfStandup == 0 ; "normal" stand up
			If doPickupPelt ; Pick up pelt if it's available
				EnableDisplay("HuntingPelt", False)
				_GP_AnimTrigger.SetValue(900)
			Else
				_GP_AnimTrigger.SetValue(10)
			EndIf
			SendAnimationEvent(PlayerRef, "IdleStop")
		ElseIf iTypeOfStandup == 1 ; Pick up
			If _GP_HunterbornAnim_PickupAnim.GetValue()
				; Hunterborn 2026: the carry pose follows the size of the animal.
				If iCarcassIndex == 3 || iCarcassIndex == 12 ; Chicken or Hare: small enough to go straight into the inventory, a plain stand up
					_GP_AnimTrigger.SetValue(10)
				ElseIf iCarcassIndex == 9 || iCarcassIndex == 10 || iCarcassIndex == 21 ; Fox, ice fox or Skeever: on the hip
					_GP_AnimTrigger.SetValue(901)
				ElseIf iCarcassIndex == 6 || iCarcassIndex == 23 || iCarcassIndex == 24 || iCarcassIndex == 19 || iCarcassIndex == 20 || iCarcassIndex == 26 ; Dog, wolves, sabrecats: left or right, at random
					_GP_AnimTrigger.SetValue(902 + RandomInt(0, 1))
				ElseIf iCarcassIndex == 5 || iCarcassIndex == 7 || iCarcassIndex == 8 || iCarcassIndex == 25 || iCarcassIndex == 11 ; Elk, deer, goat: left or right, at random
					_GP_AnimTrigger.SetValue(902 + RandomInt(0, 1))
				ElseIf iCarcassIndex == 0 || iCarcassIndex == 1 || iCarcassIndex == 2 || iCarcassIndex == 4 || iCarcassIndex == 13 || iCarcassIndex == 14 || iCarcassIndex == 15 || iCarcassIndex == 27 ; Bears, cow, horker, horse, mammoth, bristleback: across the back
					_GP_AnimTrigger.SetValue(907)
				ElseIf iCarcassIndex == 16 ; Small Mudcrab
					_GP_AnimTrigger.SetValue(906)
				ElseIf iCarcassIndex == 17 || iCarcassIndex == 18 ; Large or Giant Mudcrab
					_GP_AnimTrigger.SetValue(907)
				ElseIf iCarcassIndex == 22 ; SlaughterFish
					_GP_AnimTrigger.SetValue(908)
				EndIf
			EndIf
			SendAnimationEvent(PlayerRef, "IdleStop")
		ElseIf iTypeOfStandup == 2 ; Dispose
			If doPickupPelt ; Pick up pelt if it's available
				EnableDisplay("HuntingPelt", False)
				_GP_AnimTrigger.SetValue(900)
			Else
				_GP_AnimTrigger.SetValue(10)
			EndIf
			SendAnimationEvent(PlayerRef, "IdleStop")
			While PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Wait(0.1)
			EndWhile

			If ShovelAnimationMarker && _GP_HunterbornAnim_DisposeShovel.GetValue()
				DisablePlayerControls()
				ObjectReference ShovelAnimationRef = PlayerRef.PlaceAtMe(ShovelAnimationMarker)
				ShovelAnimationRef.Activate(PlayerRef)

				Float timeRemaining = ShovelBodyQuest.delay

				While timeRemaining > 0
					Wait(0.5)
					timeRemaining -= 0.5
				EndWhile
					
				ShovelAnimationRef.Activate(PlayerRef)
				ShovelAnimationRef.Disable()
				ShovelAnimationRef.Delete()
				EnablePlayerControls()
			EndIf
		EndIf
	EndIf
	EndAnim(True)
EndFunction

; -- Function to create IED Displays
;
Function CreateDisplay(Int iTypeOfDisplay = 0, String sDisplay, Int iDisplayIndex = 0)
	If isIEDInstalled && _GP_HunterbornAnim_Display.GetValue()
		; Sets feathers for pluck animation
		If iTypeOfDisplay == 1
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
		
			If GetFormFromFile(0x0CC0640, "Update.esm") 
				fHuntingMaterial = GetFormFromFile(0x0CC0640, "Update.esm") ; Chicken feathers
			Else
				fHuntingMaterial = GetFormFromFile(0x00E7ED0, "Skyrim.esm") ; Hawk feathers
			EndIf
			
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC R Hand [RHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC R Hand [RHnd]") 
			EndIf
		; Obsolete
		ElseIf iTypeOfDisplay == 2
		
		ElseIf iTypeOfDisplay == 3
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC R Hand [RHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC R Hand [RHnd]") 
			EndIf	
			; Removing meat from carcass
		ElseIf iTypeOfDisplay == 4
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC L Hand [LHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC L Hand [LHnd]") 
			EndIf
		; Sets vial for blood/poison extract
		ElseIf iTypeOfDisplay == 5
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC L Hand [LHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC L Hand [LHnd]") 
			EndIf
		; Sets arrow for removing animation
		ElseIf iTypeOfDisplay == 6
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			
			; Arrow on right hand
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial, 1)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand") 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, fHuntingMaterial, False, "NPC R Hand [RHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, "NPC R Hand [RHnd]") 
			EndIf
			SetItemRemoveTracersActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, True)
			SetItemScaleActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, fScale)
			SetItemPositionActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, fArrayPosition)
			SetItemRotationActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, fArrayRotation)
			
			; Arrow on carcass
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC Root [Root]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC Root [Root]") 
			EndIf
			SetItemRemoveTracersActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, True)
			
		; Sets recently sninned pelt on the ground next to the player
		ElseIf iTypeOfDisplay == 7
			fHuntingPelt = fHuntingMaterial
			doPickupPelt = True
			
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
										
			; Swap pelt with custom model
			If iDisplayIndex == 19
				fHuntingMaterial = _GP_BrownFurDisplay
			ElseIf iDisplayIndex == 20 || iDisplayIndex == 24
				fHuntingMaterial = _GP_SnowFurDisplay
			ElseIf iDisplayIndex == 23
				fHuntingMaterial = _GP_BlackFurDisplay
			ElseIf iDisplayIndex == 26
				fHuntingMaterial = _GP_ValeFurDisplay
			EndIf
			
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial, iDisplayIndex)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC Root [Root]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC Root [Root]") 
			EndIf
		; Cooking food
		ElseIf iTypeOfDisplay == 8
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf 
			
			; Raw food on left hand
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial) 
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC L Hand [LHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC L Hand [LHnd]") 
			EndIf
			SetItemScaleActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fScale)
			SetItemPositionActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fArrayPosition)
			SetItemRotationActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fArrayRotation)
			
			; Raw food on knife
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial, 1) 
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", "CookingKnife") 
				CreateItemActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, fHuntingMaterial, False, "NPC R Hand [RHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, "NPC R Hand [RHnd]") 
			EndIf
			SetItemScaleActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, fScale)
			SetItemPositionActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, fArrayPosition)
			SetItemRotationActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, fArrayRotation)
			
			; Cooked food on knife
			SetItemTransform(iTypeOfDisplay, fCookedFood, 1) 
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", "CookedKnife") 
				CreateItemActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, fCookedFood, False, "NPC R Hand [RHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, fCookedFood)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, "NPC R Hand [RHnd]") 
			EndIf
			SetItemScaleActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, fScale)
			SetItemPositionActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, fArrayPosition)
			SetItemRotationActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, fArrayRotation)
			
			; Cooked food on left hand
			SetItemTransform(iTypeOfDisplay, fCookedFood) 
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", "CookedHand") 
				CreateItemActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, fCookedFood, False, "NPC L Hand [LHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, fCookedFood)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, "NPC L Hand [LHnd]") 
			EndIf
			SetItemScaleActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, fScale)
			SetItemPositionActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, fArrayPosition)
			SetItemRotationActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, fArrayRotation)
			
			Return
		; Torch on the ground
		ElseIf iTypeOfDisplay == 9
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			SetItemTransform(iTypeOfDisplay, fLeftHandItem)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fLeftHandItem, False,"NPC Root [Root]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fLeftHandItem)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC Root [Root]") 
			EndIf
			SetItemAttachLightActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, True)
		; Processing
		ElseIf iTypeOfDisplay == 10
			If !PlayerRef.GetAnimationVariableBool("bAnimationDriven")
				Return
			EndIf
			SetItemTransform(iTypeOfDisplay, fHuntingMaterial)
			If !ItemExistsActor(PlayerRef, "Hunterborn.esp", sDisplay) 
				CreateItemActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial, False, "NPC L Hand [LHnd]")
			Else
				SetItemFormActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fHuntingMaterial)
				SetItemNodeActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, "NPC L Hand [LHnd]") 
			EndIf
		EndIf
				
		SetItemDisableHavokActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, True)
		SetItemScaleActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fScale)
		SetItemPositionActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fArrayPosition)
		SetItemRotationActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, fArrayRotation)
	EndIf
	
EndFunction

; -- Function to enable/disable displays
;
Function EnableDisplay(String sDisplay, Bool doEnable = True)
	If isIEDInstalled
		If sDisplay == "HuntingArrow"
			If doEnable
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, True)
				WaitForCancel(1.7)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, False)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, True)
			Else
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, doEnable)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay+"Hand", isPlayerFemale, doEnable)
			EndIf
		ElseIf sDisplay == "CookingHand"
			If doEnable
				
				WaitForCancel(1 - (GetCurrentRealTime() - fCurrentTime))
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, True)
				
				WaitForCancel(1.35)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, False)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, True)
				
				WaitForCancel(3)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, False)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, True)
				
				WaitForCancel(3.4)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, False)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, True)
					
				WaitForCancel(1.3)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, False)
			Else
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, doEnable)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookingKnife", isPlayerFemale, doEnable)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedKnife", isPlayerFemale, doEnable)
				SetItemEnabledActor(PlayerRef, "Hunterborn.esp", "CookedHand", isPlayerFemale, doEnable)
			EndIf
		Else
			If doEnable && !_GP_HunterbornAnim_Display.GetValue()
				Return
			EndIF
			SetItemEnabledActor(PlayerRef, "Hunterborn.esp", sDisplay, isPlayerFemale, doEnable)
		EndIf
	EndIf
EndFunction

; -- Function to delete all displays
;
Function DeleteDisplay()
	DeleteAll("Hunterborn.esp")
EndFunction

; --- Function to set transform for the displays. If PapyrusUtil is installed, then reads from json, otherwise sets default values
;
Function SetItemTransform(Int iTypeOfTransform, Form fItemtoFind, Int iTypeOfItem = 0)
	fArrayPosition = New Float[3]
	fArrayRotation = New Float[3]
	If iTypeOfTransform == 1 ; Feathers for pluck animation
		fArrayPosition[0] = -5
		fArrayPosition[1] = -3.5
		fArrayPosition[2] = 5
		fArrayRotation[0] = -43
		fArrayRotation[1] = 137
		fArrayRotation[2] = -30
	ElseIf iTypeOfTransform == 2 ; Obsolete
	
	ElseIf iTypeOfTransform == 3 ; Harvest Animation
		If !ReadTransformFromJson("HarvestList", "HarvestDefault", fItemtoFind.GetWorldModelPath())
			fArrayPosition[0] = -2
			fArrayPosition[1] = -3.5
			fArrayPosition[2] = 8.5
			fArrayRotation[0] = -98
			fArrayRotation[1] = 108.5
			fArrayRotation[2] = 0
			fScale = 1
		EndIf
	ElseIf iTypeOfTransform == 4 ; Butcher
		If !ReadTransformFromJson("ButcherList", "ButcherDefault", fItemtoFind.GetWorldModelPath())
			fArrayPosition[0] = -0.5
			fArrayPosition[1] = -2.5
			fArrayPosition[2] = 6.5
			fArrayRotation[0] = 0
			fArrayRotation[1] = 3
			fArrayRotation[2] = 91
			fScale = 1
		EndIf
	ElseIf iTypeOfTransform == 5 ; Extract Animation
		If !ReadTransformFromJson("ExtractList", "ExtractDefault", fItemtoFind.GetWorldModelPath())
			fArrayPosition[0] = 7.5
			fArrayPosition[1] = -11.5
			fArrayPosition[2] = 12
			fArrayRotation[0] = 50.5
			fArrayRotation[1] = 169
			fArrayRotation[2] = -97.5
			fScale = 1
		EndIf
	ElseIf iTypeOfTransform == 6 ; Arrows
		If iTypeOfItem == 0 ; Arrow placed on carcass
			If !ReadTransformFromJson("ArrowList", "ArrowDefault_Carcass", fItemtoFind.GetWorldModelPath()+"_Carcass")
				fArrayPosition[0] = 2.5
				fArrayPosition[1] = 55
				fArrayPosition[2] = -8.5
				fArrayRotation[0] = -5.5
				fArrayRotation[1] = -7
				fArrayRotation[2] = 268.5
				fScale = 1
			EndIf
		Else ; Arrow placed on hand
			If !ReadTransformFromJson("ArrowList", "ArrowDefault_Hand", fItemtoFind.GetWorldModelPath()+"_Hand")	
				fArrayPosition[0] = -25.5
				fArrayPosition[1] = -7.5
				fArrayPosition[2] = 4
				fArrayRotation[0] = 20.5
				fArrayRotation[1] = 101.5
				fArrayRotation[2] = 25.5
				fScale = 1
			EndIf
		EndIf
	ElseIf iTypeOfTransform == 7 ; Pelts on the ground
		If !ReadTransformFromJson("PeltList", "PeltDefault", fItemtoFind.GetWorldModelPath())
			If iTypeOfItem == 0 || iTypeOfItem == 1 || iTypeOfItem == 2 ; Bear
				fArrayPosition[0] = 41.5
				fArrayPosition[1] = 17
				fArrayPosition[2] = 0
				fArrayRotation[0] = 0
				fArrayRotation[1] = 90
				fArrayRotation[2] = 0
			ElseIf iTypeOfItem == 27 ; Bristleback
				fArrayPosition[0] = 45
				fArrayPosition[1] = 16.5
				fArrayPosition[2] = 8.5
				fArrayRotation[0] = 0
				fArrayRotation[1] = 0
				fArrayRotation[2] = 0
			ElseIf iTypeOfItem == 5 || iTypeOfItem == 7 || iTypeOfItem == 8 || iTypeOfItem == 25 ; Deer/Elk
				fArrayPosition[0] = 36
				fArrayPosition[1] = 17.5
				fArrayPosition[2] = 0
				fArrayRotation[0] = 0
				fArrayRotation[1] = 0
				fArrayRotation[2] = 0
			ElseIf iTypeOfItem == 14 ; Horse
				fArrayPosition[0] = 36
				fArrayPosition[1] = 16.5
				fArrayPosition[2] = 0.5
				fArrayRotation[0] = 0
				fArrayRotation[1] = 0
				fArrayRotation[2] = 0
			ElseIf iTypeOfItem == 4 || iTypeOfItem == 15 || iTypeOfItem == 104 ; Cow, Mammoth or Troll
				fArrayPosition[0] = 48
				fArrayPosition[1] = 16.5
				fArrayPosition[2] = 0.5
				fArrayRotation[0] = 0
				fArrayRotation[1] = 0
				fArrayRotation[2] = 0
			ElseIf iTypeOfItem == 19 || iTypeOfItem == 20 || iTypeOfItem == 23 || iTypeOfItem == 24 || iTypeOfItem == 26 ; Sabrecats or wolves
				fArrayPosition[0] = 41.5
				fArrayPosition[1] = 11.5
				fArrayPosition[2] = 0
				fArrayRotation[0] = 57.5
				fArrayRotation[1] = 92.5
				fArrayRotation[2] = -302.5
			Else ; Default position
				fArrayPosition[0] = 50
				fArrayPosition[1] = 7
				fArrayPosition[2] = 2
				fArrayRotation[0] = 0
				fArrayRotation[1] = 0
				fArrayRotation[2] = 0
			EndIf
			fScale = 1
		EndIf
	ElseIf iTypeOfTransform == 8 ; Cooking
		If iTypeOfItem == 0 ; Food placed on left hand
			If !ReadTransformFromJson("CookingList", "CookingDefault_Hand", fItemtoFind.GetWorldModelPath()+"_Hand")
				fArrayPosition[0] = -0.5
				fArrayPosition[1] = -2.5
				fArrayPosition[2] = 6.5
				fArrayRotation[0] = 0
				fArrayRotation[1] = 3
				fArrayRotation[2] = 90
				fScale = 1
			EndIf
		Else ; Food placed on knife
			If !ReadTransformFromJson("CookingList", "CookingDefault_Knife", fItemtoFind.GetWorldModelPath()+"_Knife")
				fArrayPosition[0] = 16
				fArrayPosition[1] = -0.5
				fArrayPosition[2] = 12
				fArrayRotation[0] = -95.5
				fArrayRotation[1] = 13.5
				fArrayRotation[2] = 79
				fScale = 1
			EndIf
		EndIf
	ElseIf iTypeOfTransform == 9 ; Torch
		If !ReadTransformFromJson("TorchList", "TorchDefault", fItemtoFind.GetWorldModelPath())
			fArrayPosition[0] = 40
			fArrayPosition[1] = 0
			fArrayPosition[2] = 10
			fArrayRotation[0] = 0
			fArrayRotation[1] = 0
			fArrayRotation[2] = RandomFloat(80, 100)
			fScale = 1
		EndIf
	ElseIf iTypeOfTransform == 10 ; Process; Same thing as butcher, basically
		If !ReadTransformFromJson("ProcessList", "ProcessDefault", fItemtoFind.GetWorldModelPath())
			fArrayPosition[0] = -0.5
			fArrayPosition[1] = -2.5
			fArrayPosition[2] = 6.5
			fArrayRotation[0] = 0
			fArrayRotation[1] = 3
			fArrayRotation[2] = 91
			fScale = 1
		EndIf
	EndIf
EndFunction

Bool Function ReadTransformFromJson(String sFileName, String sDefault, String sModelPath)
	; Checks if PapyrusUtil is installed
	If !PapyrusUtil.GetScriptVersion()
		Return False
	EndIf
	
	String sItemNif = sModelPath
	; Gets model path and splits it with the delimiter '\' to get the mesh file name
	If StringUtil.Find(sModelPath, "\\") != -1
		String[] sModelPathArray = StringUtil.Split(sModelPath, "\\" )
		sItemNif = sModelPathArray[sModelPathArray.Length - 1]
	EndIf
	
	; Finds additional files in the folder. This is useful if someone decides to make patch for other items; It's possible to create new files with the same names, but with a prefix/suffix.
	; Example: IH_CookingList_SomeCampfireMod.json
	; The functions below will try to look for the sItemNif in the file above first, then search the default files if not found.
	String[] sFolderArray = JsonUtil.JsonInFolder(sFilePath)
	Int iArrayIndex = sFolderArray.Length
	Bool doBreak
	
	If iArrayIndex > 8 ;  If the number of files in the folder is not greater than 7(default configs), there is no need to search for additional files.
		While iArrayIndex && !doBreak
			iArrayIndex -= 1
			If StringUtil.Find(sFolderArray[iArrayIndex], sFileName) != -1 && (sFileName + ".json") != sFolderArray[iArrayIndex]
				If JsonUtil.FloatListCount(sFilePath + sFolderArray[iArrayIndex], sItemNif) > 0
					sFileName = sFolderArray[iArrayIndex]
					doBreak = True
				EndIf
			EndIf
		EndWhile
	EndIf
	
	; Checks integrity of file
	If !JsonUtil.IsGood(sFilePath + sFileName)
		Return False
	EndIf
	
	If JsonUtil.FloatListCount(sFilePath + sFileName, sItemNif) > 0 ; Checks if the form has config
		fArrayPosition[0] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 0)
		fArrayPosition[1] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 1)
		fArrayPosition[2] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 2)
		fArrayRotation[0] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 3)
		fArrayRotation[1] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 4)
		fArrayRotation[2] = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 5)
		fScale = JsonUtil.FloatListGet(sFilePath + sFileName, sItemNif, 6)
	ElseIf JsonUtil.FloatListCount(sFilePath + sFileName, sDefault) > 0 ; If not, then read default values
		fArrayPosition[0] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 0)
		fArrayPosition[1] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 1)
		fArrayPosition[2] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 2)
		fArrayRotation[0] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 3)
		fArrayRotation[1] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 4)
		fArrayRotation[2] = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 5)
		fScale = JsonUtil.FloatListGet(sFilePath + sFileName, sDefault, 6)
	Else ; Didn't find config, return false
		Return False
	EndIf
	
	Return True
EndFunction

