
library TasQuestBox initializer AutoInit
/**
 TasQuestBox V1.3 by Tasyen
A UI to display Text to players, can use quests and search in the content. suited more for slower pace.
It shows possible pages in a list clicking anything in the list will show the text for that page.

TasQuestBox_Add(string name, string text, string icon)
 add a new entry
 name is displayed in the list
 text a big text when this is selected
 icon is shown next to the title in the pageList, "" or nil show no icon.

TasQuestBox_Remove(integer index)
 start with index 1

TasQuestBox_ForceUpdate()
 */
globals
    // Where is the TOCFile in your map?
    public string TocPath = "war3mapImported/TasQuestBox.toc"
    public boolean AutoRun = true //(true) will create Itself at 0s, (false) you need to TasQuestBox_Init()
    public boolean ReplaceQuestButton = false // hide default questbutton and place a custom one to open this
    public string SoundFile = "Sound/Interface/QuestActivateWhat1.wav" // is played when the open button is clicked make it nil to have no sound
    public sound Sound = null 
    public string Title = "TasQuestBox"
    public integer ButtonCount = 8 //amout of buttons in one Row

    public integer array ViewOffset // currentPage

    public string array DataText 
    public string array DataIcon 
    public string array DataName
    public integer DataCount = 0

    public framehandle Parent
    public framehandle SuperParent
    public framehandle Open
    public framehandle Slider = null
    public framehandle TitleFrame
    public framehandle TextArea
    public framehandle array Button
    public framehandle array ButtonIcon
    public framehandle array ButtonText
    

    public trigger OpenTrigger
    public trigger ClearFocusTrigger
    public trigger WheelTrigger
    public trigger SliderTrigger
    public trigger ButtonTrigger

endglobals

//Happens once at creation, where to pos the whole ui
public function PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction
//Happens once at creation, decides where Open Button is posed
public function PosOpen takes framehandle frame returns nothing
    local framehandle questbutton = BlzGetFrameByName("UpperButtonBarQuestsButton", 0)
    if ReplaceQuestButton then
        call BlzFrameSetAllPoints(frame, questbutton)
        call BlzFrameSetVisible(questbutton, false)
    else
        call BlzFrameSetSize(frame, BlzFrameGetWidth(questbutton), BlzFrameGetHeight(questbutton))
        // Move to the left of the quest button
        call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, questbutton, FRAMEPOINT_TOPLEFT, -0.002, 0.0)
        // This would move it below the quest button instead
        // call BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, questbutton, FRAMEPOINT_BOTTOMLEFT, 0, 0)
    endif
endfunction

//Add one skill for this key
public function Add takes string name, string text, string icon returns nothing
    set DataCount = DataCount + 1
   set DataName[DataCount] = name
   set DataText[DataCount] = text
   set DataIcon[DataCount] = icon
   if Slider != null then
    call BlzFrameSetMinMaxValue(Slider, 0, DataCount/ButtonCount)
   endif
endfunction

//Add one skill for this key
public function Remove takes integer index returns boolean
    local integer i = index
    if index <= 0 or index > DataCount then 
        return false 
    endif
    loop
        exitwhen i >= DataCount
        set DataName[i] = DataName[i + 1]
        set DataText[i] = DataText[i + 1]
        set DataIcon[i] = DataIcon[i + 1]
        set i = i + 1
    endloop
    set DataCount = DataCount - 1
   if Slider != null then
    call BlzFrameSetMinMaxValue(Slider, 0, DataCount/ButtonCount)
   endif
   return true
endfunction

// config functions relevant to user

// ParentFunc who you want as parent, this runs at InitBlizzard, if you need more control you need to modify the part that calls local function Init()
    public function ParentFunc takes nothing returns framehandle
        return BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    endfunction

// System code

//async
public function UpdateUI takes nothing returns nothing    
    local integer i
    local integer skillIndex
    local integer view = ViewOffset[GetPlayerId(GetLocalPlayer())]

    if BlzFrameIsVisible(Parent) then
        set i = 1
    loop
        exitwhen i > ButtonCount
        set skillIndex = i + view
        if skillIndex <= DataCount then
            if DataIcon[skillIndex] != "" then
                call BlzFrameSetTexture(ButtonIcon[i], DataIcon[skillIndex], 0, false)
                call BlzFrameSetVisible(ButtonIcon[i], true)
            else
                call BlzFrameSetVisible(ButtonIcon[i], false)
            endif
            call BlzFrameSetText(ButtonText[i], GetLocalizedString(DataName[skillIndex]))
            call BlzFrameSetVisible(Button[i], true)
        else
            call BlzFrameSetVisible(Button[i], false)
        endif
        set i = i + 1
    endloop
    endif
endfunction

public function ForceUpdate takes nothing returns nothing  
    call UpdateUI()
endfunction

private function ESCAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetVisible(Parent, false)
    endif
endfunction
private function SliderAction takes nothing returns nothing
    set ViewOffset[GetPlayerId(GetTriggerPlayer())] = R2I(BlzGetTriggerFrameValue()*ButtonCount)
    call UpdateUI()
endfunction
private function WheelAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        if BlzGetTriggerFrameValue() > 0 then 
            call BlzFrameSetValue(Slider, BlzFrameGetValue(Slider) + 1)
        else
            call BlzFrameSetValue(Slider, BlzFrameGetValue(Slider) - 1)
        endif
    endif
endfunction
private function ClearFoucsAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction


private function OpenAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call StartSound(Sound)
        call BlzFrameSetVisible(Parent, not BlzFrameIsVisible(Parent))   
        call UpdateUI()     
    endif
