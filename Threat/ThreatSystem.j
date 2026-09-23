/**
    ThreatSystem

    Author: Valdemar
    Version: 1.3.0

    Description:
    Automatic PvE threat and aggro management for computer-controlled enemies.
    Damage creates threat at 1:1. Effective healing of an ally creates 25%
    threat split between enemies engaged with that ally's faction. Ally-targeted
    support spells create a small split threat amount. Aggro changes at 110% in
    melee range or 130% at range and are announced with floating text. Only
    units with active threat tables consume runtime maintenance state; one-shot
    timers reset tables after inactivity.

    Credits:
    - Blizzard Entertainment, World of Warcraft threat rules
    - Quilnez, RPG Threat System (autonomous retargeting reference only)

    How to install:
    Import after Table, Events, UnitDeathEvent, DamageEngine, and HealEngine.
    No per-unit or per-ability registration is required. Import TargetUnitUI
    after this library and Boss for the boss target/threat display.

    API:
    - call ThreatSystem_Add(threatUnit, source, amount)
    - call ThreatSystem_Modify(threatUnit, source, amount)
    - call ThreatSystem_AddBuffThreat(source, alliedTarget, amount)
    - call ThreatSystem_Taunt(threatUnit, source)
    - call ThreatSystem_ClearUnit(threatUnit)
    - call ThreatSystem_ClearSource(source)
    - call ThreatSystem_SetEnabled(threatUnit, enabled)
    - call ThreatSystem_SetSourceMultiplier(source, multiplier)
    - set value = ThreatSystem_GetThreat(threatUnit, source)
    - set source = ThreatSystem_GetAggroTarget(threatUnit)
    - set threatUnit = ThreatSystem_GetCombatTarget(source)
    - set active = ThreatSystem_HasThreat(threatUnit)
    - set source = ThreatSystem_GetRankedUnit(threatUnit, rank)
    - set value = ThreatSystem_GetRankedThreat(threatUnit, rank)
    - call ThreatSystem_SetAggroTextVisible(visible) // Local UI setting
    - set visible = ThreatSystem_IsAggroTextVisible()

**/
library ThreatSystem initializer Init requires Table, Events, UnitDeathEvent, DamageEngine, HealEngine

globals
    // WoW-style threat ratios and aggro pull thresholds.
    private constant real THREAT_DAMAGE_MULTIPLIER = 1.00
    private constant real THREAT_HEAL_MULTIPLIER = 0.25
    private constant real THREAT_DEFAULT_BUFF_AMOUNT = 5.00
    private constant real THREAT_ENGAGE_AMOUNT = 1.00
    private constant real THREAT_MELEE_PULL_MULTIPLIER = 1.10
    private constant real THREAT_RANGED_PULL_MULTIPLIER = 1.30
    private constant real THREAT_MELEE_RANGE = 200.00
    private constant real THREAT_SUPPORT_ENGAGE_RANGE = 4000.00

    // Tables are bounded to protect the global JASS array limit.
    private constant integer THREAT_MAX_TABLES = 200
    private constant integer THREAT_MAX_ENTRIES = 32
    private constant real THREAT_OUT_OF_COMBAT_TIMEOUT = 20.00
    private constant integer THREAT_ATTACK_ORDER_ID = 851983
    private Table Threat_TableByTarget = 0
    private Table Threat_TableByTimer = 0
    private Table Threat_DisabledTarget = 0
    private Table Threat_SourceMultiplier = 0
    private Table Threat_CombatTargetBySource = 0

    private integer Threat_NextTableId = 1
    private integer Threat_FreeCount = 0
    private integer Threat_ActiveCount = 0
    private integer array Threat_FreeTableId
    private integer array Threat_ActiveTableId
    private integer array Threat_ActivePosition
    private boolean array Threat_TableActive
    private integer array Threat_EntryCount
    private unit array Threat_Target
    private unit array Threat_AggroTarget
    private unit array Threat_EntrySource
    private real array Threat_EntryValue
    private timer array Threat_ResetTimer
    private boolean Threat_AggroTextVisible = true

    private trigger Threat_HealTrigger = null
endglobals

private function Threat_IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

