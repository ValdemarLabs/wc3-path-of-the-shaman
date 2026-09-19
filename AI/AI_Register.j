/**
    AI_Register

    Author: Valdemar
    Version: 1.3.0

    Description:
    Central unit-type classifier for simple global NPC AI. Registered types use
    the matching `AI/Generic` profile factory and `AI.j` default-profile lookup,
    so pre-placed, created, sold, and replacement units are initialized through
    the existing unit-index lifecycle. Existing class/specific AI profiles are
    never replaced. Heroes, structures, excluded types, and excluded instances
    are deliberately left to their owning systems. Registry-owned profiles use
    the lightweight AI processing tier rather than full hero AI state.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AI.j`, `Table`, `QuestGiver.j`, and the generic AI profile
    libraries. Systems that know an NPC's role should optionally require
    `AIRegister` and call one of the role helpers when they register that NPC or
    unit type. Each registered type should represent one consistent NPC role.

    API:
    call AIRegister_RegisterType(unitTypeId, role, profileName)
    call AIRegister_RegisterInferredType(unitTypeId, role, profileName)
    call AIRegister_RegisterGenericType(unitTypeId, profileName)
    call AIRegister_RegisterAggressiveType(unitTypeId, profileName)
    call AIRegister_RegisterPassiveType(unitTypeId, profileName)
    call AIRegister_RegisterCivilianType(unitTypeId, profileName)
    call AIRegister_RegisterGuardType(unitTypeId, profileName)
    call AIRegister_RegisterScriptedType(unitTypeId, profileName)
    call AIRegister_RegisterVendorType(unitTypeId, profileName)
    call AIRegister_RegisterCasterType(unitTypeId, profileName, abilityId, order, cooldown, range)
    call AIRegister_RegisterHealerType(unitTypeId, profileName, abilityId, order, cooldown, range, threshold)
    call AIRegister_RegisterUnit(whichUnit, fallbackRole)
    call AIRegister_RegisterGenericUnit(whichUnit)
    call AIRegister_RegisterScriptedUnit(whichUnit)
    call AIRegister_RegisterVendorUnit(whichUnit)
    call AIRegister_ExcludeUnitType(unitTypeId)
    call AIRegister_AllowUnitType(unitTypeId)
    call AIRegister_ResetUnitType(unitTypeId)
    call AIRegister_ExcludeUnit(whichUnit)
    call AIRegister_AllowUnit(whichUnit)
    call AIRegister_IsUnitTypeExcluded(unitTypeId) returns boolean
    call AIRegister_IsUnitExcluded(whichUnit) returns boolean
    call AIRegister_IsOwnedProfile(profileId) returns boolean
    call AIRegister_GetRole(unitTypeId) returns integer
    call AIRegister_GetProfile(unitTypeId) returns integer

**/
library AIRegister initializer Init requires AI, Table, QuestGiver, AIGeneric, AIAggressive, AIPassive, AICivilian, AIGuard, AIScripted, AIVendor, AIGenericCaster, AIGenericHealer

globals
    constant integer AI_REGISTER_ROLE_GENERIC = 1
    constant integer AI_REGISTER_ROLE_AGGRESSIVE = 2
    constant integer AI_REGISTER_ROLE_PASSIVE = 3
    constant integer AI_REGISTER_ROLE_CIVILIAN = 4
    constant integer AI_REGISTER_ROLE_GUARD = 5
    constant integer AI_REGISTER_ROLE_SCRIPTED = 6
    constant integer AI_REGISTER_ROLE_VENDOR = 7
    constant integer AI_REGISTER_ROLE_CASTER = 8
    constant integer AI_REGISTER_ROLE_HEALER = 9

    // Shared classification and ownership state.
    private Table RoleByUnitType = 0
    private Table ProfileByUnitType = 0
    private Table OwnedProfile = 0
    private Table ExcludedUnitType = 0
    private Table ExcludedUnit = 0
    private group ScanGroup = null
    private timer ScanTimer = null
    private trigger UnitDeindexTrigger = null
endglobals

