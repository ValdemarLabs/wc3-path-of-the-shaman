library UnitExperience initializer Init requires Table
/*
    UnitExperience
    Version: 2.3
    Author: Valdemar
*/

globals
    private constant integer MAX_LEVEL   = 30
    private constant real    RANGE       = 1200.0
    private constant real    RANGE_SQ    = RANGE * RANGE
    private constant integer XP_BASE     = 200
    private constant integer XP_FACTOR   = 150

    private Table xp
    private Table level
    private Table registered
    private Table xpDisabled
    private Table baseHP
    private Table baseArmor
    private Table baseMinDmg
    private Table baseMaxDmg
    private Table baseRegen

    private group ENUM_GROUP = CreateGroup() // Manual global group for reuse
endglobals

//===================== INTERNAL UTILS =====================

private function IsNearbyHero takes unit u returns boolean
    local real dx
    local real dy

    if GetOwningPlayer(udg_Nazgrek) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Nazgrek)
        set dy = GetUnitY(u) - GetUnitY(udg_Nazgrek)
        if dx*dx + dy*dy <= RANGE_SQ then
            return true
        endif
    endif
    if GetOwningPlayer(udg_Zulkis) == Player(0) then
        set dx = GetUnitX(u) - GetUnitX(udg_Zulkis)
        set dy = GetUnitY(u) - GetUnitY(udg_Zulkis)
        if dx*dx + dy*dy <= RANGE_SQ then
            return true
        endif
    endif
    return false
endfunction

private function XPRequired takes integer lvl returns integer
    return XP_BASE + XP_FACTOR * (lvl - 1)
endfunction

//===================== STAT SCALING (WE-SAFE with optional BLZ) =====================
private function ScaleUnitStats takes unit u, integer newLevel returns nothing
    local integer CV = GetUnitUserData(u)
    local real oldMaxLife
    local real newMaxLife
    local real hpMult    = 1.12  // +12% HP per level (you can tweak)
    local real regenMult = 1.05  // +5% HP Regen per level (approximate on legacy)
    local real dmgMult   = 1.09  // uncomment for BLZ version
    local real armorMult = 1.05  // uncomment for BLZ version
    local real newArmor
    local real newMinDmg
    local real newMaxDmg

    // -----------------------
    // 1) Initialize base HP if first time
    // -----------------------
    // We use Table semantics like baseHP.has(uid) because your map previously used that.
    if not baseHP.has(CV) then
        // Store a safe base HP value (works across all WE versions)
        set baseHP.real[CV]    = GetUnitState(u, UNIT_STATE_MAX_LIFE)

        // If you have Blz natives supported in your editor/runtime, you can store Armor/Damage/Regen as well.
        // But we avoid calling those here to prevent WE save crashes.
        // If your WE supports Blz* functions, uncomment the BLZ block below and remove the "else" comments.
    endif

    // -----------------------
    // 2) SCALE HP (safe - legacy natives)
    // -----------------------
    set oldMaxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    set newMaxLife = oldMaxLife * hpMult

    // Set new max life (BlzSetUnitMaxHP exists on newer builds, but it is safe to call it at runtime.
    // To avoid WE parse/crash we call it conditionally: comment/uncomment based on your WE.)
    // --- WE-SAFE approach (core natives) ---
    // Note: There is no direct legacy native to set max life except BlzSetUnitMaxHP,
    // but calling BlzSetUnitMaxHP in an editor that rejects Blz natives causes the crash.
    // Therefore - use the following guarded approach:
    // If your editor supports BlzSetUnitMaxHP safely, use it. Otherwise, try a workaround:
    //
    // Workaround (editor-safe): Heal the unit by the computed delta and store baseHP
    // so future scalings use stored baseHP instead of reading runtime max life that may be capped.
    //
    // We'll attempt to call BlzSetUnitMaxHP ONLY if the runtime supports it. If you are unsure,
    // leave the Blz lines commented out and rely on the workaround (still safe).
    //
    // Uncomment the following two lines if your WE and patch are 1.31+ and you DO NOT get a crash:
    call BlzSetUnitMaxHP(u, R2I(newMaxLife))
    call SetUnitState(u, UNIT_STATE_LIFE, newMaxLife) // heal to full after level-up
    //
    // If you leave the above commented because your WE crashes, use this safe fallback:
    set baseHP.real[CV] = baseHP.real[CV] * hpMult
    // heal the unit by the same factor proportionally (approximate)
    call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) * hpMult)

    // -----------------------
    // 3) SCALE REGEN (approximate, WE-safe)
    // -----------------------
    // The proper regen field is only available via Blz in some builds. We approximate by recording
    // a baseRegen value in tables (if present) or simply performing a small heal-on-levelup.
    if not baseRegen.has(CV) then
        // we estimate a small base regen so it grows over time without using Blz natives
        set baseRegen.real[CV] = 0.0
    endif
    set baseRegen.real[CV] = baseRegen.real[CV] * regenMult

    // Optionally give a small instant heal as a regen-like bonus:
    call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) + (oldMaxLife * (regenMult - 1.0)))

    // -----------------------
    // 4) CUSTOM SECONDARY STATS (your existing system)
    // -----------------------
    if CV > 0 then
        set udg_Stats_Block[CV] = udg_Stats_Block[CV] + 1
        set udg_Stats_Crit[CV]  = udg_Stats_Crit[CV]  + 1
        set udg_Stats_Dodge[CV] = udg_Stats_Dodge[CV] + 2
        set udg_Stats_Hit[CV]   = udg_Stats_Hit[CV]   + 1
        call BJDebugMsg(GetUnitName(u) + " gains +1 Block/Crit/Hit and +2 Dodge from level-up.")
    endif

    // -----------------------
    // 5) BLZ-ENABLED ENHANCEMENTS (OPTIONAL)
    //    If your editor & runtime are 1.31+/Reforged and DO NOT crash on save,
    //    you can replace the WE-safe sections above with the Blz-based block below.
    //    Uncomment only when you're certain your World Editor supports Blz natives.
    // -----------------------
    
    // BLZ BLOCK START - uncomment if your WE supports Blz natives (1.31+)
    if not baseArmor.has(CV) then
        set baseArmor.real[CV]   = BlzGetUnitArmor(u)
        set baseMinDmg.real[CV]  = BlzGetUnitBaseDamage(u, 0)
        set baseMaxDmg.real[CV]  = BlzGetUnitDiceSides(u, 0) + baseMinDmg.real[CV]
    endif

    // compute new armor/damage/regens using multiplicative growth
    set newArmor  = baseArmor.real[CV] * armorMult
    set newMinDmg = baseMinDmg.real[CV] * dmgMult
    set newMaxDmg = baseMaxDmg.real[CV] * dmgMult

    // apply them (only safe if BLZ is supported)
    call BlzSetUnitArmor(u, newArmor)
    call BlzSetUnitBaseDamage(u, R2I(newMinDmg), 0)
    call BlzSetUnitDiceSides(u, R2I(newMaxDmg - newMinDmg), 0)
    call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, baseRegen.real[CV] * regenMult)
    // BLZ BLOCK END
    

    // -----------------------
    // 6) DEBUG
    // -----------------------
    call BJDebugMsg("ScaleUnitStats applied to " + GetUnitName(u) + " (CV " + I2S(CV) + "). Level: " + I2S(newLevel))