private function Threat_IsPlayerFactionUnit takes unit whichUnit returns boolean
    local integer playerIndex = 0
    local player unitOwner = null
    local player whichPlayer = null
    local boolean result = false

    if not Threat_IsAlive(whichUnit) then
        return false
    endif

    set unitOwner = GetOwningPlayer(whichUnit)
    if GetPlayerController(unitOwner) == MAP_CONTROL_USER and GetPlayerSlotState(unitOwner) == PLAYER_SLOT_STATE_PLAYING then
        set unitOwner = null
        return true
    endif

    loop
        exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS or result
        set whichPlayer = Player(playerIndex)
        if GetPlayerController(whichPlayer) == MAP_CONTROL_USER and GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING and IsUnitAlly(whichUnit, whichPlayer) then
            set result = true
        endif
        set playerIndex = playerIndex + 1
    endloop

    set unitOwner = null
    set whichPlayer = null
    return result
endfunction

private function Threat_CanManageTarget takes unit whichUnit returns boolean
    local integer handleId

    if not Threat_IsAlive(whichUnit) or IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0 then
        return false
    endif
    set handleId = GetHandleId(whichUnit)
    if Threat_DisabledTarget.has(handleId) or Threat_IsPlayerFactionUnit(whichUnit) then
        return false
    endif
    return GetPlayerController(GetOwningPlayer(whichUnit)) != MAP_CONTROL_USER
endfunction

private function Threat_IsValidSource takes unit threatUnit, unit source returns boolean
    return Threat_IsAlive(source) and GetUnitAbilityLevel(source, 'Aloc') == 0 and Threat_IsPlayerFactionUnit(source) and IsUnitEnemy(source, GetOwningPlayer(threatUnit))
endfunction

private function Threat_GetEntryIndex takes integer tableId, integer position returns integer
    return tableId * THREAT_MAX_ENTRIES + position
endfunction

private function Threat_GetTableId takes unit threatUnit returns integer
    if threatUnit == null or Threat_TableByTarget == 0 then
        return 0
    endif
    return Threat_TableByTarget[GetHandleId(threatUnit)]
endfunction

private function Threat_FindEntry takes integer tableId, unit source returns integer
    local integer position = 1
    local integer entryIndex

    loop
        exitwhen position > Threat_EntryCount[tableId]
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        if Threat_EntrySource[entryIndex] == source then
            return position
        endif
        set position = position + 1
    endloop
    return 0
endfunction

private function Threat_ReassignCombatTarget takes unit source, integer excludedTableId returns nothing
    local integer activePosition = 1
    local integer tableId
    local integer position
    local integer entryIndex
    local boolean candidateHasAggro
    local boolean bestHasAggro = false
    local real candidateThreat
    local real bestThreat = -1.00
    local unit bestTarget = null

    if source == null then
        return
    endif

    loop
        exitwhen activePosition > Threat_ActiveCount
        set tableId = Threat_ActiveTableId[activePosition]
        if tableId != excludedTableId then
            set position = Threat_FindEntry(tableId, source)
            if position > 0 and Threat_IsAlive(Threat_Target[tableId]) then
                set entryIndex = Threat_GetEntryIndex(tableId, position)
                set candidateThreat = Threat_EntryValue[entryIndex]
                set candidateHasAggro = Threat_AggroTarget[tableId] == source
                if bestTarget == null or (candidateHasAggro and not bestHasAggro) or (candidateHasAggro == bestHasAggro and candidateThreat > bestThreat) then
                    set bestTarget = Threat_Target[tableId]
                    set bestThreat = candidateThreat
                    set bestHasAggro = candidateHasAggro
                endif
            endif
        endif
        set activePosition = activePosition + 1
    endloop

    if bestTarget == null then
        call Threat_CombatTargetBySource.unit.remove(GetHandleId(source))
    else
        set Threat_CombatTargetBySource.unit[GetHandleId(source)] = bestTarget
    endif
    set bestTarget = null
endfunction

private function Threat_GetSourceMultiplierValue takes unit source returns real
    local integer handleId

    if source == null then
        return 0.00
    endif
    set handleId = GetHandleId(source)
    if Threat_SourceMultiplier.real.has(handleId) then
        return Threat_SourceMultiplier.real[handleId]
    endif
    return 1.00
