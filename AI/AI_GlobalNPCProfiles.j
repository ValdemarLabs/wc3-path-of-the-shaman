/**
    AI_GlobalNPCProfiles

    Author: Valdemar
    Version: 1.4.0

    Description:
    Trait-based default profiles for unclaimed global NPCs. The classifier
    uses attack availability and a reviewed Object Editor spell registry to
    choose a conservative simple role when an NPC first attacks, is attacked,
    deals damage, or receives damage. Explicit AI profiles keep priority,
    unknown combat units use `AI_Generic`, and units without an attack receive
    no global AI profile.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AI_Register.j`, Events, and DamageEngine. Global NPCs are
    registered lazily on their first attack or positive damage event; no
    startup/index scan is performed. Systems that take direct order ownership
    should exclude their units through `AIRegister`.

    API:
    call AIGlobalNPCProfiles_ActivateUnit(whichUnit) returns integer
    call AIGlobalNPCProfiles_QueueUnit(whichUnit)
    call AIGlobalNPCProfiles_QueueWorldScan() // Explicit maintenance only
    call AIGlobalNPCProfiles_SetDefaultProfile(profileSelection)
    call AIGlobalNPCProfiles_SetUnitTypeProfile(unitTypeId, profileSelection) returns integer // Stored normalized selection
    call AIGlobalNPCProfiles_ClearUnitTypeProfile(unitTypeId)
    call AIGlobalNPCProfiles_SetCasterType(unitTypeId, abilityId, order, cooldown, range)
    call AIGlobalNPCProfiles_SetHealerType(unitTypeId, abilityId, order, cooldown, range, threshold)
    call AIGlobalNPCProfiles_ClearSpecialistType(unitTypeId)
    call AIGlobalNPCProfiles_DisableUnit(whichUnit)
    call AIGlobalNPCProfiles_EnableUnit(whichUnit)
    call AIGlobalNPCProfiles_GetCombatStyle(whichUnit) returns integer
    call AIGlobalNPCProfiles_GetAbilityCount(whichUnit) returns integer
    call AIGlobalNPCProfiles_InferRole(whichUnit) returns integer

    Profile selections:
    AI_GLOBAL_NPC_PROFILE_DEFAULT uses AI_Generic for missing manager data.
    AI_GLOBAL_NPC_PROFILE_AUTO enables trait classification.
    AI_GLOBAL_NPC_PROFILE_NONE disables future automatic AI activation for the
    unit type without removing an existing instance or an explicit profile.
    AI_REGISTER_ROLE_GENERIC through AI_REGISTER_ROLE_VENDOR select a
    non-specialist simple role; caster/healer behavior requires reviewed spell
    configuration through the specialist setters.
    The startup default is AUTO. Profile selection is applied when an inactive
    NPC first participates in an attack or positive damage event. Manager and
    specialist setters only store configuration; they never scan the world or
    replace an already claimed unit type.

**/
library AIGlobalNPCProfiles initializer Init requires AIRegister, Table, Events, DamageEngine

globals
    constant integer AI_GLOBAL_NPC_PROFILE_DEFAULT = -2
    constant integer AI_GLOBAL_NPC_PROFILE_AUTO = -1
    constant integer AI_GLOBAL_NPC_PROFILE_NONE = 0

    constant integer AI_GLOBAL_NPC_STYLE_NONCOMBAT = 1
    constant integer AI_GLOBAL_NPC_STYLE_MELEE = 2
    constant integer AI_GLOBAL_NPC_STYLE_RANGED = 3
    constant integer AI_GLOBAL_NPC_STYLE_CASTER = 4

    // Conservative automatic-classification thresholds.
    private constant real RANGED_ATTACK_THRESHOLD = 300.00
    private constant integer CASTER_ABILITY_THRESHOLD = 2
    private constant integer MAX_COUNTED_ABILITIES = 24
    private constant integer REGISTRATION_BUDGET_PER_TICK = 16
    private constant real REGISTRATION_BATCH_INTERVAL = 0.03

    private group PendingUnits = null
    private timer PendingTimer = null
    private integer DefaultProfileSelection = AI_GLOBAL_NPC_PROFILE_AUTO
    private Table ProfileSelectionByUnitType = 0
    private Table HasProfileSelection = 0
    private Table SpecialistRoleByUnitType = 0
    private Table SpecialistAbilityByUnitType = 0
    private Table SpecialistOrderByUnitType = 0
    private Table SpecialistCooldownByUnitType = 0
    private Table SpecialistRangeByUnitType = 0
    private Table SpecialistThresholdByUnitType = 0
    private Table RealizedSpecialistProfileByUnitType = 0
    private Table RealizedSpecialistRoleByUnitType = 0
    private Table RealizedSpecialistAbilityByUnitType = 0
