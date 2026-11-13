#include-once
; Item quality checks ported from Logic ItemChecker.au3 onto GwAu3 Item_* getters.
Func IsPerfectShield($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	; Universal mods
    Local $Plus30 = StringInStr($ModStruct, "1E4823", 0, 1) ; Mod struct for +30 (shield only?)
	Local $Minus3Hex = StringInStr($ModStruct, "3009820", 0, 1) ; Mod struct for -3wHex (shield only?)
	Local $Minus2Stance = StringInStr($ModStruct, "200A820", 0, 1) ; Mod Struct for -2Stance
	Local $Minus2Ench = StringInStr($ModStruct, "2008820", 0, 1) ; Mod struct for -2Ench
	Local $Plus45Stance = StringInStr($ModStruct, "02D8823", 0, 1) ; For +45Stance
	Local $Plus45Ench = StringInStr($ModStruct, "02D6823", 0, 1) ; Mod struct for +45ench
	Local $Plus44Ench = StringInStr($ModStruct, "02C6823", 0, 1) ; For +44/+10Demons
	Local $Minus520 = StringInStr($ModStruct, "5147820", 0, 1) ; For -5(20%)
	; +1 20% Mods ~ Updated 08/10/2018 - FINISHED
	Local $PlusIllusion = StringInStr($ModStruct, "0118240", 0, 1) ; +1 Illu 20%
	Local $PlusDomination = StringInStr($ModStruct, "0218240", 0, 1) ; +1 Dom 20%
	Local $PlusInspiration = StringInStr($ModStruct, "0318240", 0, 1) ; +1 Insp 20%
	Local $PlusBlood = StringInStr($ModStruct, "0418240", 0, 1) ; +1 Blood 20%
	Local $PlusDeath = StringInStr($ModStruct, "0518240", 0, 1) ; +1 Death 20%
	Local $PlusSoulReap = StringInStr($ModStruct, "0618240", 0, 1) ; +1 SoulR 20%
	Local $PlusCurses = StringInStr($ModStruct, "0718240", 0, 1) ; +1 Curses 20%
	Local $PlusAir = StringInStr($ModStruct, "0818240", 0, 1) ; +1 Air 20%
	Local $PlusEarth = StringInStr($ModStruct, "0918240", 0, 1) ; +1 Earth 20%
    Local $PlusFire = StringInStr($ModStruct, "0A18240", 0, 1) ; +1 Fire 20%
	Local $PlusWater = StringInStr($ModStruct, "0B18240", 0, 1) ; +1 Water 20%
	Local $PlusHealing = StringInStr($ModStruct, "0D18240", 0, 1) ; +1 Heal 20%
	Local $PlusSmite = StringInStr($ModStruct, "0E18240", 0, 1) ; +1 Smite 20%
	Local $PlusProt = StringInStr($ModStruct, "0F18240", 0, 1) ; +1 Prot 20%
	Local $PlusDivine = StringInStr($ModStruct, "1018240", 0, 1) ; +1 Divine 20%
	; +10vsMonster Mods
	Local $PlusDemons = StringInStr($ModStruct, "A0848210", 0, 1) ; +10vs Demons
	Local $PlusDragons = StringInStr($ModStruct, "A0948210", 0, 1) ; +10vs Dragons
	Local $PlusPlants = StringInStr($ModStruct, "A0348210", 0, 1) ; +10vs Plants
	Local $PlusUndead = StringInStr($ModStruct, "A0048210", 0, 1) ; +10vs Undead
	Local $PlusTengu = StringInStr($ModStruct, "A0748210", 0, 1) ; +10vs Tengu
    ; New +10vsMonster Mods 07/10/2018 - Thanks to Savsuds
    Local $PlusCharr = StringInStr($ModStruct, "0A014821", 0 ,1) ; +10vs Charr
    Local $PlusTrolls = StringInStr($ModStruct, "0A024821", 0 ,1) ; +10vs Trolls
    Local $PlusSkeletons = StringInStr($ModStruct, "0A044821", 0 ,1) ; +10vs Skeletons
    Local $PlusGiants = StringInStr($ModStruct, "0A054821", 0 ,1) ; +10vs Giants
    Local $PlusDwarves = StringInStr($ModStruct, "0A064821", 0 ,1) ; +10vs Dwarves
    Local $PlusDragons = StringInStr($ModStruct, "0A094821", 0 ,1) ; +10vs Dragons
    Local $PlusOgres = StringInStr($ModStruct, "0A0A4821", 0 ,1) ; +10vs Ogres
	; +10vs Dmg
	Local $PlusPiercing = StringInStr($ModStruct, "A0118210", 0, 1) ; +10vs Piercing
	Local $PlusLightning = StringInStr($ModStruct, "A0418210", 0, 1) ; +10vs Lightning
	Local $PlusVsEarth = StringInStr($ModStruct, "A0B18210", 0, 1) ; +10vs Earth
	Local $PlusCold = StringInStr($ModStruct, "A0318210", 0, 1) ; +10 vs Cold
	Local $PlusSlashing = StringInStr($ModStruct, "A0218210", 0, 1) ; +10vs Slashing
	Local $PlusVsFire = StringInStr($ModStruct, "A0518210", 0, 1) ; +10vs Fire
	; New +10vs Dmg 08/10/2018
	Local $PlusBlunt = StringInStr($ModStruct, "A0018210", 0, 1) ; +10vs Blunt

    If $Plus30 > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
	      Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Or $PlusIllusion > 0 Or $PlusInspiration > 0 Or $PlusSoulReap > 0 Or $PlusCurses > 0 Then
		  Return True
	   ElseIf $Minus2Stance > 0 Or $Minus2Ench > 0 Or $Minus520 > 0 Or $Minus3Hex > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndIf
    If $Plus45Ench > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
	      Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   ElseIf $Minus2Ench > 0 Then
		  Return True
	   ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Or $PlusIllusion > 0 Or $PlusInspiration > 0 Or $PlusSoulReap > 0 Or $PlusCurses > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndIf
	If $Minus2Ench > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
		  Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   EndIf
	EndIf
    If $Plus44Ench > 0 Then
	   If $PlusDemons > 0 Then
	      Return True
	   EndIf
	EndIf
    If $Plus45Stance > 0 Then
	   If $Minus2Stance > 0 Then
	      Return True
	   EndIf
	EndIf
	Return False
EndFunc

Func IsPerfectStaff($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $A = Item_GetItemAttribute($aItem)
	;Generic 10% HCT
	Local $10Cast = StringInStr($ModStruct, "A0822", 0, 1) ; Mod struct for 10% HCT
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1) ; Mod struct for 20% fire
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1) ; Mod struct for 20% water
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1) ; Mod struct for 20% air
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1) ; Mod Struct for 20% Earth
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1) ; Mod Struct for 20% Energy Storage (Doesnt drop)
	; Monk mods
	Local $Smite20Casting = StringInStr($ModStruct, "0E141822", 0, 1) ; Mod struct for 20% smite
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1) ; Mod struct for 20% divine
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1) ; Mod struct for 20% healing
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1) ; Mod struct for 20% protection
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1) ; Mod struct for 20% channeling
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1) ; Mod Struct for 20% Restoration
	Local $Communing20Casting = StringInStr($ModStruct, "20141822", 0, 1) ; Mod Struct for 20% Communing
	Local $Spawning20Casting = StringInStr($ModStruct, "24141822", 0, 1) ; Mod Struct for 20% Spawning (Unconfirmed)
	; Mes mods
	Local $Illusion20Casting = StringInStr($ModStruct, "01141822", 0, 1) ; Mod struct for 20% Illusion
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1) ; Mod struct for 20% domination
	Local $Inspiration20Casting = StringInStr($ModStruct, "03141822", 0, 1) ; Mod struct for 20% Inspiration
	; Necro mods
	Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1) ; Mod struct for 20% death
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1) ; Mod Struct for 20% Blood
    Local $SoulReap20Casting = StringInStr($ModStruct, "06141822", 0, 1) ; Mod Struct for 20% Soul Reap (Doesnt drop)
	Local $Curses20Casting = StringInStr($ModStruct, "07141822", 0, 1) ; Mod Struct for 20% Curses

	Switch $A
    Case 1 ; Illusion
	   If $Illusion20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 2 ; Domination
	   If $Domination20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 3 ; Inspiration - Doesnt Drop
	   If $Inspiration20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 4 ; Blood
	   If $Blood20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 5 ; Death
	   If $Death20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 6 ; SoulReap - Doesnt Drop
	   If $SoulReap20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 7 ; Curses
	   If $Curses20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 8 ; Air
	   If $Air20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 9 ; Earth
	   If $Earth20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 10 ; Fire
	   If $Fire20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 11 ; Water
	   If $Water20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 12 ; Energy Storage
	   If $Air20Casting > 0 Or $Earth20Casting > 0 Or $Fire20Casting > 0 Or $Water20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 13 ; Healing
	   If $Healing20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 14 ; Smiting
	   If $Smite20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 15 ; Protection
	   If $Protection20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 16 ; Divine
	   If $Healing20Casting > 0 Or $Protection20Casting > 0 Or $Divine20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 32 ; Communing
	   If $Communing20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 33 ; Restoration
	   If $Restoration20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 34 ; Channeling
	   If $Channeling20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 36 ; Spawning - Unconfirmed
	   If $Spawning20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
	Return False
