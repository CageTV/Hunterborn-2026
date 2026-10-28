Scriptname _DS_HB_Animals extends Quest

_DS_HB_Globals Property dsGlobals Auto


; PROPERTIES --------------------------------------------------------------------------------------

; These are for manual lookup, by ActivateEmptyCarcass and dynamic DLC changes.
int Property INDEX_BEAR				= 0  AutoReadOnly
int Property INDEX_BEARCAVE			= 1  AutoReadOnly
int Property INDEX_BEARSNOW			= 2  AutoReadOnly
int Property INDEX_CHICKEN			= 3  AutoReadOnly
int Property INDEX_COW				= 4  AutoReadOnly
int Property INDEX_DEER				= 5  AutoReadOnly
int Property INDEX_DOG				= 6  AutoReadOnly
int Property INDEX_ELKFEMALE		= 7  AutoReadOnly
int Property INDEX_ELKMALE			= 8  AutoReadOnly
int Property INDEX_FOX				= 9  AutoReadOnly
int Property INDEX_FOXICE			= 10 AutoReadOnly
int Property INDEX_GOAT				= 11 AutoReadOnly
int Property INDEX_HARE				= 12 AutoReadOnly
int Property INDEX_HORKER			= 13 AutoReadOnly
int Property INDEX_HORSE			= 14 AutoReadOnly
int Property INDEX_MAMMOTH			= 15 AutoReadOnly
int Property INDEX_MUDCRAB01		= 16 AutoReadOnly
int Property INDEX_MUDCRAB02		= 17 AutoReadOnly
int Property INDEX_MUDCRAB03		= 18 AutoReadOnly
int Property INDEX_SABRECAT			= 19 AutoReadOnly
int Property INDEX_SABRECATSNOW		= 20 AutoReadOnly
int Property INDEX_SKEEVER			= 21 AutoReadOnly
int Property INDEX_SLAUGHTERFISH	= 22 AutoReadOnly
int Property INDEX_WOLF				= 23 AutoReadOnly
int Property INDEX_WOLFICE			= 24 AutoReadOnly
int Property INDEX_DEERVALE			= 25 AutoReadOnly
int Property INDEX_SABRECATVALE		= 26 AutoReadOnly
int Property INDEX_BRISTLEBACK		= 27 AutoReadOnly

; List of all the LeveledItem death items Hunterborn handles - for InitDeathItems.
FormList Property flDeathItems Auto
; GV's that enable/disable certain small game, via MCM.
GlobalVariable[] Property ActiveAnimalSwitches Auto
; Array of the LeveledItem's for all the HB specific tokens for each animal type.
LeveledItem[] Property DeathItemLI Auto
; Array of any "shared" DeathItem / LeveledItem's that will supplement the DeathItemLI array above
FormList[] Property SharedDeathItems Auto
; Array for checking animal type
String[] Property AnimalIndex Auto

; List of all the ActorBase "fresh" carcasses that can be spawned for "orphaned" CarcassObjects.
FormList Property flCarcassesFresh Auto
; List of all the MiscObject carcass placeholders.
FormList Property flCarcassObjects Auto
MiscObject Property moTokenCarcass_Fresh Auto
MiscObject Property moTokenCarcass_Clean Auto
; How big a carcass is, for figuring how long it takes to dress / skin, etc.
int[] Property CarcassSizes Auto
;float[] Property CarcassWeights Auto
; List of all the MiscObject death item tokens identifying fresh carcasses.
FormList Property flDeathItemTokens Auto
; And the keyword they all have that identifies them as such.
Keyword Property kwDeathItemToken Auto

ObjectReference Property SpawnMarker Auto

; List of all the pelt FormLists.
FormList Property flPeltLists Auto
; How many pelts certain animals (mammoths) yield.
int[] Property MultiPelts Auto
; Default base pelt values, used for dynamic re-valuation.
int[] Property DefaultPeltValues Auto
; The (extra) "quality" pelts for SkyRe
MiscObject[] Property SkyRePelts Auto
int[] Property SkyRePeltIDs Auto
; ... and for PerMa
MiscObject[] Property PerMaPelts Auto
int[] Property PerMaPeltIDs Auto

; List of all the mats FormLists.
FormList Property flMatLists Auto
; A unique mat list for goats.
LeveledItem Property liGoatRocks Auto