private function IsSimpleNpcType takes integer unitTypeId returns boolean
    return unitTypeId != 0 and not IsUnitIdType(unitTypeId, UNIT_TYPE_HERO) and not IsUnitIdType(unitTypeId, UNIT_TYPE_STRUCTURE)
endfunction

private function NormalizeRole takes integer role returns integer
    if role < AI_REGISTER_ROLE_GENERIC or role > AI_REGISTER_ROLE_HEALER then
        return AI_REGISTER_ROLE_GENERIC
    endif
    return role
endfunction

private function GetRoleName takes integer role returns string
    if role == AI_REGISTER_ROLE_AGGRESSIVE then
        return "Aggressive"
    elseif role == AI_REGISTER_ROLE_PASSIVE then
        return "Passive"
    elseif role == AI_REGISTER_ROLE_CIVILIAN then
        return "Civilian"
    elseif role == AI_REGISTER_ROLE_GUARD then
        return "Guard"
    elseif role == AI_REGISTER_ROLE_SCRIPTED then
        return "Scripted"
    elseif role == AI_REGISTER_ROLE_VENDOR then
        return "Vendor"
    elseif role == AI_REGISTER_ROLE_CASTER then
        return "Caster"
    elseif role == AI_REGISTER_ROLE_HEALER then
        return "Healer"
    endif
    return "Generic"
endfunction

private function GetProfileName takes integer unitTypeId, integer role, string requestedName returns string
    if requestedName != null and requestedName != "" then
        return requestedName + ":" + I2S(unitTypeId)
    endif
    return "Global NPC " + GetRoleName(role) + ":" + I2S(unitTypeId)
endfunction

private function CreateSimpleProfile takes integer unitTypeId, integer role, string profileName returns integer
    if role == AI_REGISTER_ROLE_AGGRESSIVE then
        return AIAggressive_RegisterProfile(unitTypeId, profileName, false)
    elseif role == AI_REGISTER_ROLE_PASSIVE then
        return AIPassive_RegisterProfile(unitTypeId, profileName)
    elseif role == AI_REGISTER_ROLE_CIVILIAN then
        return AICivilian_RegisterProfile(unitTypeId, profileName)
    elseif role == AI_REGISTER_ROLE_GUARD then
        return AIGuard_RegisterProfile(unitTypeId, profileName)
    elseif role == AI_REGISTER_ROLE_SCRIPTED then
        return AIScripted_RegisterProfile(unitTypeId, profileName)
    elseif role == AI_REGISTER_ROLE_VENDOR then
        return AIVendor_RegisterProfile(unitTypeId, profileName)
    endif
    return AIGeneric_RegisterProfile(unitTypeId, profileName, false)
endfunction

private function RegisterProfile takes integer unitTypeId, integer role, integer profileId returns integer
    if profileId <= 0 then
        return 0
    endif
    set RoleByUnitType[unitTypeId] = role
    set ProfileByUnitType[unitTypeId] = profileId
    set OwnedProfile.boolean[profileId] = true
    call AI_SetProfileAutomaticRevive(profileId, false)
    call AI_SetProfileGlobalNpcOnly(profileId, true)
    call AI_SetProfileLightweight(profileId, true)
    call AI_SetProfileLightweightPeriodic(profileId, role == AI_REGISTER_ROLE_CASTER or role == AI_REGISTER_ROLE_HEALER)
    call AI_SetUnitTypeDefaultProfile(unitTypeId, profileId)
    return profileId
endfunction

private function RegisterSimpleTypeInternal takes integer unitTypeId, integer role, string profileName, boolean replaceOwned returns integer
    local integer existingRole
    local integer defaultProfile
    local integer profileId
    if ExcludedUnitType.boolean[unitTypeId] or not IsSimpleNpcType(unitTypeId) then
        return 0
    endif
    set role = NormalizeRole(role)
    if role == AI_REGISTER_ROLE_CASTER or role == AI_REGISTER_ROLE_HEALER then
        set role = AI_REGISTER_ROLE_GENERIC
    endif
    set defaultProfile = AI_GetUnitTypeDefaultProfile(unitTypeId)
    if defaultProfile > 0 and not OwnedProfile.boolean[defaultProfile] then
        call RoleByUnitType.remove(unitTypeId)
        call ProfileByUnitType.remove(unitTypeId)
        return defaultProfile
    endif
    set existingRole = RoleByUnitType[unitTypeId]
    if existingRole == role then
        return ProfileByUnitType[unitTypeId]
    endif
    if existingRole > 0 and not replaceOwned then
        return ProfileByUnitType[unitTypeId]
    endif
    set profileName = GetProfileName(unitTypeId, role, profileName)
    set profileId = CreateSimpleProfile(unitTypeId, role, profileName)
    return RegisterProfile(unitTypeId, role, profileId)