EndFunc

Func IsPerfectCaster($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $A = Item_GetItemAttribute($aItem)
    ; Universal mods
    Local $PlusFive = StringInStr($ModStruct, "5320823", 0, 1) ; Mod struct for +5^50
	Local $PlusFiveEnch = StringInStr($ModStruct, "500F822", 0, 1)
	Local $10Cast = StringInStr($ModStruct, "A0822", 0, 1) ; Mod struct for 10% cast
	Local $10Recharge = StringInStr($ModStruct, "AA823", 0, 1) ; Mod struct for 10% recharge
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1) ; Mod struct for 20% fire
	Local $Fire20Recharge = StringInStr($ModStruct, "0A149823", 0, 1)
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1) ; Mod struct for 20% water
	Local $Water20Recharge = StringInStr($ModStruct, "0B149823", 0, 1)
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1) ; Mod struct for 20% air
	Local $Air20Recharge = StringInStr($ModStruct, "08149823", 0, 1)
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1)
	Local $Earth20Recharge = StringInStr($ModStruct, "09149823", 0, 1)
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1)
	Local $Energy20Recharge = StringInStr($ModStruct, "0C149823", 0, 1)
	; Monk mods
	Local $Smiting20Casting = StringInStr($ModStruct, "0E141822", 0, 1) ; Mod struct for 20% smite
	Local $Smiting20Recharge = StringInStr($ModStruct, "0E149823", 0, 1)
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1) ; Mod struct for 20% divine
	Local $Divine20Recharge = StringInStr($ModStruct, "10149823", 0, 1)
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1) ; Mod struct for 20% healing
	Local $Healing20Recharge = StringInStr($ModStruct, "0D149823", 0, 1)
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1) ; Mod struct for 20% protection
	Local $Protection20Recharge = StringInStr($ModStruct, "0F149823", 0, 1)
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1) ; Mod struct for 20% channeling
	Local $Channeling20Recharge = StringInStr($ModStruct, "22149823", 0, 1)
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1)
	Local $Restoration20Recharge = StringInStr($ModStruct, "21149823", 0, 1)
    Local $Communing20Casting = StringInStr($ModStruct, "20141822", 0, 1)
	Local $Communing20Recharge = StringInStr($ModStruct, "20149823", 0, 1)
    Local $Spawning20Casting = StringInStr($ModStruct, "24141822", 0, 1) ; Spawning - Unconfirmed
	Local $Spawning20Recharge = StringInStr($ModStruct, "24149823", 0, 1) ; Spawning - Unconfirmed
	; Mes mods
    Local $Illusion20Recharge = StringInStr($ModStruct, "01149823", 0, 1)
	Local $Illusion20Casting = StringInStr($ModStruct, "01141822", 0, 1)
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1) ; Mod struct for 20% domination
    Local $Domination20Recharge = StringInStr($ModStruct, "02149823", 0, 1) ; Mod struct for 20% domination recharge
    Local $Inspiration20Recharge = StringInStr($ModStruct, "03149823", 0, 1)
	Local $Inspiration20Casting = StringInStr($ModStruct, "03141822", 0, 1)
	; Necro mods
    Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1) ; Mod struct for 20% death
	Local $Death20Recharge = StringInStr($ModStruct, "05149823", 0, 1)
    Local $Blood20Recharge = StringInStr($ModStruct, "04149823", 0, 1)
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1)
    Local $SoulReap20Recharge = StringInStr($ModStruct, "06149823", 0, 1)
	Local $SoulReap20Casting = StringInStr($ModStruct, "06141822", 0, 1)
    Local $Curses20Recharge = StringInStr($ModStruct, "07149823", 0, 1)
	Local $Curses20Casting = StringInStr($ModStruct, "07141822", 0, 1)

	Switch $A
    Case 1 ; Illusion
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Illusion20Casting > 0 Or $Illusion20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Illusion20Recharge > 0 Or $Illusion20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Illusion20Recharge > 0 Then
		  If $Illusion20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 2 ; Domination
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Domination20Casting > 0 Or $Domination20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Domination20Recharge > 0 Or $Domination20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Domination20Recharge > 0 Then
		  If $Domination20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 3 ; Inspiration
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Inspiration20Casting > 0 Or $Inspiration20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Inspiration20Recharge > 0 Or $Inspiration20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Inspiration20Recharge > 0 Then
		  If $Inspiration20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 4 ; Blood
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Blood20Casting > 0 Or $Blood20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Blood20Recharge > 0 Or $Blood20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Blood20Recharge > 0 Then
		  If $Blood20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 5 ; Death
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Death20Casting > 0 Or $Death20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Death20Recharge > 0 Or $Death20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Death20Recharge > 0 Then
		  If $Death20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 6 ; SoulReap - Doesnt drop?
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $SoulReap20Casting > 0 Or $SoulReap20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $SoulReap20Recharge > 0 Or $SoulReap20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $SoulReap20Recharge > 0 Then
		  If $SoulReap20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 7 ; Curses
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Curses20Casting > 0 Or $Curses20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Curses20Recharge > 0 Or $Curses20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Curses20Recharge > 0 Then
		  If $Curses20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 8 ; Air
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Air20Recharge > 0 Or $Air20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Air20Recharge > 0 Then
		  If $Air20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 9 ; Earth
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Earth20Casting > 0 Or $Earth20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Earth20Recharge > 0 Or $Earth20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Earth20Recharge > 0 Then
		  If $Earth20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
       Return False
    Case 10 ; Fire
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Fire20Casting > 0 Or $Fire20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Fire20Recharge > 0 Or $Fire20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Fire20Recharge > 0 Then
		  If $Fire20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
       Return False
    Case 11 ; Water
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Water20Casting > 0 Or $Water20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Water20Recharge > 0 Or $Water20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Water20Recharge > 0 Then
		  If $Water20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 12 ; Energy Storage
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Energy20Casting > 0 Or $Energy20Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Energy20Recharge > 0 Or $Energy20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
       EndIf
	   If $Energy20Recharge > 0 Then
		  If $Energy20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $10Cast > 0 Or $10Recharge > 0 Then
		  If $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 13 ; Healing
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Healing20Casting > 0 Or $Healing20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Healing20Recharge > 0 Or $Healing20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Healing20Recharge > 0 Then
		  If $Healing20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 14 ; Smiting
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Smiting20Recharge > 0 Or $Smiting20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Smiting20Recharge > 0 Then
		  If $Smiting20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 15 ; Protection
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Protection20Recharge > 0 Or $Protection20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Protection20Recharge > 0 Then
		  If $Protection20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 16 ; Divine
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Divine20Casting > 0 Or $Divine20Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Divine20Recharge > 0 Or $Divine20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Divine20Recharge > 0 Then
		  If $Divine20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $10Cast > 0 Or $10Recharge > 0 Then
		  If $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 32 ; Communing
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Communing20Casting > 0 Or $Communing20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Communing20Recharge > 0 Or $Communing20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Communing20Recharge > 0 Then
		  If $Communing20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
	Case 33 ; Restoration
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Restoration20Casting > 0 Or $Restoration20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Restoration20Recharge > 0 Or $Restoration20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Restoration20Recharge > 0 Then
		  If $Restoration20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 34 ; Channeling
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Channeling20Casting > 0 Or $Channeling20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Channeling20Recharge > 0 Or $Channeling20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Channeling20Recharge > 0 Then
		  If $Channeling20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 36 ; Spawning - Unconfirmed
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Spawning20Casting > 0 Or $Spawning20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Spawning20Recharge > 0 Or $Spawning20Casting > 0 Then
		  If $10Cast > 0 Or $10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Spawning20Recharge > 0 Then
		  If $Spawning20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    EndSwitch
    Return False