endfunction

private function Threat_AllocateTable takes unit threatUnit returns integer
    local integer tableId

    if Threat_FreeCount > 0 then
        set tableId = Threat_FreeTableId[Threat_FreeCount]
        set Threat_FreeTableId[Threat_FreeCount] = 0
        set Threat_FreeCount = Threat_FreeCount - 1
    elseif Threat_NextTableId <= THREAT_MAX_TABLES then
        set tableId = Threat_NextTableId
        set Threat_NextTableId = Threat_NextTableId + 1
    else
        return 0
    endif

    set Threat_TableActive[tableId] = true
    set Threat_Target[tableId] = threatUnit
    set Threat_AggroTarget[tableId] = null
    set Threat_EntryCount[tableId] = 0
    set Threat_TableByTarget[GetHandleId(threatUnit)] = tableId
    if Threat_ResetTimer[tableId] == null then
        set Threat_ResetTimer[tableId] = CreateTimer()
        set Threat_TableByTimer[GetHandleId(Threat_ResetTimer[tableId])] = tableId
    endif
    set Threat_ActiveCount = Threat_ActiveCount + 1
    set Threat_ActiveTableId[Threat_ActiveCount] = tableId
    set Threat_ActivePosition[tableId] = Threat_ActiveCount
    return tableId
endfunction

private function Threat_ReleaseTable takes integer tableId returns nothing
    local integer position = 1
    local integer entryIndex
    local integer activePosition
    local integer movedTableId
    local unit threatUnit = null
    local unit source = null

    if tableId <= 0 or tableId >= Threat_NextTableId or not Threat_TableActive[tableId] then
        return
    endif

    set threatUnit = Threat_Target[tableId]
    if threatUnit != null then
        call Threat_TableByTarget.remove(GetHandleId(threatUnit))
    endif

    loop
        exitwhen position > Threat_EntryCount[tableId]
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set source = Threat_EntrySource[entryIndex]
        if source != null and Threat_CombatTargetBySource.unit[GetHandleId(source)] == threatUnit then
            call Threat_CombatTargetBySource.unit.remove(GetHandleId(source))
            call Threat_ReassignCombatTarget(source, tableId)
        endif
        set Threat_EntrySource[entryIndex] = null
        set Threat_EntryValue[entryIndex] = 0.00
        set position = position + 1
    endloop

    set Threat_TableActive[tableId] = false
    call PauseTimer(Threat_ResetTimer[tableId])
    set Threat_Target[tableId] = null
    set Threat_AggroTarget[tableId] = null
    set Threat_EntryCount[tableId] = 0

    set activePosition = Threat_ActivePosition[tableId]
    if activePosition > 0 then
        set movedTableId = Threat_ActiveTableId[Threat_ActiveCount]
        set Threat_ActiveTableId[activePosition] = movedTableId
        set Threat_ActivePosition[movedTableId] = activePosition
        set Threat_ActiveTableId[Threat_ActiveCount] = 0
        set Threat_ActivePosition[tableId] = 0
        set Threat_ActiveCount = Threat_ActiveCount - 1
    endif

    set Threat_FreeCount = Threat_FreeCount + 1
    set Threat_FreeTableId[Threat_FreeCount] = tableId
    set threatUnit = null
    set source = null
endfunction

private function Threat_OnCombatTimeout takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer tableId = Threat_TableByTimer[GetHandleId(expiredTimer)]

    if tableId > 0 and Threat_TableActive[tableId] then
        call Threat_ReleaseTable(tableId)
    endif
    set expiredTimer = null
endfunction

private function Threat_TouchTable takes integer tableId returns nothing
    if tableId > 0 and Threat_TableActive[tableId] then
        call TimerStart(Threat_ResetTimer[tableId], THREAT_OUT_OF_COMBAT_TIMEOUT, false, function Threat_OnCombatTimeout)
    endif
endfunction