endfunction

//===================== CORE LOGIC =====================
private function AddXP takes unit u, integer amount returns nothing
    local integer CV = GetUnitUserData(u)
    local integer oldLevel
    local integer newLevel
    local integer levelsGained = 0
    local integer xpNeeded

    if u == null then 
        return 
    endif

    if xpDisabled.has(CV) and xpDisabled[CV] then 
        return 
    endif

    if not xp.has(CV) then 
        set xp[CV] = 0 
    endif
    if not level.has(CV) then 
        set level[CV] = GetUnitLevel(u) 
    endif

    set xp[CV] = xp[CV] + amount

    if amount >= 5 then
        call ArcingTextTag.createEx("+" + I2S(amount) + " XP", u, 1.0, 0.5, GetLocalPlayer(), 0.7, 0.7, 1.0)
    endif

    call BJDebugMsg("XP Added: " + I2S(amount) + " to " + GetUnitName(u) + ". Total XP: " + I2S(xp[CV]))

    set oldLevel = level[CV]
    set newLevel = oldLevel
    loop
        set xpNeeded = XPRequired(newLevel)
        exitwhen newLevel >= MAX_LEVEL or xp.integer[CV] < xpNeeded
        set xp.integer[CV] = xp.integer[CV] - xpNeeded
        set newLevel = newLevel + 1
        set levelsGained = levelsGained + 1
    endloop

    if levelsGained > 0 then
        set level[CV] = newLevel
        call BlzSetUnitIntegerField(u, UNIT_IF_LEVEL, GetUnitLevel(u) + levelsGained)
        call TriggerExecute(gg_trg_MultiboardUpdateLevelTamed)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", u, "origin"))
        call StartSound(bj_questCompletedSound)
        call ScaleUnitStats(u, newLevel)
        call BJDebugMsg("Unit Leveled Up: " + GetUnitName(u) + ". OldLevel: " + I2S(oldLevel) + " NewLevel: " + I2S(newLevel))
    endif