endglobals

private function IsIgnoredAbility takes integer abilityId returns boolean
    return abilityId == 0 or abilityId == 'Amov' or abilityId == 'Aatk' or abilityId == 'AInv' or abilityId == 'AHer' or abilityId == 'Aloc' or abilityId == 'Avul' or abilityId == 'Aneu' or abilityId == 'Awan'
endfunction

public function GetAbilityCount takes unit whichUnit returns integer
    local ability whichAbility
    local integer abilityId
    local integer index = 0
    local integer count = 0
    if whichUnit == null then
        return 0
    endif
    set whichAbility = BlzGetUnitAbilityByIndex(whichUnit, index)
    loop
        exitwhen whichAbility == null or count >= MAX_COUNTED_ABILITIES
        set abilityId = BlzGetAbilityId(whichAbility)
        if not IsIgnoredAbility(abilityId) then
            set count = count + 1
        endif
        set index = index + 1
        set whichAbility = BlzGetUnitAbilityByIndex(whichUnit, index)
    endloop
    set whichAbility = null
    return count
endfunction

private function HasAttack takes unit whichUnit returns boolean
    return BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0) or BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 1)
endfunction

private function HasMagicAttack takes unit whichUnit returns boolean
    if BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0) and BlzGetUnitWeaponIntegerField(whichUnit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0) == GetHandleId(ATTACK_TYPE_MAGIC) then
        return true
    endif
    return BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 1) and BlzGetUnitWeaponIntegerField(whichUnit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 1) == GetHandleId(ATTACK_TYPE_MAGIC)
endfunction

private function HasRangedAttack takes unit whichUnit returns boolean
    if IsUnitType(whichUnit, UNIT_TYPE_RANGED_ATTACKER) then
        return true
    endif
    if BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0) and BlzGetUnitWeaponRealField(whichUnit, UNIT_WEAPON_RF_ATTACK_RANGE, 0) >= RANGED_ATTACK_THRESHOLD then
        return true
    endif
    return BlzGetUnitWeaponBooleanField(whichUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 1) and BlzGetUnitWeaponRealField(whichUnit, UNIT_WEAPON_RF_ATTACK_RANGE, 1) >= RANGED_ATTACK_THRESHOLD
endfunction

public function GetCombatStyle takes unit whichUnit returns integer
    local integer abilityCount
    local boolean hasMana
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return AI_GLOBAL_NPC_STYLE_NONCOMBAT
    endif
    if not HasAttack(whichUnit) then
        return AI_GLOBAL_NPC_STYLE_NONCOMBAT
    endif
    set abilityCount = AIGlobalNPCProfiles_GetAbilityCount(whichUnit)
    set hasMana = GetUnitState(whichUnit, UNIT_STATE_MAX_MANA) > 0.00
    if hasMana and (abilityCount >= CASTER_ABILITY_THRESHOLD or HasMagicAttack(whichUnit)) then
        return AI_GLOBAL_NPC_STYLE_CASTER
    endif
    if HasRangedAttack(whichUnit) then
        return AI_GLOBAL_NPC_STYLE_RANGED
    endif
    return AI_GLOBAL_NPC_STYLE_MELEE