endfunction

private function ScanUnit takes unit whichUnit returns integer
    local integer unitTypeId
    local integer profileId
    local integer existingProfile
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return 0
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    set existingProfile = AI_GetProfileId(whichUnit)
    if ExcludedUnit.boolean[GetHandleId(whichUnit)] or ExcludedUnitType.boolean[unitTypeId] or not IsSimpleNpcType(unitTypeId) then
        if existingProfile > 0 and OwnedProfile.boolean[existingProfile] then
            call AI_UnregisterUnit(whichUnit)
        endif
        return 0
    endif
    set profileId = ProfileByUnitType[unitTypeId]
    if profileId <= 0 then
        set profileId = AI_GetUnitTypeDefaultProfile(unitTypeId)
        if profileId > 0 then
            if existingProfile > 0 and OwnedProfile.boolean[existingProfile] and not OwnedProfile.boolean[profileId] then
                call AI_UnregisterUnit(whichUnit)
                return AI_RegisterUnit(whichUnit, profileId, 0)
            elseif existingProfile <= 0 then
                return AI_RegisterUnit(whichUnit, profileId, 0)
            endif
        endif
        if existingProfile > 0 and OwnedProfile.boolean[existingProfile] then
            call AI_UnregisterUnit(whichUnit)
        endif
        return AI_GetInstance(whichUnit)
    endif
    if existingProfile == profileId then
        return AI_GetInstance(whichUnit)
    endif
    if existingProfile > 0 then
        if not OwnedProfile.boolean[existingProfile] then
            return AI_GetInstance(whichUnit)
        endif
        call AI_UnregisterUnit(whichUnit)
    endif
    return AI_RegisterUnit(whichUnit, profileId, 0)
endfunction

private function ScanAll takes nothing returns nothing
    local rect worldBounds = GetWorldBounds()
    local unit whichUnit
    call GroupClear(ScanGroup)
    call GroupEnumUnitsInRect(ScanGroup, worldBounds, null)
    loop
        set whichUnit = FirstOfGroup(ScanGroup)
        exitwhen whichUnit == null
        call GroupRemoveUnit(ScanGroup, whichUnit)
        if QuestMaster_IsRegisteredGiver(whichUnit) then
            call RegisterSimpleTypeInternal(GetUnitTypeId(whichUnit), AI_REGISTER_ROLE_SCRIPTED, "", true)
        endif
        call ScanUnit(whichUnit)
    endloop
    call DestroyTimer(ScanTimer)
    set ScanTimer = null
    set whichUnit = null
    set worldBounds = null
endfunction

private function QueueScan takes nothing returns nothing
    if ScanTimer == null then
        set ScanTimer = CreateTimer()
        call TimerStart(ScanTimer, 0.00, false, function ScanAll)
    endif
endfunction

public function RegisterType takes integer unitTypeId, integer role, string profileName returns integer
    local integer profileId = RegisterSimpleTypeInternal(unitTypeId, role, profileName, true)
    if profileId > 0 and ProfileByUnitType[unitTypeId] == profileId then
        call QueueScan()
    endif
    return profileId
endfunction

public function RegisterInferredType takes integer unitTypeId, integer role, string profileName returns integer
    return RegisterSimpleTypeInternal(unitTypeId, role, profileName, false)
endfunction

public function RegisterGenericType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_GENERIC, profileName)
endfunction

public function RegisterAggressiveType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_AGGRESSIVE, profileName)
endfunction

public function RegisterPassiveType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_PASSIVE, profileName)
endfunction

public function RegisterCivilianType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_CIVILIAN, profileName)
endfunction