private function Threat_RemoveEntry takes integer tableId, integer position returns nothing
    local integer lastPosition = Threat_EntryCount[tableId]
    local integer entryIndex
    local integer lastIndex
    local unit removedSource = null

    if position <= 0 or position > lastPosition then
        return
    endif

    set entryIndex = Threat_GetEntryIndex(tableId, position)
    set lastIndex = Threat_GetEntryIndex(tableId, lastPosition)
    set removedSource = Threat_EntrySource[entryIndex]
    if removedSource != null and Threat_CombatTargetBySource.unit[GetHandleId(removedSource)] == Threat_Target[tableId] then
        call Threat_CombatTargetBySource.unit.remove(GetHandleId(removedSource))
        call Threat_ReassignCombatTarget(removedSource, tableId)
    endif
    if Threat_AggroTarget[tableId] == removedSource then
        set Threat_AggroTarget[tableId] = null
    endif

    if position != lastPosition then
        set Threat_EntrySource[entryIndex] = Threat_EntrySource[lastIndex]
        set Threat_EntryValue[entryIndex] = Threat_EntryValue[lastIndex]
    endif
    set Threat_EntrySource[lastIndex] = null
    set Threat_EntryValue[lastIndex] = 0.00
    set Threat_EntryCount[tableId] = lastPosition - 1
    set removedSource = null
endfunction

private function Threat_ShowAggroChange takes unit threatUnit, unit newTarget returns nothing
    local texttag tag = null

    if threatUnit == null or newTarget == null then
        return
    endif

    set tag = CreateTextTag()
    call SetTextTagText(tag, "Aggro -> " + GetUnitName(newTarget), 0.022)
    call SetTextTagPosUnit(tag, threatUnit, 24.00)
    call SetTextTagColor(tag, 255, 170, 64, 255)
    call SetTextTagVelocity(tag, 0.00, 0.035)
    call SetTextTagPermanent(tag, false)
    call SetTextTagFadepoint(tag, 1.20)
    call SetTextTagLifespan(tag, 2.00)
    call SetTextTagVisibility(tag, Threat_AggroTextVisible)
    set tag = null
endfunction

private function Threat_SetAggroTarget takes integer tableId, unit newTarget returns nothing
    local unit threatUnit = null

    if not Threat_TableActive[tableId] or Threat_AggroTarget[tableId] == newTarget then
        return
    endif

    set threatUnit = Threat_Target[tableId]
    set Threat_AggroTarget[tableId] = newTarget
    if newTarget != null and Threat_IsAlive(threatUnit) then
        call Threat_ShowAggroChange(threatUnit, newTarget)
        call IssueTargetOrderById(threatUnit, THREAT_ATTACK_ORDER_ID, newTarget)
    endif
    set threatUnit = null
endfunction

private function Threat_EvaluateAggro takes integer tableId returns nothing
    local integer position = 1
    local integer entryIndex
    local integer currentPosition
    local unit highestSource = null
    local unit currentSource = null
    local real highestThreat = -1.00
    local real currentThreat
    local real pullMultiplier

    if not Threat_TableActive[tableId] or Threat_EntryCount[tableId] <= 0 then
        return
    endif

    loop
        exitwhen position > Threat_EntryCount[tableId]
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        if Threat_IsValidSource(Threat_Target[tableId], Threat_EntrySource[entryIndex]) and Threat_EntryValue[entryIndex] > highestThreat then
            set highestThreat = Threat_EntryValue[entryIndex]
            set highestSource = Threat_EntrySource[entryIndex]
        endif
        set position = position + 1
    endloop

    if highestSource == null then
        call Threat_SetAggroTarget(tableId, null)
        return
    endif

    set currentSource = Threat_AggroTarget[tableId]
    set currentPosition = Threat_FindEntry(tableId, currentSource)
    if currentPosition <= 0 or not Threat_IsValidSource(Threat_Target[tableId], currentSource) then
        call Threat_SetAggroTarget(tableId, highestSource)
    elseif highestSource != currentSource then
        set currentThreat = Threat_EntryValue[Threat_GetEntryIndex(tableId, currentPosition)]
        if IsUnitInRange(Threat_Target[tableId], highestSource, THREAT_MELEE_RANGE) then
            set pullMultiplier = THREAT_MELEE_PULL_MULTIPLIER
        else
            set pullMultiplier = THREAT_RANGED_PULL_MULTIPLIER
        endif
        if highestThreat > currentThreat * pullMultiplier then
            call Threat_SetAggroTarget(tableId, highestSource)
        endif
    endif

    set highestSource = null
    set currentSource = null
