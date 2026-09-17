/**
    FogSystem

    Author: Valdemar
    Version: 2.0.0

    Description:
    Stores and transitions complete per-player Warcraft III 3.0 terrain-fog
    presets while preserving the original linear start/end/RGB path exactly.

    Credits:
    - Refactored from The_Flood (Flood @ HiveWorkshop)
    - Transition approach inspired by Bribe's RetroFade

    How to install:
    Import before ZoneEvent, Storm, and systems that temporarily override fog.
    Existing AddFogForPlayer calls remain legacy-linear and unchanged visually.

    API:
    - AddFogForPlayer(start, end, redPercent, greenPercent, bluePercent, player)
    - FogSystem_SetPresetForPlayer(style, zStart, zEnd, density, heightStart,
      heightEnd, linearStart, linearEnd, maxLinearDensity, drawOverSky,
      red, green, blue, player)
    - FogSystem_BeginOverride() / FogSystem_EndOverride()
    - FogSystem_ApplyOverrideForPlayer(extended, ...)
    - FogSystem_GetCurrent* / FogSystem_GetTarget*

**/
library FogSystem initializer Init
    globals
        // Transition configuration.
        private constant real FOG_FADE_PERIOD = 0.03
        private constant real FOG_CHANGE_SPEED = 0.015
        private constant real FOG_DISTANCE_EPSILON = 1.00
        private constant real FOG_COLOR_EPSILON = 0.01
        private constant real FOG_VALUE_EPSILON = 0.001
        private constant integer FOG_MAX_PLAYERS = 24

        private timer FogFadeTimer = null
        private boolean FogFadeTimerRunning = false
        private integer FogOverrideCount = 0

        private player array FogPlayer
        private boolean array FogFading
        private boolean array FogCurrentExtended
        private boolean array FogTargetExtended
        private boolean array FogAppliedExtended
        private boolean array FogCurrentDrawOverSky
        private boolean array FogTargetDrawOverSky
        private integer array FogCurrentStyle
        private integer array FogTargetStyle

        private real array FogCurrentZStart
        private real array FogCurrentZEnd
        private real array FogCurrentDensity
        private real array FogCurrentHeightStart
        private real array FogCurrentHeightEnd
        private real array FogCurrentLinearStart
        private real array FogCurrentLinearEnd
        private real array FogCurrentMaxLinearDensity
        private real array FogCurrentRed
        private real array FogCurrentGreen
        private real array FogCurrentBlue

        private real array FogTargetZStart
        private real array FogTargetZEnd
        private real array FogTargetDensity
        private real array FogTargetHeightStart
        private real array FogTargetHeightEnd
        private real array FogTargetLinearStart
        private real array FogTargetLinearEnd
        private real array FogTargetMaxLinearDensity
        private real array FogTargetRed
        private real array FogTargetGreen
        private real array FogTargetBlue
    endglobals

    private function FogIndex takes player whichPlayer returns integer
        return GetPlayerId(whichPlayer) + 1
    endfunction

    private function Clamp01 takes real value returns real
        if value < 0.00 then
            return 0.00
        endif
        if value > 1.00 then
            return 1.00
        endif
        return value
    endfunction

    private function ClampStyle takes integer style returns integer
        if style < 0 then
            return 0
        endif
        if style > 5 then
            return 5
        endif
        return style
    endfunction

    private function BlendValue takes real current, real target, real epsilon returns real
        set current = current + (target - current)*FOG_CHANGE_SPEED
        if RAbsBJ(current - target) <= epsilon then
            return target
        endif
        return current
    endfunction

    private function IsAtTarget takes real current, real target, real epsilon returns boolean
        return RAbsBJ(current - target) <= epsilon
    endfunction

    private function ApplyValuesForPlayer takes player whichPlayer, boolean extended, integer style, real zStart, real zEnd, real density, real heightStart, real heightEnd, real linearStart, real linearEnd, real maxLinearDensity, boolean drawOverSky, real red, real green, real blue returns nothing
        local integer index = FogIndex(whichPlayer)

        if GetLocalPlayer() == whichPlayer then
            if extended then
                call SetTerrainFogExV(style, zStart, zEnd, density, heightStart, heightEnd, linearStart, linearEnd, red, green, blue)
                call BlzSetTerrainFogMaxLinearDensity(maxLinearDensity)
                call BlzSetTerrainFogDrawOverSky(drawOverSky)
            else
                if FogAppliedExtended[index] then
                    call BlzSetTerrainFogHeightStart(0.00)
                    call BlzSetTerrainFogHeightEnd(0.00)
                    call BlzSetTerrainFogLinearStart(zStart)
                    call BlzSetTerrainFogLinearEnd(zEnd)
                    call BlzSetTerrainFogMaxLinearDensity(1.00)
                    call BlzSetTerrainFogDrawOverSky(false)
                endif
                call SetTerrainFogEx(style, zStart, zEnd, density, red, green, blue)
            endif
            set FogAppliedExtended[index] = extended
        endif
    endfunction

    private function ApplyCurrentFog takes integer index returns nothing
        local player whichPlayer = Player(index - 1)

        if FogOverrideCount == 0 then
            call ApplyValuesForPlayer(whichPlayer, FogCurrentExtended[index], FogCurrentStyle[index], FogCurrentZStart[index], FogCurrentZEnd[index], FogCurrentDensity[index], FogCurrentHeightStart[index], FogCurrentHeightEnd[index], FogCurrentLinearStart[index], FogCurrentLinearEnd[index], FogCurrentMaxLinearDensity[index], FogCurrentDrawOverSky[index], FogCurrentRed[index], FogCurrentGreen[index], FogCurrentBlue[index])
        endif

        set whichPlayer = null
    endfunction

    private function CurrentMatchesTarget takes integer index returns boolean
        return FogCurrentExtended[index] == FogTargetExtended[index] and FogCurrentStyle[index] == FogTargetStyle[index] and FogCurrentDrawOverSky[index] == FogTargetDrawOverSky[index] and IsAtTarget(FogCurrentZStart[index], FogTargetZStart[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentZEnd[index], FogTargetZEnd[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentDensity[index], FogTargetDensity[index], FOG_VALUE_EPSILON) and IsAtTarget(FogCurrentHeightStart[index], FogTargetHeightStart[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentHeightEnd[index], FogTargetHeightEnd[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentLinearStart[index], FogTargetLinearStart[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentLinearEnd[index], FogTargetLinearEnd[index], FOG_DISTANCE_EPSILON) and IsAtTarget(FogCurrentMaxLinearDensity[index], FogTargetMaxLinearDensity[index], FOG_VALUE_EPSILON) and IsAtTarget(FogCurrentRed[index], FogTargetRed[index], FOG_COLOR_EPSILON) and IsAtTarget(FogCurrentGreen[index], FogTargetGreen[index], FOG_COLOR_EPSILON) and IsAtTarget(FogCurrentBlue[index], FogTargetBlue[index], FOG_COLOR_EPSILON)
    endfunction

    private function SnapCurrentToTarget takes integer index returns nothing
        set FogCurrentExtended[index] = FogTargetExtended[index]
        set FogCurrentStyle[index] = FogTargetStyle[index]
        set FogCurrentDrawOverSky[index] = FogTargetDrawOverSky[index]
        set FogCurrentZStart[index] = FogTargetZStart[index]
        set FogCurrentZEnd[index] = FogTargetZEnd[index]
        set FogCurrentDensity[index] = FogTargetDensity[index]
        set FogCurrentHeightStart[index] = FogTargetHeightStart[index]
        set FogCurrentHeightEnd[index] = FogTargetHeightEnd[index]
        set FogCurrentLinearStart[index] = FogTargetLinearStart[index]
        set FogCurrentLinearEnd[index] = FogTargetLinearEnd[index]
        set FogCurrentMaxLinearDensity[index] = FogTargetMaxLinearDensity[index]
        set FogCurrentRed[index] = FogTargetRed[index]
        set FogCurrentGreen[index] = FogTargetGreen[index]
        set FogCurrentBlue[index] = FogTargetBlue[index]
    endfunction

    private function UpdateCurrentValues takes integer index returns nothing
        set FogCurrentZStart[index] = BlendValue(FogCurrentZStart[index], FogTargetZStart[index], FOG_DISTANCE_EPSILON)
        set FogCurrentZEnd[index] = BlendValue(FogCurrentZEnd[index], FogTargetZEnd[index], FOG_DISTANCE_EPSILON)
        set FogCurrentDensity[index] = BlendValue(FogCurrentDensity[index], FogTargetDensity[index], FOG_VALUE_EPSILON)
        set FogCurrentHeightStart[index] = BlendValue(FogCurrentHeightStart[index], FogTargetHeightStart[index], FOG_DISTANCE_EPSILON)
        set FogCurrentHeightEnd[index] = BlendValue(FogCurrentHeightEnd[index], FogTargetHeightEnd[index], FOG_DISTANCE_EPSILON)
        set FogCurrentLinearStart[index] = BlendValue(FogCurrentLinearStart[index], FogTargetLinearStart[index], FOG_DISTANCE_EPSILON)
        set FogCurrentLinearEnd[index] = BlendValue(FogCurrentLinearEnd[index], FogTargetLinearEnd[index], FOG_DISTANCE_EPSILON)
        set FogCurrentMaxLinearDensity[index] = BlendValue(FogCurrentMaxLinearDensity[index], FogTargetMaxLinearDensity[index], FOG_VALUE_EPSILON)
        set FogCurrentRed[index] = BlendValue(FogCurrentRed[index], FogTargetRed[index], FOG_COLOR_EPSILON)
        set FogCurrentGreen[index] = BlendValue(FogCurrentGreen[index], FogTargetGreen[index], FOG_COLOR_EPSILON)
        set FogCurrentBlue[index] = BlendValue(FogCurrentBlue[index], FogTargetBlue[index], FOG_COLOR_EPSILON)
    endfunction

    private function FogFade takes nothing returns nothing
        local integer index = 1
        local integer activeCount = 0

        loop
            exitwhen index > FOG_MAX_PLAYERS
            if FogFading[index] then
                call UpdateCurrentValues(index)
                if CurrentMatchesTarget(index) then
                    call SnapCurrentToTarget(index)
                    set FogFading[index] = false
                else
                    set activeCount = activeCount + 1
                endif
                call ApplyCurrentFog(index)
            endif
            set index = index + 1
        endloop

        if activeCount == 0 then
            call PauseTimer(FogFadeTimer)
            set FogFadeTimerRunning = false
        endif
    endfunction

    private function StartFadeTimer takes nothing returns nothing
        if not FogFadeTimerRunning then
            set FogFadeTimerRunning = true
            call TimerStart(FogFadeTimer, FOG_FADE_PERIOD, true, function FogFade)
        endif
    endfunction

    private function SetTargetPreset takes boolean extended, integer style, real zStart, real zEnd, real density, real heightStart, real heightEnd, real linearStart, real linearEnd, real maxLinearDensity, boolean drawOverSky, real red, real green, real blue, player whichPlayer returns nothing
        local integer index = FogIndex(whichPlayer)

        set FogPlayer[index] = whichPlayer
        set FogTargetExtended[index] = extended
        set FogTargetStyle[index] = ClampStyle(style)
        set FogTargetDrawOverSky[index] = drawOverSky
        set FogTargetZStart[index] = zStart
        set FogTargetZEnd[index] = zEnd
        set FogTargetDensity[index] = density
        set FogTargetHeightStart[index] = heightStart
        set FogTargetHeightEnd[index] = heightEnd
        set FogTargetLinearStart[index] = linearStart
        set FogTargetLinearEnd[index] = linearEnd
        set FogTargetMaxLinearDensity[index] = Clamp01(maxLinearDensity)
        set FogTargetRed[index] = Clamp01(red)
        set FogTargetGreen[index] = Clamp01(green)
        set FogTargetBlue[index] = Clamp01(blue)

        // Discrete fields switch at transition start; numeric fields continue fading.
        set FogCurrentExtended[index] = FogTargetExtended[index]
        set FogCurrentStyle[index] = FogTargetStyle[index]
        set FogCurrentDrawOverSky[index] = FogTargetDrawOverSky[index]
        if CurrentMatchesTarget(index) then
            call SnapCurrentToTarget(index)
            set FogFading[index] = false
            call ApplyCurrentFog(index)
        else
            set FogFading[index] = true
            call StartFadeTimer()
        endif
    endfunction

    function AddFogForPlayer takes real start, real end, real redPercent, real greenPercent, real bluePercent, player whichPlayer returns nothing
        call SetTargetPreset(false, 0, start, end, 0.00, 0.00, 0.00, start, end, 1.00, false, redPercent*0.01, greenPercent*0.01, bluePercent*0.01, whichPlayer)
    endfunction

    public function SetPresetForPlayer takes integer style, real zStart, real zEnd, real density, real heightStart, real heightEnd, real linearStart, real linearEnd, real maxLinearDensity, boolean drawOverSky, real red, real green, real blue, player whichPlayer returns nothing
        call SetTargetPreset(true, style, zStart, zEnd, density, heightStart, heightEnd, linearStart, linearEnd, maxLinearDensity, drawOverSky, red, green, blue, whichPlayer)
    endfunction

    public function BeginOverride takes nothing returns nothing
        set FogOverrideCount = FogOverrideCount + 1
    endfunction

    public function EndOverride takes nothing returns nothing
        local integer index = 1

        if FogOverrideCount > 0 then
            set FogOverrideCount = FogOverrideCount - 1
        endif
        if FogOverrideCount == 0 then
            loop
                exitwhen index > FOG_MAX_PLAYERS
                if FogPlayer[index] != null then
                    call ApplyCurrentFog(index)
                endif
                set index = index + 1
            endloop
        endif
    endfunction

    public function ApplyOverrideForPlayer takes boolean extended, integer style, real zStart, real zEnd, real density, real heightStart, real heightEnd, real linearStart, real linearEnd, real maxLinearDensity, boolean drawOverSky, real red, real green, real blue, player whichPlayer returns nothing
        if FogOverrideCount > 0 then
            call ApplyValuesForPlayer(whichPlayer, extended, ClampStyle(style), zStart, zEnd, density, heightStart, heightEnd, linearStart, linearEnd, Clamp01(maxLinearDensity), drawOverSky, Clamp01(red), Clamp01(green), Clamp01(blue))
        endif
    endfunction

    public function GetOverrideDepth takes nothing returns integer
        return FogOverrideCount
    endfunction

    public function IsFading takes player whichPlayer returns boolean
        return FogFading[FogIndex(whichPlayer)]
    endfunction

    public function IsCurrentExtended takes player whichPlayer returns boolean
        return FogCurrentExtended[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentStyle takes player whichPlayer returns integer
        return FogCurrentStyle[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentStart takes player whichPlayer returns real
        return FogCurrentZStart[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentEnd takes player whichPlayer returns real
        return FogCurrentZEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentDensity takes player whichPlayer returns real
        return FogCurrentDensity[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentHeightStart takes player whichPlayer returns real
        return FogCurrentHeightStart[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentHeightEnd takes player whichPlayer returns real
        return FogCurrentHeightEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentLinearStart takes player whichPlayer returns real
        return FogCurrentLinearStart[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentLinearEnd takes player whichPlayer returns real
        return FogCurrentLinearEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentMaxLinearDensity takes player whichPlayer returns real
        return FogCurrentMaxLinearDensity[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentDrawOverSky takes player whichPlayer returns boolean
        return FogCurrentDrawOverSky[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentRed takes player whichPlayer returns real
        return FogCurrentRed[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentGreen takes player whichPlayer returns real
        return FogCurrentGreen[FogIndex(whichPlayer)]
    endfunction

    public function GetCurrentBlue takes player whichPlayer returns real
        return FogCurrentBlue[FogIndex(whichPlayer)]
    endfunction

    public function IsTargetExtended takes player whichPlayer returns boolean
        return FogTargetExtended[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetStyle takes player whichPlayer returns integer
        return FogTargetStyle[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetStart takes player whichPlayer returns real
        return FogTargetZStart[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetEnd takes player whichPlayer returns real
        return FogTargetZEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetDensity takes player whichPlayer returns real
        return FogTargetDensity[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetHeightStart takes player whichPlayer returns real
        return FogTargetHeightStart[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetHeightEnd takes player whichPlayer returns real
        return FogTargetHeightEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetLinearStart takes player whichPlayer returns real
        return FogTargetLinearStart[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetLinearEnd takes player whichPlayer returns real
        return FogTargetLinearEnd[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetMaxLinearDensity takes player whichPlayer returns real
        return FogTargetMaxLinearDensity[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetDrawOverSky takes player whichPlayer returns boolean
        return FogTargetDrawOverSky[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetRed takes player whichPlayer returns real
        return FogTargetRed[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetGreen takes player whichPlayer returns real
        return FogTargetGreen[FogIndex(whichPlayer)]
    endfunction

    public function GetTargetBlue takes player whichPlayer returns real
        return FogTargetBlue[FogIndex(whichPlayer)]
    endfunction

    private function InitializePlayer takes integer index returns nothing
        set FogCurrentExtended[index] = false
        set FogTargetExtended[index] = false
        set FogAppliedExtended[index] = false
        set FogCurrentDrawOverSky[index] = false
        set FogTargetDrawOverSky[index] = false
        set FogCurrentStyle[index] = 0
        set FogTargetStyle[index] = 0
        set FogCurrentZStart[index] = 400.00
        set FogCurrentZEnd[index] = 5000.00
        set FogCurrentDensity[index] = 0.00
        set FogCurrentHeightStart[index] = 0.00
        set FogCurrentHeightEnd[index] = 0.00
        set FogCurrentLinearStart[index] = 400.00
        set FogCurrentLinearEnd[index] = 5000.00
        set FogCurrentMaxLinearDensity[index] = 1.00
        set FogCurrentRed[index] = 0.50
        set FogCurrentGreen[index] = 0.50
        set FogCurrentBlue[index] = 0.50
        set FogTargetZStart[index] = FogCurrentZStart[index]
        set FogTargetZEnd[index] = FogCurrentZEnd[index]
        set FogTargetDensity[index] = FogCurrentDensity[index]
        set FogTargetHeightStart[index] = FogCurrentHeightStart[index]
        set FogTargetHeightEnd[index] = FogCurrentHeightEnd[index]
        set FogTargetLinearStart[index] = FogCurrentLinearStart[index]
        set FogTargetLinearEnd[index] = FogCurrentLinearEnd[index]
        set FogTargetMaxLinearDensity[index] = FogCurrentMaxLinearDensity[index]
        set FogTargetRed[index] = FogCurrentRed[index]
        set FogTargetGreen[index] = FogCurrentGreen[index]
        set FogTargetBlue[index] = FogCurrentBlue[index]
    endfunction

    private function Init takes nothing returns nothing
        local integer index = 1
        local player whichPlayer

        set FogFadeTimer = CreateTimer()
        loop
            exitwhen index > FOG_MAX_PLAYERS
            call InitializePlayer(index)
            set whichPlayer = Player(index - 1)
            if GetPlayerController(whichPlayer) == MAP_CONTROL_USER and GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING then
                set FogPlayer[index] = whichPlayer
                call AddFogForPlayer(400.00, 3000.00, 100.00, 100.00, 100.00, whichPlayer)
            endif
            set index = index + 1
        endloop

        set whichPlayer = null
    endfunction
endlibrary