endfunction
private function ButtonAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pId = GetPlayerId(p)
    local integer i = S2I(BlzFrameGetText(BlzGetTriggerFrame())) + ViewOffset[pId]
    if GetLocalPlayer() == p then
        call BlzFrameSetText(TextArea, GetLocalizedString(DataText[i]))
        call BlzFrameSetText(TitleFrame, Title + " - "+ GetLocalizedString(DataName[i]))
    endif
endfunction

private function InitFrames takes nothing returns nothing

local framehandle frame
local integer i
    call BlzLoadTOCFile(TocPath)
    set Parent = BlzCreateFrame("TasQuestBox", ParentFunc(), 0, 0)    
    if GetHandleId(Parent) == 0 then
        call BJDebugMsg("Error - TasQuestBox Create")
        call BJDebugMsg("Check Imported toc & fdf file")
    endif
    call PosBox(Parent)
    set Slider = BlzGetFrameByName("TasQuestBoxSlider1", 0)
    call BlzTriggerRegisterFrameEvent(SliderTrigger, Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(WheelTrigger, Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(Slider, 0, DataCount/ButtonCount)

    set frame = BlzCreateFrameByType("SLIDER", "MoreScroll", Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(WheelTrigger, frame, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.00)
    call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMLEFT, Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", 0)
    set TitleFrame = BlzGetFrameByName("TasQuestBoxText1", 0)
    call BlzFrameSetText(TitleFrame, Title)

    set frame = BlzCreateFrameByType("GLUETEXTBUTTON", "MapInfoButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "ScriptDialogButton", 0)
    call PosOpen(frame)         
    call BlzFrameSetText(frame, GetLocalizedString("Zones"))
    call BlzTriggerRegisterFrameEvent(OpenTrigger, frame, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ClearFocusTrigger, frame, FRAMEEVENT_CONTROL_CLICK)

    call BlzTriggerRegisterFrameEvent(OpenTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", 0), FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(ClearFocusTrigger, BlzGetFrameByName("TasQuestBoxCloseButton1", 0), FRAMEEVENT_CONTROL_CLICK)

    set i = 1
    loop
        exitwhen i > ButtonCount
        set Button[i] = BlzCreateFrame("TasQuestBoxButton", Parent, 0, i)
        call BlzFrameSetText(Button[i], I2S(i))
        // reserve HandleIds to allow async access later
        set ButtonIcon[i] = BlzGetFrameByName("TasQuestBoxButtonIcon", i)
        set ButtonText[i] =  BlzGetFrameByName("TasQuestBoxButtonText", i)

        if i > 1 then
            call BlzFrameSetPoint(Button[i] , FRAMEPOINT_TOPLEFT, Button[i - 1] , FRAMEPOINT_BOTTOMLEFT, 0., -0.002)
        endif
        call BlzTriggerRegisterFrameEvent(ButtonTrigger, Button[i], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(ClearFocusTrigger, Button[i], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(WheelTrigger, Button[i], FRAMEEVENT_MOUSE_WHEEL)

        set i = i + 1
    endloop
    call BlzFrameSetPoint(Button[1], FRAMEPOINT_TOPRIGHT, Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.00)

    call BlzFrameSetVisible(Parent, false)
endfunction

// added cinematic hooks to hide the UI during cinematics
private function OnCinematicStart takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        // Hide the custom UI during cinematic
        call BlzFrameSetVisible(Parent, false)
        call BlzFrameSetVisible(Open, false) // also hide the Zones button
    endif
endfunction

private function OnCinematicEnd takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        // Re-show the Zones button (but not force-open the UI window)
        call BlzFrameSetVisible(Open, true)
    endif
endfunction
    
    public function Init takes nothing returns nothing
        local trigger trig
        local integer i
        set Sound = CreateSound(SoundFile, false, false, false, 10000, 10000, "")
        
        // ESC hides UI
        set trig = CreateTrigger()
        call TriggerAddAction(trig, function ESCAction)
        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYERS
            call TriggerRegisterPlayerEventEndCinematic(trig, Player(i))
            call TriggerRegisterPlayerEventEndCinematic(trig, Player(i)) // keep ESC working after cinematic
            set i = i + 1
        endloop

        /*
        // Cinematic START → hide Zones UI
        set trig = CreateTrigger()
        call TriggerAddAction(trig, function OnCinematicStart)
        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYERS
            call TriggerRegisterPlayerEventCinematicStart(trig, Player(i))
            set i = i + 1
        endloop
        */

        // Cinematic END → restore Zones button (but not force-open the panel)
        set trig = CreateTrigger()
        call TriggerAddAction(trig, function OnCinematicEnd)
        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYERS
            call TriggerRegisterPlayerEventEndCinematic(trig, Player(i))
            set i = i + 1
        endloop

        // Other triggers
        set ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(ClearFocusTrigger, function ClearFoucsAction)

        set ButtonTrigger = CreateTrigger()
        call TriggerAddAction(ButtonTrigger, function ButtonAction)

        set SliderTrigger = CreateTrigger()
        call TriggerAddAction(SliderTrigger, function SliderAction)

        set WheelTrigger = CreateTrigger()
        call TriggerAddAction(WheelTrigger, function WheelAction)

    set OpenTrigger = CreateTrigger()
    call TriggerAddAction(OpenTrigger, function OpenAction)

        call InitFrames()
        static if LIBRARY_FrameLoader then
            call FrameLoaderAdd(function InitFrames)
        endif
    endfunction
    public function AutoInit takes nothing returns nothing
        if AutoRun then
            call Init()
        endif
    endfunction
endlibrary