; Perfect mats.
FormList Property flPerfectMats Auto

; Array of meat types (Potions) that drop for any given animal.
Potion[] Property MeatTypes Auto
; Vanilla meats to re-weight.
FormList Property flDefaultMeats Auto
; Default vanilla meat weights, used for dynamic re-weighting.
float[] Property DefaultMeatWeights Auto
; Re-weighted values.
float[] Property HBMeatWeights Auto
; For SKSE-less weight lookups
float[] Property AllMeatWeights Auto
; Default base meat values, used for dynamic re-valuation.
;int[] Property DefaultMeatValues Auto

; SE no-SKSE static meat count tables
int[] Property MeatCounts_0Scrawny Auto
int[] Property MeatCounts_1Lean Auto
int[] Property MeatCounts_2Normal Auto

; Used by Forage / track animals
; This supports *most* of the races that have Keyword ActorTypeAnimal
FormList Property flAnimalRaces Auto
string[] Property AnimalRaceNames Auto

; Dawnguard Items.
LeveledItem Property liDLC1DeerDeathItem Auto Hidden
LeveledItem Property liDLC1SabreCatDeathItem Auto Hidden
MiscObject Property moDLC1DeerHide Auto Hidden
MiscObject Property moDLC1SabreCatHide Auto Hidden
; HearthFire items.
MiscObject Property moBYOHGoatHorns Auto Hidden
Potion Property poBYOHMudcrabLegs Auto Hidden


; FUNCTIONS ---------------------------------------------------------------------------------------

; -- InitDeathItems
;
; When started (from MCM) Hunterborn adds MiscObject's to each of the animal Death Items.
; _DS_Token_Carcass is used by _DS_PerkCarcass to identify a carcass Hunterborn should activate.
; The rest are used to identify the type of carcass, since GetRace is inadequate without a GetSkin.
;
Function InitDeathItems(bool abRevertAll = False)

	DebugMode("Animal InitDeathItems abRevertAll = " + abRevertAll)

	int i
	int j
	FormList fl
	FormList share
	LeveledItem di

	; Populate shares first. Shares take precedence in the main routine below.
	DebugMode("Configuring Shared FormLists.")
	i = SharedDeathItems.Length
	While i
		i -= 1
		DebugMode("Index " + i + "...")
		share = SharedDeathItems[i]
		If share
			DebugMode("Share = " + share)
		
			If abRevertAll
				; As per CreationKit.com, RemoveAddedForm may not be reliable. But the note is pretty old.
				; Google results suggest it's been fixed since then?
				If share.HasForm(moTokenCarcass_Fresh)
					DebugMode("RemoveAddedForm " + moTokenCarcass_Fresh)
					share.RemoveAddedForm(moTokenCarcass_Fresh)
				EndIf
				If share.HasForm(flDeathItemTokens.GetAt(i))
					DebugMode("RemoveAddedForm " + flDeathItemTokens.GetAt(i))
					share.RemoveAddedForm(flDeathItemTokens.GetAt(i))
				EndIf
				
			Else
				If !share.HasForm(moTokenCarcass_Fresh)
					DebugMode("AddForm " + moTokenCarcass_Fresh)
					share.AddForm(moTokenCarcass_Fresh)
				EndIf
				If !share.HasForm(flDeathItemTokens.GetAt(i))
					DebugMode("AddForm " + flDeathItemTokens.GetAt(i))
					share.AddForm(flDeathItemTokens.GetAt(i))
				EndIf
			EndIf
			
		EndIf
	EndWhile

	DebugMode("Init death items.")
	i = flDeathItems.GetSize()
	While i
		i -= 1
		DebugMode("Index " + i + "...")
		di = flDeathItems.GetAt(i) as LeveledItem
		di.Revert()
		share = SharedDeathItems[i]
		If !abRevertAll && IsActiveAnimal(i)
			; If there is a shared DI, load from it. As of 1.4, only Immersive Armors (IA7) uses shared DI's.
			; Problem: The exclusive indices above (dog, goat, etc) won't use this system... future fix may be needed. IA doesn't mess with those, though.
			If share
				DebugMode("This death item is shared.")
				j = share.GetSize()
				While j
					j -= 1
					DebugMode("AddForm " + share.GetAt(j))
					di.AddForm( share.GetAt(j), 1, 1 )
				EndWhile
			Else
				DebugMode("AddForm " + moTokenCarcass_Fresh)
				di.AddForm(moTokenCarcass_Fresh, 1, 1)
				DebugMode("AddForm " + flDeathItemTokens.GetAt(i))
				di.AddForm(flDeathItemTokens.GetAt(i), 1, 1)
			EndIf
		EndIf
	EndWhile
	
	; Hunterborn 2026 AutoPatch: the animals other mods add have loot lists of their own. They get what a vanilla animal's list gets (the fresh
	; carcass token and the type's token), only while Hunterborn runs and the type is active. HunterbornNative.dll says which lists they are.
	i = flDeathItems.GetSize()
	While i
		i -= 1
		LeveledItem[] extra = HunterbornNative.GetLists(False, i)
		If extra
			j = extra.Length
			While j
				j -= 1
				extra[j].Revert()
				If !abRevertAll && IsActiveAnimal(i)
					extra[j].AddForm(moTokenCarcass_Fresh, 1, 1)
					extra[j].AddForm(flDeathItemTokens.GetAt(i), 1, 1)
				EndIf
			EndWhile
		EndIf
	EndWhile

	DebugMode("Animal InitDeathItems done!")
	