EndFunc

Func IsRareRune($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1) ; Mod struct for Sup vigor rune
	Local $WindWalker = StringInStr($ModStruct, "040430A5060518A7", 0, 1) ; Windwalker insig
	Local $MinorMyst = StringInStr($ModStruct, "05033025012CE821", 0, 1) ; Minor Mysticism
	; Not Worth Anything - Local $SupEarthPrayers = StringInStr($ModStruct, "32BE82109033025", 0, 1) ; Sup earth prayers
	Local $Prodigy = StringInStr($ModStruct, "C60330A5000528A7", 0, 1) ; Prodigy insig
	Local $SupDom = StringInStr($ModStruct, "30250302E821770", 0, 1) ; Superior Domination
	Local $Shamans = StringInStr($ModStruct, "080430A50005F8A", 0, 1) ; Shamans insig
	Local $MinorSpawning = StringInStr($ModStruct, "0124E821", 0, 1) ; Minor Spawning
	Local $MinorEnergyStorage = StringInStr($ModStruct, "010CE821", 0, 1) ; Minor Energy Storage
	Local $MinorFastCasting = StringInStr($ModStruct, "0100E821", 0, 1) ; Minor Fast Casting
	Local $MinorIllusion = StringInStr($ModStruct, "0101E821", 0, 1) ; Minor Illusion
	Local $MinorSoulReap = StringInStr($ModStruct, "0106E821", 0, 1) ; Minor SoulReaping

	If $SupVigor > 0 Or $WindWalker > 0 Or $MinorMyst > 0 Or $Shamans > 0 Or $MinorSpawning > 0 Or $MinorEnergyStorage > 0 Or $MinorFastCasting > 0 Or $MinorIllusion > 0 Or $MinorSoulReap > 0 Or $SupDom > 0 Or $Prodigy > 0 Then
	   Return True
	Else
	   Return False
	EndIf