endfunction

private function Threat_AddInternal takes unit threatUnit, unit source, real amount returns nothing
    local integer tableId
    local integer position
    local integer entryIndex
    local integer lowestPosition = 0
    local real lowestThreat = 0.00
    local real adjustedAmount
    local unit replacedSource = null

    if amount <= 0.00 or not Threat_CanManageTarget(threatUnit) or not Threat_IsValidSource(threatUnit, source) then
        return
    endif

    set adjustedAmount = amount * Threat_GetSourceMultiplierValue(source)
    if adjustedAmount <= 0.00 then
        return
    endif

    set tableId = Threat_GetTableId(threatUnit)
    if tableId == 0 then
        set tableId = Threat_AllocateTable(threatUnit)
        if tableId == 0 then
            return
        endif
    endif

    set position = Threat_FindEntry(tableId, source)
    if position == 0 then
        if Threat_EntryCount[tableId] < THREAT_MAX_ENTRIES then
            set position = Threat_EntryCount[tableId] + 1
            set Threat_EntryCount[tableId] = position
        else
            set position = 1
            set lowestPosition = 1
            set lowestThreat = Threat_EntryValue[Threat_GetEntryIndex(tableId, 1)]
            loop
                exitwhen position > THREAT_MAX_ENTRIES
                set entryIndex = Threat_GetEntryIndex(tableId, position)
                if Threat_EntryValue[entryIndex] < lowestThreat then
                    set lowestThreat = Threat_EntryValue[entryIndex]
                    set lowestPosition = position
                endif
                set position = position + 1
            endloop
            if adjustedAmount <= lowestThreat then
                call Threat_TouchTable(tableId)
                return
            endif
            set position = lowestPosition
            set entryIndex = Threat_GetEntryIndex(tableId, position)
            set replacedSource = Threat_EntrySource[entryIndex]
            if replacedSource != null and Threat_CombatTargetBySource.unit[GetHandleId(replacedSource)] == threatUnit then
                call Threat_CombatTargetBySource.unit.remove(GetHandleId(replacedSource))
                call Threat_ReassignCombatTarget(replacedSource, tableId)
            endif
        endif
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set Threat_EntrySource[entryIndex] = source
        set Threat_EntryValue[entryIndex] = adjustedAmount
    else
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set Threat_EntryValue[entryIndex] = Threat_EntryValue[entryIndex] + adjustedAmount
    endif

    set Threat_CombatTargetBySource.unit[GetHandleId(source)] = threatUnit
    call Threat_TouchTable(tableId)
    call Threat_EvaluateAggro(tableId)
    set replacedSource = null
endfunction

private function Threat_IsEngagedWithAlly takes integer tableId, unit alliedUnit returns boolean
    local integer position = 1
    local integer entryIndex
    local player alliedOwner = null
    local boolean engaged = false

    if not Threat_TableActive[tableId] or alliedUnit == null then
        return false
    endif
    if not IsUnitInRange(Threat_Target[tableId], alliedUnit, THREAT_SUPPORT_ENGAGE_RANGE) then
        return false
    endif

    set alliedOwner = GetOwningPlayer(alliedUnit)
    loop
        exitwhen position > Threat_EntryCount[tableId] or engaged
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        if Threat_IsAlive(Threat_EntrySource[entryIndex]) and IsUnitAlly(Threat_EntrySource[entryIndex], alliedOwner) then
            set engaged = true
        endif
        set position = position + 1
    endloop

    set alliedOwner = null
    return engaged
endfunction

