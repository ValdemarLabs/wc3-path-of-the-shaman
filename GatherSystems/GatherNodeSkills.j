// ============================================================
// GatherNodeSkills - Profession Skill Tracking & Enforcement
// ============================================================

library GatherNodeSkills initializer Init requires GatherNodes, DamageEngine, ExSound, Table

globals
    private constant integer skillMin = 0
    private constant integer skillMax = 100
    private constant real GNS_FAILURE_COOLDOWN = 2.50

    constant integer GNS_PROF_NONE = 0
    constant integer GNS_PROF_MINING = 1
    constant integer GNS_PROF_HERBALISM = 2
    constant integer GNS_PROF_SKINNING = 3
    constant integer GNS_PROF_FISHING = 4
    constant integer GNS_PROF_ALCHEMY = 5
    constant integer GNS_PROF_BLACKSMITHING = 6
    constant integer GNS_PROF_LEATHERWORKING = 7
    constant integer GNS_PROF_ENCHANTING = 8
    constant integer GNS_PROF_COOKING = 9

    private Table GNS_SkillLevels
    private Table GNS_FailureThrottle
    private string array GNS_ProfessionNames
    private timer GNS_ClockTimer = null
    private real GNS_GlobalFailureUntil = 0.0

    private unit GNS_Nazgrek = null
    private unit GNS_Zulkis = null
    private unit GNS_LastSelectedUnit = null

    private trigger GNS_InitTrigger = null
    private trigger GNS_OrderTrigger = null
    private trigger GNS_AttackTrigger = null
    private trigger GNS_DamageTrigger = null
    private trigger GNS_ChatTrigger = null
    private trigger GNS_SelectTrigger = null
endglobals

private function GNS_NoOp takes nothing returns nothing
endfunction

private function GNS_GetSkillKey takes unit u, integer professionId returns integer
    return StringHash(I2S(GetHandleId(u)) + ":" + I2S(professionId))
endfunction

private function GNS_IsNazgrek takes unit u returns boolean
    if u == null then
        return false
    endif
    return u == GNS_Nazgrek or u == udg_Nazgrek
endfunction

private function GNS_IsZulkis takes unit u returns boolean
    if u == null then
        return false
    endif
    return u == GNS_Zulkis or u == udg_Zulkis
endfunction

function GNS_IsTrackedGatherer takes unit u returns boolean
    return GNS_IsNazgrek(u) or GNS_IsZulkis(u)
endfunction

function GNS_GetProfessionName takes integer professionId returns string
    if professionId < GNS_PROF_NONE or professionId > GNS_PROF_COOKING then
        return "None"
    endif
    return GNS_ProfessionNames[professionId]
endfunction

function GNS_GetSkill takes unit u, integer professionId returns integer
    local integer key

    if u == null or professionId <= GNS_PROF_NONE then
        return skillMin
    endif

    set key = GNS_GetSkillKey(u, professionId)
    if GNS_SkillLevels.has(key) then
        return GNS_SkillLevels.integer[key]
    endif

    return skillMin
endfunction

function GNS_SetSkill takes unit u, integer professionId, integer value returns nothing
    local integer key

    if u == null or professionId <= GNS_PROF_NONE then
        return
    endif

    if value < skillMin then
        set value = skillMin
    elseif value > skillMax then
        set value = skillMax
    endif

    set key = GNS_GetSkillKey(u, professionId)
    set GNS_SkillLevels.integer[key] = value
endfunction

function GNS_CanGatherNode takes unit u, integer professionId, integer requiredSkill returns boolean
    if not GNS_IsTrackedGatherer(u) then
        return true
    endif

    if professionId <= GNS_PROF_NONE then
        return true
    endif

    return GNS_GetSkill(u, professionId) >= requiredSkill
endfunction

private function GNS_GetDisplayName takes unit u returns string
    if u == null then
        return "Unknown"
    endif

    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif

    return GetUnitName(u)
endfunction

private function GNS_GetSkillGainChance takes integer currentSkill, integer requiredSkill returns integer
    if currentSkill <= requiredSkill then
        return 100
    endif
    if currentSkill <= requiredSkill + 15 then
        return 75
    endif
    if currentSkill <= requiredSkill + 30 then
        return 50
    endif
    if currentSkill <= requiredSkill + 45 then
        return 25
    endif
    return 0
endfunction