EndFunction


; -- IsActiveAnimal
;
bool Function IsActiveAnimal(int aiIndex)

	GlobalVariable g = ActiveAnimalSwitches[aiIndex]
	Return ( g == None || (dsGlobals.gSmallGame && g.GetValueInt() == 1) )

EndFunction


; -- SpawnNew
;
; This is called when a MiscObject gets dropped that doesn't have a match in the CarcassArray.
; This could happen if you bought a carcass back from a vendor, took it out of a container, or just used the console to add one for testing.
; It doesn't 'muffle' like with SpawnDressed, since you're presumably dropping it anyway.
;
Actor Function SpawnNew(MiscObject akPlaceholder)

	Return SpawnMarker.PlaceActorAtMe( flCarcassesFresh.GetAt( flCarcassObjects.Find(akPlaceholder) ) as ActorBase )
	
EndFunction


; -- GetCarcassToken
;
; Look up the MiscObject token that should be on the carcass this MiscObject placeholder represents.
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

; -- SetPeltValues
;
Function SetPeltValues(int aiValue, FormList akPelts, int[] aiPeltValues)

	int mult = aiValue
	If (aiValue == 2)
		mult = 10
	ElseIf (aiValue == 3)
		mult = 50
	EndIf
	
	int i = akPelts.GetSize()
	FormList fl
	MiscObject mo
	While (i)
		i -= 1
		fl = akPelts.GetAt(i) as FormList
		If (fl.GetSize() > 0)
			; Poor quality pelt
			mo = fl.GetAt(0) as MiscObject
			mo.SetGoldValue( mult * Math.Floor(aiPeltValues[i] * 0.5) )
		EndIf
		If (fl.GetSize() > 1)
			; Default (vanilla) pelt
			mo = fl.GetAt(1) as MiscObject
			mo.SetGoldValue( mult * aiPeltValues[i] )
		EndIf
		If (fl.GetSize() > 2)
			; Fine quality pelt
			mo = fl.GetAt(2) as MiscObject
			mo.SetGoldValue( mult * aiPeltValues[i] * 2 )
		EndIf
		If (fl.GetSize() > 3)
			; Flawless quality pelt
			mo = fl.GetAt(3) as MiscObject
			mo.SetGoldValue( mult * aiPeltValues[i] * 20 )
		EndIf
	EndWhile
	
EndFunction

; -- ReweighMeat
;
Function ReweighMeat(bool abRevertAll = False)
	int i = flDefaultMeats.GetSize()
	Potion p
	While (i)
		i -= 1
		p = flDefaultMeats.GetAt(i) as Potion
		If (abRevertAll)
			p.SetWeight(DefaultMeatWeights[i])
		Else
			;Debug.Notification(p.GetWeight() + " to " + HBMeatWeights[i])
			p.SetWeight(HBMeatWeights[i])
		EndIf
	EndWhile
EndFunction

; -- GetMeatWeight
;
; Stand-in function until SKSE GetWeight is available again.
; This just assumes all meat weight has been statically assigned in ESP.
;

