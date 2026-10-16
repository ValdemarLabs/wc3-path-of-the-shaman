/**
    DynamicFarZ

    Author: Valdemar
    Version: 1.1.0

    Description:
    Calculates a local player's Far Z from the active camera angle, selected
    performance profile, cinematic state, and optional zone-specific limits.

    Credits:

    How to install:
    Import before CameraControl and CameraUI.

    API:
    call DynamicFarZ_SetAuto(whichPlayer, enabled)
    call DynamicFarZ_ToggleAuto(whichPlayer)
    call DynamicFarZ_IsAuto(whichPlayer) returns boolean
    call DynamicFarZ_SetProfile(whichPlayer, profile)
    call DynamicFarZ_CycleProfile(whichPlayer)
    call DynamicFarZ_GetProfile(whichPlayer) returns integer
    call DynamicFarZ_GetProfileName(whichPlayer) returns string
    call DynamicFarZ_ResetDefaults(whichPlayer)
    call DynamicFarZ_DefineContext(contextId, lightMaximum, mediumMaximum, heavyMaximum)
    call DynamicFarZ_HasContext(contextId) returns boolean
    call DynamicFarZ_GetEffectiveFarZ(whichPlayer, baseFarZ, angle, contextId, cinematic) returns real

    Debug API:
    call DynamicFarZ_SetDiagnosticsEnabled(whichPlayer, enabled)
    call DynamicFarZ_IsDiagnosticsEnabled(whichPlayer) returns boolean
    call DynamicFarZ_ResetDiagnostics(whichPlayer)
    call DynamicFarZ_GetLastCalculatedFactor(whichPlayer) returns real
    call DynamicFarZ_GetLastProfileCeilingFactor(whichPlayer) returns real
    call DynamicFarZ_GetLastContextMaximum(whichPlayer) returns real
    call DynamicFarZ_GetLastEffectiveFarZ(whichPlayer) returns real

**/
library DynamicFarZ initializer AutoInit
globals
    public constant integer MODE_DISABLED = 0
    public constant integer MODE_AUTO = 1

    public constant integer PROFILE_LIGHT = 1
    public constant integer PROFILE_MEDIUM = 2
    public constant integer PROFILE_HEAVY = 3

    // Configuration
    private constant integer DFZ_DEFAULT_MODE = MODE_AUTO
    private constant integer DFZ_DEFAULT_PROFILE = PROFILE_MEDIUM
    private constant real DFZ_NATURAL_ANGLE = 310.00
    private constant real DFZ_HORIZON_ANGLE = 345.00
    private constant real DFZ_LIGHT_MINIMUM_FACTOR = 0.85
    private constant real DFZ_MEDIUM_MINIMUM_FACTOR = 0.65
    private constant real DFZ_HEAVY_MINIMUM_FACTOR = 0.45
    private constant real DFZ_LIGHT_HORIZON_CEILING_FACTOR = 1.00
    private constant real DFZ_MEDIUM_HORIZON_CEILING_FACTOR = 0.80
    private constant real DFZ_HEAVY_HORIZON_CEILING_FACTOR = 0.65

    private boolean DFZ_Initialized = false
    private integer array DFZ_Mode
    private integer array DFZ_Profile
    private real array DFZ_ContextLightMaximum
    private real array DFZ_ContextMediumMaximum
    private real array DFZ_ContextHeavyMaximum
    private boolean array DFZ_ContextDefined
    private boolean array DFZ_DiagnosticsEnabled
    private real array DFZ_LastCalculatedFactor
    private real array DFZ_LastProfileCeilingFactor
    private real array DFZ_LastContextMaximum
    private real array DFZ_LastEffectiveFarZ
endglobals

private function DFZ_GetPlayerIndex takes player whichPlayer returns integer
    return GetPlayerId(whichPlayer)
endfunction

private function DFZ_Clamp takes real value, real minValue, real maxValue returns real
    if value < minValue then
        return minValue
    endif
    if value > maxValue then
        return maxValue
    endif
    return value
endfunction

private function DFZ_NormalizeAngle takes real angle returns real
    loop
        exitwhen angle >= 0.00
        set angle = angle + 360.00
    endloop
    loop
        exitwhen angle < 360.00
        set angle = angle - 360.00
    endloop
    return angle
