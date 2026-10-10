/**
    DynamicFarZ

    Author: Valdemar
    Version: 1.0.1

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

    private boolean DFZ_Initialized = false
    private integer array DFZ_Mode
    private integer array DFZ_Profile
    private real array DFZ_ContextLightMaximum
    private real array DFZ_ContextMediumMaximum
    private real array DFZ_ContextHeavyMaximum
    private boolean array DFZ_ContextDefined
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

public function GetEffectiveFarZ takes player whichPlayer, real baseFarZ, real angle, integer contextId, boolean cinematic returns real
    local integer profile = DFZ_Profile[DFZ_GetPlayerIndex(whichPlayer)]
    local real minimumFactor
    local real factor
    local real contextMaximum
    local real effectiveFarZ

    if DFZ_Mode[DFZ_GetPlayerIndex(whichPlayer)] != MODE_AUTO or baseFarZ <= 0.00 then
        return baseFarZ
    endif

    // Scripted and interactive cinematic cameras may use their full authored range.
    if cinematic then
        return baseFarZ
    endif

    set angle = DFZ_NormalizeAngle(angle)
    set minimumFactor = DFZ_GetMinimumFactor(profile)
    if angle <= DFZ_NATURAL_ANGLE then
        set factor = minimumFactor
    elseif angle >= DFZ_HORIZON_ANGLE then
        set factor = 1.00
    else
        set factor = minimumFactor + (1.00 - minimumFactor)*(angle - DFZ_NATURAL_ANGLE)/(DFZ_HORIZON_ANGLE - DFZ_NATURAL_ANGLE)
    endif

    set effectiveFarZ = baseFarZ*factor
    set contextMaximum = DFZ_GetContextMaximum(contextId, profile)
    if contextMaximum > 0.00 then
        set effectiveFarZ = DFZ_Clamp(effectiveFarZ, 0.00, contextMaximum)
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