private function Threat_AddSupportThreat takes unit source, unit alliedTarget, real totalThreat returns nothing
    local integer activePosition = 1
    local integer tableId
    local integer engagedCount = 0
    local real splitThreat

    if totalThreat <= 0.00 or source == null or alliedTarget == null or not IsUnitAlly(alliedTarget, GetOwningPlayer(source)) then
        return
    endif

    loop
        exitwhen activePosition > Threat_ActiveCount
        set tableId = Threat_ActiveTableId[activePosition]
        if Threat_CanManageTarget(Threat_Target[tableId]) and IsUnitEnemy(source, GetOwningPlayer(Threat_Target[tableId])) and Threat_IsEngagedWithAlly(tableId, alliedTarget) then
            set engagedCount = engagedCount + 1
        endif
        set activePosition = activePosition + 1
    endloop

    if engagedCount <= 0 then
        return
    endif

    set splitThreat = totalThreat / I2R(engagedCount)
    set activePosition = 1
    loop
        exitwhen activePosition > Threat_ActiveCount
        set tableId = Threat_ActiveTableId[activePosition]
        if Threat_CanManageTarget(Threat_Target[tableId]) and IsUnitEnemy(source, GetOwningPlayer(Threat_Target[tableId])) and Threat_IsEngagedWithAlly(tableId, alliedTarget) then
            call Threat_AddInternal(Threat_Target[tableId], source, splitThreat)
        endif
        set activePosition = activePosition + 1
    endloop
endfunction

public function Add takes unit threatUnit, unit source, real amount returns nothing
    call Threat_AddInternal(threatUnit, source, amount)
endfunction

public function Modify takes unit threatUnit, unit source, real amount returns nothing
    local integer tableId = Threat_GetTableId(threatUnit)
    local integer position
    local integer entryIndex
    local real newThreat

    if amount > 0.00 and tableId == 0 then
        call Threat_AddInternal(threatUnit, source, amount)
        return
    elseif tableId == 0 then
        return
    endif

    set position = Threat_FindEntry(tableId, source)
    if position == 0 then
        if amount > 0.00 then
            call Threat_AddInternal(threatUnit, source, amount)
        endif
        return
    endif

    set entryIndex = Threat_GetEntryIndex(tableId, position)
    set newThreat = Threat_EntryValue[entryIndex] + amount
    if newThreat <= 0.00 then
        call Threat_RemoveEntry(tableId, position)
    else
        set Threat_EntryValue[entryIndex] = newThreat
    endif
    if Threat_EntryCount[tableId] <= 0 then
        call Threat_ReleaseTable(tableId)
    else
        if newThreat > 0.00 then
            set Threat_CombatTargetBySource.unit[GetHandleId(source)] = threatUnit
        endif
        call Threat_TouchTable(tableId)
        call Threat_EvaluateAggro(tableId)
    endif
endfunction

public function AddBuffThreat takes unit source, unit alliedTarget, real amount returns nothing
    if amount <= 0.00 then
        set amount = THREAT_DEFAULT_BUFF_AMOUNT
    endif
    call Threat_AddSupportThreat(source, alliedTarget, amount)
endfunction

public function ClearUnit takes unit threatUnit returns nothing
    call Threat_ReleaseTable(Threat_GetTableId(threatUnit))
endfunction

public function ClearSource takes unit source returns nothing
    local integer activePosition = 1
    local integer tableId
    local integer position
    local boolean released

    if source == null then
        return
    endif
    call Threat_CombatTargetBySource.unit.remove(GetHandleId(source))

    loop
        exitwhen activePosition > Threat_ActiveCount
        set tableId = Threat_ActiveTableId[activePosition]
        set released = false
        set position = Threat_FindEntry(tableId, source)
        if position > 0 then
            call Threat_RemoveEntry(tableId, position)
            if Threat_EntryCount[tableId] <= 0 then
                call Threat_ReleaseTable(tableId)
                set released = true
            else
                call Threat_TouchTable(tableId)
                call Threat_EvaluateAggro(tableId)
            endif
        endif
        if not released then
            set activePosition = activePosition + 1
        endif
    endloop
endfunction

public function SetEnabled takes unit threatUnit, boolean enabled returns nothing
    local integer handleId

    if threatUnit == null then
        return
    endif

    set handleId = GetHandleId(threatUnit)
    if enabled then
        call Threat_DisabledTarget.remove(handleId)
    else
        set Threat_DisabledTarget[handleId] = 1
        call ClearUnit(threatUnit)
    endif
endfunction

public function SetSourceMultiplier takes unit source, real multiplier returns nothing
    local integer handleId

    if source == null then
        return
    endif
    if multiplier < 0.00 then
        set multiplier = 0.00
    endif

    set handleId = GetHandleId(source)
    if multiplier == 1.00 then
        call Threat_SourceMultiplier.real.remove(handleId)
    else
        set Threat_SourceMultiplier.real[handleId] = multiplier
    endif
