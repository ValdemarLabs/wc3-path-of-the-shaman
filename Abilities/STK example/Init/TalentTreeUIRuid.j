globals 
    framehandle TalentMainFrame = null 
    trigger TriggerTalentMainFrame = null 
    framehandle TreeLeft = null 
    trigger TriggerTreeLeft = null 
    framehandle TreeMiddle = null 
    trigger TriggerTreeMiddle = null 
    framehandle TreeRight = null 
    trigger TriggerTreeRight = null 
    framehandle ConfirmTalentsButton = null 
    trigger TriggerConfirmTalentsButton = null 
    framehandle CancelTalentsButton = null 
    trigger TriggerCancelTalentsButton = null 
    framehandle CloseTalentViewButton = null 
    trigger TriggerCloseTalentViewButton = null 
    framehandle TreeBackgroundLeft = null 
    trigger TriggerTreeBackgroundLeft = null 
    framehandle TitleBackgroundLeft = null 
    trigger TriggerTitleBackgroundLeft = null 
    framehandle TreeBackgroundMiddle = null 
    trigger TriggerTreeBackgroundMiddle = null 
    framehandle TitleBackgroundMiddle = null 
    trigger TriggerTitleBackgroundMiddle = null 
    framehandle TreeBackgroundRight = null 
    trigger TriggerTreeBackgroundRight = null 
    framehandle TitleBackgroundRight = null 
    trigger TriggerTitleBackgroundRight = null 
    framehandle TitleLeft = null 
    trigger TriggerTitleLeft = null 
    framehandle TitleMiddle = null 
    trigger TriggerTitleMiddle = null 
    framehandle TitleRight = null 
    trigger TriggerTitleRight = null 
endglobals 
     
