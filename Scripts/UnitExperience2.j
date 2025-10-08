library UnitExperience initializer Init requires Table
/*
    UnitExperience
    Version: 2.1
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

//===================== CORE LOGIC =====================

private function AddXP takes unit u, integer amount returns nothing
    local integer id = GetHandleId(u)

    if xpDisabled.boolean[id] or level.integer[id] >= MAX_LEVEL then
        return
    endif

    set xp.integer[id] = xp.integer[id] + amount

    call ArcingTextTag.createEx("+" + I2S(amount) + " XP", u, 1.0, 0.5, GetLocalPlayer(), 0.7, 0.7, 1.0)
    call BJDebugMsg("XP Added: " + I2S(amount) + " to " + GetUnitName(u) + ". Total XP: " + I2S(xp.integer[id]))

    loop
        exitwhen level.integer[id] >= MAX_LEVEL or xp.integer[id] < XPRequired(level.integer[id])
        set xp.integer[id] = xp.integer[id] - XPRequired(level.integer[id])
        set level.integer[id] = level.integer[id] + 1

        call BlzSetUnitIntegerField(u, UNIT_IF_LEVEL, GetUnitLevel(u) + 1)
        call TriggerExecute(gg_trg_MultiboardUpdateLevel)

        if GetUnitTypeId(u) != 'n655' then
            call TriggerExecute(gg_trg_Shadowclaw_Stats)
        endif

        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Levelup\\LevelupCaster.mdl", u, "origin"))
        call StartSound(bj_questCompletedSound)

        call BJDebugMsg("Unit Leveled Up: " + GetUnitName(u) + ". New Level: " + I2S(level.integer[id]))
    endloop
endfunction

private function AddXPToNearbyUnits takes nothing returns nothing
    local unit u = GetEnumUnit()
    local unit dying = GetDyingUnit()

    if registered.boolean[GetHandleId(u)] and IsNearbyHero(u) and GetUnitAbilityLevel(dying, 'Aloc') == 0 then
        call AddXP(u, GetUnitLevel(dying))
    endif
endfunction

private function UnitDeathHandler takes nothing returns nothing
    local unit dying = GetDyingUnit()
    local unit killer = GetKillingUnit()

    if killer == dying then
        return
    endif

    call GroupEnumUnitsInRange(ENUM_GROUP, GetUnitX(dying), GetUnitY(dying), RANGE, null)
    call ForGroup(ENUM_GROUP, function AddXPToNearbyUnits)
    call GroupClear(ENUM_GROUP)
endfunction

//===================== PUBLIC API =====================

public function RegisterUnit takes unit u returns nothing
    local integer id = GetHandleId(u)
    if not registered.boolean[id] then
        set xp.integer[id] = 0
        set level.integer[id] = 1
        set registered.boolean[id] = true
        set xpDisabled.boolean[id] = false
        call BJDebugMsg("Unit Registered for XP: " + GetUnitName(u))
    endif
endfunction

public function RemoveUnit takes unit u returns nothing
    local integer id = GetHandleId(u)
    call xp.remove(id)
    call level.remove(id)
    call registered.remove(id)
    call xpDisabled.remove(id)
    call BJDebugMsg("Unit Removed from XP System: " + GetUnitName(u))
endfunction

public function DisableXP takes unit u, boolean flag returns nothing
    local integer id = GetHandleId(u)
    if registered.boolean[id] then
        set xpDisabled.boolean[id] = flag
        if flag then
            call BJDebugMsg("XP Disabled for: " + GetUnitName(u))
        else
            call BJDebugMsg("XP Enabled for: " + GetUnitName(u))
        endif
    endif
endfunction

public function UnitExperience_GetUnitXP takes unit u returns integer
    return xp.integer[GetHandleId(u)]
endfunction

public function UnitExperience_GetUnitXPToNextLevel takes unit u returns integer
    local integer id = GetHandleId(u)
    local integer lvl = level.integer[id]

    if lvl >= MAX_LEVEL then
        return 0
    endif
    return XPRequired(lvl) - xp.integer[id]
endfunction

//===================== INITIALIZER =====================

private function Init takes nothing returns nothing
    local trigger t = CreateTrigger()

    set xp = Table.create()
    set level = Table.create()
    set registered = Table.create()
    set xpDisabled = Table.create()

    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(t, function UnitDeathHandler)
endfunction

endlibrary