endfunction

public function GetThreat takes unit threatUnit, unit source returns real
    local integer tableId = Threat_GetTableId(threatUnit)
    local integer position

    if tableId == 0 then
        return 0.00
    endif
    set position = Threat_FindEntry(tableId, source)
    if position == 0 then
        return 0.00
    endif
    return Threat_EntryValue[Threat_GetEntryIndex(tableId, position)]
endfunction

public function GetAggroTarget takes unit threatUnit returns unit
    local integer tableId = Threat_GetTableId(threatUnit)

    if tableId == 0 then
        return null
    endif
    return Threat_AggroTarget[tableId]
endfunction

public function GetCombatTarget takes unit source returns unit
    local integer tableId
    local unit target = null

    if source == null then
        return null
    endif

    set target = Threat_CombatTargetBySource.unit[GetHandleId(source)]
    set tableId = Threat_GetTableId(target)
    if tableId > 0 and Threat_TableActive[tableId] and Threat_FindEntry(tableId, source) > 0 then
        return target
    endif
    call Threat_CombatTargetBySource.unit.remove(GetHandleId(source))
    set target = null
    return null
endfunction

public function SetAggroTextVisible takes boolean visible returns nothing
    set Threat_AggroTextVisible = visible
endfunction

public function IsAggroTextVisible takes nothing returns boolean
    return Threat_AggroTextVisible
endfunction

public function HasThreat takes unit threatUnit returns boolean
    local integer tableId = Threat_GetTableId(threatUnit)

    return tableId > 0 and Threat_TableActive[tableId] and Threat_EntryCount[tableId] > 0 and Threat_AggroTarget[tableId] != null
endfunction

public function GetRankedUnit takes unit threatUnit, integer rank returns unit
    local integer tableId = Threat_GetTableId(threatUnit)
    local integer candidatePosition = 1
    local integer comparePosition
    local integer candidateIndex
    local integer compareIndex
    local integer numericRank
    local unit currentSource = null
    local unit candidateSource = null
    local unit compareSource = null
    local real candidateThreat
    local real compareThreat

    if tableId == 0 or rank <= 0 then
        return null
    endif

    set currentSource = Threat_AggroTarget[tableId]
    if rank == 1 then
        set currentSource = null
        return Threat_AggroTarget[tableId]
    endif
    if currentSource == null then
        set rank = rank + 1
    endif

    loop
        exitwhen candidatePosition > Threat_EntryCount[tableId]
        set candidateIndex = Threat_GetEntryIndex(tableId, candidatePosition)
        set candidateSource = Threat_EntrySource[candidateIndex]
        if candidateSource != currentSource and Threat_IsAlive(candidateSource) then
            set numericRank = 1
            set comparePosition = 1
            set candidateThreat = Threat_EntryValue[candidateIndex]
            loop
                exitwhen comparePosition > Threat_EntryCount[tableId]
                set compareIndex = Threat_GetEntryIndex(tableId, comparePosition)
                set compareSource = Threat_EntrySource[compareIndex]
                if compareSource != currentSource and compareSource != candidateSource and Threat_IsAlive(compareSource) then
                    set compareThreat = Threat_EntryValue[compareIndex]
                    if compareThreat > candidateThreat or (compareThreat == candidateThreat and GetHandleId(compareSource) < GetHandleId(candidateSource)) then
                        set numericRank = numericRank + 1
                    endif
                endif
                set comparePosition = comparePosition + 1
            endloop
            if numericRank == rank - 1 then
                set currentSource = null
                set candidateSource = null
                set compareSource = null
                return Threat_EntrySource[candidateIndex]
            endif
        endif
        set candidatePosition = candidatePosition + 1
    endloop

    set currentSource = null
    set candidateSource = null
    set compareSource = null
    return null
endfunction

public function GetRankedThreat takes unit threatUnit, integer rank returns real
    local unit source = GetRankedUnit(threatUnit, rank)
    local real value = GetThreat(threatUnit, source)

    set source = null
    return value