float Function GetMeatWeight(int aiIndex)
	If (aiIndex < 0)
		Return 1
	Else
		Return AllMeatWeights[aiIndex]
	EndIf
EndFunction



; -- GetMeatCount
;
; How many of this meat type does the animal yield, under various settings?
; The result is a TOTAL, calling function must handle sectioning.
;
; This works differently in SE, simplifying the math using just the carcass size, with a little variability.
;
int Function GetMeatCount(int aiSize)

	DebugMode("GetMeatCount aiSize = " + aiSize + " ; gMeatYield = " + dsGlobals.gMeatYield)
	
	int result
	int rnd = Utility.RandomInt()
	float delta
	int bonus
	int abundance = dsGlobals.gMeatYield
	
	If (abundance == 0)
		result = MeatCounts_0Scrawny[aiSize]
		DebugMode("result = " + result)
		; At Scrawny there's a chance you get some extra
		If (rnd > 65)
			delta = Utility.RandomFloat(0.01, 0.5)
			DebugMode("delta = " + delta)
			bonus = Math.Ceiling(result * delta)
			DebugMode("bonus = " + bonus)
			result += bonus
		EndIf
	ElseIf (abundance == 1)
		result = MeatCounts_1Lean[aiSize]
		DebugMode("result = " + result)
		; At Lean there's a chance you get some less
		If (rnd > 50)
			If (result == 1)
				bonus = 0
			ElseIf (result == 2)
				bonus = 1
			Else
				delta = Utility.RandomFloat(0.01, 0.6)
				DebugMode("delta = " + delta)
				bonus = Math.Floor(result * delta)
			EndIf
			DebugMode("loss = " + bonus)
			result -= bonus
		EndIf
	ElseIf (abundance == 2)
		result = MeatCounts_2Normal[aiSize]
		DebugMode("result = " + result)
		; At Normal you always get a certain amount less
		; There's some favoritism for small game
		If (result == 2 && rnd > 50)
			bonus = 1
		ElseIf (result > 2)
			delta = Utility.RandomFloat(0.01, 0.5)
			DebugMode("delta = " + delta)
			bonus = Math.Floor(result * delta)
		EndIf
		DebugMode("loss = " + bonus)
		result -= bonus
	Else
		; Only supported through console hacks: set meatyield to 4, set meatyieldcustom to > 100
		result = MeatCounts_2Normal[aiSize]
		DebugMode("result = " + result)
		; Use Normal as a baseline and apply a percent to it (which should be > 100)
		int yc = dsGlobals.gMeatYieldCustom
		If yc < 100
			yc = 100
		EndIf
		yc += Utility.RandomInt(-25, 25)
		delta = yc
		delta = delta / 100
		DebugMode("custom% = " + yc + " ; delta = " + delta)
		result = Math.Floor(result * delta)
		DebugMode("result = " + result)
	EndIf
	
	If (result < 1)
		result = 1
	EndIf
	
	Return result
	
EndFunction


; -- PrepForDLC
;
; Dynamically load in DLC resources if they're available.
;
Function PrepForDLC()

	Form f
	bool dlc_removed
	bool dlc_added
	FormList fl
	LeveledItem li
	int i
	int j
	
	; Dawnguard
	;
	f = Game.GetFormFromFile(0x013E25, "Dawnguard.esm")
;	dlc_added = !dsGlobals.isDLC1Loaded && f
;	dlc_removed = dsGlobals.isDLC1Loaded && !f
;	Debug.MessageBox("Dawnguard:\nAdded? " + dlc_added + "\nRemoved? " + dlc_removed)
	dsGlobals.isDLC1Loaded = f
;	If (dlc_added || dlc_removed)
;		liDLC1DeerDeathItem = f as LeveledItem														; ADD REMOVE VALE DEER HIDE
;		liDLC1DeerDeathItem.Revert()
;		moDLC1DeerHide = Game.GetFormFromFile(0x011999, "Dawnguard.esm") as MiscObject
;		liDLC1SabreCatDeathItem = Game.GetFormFromFile(0x013E24, "Dawnguard.esm") as LeveledItem	; ADD REMOVE VALE SABRECAT HIDE
;		moDLC1SabreCatHide = Game.GetFormFromFile(0x01199A, "Dawnguard.esm") as MiscObject
;	EndIf
	
	; Hearthfire
	;
	f = Game.GetFormFromFile(0x00303F, "HearthFires.esm")
	dlc_added = !dsGlobals.isBYOHLoaded && f
	dlc_removed = dsGlobals.isBYOHLoaded && !f
