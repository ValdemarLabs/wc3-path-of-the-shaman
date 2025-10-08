// Codex UI
/* 
    Original creator: InsaneMonster
    Edited and repurposed by: Valdemar

    Purpose:
    Dialog to store information of the map Zones, subzones and dungeon that are gathered when player first explores them.


*/


function CodexDialogUpdateEntries takes nothing returns nothing
    local framehandle codexDialogEntryOneTitle = BlzGetFrameByName("CodexDialogEntryTopLeftTitle",0)
    local framehandle codexDialogEntryTwoTitle = BlzGetFrameByName("CodexDialogEntryTopRightTitle",0)
    local framehandle codexDialogEntryThreeTitle = BlzGetFrameByName("CodexDialogEntryCenterLeftTitle",0)
    local framehandle codexDialogEntryFourTitle = BlzGetFrameByName("CodexDialogEntryCenterRightTitle",0)
    local framehandle codexDialogEntryFiveTitle = BlzGetFrameByName("CodexDialogEntryBottomLeftTitle",0)
    local framehandle codexDialogEntrySixTitle = BlzGetFrameByName("CodexDialogEntryBottomRightTitle",0)

    // Update all entries button titles
    if udg_Codex_EntryDiscovered01 == true then
        call BlzFrameSetText(codexDialogEntryOneTitle, udg_Codex_EntryTitle01)
    endif
    if udg_Codex_EntryDiscovered02 == true then
        call BlzFrameSetText(codexDialogEntryTwoTitle, udg_Codex_EntryTitle02)
    endif
    if udg_Codex_EntryDiscovered03 == true then
        call BlzFrameSetText(codexDialogEntryThreeTitle, udg_Codex_EntryTitle03)
    endif
    if udg_Codex_EntryDiscovered04 == true then
        call BlzFrameSetText(codexDialogEntryFourTitle, udg_Codex_EntryTitle04)
    endif
    if udg_Codex_EntryDiscovered05 == true then
        call BlzFrameSetText(codexDialogEntryFiveTitle, udg_Codex_EntryTitle05)
    endif
    if udg_Codex_EntryDiscovered06 == true then
        call BlzFrameSetText(codexDialogEntrySixTitle, udg_Codex_EntryTitle06)
    endif

    // Clean the leaks
    set codexDialogEntryOneTitle = null
    set codexDialogEntryTwoTitle = null
    set codexDialogEntryThreeTitle = null
    set codexDialogEntryFourTitle = null
    set codexDialogEntryFiveTitle = null
    set codexDialogEntrySixTitle = null
endfunction

function CodexDialogEntryAllButtonsDeselect takes nothing returns nothing
    local framehandle codexDialogEntryOneButton = BlzGetFrameByName("CodexDialogEntryTopLeftButtonSelectedHighlight", 0)
    local framehandle codexDialogEntryTwoButton = BlzGetFrameByName("CodexDialogEntryTopRightButtonSelectedHighlight" , 0)
    local framehandle codexDialogEntryThreeButton = BlzGetFrameByName("CodexDialogEntryCenterLeftButtonSelectedHighlight" , 0)
    local framehandle codexDialogEntryFourButton = BlzGetFrameByName("CodexDialogEntryCenterRightButtonSelectedHighlight" , 0)
    local framehandle codexDialogEntryFiveButton = BlzGetFrameByName("CodexDialogEntryBottomLeftButtonSelectedHighlight" , 0)
    local framehandle codexDialogEntrySixButton = BlzGetFrameByName("CodexDialogEntryBottomRightButtonSelectedHighlight" , 0)
    local framehandle codexDialogDisplay = BlzGetFrameByName("CodexDialogDisplay" , 0)

    // Remove all highlights from the buttons
    call BlzFrameSetVisible(codexDialogEntryOneButton, false)
    call BlzFrameSetVisible(codexDialogEntryTwoButton, false)
    call BlzFrameSetVisible(codexDialogEntryThreeButton, false)
    call BlzFrameSetVisible(codexDialogEntryFourButton, false)
    call BlzFrameSetVisible(codexDialogEntryFiveButton, false)
    call BlzFrameSetVisible(codexDialogEntrySixButton, false)

    // Hide the display
    call BlzFrameSetVisible(codexDialogDisplay, false)

    // Set the selected value to an invalid value
    set udg_Codex_UISelectedEntry = -1

    // Clean the leaks
    set codexDialogEntryOneButton = null
    set codexDialogEntryTwoButton = null
    set codexDialogEntryThreeButton = null
    set codexDialogEntryFourButton = null
    set codexDialogEntryFiveButton = null
    set codexDialogEntrySixButton = null
    set codexDialogDisplay = null