library REFORGEDUIMAKER initializer init 
    function ConfirmTalentsButtonFunc takes nothing returns nothing 
        call BlzFrameSetEnable(ConfirmTalentsButton, false) 
        call BlzFrameSetEnable(ConfirmTalentsButton, true) 
    endfunction 
     
    function CancelTalentsButtonFunc takes nothing returns nothing 
        call BlzFrameSetEnable(CancelTalentsButton, false) 
        call BlzFrameSetEnable(CancelTalentsButton, true) 
    endfunction 
     
    function CloseTalentViewButtonFunc takes nothing returns nothing 
        call BlzFrameSetEnable(CloseTalentViewButton, false) 
        call BlzFrameSetEnable(CloseTalentViewButton, true) 
    endfunction 
     
    private function init takes nothing returns nothing 
    
    
        set TalentMainFrame = BlzCreateFrame("EscMenuBackdrop", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0) 
        call BlzFrameSetAbsPoint(TalentMainFrame, FRAMEPOINT_TOPLEFT, 0.000574000, 0.530800) 
        call BlzFrameSetAbsPoint(TalentMainFrame, FRAMEPOINT_BOTTOMRIGHT, 0.516074, 0.152300)
        call BlzFrameSetVisible(TalentMainFrame, false) // +++++++++++++++++
    
        // set TreeLeft = BlzCreateFrameByType("ListBoxWar3", "TreeLeft", TalentMainFrame, "", 1) 
        set TreeLeft = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1) // Switch
        call BlzFrameSetAbsPoint(TreeLeft, FRAMEPOINT_TOPLEFT, 0.0207000, 0.49)
        call BlzFrameSetAbsPoint(TreeLeft, FRAMEPOINT_BOTTOMRIGHT, 0.175400, 0.179700)
        call BlzFrameSetVisible(TreeLeft, false) // +++++++++++++++++
        // call BlzFrameSetTexture(TreeLeft, "", 0, true) ----------------
    
        // set TreeMiddle = BlzCreateFrameByType("BACKDROP", "TreeMiddle", TalentMainFrame, "", 1) 
        set TreeMiddle = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1) // Switch
        call BlzFrameSetAbsPoint(TreeMiddle, FRAMEPOINT_TOPLEFT, 0.179400, 0.49) 
        call BlzFrameSetAbsPoint(TreeMiddle, FRAMEPOINT_BOTTOMRIGHT, 0.334100, 0.180300)
        call BlzFrameSetVisible(TreeMiddle, false) // +++++++++++++++++
        // call BlzFrameSetTexture(TreeMiddle, "", 0, true) ----------------
    
        // set TreeRight = BlzCreateFrameByType("BACKDROP", "TreeRight", TalentMainFrame, "", 1) 
        set TreeRight = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1) // Switch
        call BlzFrameSetAbsPoint(TreeRight, FRAMEPOINT_TOPLEFT, 0.338200, 0.49)
        call BlzFrameSetAbsPoint(TreeRight, FRAMEPOINT_BOTTOMRIGHT, 0.492900, 0.180400)
        call BlzFrameSetVisible(TreeRight, false) // +++++++++++++++++
        // call BlzFrameSetTexture(TreeRight, "", 0, true) ----------------
    
        set ConfirmTalentsButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0) 
        call BlzFrameSetAbsPoint(ConfirmTalentsButton, FRAMEPOINT_TOPLEFT, 0.0207000, 0.180410) 
        call BlzFrameSetAbsPoint(ConfirmTalentsButton, FRAMEPOINT_BOTTOMRIGHT, 0.123700, 0.151000) 
        call BlzFrameSetText(ConfirmTalentsButton, "|cffFCD20DConfirm|r") 
        call BlzFrameSetScale(ConfirmTalentsButton, 1.00) 
        set TriggerConfirmTalentsButton = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerConfirmTalentsButton, ConfirmTalentsButton, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerConfirmTalentsButton, function ConfirmTalentsButtonFunc) 
    
        set CancelTalentsButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0) 
        call BlzFrameSetAbsPoint(CancelTalentsButton, FRAMEPOINT_TOPLEFT, 0.389900, 0.180410) 
        call BlzFrameSetAbsPoint(CancelTalentsButton, FRAMEPOINT_BOTTOMRIGHT, 0.492900, 0.151000) 
        call BlzFrameSetText(CancelTalentsButton, "|cffFCD20DCancel|r") 
        call BlzFrameSetScale(CancelTalentsButton, 1.00) 
        set TriggerCancelTalentsButton = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerCancelTalentsButton, CancelTalentsButton, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerCancelTalentsButton, function CancelTalentsButtonFunc) 
    
        set CloseTalentViewButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0) 
        call BlzFrameSetAbsPoint(CloseTalentViewButton, FRAMEPOINT_TOPLEFT, 0.49, 0.53) 
        call BlzFrameSetAbsPoint(CloseTalentViewButton, FRAMEPOINT_BOTTOMRIGHT, 0.515, 0.505) 
        call BlzFrameSetText(CloseTalentViewButton, "|cffFCD20DX|r") 
        call BlzFrameSetScale(CloseTalentViewButton, 1.00) 
        set TriggerCloseTalentViewButton = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerCloseTalentViewButton, CloseTalentViewButton, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerCloseTalentViewButton, function CloseTalentViewButtonFunc) 
    
        set TreeBackgroundLeft = BlzCreateFrameByType("BACKDROP", "TreeBackgroundLeft", TreeLeft, "", 1) 
        call BlzFrameSetAbsPoint(TreeBackgroundLeft, FRAMEPOINT_TOPLEFT, 0.0297000, 0.48)
        call BlzFrameSetAbsPoint(TreeBackgroundLeft, FRAMEPOINT_BOTTOMRIGHT, 0.1664, 0.1887)
        call BlzFrameSetTexture(TreeBackgroundLeft, "", 0, true) 
    
        set TitleBackgroundLeft = BlzCreateFrameByType("BACKDROP", "TitleBackgroundLeft", TreeLeft, "", 1) 
        call BlzFrameSetAbsPoint(TitleBackgroundLeft, FRAMEPOINT_TOPLEFT, 0.0167000, 0.506)
        call BlzFrameSetAbsPoint(TitleBackgroundLeft, FRAMEPOINT_BOTTOMRIGHT, 0.179400, 0.48)
        call BlzFrameSetTexture(TitleBackgroundLeft, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true) 
    
        set TreeBackgroundMiddle = BlzCreateFrameByType("BACKDROP", "TreeBackgroundMiddle", TreeMiddle, "", 1) 
        call BlzFrameSetAbsPoint(TreeBackgroundMiddle, FRAMEPOINT_TOPLEFT, 0.1884, 0.48)
        call BlzFrameSetAbsPoint(TreeBackgroundMiddle, FRAMEPOINT_BOTTOMRIGHT, 0.3251, 0.1893)
        call BlzFrameSetTexture(TreeBackgroundMiddle, "", 0, true) 
    
        set TitleBackgroundMiddle = BlzCreateFrameByType("BACKDROP", "TitleBackgroundMiddle", TreeMiddle, "", 1) 
        call BlzFrameSetAbsPoint(TitleBackgroundMiddle, FRAMEPOINT_TOPLEFT, 0.1754, 0.506) 
        call BlzFrameSetAbsPoint(TitleBackgroundMiddle, FRAMEPOINT_BOTTOMRIGHT, 0.3381, 0.48)
        call BlzFrameSetTexture(TitleBackgroundMiddle, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true) 
    
        set TreeBackgroundRight = BlzCreateFrameByType("BACKDROP", "TreeBackgroundRight", TreeRight, "", 1) 
        call BlzFrameSetAbsPoint(TreeBackgroundRight, FRAMEPOINT_TOPLEFT, 0.3472, 0.48)
        call BlzFrameSetAbsPoint(TreeBackgroundRight, FRAMEPOINT_BOTTOMRIGHT, 0.4839, 0.1894)
        call BlzFrameSetTexture(TreeBackgroundRight, "", 0, true) 
    
        set TitleBackgroundRight = BlzCreateFrameByType("BACKDROP", "TitleBackgroundRight", TreeRight, "", 1) 
        call BlzFrameSetAbsPoint(TitleBackgroundRight, FRAMEPOINT_TOPLEFT, 0.3342, 0.506) 
        call BlzFrameSetAbsPoint(TitleBackgroundRight, FRAMEPOINT_BOTTOMRIGHT, 0.4969, 0.48) 
        call BlzFrameSetTexture(TitleBackgroundRight, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true) 
    
        set TitleLeft = BlzCreateFrameByType("TEXT", "name", TitleBackgroundLeft, "", 0) 
        call BlzFrameSetAbsPoint(TitleLeft, FRAMEPOINT_TOPLEFT, 0.0359600, 0.506) 
        call BlzFrameSetAbsPoint(TitleLeft, FRAMEPOINT_BOTTOMRIGHT, 0.160560, 0.48) 
        call BlzFrameSetText(TitleLeft, "|cffFFFFFFFirst Tree|r") 
        call BlzFrameSetEnable(TitleLeft, false) 
        call BlzFrameSetScale(TitleLeft, 1.00) 
        call BlzFrameSetTextAlignment(TitleLeft, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE) 
    
        set TitleMiddle = BlzCreateFrameByType("TEXT", "name", TitleBackgroundMiddle, "", 0) 
        call BlzFrameSetAbsPoint(TitleMiddle, FRAMEPOINT_TOPLEFT, 0.196000, 0.506) 
        call BlzFrameSetAbsPoint(TitleMiddle, FRAMEPOINT_BOTTOMRIGHT, 0.320600, 0.48) 
        call BlzFrameSetText(TitleMiddle, "|cffFFFFFFText Frame|r") 
        call BlzFrameSetEnable(TitleMiddle, false) 
        call BlzFrameSetScale(TitleMiddle, 1.00) 
        call BlzFrameSetTextAlignment(TitleMiddle, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE) 
    
        set TitleRight = BlzCreateFrameByType("TEXT", "name", TitleBackgroundRight, "", 0) 
        call BlzFrameSetAbsPoint(TitleRight, FRAMEPOINT_TOPLEFT, 0.353700, 0.506) 
        call BlzFrameSetAbsPoint(TitleRight, FRAMEPOINT_BOTTOMRIGHT, 0.479100, 0.48) 
        call BlzFrameSetText(TitleRight, "|cffFFFFFFText Frame|r") 
        call BlzFrameSetEnable(TitleRight, false) 
        call BlzFrameSetScale(TitleRight, 1.00) 
        call BlzFrameSetTextAlignment(TitleRight, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE) 
    endfunction 
endlibrary
    