function GNS_AwardGatherSkillForNode takes unit u, integer professionId, integer requiredSkill, integer amount returns nothing
    local integer oldValue
    local integer newValue
    local integer gainChance

    if not GNS_IsTrackedGatherer(u) or professionId <= GNS_PROF_NONE or amount <= 0 then
        return
    endif

    set oldValue = GNS_GetSkill(u, professionId)
    set gainChance = GNS_GetSkillGainChance(oldValue, requiredSkill)
    if gainChance <= 0 or GetRandomInt(1, 100) > gainChance then
        return
    endif

    set newValue = oldValue + amount
    call GNS_SetSkill(u, professionId, newValue)
    set newValue = GNS_GetSkill(u, professionId)

    if newValue > oldValue then
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cff66ccff" + GNS_GetDisplayName(u) + " skill in " + GNS_GetProfessionName(professionId) + " has increased to " + I2S(newValue) + "|r")
    endif
endfunction

private function GNS_GetFailureSoundKey takes unit u returns string
    if GNS_IsNazgrek(u) then
        return "Nazgrek_GeneralError2"
    endif

    if GNS_IsZulkis(u) then
        return "Zulkis_GeneralError2"
    endif

    return ""
endfunction

private function GNS_ShouldSuppressFailure takes unit u returns boolean
    local integer handleId
    local real now

    if u == null then
        return true
    endif

    set handleId = GetHandleId(u)
    if GNS_ClockTimer == null then
        return false
    endif
    set now = TimerGetElapsed(GNS_ClockTimer)

    if GNS_GlobalFailureUntil > now then
        return true
    endif

    if GNS_FailureThrottle.has(handleId) and GNS_FailureThrottle.real[handleId] > now then
        return true
    endif

    set GNS_GlobalFailureUntil = now + GNS_FAILURE_COOLDOWN
    set GNS_FailureThrottle.real[handleId] = now + GNS_FAILURE_COOLDOWN
    return false
endfunction

private function GNS_ShowFailure takes unit u, string nodeName, integer requiredSkill returns nothing
    local string transmissionText
    local string requirementText
    local string soundKey

    if u == null then
        return
    endif

    if GNS_ShouldSuppressFailure(u) then
        return
    endif

    set transmissionText = "I'm unable to do that."
    if nodeName == null or nodeName == "" then
        set nodeName = "node"
    endif
    set requirementText = nodeName + " requires at least skill level of " + I2S(requiredSkill)
    set soundKey = GNS_GetFailureSoundKey(u)

    if soundKey != "" then
        call ExSound_Play(soundKey, transmissionText)
    else
        set udg_ExSoundDuration = 2.00
    endif

    call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, u, GNS_GetDisplayName(u), null, transmissionText, bj_TIMETYPE_SET, udg_ExSoundDuration, false)
    call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, requirementText)
endfunction

private function GNS_AbortGatherOrder takes unit u returns nothing
    if u == null then
        return
    endif

    call PauseUnit(u, true)
    call PauseUnit(u, false)
    call IssueImmediateOrder(u, "stop")
endfunction

function GNS_ShouldBlockItemPickup takes unit gatherer, item nodeItem returns boolean
    local integer professionId
    local integer requiredSkill

    if gatherer == null or nodeItem == null then
        return false
    endif

    if not GN_IsGatherItem(nodeItem) then
        return false
    endif

    if not GNS_IsTrackedGatherer(gatherer) then
        return false
    endif

    set professionId = GN_GetGatherItemProfessionId(nodeItem)
    set requiredSkill = GN_GetGatherItemSkillRequired(nodeItem)
    if GNS_CanGatherNode(gatherer, professionId, requiredSkill) then
        return false
    endif

    call GNS_ShowFailure(gatherer, GN_GetGatherItemName(nodeItem), requiredSkill)
    return true
endfunction

function GNS_ShouldBlockGatherUnit takes unit gatherer, unit node returns boolean
    local integer professionId
    local integer requiredSkill

    if gatherer == null or node == null then
        return false
    endif

    if not GN_IsGatherUnit(node) then
        return false
    endif

    if not GNS_IsTrackedGatherer(gatherer) then
        return false
    endif

    set professionId = GN_GetGatherUnitProfessionId(node)
    set requiredSkill = GN_GetGatherUnitSkillRequired(node)
    if GNS_CanGatherNode(gatherer, professionId, requiredSkill) then
        return false
    endif

    call GNS_ShowFailure(gatherer, GN_GetGatherUnitName(node), requiredSkill)
    return true