endfunction

function CodexDialogSelectEntry takes integer number returns nothing
    local framehandle buttonSelectedHighlight = null
    local framehandle codexDialogDisplay = BlzGetFrameByName("CodexDialogDisplay" , 0)
    local framehandle codexDialogDisplayTitle = BlzGetFrameByName("CodexDialogDisplayTitle" , 0)

    if number <= udg_Codex_EntriesNumber then
        // Set the selected value to the selected button
        set udg_Codex_UISelectedEntry = number
        // Highlight the selected button and setup title and content then show display if discovered
        if number == 1 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryTopLeftButtonSelectedHighlight", 0)
            if udg_Codex_EntryDiscovered01 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle01)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent01)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        elseif number == 2 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryTopRightButtonSelectedHighlight" , 0)
            if udg_Codex_EntryDiscovered02 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle02)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent02)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        elseif number == 3 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryCenterLeftButtonSelectedHighlight" , 0)
            if udg_Codex_EntryDiscovered03 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle03)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent03)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        elseif number == 4 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryCenterRightButtonSelectedHighlight" , 0)
            if udg_Codex_EntryDiscovered04 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle04)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent04)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        elseif number == 5 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryBottomLeftButtonSelectedHighlight" , 0)
            if udg_Codex_EntryDiscovered05 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle05)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent05)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        elseif number == 6 then
            set buttonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryBottomRightButtonSelectedHighlight" , 0)
            if udg_Codex_EntryDiscovered06 == true then
                call BlzFrameSetText(codexDialogDisplayTitle, udg_Codex_EntryTitle06)
                call BlzFrameSetText(codexDialogDisplay, udg_Codex_EntryContent06)
                call BlzFrameSetVisible(codexDialogDisplay, true)
                call BlzFrameSetEnable(codexDialogDisplay, false)
            endif
        endif
        call BlzFrameSetVisible(buttonSelectedHighlight, true)

    else
        // Set the selected value to an invalid value
        set udg_Codex_UISelectedEntry = -1

        // Hide the display
        call BlzFrameSetVisible(codexDialogDisplay, false)
    endif

    // Clean the leaks
    set codexDialogDisplay = null
    set codexDialogDisplayTitle = null
    set buttonSelectedHighlight = null
endfunction

function CodexDialogEntryOneButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntryOneButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryTopLeftButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(1)

    // Clean the leaks
    set codexDialogEntryOneButtonSelectedHighlight = null
endfunction

function CodexDialogEntryTwoButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntryTwoButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryTopRightButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(2)

    // Clean the leaks
    set codexDialogEntryTwoButtonSelectedHighlight = null
endfunction

function CodexDialogEntryThreeButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntryThreeButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryCenterLeftButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(3)

    // Clean the leaks
    set codexDialogEntryThreeButtonSelectedHighlight = null
endfunction

function CodexDialogEntryFourButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntryFourButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryCenterRightButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(4)

    // Clean the leaks
    set codexDialogEntryFourButtonSelectedHighlight = null
endfunction

function CodexDialogEntryFiveButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntryFiveButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryBottomLeftButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(5)

    // Clean the leaks
    set codexDialogEntryFiveButtonSelectedHighlight = null
endfunction

function CodexDialogEntrySixButtonClickAction takes nothing returns nothing
    local framehandle codexDialogEntrySixButtonSelectedHighlight = BlzGetFrameByName("CodexDialogEntryBottomRightButtonSelectedHighlight" , 0)

    call CodexDialogEntryAllButtonsDeselect()
    call CodexDialogSelectEntry(6)

    // Clean the leaks
    set codexDialogEntrySixButtonSelectedHighlight = null
endfunction

function CodexDialogDoneButtonClickAction takes nothing returns nothing
    local framehandle allianceDialog = BlzGetFrameByName("AllianceDialog", 0)
    local framehandle allianceAcceptButton = BlzGetFrameByName("AllianceAcceptButton", 0)

    // Click on the alliance dialog button (focus is required to return control to player)
    call BlzFrameSetFocus(allianceDialog, true)
    call BlzFrameClick(allianceAcceptButton)

    // Clean the leaks
    set allianceDialog = null
    set allianceAcceptButton = null
endfunction