endfunction

private function IsCandidate takes unit whichUnit returns boolean
    local integer unitTypeId
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return false
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    if GetWidgetLife(whichUnit) <= 0.405 or IsUnitType(whichUnit, UNIT_TYPE_HERO) or IsUnitType(whichUnit, UNIT_TYPE_STRUCTURE) or IsUnitType(whichUnit, UNIT_TYPE_SUMMONED) or GetUnitAbilityLevel(whichUnit, 'Aloc') > 0 or not HasAttack(whichUnit) then
        return false
    endif
    if GetPlayerController(GetOwningPlayer(whichUnit)) == MAP_CONTROL_USER or AIRegister_IsUnitTypeExcluded(unitTypeId) or AIRegister_IsUnitExcluded(whichUnit) then
        return false
    endif
    return true
endfunction

public function InferRole takes unit whichUnit returns integer
    local integer style = AIGlobalNPCProfiles_GetCombatStyle(whichUnit)
    if style == AI_GLOBAL_NPC_STYLE_NONCOMBAT then
        return 0
    endif
    // Guard/aggressive intent cannot be inferred safely from combat stats.
    return AI_REGISTER_ROLE_GENERIC
endfunction

private function GetStyleName takes integer style returns string
    if style == AI_GLOBAL_NPC_STYLE_NONCOMBAT then
        return "Auto No AI"
    elseif style == AI_GLOBAL_NPC_STYLE_MELEE then
        return "Auto Melee"
    elseif style == AI_GLOBAL_NPC_STYLE_RANGED then
        return "Auto Ranged"
    elseif style == AI_GLOBAL_NPC_STYLE_CASTER then
        return "Auto Caster Fallback"
    endif
    return "Auto Generic"
endfunction

private function NormalizeSimpleProfile takes integer profileSelection returns integer
    if profileSelection < AI_REGISTER_ROLE_GENERIC or profileSelection > AI_REGISTER_ROLE_VENDOR then
        return AI_REGISTER_ROLE_GENERIC
    endif
    return profileSelection
endfunction

public function SetCasterType takes integer unitTypeId, integer abilityId, string order, real cooldown, real range returns nothing
    if unitTypeId == 0 or abilityId == 0 or order == null or order == "" then
        return
    endif
    set SpecialistRoleByUnitType[unitTypeId] = AI_REGISTER_ROLE_CASTER
    set SpecialistAbilityByUnitType[unitTypeId] = abilityId
    set SpecialistOrderByUnitType.string[unitTypeId] = order
    set SpecialistCooldownByUnitType.real[unitTypeId] = cooldown
    set SpecialistRangeByUnitType.real[unitTypeId] = range
    call SpecialistThresholdByUnitType.real.remove(unitTypeId)
endfunction

public function SetHealerType takes integer unitTypeId, integer abilityId, string order, real cooldown, real range, real threshold returns nothing
    if unitTypeId == 0 or abilityId == 0 or order == null or order == "" then
        return
    endif
    set SpecialistRoleByUnitType[unitTypeId] = AI_REGISTER_ROLE_HEALER
    set SpecialistAbilityByUnitType[unitTypeId] = abilityId
    set SpecialistOrderByUnitType.string[unitTypeId] = order
    set SpecialistCooldownByUnitType.real[unitTypeId] = cooldown
    set SpecialistRangeByUnitType.real[unitTypeId] = range
    set SpecialistThresholdByUnitType.real[unitTypeId] = threshold
endfunction

public function ClearSpecialistType takes integer unitTypeId returns nothing
    call SpecialistRoleByUnitType.remove(unitTypeId)
    call SpecialistAbilityByUnitType.remove(unitTypeId)
    call SpecialistOrderByUnitType.string.remove(unitTypeId)
    call SpecialistCooldownByUnitType.real.remove(unitTypeId)
    call SpecialistRangeByUnitType.real.remove(unitTypeId)
    call SpecialistThresholdByUnitType.real.remove(unitTypeId)