endfunction

private function DFZ_GetMinimumFactor takes integer profile returns real
    if profile == PROFILE_LIGHT then
        return DFZ_LIGHT_MINIMUM_FACTOR
    elseif profile == PROFILE_HEAVY then
        return DFZ_HEAVY_MINIMUM_FACTOR
    endif
    return DFZ_MEDIUM_MINIMUM_FACTOR
endfunction

private function DFZ_GetHorizonCeilingFactor takes integer profile returns real
    if profile == PROFILE_LIGHT then
        return DFZ_LIGHT_HORIZON_CEILING_FACTOR
    elseif profile == PROFILE_HEAVY then
        return DFZ_HEAVY_HORIZON_CEILING_FACTOR
    endif
    return DFZ_MEDIUM_HORIZON_CEILING_FACTOR
endfunction

private function DFZ_GetContextMaximum takes integer contextId, integer profile returns real
    if contextId <= 0 then
        return 0.00
    endif
    if profile == PROFILE_LIGHT then
        return DFZ_ContextLightMaximum[contextId]
    elseif profile == PROFILE_HEAVY then
        return DFZ_ContextHeavyMaximum[contextId]
    endif
    return DFZ_ContextMediumMaximum[contextId]
endfunction

public function SetAuto takes player whichPlayer, boolean enabled returns nothing
    if enabled then
        set DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] = MODE_AUTO
    else
        set DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] = MODE_DISABLED
    endif
endfunction

public function ToggleAuto takes player whichPlayer returns nothing
    call SetAuto(whichPlayer, DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] != MODE_AUTO)
endfunction

public function IsAuto takes player whichPlayer returns boolean
    return DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] == MODE_AUTO
endfunction

public function SetProfile takes player whichPlayer, integer profile returns nothing
    if profile < PROFILE_LIGHT then
        set profile = PROFILE_LIGHT
    elseif profile > PROFILE_HEAVY then
        set profile = PROFILE_HEAVY
    endif
    set DFZ_Profile[DFZ_GetPlayerIndex(whichPlayer)] = profile
endfunction

public function CycleProfile takes player whichPlayer returns nothing
    local integer profile = DFZ_Profile[DFZ_GetPlayerIndex(whichPlayer)] + 1
    if profile > PROFILE_HEAVY then
        set profile = PROFILE_LIGHT
    endif
    call SetProfile(whichPlayer, profile)
endfunction

public function GetProfile takes player whichPlayer returns integer
    return DFZ_Profile[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function GetProfileName takes player whichPlayer returns string
    local integer profile = GetProfile(whichPlayer)
    if profile == PROFILE_LIGHT then
        return "Light"
    elseif profile == PROFILE_HEAVY then
        return "Heavy"
    endif
    return "Medium"
endfunction

public function ResetDefaults takes player whichPlayer returns nothing
    set DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] = DFZ_DEFAULT_MODE
    set DFZ_Profile[DFZ_GetPlayerIndex(whichPlayer)] = DFZ_DEFAULT_PROFILE
endfunction

public function DefineContext takes integer contextId, real lightMaximum, real mediumMaximum, real heavyMaximum returns nothing
    if contextId <= 0 then
        return
    endif
    set DFZ_ContextLightMaximum[contextId] = lightMaximum
    set DFZ_ContextMediumMaximum[contextId] = mediumMaximum
    set DFZ_ContextHeavyMaximum[contextId] = heavyMaximum
    set DFZ_ContextDefined[contextId] = true
endfunction

public function HasContext takes integer contextId returns boolean
    return contextId > 0 and DFZ_ContextDefined[contextId]
endfunction

public function SetDiagnosticsEnabled takes player whichPlayer, boolean enabled returns nothing
    set DFZ_DiagnosticsEnabled[DFZ_GetPlayerIndex(whichPlayer)] = enabled
endfunction