function SetupCodexDialog takes integer codexEntries returns nothing
    local framehandle codexDialogEntryOne = null
    local framehandle codexDialogEntryOneButton = null
    local trigger codexDialogEntryOneButtonTrigger = gg_trg_Codex_UI_Entry_One_Button_Clicked
    local framehandle codexDialogEntryTwo = null
    local framehandle codexDialogEntryTwoButton = null
    local trigger codexDialogEntryTwoButtonTrigger = gg_trg_Codex_UI_Entry_Two_Button_Clicked
    local framehandle codexDialogEntryThree = null
    local framehandle codexDialogEntryThreeButton = null
    local trigger codexDialogEntryThreeButtonTrigger = gg_trg_Codex_UI_Entry_Three_Button_Clicked
    local framehandle codexDialogEntryFour = null
    local framehandle codexDialogEntryFourButton = null
    local trigger codexDialogEntryFourButtonTrigger = gg_trg_Codex_UI_Entry_Four_Button_Clicked
    local framehandle codexDialogEntryFive = null
    local framehandle codexDialogEntryFiveButton = null
    local trigger codexDialogEntryFiveButtonTrigger = gg_trg_Codex_UI_Entry_Five_Button_Clicked
    local framehandle codexDialogEntrySix = null
    local framehandle codexDialogEntrySixButton = null
    local trigger codexDialogEntrySixButtonTrigger = gg_trg_Codex_UI_Entry_Six_Button_Clicked
    local framehandle codexDialogDoneButton = null
    local trigger codexDialogDoneButtonTrigger = gg_trg_Codex_UI_Done_Button_Clicked
    local trigger codexUIReloadTrigger = gg_trg_Codex_UI_Reload

    // Hide all alliance dialog default UI
    call BlzFrameSetVisible(BlzGetFrameByName("AllianceBackdrop", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AllianceTitle", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("ResourceTradingTitle", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("PlayersHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AllyHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("VisionHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("UnitsHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("GoldHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("LumberHeader", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AllianceCancelButton", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AlliedVictoryCheckBox", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AlliedVictoryLabel", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AllianceDialogScrollBar", 0), false)
    call BlzFrameSetVisible(BlzGetFrameByName("AllianceAcceptButton", 0), false)

    // Create the codex dialog as child of the alliance dialog (since it's bigger, it works well)
    // Note: this makes the dialog appear when the alliance dialog is shown by the game, we also make sure to not have a leaking equal dialog
    call BlzDestroyFrame(BlzGetFrameByName("CodexDialog",0))
    call BlzCreateFrame("CodexDialog", BlzGetFrameByName("AllianceDialog",0), 0,0)

    // Setup the done button events
    set codexDialogDoneButton = BlzGetFrameByName("CodexDialogDoneButton" , 0)
    call BlzTriggerRegisterFrameEvent(codexDialogDoneButtonTrigger, codexDialogDoneButton, FRAMEEVENT_CONTROL_CLICK)

    // Setup the entry one button events (also select it by default)
    set codexDialogEntryOne = BlzGetFrameByName("CodexDialogEntryTopLeft" , 0)
    if codexEntries > 0 then
        set codexDialogEntryOneButton = BlzGetFrameByName("CodexDialogEntryTopLeftButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntryOneButtonTrigger, codexDialogEntryOneButton, FRAMEEVENT_CONTROL_CLICK)
        call CodexDialogEntryAllButtonsDeselect()
        call CodexDialogSelectEntry(1)
    else
        call BlzFrameSetVisible(codexDialogEntryOne, false)
    endif

    // Setup the entry two button events
    set codexDialogEntryTwo = BlzGetFrameByName("CodexDialogEntryTopRight" , 0)
    if codexEntries > 1 then
        set codexDialogEntryTwoButton = BlzGetFrameByName("CodexDialogEntryTopRightButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntryTwoButtonTrigger, codexDialogEntryTwoButton, FRAMEEVENT_CONTROL_CLICK)
    else
        call BlzFrameSetVisible(codexDialogEntryTwo, false)
    endif

    // Setup the entry three button events
    set codexDialogEntryThree = BlzGetFrameByName("CodexDialogEntryCenterLeft" , 0)
    if codexEntries > 2 then
        set codexDialogEntryThreeButton = BlzGetFrameByName("CodexDialogEntryCenterLeftButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntryThreeButtonTrigger, codexDialogEntryThreeButton, FRAMEEVENT_CONTROL_CLICK)
    else
        call BlzFrameSetVisible(codexDialogEntryThree, false)
    endif

    // Setup the entry four button events
    set codexDialogEntryFour = BlzGetFrameByName("CodexDialogEntryCenterRight" , 0)
    if codexEntries > 3 then
        set codexDialogEntryFourButton = BlzGetFrameByName("CodexDialogEntryCenterRightButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntryFourButtonTrigger, codexDialogEntryFourButton, FRAMEEVENT_CONTROL_CLICK)
    else
        call BlzFrameSetVisible(codexDialogEntryFour, false)
    endif

    // Setup the entry five button events
    set codexDialogEntryFive = BlzGetFrameByName("CodexDialogEntryBottomLeft" , 0)
    if codexEntries > 4 then
        set codexDialogEntryFiveButton = BlzGetFrameByName("CodexDialogEntryBottomLeftButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntryFiveButtonTrigger, codexDialogEntryFiveButton, FRAMEEVENT_CONTROL_CLICK)
    else
        call BlzFrameSetVisible(codexDialogEntryFive, false)
    endif

    // Setup the entry six button events
    set codexDialogEntrySix = BlzGetFrameByName("CodexDialogEntryBottomRight" , 0)
    if codexEntries > 5 then
        set codexDialogEntrySixButton = BlzGetFrameByName("CodexDialogEntryBottomRightButton" , 0)
        call BlzTriggerRegisterFrameEvent(codexDialogEntrySixButtonTrigger, codexDialogEntrySixButton, FRAMEEVENT_CONTROL_CLICK)
    else
        call BlzFrameSetVisible(codexDialogEntrySix, false)
    endif

    // Make sure to update all entries (this is useful when the map is reloaded)
    call CodexDialogUpdateEntries()

    // Clean the leaks (we don't clean all the frames because they are called only one time)
    set codexDialogEntryOne = null
    set codexDialogEntryOneButton = null
    set codexDialogEntryTwo = null
    set codexDialogEntryTwoButton = null
    set codexDialogEntryThree = null
    set codexDialogEntryThreeButton = null
    set codexDialogEntryFour = null
    set codexDialogEntryFourButton = null
    set codexDialogEntryFive = null
    set codexDialogEntryFiveButton = null
    set codexDialogEntrySix = null
    set codexDialogEntrySixButton = null
    set codexDialogDoneButton = null
endfunction

function AlliesButtonKeepEnabled takes nothing returns nothing
    local framehandle alliesButton = BlzGetFrameByName("UpperButtonBarAlliesButton",0)
    local framehandle menuButton = BlzGetFrameByName("UpperButtonBarMenuButton",0)

    // Enable the allies button whenever the menu button is also enabled
    if BlzFrameGetEnable(menuButton) == true then
        if BlzFrameGetEnable(alliesButton) == false then
            call BlzFrameSetEnable(alliesButton, true)
        endif
    endif

    // Clean the leaks
    set alliesButton = null
    set menuButton = null
endfunction

function AllianceDialogKeepPaused takes nothing returns nothing
    local integer lastSelectedEntry = udg_Codex_UISelectedEntry
    local framehandle allianceDialog = BlzGetFrameByName("AllianceDialog",0)

    // Pause the game when alliance dialog is shown/hidden
    if BlzFrameIsVisible(allianceDialog) == true then
        if udg_Codex_UIEnabled == false then
            set udg_Codex_UIEnabled = true
            call ConditionalTriggerExecute(gg_trg_Codex_UI_Pause)
            call ConditionalTriggerExecute(gg_trg_Codex_UI_Maintenance_Menu)

            // Reselect the last selected entry to update display
            call CodexDialogEntryAllButtonsDeselect()
            call CodexDialogSelectEntry(lastSelectedEntry)
        endif
    endif

    // Clean the leaks
    set allianceDialog = null
endfunction

function AllianceDialogClearPaused takes nothing returns nothing
    local framehandle allianceDialog = BlzGetFrameByName("AllianceDialog",0)

    // Loop always when the alliance dialog is open (this is not stopped by the game pause)
    loop
        call TriggerSleepAction(0.1)
        // Keep the focus on the alliance dialog to avoid bugs on the player focus
        call BlzFrameSetFocus(allianceDialog, true)
        if BlzFrameIsVisible(allianceDialog) == false then
            if udg_Codex_UIEnabled == true then
                set udg_Codex_UIEnabled = false
                call ConditionalTriggerExecute(gg_trg_Codex_UI_Unpause)
            endif
        endif
        // Stop the loop (and then the trigger) as soon as the alliance menu is closed and the game unpaused
        exitwhen udg_Codex_UIEnabled == false

    endloop

    // Clean the leaks
    set allianceDialog = null
endfunction