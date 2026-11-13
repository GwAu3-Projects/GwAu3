#include-once

#Region Module Constants
; Agent module specific constants
Global Const $GC_I_AGENT_TYPE_LIVING = 0xDB
Global Const $GC_I_AGENT_TYPE_GADGET = 0x200
Global Const $GC_I_AGENT_TYPE_ITEM = 0x400

; Agent array constants
Global Const $GC_I_AGENT_MAX_COPY = 256
Global Const $GC_I_AGENT_STRUCT_SIZE = 0x1C0

; Allegiance
Global Const $GC_I_ALLEGIANCE_ALLY = 0x1 ; Ally/non-attackable
Global Const $GC_I_ALLEGIANCE_ANIMAL = 0x2 ; Animal
Global Const $GC_I_ALLEGIANCE_ENEMY = 0x3 ; Enemy
Global Const $GC_I_ALLEGIANCE_SPIRIT = 0x4 ; Spirit or Pet
Global Const $GC_I_ALLEGIANCE_MINION = 0x5 ; Minion
Global Const $GC_I_ALLEGIANCE_NPC = 0x6 ; NPC/Minipet
#EndRegion Module Constants

#Region NPC PlayerNumber
; Core list is sparse; LogicCast/constants.au3 holds the farm NPC PlayerNumbers (Tekk, Shandra, spirits…).
Global Const $GC_I_NPC_THE_PURVEYOR = 8057
Global Const $GC_I_NPC_TEKK = 6795
Global Const $GC_I_NPC_SHANDRA = 7020
#EndRegion NPC PlayerNumber