public function RegisterGuardType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_GUARD, profileName)
endfunction

public function RegisterScriptedType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_SCRIPTED, profileName)
endfunction

public function RegisterVendorType takes integer unitTypeId, string profileName returns integer
    return AIRegister_RegisterType(unitTypeId, AI_REGISTER_ROLE_VENDOR, profileName)
endfunction

public function RegisterCasterType takes integer unitTypeId, string profileName, integer abilityId, string order, real cooldown, real range returns integer
    local integer defaultProfile
    local integer profileId
    if ExcludedUnitType.boolean[unitTypeId] or not IsSimpleNpcType(unitTypeId) then
        return 0
    endif
    set defaultProfile = AI_GetUnitTypeDefaultProfile(unitTypeId)
    if defaultProfile > 0 and not OwnedProfile.boolean[defaultProfile] then
        return defaultProfile
    endif
    if RoleByUnitType[unitTypeId] == AI_REGISTER_ROLE_CASTER and ProfileByUnitType[unitTypeId] > 0 then
        return ProfileByUnitType[unitTypeId]
    endif
    set profileName = GetProfileName(unitTypeId, AI_REGISTER_ROLE_CASTER, profileName)
    set profileId = AIGenericCaster_RegisterProfile(unitTypeId, profileName, abilityId, order, cooldown, range, false)
    if RegisterProfile(unitTypeId, AI_REGISTER_ROLE_CASTER, profileId) > 0 then
        call QueueScan()
    endif
    return profileId
endfunction

public function RegisterHealerType takes integer unitTypeId, string profileName, integer abilityId, string order, real cooldown, real range, real threshold returns integer
    local integer defaultProfile
    local integer profileId
    if ExcludedUnitType.boolean[unitTypeId] or not IsSimpleNpcType(unitTypeId) then
        return 0
    endif
    set defaultProfile = AI_GetUnitTypeDefaultProfile(unitTypeId)
    if defaultProfile > 0 and not OwnedProfile.boolean[defaultProfile] then
        return defaultProfile
    endif
    if RoleByUnitType[unitTypeId] == AI_REGISTER_ROLE_HEALER and ProfileByUnitType[unitTypeId] > 0 then
        return ProfileByUnitType[unitTypeId]
    endif
    set profileName = GetProfileName(unitTypeId, AI_REGISTER_ROLE_HEALER, profileName)
    set profileId = AIGenericHealer_RegisterProfile(unitTypeId, profileName, abilityId, order, cooldown, range, threshold, false)
    if RegisterProfile(unitTypeId, AI_REGISTER_ROLE_HEALER, profileId) > 0 then
        call QueueScan()
    endif
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer fallbackRole returns integer
    local integer unitTypeId
    local integer profileId
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or ExcludedUnit.boolean[GetHandleId(whichUnit)] then
        set whichUnit = null
        return 0
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    set profileId = ProfileByUnitType[unitTypeId]
    if profileId <= 0 then
        set profileId = AIRegister_RegisterType(unitTypeId, fallbackRole, "")
    endif
    if profileId > 0 and ProfileByUnitType[unitTypeId] <= 0 then
        set profileId = AI_RegisterUnitByType(whichUnit, 0)
    else
        set profileId = ScanUnit(whichUnit)
    endif
    set whichUnit = null
    return profileId
endfunction

public function RegisterGenericUnit takes unit whichUnit returns integer
    return AIRegister_RegisterUnit(whichUnit, AI_REGISTER_ROLE_GENERIC)
endfunction

public function RegisterScriptedUnit takes unit whichUnit returns integer
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return 0
    endif
    call AIRegister_RegisterScriptedType(GetUnitTypeId(whichUnit), "")
    return ScanUnit(whichUnit)
endfunction

public function RegisterVendorUnit takes unit whichUnit returns integer
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return 0
    endif
    call AIRegister_RegisterVendorType(GetUnitTypeId(whichUnit), "")
    return ScanUnit(whichUnit)
endfunction