endfunction

private function RegisterConfiguredSpecialist takes unit whichUnit returns integer
    local integer unitTypeId = GetUnitTypeId(whichUnit)
    local integer role = SpecialistRoleByUnitType[unitTypeId]
    local integer abilityId = SpecialistAbilityByUnitType[unitTypeId]
    local integer profileId = 0
    local string order
    if role <= 0 or abilityId == 0 or GetUnitAbilityLevel(whichUnit, abilityId) <= 0 then
        return 0
    endif
    set order = SpecialistOrderByUnitType.string[unitTypeId]
    if order == "" then
        return 0
    endif
    if role == AI_REGISTER_ROLE_CASTER then
        set profileId = AIRegister_RegisterInferredCasterType(unitTypeId, "Object Data Caster", abilityId, order, SpecialistCooldownByUnitType.real[unitTypeId], SpecialistRangeByUnitType.real[unitTypeId])
    elseif role == AI_REGISTER_ROLE_HEALER then
        set profileId = AIRegister_RegisterInferredHealerType(unitTypeId, "Object Data Healer", abilityId, order, SpecialistCooldownByUnitType.real[unitTypeId], SpecialistRangeByUnitType.real[unitTypeId], SpecialistThresholdByUnitType.real[unitTypeId])
    endif
    if profileId > 0 and AIRegister_IsInferredType(unitTypeId) then
        set RealizedSpecialistProfileByUnitType[unitTypeId] = profileId
        set RealizedSpecialistRoleByUnitType[unitTypeId] = role
        set RealizedSpecialistAbilityByUnitType[unitTypeId] = abilityId
    endif
    return profileId
endfunction

private function IsRealizedSpecialistInstance takes unit whichUnit, integer role returns boolean
    local integer unitTypeId
    local integer abilityId
    if whichUnit == null or (role != AI_REGISTER_ROLE_CASTER and role != AI_REGISTER_ROLE_HEALER) then
        return false
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    set abilityId = RealizedSpecialistAbilityByUnitType[unitTypeId]
    if RealizedSpecialistRoleByUnitType[unitTypeId] != role or abilityId == 0 then
        return false
    endif
    return GetUnitAbilityLevel(whichUnit, abilityId) > 0
endfunction

private function ApplyAutomaticProfile takes unit whichUnit returns integer
    local integer unitTypeId
    local integer role
    local integer profileId
    local integer style
    local integer profileSelection
    if not IsCandidate(whichUnit) then
        return 0
    endif
    if AI_GetInstance(whichUnit) > 0 then
        return AI_GetInstance(whichUnit)
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    set profileId = AI_GetUnitTypeDefaultProfile(unitTypeId)
    if profileId > 0 and not AIRegister_IsOwnedProfile(profileId) then
        return AI_RegisterUnitByType(whichUnit, 0)
    endif
    set role = AIRegister_GetRole(unitTypeId)
    if HasProfileSelection.boolean[unitTypeId] then
        set profileSelection = ProfileSelectionByUnitType[unitTypeId]
    else
        set profileSelection = DefaultProfileSelection
    endif
    if profileSelection == AI_GLOBAL_NPC_PROFILE_NONE and (role <= 0 or AIRegister_IsInferredType(unitTypeId)) then
        return 0
    endif
    if AIRegister_IsInferredType(unitTypeId) and RealizedSpecialistProfileByUnitType[unitTypeId] == AIRegister_GetProfile(unitTypeId) and not IsRealizedSpecialistInstance(whichUnit, role) then
        return 0
    endif
    if role <= 0 then
        if profileSelection == AI_GLOBAL_NPC_PROFILE_AUTO then
            set style = AIGlobalNPCProfiles_GetCombatStyle(whichUnit)
            if style == AI_GLOBAL_NPC_STYLE_NONCOMBAT then
                return 0
            endif
            if SpecialistRoleByUnitType[unitTypeId] > 0 then
                set profileId = RegisterConfiguredSpecialist(whichUnit)
                if profileId <= 0 then
                    return 0
                endif
                set role = AIRegister_GetRole(unitTypeId)
            else
                set role = AIGlobalNPCProfiles_InferRole(whichUnit)
                if role <= 0 then
                    return 0
                endif
                set profileId = AIRegister_RegisterInferredType(unitTypeId, role, GetStyleName(style))
            endif
        else
            set role = NormalizeSimpleProfile(profileSelection)
            set profileId = AIRegister_RegisterInferredType(unitTypeId, role, "Default")
        endif
        if profileId <= 0 then
            set role = AI_REGISTER_ROLE_GENERIC
            set profileId = AIRegister_RegisterInferredType(unitTypeId, role, "Auto Generic")
        endif
    endif
    if profileId <= 0 then
        set profileId = AIRegister_GetProfile(unitTypeId)
    endif
    if profileId <= 0 then
        return 0
    endif
    return AIRegister_RegisterUnit(whichUnit, role)