endfunction

function GNS_OnSuccessfulItemGather takes unit gatherer, item nodeItem returns nothing
    local integer professionId
    local integer requiredSkill

    if gatherer == null or nodeItem == null then
        return
    endif

    if not GN_IsGatherItem(nodeItem) then
        return
    endif

    if not GNS_IsTrackedGatherer(gatherer) then
        return
    endif

    set professionId = GN_GetGatherItemProfessionId(nodeItem)
    set requiredSkill = GN_GetGatherItemSkillRequired(nodeItem)
    if GNS_CanGatherNode(gatherer, professionId, requiredSkill) then
        call GNS_AwardGatherSkillForNode(gatherer, professionId, requiredSkill, 1)
    endif
endfunction

function GNS_OnSuccessfulMining takes unit gatherer, unit node returns nothing
    local integer professionId
    local integer requiredSkill

    if gatherer == null or node == null then
        return
    endif

    if not GN_IsGatherUnit(node) then
        return
    endif

    if not GNS_IsTrackedGatherer(gatherer) then
        return
    endif

    set professionId = GN_GetGatherUnitProfessionId(node)
    set requiredSkill = GN_GetGatherUnitSkillRequired(node)
    if GNS_CanGatherNode(gatherer, professionId, requiredSkill) then
        call GNS_AwardGatherSkillForNode(gatherer, professionId, requiredSkill, 1)
    endif
endfunction