public function ExcludeUnitType takes integer unitTypeId returns nothing
    local integer profileId = ProfileByUnitType[unitTypeId]
    if unitTypeId == 0 then
        return
    endif
    set ExcludedUnitType.boolean[unitTypeId] = true
    if profileId > 0 and AI_GetUnitTypeDefaultProfile(unitTypeId) == profileId then
        call AI_SetUnitTypeDefaultProfile(unitTypeId, 0)
    endif
    call QueueScan()
endfunction

public function AllowUnitType takes integer unitTypeId returns nothing
    local integer defaultProfile
    local integer profileId
    if unitTypeId == 0 then
        return
    endif
    call ExcludedUnitType.boolean.remove(unitTypeId)
    set profileId = ProfileByUnitType[unitTypeId]
    set defaultProfile = AI_GetUnitTypeDefaultProfile(unitTypeId)
    if profileId > 0 and (defaultProfile <= 0 or OwnedProfile.boolean[defaultProfile]) then
        call AI_SetUnitTypeDefaultProfile(unitTypeId, profileId)
    endif
    call QueueScan()
endfunction

public function ResetUnitType takes integer unitTypeId returns nothing
    local integer profileId
    if unitTypeId == 0 then
        return
    endif
    set profileId = ProfileByUnitType[unitTypeId]
    call ExcludedUnitType.boolean.remove(unitTypeId)
    if profileId > 0 and AI_GetUnitTypeDefaultProfile(unitTypeId) == profileId then
        call AI_SetUnitTypeDefaultProfile(unitTypeId, 0)
    endif
    call RoleByUnitType.remove(unitTypeId)
    call ProfileByUnitType.remove(unitTypeId)
    call QueueScan()
endfunction

public function ExcludeUnit takes unit whichUnit returns nothing
    local integer profileId
    if whichUnit == null then
        return
    endif
    set ExcludedUnit.boolean[GetHandleId(whichUnit)] = true
    set profileId = AI_GetProfileId(whichUnit)
    if profileId > 0 and OwnedProfile.boolean[profileId] then
        call AI_UnregisterUnit(whichUnit)
    endif
    set whichUnit = null
endfunction

public function AllowUnit takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call ExcludedUnit.boolean.remove(GetHandleId(whichUnit))
    set whichUnit = null
endfunction

public function IsUnitTypeExcluded takes integer unitTypeId returns boolean
    return unitTypeId != 0 and ExcludedUnitType.boolean[unitTypeId]
endfunction

public function IsUnitExcluded takes unit whichUnit returns boolean
    if whichUnit == null then
        return true
    endif
    return ExcludedUnit.boolean[GetHandleId(whichUnit)]
endfunction

public function IsOwnedProfile takes integer profileId returns boolean
    return profileId > 0 and OwnedProfile.boolean[profileId]
endfunction

public function GetRole takes integer unitTypeId returns integer
    if ExcludedUnitType.boolean[unitTypeId] then
        return 0
    endif
    return RoleByUnitType[unitTypeId]
endfunction

public function GetProfile takes integer unitTypeId returns integer
    return ProfileByUnitType[unitTypeId]
endfunction

private function OnQuestGiverRegistered takes nothing returns nothing
    call AIRegister_RegisterScriptedUnit(QuestGiver_EventUnit)
endfunction

private function OnUnitDeindexed takes nothing returns nothing
    local unit deindexedUnit = udg_UDexUnits[udg_UDex]
    if deindexedUnit != null then
        call ExcludedUnit.boolean.remove(GetHandleId(deindexedUnit))
    endif
    set deindexedUnit = null
endfunction

private function Init takes nothing returns nothing
    set RoleByUnitType = Table.create()
    set ProfileByUnitType = Table.create()
    set OwnedProfile = Table.create()
    set ExcludedUnitType = Table.create()
    set ExcludedUnit = Table.create()
    set ScanGroup = CreateGroup()
    set UnitDeindexTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(UnitDeindexTrigger, "udg_UnitIndexEvent", EQUAL, 2.00)
    call TriggerAddAction(UnitDeindexTrigger, function OnUnitDeindexed)
    call QuestGiver_RegisterRegistrationCallback(function OnQuestGiverRegistered)
    call QueueScan()
endfunction

endlibrary
