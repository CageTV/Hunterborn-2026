;Hunterborn 2026: the natives of HunterbornNative.dll.
Scriptname HunterbornNative Hidden

; The loot lists of other mods' creatures that the DLL found to be one of Hunterborn's types (see SKSE\HunterbornNative_AutoPatch.txt).
; abMonster/aiIndex are the position in Hunterborn's own lists (_DS_FL_DeathItems / _DS_FL_DeathItems_Monsters). None when there are none.
LeveledItem[] Function GetLists(bool abMonster, int aiIndex) global native

; The loot list each of those stands in for, in the same order: the stand-in is empty until a script puts the original (and Hunterborn's tokens) into it.
LeveledItem[] Function GetOriginals(bool abMonster, int aiIndex) global native