EndFunc

Func GetItemMaxReq8($aItem)
	Local $Type = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ItemType")
	Local $Dmg = Item_GetItemMaxDmg($aItem)
	Local $Req = Item_GetItemReq($aItem)

	Switch $Type
    Case 12 ;~ Offhand
	   If $Dmg == 12 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 24 ;~ Shield
	   If $Dmg == 16 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 27 ;~ Sword
	   If $Dmg == 22 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
EndFunc

Func GetItemMaxReq7($aItem)
	Local $Type = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ItemType")
	Local $Dmg = Item_GetItemMaxDmg($aItem)
	Local $Req = Item_GetItemReq($aItem)

	Switch $Type
    Case 12 ;~ Offhand
	   If $Dmg == 11 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 24 ;~ Shield
	   If $Dmg == 15 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 27 ;~ Sword
	   If $Dmg == 21 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
EndFunc

Func IsReq8Max($aItem)
	Local $Type = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ItemType")
	Local $Rarity = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "Rarity")
	Local $MaxDmgOffHand = GetItemMaxReq8($aItem)
	Local $MaxDmgShield = GetItemMaxReq8($aItem)
	Local $MaxDmgSword = GetItemMaxReq8($aItem)

	Switch $Rarity
    Case 2624 ;~ Gold
       Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2623 ;~ Purple?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2626 ;~ Blue?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
	EndSwitch
	Return False
