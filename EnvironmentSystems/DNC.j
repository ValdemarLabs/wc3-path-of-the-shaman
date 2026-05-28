library DNC initializer InitDNC

//===========================================================================
/*
    DNC

    Author: [Valdemar]
    Version: 1.0
    
    Uses:
    - To simply switch DNC models

    Requirements:
    - Import custom DNC models into the map and set up the model paths correctly in the code

    API:
    call DNC_Outdoors()
    call DNC_OutdoorsCloudy()
    call DNC_OutdoorsDirty()
    call DNC_OutdoorsMountains()
    call DNC_OutdoorsRed()
    call DNC_Underground()
    call DNC_Hellish()
    call DNC_Firelands()
    call DNC_DarkPlace()
    call DNC_DarkerPlace()
    call DNC_DarkStock()
    call DNC_DarkSpace()
    call DNC_Storm()
    call DNC_Death1()

    // Chat (debug) commands:
    "dnc underground" - switches to underground DNC
    "dnc darkplace" - switches to DarkPlace DNC
    "dnc darkerplace" - switches to DarkerPlace DNC
    "dnc darkstock" - switches to DarkStock DNC

*/
//===========================================================================

globals

    private constant boolean DEBUG = true
    // DNC type constants
    constant string DNC_Outdoors_TYPE = "DNC_Outdoors"
    constant string DNC_OutdoorsCloudy_TYPE = "DNC_OutdoorsCloudy"
    constant string DNC_OutdoorsDirty_TYPE = "DNC_OutdoorsDirty"
    constant string DNC_OutdoorsMountains_TYPE = "DNC_OutdoorsMountains"
    constant string DNC_OutdoorsRed_TYPE = "DNC_OutdoorsRed"
    constant string DNC_Underground_TYPE = "DNC_Underground"
    constant string DNC_Hellish_TYPE = "DNC_Hellish"
    constant string DNC_Firelands_TYPE = "DNC_Firelands"
    constant string DNC_DarkPlace_TYPE = "DNC_DarkPlace"
    constant string DNC_DarkerPlace_TYPE = "DNC_DarkerPlace"
    constant string DNC_DarkStock_TYPE = "DNC_DarkStock"
    constant string DNC_DarkSpace_TYPE = "DNC_DarkSpace"
    constant string DNC_Storm_TYPE = "DNC_Storm"
    constant string DNC_Death1_TYPE = "DNC_Death1"

    string DNC_Type = null

endglobals

// Utility function to set sky
function DNC_SetSky takes string sky returns nothing
    if sky == "None" or sky == "none" then
        call SetSkyModel("")
    else
        call SetSkyModel(sky)
    endif
endfunction

