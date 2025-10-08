library CinematicMover initializer Init requires Table
//===========================================================================
/*
    Cinematic Mover

    Author: [Valdemar]

    Description:
    This library manages the movement of hero units (Nazgrek and Zulkis), their companions, and pets during cinematic sequences.
    It ensures that these units are moved to a specified cinematic location, and if they die during the cinematic, they are revived and returned to their original positions afterward.
    Features:
    - Register Nazgrek and Zulkis with ownership flags.
    - Move heroes, companions, and pets to a cinematic location.
    - Revive heroes if they die during the cinematic.
    - Return units to their original locations after the cinematic, with a maximum return range.
    - Uses global revive timers for heroes (must be defined in the map script).
    - Companion and pet groups are set externally.

    Requires:
    - Table library for data storage by Bribe

    // Companion + Pet groups (set externally)
    //group udg_Companion_Group
    //group udg_TamedUnits 

    Move Modes:
    1 = All units (default)
    2 = All except Zulkis
    3 = All except Nazgrek
    4 = All except Companion group
    5 = All except TamedUnits group
    6 = Only Nazgrek and Zulkis
    7 = Only Nazgrek
    8 = Only Zulkis

    Usage:
    call CinematicMover_MoveUnitsToCinematic(udg_CinematicTriggerUnit, moveMode)

    call CinematicMover_MoveUnitsToCinematic(udg_CinematicTriggerUnit, 1)
    call CinematicMover_ReturnUnitsFromCinematic(udg_CinematicTriggerUnit, 1)
    // Move mode is optional, default is 1 (all units)

    // Register heroes and their revive timers
    call CinematicMover_RegisterReviveTimer(udg_Nazgrek, udg_ReviveTimerNazgrek)
    call CinematicMover_RegisterReviveTimer(udg_Zulkis, udg_ReviveTimerZulkis)
    call CinematicMover_RegisterReviveTimer(udg_Engineer, udg_ReviveTimer_Engineer)
    call CinematicMover_RegisterReviveTimer(udg_Paladin, udg_ReviveTimerPaladin)
    call CinematicMover_RegisterReviveTimer(udg_Rogue, udg_ReviveTimerRogue)
    call CinematicMover_RegisterReviveTimer(udg_Warlock, udg_ReviveTimerWarlock)
    call CinematicMover_RegisterReviveTimer(udg_Restoshaman, udg_ReviveTimerRestoshaman)
    call CinematicMover_RegisterReviveTimer(udg_Shadowclaw, udg_ReviveTimerPet)
    call CinematicMover_RegisterReviveTimer(udg_Warrior, udg_ReviveTimerWarrior)

    //
    // Move units to cinematic location
    call CinematicMoverMoveUnitsToCinematic(udg_CinematicTriggerUnit)
    // ... cinematic sequence ...
    // Return units to their original locations 
    call CinematicMoverReturnUnitsFromCinematic(udg_CinematicTriggerUnit)

*/
//===========================================================================
// Globals
//===========================================================================

    globals
        // Constants
        private constant real MAX_RETURN_RANGE      = 1200.0
        private constant real RANDOM_OFFSET         = 250.0
        
        private boolean ZULKIS_OWNED       = true
        private real CENTER_X = 0.0
        private real CENTER_Y = 0.0

        // Storage (Table for x/y + revived flag)
        // data.real[id*2] / data.real[id*2+1] : stored X/Y
        // data.timer[id] : revive timer
        // data.boolean[id] : revived flag
        // data.integer[id] : stored moveMode per cine trigger
        private Table data
    endglobals

