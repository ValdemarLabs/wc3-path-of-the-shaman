library HBridge002 initializer Init requires BridgeSystem

globals
    private integer HBridge002_Id = 0
endglobals

function HBridge002_Activate takes unit whichUnit returns nothing
    call BridgeSystem_Activate(HBridge002_Id, whichUnit)
endfunction

function HBridge002_Deactivate takes unit whichUnit returns nothing
    call BridgeSystem_Deactivate(HBridge002_Id, whichUnit)
endfunction

private function Init takes nothing returns nothing
    local integer bridgeId = BridgeSystem_Create("HBridge002", gg_rct_HBridge002)

    set HBridge002_Id = bridgeId

    call BridgeSystem_RegisterDefaultControlledTypes(bridgeId)

    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR1)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR2)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR3)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR4)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR5)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR6)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR7)
    call BridgeSystem_AddEntryBlockerPoint(bridgeId, gg_rct_HBridge002PBR8)

    // C/D are the top-lane bridge entry rects.
    // Entering them activates the bridge-top crossing flow.
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge002C)
    call BridgeSystem_AddActivateRect(bridgeId, gg_rct_HBridge002D)

    // A/B are the under-bridge entry rects.
    // They are only bridge-managed while a top-lane C/D crossing is active;
    // otherwise units under the bridge move normally.
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_HBridge002A)
    call BridgeSystem_AddDeactivateRect(bridgeId, gg_rct_HBridge002B)

    // Optional approach redirect rects:
    // if a unit is inside one of these outer approach areas and is issued a
    // movement order into the main bridge rect, redirect it to the matching
    // entry rect center first so the bridge logic can take over cleanly.
    // Under-lane A/B approach redirects only matter while top-lane traffic is active.
    call BridgeSystem_SetTopApproach(bridgeId, 1, gg_rct_HBridge002Carea)
    call BridgeSystem_SetTopApproach(bridgeId, 2, gg_rct_HBridge002Darea)
    call BridgeSystem_SetUnderApproach(bridgeId, 1, gg_rct_HBridge002Aarea)
    call BridgeSystem_SetUnderApproach(bridgeId, 2, gg_rct_HBridge002Barea)

    // Optional lane ghost collision overrides.
    // Defaults are true for both lanes.
    //call BridgeSystem_SetTopLaneGhostCollision(bridgeId, false)
    call BridgeSystem_SetUnderLaneGhostCollision(bridgeId, false)

    call BridgeSystem_FinalizeSetup(bridgeId)
endfunction

endlibrary
