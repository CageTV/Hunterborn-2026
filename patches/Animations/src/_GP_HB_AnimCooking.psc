; Hunterborn - Animations by Elsawirr and GiraPomba (Nexus 80677), modified by Hunterborn 2026 (CageTV): the Hunterborn quest is found through HunterbornNative.ModFormId, so the ESL edition of Hunterborn.esp works.
Scriptname _GP_HB_AnimCooking extends ObjectReference  

_GP_HB_AnimFunctions gpAnimFunctions
_DS_HB_Globals dsGlobals

Event OnInit()
	Utility.Wait(3)
	LoadScriptVariables()
EndEvent

Event OnActivate(ObjectReference akActionRef)
	If !gpAnimFunctions || !dsGlobals
		LoadScriptVariables()
	EndIf
	
	gpAnimFunctions.CheckWeaponsDrawn()
	
	If dsGlobals.gUseAnimation
		gpAnimFunctions.doAnim(7)
	EndIf
	
	gpAnimFunctions.CheckWeaponsDrawn(False)
EndEvent

Function LoadScriptVariables()
	gpAnimFunctions = (Game.GetFormFromFile(0x0000800, "Hunterborn - Animations.esp") as Quest) as _GP_HB_AnimFunctions
	dsGlobals = (Game.GetFormFromFile(HunterbornNative.ModFormId(0x0003367, "Hunterborn.esp"), "Hunterborn.esp") as Quest) as _DS_HB_Globals
EndFunction