function GNS_PrintSkills takes unit u returns nothing
    if u == null then
        call BJDebugMsg("|cffff8800[GatherNodeSkills]|r Missing tracked unit")
        return
    endif

    call BJDebugMsg("|cff00ff00[GatherNodeSkills]|r " + GNS_GetDisplayName(u))
    call BJDebugMsg("  Mining: " + I2S(GNS_GetSkill(u, GNS_PROF_MINING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Herbalism: " + I2S(GNS_GetSkill(u, GNS_PROF_HERBALISM)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Skinning: " + I2S(GNS_GetSkill(u, GNS_PROF_SKINNING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Fishing: " + I2S(GNS_GetSkill(u, GNS_PROF_FISHING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Alchemy: " + I2S(GNS_GetSkill(u, GNS_PROF_ALCHEMY)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Blacksmithing: " + I2S(GNS_GetSkill(u, GNS_PROF_BLACKSMITHING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Leatherworking: " + I2S(GNS_GetSkill(u, GNS_PROF_LEATHERWORKING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Enchanting: " + I2S(GNS_GetSkill(u, GNS_PROF_ENCHANTING)) + "/" + I2S(skillMax))
    call BJDebugMsg("  Cooking: " + I2S(GNS_GetSkill(u, GNS_PROF_COOKING)) + "/" + I2S(skillMax))
endfunction

private function GNS_GetSkillsTargetUnit takes nothing returns unit
    if GNS_IsTrackedGatherer(GNS_LastSelectedUnit) then
        return GNS_LastSelectedUnit
    endif

    if GNS_IsTrackedGatherer(udg_Nazgrek) then
        return udg_Nazgrek
    endif

    if GNS_IsTrackedGatherer(GNS_Nazgrek) then
        return GNS_Nazgrek
    endif

    if GNS_IsTrackedGatherer(udg_Zulkis) then
        return udg_Zulkis
    endif

    if GNS_IsTrackedGatherer(GNS_Zulkis) then
        return GNS_Zulkis
    endif

    return null
endfunction

function GNS_GetUITargetUnit takes nothing returns unit
    return GNS_GetSkillsTargetUnit()
endfunction

private function GNS_OnUnitSelected takes nothing returns nothing
    local unit u = GetTriggerUnit()

    if GNS_IsTrackedGatherer(u) then
        set GNS_LastSelectedUnit = u
    endif

    set u = null
endfunction

private function GNS_OnTargetOrder takes nothing returns nothing
    local unit ordered = GetTriggerUnit()
    local unit targetUnit = GetOrderTargetUnit()
    local item targetItem = GetOrderTargetItem()

    if not GNS_IsTrackedGatherer(ordered) then
        set ordered = null
        set targetUnit = null
        set targetItem = null
        return
    endif

    if targetItem != null then
        if GNS_ShouldBlockItemPickup(ordered, targetItem) then
            call GNS_AbortGatherOrder(ordered)
        endif
    elseif targetUnit != null then
        if GNS_ShouldBlockGatherUnit(ordered, targetUnit) then
            call GNS_AbortGatherOrder(ordered)
        endif
    endif

    set ordered = null
    set targetUnit = null
    set targetItem = null
endfunction

private function GNS_OnDamageModifier takes nothing returns nothing
    if not GNS_IsTrackedGatherer(udg_DamageEventSource) then
        return
    endif
    if udg_DamageEventTarget == null or not GN_IsGatherUnit(udg_DamageEventTarget) then
        return
    endif

    if GNS_ShouldBlockGatherUnit(udg_DamageEventSource, udg_DamageEventTarget) then
        set udg_DamageEventAmount = 0.0
        call GNS_AbortGatherOrder(udg_DamageEventSource)
    endif
endfunction

private function GNS_OnUnitAttacked takes nothing returns nothing
    local unit node = GetTriggerUnit()
    local unit attacker = GetAttacker()

    if attacker != null and node != null and GNS_ShouldBlockGatherUnit(attacker, node) then
        call GNS_AbortGatherOrder(attacker)
    endif

    set node = null
    set attacker = null
endfunction

private function GNS_OnChat takes nothing returns nothing
    local unit targetUnit

    if GetEventPlayerChatString() == "/skills" then
        call BJDebugMsg("|cff00ff00[GatherNodeSkills]|r === Gather Skills ===")
        set targetUnit = GNS_GetSkillsTargetUnit()
        call GNS_PrintSkills(targetUnit)
    endif
    set targetUnit = null
endfunction

private function GNS_RegisterProfessionNames takes nothing returns nothing
    set GNS_ProfessionNames[GNS_PROF_NONE] = "None"
    set GNS_ProfessionNames[GNS_PROF_MINING] = "Mining"
    set GNS_ProfessionNames[GNS_PROF_HERBALISM] = "Herbalism"
    set GNS_ProfessionNames[GNS_PROF_SKINNING] = "Skinning"
    set GNS_ProfessionNames[GNS_PROF_FISHING] = "Fishing"
    set GNS_ProfessionNames[GNS_PROF_ALCHEMY] = "Alchemy"
    set GNS_ProfessionNames[GNS_PROF_BLACKSMITHING] = "Blacksmithing"
    set GNS_ProfessionNames[GNS_PROF_LEATHERWORKING] = "Leatherworking"
    set GNS_ProfessionNames[GNS_PROF_ENCHANTING] = "Enchanting"
    set GNS_ProfessionNames[GNS_PROF_COOKING] = "Cooking"
endfunction

private function GNS_DelayedInit takes nothing returns nothing
    local integer playerIndex = 0

    set GNS_Nazgrek = udg_Nazgrek
    set GNS_Zulkis = udg_Zulkis

    set GNS_OrderTrigger = CreateTrigger()
    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(GNS_OrderTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(GNS_OrderTrigger, function GNS_OnTargetOrder)

    set GNS_AttackTrigger = CreateTrigger()
    set playerIndex = 0
    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(GNS_AttackTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_ATTACKED, null)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(GNS_AttackTrigger, function GNS_OnUnitAttacked)

    set GNS_DamageTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(GNS_DamageTrigger, "udg_DamageModifierEvent", EQUAL, 1.00)
    call TriggerAddAction(GNS_DamageTrigger, function GNS_OnDamageModifier)

    set GNS_SelectTrigger = CreateTrigger()
    call TriggerRegisterPlayerUnitEvent(GNS_SelectTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
    call TriggerAddAction(GNS_SelectTrigger, function GNS_OnUnitSelected)

    set GNS_ChatTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(GNS_ChatTrigger, Player(0), "/skills", false)
    call TriggerAddAction(GNS_ChatTrigger, function GNS_OnChat)

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeSkills]|r Skills initialized for Nazgrek and Zulkis")
    endif
endfunction

private function Init takes nothing returns nothing
    set GNS_SkillLevels = Table.create()
    set GNS_FailureThrottle = Table.create()
    set GNS_ClockTimer = CreateTimer()
    call TimerStart(GNS_ClockTimer, 999999.0, false, function GNS_NoOp)
    call GNS_RegisterProfessionNames()

    set GNS_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(GNS_InitTrigger, 0.10, false)
    call TriggerAddAction(GNS_InitTrigger, function GNS_DelayedInit)
endfunction

endlibrary
