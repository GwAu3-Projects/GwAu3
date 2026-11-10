Opt("GUIOnEventMode", True)

Global Const $MOD_INI_PATH 		= @ScriptDir & "\Mod_Settings.ini"
Global $defaultSeparator = Opt("GUIDataSeparatorChar", "|") ; used for arraay to ini and ini to array functions
Global $defaultSeparatorString = "<%Separator%>" 			; used for arraay to ini and ini to array functions


;~ 				Autor logicdoor
;~
;~				 $array_mods_[x][0] = Name
;~				 $array_mods_[x][1] = Modstring 1
;~ 				 $array_mods_[x][2] = Modstring 2

;~			     $array_mods_[x][3-13] = Staff (26), Wand (22), Offhand (12),  Shield (24), Axe (2), Bow (5), Hammer (15), Daggers (32), Scythe (35), Spear (36), Sword (27)
; 										stores for which weapon types the mod should be salvaged

Global $ColLabels[12] = ["Staff", "Wand",  "Focus", "Shield", "Axe", "Bow", "Hammer", "Daggers", "Scythe", "Spear", "Sword", "Runes & Insignas"]
Global $array_weaponmods_ini [133][15]
Global $array_weaponmods [133][15] = [ _
		 [ "HCT20 [Inscription]",  							2, "22500140828","" ,		 1,  1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "HCT20 [Staff head]", 							0, "02500140828","" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _ 	; 004302500140828 (adept staff head)
		 [ "HCT20 [Focus Core]",			 				1, "02500140828","" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _ 	; F04302500140828 (focus core)
		 [ "HCT10 [Inscription]",							2, "000A0822",   "" ,		 0,  0,  0, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "HCT10 [Staff Head]",							0, "000A0822",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "HSR20 [Inscription]",							2, "00142828",   "" ,		-1, -1,  1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "HSR20 [Wand Wrapping]",							1, "00142828",   "" ,		-1,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "HSR10 [Inscription]",							2, "000AA823",   "" ,		-1, -1,  0, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "HSR10 [Wand Wrapping]",							1, "000AA823",   "" ,		-1,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+1 Attr. (Chance 20%) [Inscription]",			2, "00143828",   "" ,	  	-1, -1,  1,  1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+1 Attr. (Chance 20%) [Staff Wrapping]",		1, "00143828",   "" ,	  	 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Highly salvageable",							2, "1E000826",   "" ,	  	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Improved sale value",							2, "3200F805",   "" ,	  	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Energy +5 [Inscription]" ,						2, "0500D822",   "" ,	  	-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Energy +5 [Staff Head]" ,						0, "0500D822",   "" ,	  	 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Energy +5 (HP>50%)",							2, "05320823",   "" ,	  	 0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Energy +5 (while Enchanted)",					2, "0500F822",   "" ,	  	 0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Energy +7 (HP<50%)",							2, "07321823",   "" ,	  	 0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Energy +7 (while hexed)",						2, "07002823",   "" ,	  	 0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Energy +15 (-1 energy regen)",					2, "0F00D822",   "0100C820", 0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Damage -2 (while Enchanted)",					2, "02008820",   "" ,  		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Damage -2 (while in a Stance)",					2, "0200A820",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Damage -3 (while Hexed)",						2, "03009820",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Damage -5 (Chance: 20%)",						2, "05147820",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Bleeding", 								2, "00005828",	 "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Blind",									2, "00015828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Crippled",									2, "00035828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Dazed",									2, "00075828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Deep Wound",								2, "00045828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Disease (Inscribable)",					2, "00055828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Disease", 									2, "E3017824",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Poison",									2, "00065828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "-20% Weakness",									2, "00085828",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Damage +15% (-1 energy regen)",					2, "0F003822",   "0100C820",-1, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _ ; cannot be salvaged
		 [ "Damage +15% (-1 HP regen)",						2, "0F003822",   "0100E820",-1, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _ ; cannot be salvaged
		 [ "Damage +15% (HP> 50%)",							2, "0F327822",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage +15% (while Enchanted)",					2, "0F006822",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage +15% (while in a Stance)",				2, "0F00A822",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage +15% (vs Hexed Foes)",					2, "0F005822",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage +15% (-10 AL while attacking)",			2, "0A001820",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage +15% (Energy -5)",						2, "0500B820",   "" , 		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage 20% (HP<50%)",							2, "14328822",   "" ,		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Damage 20% (while Hexed)",						2, "14009822",   "" ,		 0,  0, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Ebon",											0, "000BB824",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Fiery",											0, "0005B824",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Icy",											0, "0003B824",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Shocking",										0, "0004B824",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Barbed",										0, "DE016824",   "" ,		-1, -1, -1, -1,  0,  0, -1,  0,  0,  0,  0], _
		 [ "Crippling",										0, "E1016824",   "" ,		-1, -1, -1, -1,  0,  0, -1,  0,  0,  0,  0], _
		 [ "Cruel",											0, "E2016824",   "" ,		-1, -1, -1, -1,  0, -1,  0,  0,  0,  0,  0], _
		 [ "Furious",										0, "0A00B823",   "" ,		-1, -1, -1, -1,  0, -1,  0,  0,  0,  0,  0], _
		 [ "Heavy",											0, "E601824",    "" ,		-1, -1, -1, -1,  0, -1,  0, -1,  0,  0, -1], _
		 [ "Poisonous",										0, "E4016824",   "" ,		-1, -1, -1, -1,  0,  0, -1,  0,  0,  0,  0], _
		 [ "Silencing",										0, "E5016824",   "" ,		-1, -1, -1, -1, -1,  0,  0,  0, -1,  0, -1], _
		 [ "Sundering",										0, "1414F823",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Vampiric (+3)",									0, "00032825",   "" ,		-1, -1, -1, -1,  0, -1, -1,  0, -1,  0,  0], _
		 [ "Vampiric (+5)",									0, "00052825",   "" ,		-1, -1, -1, -1, -1,  0,  0, -1,  0, -1, -1], _
		 [ "Zealous",										0, "01001825",   "" ,		-1, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "+ 20% (vs Charr)",								1, "00018080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Demons)",								1, "00088080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Dragons",								1, "00098080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Dwarves)",							1, "00068080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Giants)",								1, "00058080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Ogres)",								1, "000A8080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Plants)",								1, "00038080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Skeletons)",							1, "00048080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Tengu)",								1, "00078080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Trolls)",								1, "00028080",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _
		 [ "+ 20% (vs Undead)",								1, "001448A2",   "" ,		 0, -1, -1, -1,  0,  0,  0, -1, -1, -1,  0], _		; use 00008080 for +19%/+20%
		 [ "+30 HP",										1, "001E4823",   "" ,		-1, -1,  0,  1,  0,  0,  0,  0,  0,  0,  0], _  	; weapons and shields
		 [ "+30 HP (staff wrapping)",						1, "9013025001E4823", "" ,	 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _  	; DC000824B9013025001E4823 (staff wrapping)
		 [ "+30 HP (staff head)",							0, "A013025001E4823", "" , 	 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _  	; 9D0008243A013025001E4823 (hale staff head)
		 [ "+45 HP while Enchanted",						1, "002D6823",   "" ,		 0, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+45 HP while in a Stance",						1, "002D8823",   "" ,		 0, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+60 HP while Hexed",							1, "003C7823",   "" ,	 	 0, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+20% Enchantment Duration",						1, "1400B822",   "" , 		 0, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Axe Mastery +1 (20% chance)",					1, "14121824",   "" ,		-1, -1, -1, -1,  0, -1, -1, -1, -1, -1, -1], _
		 [ "Marksmanship +1 (20% chance)",					1, "14191824",   "" ,		-1, -1, -1, -1, -1,  0, -1, -1, -1, -1, -1], _
		 [ "Hammer Mastery +1 (20% chance)",				1, "14131824",   "" , 		-1, -1, -1, -1, -1, -1,  0, -1, -1, -1, -1], _
		 [ "Dagger Mastery +1 (20% chance)",				1, "141D1824",   "" ,		-1, -1, -1, -1, -1, -1, -1,  0, -1, -1, -1], _
		 [ "Scythe Mastery +1 (20% chance)",				1, "14291824",   "" ,		-1, -1, -1, -1, -1, -1, -1, -1,  0, -1, -1], _
		 [ "Spear Mastery +1 (20% chance)",					1, "14251824",   "" ,		-1, -1, -1, -1, -1, -1, -1, -1, -1,  0, -1], _
		 [ "Swordmanship +1 (20% chance)",					1, "14141824",   "" ,		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  0], _
		 [ "Air Magic +1 (20% chance)",						1, "14081824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Blood Magic +1 (20% chance)",					1, "14041824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Channeling Magic +1 (20% chance)",				1, "14221824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Communing Magic +1 (20% chance)",				1, "14201824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Curse Magic +1 (20% chance)",					1, "14071824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Death Magic +1 (20% chance)",					1, "14051824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Divine Favor  +1 (20% chance)",					1, "14101824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Domination Magic +1 (20% chance)",				1, "14021824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Earth Magic +1 (20% chance)",					1, "14091824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Fire Magic +1 (20% chance)",					1, "140A1824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Healing Prayers +1 (20% chance)",				1, "140D1824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Illusion Magic +1 (20% chance)",				1, "14011824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Inspiration  +1 (20% chance)",					1, "14031824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Protection Prayers +1 (20% chance)",			1, "140F1824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Restoration Magic +1 (20% chance)",				1, "14211824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Smiting Prayers +1 (20% chance)",				1, "140E1824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Soul Reaping +1 (20% chance)",					1, "14061824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Spawning Magic +1 (20% chance)",				1, "14241824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Water Magic +1 (20% chance)",					1, "140B1824",   "" ,		 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+7 armor vs Physical",							1, "07005821",   "" ,		 0, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "+7 Armor vs Elemental",							1, "07002821",   "" ,		 0, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Armor +5",										1, "05000821",   "" ,		 0, -1, -1, -1,  0,  0,  0,  0,  0,  0,  0], _
		 [ "Armor +5 (HP> 50%)",							2, "0532A821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (HP< 50%)",							2, "0A32B821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (while Enchanted)",					2, "05009821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (while attacking)",					2, "05007821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (while casting)",						2, "05008821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (vs Elemental)",						2, "05002821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (vs Physical)",						2, "05005821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (Energy -5)",							2, "0500B820",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +5 (Health -20)",							2, "1400D820",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (while Hexed)",						2, "0A00C821",   "" ,		-1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1], _
		 [ "+10 Armor vs.Undead",							2, "0A004821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Charr",							2, "0A014821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Trolls",							2, "0A024821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Plants",							2, "0A034821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Skeletons",						2, "0A044821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Giants",							2, "0A054821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Dwarves",							2, "0A064821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Tengu",							2, "0A074821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Demons",							2, "0A084821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Dragons",							2, "0A094821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "+10 Armor vs.Ogres",							2, "0A0A4821",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _ ; cannot be salavaged
		 [ "Armor +10 (vs Blunt)",							2, "0A0018A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Cold)",							2, "0A0318A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Earth)",							2, "0A0B18A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Fire)",							2, "0A0518A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Lightning)",						2, "0A0418A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Piercing)",						2, "0A0118A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1], _
		 [ "Armor +10 (vs Slashing)",						2, "0A0218A1",   "" ,		-1, -1,  0,  0, -1, -1, -1, -1, -1, -1, -1]]

		; Name, 									ModelID,Index, Modstruct, Salvage indicator
	Global $array_armormods [183][5] = [ _
		 ["Minor Critical Strikes [Assassin]", 		6324,	1, "0123E821", 1], _
		 ["Minor Dagger Mastery [Assassin]",		6324,	1, "011DE821", 0], _
		 ["Minor Deadly Arts [Assassin]", 			6324,	1, "011EE821", 0], _
		 ["Minor Shadow Arts [Assassin]", 			6324,	1, "011FE821", 0], _
		 ["Major Critical Strikes [Assassin]", 		6325,	1, "0223E8217902", 0], _
		 ["Major Dagger Mastery [Assassin]", 		6325,	1, "021DE8217902", 0], _
		 ["Major Deadly Arts [Assassin]", 			6325,	1, "021EE8217902", 0], _
		 ["Major Shadow Arts [Assassin]", 			6325,	1, "021FE8217902", 0], _
		 ["Superior Critical Strikes [Assassin]", 	6326,	1, "0323E8217B02", 0], _
		 ["Superior Dagger Mastery [Assassin]", 	6326,	1, "031DE8217B02", 0], _
		 ["Superior Deadly Arts [Assassin]", 		6326,	1, "031EE8217B02", 0], _
		 ["Superior Shadow Arts [Assassin]", 		6326,	1, "031FE8217B02", 0], _
		 ["Vanguard's Insignia [Assassin]", 		19124,	1, "DE010824", 0], _
		 ["Infiltrator's Insignia [Assassin]", 		19125,	0, "DF010824", 0], _
		 ["Saboteur's Insignia [Assassin]", 		19126,	0, "E0010824", 0], _
		 ["Nightstalker's Insignia [Assassin]", 	19127,	0, "E1010824", 0], _
		 ["Minor Earth Prayers[Dervish]", 			15545,	1, "012BE821", 1], _
		 ["Minor Mysticism[Dervish]", 				15545,	1, "012CE821", 0], _
		 ["Minor Scythe Mastery[Dervish]", 			15545,	1, "0129E821", 0], _
		 ["Minor Wind Prayers[Dervish]", 			15545,	1, "012AE821", 0], _
		 ["Major Earth Prayers[Dervish]", 			15546,	1, "022BE8210703", 0], _
		 ["Major Mysticism[Dervish]", 				15546,	1, "022CE8210703", 0], _
		 ["Major Scythe Mastery[Dervish]", 			15546,	1, "0229E8210703", 0], _
		 ["Major Wind Prayers[Dervish]", 			15546,	1, "022AE8210703", 0], _
		 ["Superior Earth Prayers[Dervish]", 		15547,	1, "032BE8210903", 0], _
		 ["Superior Mysticism[Dervish]", 			15547,	1, "032CE8210903", 0], _
		 ["Superior Scythe Mastery[Dervish]", 		15547,	1, "0329E8210903", 0], _
		 ["Superior Wind Prayers[Dervish]", 		15547,	1, "032AE8210903", 0], _
		 ["Windwalker Insignia [Dervish]", 			19163,	0, "02020824", 1], _
		 ["Forsaken Insignia [Dervish]", 			19164,	0, "03020824", 0], _
		 ["Minor Air Magic [Elementalist]", 		901,	1, "0108E821", 0], _
		 ["Minor Earth Magic [Elementalist]", 		901,	1, "0109E821", 0], _
		 ["Minor Energy Storage [Elementalist]", 	901,	1, "010CE821", 0], _
		 ["Minor Water Magic [Elementalist]", 		901,	1, "010BE821", 0], _
		 ["Minor Fire Magic [Elementalist]", 		901,	1, "010AE821", 0], _
		 ["Major Air Magic [Elementalist]", 		5554,	1, "0208E8216F01", 0], _
		 ["Major Earth Magic [Elementalist]", 		5554,	1, "0209E8216F01", 0], _
		 ["Major Energy Storage [Elementalist]", 	5554,	1, "020CE8216F01", 0], _
		 ["Major Fire Magic [Elementalist]", 		5554,	1, "020AE8216F01", 0], _
		 ["Major Water Magic [Elementalist]", 		5554,	1, "020BE8216F01", 0], _
		 ["Superior Air Magic [Elementalist]", 		5555,	1, "0308E8217B01", 1], _
		 ["Superior Earth Magic [Elementalist]", 	5555,	1, "0309E8217B01", 0], _
		 ["Superior Energy Storage [Elementalist]", 5555,	1, "030CE8217B01", 0], _
		 ["Superior Fire Magic [Elementalist]", 	5555,	1, "030AE8217B01", 1], _
		 ["Superior Water Magic [Elementalist]", 	5555,	1, "030BE8217B01", 0], _
		 ["Prismatic Insignia [Elementalist]", 		19144,	0, "F1010824", 0], _
		 ["Hydromancer Insignia [Elementalist]", 	19145,	0, "F2010824", 0], _
		 ["Geomancer Insignia [Elementalist]", 		19146,	0, "F3010824", 0], _
		 ["Pyromancer Insignia [Elementalist]", 	19147,	0, "F4010824", 0], _
		 ["Aeromancer Insignia [Elementalist]", 	19148,	0, "F5010824", 0], _
		 ["Rune of Attunement", 					898,	1, "0200D822", 0], _
		 ["Rune of Minor Vigor", 					898,	1, "C202E827", 1], _
		 ["Rune of Vitae", 							898,	1, "000A4823", 0], _
		 ["Rune of Clarity", 						5550,	1, "01087827", 1], _
		 ["Rune of Major Vigor", 					5550,	1, "C202E927", 1], _
		 ["Rune of Purity", 						5550,	1, "05067827", 0], _
		 ["Rune of Recovery", 						5550,	1, "07047827", 0], _
		 ["Rune of Restoration", 					5550,	1, "00037827", 0], _
		 ["Rune of Superior Vigor", 				5551,	1, "C202EA27", 1], _
		 ["Radiant Insignia",		 				19131,	0, "E5010824", 0], _
		 ["Survivor Insignia", 						19132,	0, "E6010824", 0], _
		 ["Stalwart Insignia", 						19133,	0, "E7010824", 0], _
		 ["Brawler's Insignia", 					19134,	0, "E8010824", 0], _
		 ["Blessed Insignia", 						19135,	0, "E9010824", 1], _
		 ["Herald's Insignia", 						19136,	0, "EA010824", 0], _
		 ["Sentry's Insignia", 						19137,	0, "EB010824", 0], _
		 ["Minor Domination Magic [Mesmer]", 		899,	1, "0102E821", 0], _
		 ["Minor Fast Casting [Mesmer]", 			899,	1, "0100E821", 0], _
		 ["Minor Illusion Magic [Mesmer]", 			899,	1, "0101E821", 0], _
		 ["Minor Inspiration Magic [Mesmer]", 		899,	1, "0103E821", 1], _
		 ["Major Domination Magic [Mesmer]", 		3612,	1, "0202E8216B01", 0], _
		 ["Major Fast Casting [Mesmer]", 			3612,	1, "0200E8216B01", 0], _
		 ["Major Illusion Magic [Mesmer]", 			3612,	1, "0201E8216B01", 0], _
		 ["Major Inspiration Magic [Mesmer]", 		3612,	1, "0203E8216B01", 0], _
		 ["Superior Domination Magic [Mesmer]", 	5549,	1, "0302E8217701", 1], _
		 ["Superior Fast Casting [Mesmer]", 		5549,	1, "0300E8217701", 0], _
		 ["Superior Illusion Magic [Mesmer]", 		5549,	1, "0301E8217701", 0], _
		 ["Superior Inspiration Magic [Mesmer]", 	5549,	1, "0303E8217701", 0], _
		 ["Artificer's Insignia [Mesmer]", 			19128,	0, "E2010824", 0], _
		 ["Prodigy's Insignia [Mesmer]", 			19129,	0, "E3010824", 1], _
		 ["Virtuoso's Insignia [Mesmer]", 			19130,	0, "E4010824", 0], _
		 ["Minor Divine Favor [Monk]", 				902,	1, "0110E821", 0], _
		 ["Minor Healing Prayers [Monk]", 			902,	1, "010DE821", 0], _
		 ["Minor Protection Prayers [Monk]", 		902,	1, "010FE821", 1], _
		 ["Minor Smiting Prayers [Monk]", 			902,	1, "010EE821", 0], _
		 ["Major Healing Prayers [Monk]", 			5556,	1, "020DE8217101", 0], _
		 ["Major Protection Prayers [Monk]", 		5556,	1, "020FE8217101", 0], _
		 ["Major Smiting Prayers [Monk]", 			5556,	1, "020EE8217101", 0], _
		 ["Major Divine Favor [Monk]", 				5556,	1, "0210E8217101", 0], _
		 ["Superior Divine Favor [Monk]", 			5557,	1, "0310E8217D01", 0], _
		 ["Superior Healing Prayers [Monk]", 		5557,	1, "030DE8217D01", 0], _
		 ["Superior Protection Prayers [Monk]", 	5557,	1, "030FE8217D01", 0], _
		 ["Superior Smiting Prayers [Monk]",		5557,	1, "030EE8217D01", 0], _
		 ["Wanderer's Insignia [Monk]", 			19149,	0, "F6010824", 0], _
		 ["Disciple's Insignia [Monk]", 			19150,	0, "F7010824", 0], _
		 ["Anchorite's Insignia [Monk]", 			19151,	0, "F8010824", 0], _
		 ["Minor Blood Magic [Necromancer]",		900,	1, "0104E821", 0], _
		 ["Minor Curses [Necromancer]", 			900,	1, "0107E821", 0], _
		 ["Minor Death Magic [Necromancer]", 		900,	1, "0105E821", 0], _
		 ["Minor Soul Reaping [Necromancer]", 		900,	1, "0106E821", 0], _
		 ["Major Blood Magic [Necromancer]",		5552,	1, "0204E8216D01", 0], _
		 ["Major Curses [Necromancer]",				5552,	1, "0207E8216D01", 0], _
		 ["Major Death Magic [Necromancer]",		5552,	1, "0205E8216D01", 0], _
		 ["Major Soul Reaping [Necromancer]", 		5552,	1, "0206E8216D01", 1], _
		 ["Superior Blood Magic [Necromancer]", 	5553,	1, "0304E8217901", 0], _
		 ["Superior Curses [Necromancer]",			5553,	1, "0307E8217901", 0], _
		 ["Superior Death Magic [Necromancer]",		5553,	1, "0305E8217901", 1], _
		 ["Superior Soul Reaping [Necromancer",		5553,	1, "0306E8217901", 0], _
		 ["Bloodstained Insignia [Necromancer]",	19138,	0, "0A020824", 0], _
		 ["Tormentor's Insignia [Necromancer]",		19139,	0, "EC010824", 1], _
		 ["Undertaker's Insignia [Necromancer]",	19140,	0, "ED010824", 0], _
		 ["Bonelace Insignia [Necromancer]",		19141,	0, "EE010824", 0], _
		 ["Minion Master's Insignia [Necromancer]",	19142,	0, "EF010824", 0], _
		 ["Blighter's Insignia [Necromancer]",		19143,	1, "F0010824", 0], _
		 ["Minor Command [Paragon]",				15548,	1, "0126E821", 0], _
		 ["Minor Leadership [Paragon]",				15548,	1, "0128E821", 0], _
		 ["Minor Motivation [Paragon]",				15548,	1, "0127E821", 0], _
		 ["Minor Spear Mastery [Paragon]",			15548,	1, "0125E821", 1], _
		 ["Major Command [Paragon]",				15549,	1, "0226E8210D03", 0], _
		 ["Major Leadership [Paragon]",				15549,	1, "0228E8210D03", 0], _
		 ["Major Motivation [Paragon]",				15549,	1, "0227E8210D03", 0], _
		 ["Major Spear Mastery [Paragon]",			15549,	1, "0225E8210D03", 0], _
		 ["Superior Command [Paragon]",				15550,	1, "0326E8210F03", 0], _
		 ["Superior Leadership [Paragon]",			15550,	1, "0328E8210F03", 0], _
		 ["Superior Motivation [Paragon]",			15550,	1, "0327E8210F03", 0], _
		 ["Superior Spear Mastery [Paragon]",		15550,	1, "0325E8210F03", 0], _
		 ["Centurion's Insignia [Paragon]",			19168,	0, "07020824", 1], _
		 ["Minor Beast Mastery [Ranger]",			904,	1, "0116E821", 0], _
		 ["Minor Expertise [Ranger]",				904,	1, "0117E821", 0], _
		 ["Minor Marksmanship [Ranger]",			904,	1, "0119E821", 0], _
		 ["Minor Wilderness Survival [Ranger]",		904,	1, "0118E821", 0], _
		 ["Major Beast Mastery [Ranger]",			5560,	1, "0216E8217501", 0], _
		 ["Major Expertise [Ranger]",				5560,	1, "0217E8217501", 0], _
		 ["Major Marksmanship [Ranger]",			5560,	1, "0219E8217501", 0], _
		 ["Major Wilderness Survival [Ranger]",		5560,	1, "0218E8217501", 0], _
		 ["Superior Beast Mastery [Ranger]",		5561,	1, "0316E8218101", 0], _
		 ["Superior Expertise [Ranger]",			5561,	1, "0317E8218101", 0], _
		 ["Superior Marksmanship [Ranger]",			5561,	1, "0319E8218101", 0], _
		 ["Superior Wilderness Survival [Ranger]",	5561,	1, "0318E8218101", 0], _
		 ["Frostbound Insignia [Ranger]",			19157,	0, "FC010824", 0], _
		 ["Earthbound Insignia [Ranger]",			19158,	0, "FD010824", 0], _
		 ["Pyrebound Insignia [Ranger]",			19159,	0, "FE010824", 0], _
		 ["Stormbound Insignia [Ranger]",			19160,	0, "FF010824", 0], _
		 ["Beastmaster's Insignia [Ranger]",		19161,	0, "00020824", 0], _
		 ["Scout's Insignia [Ranger]",				19162,	0, "01020824", 0], _
		 ["Minor Channeling Magic [Ritualist]",		6327,	1, "0122E821", 0], _
		 ["Minor Communing [Ritualist]",			6327,	1, "0120E821", 0], _
		 ["Minor Restoration Magic [Ritualist]",	6327,	1, "0121E821", 0], _
		 ["Minor Spawning Power [Ritualist]",		6327,	1, "0124E821", 0], _
		 ["Major Channeling Magic [Ritualist]",		6328,	1, "0222E8217F02", 0], _
		 ["Major Communing [Ritualist]",			6328,	1, "0220E8217F02", 0], _
		 ["Major Restoration Magic [Ritualist]",	6328,	1, "0221E8217F02", 0], _
		 ["Major Spawning Power [Ritualist]",		6328,	1, "0224E8217F02", 0], _
		 ["Superior Channeling Magic [Ritualist]",	6329,	1, "0322E8218102", 0], _
		 ["Superior Communing [Ritualist]",			6329,	1, "0320E8218102", 1], _
		 ["Superior Restoration Magic [Ritualist]",	6329,	1, "0321E8218102", 0], _
		 ["Superior Spawning Power [Ritualist]",	6329,	1, "0324E8218102", 0], _
		 ["Shaman's Insignia [Ritualist]",			19165,	0, "04020824", 1], _
		 ["Ghost Forge Insignia [Ritualist]",		19166,	0, "05020824", 0], _
		 ["Mystic's Insignia [Ritualist]",			19167,	0, "06020824", 0], _
		 ["Minor Absorption [Warrior]",				903,	0, "EA02E827", 0], _
		 ["Minor Axe Mastery [Warrior]",			903,	1, "0112E821", 0], _
		 ["Minor Hammer Mastery [Warrior]",			903,	1, "0113E821", 0], _
		 ["Minor Strength [Warrior]",				903,	1, "0111E821", 0], _
		 ["Minor Swordsmanship [Warrior]",			903,	1, "0114E821", 0], _
		 ["Minor Tactics [Warrior]",				903,	1, "0115E821", 0], _
		 ["Major Absorption [Warrior]",				5558,	1, "EA02E927", 0], _
		 ["Major Axe Mastery [Warrior]",			5558,	1, "0212E8217301", 0], _
		 ["Major Hammer Mastery [Warrior]",			5558,	1, "0213E8217301", 0], _
		 ["Major Strength [Warrior]",				5558,	1, "0211E8217301", 0], _
		 ["Major Swordsmanship [Warrior]",			5558,	1, "0214E8217301", 0], _
		 ["Major Tactics [Warrior]",				5558,	1, "0215E8217301", 0], _
		 ["Superior Axe Mastery [Warrior]",			5559,	1, "0312E8217F01", 0], _
		 ["Superior Hammer Mastery [Warrior]",		5559,	1, "0313E8217F01", 0], _
		 ["Superior Strength [Warrior]",			5559,	1, "0311E8217F01", 0], _
		 ["Superior Swordsmanship [Warrior]",		5559,	1, "0314E8217F01", 0], _
		 ["Superior Tactics [Warrior]",				5559,	1, "0315E8217F01", 0], _
		 ["Superior Absorption [Warrior]",			5559,	1, "EA02EA27", 0], _
		 ["Knight's Insignia [Warrior]",			19152,	0, "F9010824", 0], _
		 ["Lieutenant's Insignia [Warrior]",		19153,	0, "08020824", 0], _
		 ["Stonefist Insignia [Warrior]",			19154,	0, "09020824", 0], _
		 ["Dreadnought Insignia [Warrior]",			19155,	0, "FA010824", 0], _
		 ["Sentinel's Insignia [Warrior]",			19156,	0, "FB010824", 1]]

;~ 		 _ArrayDisplay ($array_armormods)

Func ModSelection()
   Global $frmSelection = GUICreate("Mod Selection", 816, 660, 500, 112)
   Global $array_checkboxes[133][15]


   GUICtrlSetFont($frmSelection, 9, -1, 0, "Arial")

   GUICtrlCreateTab(1, 0, 816, 660)
   $X_GUI = 8
   $Y_GUI = 8
   $Width_GUI = 390
   $Height_GUI = 312
   $iSpacing= 8

   If FileExists($MOD_INI_PATH) Then $array_weaponmods_ini = _iniToArray("Mod_Settings.ini", "array_weaponmods")
;  _ArrayDisplay ($Array_weaponmods_ini, "2D Display")


   GUICtrlCreateTabItem("Popular Mods")
		 Global $grpEnergy = GUICtrlCreateGroup("", 0, 14, 816, 660)
		 For $j = 4 to 14
			GUICtrlCreateLabel($ColLabels[$j-4], $X_GUI + 55 +(50 * $j), 40 , $iSpacing*6, $iSpacing*2, $ES_CENTER)
			For $i = 0 To 32
				If $j = 4 then GUICtrlCreateLabel($array_weaponmods[$i][0], $X_GUI + $iSpacing*2, 60 + (18 * $i),200, $iSpacing*2)
				$array_checkboxes[$i][$j] = GUICtrlCreateCheckbox("", $X_GUI + 72+(50 * $j), 60 + (18 * $i), $iSpacing*2, $iSpacing*2, BitOR($BS_AUTOCHECKBOX, $ES_CENTER,($array_checkboxes[$i][$j] > -1 ? $GUI_CHECKED : $GUI_UNCHECKED)))
				If $array_weaponmods[$i][$j] 		= 1 then guictrlsetstate (-1, $GUI_CHECKED)
			    If $array_weaponmods[$i][$j] 		=-1 then guictrlsetstate (-1, $GUI_DISABLE)
			    If $array_weaponmods_ini[$i][$j] 	= 1 then guictrlsetstate (-1, $GUI_CHECKED)
				Next
			 Next
   GUICtrlCreateTabItem("") ; end tabitem definition

   GUICtrlCreateTabItem("Damage")
		 Global $grpEnergy = GUICtrlCreateGroup("", 0, 14, 816, 660)
		 For $j = 4 to 14
			GUICtrlCreateLabel($ColLabels[$j-4], $X_GUI + 55 +(50 * $j),40 , $iSpacing*6, $iSpacing*2, $ES_CENTER)
			For $i = 33 To 68
				If $j = 4 then GUICtrlCreateLabel($array_weaponmods[$i][0], $X_GUI + $iSpacing*2, 60 + (16 * ($i - 33)),200, $iSpacing*2)
				$array_checkboxes[$i][$j] = GUICtrlCreateCheckbox("", $X_GUI + 72+(50 * $j), 60 + (16 * ($i - 33)), $iSpacing*2, $iSpacing*2, BitOR($BS_AUTOCHECKBOX, $ES_CENTER,($array_checkboxes[$i][$j] >-1 ? $GUI_CHECKED : $GUI_UNCHECKED)))
				If $array_weaponmods[$i][$j] = 1 then guictrlsetstate (-1, $GUI_CHECKED)
			    If $array_weaponmods[$i][$j] 		= -1 then guictrlsetstate (-1, $GUI_DISABLE)
			    If $array_weaponmods_ini[$i][$j] 	= 1 then guictrlsetstate (-1, $GUI_CHECKED)
				Next
			 Next

   GUICtrlCreateTabItem("") ; end tabitem definition

   GUICtrlCreateTabItem("HP, Echanting and Attribute")
		 Global $grpEnergy = GUICtrlCreateGroup("", 0, 14, 816, 660)
		 For $j = 4 to 14
			GUICtrlCreateLabel($ColLabels[$j-4], $X_GUI + 55 +(50 * $j), 40 , $iSpacing*6, $iSpacing*2, $ES_CENTER)
			For $i = 69 To 101
				If $j = 4 then GUICtrlCreateLabel($array_weaponmods[$i][0], $X_GUI+$iSpacing*2, 60 + (18 * ($i - 69)),200, $iSpacing*2)
				$array_checkboxes[$i][$j] = GUICtrlCreateCheckbox("", $X_GUI + 72+(50 * $j), 60 + (18 * ($i - 69)), $iSpacing*2, $iSpacing*2, BitOR($BS_AUTOCHECKBOX, $ES_CENTER,($array_checkboxes[$i][$j] >-1 ? $GUI_CHECKED : $GUI_UNCHECKED)))
			    If $array_weaponmods[$i][$j] = 1 then guictrlsetstate (-1, $GUI_CHECKED)
			    If $array_weaponmods[$i][$j] 		= -1 then guictrlsetstate (-1, $GUI_DISABLE)
			    If $array_weaponmods_ini[$i][$j] 	= 1 then guictrlsetstate (-1, $GUI_CHECKED)
				Next
			 Next

   GUICtrlCreateTabItem("") ; end tabitem definition

   GUICtrlCreateTabItem("Armor")
		 Global $grpEnergy = GUICtrlCreateGroup("", 0, 14, 816, 660)
		 For $j = 4 to 14
			GUICtrlCreateLabel($ColLabels[$j-4], $X_GUI + 55 +(50 * $j), 40 , $iSpacing*6, $iSpacing*2, $ES_CENTER)
			For $i = 102 To 132
				If $j = 4 then GUICtrlCreateLabel($array_weaponmods[$i][0], $X_GUI+$iSpacing*2, 60 + (19 * ($i - 102)),200, $iSpacing*2)
				$array_checkboxes[$i][$j] = GUICtrlCreateCheckbox("", $X_GUI + 72+(50 * $j), 60 + (19 * ($i - 102)), $iSpacing*2, $iSpacing*2, BitOR($BS_AUTOCHECKBOX, $ES_CENTER,($array_checkboxes[$i][$j] >-1 ? $GUI_CHECKED : $GUI_UNCHECKED)))
			    If $array_weaponmods[$i][$j] = 1 then guictrlsetstate (-1, $GUI_CHECKED)
			    If $array_weaponmods[$i][$j] 		= -1 then guictrlsetstate (-1, $GUI_DISABLE)
			    If $array_weaponmods_ini[$i][$j] 	= 1 then guictrlsetstate (-1, $GUI_CHECKED)
			Next
		 Next

   GUICtrlCreateTabItem("") ; end tabitem definition

   GUISetOnEvent($GUI_EVENT_CLOSE, "SpecialEvents")

   GUICtrlCreateGroup("", -99, -99, 1, 1)

   GUISetState()

EndFunc

Func SpecialEvents()

   Select
        Case @GUI_CtrlId = $GUI_EVENT_CLOSE
			For $j = 4 to 14
			   For $i = 0 to 132
				  $array_weaponmods[$i][$j] = GUICtrlRead($array_checkboxes[$i][$j])
			   Next
			Next

			_arrayToIni("Mod_Settings.ini", "Mod_Settings.ini", $array_weaponmods)

;			_ArrayDisplay($array_weaponmods_ini, "2D display")

			GUISetState (@SW_HIDE)

	    Case @GUI_CtrlId = $GUI_EVENT_MINIMIZE
			GUISetState (@SW_MINIMIZE)
;			MsgBox($MB_SYSTEMMODAL, "Window Minimized", "ID=" & @GUI_CtrlId & " WinHandle=" & @GUI_WinHandle)

        Case @GUI_CtrlId = $GUI_EVENT_RESTORE
		    GUISetState (@SW_MAXIMIZE)
;           MsgBox($MB_SYSTEMMODAL, "Window Restored", "ID=" & @GUI_CtrlId & " WinHandle=" & @GUI_WinHandle)

    EndSelect
 EndFunc   ;==>SpecialEvents


 #Region Ini

#cs#  Returns the array stored in ini file via the _arraytoini function based on preselected array number of columns and total number of rows
	  Maps ini rows back into array based on initially stored properties, including number of columns to break the string into

	  To read a ini file to array, you must have declared the array that will receive the ini file's array. You must pass the array name as a string, not a variable.

	   Global (or Local) $colors
	   _iniToArray("config.ini", "colors");correct
	   _iniToArray("config.ini", $colors);wrongv
#ce

 Func _iniToArray($hFile, $sArrays = 0)
   If $sArrays == 0 Then Return
   $sArrays = StringSplit($sArrays, ",", 2)
   Local $aSection = IniReadSectionNames($hFile)
   _ArrayDelete($aSection, 0)

   Local $aProperties[UBound($aSection)][4]
   Local $aData = StringSplit($aSection[0], "#")										; returns an array of properties
   Local $sTemp = IniReadSection($hFile, $aSection[0]), $aTemp[1]
;   _ArrayDisplay ($sTemp, "2D Display")

   For $jj = 1 To $sTemp[0][0]
	  _ArrayAdd($aTemp, $sTemp[$jj][1])
   Next
   _ArrayDelete($aTemp, 0)
;   _ArrayDisplay ($aTemp, "2D Display")

   Local $Array_ini[(UBound($aTemp))/$aData[2]][$aData[2]]

   For $i = 0 To (UBound($aTemp)+1)/$aData[2] - 1
	  For $j = 0 to $aData[2] - 1
		 $Array_ini[$i][$j] = $aTemp[ $i * $aData[2] + $j ]
		 If $i = (UBound($aTemp)+1)/$aData[2] - 1 then _ArrayDisplay ($Array_ini, "2D Display")
	  Next
   Next

   Return $Array_ini

EndFunc   ;==>_iniToArray


 #comments-start

 Script Function:
	This script write a single array[i] or bi-dimensional array[i][j] into a ini file's section.
	Each column is separated by '|' and if string contain a '|', it was changed to string '<%Separator%>'.

	If a single array[i], is a traditional way... not changing...
	_arrayToIni($IniNameFile, $IniSectionName, $ArrayName)
	$config[3] = ["optionA", "optionB", "optionC"]
	_arrayToIni("config.ini", "config", $config)
	In the ini:
	[config]
	0=optionA
	1=optionB
	2=optionC

	If a bi-dimensional array[i][j] has some diferences...
	$colors[3][2] = [["green","verde"],["red","vermelho"],["blue","azul"]]
	_arrayToIni("config.ini", "colors", $colors)
	In the Ini:
	[colors#2#|#<%Separator%>]
	0=green|verde
	1=red|vermelho
	2=blue|azul

	A columns number, the character separator (|) and long string to separator has include in the section name's ini.

#comments-end

 Func _arrayToIni($hFile, $sSection, $aName)
	Local $iLines = UBound($aName)
	Switch UBound($aName, 2)
		Case 0
			Local $sTemp = ""
			For $ii = 0 To $iLines - 1
				$aName[$ii] = StringReplace($aName[$ii], @LF, "At^LF")
				$sTemp &= $ii & "=" & $aName[$ii] & @LF
			Next
			IniWriteSection($hFile, $sSection, $sTemp, 0)
		Case Else
			Local $aTemp[1], $sString = "", $iColumns = UBound($aName, 2)
			For $ii = 0 To $iLines - 1
				For $jj = 0 To $iColumns - 1
					$aName[$ii][$jj] = StringReplace($aName[$ii][$jj], $defaultSeparator, $defaultSeparatorString)
					$sString &= $aName[$ii][$jj] & $defaultSeparator
				Next
				_ArrayAdd($aTemp, StringTrimRight($sString, 1))
				$sString = ""
			Next
			_ArrayDelete($aTemp, 0)
			_arrayToIni($hFile, $sSection & "#" & $iColumns & "#" & $defaultSeparator & "#" & $defaultSeparatorString, $aTemp)
	EndSwitch
EndFunc   ;==>_arrayToIni

#EndRegion Ini File