// DNC Outdoors
function DNC_Outdoors takes nothing returns nothing
    if DNC_Type != DNC_Outdoors_TYPE then
        call DNC_SetSky("war3campImported\\SummerSphereCT2.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
        set DNC_Type = DNC_Outdoors_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Outdoors|r")
        endif
    endif
endfunction

// DNC Outdoors Cloudy
function DNC_OutdoorsCloudy takes nothing returns nothing
    if DNC_Type != DNC_OutdoorsCloudy_TYPE then
        call DNC_SetSky("environments_stars_skywallskybox.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
        set DNC_Type = DNC_OutdoorsCloudy_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to OutdoorsCloudy|r")
        endif
    endif
endfunction

// DNC Outdoors Dirty
function DNC_OutdoorsDirty takes nothing returns nothing
    if DNC_Type != DNC_OutdoorsDirty_TYPE then
        call DNC_SetSky("environments_stars_battlefield_dirty_skybox.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
        set DNC_Type = DNC_OutdoorsDirty_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to OutdoorsDirty|r")
        endif
    endif
endfunction

// DNC Outdoors Mountains
function DNC_OutdoorsMountains takes nothing returns nothing
    if DNC_Type != DNC_OutdoorsMountains_TYPE then
        call DNC_SetSky("environments_stars_deathskybox__e38898f61f50c7ebf4f12515f3390ceb.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
        set DNC_Type = DNC_OutdoorsMountains_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to OutdoorsMountains|r")
        endif
    endif
endfunction

// DNC Outdoors Red
function DNC_OutdoorsRed takes nothing returns nothing
    if DNC_Type != DNC_OutdoorsRed_TYPE then
        call DNC_SetSky("war3mapImported\\LordaeronWinterSkyRedCustom.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
        set DNC_Type = DNC_OutdoorsRed_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to OutdoorsRed|r")
        endif
    endif
endfunction

// DNC Underground (chat command)
function DNC_Underground takes nothing returns nothing
    if DNC_Type != DNC_Underground_TYPE then
        call DNC_SetSky("None")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl")
        set DNC_Type = DNC_Underground_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Underground|r")
        endif
    endif
endfunction

// DNC Hellish
function DNC_Hellish takes nothing returns nothing
    if DNC_Type != DNC_Hellish_TYPE then
        call DNC_SetSky("war3mapImported\\LordaeronWinterSkyRedCustom.mdx")
        set DNC_Type = DNC_Hellish_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Hellish|r")
        endif
    endif
endfunction

// DNC Firelands
function DNC_Firelands takes nothing returns nothing
    if DNC_Type != DNC_Firelands_TYPE then
        //call DNC_SetSky("environments_stars_firelandssky01.mdx")
        call DNC_SetSky("war3mapImported\\LordaeronWinterSkyRedCustom.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl")
        set DNC_Type = DNC_Firelands_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Firelands|r")
        endif
    endif
endfunction

// DNC DarkPlace (chat command)
function DNC_DarkPlace takes nothing returns nothing
    if DNC_Type != DNC_DarkPlace_TYPE then
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl")
        set DNC_Type = DNC_DarkPlace_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to DarkPlace|r")
        endif
    endif
endfunction

// DNC DarkerPlace (chat command)
function DNC_DarkerPlace takes nothing returns nothing
    if DNC_Type != DNC_DarkerPlace_TYPE then
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3c.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3c.mdl")
        set DNC_Type = DNC_DarkerPlace_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to DarkerPlace|r")
        endif
    endif
endfunction

// DNC DarkStock (chat command)
function DNC_DarkStock takes nothing returns nothing
    if DNC_Type != DNC_DarkStock_TYPE then
        call SetDayNightModels("","")
        set DNC_Type = DNC_DarkStock_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to DarkStock|r")
        endif
    endif
endfunction

// DNC DarkSpace
function DNC_DarkSpace takes nothing returns nothing
    if DNC_Type != DNC_DarkSpace_TYPE then
        call DNC_SetSky("Outland Sky")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl")
        set DNC_Type = DNC_DarkSpace_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to DarkSpace|r")
        endif
    endif
endfunction

// DNC Storm
function DNC_Storm takes nothing returns nothing
    if DNC_Type != DNC_Storm_TYPE then
        // Lets not change DNC here, Storm library will handle it
        set DNC_Type = DNC_Storm_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Storm|r")
        endif
    endif
endfunction

// DNC Death1
function DNC_Death1 takes nothing returns nothing
    if DNC_Type != DNC_Death1_TYPE then
        call DNC_SetSky("environments_stars_deathclouds.mdx")
        call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker3.mdl")
        set DNC_Type = DNC_Death1_TYPE
        if DEBUG then
            call BJDebugMsg("|cffFF8800DNC: Set to Death1|r")
        endif
    endif
endfunction


// Chat event triggers for special DNC types
private function DNC_Chat takes nothing returns nothing
    local string msg = GetEventPlayerChatString()
    if msg == "dnc underground" then
        call DNC_Underground()
    elseif msg == "dnc darkplace" then
        call DNC_DarkPlace()
    elseif msg == "dnc darkerplace" then
        call DNC_DarkerPlace()
    elseif msg == "dnc darkstock" then
        call DNC_DarkStock()
    endif
endfunction

// Register chat triggers
private function Register_Chat takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(t, Player(0), "dnc underground", true)
    call TriggerRegisterPlayerChatEvent(t, Player(0), "dnc darkplace", true)
    call TriggerRegisterPlayerChatEvent(t, Player(0), "dnc darkerplace", true)
    call TriggerRegisterPlayerChatEvent(t, Player(0), "dnc darkstock", true)
    call TriggerAddAction(t, function DNC_Chat)
endfunction

// INITIALIZER
private function InitDNC takes nothing returns nothing
    call DNC_SetSky("war3campImported\\SummerSphereCT2.mdx")
    call SetDayNightModels("Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl","Environment\\DNC\\DNCAnimated2\\DNCAnimated2_Darker.mdl")
    call FogMaskEnable(false)
    call FogEnable(false)
    set DNC_Type = DNC_Outdoors_TYPE

    // Register chat commands
    call Register_Chat()

    if DEBUG then
        call BJDebugMsg("|cffFF8800DNC: Initialized (Outdoors)|r")
    endif

endfunction

endlibrary