endfunction

public function ActivateUnit takes unit whichUnit returns integer
    return ApplyAutomaticProfile(whichUnit)
endfunction

private function ProcessPending takes nothing returns nothing
    local unit whichUnit
    local integer processed = 0
    loop
        exitwhen processed >= REGISTRATION_BUDGET_PER_TICK
        set whichUnit = FirstOfGroup(PendingUnits)
        exitwhen whichUnit == null
        call GroupRemoveUnit(PendingUnits, whichUnit)
        call ApplyAutomaticProfile(whichUnit)
        set processed = processed + 1
    endloop
    if FirstOfGroup(PendingUnits) == null then
        call DestroyTimer(PendingTimer)
        set PendingTimer = null
    else
        call TimerStart(PendingTimer, REGISTRATION_BATCH_INTERVAL, false, function ProcessPending)
    endif
    set whichUnit = null
endfunction

public function QueueUnit takes unit whichUnit returns nothing
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif
    call GroupAddUnit(PendingUnits, whichUnit)
    if PendingTimer == null then
        set PendingTimer = CreateTimer()
        call TimerStart(PendingTimer, 0.00, false, function ProcessPending)
    endif
endfunction

public function QueueWorldScan takes nothing returns nothing
    local rect worldBounds = GetWorldBounds()
    call GroupEnumUnitsInRect(PendingUnits, worldBounds, null)
    if PendingTimer == null then
        set PendingTimer = CreateTimer()
        call TimerStart(PendingTimer, 0.00, false, function ProcessPending)
    endif
    set worldBounds = null
endfunction

public function SetDefaultProfile takes integer profileSelection returns nothing
    if profileSelection == AI_GLOBAL_NPC_PROFILE_AUTO or profileSelection == AI_GLOBAL_NPC_PROFILE_NONE then
        set DefaultProfileSelection = profileSelection
    else
        set DefaultProfileSelection = NormalizeSimpleProfile(profileSelection)
    endif
endfunction

public function SetUnitTypeProfile takes integer unitTypeId, integer profileSelection returns integer
    if unitTypeId == 0 then
        return 0
    endif
    if profileSelection != AI_GLOBAL_NPC_PROFILE_NONE and profileSelection != AI_GLOBAL_NPC_PROFILE_AUTO then
        set profileSelection = NormalizeSimpleProfile(profileSelection)
    endif
    set ProfileSelectionByUnitType[unitTypeId] = profileSelection
    set HasProfileSelection.boolean[unitTypeId] = true
    return profileSelection
endfunction

public function ClearUnitTypeProfile takes integer unitTypeId returns nothing
    if unitTypeId == 0 then
        return
    endif
    call ProfileSelectionByUnitType.remove(unitTypeId)
    call HasProfileSelection.boolean.remove(unitTypeId)
endfunction

