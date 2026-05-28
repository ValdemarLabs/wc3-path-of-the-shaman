library AchievementsUI initializer AutoInit requires Table, MasterUI
/**
    AchievementsUI

    Purpose:
    - Stores predefined achievements in one JASS library.
    - All achievements are always visible in the UI.
    - Locked achievements are shown greyed out.
    - External systems unlock achievements with a simple API call.

    Public API:
    - call AchievementsUI_Unlock(AchievementsUI_ACH_FIRST_BLOOD)
    - call AchievementsUI_Show()
    - call AchievementsUI_Hide()
    - if AchievementsUI_IsUnlocked(AchievementsUI_ACH_PATHFINDER) then

    How to add a new achievement:
    1. Add one new public integer name below, for example:
       public integer ACH_EXAMPLE = 0
    2. Add one registration line inside AUI_InitDefinitions():
       set ACH_EXAMPLE = AUI_RegisterAchievement(...)
    3. Unlock it from gameplay code with:
       call AchievementsUI_Unlock(AchievementsUI_ACH_EXAMPLE)
*/

globals
    public integer ACH_FIRST_BLOOD = 0
    public integer ACH_PATHFINDER = 0
    public integer ACH_CAMPKEEPER = 0

    private constant integer AUI_BUTTON_COUNT = 8
    private constant integer AUI_FRAME_CONTEXT = 2

    private boolean AUI_Initialized = false
    private integer AUI_DefinitionCount = 0

    private string AUI_TocPath = "war3mapImported/TasQuestBox.toc"
    private string AUI_Title = "Achievements"
    private string AUI_ReturnButtonText = "Return"
    private string AUI_UnlockSoundPath = "Sound\\Inferface\\GoodJob.wav"
    private string AUI_LockedDetailText = "|cff9f9f9fThis achievement has not been unlocked yet.|r"
    private string AUI_LockedTag = "|cff9f9f9fLocked|r"
    private string AUI_UnlockedTag = "|cff80ff80Unlocked|r"

    private integer array AUI_ViewOffset
    private integer array AUI_SelectedAchievementId

    private boolean array AUI_Unlocked
    private string array AUI_AchTitle
    private string array AUI_AchCategory
    private string array AUI_AchIcon
    private string array AUI_AchBody
    private string array AUI_AchUnlockMessage

    private framehandle AUI_Parent = null
    private framehandle AUI_ReturnButton = null
    private framehandle AUI_Slider = null
    private framehandle AUI_TitleFrame = null
    private framehandle AUI_TextArea = null
    private framehandle array AUI_Button
    private framehandle array AUI_ButtonIcon
    private framehandle array AUI_ButtonText

    private trigger AUI_CloseTrigger = null
    private trigger AUI_ReturnTrigger = null
    private trigger AUI_ClearFocusTrigger = null
    private trigger AUI_WheelTrigger = null
    private trigger AUI_SliderTrigger = null
    private trigger AUI_ButtonTrigger = null

    private Table AUI_ButtonRow = 0
endglobals

private function AUI_IsAchievementIdValid takes integer achievementId returns boolean
    return achievementId >= 1 and achievementId <= AUI_DefinitionCount
endfunction

private function AUI_GetDisplayPlayer takes nothing returns player
    return Player(0)
endfunction

private function AUI_PlayUnlockSound takes nothing returns nothing
    local sound s
    if GetLocalPlayer() == AUI_GetDisplayPlayer() then
        set s = CreateSound(AUI_UnlockSoundPath, false, false, false, 10, 10, "")
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endif
endfunction

private function AUI_GetAchievementIcon takes integer achievementId returns string
    if not AUI_IsAchievementIdValid(achievementId) or AUI_AchIcon[achievementId] == null or AUI_AchIcon[achievementId] == "" then
        return ""
    endif
    return AUI_AchIcon[achievementId]
endfunction

private function AUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function AUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function AUI_RegisterAchievement takes string title, string category, string iconPath, string bodyText, string unlockMessage returns integer
    local integer achievementId = AUI_DefinitionCount + 1
    set AUI_DefinitionCount = achievementId
    set AUI_AchTitle[achievementId] = title
    set AUI_AchCategory[achievementId] = category
    set AUI_AchIcon[achievementId] = iconPath
    set AUI_AchBody[achievementId] = bodyText
    set AUI_AchUnlockMessage[achievementId] = unlockMessage
    return achievementId
endfunction