endfunction

public function Taunt takes unit threatUnit, unit source returns nothing
    local integer tableId
    local integer position = 1
    local integer entryIndex
    local integer sourcePosition
    local real highestThreat = 1.00

    if not Threat_CanManageTarget(threatUnit) or not Threat_IsValidSource(threatUnit, source) then
        return
    endif

    set tableId = Threat_GetTableId(threatUnit)
    if tableId == 0 then
        call Threat_AddInternal(threatUnit, source, 1.00)
        set tableId = Threat_GetTableId(threatUnit)
    endif
    if tableId == 0 then
        return
    endif

    loop
        exitwhen position > Threat_EntryCount[tableId]
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        if Threat_EntryValue[entryIndex] > highestThreat then
            set highestThreat = Threat_EntryValue[entryIndex]
        endif
        set position = position + 1
    endloop

    set sourcePosition = Threat_FindEntry(tableId, source)
    if sourcePosition == 0 then
        call Threat_AddInternal(threatUnit, source, highestThreat)
        set sourcePosition = Threat_FindEntry(tableId, source)
    endif
    if sourcePosition > 0 then
        set Threat_EntryValue[Threat_GetEntryIndex(tableId, sourcePosition)] = highestThreat
        set Threat_CombatTargetBySource.unit[GetHandleId(source)] = threatUnit
        call Threat_TouchTable(tableId)
        call Threat_SetAggroTarget(tableId, source)
    endif
endfunction

private function Threat_OnDamage takes nothing returns nothing
    if udg_DamageEventAmount > 0.00 then
        call Threat_AddInternal(udg_DamageEventTarget, udg_DamageEventSource, udg_DamageEventAmount * THREAT_DAMAGE_MULTIPLIER)
        // An enemy that initiates combat still needs a table before the party
        // damages it, so subsequent healing and support casts can create threat.
        if Threat_CanManageTarget(udg_DamageEventSource) and Threat_IsValidSource(udg_DamageEventSource, udg_DamageEventTarget) then
            call Threat_AddInternal(udg_DamageEventSource, udg_DamageEventTarget, THREAT_ENGAGE_AMOUNT)
        endif
    endif
endfunction

private function Threat_OnHeal takes nothing returns nothing
    if udg_HealSource != null and udg_HealTarget != null and udg_HealSource != udg_HealTarget and udg_EffectiveHealAmount > 0.00 and IsUnitAlly(udg_HealTarget, GetOwningPlayer(udg_HealSource)) then
        call Threat_AddSupportThreat(udg_HealSource, udg_HealTarget, udg_EffectiveHealAmount * THREAT_HEAL_MULTIPLIER)
    endif
endfunction

private function Threat_OnSpellEffect takes nothing returns nothing
    local unit source = Events_GetTriggerUnit()
    local unit alliedTarget = Events_GetSpellTargetUnit()

    if source != null and alliedTarget != null and source != alliedTarget and IsUnitAlly(alliedTarget, GetOwningPlayer(source)) then
        call Threat_AddSupportThreat(source, alliedTarget, THREAT_DEFAULT_BUFF_AMOUNT)
    endif

    set source = null
    set alliedTarget = null
endfunction

private function Threat_OnDeath takes nothing returns nothing
    local unit dyingUnit = UnitDeathEvent_GetDyingUnit()

    call ClearUnit(dyingUnit)
    call ClearSource(dyingUnit)
    set dyingUnit = null
endfunction

private function Init takes nothing returns nothing
    set Threat_TableByTarget = Table.create()
    set Threat_TableByTimer = Table.create()
    set Threat_DisabledTarget = Table.create()
    set Threat_SourceMultiplier = Table.create()
    set Threat_CombatTargetBySource = Table.create()

    set Threat_HealTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(Threat_HealTrigger, "udg_AfterHealEvent", EQUAL, 1.00)
    call TriggerAddAction(Threat_HealTrigger, function Threat_OnHeal)

    call RegisterDamageEngine(function Threat_OnDamage, "After", 1.00)
    call Events_RegisterSpellEffect(function Threat_OnSpellEffect)
    call UnitDeathEvent_Register(function Threat_OnDeath)
endfunction

endlibrary