private function ConfigureExportedSpecialists takes nothing returns nothing
    // Reviewed matching 2026-09-20 W3U/W3A exports. Profiles remain lazy.
    call AIGlobalNPCProfiles_SetCasterType('n00L', 'A6EN', "firebolt", 2.00, 700.00)
    call AIGlobalNPCProfiles_SetCasterType('n01O', 'ACcr', "cripple", 10.00, 600.00)
    call AIGlobalNPCProfiles_SetCasterType('n027', 'A03C', "firebolt", 2.00, 700.00)
    call AIGlobalNPCProfiles_SetCasterType('n60K', 'ACcr', "cripple", 10.00, 600.00)
    call AIGlobalNPCProfiles_SetCasterType('n60V', 'ACcr', "cripple", 10.00, 600.00)
    call AIGlobalNPCProfiles_SetCasterType('n61H', 'ACfb', "firebolt", 2.00, 700.00)
    call AIGlobalNPCProfiles_SetCasterType('n640', 'A6AK', "firebolt", 15.00, 1500.00)
    call AIGlobalNPCProfiles_SetCasterType('n65V', 'A6EM', "firebolt", 2.00, 700.00)
    call AIGlobalNPCProfiles_SetCasterType('n65W', 'A6EN', "firebolt", 2.00, 700.00)
    call AIGlobalNPCProfiles_SetHealerType('n00P', 'A02S', "holybolt", 3.00, 700.00, 65.00)
    call AIGlobalNPCProfiles_SetHealerType('n62A', 'ACrj', "rejuvenation", 10.00, 600.00, 70.00)
    call AIGlobalNPCProfiles_SetHealerType('o01O', 'A00D', "holybolt", 3.00, 700.00, 65.00)
endfunction

public function DisableUnit takes unit whichUnit returns nothing
    call AIRegister_ExcludeUnit(whichUnit)
endfunction

public function EnableUnit takes unit whichUnit returns nothing
    call AIRegister_AllowUnit(whichUnit)
endfunction

private function ActivateCombatUnit takes unit whichUnit, unit opponent, boolean react returns nothing
    if whichUnit == null or opponent == null or AI_GetInstance(whichUnit) > 0 then
        return
    endif
    if AIGlobalNPCProfiles_ActivateUnit(whichUnit) > 0 then
        if react then
            call AI_HandleLightweightAttack(whichUnit, opponent)
        endif
    endif
endfunction

private function OnUnitAttacked takes nothing returns nothing
    local unit attacked = GetTriggerUnit()
    local unit attacker = GetAttacker()

    // AI's earlier attack callback could not react before lazy registration.
    call ActivateCombatUnit(attacked, attacker, true)
    call ActivateCombatUnit(attacker, attacked, false)

    set attacked = null
    set attacker = null
endfunction

private function OnDamage takes nothing returns nothing
    local unit attacked = udg_DamageEventTarget
    local unit attacker = udg_DamageEventSource

    if udg_DamageEventAmount > 0.00 then
        call ActivateCombatUnit(attacked, attacker, true)
        call ActivateCombatUnit(attacker, attacked, false)
    endif

    set attacked = null
    set attacker = null
endfunction

private function Init takes nothing returns nothing
    set ProfileSelectionByUnitType = Table.create()
    set HasProfileSelection = Table.create()
    set SpecialistRoleByUnitType = Table.create()
    set SpecialistAbilityByUnitType = Table.create()
    set SpecialistOrderByUnitType = Table.create()
    set SpecialistCooldownByUnitType = Table.create()
    set SpecialistRangeByUnitType = Table.create()
    set SpecialistThresholdByUnitType = Table.create()
    set RealizedSpecialistProfileByUnitType = Table.create()
    set RealizedSpecialistRoleByUnitType = Table.create()
    set RealizedSpecialistAbilityByUnitType = Table.create()
    set PendingUnits = CreateGroup()
    call ConfigureExportedSpecialists()
    call Events_RegisterPlayerUnitEvent(function OnUnitAttacked, EVENT_PLAYER_UNIT_ATTACKED)
    call RegisterDamageEngine(function OnDamage, "After", 1.00)
endfunction

endlibrary