private function AUI_InitDefinitions takes nothing returns nothing
    set ACH_FIRST_BLOOD = AUI_RegisterAchievement("First Blood", "Combat", "ReplaceableTextures\\CommandButtons\\BTNHeroBlademaster.blp", "Defeat your first hostile enemy.", "|cffffff80Achievement unlocked:|r First Blood")
    set ACH_PATHFINDER = AUI_RegisterAchievement("Pathfinder", "Exploration", "ReplaceableTextures\\CommandButtons\\BTNPackBeast.blp", "Discover and walk over a new graveyard or other key travel landmark.", "|cffffff80Achievement unlocked:|r Pathfinder")
    set ACH_CAMPKEEPER = AUI_RegisterAchievement("Campkeeper", "Survival", "ReplaceableTextures\\CommandButtons\\BTNFarm.blp", "Successfully build and maintain your first field camp setup.", "|cffffff80Achievement unlocked:|r Campkeeper")
endfunction

private function AUI_GetSelectedAchievementId takes player whichPlayer returns integer
    local integer pid = GetPlayerId(whichPlayer)
    if AUI_IsAchievementIdValid(AUI_SelectedAchievementId[pid]) then
        return AUI_SelectedAchievementId[pid]
    endif
    if AUI_DefinitionCount > 0 then
        return 1
    endif
    return 0
endfunction

