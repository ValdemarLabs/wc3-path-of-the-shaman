/**
    ThreatSystem

    Author: Valdemar
    Version: 1.0.0

    Description:
    Automatic PvE threat and aggro management for computer-controlled enemies.
    Damage creates threat at 1:1. Effective healing of an ally creates 25%
    threat split between enemies engaged with that ally's faction. Ally-targeted
    support spells create a small split threat amount. Aggro changes at 110% in
    melee range or 130% at range and are announced with floating text.

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
    - set source = ThreatSystem_GetRankedUnit(threatUnit, rank)
    - set value = ThreatSystem_GetRankedThreat(threatUnit, rank)

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

    // Tables are bounded to protect the global JASS array limit.
    private constant integer THREAT_MAX_TABLES = 200
    private constant integer THREAT_MAX_ENTRIES = 32
    private constant real THREAT_UPDATE_INTERVAL = 0.50
    private constant integer THREAT_IDLE_TICKS = 40
    private constant real THREAT_LEASH_RANGE = 5000.00
    private constant integer THREAT_ATTACK_ORDER_ID = 851983
    private constant boolean THREAT_SHOW_AGGRO_TEXT = true

    private Table Threat_TableByTarget = 0
    private Table Threat_DisabledTarget = 0
    private Table Threat_SourceMultiplier = 0

    private integer Threat_NextTableId = 1
    private integer Threat_FreeCount = 0
    private integer Threat_ClockTick = 0
    private integer array Threat_FreeTableId
    private boolean array Threat_TableActive
    private integer array Threat_EntryCount
    private integer array Threat_LastActivityTick
    private unit array Threat_Target
    private unit array Threat_AggroTarget
    private unit array Threat_EntrySource
    private real array Threat_EntryValue

    private trigger Threat_HealTrigger = null
    private timer Threat_UpdateTimer = null
endglobals

private function Threat_IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

private function Threat_IsPlayerFactionUnit takes unit whichUnit returns boolean
    local integer playerIndex = 0
    local player whichPlayer = null
    local boolean result = false

    if not Threat_IsAlive(whichUnit) then
        return false
    endif

    loop
        exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS or result
        set whichPlayer = Player(playerIndex)
        if GetPlayerController(whichPlayer) == MAP_CONTROL_USER and GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING and IsUnitAlly(whichUnit, whichPlayer) then
            set result = true
        endif
        set playerIndex = playerIndex + 1
    endloop

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
    set Threat_LastActivityTick[tableId] = Threat_ClockTick
    set Threat_TableByTarget[GetHandleId(threatUnit)] = tableId
    return tableId
endfunction

private function Threat_ReleaseTable takes integer tableId returns nothing
    local integer position = 1
    local integer entryIndex
    local unit threatUnit = null

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
        set Threat_EntrySource[entryIndex] = null
        set Threat_EntryValue[entryIndex] = 0.00
        set position = position + 1
    endloop

    set Threat_TableActive[tableId] = false
    set Threat_Target[tableId] = null
    set Threat_AggroTarget[tableId] = null
    set Threat_EntryCount[tableId] = 0
    set Threat_LastActivityTick[tableId] = 0
    set Threat_FreeCount = Threat_FreeCount + 1
    set Threat_FreeTableId[Threat_FreeCount] = tableId
    set threatUnit = null
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

    if not THREAT_SHOW_AGGRO_TEXT or threatUnit == null or newTarget == null then
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
                return
            endif
            set position = lowestPosition
        endif
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set Threat_EntrySource[entryIndex] = source
        set Threat_EntryValue[entryIndex] = adjustedAmount
    else
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set Threat_EntryValue[entryIndex] = Threat_EntryValue[entryIndex] + adjustedAmount
    endif

    set Threat_LastActivityTick[tableId] = Threat_ClockTick
    call Threat_EvaluateAggro(tableId)
endfunction

private function Threat_IsEngagedWithAlly takes integer tableId, unit alliedUnit returns boolean
    local integer position = 1
    local integer entryIndex
    local player alliedOwner = null
    local boolean engaged = false

    if not Threat_TableActive[tableId] or alliedUnit == null then
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
    local integer tableId = 1
    local integer engagedCount = 0
    local real splitThreat

    if totalThreat <= 0.00 or source == null or alliedTarget == null or not IsUnitAlly(alliedTarget, GetOwningPlayer(source)) then
        return
    endif

    loop
        exitwhen tableId >= Threat_NextTableId
        if Threat_TableActive[tableId] and Threat_CanManageTarget(Threat_Target[tableId]) and IsUnitEnemy(source, GetOwningPlayer(Threat_Target[tableId])) and Threat_IsEngagedWithAlly(tableId, alliedTarget) then
            set engagedCount = engagedCount + 1
        endif
        set tableId = tableId + 1
    endloop

    if engagedCount <= 0 then
        return
    endif

    set splitThreat = totalThreat / I2R(engagedCount)
    set tableId = 1
    loop
        exitwhen tableId >= Threat_NextTableId
        if Threat_TableActive[tableId] and Threat_CanManageTarget(Threat_Target[tableId]) and IsUnitEnemy(source, GetOwningPlayer(Threat_Target[tableId])) and Threat_IsEngagedWithAlly(tableId, alliedTarget) then
            call Threat_AddInternal(Threat_Target[tableId], source, splitThreat)
        endif
        set tableId = tableId + 1
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
    set Threat_LastActivityTick[tableId] = Threat_ClockTick
    if Threat_EntryCount[tableId] <= 0 then
        call Threat_ReleaseTable(tableId)
    else
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
    local integer tableId = 1
    local integer position

    if source == null then
        return
    endif

    loop
        exitwhen tableId >= Threat_NextTableId
        if Threat_TableActive[tableId] then
            set position = Threat_FindEntry(tableId, source)
            if position > 0 then
                call Threat_RemoveEntry(tableId, position)
                if Threat_EntryCount[tableId] <= 0 then
                    call Threat_ReleaseTable(tableId)
                else
                    call Threat_EvaluateAggro(tableId)
                endif
            endif
        endif
        set tableId = tableId + 1
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
        set Threat_LastActivityTick[tableId] = Threat_ClockTick
        call Threat_SetAggroTarget(tableId, source)
    endif
endfunction

private function Threat_PruneTable takes integer tableId returns nothing
    local integer position = 1
    local integer entryIndex
    local unit source = null

    loop
        exitwhen position > Threat_EntryCount[tableId]
        set entryIndex = Threat_GetEntryIndex(tableId, position)
        set source = Threat_EntrySource[entryIndex]
        if not Threat_IsValidSource(Threat_Target[tableId], source) or not IsUnitInRange(Threat_Target[tableId], source, THREAT_LEASH_RANGE) then
            call Threat_RemoveEntry(tableId, position)
        else
            set position = position + 1
        endif
    endloop
    set source = null
endfunction

private function Threat_OnPeriodic takes nothing returns nothing
    local integer tableId = 1
    local unit threatUnit = null
    local unit aggroTarget = null

    set Threat_ClockTick = Threat_ClockTick + 1
    loop
        exitwhen tableId >= Threat_NextTableId
        if Threat_TableActive[tableId] then
            set threatUnit = Threat_Target[tableId]
            if not Threat_CanManageTarget(threatUnit) then
                call Threat_ReleaseTable(tableId)
            else
                call Threat_PruneTable(tableId)
                if Threat_EntryCount[tableId] <= 0 then
                    call Threat_ReleaseTable(tableId)
                elseif Threat_ClockTick - Threat_LastActivityTick[tableId] >= THREAT_IDLE_TICKS and GetUnitCurrentOrder(threatUnit) == 0 then
                    call Threat_ReleaseTable(tableId)
                else
                    call Threat_EvaluateAggro(tableId)
                    set aggroTarget = Threat_AggroTarget[tableId]
                    if aggroTarget != null and GetUnitCurrentOrder(threatUnit) == 0 and not IsUnitPaused(threatUnit) and not IsUnitType(threatUnit, UNIT_TYPE_STUNNED) then
                        call IssueTargetOrderById(threatUnit, THREAT_ATTACK_ORDER_ID, aggroTarget)
                    endif
                endif
            endif
        endif
        set tableId = tableId + 1
    endloop

    set threatUnit = null
    set aggroTarget = null
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
    set Threat_DisabledTarget = Table.create()
    set Threat_SourceMultiplier = Table.create()

    set Threat_HealTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(Threat_HealTrigger, "udg_AfterHealEvent", EQUAL, 1.00)
    call TriggerAddAction(Threat_HealTrigger, function Threat_OnHeal)

    set Threat_UpdateTimer = CreateTimer()
    call TimerStart(Threat_UpdateTimer, THREAT_UPDATE_INTERVAL, true, function Threat_OnPeriodic)

    call RegisterDamageEngine(function Threat_OnDamage, "After", 1.00)
    call Events_RegisterSpellEffect(function Threat_OnSpellEffect)
    call UnitDeathEvent_Register(function Threat_OnDeath)
endfunction

endlibrary
