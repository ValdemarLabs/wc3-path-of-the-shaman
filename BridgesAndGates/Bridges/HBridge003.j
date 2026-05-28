library HBridge003 initializer Init requires BridgeSystem

globals
    private integer HBridge003_Id = 0
endglobals

function HBridge003_Activate takes unit whichUnit returns nothing
    call BridgeSystem_Activate(HBridge003_Id, whichUnit)
endfunction

function HBridge003_Deactivate takes unit whichUnit returns nothing
    call BridgeSystem_Deactivate(HBridge003_Id, whichUnit)
endfunction

private function Init takes nothing returns nothing
    local integer bridgeId = BridgeSystem_Create("HBridge003", gg_rct_HBridge003)

    set HBridge003_Id = bridgeId

    call BridgeSystem_RegisterDefaultControlledTypes(bridgeId)

    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR1)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR2)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR3)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR4)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR5)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR6)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR7)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR8)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR9)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR10)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR11)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR12)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR13)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR14)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR15)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge003PBR16)

    // C/D are the top-lane bridge entry rects.
    // Entering them activates the bridge-top crossing flow.
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge003C)
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge003D)

    // A/B are the under-bridge entry rects.
    // They are only bridge-managed while a top-lane C/D crossing is active;
    // otherwise units under the bridge move normally.
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_HBridge003A)
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_HBridge003B)

    // Optional approach redirect rects:
    // if a unit is inside one of these outer approach areas and is issued a
    // movement order into the main bridge rect, redirect it to the matching
    // entry rect center first so the bridge logic can take over cleanly.
    // Under-lane A/B approach redirects only matter while top-lane traffic is active.
    call BridgeSystem_SetTopApproach(bridgeId, 1, gg_rct_HBridge003Carea)
    call BridgeSystem_SetTopApproach(bridgeId, 2, gg_rct_HBridge003Darea)
    call BridgeSystem_SetUnderApproach(bridgeId, 1, gg_rct_HBridge003Aarea)
    call BridgeSystem_SetUnderApproach(bridgeId, 2, gg_rct_HBridge003Barea)

    // Optional lane ghost collision overrides.
    // Defaults are true for both lanes.
    //call BridgeSystem_SetTopLaneGhostCollision(bridgeId, false)
    call BridgeSystem_SetUnderLaneGhostCollision(bridgeId, false)

    call BridgeSystem_FinalizeSetup(bridgeId)
endfunction

endlibrary