private function AUI_UpdateUI takes nothing returns nothing
    local integer pid = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer achievementId
    local integer maxPage = 0
    local integer selectedAchievementId
    local string detailText
    local string rowText

    if AUI_Parent == null or not BlzFrameIsVisible(AUI_Parent) then
        return
    endif

    if AUI_DefinitionCount > AUI_BUTTON_COUNT then
        set maxPage = (AUI_DefinitionCount - 1) / AUI_BUTTON_COUNT
    endif
    if AUI_ViewOffset[pid] < 0 then
        set AUI_ViewOffset[pid] = 0
    elseif AUI_ViewOffset[pid] > maxPage * AUI_BUTTON_COUNT then
        set AUI_ViewOffset[pid] = maxPage * AUI_BUTTON_COUNT
    endif

    call BlzFrameSetMinMaxValue(AUI_Slider, 0.0, I2R(maxPage))
    call BlzFrameSetValue(AUI_Slider, I2R(AUI_ViewOffset[pid] / AUI_BUTTON_COUNT))

    loop
        exitwhen rowIndex > AUI_BUTTON_COUNT
        set achievementId = AUI_ViewOffset[pid] + rowIndex
        if achievementId <= AUI_DefinitionCount then
            if AUI_GetAchievementIcon(achievementId) != "" then
                call BlzFrameSetTexture(AUI_ButtonIcon[rowIndex], AUI_GetAchievementIcon(achievementId), 0, false)
                call BlzFrameSetVisible(AUI_ButtonIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(AUI_ButtonIcon[rowIndex], false)
            endif
            if AUI_Unlocked[achievementId] then
                set rowText = "|cffffffff" + AUI_AchTitle[achievementId] + "|r"
            else
                set rowText = "|cff8f8f8f" + AUI_AchTitle[achievementId] + "|r"
            endif
            call BlzFrameSetText(AUI_ButtonText[rowIndex], rowText)
            call BlzFrameSetVisible(AUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(AUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedAchievementId = AUI_GetSelectedAchievementId(GetLocalPlayer())
    if selectedAchievementId <= 0 then
        call BlzFrameSetText(AUI_TitleFrame, AUI_Title)
        call BlzFrameSetText(AUI_TextArea, "No achievements configured.")
        return
    endif

    set AUI_SelectedAchievementId[pid] = selectedAchievementId
    if AUI_Unlocked[selectedAchievementId] then
        set detailText = AUI_UnlockedTag + " - " + AUI_AchCategory[selectedAchievementId] + "|n|n" + AUI_AchBody[selectedAchievementId]
    else
        set detailText = AUI_LockedTag + " - " + AUI_AchCategory[selectedAchievementId] + "|n|n" + AUI_LockedDetailText
    endif
    call BlzFrameSetText(AUI_TitleFrame, AUI_Title + " - " + AUI_AchTitle[selectedAchievementId])
    call BlzFrameSetText(AUI_TextArea, detailText)
endfunction

public function ForceUpdate takes nothing returns nothing
    call AUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if AUI_Parent != null then
        call BlzFrameSetVisible(AUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    call BlzFrameSetVisible(AUI_Parent, true)
    call AUI_UpdateUI()
endfunction

private function AUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(AUI_Parent, false)
    endif
endfunction

private function AUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function AUI_SliderAction takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    set AUI_ViewOffset[pid] = R2I(BlzGetTriggerFrameValue()) * AUI_BUTTON_COUNT
    call AUI_UpdateUI()
endfunction

private function AUI_WheelAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        if BlzGetTriggerFrameValue() > 0.0 then
            call BlzFrameSetValue(AUI_Slider, BlzFrameGetValue(AUI_Slider) + 1.0)
        else
            call BlzFrameSetValue(AUI_Slider, BlzFrameGetValue(AUI_Slider) - 1.0)
        endif
    endif
endfunction

private function AUI_ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = 0
    local integer achievementId = 0

    if AUI_ButtonRow.has(GetHandleId(BlzGetTriggerFrame())) then
        set rowIndex = AUI_ButtonRow.integer[GetHandleId(BlzGetTriggerFrame())]
        set achievementId = AUI_ViewOffset[pid] + rowIndex
        if achievementId <= AUI_DefinitionCount then
            set AUI_SelectedAchievementId[pid] = achievementId
            if GetLocalPlayer() == p then
                call AUI_UpdateUI()
            endif
        endif
    endif

    set p = null
endfunction

private function AUI_InitFrames takes nothing returns nothing
    local framehandle frame
    local integer rowIndex = 1

    call BlzLoadTOCFile(AUI_TocPath)

    set AUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, AUI_FRAME_CONTEXT)
    call AUI_PosBox(AUI_Parent)

    set AUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", AUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(AUI_SliderTrigger, AUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(AUI_WheelTrigger, AUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(AUI_Slider, 0.0, 0.0)

    set frame = BlzCreateFrameByType("SLIDER", "AchievementsUIMoreScroll", AUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(AUI_WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, AUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, AUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set AUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", AUI_FRAME_CONTEXT)
    set AUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", AUI_FRAME_CONTEXT)
    call BlzFrameSetText(AUI_TitleFrame, AUI_Title)

    call BlzTriggerRegisterFrameEvent(AUI_CloseTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", AUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", AUI_FRAME_CONTEXT), FRAMEEVENT_CONTROL_CLICK)

    set AUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "AchievementsUIReturnButton", AUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(AUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(AUI_ReturnButton, AUI_ReturnButtonText)
    call BlzFrameSetPoint(AUI_ReturnButton, FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("TasQuestBoxCloseButton1", AUI_FRAME_CONTEXT), FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(AUI_ReturnTrigger, AUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, AUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > AUI_BUTTON_COUNT
        set AUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", AUI_Parent, 0, rowIndex + 200)
        if rowIndex > 1 then
            call BlzFrameSetPoint(AUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, AUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set AUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 200)
        set AUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 200)
        set AUI_ButtonRow.integer[GetHandleId(AUI_Button[rowIndex])] = rowIndex
        call BlzTriggerRegisterFrameEvent(AUI_ButtonTrigger, AUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(AUI_ClearFocusTrigger, AUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(AUI_WheelTrigger, AUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(AUI_Button[1], FRAMEPOINT_TOPRIGHT, AUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    call BlzFrameSetVisible(AUI_Parent, false)
endfunction

public function Init takes nothing returns nothing
    if AUI_Initialized then
        return
    endif
    set AUI_Initialized = true

    set AUI_ButtonRow = Table.create()
    call AUI_InitDefinitions()

    set AUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(AUI_CloseTrigger, function AUI_CloseAction)

    set AUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ReturnTrigger, function AUI_ReturnAction)

    set AUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ClearFocusTrigger, function AUI_ClearFocusAction)

    set AUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(AUI_ButtonTrigger, function AUI_ButtonAction)

    set AUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(AUI_SliderTrigger, function AUI_SliderAction)

    set AUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(AUI_WheelTrigger, function AUI_WheelAction)

    call AUI_InitFrames()
endfunction

public function IsUnlocked takes integer achievementId returns boolean
    if not AUI_IsAchievementIdValid(achievementId) then
        return false
    endif
    return AUI_Unlocked[achievementId]
endfunction

public function Unlock takes integer achievementId returns nothing
    local integer pid

    if not AUI_IsAchievementIdValid(achievementId) or AUI_Unlocked[achievementId] then
        return
    endif

    set AUI_Unlocked[achievementId] = true
    set pid = GetPlayerId(AUI_GetDisplayPlayer())
    if AUI_SelectedAchievementId[pid] <= 0 then
        set AUI_SelectedAchievementId[pid] = achievementId
    endif

    call AUI_PlayUnlockSound()
    if AUI_AchUnlockMessage[achievementId] != null and AUI_AchUnlockMessage[achievementId] != "" then
        call DisplayTextToPlayer(AUI_GetDisplayPlayer(), 0, 0, AUI_AchUnlockMessage[achievementId])
    endif
    call AUI_UpdateUI()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
