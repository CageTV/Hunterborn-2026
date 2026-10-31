; Hunterborn 2026 - Animations patch. Hunterborn Animations (Nexus 80677) by Elsawirr (animations) and GiraPomba (scripts) is the source of the animation calls
; in this script; the author allows modifying the files with credit, and asks that patches require the mod. Their version, unchanged (it already contains a Process hotkey fix for monsters).
; Needs Hunterborn - Animations installed (the animation calls look its quest up at run time and do nothing without it).
Scriptname _DS_HB_mgef_Track extends activemagiceffect  

_DS_HB_Globals Property dsGlobals Auto
_DS_HB_Actions Property dsActions Auto
_DS_HB_Animals Property dsAnimals Auto
_DS_HB_Tracks_Finder Property dsTracksFinder Auto

Actor Property PlayerRef Auto

Spell Property spelRegionDetect Auto
MagicEffect Property mgefTracker Auto

Keyword Property kwLocTypeCity Auto
;FormList Property flForageLocsInvalid Auto
FormList Property flForageLocsHolds Auto

Message Property MsgErrorCantInCombat Auto
Message Property MsgMustBeOutdoors Auto
Message Property MsgErrorCantTrackHere Auto
Message Property MsgFailedToTrack Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)

	DebugMode("_DS_HB_mgef_Track OnEffectStart")
	
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
		MsgErrorCantTrackHere.Show()
		Return
	EndIf
	
	int foragelevel = dsGlobals.gForageLevel
	DebugMode("foragelevel = " + foragelevel)
	
	If dsGlobals.gUseAnimation
		dsActions.gpAnimFunctions.CheckWeaponsDrawn()
		If !PlayerRef.isWeaponDrawn()
			dsActions.gpAnimFunctions.doAnim(11)
		EndIf
	EndIf

	; Tracks - added 1.6.2
	; This is mutually exclusive with scavenging just to keep popup clutter down - maybe a discrete skill later?
	Actor tracked = none
	string tracked_name
	string tracked_dir
  
  int trackroll = Utility.RandomInt()
  If PlayerRef.HasMagicEffect(mgefTracker)
    trackroll += 15
  EndIf
  If foragelevel > 9
    trackroll += 80
  ElseIf foragelevel > 7
    trackroll += 65
  ElseIf foragelevel > 5
    trackroll += 50
  ElseIf foragelevel > 3
    trackroll += 40
  ElseIf foragelevel > 1
    trackroll += 30
  EndIf
  If trackroll > 99		
    DebugMode("Attempting tracking...")
    dsTracksFinder.Start()
    tracked = dsTracksFinder.AnimalFound.GetActorRef()
    DebugMode("found = " + tracked)
    dsTracksFinder.Stop()
    dsTracksFinder.Reset()
  EndIf

	If dsGlobals.gTrackingTimed
		dsActions.FadeToBlack()
		dsActions.AdvanceGameTime(0.25)
		dsActions.FadeFromBlack()
	EndIf
	
	If tracked != None
		DebugMode("Tracking debug:")
		DebugMode("MyX = " + PlayerRef.X + " MyY = " + PlayerRef.Y + " MyZ = " + PlayerRef.Z)
		DebugMode("FoundX = " + tracked.X + " FoundY = " + tracked.Y + " FoundZ = " + tracked.Z)
		tracked_name = dsAnimals.GetRaceName(tracked.GetRace())
		DebugMode("Race = " + tracked.GetRace() + " '" + tracked_name + "'")
		tracked_dir = "somewhere"
		; This is dynamic, so it can't (easily) use Properties for translation. Sorry. :(
		If foragelevel < 3
			Debug.MessageBox("While tracking game, you found some " + tracked_name + " sign. May be one nearby.")
		Else
			tracked_dir = GetDirectionTowardRef(tracked, foragelevel > 4)
			Debug.MessageBox("While tracking game, you found some " + tracked_name + " tracks, heading " + tracked_dir + ".")
		EndIf
		DebugMode("Direction = '" + tracked_dir + "'")
  Else
    MsgFailedToTrack.Show()
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

string Function GetDirectionTowardRef(ObjectReference akTarget, bool abDetailed)
	float PX = PlayerRef.X
	float PY = PlayerRef.Y
	float TX = akTarget.X
	float TY = akTarget.Y
	float EastWest = TX - PX
	float NorthSouth = TY - PY
	float EWA = Math.abs(EastWest)
	float NSA = Math.abs(NorthSouth)
	float EWF = EWA / 2
	float NSF = NSA / 2
	DebugMode("EastWest = " + EastWest + " NorthSouth = " + NorthSouth)
	DebugMode("EWA = " + EWA + " NSA = " + NSA + " EWF = " + EWF + " NSF = " + NSF)
	If abDetailed
		If NorthSouth > 0 && NSF > EWA
			Return "north"
		ElseIf NorthSouth > 0 && EastWest > 0 && NSA >= EWF
			Return "northeast"
		ElseIf EastWest > 0 && EWF > NSA
			Return "east"
		ElseIf EastWest > 0 && NorthSouth <= 0 && EWA >= NSF
			Return "southeast"
		ElseIf NorthSouth <= 0 && NSF > EWA
			Return "south"
		ElseIf NorthSouth <= 0 && EastWest <= 0 && NSA >= EWF
			Return "southwest"
		ElseIf EastWest <= 0 && EWF > NSA
			Return "west"
		ElseIf EastWest <= 0 && NorthSouth > 0 && EWA >= NSF
			Return "northwest"
		EndIf
	Else
		If NorthSouth > 0 && EWA <= NSA
			Return "north"
		ElseIf EastWest > 0 && EWA > NSA
			Return "east"			
		ElseIf NorthSouth <= 0 && EWA <= NSA
			Return "south"
		ElseIf EastWest <= 0 && EWA > NSA
			Return "west"
		EndIf
	EndIf
	Return "in opposite directions simultaneously"
EndFunction


; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Debug.Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