EndFunc

Func IsReq7Max($aItem)
	Local $Type = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ItemType")
	Local $Rarity = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "Rarity")
	Local $MaxDmgOffHand = GetItemMaxReq7($aItem)
	Local $MaxDmgShield = GetItemMaxReq7($aItem)
	Local $MaxDmgSword = GetItemMaxReq7($aItem)

	Switch $Rarity
    Case 2624 ;~ Gold
       Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2623 ;~ Purple?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2626 ;~ Blue?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
	EndSwitch
	Return False
EndFunc

Func IsEliteTome($aItem)
	Local $ModelID = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ModelID")

	Switch $ModelID
    Case 21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795
	   Return True ; All Elite Tomes
	EndSwitch
	Return False
EndFunc

Func IsRegularTome($aItem)
	Local $ModelID = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ModelID")

	Switch $ModelID
    Case 21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805
	   Return True
	EndSwitch
	Return False
EndFunc

Func IsPcon($aItem)
	Local $ModelID = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ModelID")

	Switch $ModelID
    Case 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 30855, 31145, 31146, 35124, 36682 ;;28435 hard apple cider, 910 = hunters ales
	   Return True ; Alcohol
    Case 6376, 36683 ;;21809. = bottle rocket, champagne poppers = 21810, 21813 = sparkler
	   Return True ; Party
    Case 21492, 21812, 22269, 22644, 22752, 28436
	   Return True ; Sweets
    Case 6370, 21488, 21489, 22191, 26784, 28433
	   Return True ; DP Removal
    Case 15837, 21490, 30648, 31020
	   Return True ; Tonic
    EndSwitch
	Return False