public function IsDiagnosticsEnabled takes player whichPlayer returns boolean
    return DFZ_DiagnosticsEnabled[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function ResetDiagnostics takes player whichPlayer returns nothing
    local integer pid = DFZ_GetPlayerIndex(whichPlayer)
    set DFZ_LastCalculatedFactor[pid] = 0.00
    set DFZ_LastProfileCeilingFactor[pid] = 0.00
    set DFZ_LastContextMaximum[pid] = 0.00
    set DFZ_LastEffectiveFarZ[pid] = 0.00
endfunction

public function GetLastCalculatedFactor takes player whichPlayer returns real
    return DFZ_LastCalculatedFactor[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function GetLastProfileCeilingFactor takes player whichPlayer returns real
    return DFZ_LastProfileCeilingFactor[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function GetLastContextMaximum takes player whichPlayer returns real
    return DFZ_LastContextMaximum[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function GetLastEffectiveFarZ takes player whichPlayer returns real
    return DFZ_LastEffectiveFarZ[DFZ_GetPlayerIndex(whichPlayer)]
endfunction

public function GetEffectiveFarZ takes player whichPlayer, real baseFarZ, real angle, integer contextId, boolean cinematic returns real
    local integer pid = DFZ_GetPlayerIndex(whichPlayer)
    local integer profile = DFZ_Profile[pid]
    local real minimumFactor
    local real calculatedFactor
    local real ceilingFactor
    local real factor
    local real contextMaximum
    local real effectiveFarZ

    if DFZ_Mode[pid] != MODE_AUTO or baseFarZ <= 0.00 then
        if DFZ_DiagnosticsEnabled[pid] then
            set DFZ_LastCalculatedFactor[pid] = 1.00
            set DFZ_LastProfileCeilingFactor[pid] = DFZ_GetHorizonCeilingFactor(profile)
            set DFZ_LastContextMaximum[pid] = DFZ_GetContextMaximum(contextId, profile)
            set DFZ_LastEffectiveFarZ[pid] = baseFarZ
        endif
        return baseFarZ
    endif

    // Scripted and interactive cinematic cameras may use their full authored range.
    if cinematic then
        if DFZ_DiagnosticsEnabled[pid] then
            set DFZ_LastCalculatedFactor[pid] = 1.00
            set DFZ_LastProfileCeilingFactor[pid] = DFZ_GetHorizonCeilingFactor(profile)
            set DFZ_LastContextMaximum[pid] = DFZ_GetContextMaximum(contextId, profile)
            set DFZ_LastEffectiveFarZ[pid] = baseFarZ
        endif
        return baseFarZ
    endif

    set angle = DFZ_NormalizeAngle(angle)
    set minimumFactor = DFZ_GetMinimumFactor(profile)
    if angle <= DFZ_NATURAL_ANGLE then
        set calculatedFactor = minimumFactor
    elseif angle >= DFZ_HORIZON_ANGLE then
        set calculatedFactor = 1.00
    else
        set calculatedFactor = minimumFactor + (1.00 - minimumFactor)*(angle - DFZ_NATURAL_ANGLE)/(DFZ_HORIZON_ANGLE - DFZ_NATURAL_ANGLE)
    endif

    // Preserve Light's authored horizon range while Medium and Heavy stop at
    // 8000 and 6500 for the default 10000 base Far Z candidate.
    set ceilingFactor = DFZ_GetHorizonCeilingFactor(profile)
    set factor = calculatedFactor
    if factor > ceilingFactor then
        set factor = ceilingFactor
    endif

    set effectiveFarZ = baseFarZ*factor
    set contextMaximum = DFZ_GetContextMaximum(contextId, profile)
    if contextMaximum > 0.00 then
        set effectiveFarZ = DFZ_Clamp(effectiveFarZ, 0.00, contextMaximum)
    endif
    if DFZ_DiagnosticsEnabled[pid] then
        set DFZ_LastCalculatedFactor[pid] = calculatedFactor
        set DFZ_LastProfileCeilingFactor[pid] = ceilingFactor
        set DFZ_LastContextMaximum[pid] = contextMaximum
        set DFZ_LastEffectiveFarZ[pid] = effectiveFarZ
    endif
    return effectiveFarZ
endfunction

public function Init takes nothing returns nothing
    local integer i = 0
    if DFZ_Initialized then
        return
    endif
    set DFZ_Initialized = true

    loop
        exitwhen i >= bj_MAX_PLAYERS
        set DFZ_Mode[i] = DFZ_DEFAULT_MODE
        set DFZ_Profile[i] = DFZ_DEFAULT_PROFILE
        set i = i + 1
    endloop
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