//===========================================================================

    //===========================================================================
    // Register Revive Timer
    //===========================================================================
    function CinematicMover_RegisterReviveTimer takes unit u, timer reviveTimer returns nothing
        if u != null and reviveTimer != null then
            set data.timer[GetHandleId(u)] = reviveTimer
        endif
    endfunction

    // Register a hero unit with its revive timer
    private function RegisterDefaultReviveTimers takes nothing returns nothing
        // Map all known heroes to their respective revive timers
        call CinematicMover_RegisterReviveTimer(udg_Nazgrek,                    udg_ReviveTimerNazgrek)
        call CinematicMover_RegisterReviveTimer(udg_Zulkis,                     udg_ReviveTimerZulkis)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Neutral_Engineer,       udg_ReviveTimerEngineer)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Riverbane_Paladin,      udg_ReviveTimerPaladin)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Horde_AI_Rogue,         udg_ReviveTimerRogue)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Horde_AI_Warlock,       udg_ReviveTimerWarlock)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Horde_AI_Shaman,        udg_ReviveTimerRestoshaman)
        call CinematicMover_RegisterReviveTimer(udg_TamedUnit,                 udg_ReviveTimerPet)
        call CinematicMover_RegisterReviveTimer(udg_NPC_Horde_AI_Warrior,       udg_ReviveTimerWarrior)
    endfunction

    //===========================================================================
    // Helpers
    //===========================================================================
    // Store and pause the revive timer for a unit
    private function StoreAndPauseReviveTimer takes unit u returns nothing
        local timer t
        local real remaining
        if u == null then
            return
        endif
        set t = data.timer[GetHandleId(u)]
        if t != null then
            set remaining = TimerGetRemaining(t)
            if remaining > 0.0 then
                call PauseTimer(t)
                set data.real[GetHandleId(u) + 1000000] = remaining
            endif
        endif
    endfunction

    // Resume the revive timer for a unit
    private function ResumeReviveTimer takes unit u returns nothing
        local timer t
        local real remaining
        if u == null then
            return
        endif
        set t = data.timer[GetHandleId(u)]
        if t != null and data.real.has(GetHandleId(u) + 1000000) then
            set remaining = data.real[GetHandleId(u) + 1000000]
            call TimerStart(t, remaining, false, null)
            call data.real.remove(GetHandleId(u) + 1000000)
        endif
    endfunction

    private function StoreCompanionPosition takes nothing returns nothing
        local unit u = GetEnumUnit()
        local integer id = GetHandleId(u)

        set data.real[id*2]   = GetUnitX(u)
        set data.real[id*2+1] = GetUnitY(u)
        call BJDebugMsg("[CinematicMover] Stored companion position: " + GetUnitName(u))
    endfunction

    private function StoreTamedPosition takes nothing returns nothing
        local unit u = GetEnumUnit()
        local integer id = GetHandleId(u)

        set data.real[id*2]   = GetUnitX(u)
        set data.real[id*2+1] = GetUnitY(u)
        call BJDebugMsg("[CinematicMover] Stored pet position: " + GetUnitName(u))
    endfunction

    // Helper function to store initial distance to cineTriggerUnit
    private function StoreDistanceToTrigger takes unit u, real tx, real ty returns nothing
        local integer id = GetHandleId(u)
        local real dx = GetUnitX(u) - tx
        local real dy = GetUnitY(u) - ty
        set data.real[id*2 + 100] = SquareRoot(dx*dx + dy*dy)
    endfunction

    // Store the original locations of all relevant units
    private function StoreUnitLocations takes nothing returns nothing
        local group g
        local unit u
        local integer id

        call BJDebugMsg("[CinematicMover] Storing unit locations...")

        // Store Nazgrek's position
        if udg_Nazgrek != null then
            set id = GetHandleId(udg_Nazgrek)
            set data.real[id * 2] = GetUnitX(udg_Nazgrek)
            set data.real[id * 2 + 1] = GetUnitY(udg_Nazgrek)
            call BJDebugMsg("[CinematicMover] Stored Nazgrek position.")
        endif

        // Store Zulkis's position
        if udg_Zulkis != null then
            set id = GetHandleId(udg_Zulkis)
            set data.real[id * 2] = GetUnitX(udg_Zulkis)
            set data.real[id * 2 + 1] = GetUnitY(udg_Zulkis)
            call BJDebugMsg("[CinematicMover] Stored Zulkis position.")
        endif

        // Store Companion units' positions
        if CountUnitsInGroup(udg_Companion_Group) > 0 then
            call ForGroupBJ(udg_Companion_Group, function StoreCompanionPosition)
        else
            call BJDebugMsg("[CinematicMover] No companions found in group.")
        endif

        // Store Tamed units' positions
        if CountUnitsInGroup(udg_TamedUnits) > 0 then
            call ForGroupBJ(udg_TamedUnits, function StoreTamedPosition)
        else
            call BJDebugMsg("[CinematicMover] No tamed units found in group.")
        endif

        /*
        // Store Companion units' positions
        if (CountUnitsInGroup(udg_Companion_Group) > 0) then
            set g = CreateGroup()
            call GroupAddGroup(g, udg_Companion_Group)
            loop
                set u = FirstOfGroup(g)
                exitwhen u == null
                call GroupRemoveUnit(g, u)
                set id = GetHandleId(u)
                set data.real[id * 2] = GetUnitX(u)
                set data.real[id * 2 + 1] = GetUnitY(u)
                call BJDebugMsg("[CinematicMover] Stored companion position: " + GetUnitName(u))
            endloop
            call DestroyGroup(g)
        else
            call BJDebugMsg("[CinematicMover] No companions found in group.")
        endif

        // Store Tamed units' positions
        if (CountUnitsInGroup(udg_TamedUnits) > 0) then
            set g = CreateGroup()
            call GroupAddGroup(g, udg_TamedUnits)
            loop
                set u = FirstOfGroup(g)
                exitwhen u == null
                call GroupRemoveUnit(g, u)
                set id = GetHandleId(u)
                set data.real[id * 2] = GetUnitX(u)
                set data.real[id * 2 + 1] = GetUnitY(u)
                call BJDebugMsg("[CinematicMover] Stored pet position: " + GetUnitName(u))
            endloop
            call DestroyGroup(g)
        else
            call BJDebugMsg("[CinematicMover] No tamed units found in group.")
        endif
        */

    endfunction

    // Restore a unit's original location
    private function RestoreLocation takes unit u returns nothing
        local integer id = GetHandleId(u)
        if data.real.has(id*2) then
            call SetUnitX(u, data.real[id*2])
        endif
        if data.real.has(id*2+1) then
            call SetUnitY(u, data.real[id*2+1])
        endif
    endfunction

    //===========================================================================
    // Revive Tracking
    //===========================================================================

    private function MarkRevived takes unit u returns nothing
        set data.boolean[GetHandleId(u)] = true
    endfunction

    private function WasRevived takes unit u returns boolean
        return data.boolean[GetHandleId(u)]
    endfunction

    private function ClearRevived takes unit u returns nothing
        call data.boolean.remove(GetHandleId(u))
    endfunction

    //===========================================================================
    // Unit Handling
    //===========================================================================
    // Handle unit movement to cinematic location
    //===========================================================================
    private function HandleUnitMove takes unit u, real cx, real cy returns nothing
        local real rx
        local real ry
        local timer unitReviveTimer

        if u == null then
            return
        endif

        if cx == 0.0 and cy == 0.0 then
            set cx = GetUnitX(u)
            set cy = GetUnitY(u)
        endif

        // Retrieve the revive timer for the unit
        set unitReviveTimer = data.timer[GetHandleId(u)]

        if IsUnitAliveBJ(u) then
            // Add randomness to the cinematic position
            set rx = RMaxBJ(RMinBJ(cx + GetRandomReal(-RANDOM_OFFSET, RANDOM_OFFSET), GetRectMaxX(bj_mapInitialPlayableArea)), GetRectMinX(bj_mapInitialPlayableArea))
            set ry = RMaxBJ(RMinBJ(cy + GetRandomReal(-RANDOM_OFFSET, RANDOM_OFFSET), GetRectMaxY(bj_mapInitialPlayableArea)), GetRectMinY(bj_mapInitialPlayableArea))
            call SetUnitX(u, rx)
            call SetUnitY(u, ry)
            call BJDebugMsg("[CinematicMover] Moved alive unit: " + GetUnitName(u))
        // Unit is dead, revive if not already revived

        else
            call BJDebugMsg("[CinematicMover] Reviving unit: " + GetUnitName(u))
            // REVIVAL

            /*
            // Shadowclaw has a special revive trigger - normal pets (TamedUnits group) dont revive
            if u == udg_Shadowclaw then
                call TriggerExecute(gg_trg_Shadowclaw_Revival)
                if IsUnitAliveBJ(u) then
                    call MarkRevived(u)
                    call BJDebugMsg("[CinematicMover] Shadowclaw revived successfully.")
                endif
            else 
                call MarkRevived(u)
                call ReviveHero(u, cx, cy, false)
            endif
            */

            if IsUnitInGroup(u, udg_TamedUnits) then
                call BJDebugMsg("[CinematicMover] Reviving tamed unit via Tamed Unit Revival trigger: " + GetUnitName(u))
                call TriggerExecute(gg_trg_Tamed_Unit_Revival)
                call MarkRevived(u)
            else
                call MarkRevived(u)
                call ReviveHero(u, cx, cy, false)
            endif

            // Automatically pause and store remaining revive time
            call StoreAndPauseReviveTimer(u)

            // Add randomness to the revived position
            set rx = cx + GetRandomReal(-RANDOM_OFFSET, RANDOM_OFFSET)
            set ry = cy + GetRandomReal(-RANDOM_OFFSET, RANDOM_OFFSET)
            call SetUnitX(u, rx)
            call SetUnitY(u, ry)
            call BJDebugMsg("[CinematicMover] Unit revived and moved: " + GetUnitName(u))
        endif

    endfunction

    //===========================================================================
    // Handle unit return after cinematic
    //===========================================================================
    private function HandleUnitReturn takes unit u, real cx, real cy returns nothing
        local integer id
        local real dist

        if u == null then
            return
        endif

        set id = GetHandleId(u)

        // Check if within MAX_RETURN_RANGE initially
        if data.real.has(id*2 + 100) then
            set dist = data.real[id*2 + 100]
            if dist <= MAX_RETURN_RANGE then
                call BJDebugMsg("[CinematicMover] Skipped returning " + GetUnitName(u) + " (was within " + R2S(dist) + " of cineTriggerUnit).")
                return
            endif
        endif

        // If the unit was revived during the cinematic, remove it (kill) and resume timer
        if WasRevived(u) then
            // Tamed units are returned to "dead" state if they were dead
            if IsUnitInGroup(u, udg_TamedUnits) then
                call BJDebugMsg("[CinematicMover] Returning tamed unit to dead-state via Tamed Unit Kill: " + GetUnitName(u))
                call TriggerExecute(gg_trg_Tamed_Unit_Dies)
            else
                call KillUnit(u)
            endif
            call ResumeReviveTimer(u)
            call ClearRevived(u)
            call BJDebugMsg("[CinematicMover] Revived unit returned to dead-state: " + GetUnitName(u))
            return
        endif

        // If we have stored original coords, restore them (heroes always restored this way)
        if data.real.has(id*2) and data.real.has(id*2+1) then
            call SetUnitX(u, data.real[id*2])
            call SetUnitY(u, data.real[id*2+1])
            call BJDebugMsg("[CinematicMover] Restored original position for: " + GetUnitName(u))
            return
        else
            call BJDebugMsg("[CinematicMover] No stored position found for: " + GetUnitName(u))
        endif
        // Fallback: nothing to restore
    endfunction

    private function MoveCompanionCallback takes nothing returns nothing
        local unit u = GetEnumUnit()

        call HandleUnitMove(u, CENTER_X, CENTER_Y) // random offset will be applied inside
        call BJDebugMsg("[CinematicMover] Moving companion: " + GetUnitName(u))
    endfunction

    private function MoveTamedCallback takes nothing returns nothing
        local unit u = GetEnumUnit()

        call HandleUnitMove(u, CENTER_X, CENTER_Y)
        call BJDebugMsg("[CinematicMover] Moving pet: " + GetUnitName(u))
    endfunction

    private function StoreDistanceToTriggerWrapper takes nothing returns nothing
        call StoreDistanceToTrigger(GetEnumUnit(), CENTER_X, CENTER_Y)
    endfunction

    //===========================================================================
    // Main: Move Units to Cinematic
    //===========================================================================
    function CinematicMover_MoveUnitsToCinematic takes unit cineTriggerUnit, integer moveMode returns nothing
        local boolean moveNazgrek = true
        local boolean moveZulkis = true
        local boolean moveCompanions = true
        local boolean moveTamed = true
        local real cx = GetUnitX(cineTriggerUnit)
        local real cy = GetUnitY(cineTriggerUnit)
        local location loc = null
        local group g = null
        local unit u = null

        if cineTriggerUnit == null then
            return
        endif

        call BJDebugMsg("[CinematicMover] Starting cinematic move with mode " + I2S(moveMode))

        // ============================================================
        // OPTIONAL: Move the cinematic trigger unit itself
        // If udg_CinematicMovePoint[0] exists, reposition the trigger unit.
        // This is useful for moving the camera focus point.
        // If not defined, the trigger unit stays in place.
        // ============================================================
        if udg_CinematicMovePoint[0] != null then
            set loc = udg_CinematicMovePoint[0]
            set cx = GetLocationX(loc)
            set cy = GetLocationY(loc)
        else
            set cx = GetUnitX(cineTriggerUnit)
            set cy = GetUnitY(cineTriggerUnit)
        endif

        // ============================================================
        // Determine which units to move based on moveMode
        // ============================================================
        /* Move Modes:
            1 = move all units (most used)
            2 = move all units except zulkis (situational use)
            3 = move all units except Nazgrek (situational use)
            4 = move all units except companio_group units (situational use) 
            5 = move all units except TamedUnits group (situational use)
            6 = move only Nazgrek and Zulkis (some main cinematics)
            7 = only nazgrek
            8 = only zulkis
        */
        if moveMode == 2 then
            set moveZulkis = false
        elseif moveMode == 3 then
            set moveNazgrek = false
        elseif moveMode == 4 then
            set moveCompanions = false
        elseif moveMode == 5 then
            set moveTamed = false
        elseif moveMode == 6 then
            set moveCompanions = false
            set moveTamed = false
        elseif moveMode == 7 then
            set moveZulkis = false
            set moveCompanions = false
            set moveTamed = false
        elseif moveMode == 8 then
            set moveNazgrek = false
            set moveCompanions = false
            set moveTamed = false
        else
            // Movemode 1: move all units
            set moveNazgrek = true
            set moveZulkis = true
            set moveCompanions = true
            set moveTamed = true
        endif

        // Store initial locations of all units
        call StoreUnitLocations()

        // Store initial distances from cinematic trigger to all major units
        if udg_Nazgrek != null then
            call StoreDistanceToTrigger(udg_Nazgrek, cx, cy)
        endif
        if udg_Zulkis != null then
            call StoreDistanceToTrigger(udg_Zulkis, cx, cy)
        endif
        if CountUnitsInGroup(udg_Companion_Group) > 0 then
            call ForGroup(udg_Companion_Group, function StoreDistanceToTriggerWrapper)
        endif
        if CountUnitsInGroup(udg_TamedUnits) > 0 then
            call ForGroup(udg_TamedUnits, function StoreDistanceToTriggerWrapper)
        endif

        
        // ============================================================
        // Handle Hero Movement
        // ============================================================
        // Heroes
        // Default to cinematicTrigger position unless custom points exist
        // If custom points are defined, use them

        if moveNazgrek and udg_Nazgrek != null then
            if GetOwningPlayer(udg_Nazgrek) == Player(0) then
                if udg_CinematicMovePoint[1] != null then
                    // Precise cinematic location
                    call SetUnitX(udg_Nazgrek, GetLocationX(udg_CinematicMovePoint[1]))
                    call SetUnitY(udg_Nazgrek, GetLocationY(udg_CinematicMovePoint[1]))
                else
                    call HandleUnitMove(udg_Nazgrek, cx, cy) // random offset
                endif
            endif
        endif

        if moveZulkis and udg_Zulkis != null then
            if GetOwningPlayer(udg_Zulkis) == Player(0) then
                set ZULKIS_OWNED = true
                if udg_CinematicMovePoint[2] != null then
                    call SetUnitX(udg_Zulkis, GetLocationX(udg_CinematicMovePoint[2]))
                    call SetUnitY(udg_Zulkis, GetLocationY(udg_CinematicMovePoint[2]))
                else
                    call HandleUnitMove(udg_Zulkis, cx, cy) 
                endif
            else
                // Zulkis is not owned by Player 1, do not move
                set ZULKIS_OWNED = false
            endif
        endif

        // Store cinematic center for companion/pet movement
        // This is either the cine trigger position or the custom point if defined
        set CENTER_X = cx
        set CENTER_Y = cy

        // Companions
        if moveCompanions and CountUnitsInGroup(udg_Companion_Group) > 0 then
            call ForGroupBJ(udg_Companion_Group, function MoveCompanionCallback)
        endif

        // Pets
        if moveTamed and CountUnitsInGroup(udg_TamedUnits) > 0 then
            call ForGroupBJ(udg_TamedUnits, function MoveTamedCallback)
        endif

        /*
        // Companions
        if moveCompanions then
            set g = CreateGroup() // temporary group
            call GroupAddGroup(g, udg_Companion_Group) // copy units
            loop
                set u = FirstOfGroup(g)
                exitwhen u == null
                call GroupRemoveUnit(g, u)
                call HandleUnitMove(u, cx, cy)
                call BJDebugMsg("[CinematicMover] Moving companion: " + GetUnitName(u))
            endloop
            call DestroyGroup(g)
            call BJDebugMsg("[CinematicMover] Moved companions.")
        endif

        // Pets
        // Move Tamed Units without removing from group
        if moveTamed and udg_TamedUnits != null then
            set g = CreateGroup()
            call GroupAddGroup(g, udg_TamedUnits)
            loop
                set u = FirstOfGroup(g)
                exitwhen u == null
                call GroupRemoveUnit(g, u)
                call HandleUnitMove(u, cx, cy)
                call BJDebugMsg("[CinematicMover] Moving pet: " + GetUnitName(u))
            endloop
            call DestroyGroup(g)
            call BJDebugMsg("[CinematicMover] Moved tamed units.")
        endif
        */

        // Store the last mode used per cinematic trigger
        set data.integer[GetHandleId(cineTriggerUnit)] = moveMode

    endfunction

    // Companion return callback
    private function ReturnCompanionCallback takes nothing returns nothing
        local unit u = GetEnumUnit()
        
        call HandleUnitReturn(u, GetUnitX(u), GetUnitY(u))
        call BJDebugMsg("[CinematicMover] Returning companion: " + GetUnitName(u))
    endfunction

    // Tamed return callback
    private function ReturnTamedCallback takes nothing returns nothing
        local unit u = GetEnumUnit()

        call HandleUnitReturn(u, GetUnitX(u), GetUnitY(u))
        call BJDebugMsg("[CinematicMover] Returning pet: " + GetUnitName(u))
    endfunction

    //===========================================================================
    // Return Units After Cinematic
    //===========================================================================
    function CinematicMover_ReturnUnitsFromCinematic takes unit cineTriggerUnit returns nothing
        local real cx = GetUnitX(cineTriggerUnit)
        local real cy = GetUnitY(cineTriggerUnit)
        local group g = null
        local unit u = null
        local integer moveMode
        local boolean moveNazgrek = true
        local boolean moveZulkis = true
        local boolean moveCompanions = true
        local boolean moveTamed = true

        if cineTriggerUnit == null then
            return
        endif

        call BJDebugMsg("[CinematicMover] Returning units from cinematic...")

        // Cinematic center (if cine trigger moved earlier, cineTrigger will be at that point)
        set cx = GetUnitX(cineTriggerUnit)
        set cy = GetUnitY(cineTriggerUnit)

        // Retrieve stored move mode from when cinematic started
        if data.integer.has(GetHandleId(cineTriggerUnit)) then
            set moveMode = data.integer[GetHandleId(cineTriggerUnit)]
        else
            set moveMode = 1 // default fallback
        endif

        // Apply filtering based on stored mode
        if moveMode == 2 then
            set moveZulkis = false
        elseif moveMode == 3 then
            set moveNazgrek = false
        elseif moveMode == 4 then
            set moveCompanions = false
        elseif moveMode == 5 then
            set moveTamed = false
        elseif moveMode == 6 then
            set moveCompanions = false
            set moveTamed = false
        elseif moveMode == 7 then
            set moveZulkis = false
            set moveCompanions = false
            set moveTamed = false
        elseif moveMode == 8 then
            set moveNazgrek = false
            set moveCompanions = false
            set moveTamed = false
        endif

        // Heroes always restore to stored original positions (if exist)
        // But NEVER move the hero who triggered the cinematic itself
        if moveNazgrek and udg_Nazgrek != cineTriggerUnit then
            call HandleUnitReturn(udg_Nazgrek, cx, cy)
        endif
        if moveZulkis and ZULKIS_OWNED and udg_Zulkis != cineTriggerUnit then
            call HandleUnitReturn(udg_Zulkis, cx, cy)
        endif

        // Return companions
        if moveCompanions and CountUnitsInGroup(udg_Companion_Group) > 0 then
            call ForGroupBJ(udg_Companion_Group, function ReturnCompanionCallback)
        endif

        // Return tamed units
        if moveTamed and CountUnitsInGroup(udg_TamedUnits) > 0 then
            call ForGroupBJ(udg_TamedUnits, function ReturnTamedCallback)
        endif

        // Cleanup stored mode
        call data.integer.remove(GetHandleId(cineTriggerUnit))

        // Clear cinematic global variable points after use
        set udg_CinematicMovePoint[0] = null
        set udg_CinematicMovePoint[1] = null
        set udg_CinematicMovePoint[2] = null
    endfunction

    //===========================================================================
    // Init
    //===========================================================================
    private function Init takes nothing returns nothing
        // Initialize storage table
        set data = Table.create()

        // Register default heroes and their revive timers
        call RegisterDefaultReviveTimers()

        set udg_CinematicMovePoint[0] = null
        set udg_CinematicMovePoint[1] = null
        set udg_CinematicMovePoint[2] = null

    endfunction

endlibrary
