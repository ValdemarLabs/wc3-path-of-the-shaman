/**
    PotSSaveCommands

    Author: Valdemar
    Version: 2.0.0

    Description:
    Owns the non-conflicting PotS chat commands for the PotSSaveLoad facade.

    Credits:

    How to install:
    Import after PotSSaveLoad. Do not register duplicate handlers for these
    commands or for the vendor example's -save/-load commands.

    API:
    - Player commands: -pots-save <slot> and -pots-load <slot>

**/
library PotSSaveCommands initializer Init requires PotSSaveLoad
    globals
        private constant string PSC_SAVE_COMMAND = "-pots-save"
        private constant string PSC_LOAD_COMMAND = "-pots-load"
        private trigger PSC_SaveTrigger = null
        private trigger PSC_LoadTrigger = null
    endglobals

    private function PSC_OnSave takes nothing returns nothing
        local player whichPlayer = GetTriggerPlayer()
        local string input = GetEventPlayerChatString()
        local string slot = ""

        if input == PSC_SAVE_COMMAND then
            call PotSSaveLoad_RequestSave(whichPlayer, slot)
            set whichPlayer = null
            return
        elseif StringLength(input) <= 11 or SubString(input, 0, 11) != PSC_SAVE_COMMAND + " " then
            set whichPlayer = null
            return
        endif
        set slot = SubString(input, 11, StringLength(input))
        call PotSSaveLoad_RequestSave(whichPlayer, slot)
        set whichPlayer = null
    endfunction

    private function PSC_OnLoad takes nothing returns nothing
        local player whichPlayer = GetTriggerPlayer()
        local string input = GetEventPlayerChatString()
        local string slot = ""

        if input == PSC_LOAD_COMMAND then
            call PotSSaveLoad_RequestLoad(whichPlayer, slot)
            set whichPlayer = null
            return
        elseif StringLength(input) <= 11 or SubString(input, 0, 11) != PSC_LOAD_COMMAND + " " then
            set whichPlayer = null
            return
        endif
        set slot = SubString(input, 11, StringLength(input))
        call PotSSaveLoad_RequestLoad(whichPlayer, slot)
        set whichPlayer = null
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0

        set PSC_SaveTrigger = CreateTrigger()
        set PSC_LoadTrigger = CreateTrigger()
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerChatEvent(PSC_SaveTrigger, Player(i), PSC_SAVE_COMMAND, false)
            call TriggerRegisterPlayerChatEvent(PSC_LoadTrigger, Player(i), PSC_LOAD_COMMAND, false)
            set i = i + 1
        endloop
        call TriggerAddAction(PSC_SaveTrigger, function PSC_OnSave)
        call TriggerAddAction(PSC_LoadTrigger, function PSC_OnLoad)
    endfunction
endlibrary
