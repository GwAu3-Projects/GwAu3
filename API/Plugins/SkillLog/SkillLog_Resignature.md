# SkillLog resignature playbook

How caster/melee SkillLog was fixed (Nov 2026) and what to do when the next `Gw.exe` breaks the patterns.

## What SkillLog hooks

Logic/GwAu3 do **not** hook the soft-assert function itself. They use a **landmark** AOB, then apply scanner offset **`-46`**.

| Piece | Role |
|--------|------|
| Landmark | Soft-push null check: `55 8B EC 56 8B 75 08 85 F6 75 14 68 <assert_id>` |
| Assert IDs | Distinguish caster vs melee (same shape, different imm32 after `68`) |
| Hook | Landmark **−47** bytes → `8B EC FF 75 08` (thin wrapper: `mov ebp,esp; push [ebp+8]`) |
| Why −46 | `GetScannedAddress` / `Memory_GetScannedAddress` already behaves like match−1, so **−46 ⇒ hook at match−47** |
| Detour replay | After callback: `mov ebp,esp` / `push [ebp+8]` / jmp Return (= Start+5) |
| Registers | `edi` = caster, `ecx` = target, `ebx` = skill |

On this client the landmarks sit in **AvApi.cpp** soft-asserts (`agent`), not in `ChCliSkill.cpp`.

Classic GWA2 single SkillLog (`408946105E5B5D` mid-epilogue) is a **different** hook and is gone/unreliable on current builds. Dual caster/melee is the path we maintain.

## What broke (and why soft-probe failed)

1. **Assert IDs moved** with the client. Old patterns found **0** hits → invalid Start → SetEvent silent.
2. Soft-AOB probe hooked the **landmark prologue** (`55 8B EC…`), not the wrapper at **−47**. Nearby sites could be scanned and still never HIT SkillLog traffic.

## Fix applied (this client)

| Path | Old assert | New assert | Pattern (hex) |
|------|------------|------------|----------------|
| Caster | `0x50E` | `0x531` | `558BEC568B750885F675146831050000` |
| Melee | `0x4D0` | `0x4F3` | `558BEC568B750885F6751468F3040000` |

- Both shifted **`+0x23`**; pair gap stayed **`0x3E`** (`0x531 − 0x4F3`).
- Each pattern unique (1 hit) on disk `Gw.exe`.
- Files: `SkillLog_Core.au3` (`$GC_S_SKILLLOG_PAT_*`), `Logic-main\logic\logic.au3` (`ScanCasterSkillLog` / `ScanMeleeSkillLog`).

Verified: caster HITs (e.g. Overload) and melee HIT (`[MELEE] skill=…`).

## Next time the client changes

### 1. Confirm it’s a signature miss

- `SkillLog_DumpScan` / Logic tester: Start invalid, or pre-arm bytes ≠ `8BECFF75…`
- After arm: hook ≠ `E9…`
- Casts never reach RuptEX / SkillLog callback (Listen/ESW may still work)

### 2. Disk AOB on `Gw.exe`

Target: `C:\Program Files (x86)\Guild Wars\Gw.exe` (or the running build).

```text
Landmark prefix: 55 8B EC 56 8B 75 08 85 F6 75 14 68
```

1. Find all soft_push hits; list **assert dword** after `68`.
2. Keep sites where **bytes at match−48** are:

   `55 8B EC FF 75 08`  
   (wrapper; hook body is that sequence starting at match−47: `8B EC FF 75 08`)

3. Prefer a **pair** in the same assert family (same `BA`/`B9` string pointers, often AvApi/`agent`).
4. Rank by continuity with last known IDs:
   - Same **delta** between caster and melee (was `0x3E`)
   - Similar **absolute shift** (was `+0x23`) if both moved together
5. Confirm each full 16-byte pattern is **unique** (exactly one hit).

### 3. Wire patterns

Update both (keep them in sync):

- `GwAu3\API\Plugins\SkillLog\SkillLog_Core.au3` — `$GC_S_SKILLLOG_PAT_CASTER` / `_MELEE`
- `Logic-main\logic\logic.au3` — `ScanCasterSkillLog` / `ScanMeleeSkillLog`

Leave scanner offset at **`-46`** unless `Memory_GetScannedAddress` math changes (see commented `+1` variant in `GwAu3_Core_Memory.au3`).

### 4. Verify in-game

1. Restart bot / SkillLogTester after rebuild.
2. Dump scan: valid Starts; pre-arm `8BECFF75…`; post-arm `E9…`.
3. **Caster:** cast a spell (e.g. Overload) → HIT on caster path.
4. **Melee:** take a melee/physical skill → HIT with melee/lparam path.

### 5. What not to do

- Do not treat soft_push prologue matches as hook candidates (option‑1 ladder hooks the wrong site).
- Do not assume old GWA2 epilogue `408946105E5B5D` still exists (may false-positive on unrelated ctors).
- Do not change Core for a one-off probe without updating Logic patterns too (or dual stacks diverge).

## Quick checklist

- [ ] Soft_push catalog + assert IDs
- [ ] Filter: wrapper `558BECFF7508` at match−48
- [ ] Pick caster/melee pair (gap / shift / uniqueness)
- [ ] Patch GwAu3 + Logic patterns
- [ ] In-game caster + melee HIT

## SkillLog_Respond wiring (GwAu3)

Public API: **`SkillLog_Respond("OnSpell", "OnMelee")`** (not `EventCallback` — that name is the WM handler).  
Compat alias: `SkillLog_SetEventCallback` → `SkillLog_Respond`.

| Context | Arm | Handlers |
|---------|-----|----------|
| `CacheSkillBar()` | `SkillLog_Respond("OnSpell","OnMelee")` then `SetLive(False)` | LogicCast `OnSpell` / `OnMelee` |
| `Fight()` | `SetLive(True)` enter / `SetLive(False)` exit | same (already armed) |
| Example | `Scripts/Exemples/Exemple_SkillLog_Respond.au3` | same + `SetLive(True)` for always-on test |

**No thin wrappers:** `OnSpell` / `OnMelee` *are* the SkillLog responders.

**Agent poll archived:** `logiccast_AgentCastWatch_archived.au3` (`UpdateAndDispatchCasts`).

**ESW via SkillLog:** `OnSpell` / `OnMelee` call `EnemySkillWatch_Note(caster, skill, target)`. Ally/self target → Shame/Mark; foe spell → Guilt/Mistrust (staged `FOLLOW_*`, drained by Listen). Poll only lands/prunes while SkillLog is live.

**Live gate:** detours stay installed; `$g_b_SkillLogLive` ignores activates outside Fight/bot window.
