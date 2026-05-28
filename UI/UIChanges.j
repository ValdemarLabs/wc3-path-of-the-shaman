library UIChanges initializer Init
///===========================================================================
/*
    UI Changes

    Author: [Valdemar]
    Version: 1.0
    
    XXX Description:
    This script modifies the UI by hiding certain elements and adjusting the position of others.

    Credits: Tasyen at HiveWorkshop

*/
//===========================================================================

private function QuestExpand takes nothing returns nothing
// Expand Quest-Description's space by taking Quest-Defeat-Condition reserved space.

    call BlzFrameClick(BlzGetFrameByName("UpperButtonBarQuestsButton", 0))
    call BlzFrameClick(BlzGetFrameByName("QuestAcceptButton", 0))
    call BlzFrameSetSize(BlzGetFrameByName("QuestItemListContainer", 0), 0.01, 0.01)
    call BlzFrameSetSize(BlzGetFrameByName("QuestItemListScrollBar", 0), 0.001, 0.001)
endfunction

private function HideBuffBar takes nothing returns nothing
// Hide BuffBar, as the BuffBar is reshown with selection a simple BlzFrameSetVisible false won't do it. Instead one creates a hidden parent and changes parentship:

    local framehandle newParent = BlzCreateFrameByType("SIMPLEFRAME", "", BlzGetFrameByName("ConsoleUI", 0), "", 0)
    call BlzFrameSetVisible(newParent, false)
    call BlzFrameSetParent(BlzGetOriginFrame(ORIGIN_FRAME_UNIT_PANEL_BUFF_BAR, 0), newParent)
endfunction

private function Init takes nothing returns nothing

    call QuestExpand()
    // call HideBuffBar()

endfunction

endlibrary