;	Debug.MessageBox("Hearthfire:\nAdded? " + dlc_added + "\nRemoved? " + dlc_removed)
	dsGlobals.isBYOHLoaded = f
	If (dlc_added || dlc_removed)
		moBYOHGoatHorns = f as MiscObject															; ADD REMOVE GOAT HORNS
		i = 1
		fl = flMatLists.GetAt(INDEX_GOAT) as FormList
		While (i < 3)
			li = fl.GetAt(i) as LeveledItem
			li.Revert()
			If (dlc_added)
				li.AddForm(moBYOHGoatHorns, 1, 1)
			EndIf
			i += 1
		EndWhile
		poBYOHMudcrabLegs = Game.GetFormFromFile(0x003540, "HearthFires.esm") as Potion				; ADD REMOVE MUD CRAB LEGS
		li = DeathItemLI[INDEX_MUDCRAB01]
		li.Revert()
		If (dlc_added)
			li.AddForm(poBYOHMudcrabLegs, 1, 1)
		EndIf
	EndIf
	
	; Dragonborn
	;
	dsGlobals.isDLC2Loaded = Game.GetFormFromFile(0x01FB99, "Dragonborn.esm")

EndFunction

string Function GetRaceName(Race akRace)
	int r = flAnimalRaces.Find(akRace)
	If r < 0
		Return ""
	Else
		; Without SKSE, these have to be set in script to avoid the uppercasing bug :\
		AnimalRaceNames[0]	= "bear"
		AnimalRaceNames[1]	= "bear"
		AnimalRaceNames[2]	= "bear"
		AnimalRaceNames[3]	= "chaurus"
		AnimalRaceNames[4]	= "chaurus"
		AnimalRaceNames[5]	= "cow"
		AnimalRaceNames[6]	= "deer"
		AnimalRaceNames[7]	= "chaurus"
		AnimalRaceNames[8]	= "deer"
		AnimalRaceNames[9]	= "dog"
		AnimalRaceNames[10]	= "dog"
		AnimalRaceNames[11]	= "dog"
		AnimalRaceNames[12]	= "dog"
		AnimalRaceNames[13]	= "sabre cat"
		AnimalRaceNames[14]	= "mudcrab"
		AnimalRaceNames[15]	= "dog"
		AnimalRaceNames[16]	= "dog"
		AnimalRaceNames[17]	= "elk"
		AnimalRaceNames[18]	= "spider"
		AnimalRaceNames[19]	= "spider"
		AnimalRaceNames[20]	= "spider"
		AnimalRaceNames[21]	= "goat"
		AnimalRaceNames[22]	= "goat"
		AnimalRaceNames[23]	= "rabbit"
		AnimalRaceNames[24]	= "horker"
		AnimalRaceNames[25]	= "mudcrab"
		AnimalRaceNames[26]	= "sabre cat"
		AnimalRaceNames[27]	= "sabre cat"
		AnimalRaceNames[28]	= "skeever"
		AnimalRaceNames[29]	= "skeever"
		AnimalRaceNames[30]	= "stag"
		AnimalRaceNames[31]	= "troll"
		AnimalRaceNames[32]	= "troll"
		AnimalRaceNames[33]	= "troll"
		AnimalRaceNames[34]	= "troll"
		AnimalRaceNames[35]	= "fox"
		AnimalRaceNames[36]	= "wolf"
		AnimalRaceNames[37]	= "mammoth"
		AnimalRaceNames[38]	= "ash hopper"
		AnimalRaceNames[39]	= "horse"
		AnimalRaceNames[40]	= "spider"
		AnimalRaceNames[41]	= "spider"
		Return AnimalRaceNames[r]
	EndIf
EndFunction


; -- DebugMode
;
Function DebugMode(string sMsg)
	If dsGlobals.gDebugMode
		Debug.Trace("HUNTERBORN DEBUG :: " + sMsg)
	EndIf
EndFunction