EndFunc

Func IsSpecialItem($aItem)
	Local $ModelID = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ModelID")
	Local $ExtraID = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ExtraID")

	Switch $ModelID ; ovde je Magnas shield
    Case 5656, 18345, 21491, 37765, 21833, 28433, 28434, 5899, 344
	   Return True ; Special - ToT etc
    Case 22751
	   Return True ; Lockpicks
    Case 27047
	   Return True ; Glacial Stones
    Case 146
	   If $ExtraID = 10 Or $ExtraID = 12 Then
		  Return True ; Black & White Dye
	   Else
		  Return False
	   EndIf
    Case 24353, 24354
	   Return True ; Chalice & Rin Relics
    Case 27052
	   Return True ; Superb Charr Carving
    Case 522
	   Return True ; Dark Remains
    Case 3746, 22280
	   Return True ; Underworld & FOW Scroll
    Case 819
	   Return True ; Dragon Root
    Case 35121
	   Return True ; War supplies
    Case 36985
	   Return True ; Commendations
    EndSwitch
	Return False
EndFunc

Func IsRareMaterial($aItem)
   Local $M = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ModelID")

   Switch $M
   Case 937, 938, 935, 931, 932, 936, 930
	  Return True ; Rare Mats
   EndSwitch
   Return False
EndFunc