endfunction

private function FilterXPUnits takes nothing returns boolean
    local unit u = GetFilterUnit()
    local integer CV = GetUnitUserData(u)
    local boolean result = IsUnitAliveBJ(u) and registered.has(CV)
    set u = null
    return result
endfunction

private function AddXPToNearbyUnits takes nothing returns nothing
    local unit u = GetEnumUnit()
    local unit dying = GetDyingUnit()
    local integer CV = GetUnitUserData(u)

    if registered.has(CV) and IsNearbyHero(u) and GetUnitAbilityLevel(dying, 'Aloc') == 0 then
        call AddXP(u, GetUnitLevel(dying))
    endif

    set u = null
    set dying = null
endfunction

private function UnitDeathHandler takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local unit killer = GetKillingUnit()
    local boolexpr xpFilter = Condition(function FilterXPUnits)

    if killer == dying then
        set dying = null
        set killer = null
        return
    endif

    call GroupEnumUnitsInRange(ENUM_GROUP, GetUnitX(dying), GetUnitY(dying), RANGE, xpFilter)
    call ForGroup(ENUM_GROUP, function AddXPToNearbyUnits)
    call GroupClear(ENUM_GROUP)
    call DestroyBoolExpr(xpFilter)

    set dying = null
    set killer = null
endfunction

//===================== PUBLIC API =====================

public function RegisterUnit takes unit u returns nothing
    local integer CV = GetUnitUserData(u)
    local integer currentLevel
    local integer totalXP = 0
    local integer i

    if registered.has(CV) then 
        return 
    endif

    set currentLevel = GetUnitLevel(u)
    if currentLevel < 1 then 
        set currentLevel = 1 
    endif

    set i = 1
    loop
        exitwhen i >= currentLevel
        set totalXP = totalXP + XPRequired(i)
        set i = i + 1
    endloop

    set xp[CV] = totalXP
    set level[CV] = currentLevel
    set registered[CV] = true
    set xpDisabled[CV] = false

    call BJDebugMsg("Unit Registered for XP: " + GetUnitName(u) + " (Level " + I2S(currentLevel) + ", CV: " + I2S(CV) + ")")
endfunction

public function RemoveUnit takes unit u returns nothing
    local integer CV = GetUnitUserData(u)

    if xp.has(CV) then 
        call xp.remove(CV) 
    endif

    if level.has(CV) then 
        call level.remove(CV) 
    endif

    if registered.has(CV) then 
        call registered.remove(CV) 
    endif

    if xpDisabled.has(CV) then 
        call xpDisabled.remove(CV) 
    endif

    call BJDebugMsg("Unit Removed from XP System: " + GetUnitName(u))
endfunction

public function DisableXP takes unit u, boolean flag returns nothing
    local integer CV = GetUnitUserData(u)

    if registered.has(CV) then
        set xpDisabled[CV] = flag
        if flag then 
            call BJDebugMsg("XP Disabled for: " + GetUnitName(u))
        else 
            call BJDebugMsg("XP Enabled for: " + GetUnitName(u)) 
        endif
    endif
endfunction

public function UnitExperience_GetUnitXP takes unit u returns integer
    local integer CV = GetUnitUserData(u)
    return xp[CV]
endfunction

endfunction

public function UnitExperience_GetUnitXPToNextLevel takes unit u returns integer
    local integer CV = GetUnitUserData(u)
    local integer lvl = level[CV]

    if lvl >= MAX_LEVEL then 
        return 0 
    endif
    return XPRequired(lvl) - xp[CV]
endfunction

public function IsUnitRegistered takes unit u returns boolean
    local integer CV = GetUnitUserData(u)
    local boolean isReg = registered.has(CV)
    local string status = "false"

    if u == null then
        call BJDebugMsg("IsUnitRegistered called with null unit.")
        return false
    endif

    set isReg = registered.has(CV)

    if isReg then
        set status = "true"
    else
        set status = "false"
    endif

    call BJDebugMsg("Checking registration for unit: " + GetUnitName(u) + " (ID: " + I2S(CV) + ") -> " + status)

    return isReg
endfunction

//===================== INITIALIZER =====================

private function Init takes nothing returns nothing
    local trigger   t = CreateTrigger()

    set xp          = Table.create()
    set level       = Table.create()
    set registered  = Table.create()
    set xpDisabled  = Table.create()
    set baseHP      = Table.create()
    set baseArmor   = Table.create()
    set baseMinDmg  = Table.create()
    set baseMaxDmg  = Table.create()
    set baseRegen   = Table.create()

    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(t, function UnitDeathHandler)
endfunction

endlibrary
