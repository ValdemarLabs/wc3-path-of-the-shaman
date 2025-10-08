library Reputation initializer InitReputations requires Table

/*
    Reputation system

    Author: [Valdemar]
    Version: 1.0

    Required global variables (Path of the Shaman)
        udg_InCinematic (when cinematic is turned on in trigger CinematicON)
        udg_Multiboard (stats multiboard)

    Description:
    - Faction registry holds names and linked relationships.
    - Reputation struct stores per-player values.
    - InitReputations sets your default reputation values.
    - ReputationBoard displays them and updates regularly.
    - The multiboard toggles visibility with your udg_Multiboard (Stats) hidden when showing the reputation board.

    - Every 5 seconds, the system calls UpdateFactionAlliances.
        Compares current status vs. stored status.
        If changed → updates alliance state and displays a colored floating alert.
        Stores the new status.

        Example messages:

        |cff40ff40You are now Friendly with the Horde!|r

        |cffff4040You are now Hostile toward the Fel Orcs!|r

        |cffc0c0c0You are now Neutral with the Goblins.|r

    - For each faction with a valid owner (f.p), it checks the reputation of Player 1 (Red) toward that faction.
    - The system then automatically sets their alliance state:
        less than equal to -6000 → Enemy (unallied)
        0–2999 → Neutral
        greater than equal to 3000 → Allied
    - You can change which player is considered the "main" hero controller by editing:
        local player main = Player(0)

    Adding Reputation Changes:
        addRaw - affects only the selected faction, use these in triggers for quest reputation,etc. note: not for killing units unless specific
        call Reputation.addRaw(Player(0), Faction.get("Horde"), 100)
        call Reputation.addRaw(Player(0), Faction.get("Satyr"), -200)

        addLinked - affects the faction and linked factions, used only when killing units


    Show the Reputation Multiboard
        call ReputationBoard.show(Player(0), true)  // Show

    Linking factions:
        call horde.link(felorcs, -0.5)

    Getting faction (no other use)
        local Faction f = Faction.getFaction("Horde")
        call Reputation.addRaw(Player(0), f, 100)

*/

//===================================================
// CONFIGURATION
//===================================================

globals
    private constant integer MAX_FACTIONS = 11
    private constant integer REP_MIN = -20000
    private constant integer REP_MAX =  20000
    private constant integer REP_NEUTRAL = 0
    private constant integer REP_FRIENDLY = 3000
    private constant integer REP_HOSTILE = -6000

    private constant real BOARD_UPDATE_INTERVAL = 1.50
    private constant real RELATION_UPDATE_INTERVAL = 5.00

    // Reputation change values per faction (when killed)
    private Table REP_KILL_DELTA
    private Table UNIT_TYPE_FACTIONS
    private trigger tKillListener
    private Table prevStates
endglobals

//===================================================
// FACTION STRUCT
//===================================================

struct Faction
    string name
    integer id
    Table linked        // Table of linked factions {key=index, value=Faction}
    Table weights       // Table of corresponding weights {key=Faction.id, value=real}
    player p            // optional reference to the actual in-game player controlling this faction
    integer nextIndex   // track next free index for linking
    string iconPath     // icon used in multiboard for faction

    static Table byName
    static Faction array all
    static integer total = 1

    // Create a new faction
    static method createFaction takes string name, player owner returns thistype
        local thistype this = allocate()
        set this.name = name
        set this.p = owner
        set this.linked = Table.create()
        set this.weights = Table.create()
        set this.nextIndex = 0
        set byName.string[ StringHash(name) ] = I2S(this)
        set this.id = total
        set all[total] = this
        set total = total + 1
        return this
    endmethod

    // Link this faction to another with a weight factor
    method linkFaction takes Faction other, real factor returns nothing
        local integer i = 0

        // Check if already linked — update weight
        loop
            exitwhen i >= this.nextIndex
            if this.linked[i] == other then
                set this.weights.real[other.id] = factor
                return
            endif
            set i = i + 1
        endloop

        // Add new link
        set this.linked[this.nextIndex] = other
        set this.weights.real[other.id] = factor
        set this.nextIndex = this.nextIndex + 1
    endmethod

    static method getFaction takes string name returns Faction
        local string idStr = byName.string[ StringHash(name) ]
        if idStr != "" then
            return Faction(S2I(idStr))
        endif
        return 0
    endmethod

    static method getByPlayer takes player p returns Faction
        local integer i = 1
        loop
            exitwhen i >= total
            if all[i] != null and all[i].p == p then
                return all[i]
            endif
            set i = i + 1
        endloop
        return 0
    endmethod

    static method onInit takes nothing returns nothing
        set byName = Table.create()
    endmethod

    static method getByUnit takes unit u returns Faction
        local integer typeId = GetUnitTypeId(u)
        
        if UNIT_TYPE_FACTIONS.has(typeId) then
            return UNIT_TYPE_FACTIONS[GetUnitTypeId(u)]
        endif

        // Fallback to player-linked faction
        return Faction.getByPlayer(GetOwningPlayer(u))
    endmethod

endstruct

//===================================================
// REPUTATION STRUCT
//===================================================

struct Reputation
    static Table rep

    static method getRep takes player p, Faction f returns integer
        return rep[GetPlayerId(p) * MAX_FACTIONS + f.id]
    endmethod

    static method setRep takes player p, Faction f, integer value returns nothing
        if value > REP_MAX then
            set value = REP_MAX
        elseif value < REP_MIN then
            set value = REP_MIN
        endif
        set rep[GetPlayerId(p) * MAX_FACTIONS + f.id] = value
    endmethod

    // Only adjust the given faction (used for direct changes outside linked logic)
    static method addRaw takes player p, Faction f, integer delta returns nothing
        local integer newVal

        if udg_InCinematic then
            return
        endif

        set newVal = .getRep(p, f) + delta
        call .setRep(p, f, newVal)
        
        if delta > 0 then
            call BJDebugMsg("[Reputation] " + GetPlayerName(p) + " gained +" + I2S(delta) + " reputation with " + f.name)
            call DisplayTextToPlayer(p, 0, 0, "|cff80a0ff" + f.name + "|r reputation +" + I2S(delta))
        elseif delta < 0 then
            call BJDebugMsg("[Reputation] " + GetPlayerName(p) + " lost " + I2S(-delta) + " reputation with " + f.name)
            call DisplayTextToPlayer(p, 0, 0, "|cff80a0ff" + f.name + "|r reputation " + I2S(delta))
        else    
            call BJDebugMsg("[Reputation] No reputation change for " + f.name)
        endif
    endmethod

        // Adjust the faction + linked factions (used only in unit-kill logic)
    static method addLinked takes player p, Faction f, integer delta returns nothing
        local integer i = 0
        local Faction other

        call .addRaw(p, f, delta)

        if delta != 0 then
            loop
                exitwhen i >= f.nextIndex
                set other = f.linked[i]
                if other != null then
                    call BJDebugMsg("[Reputation] Linked reputation: " + f.name + " affects " + other.name + " by " + I2S(R2I(delta * f.weights.real[other.id])))
                    call .addRaw(p, other, R2I(delta * f.weights.real[other.id]))
                endif
                set i = i + 1
            endloop
        endif
    endmethod

    static method getStatus takes player p, Faction f returns string
        local integer val = .getRep(p, f)
        if val <= REP_HOSTILE then
            return "|cffff4040Hostile|r"
        elseif val < REP_FRIENDLY then
            return "|cffc0c0c0Neutral|r"
        else
            return "|cff40ff40Friendly|r"
        endif
    endmethod

    static method OnUnitKilled takes unit killer, unit victim returns nothing
        local player pKiller = GetOwningPlayer(killer)
        local Faction fVictim = Faction.getByUnit(victim)
        local integer delta

        if fVictim == null then 
            call BJDebugMsg("[Reputation] Victim has no associated faction. Skipping reputation adjustment.")
            return 
        endif

        if REP_KILL_DELTA.has(fVictim.id) then
            set delta = R2I(REP_KILL_DELTA.real[fVictim.id])
        else
            set delta = 0
        endif

        // === Debug message ===
        call BJDebugMsg("[Reputation] Kill event: " + GetUnitName(killer) + " killed a unit of faction " + fVictim.name + " (delta=" + I2S(delta) + ")")

        if delta != 0 then
            call .addLinked(pKiller, fVictim, delta)
        else
            call BJDebugMsg("[Reputation] No REP_KILL_DELTA defined for faction " + fVictim.name)
        endif
    endmethod

    static method onInit takes nothing returns nothing
        set rep = Table.create()
    endmethod
endstruct

//===================================================
// MULTIBOARD SYSTEM
//===================================================

struct ReputationBoard
    static multiboard array boards
    static timer updater

    static method show takes player p, boolean flag returns nothing
        local integer pid = GetPlayerId(p)
        if boards[pid] == null then
            call .createBoard(p)
        endif

        if flag then
            call MultiboardDisplay(udg_Multiboard, false)
            call MultiboardDisplay(boards[pid], true)
            call BJDebugMsg("[ReputationBoard] Showing reputation board for " + GetPlayerName(p))
        else
            call MultiboardDisplay(boards[pid], false)
            call MultiboardDisplay(udg_Multiboard, true)
            call BJDebugMsg("[ReputationBoard] Hiding reputation board for " + GetPlayerName(p))
        endif
    endmethod

    static method createBoard takes player p returns nothing
        local multiboard mb = CreateMultiboard()
        local integer rows = Faction.total + 1
        local integer i = 1
        local multiboarditem mItem
        local Faction f
        local string value

        call MultiboardSetTitleText(mb, "|cff20c0ff☯ Reputations|r")
        call MultiboardSetRowCount(mb, rows)
        call MultiboardSetColumnCount(mb, 2)

        // Header row
        set mItem = MultiboardGetItem(mb, 0, 0)
        call MultiboardSetItemValue(mItem, "|cffffcc00Faction|r")
        call MultiboardSetItemWidth(mItem, 0.15)
        call MultiboardReleaseItem(mItem)

        set mItem = MultiboardGetItem(mb, 0, 1)
        call MultiboardSetItemValue(mItem, "|cffffcc00Status|r")
        call MultiboardSetItemWidth(mItem, 0.10)
        call MultiboardReleaseItem(mItem)

        // Faction rows
        loop
            exitwhen i >= Faction.total
            set f = Faction.all[i]
            if f != null then
                // Faction name cell with alternating color
                set mItem = MultiboardGetItem(mb, i + 1, 0)
                if ModuloInteger(i, 2) == 0 then
                    call MultiboardSetItemValue(mItem, "|cffd0e0ff" + f.name + "|r")
                else
                    call MultiboardSetItemValue(mItem, "|cffb0c0e0" + f.name + "|r")
                endif
                call MultiboardSetItemWidth(mItem, 0.15)

                // Set the faction icon
                if f.iconPath != "" then
                    call MultiboardSetItemIcon(mItem, f.iconPath)
                endif

                call MultiboardReleaseItem(mItem)

                // Reputation status cell
                set mItem = MultiboardGetItem(mb, i + 1, 1)
                set value = Reputation.getStatus(p, f) + " |cff808080(" + I2S(Reputation.getRep(p, f)) + ")|r"
                call MultiboardSetItemValue(mItem, value)
                call MultiboardSetItemWidth(mItem, 0.10)
                call MultiboardReleaseItem(mItem)
            endif
            set i = i + 1
        endloop

        set boards[GetPlayerId(p)] = mb
        // hide multiboard initially
        call MultiboardDisplay(mb, false)
        call BJDebugMsg("[ReputationBoard] Created with improved visuals for " + GetPlayerName(p))
    endmethod

    static method update takes nothing returns nothing
        local player p = Player(0) // Player 1 (Red)
        local Faction f
        local multiboard mb
        local integer row
        local string value

        // Skip multiboard updates if in cinematic
        if udg_InCinematic then
            return
        endif

        set mb = boards[GetPlayerId(p)]

        if mb != null then
            set row = 1
            loop
                exitwhen row > Faction.total
                set f = Faction.all[row - 1]
                set value = Reputation.getStatus(p, f) + " (" + I2S(Reputation.getRep(p, f)) + ")"
                call MultiboardSetItemValue(MultiboardGetItem(mb, row, 1), value)
                set row = row + 1
            endloop
        endif
    endmethod

    static method onInit takes nothing returns nothing
        set updater = CreateTimer()
        call TimerStart(updater, BOARD_UPDATE_INTERVAL, true, function thistype.update)
    endmethod
endstruct

//===================================================
// RELATIONSHIP ADJUSTMENT
//===================================================

function UpdateFactionAlliances takes nothing returns nothing
    local integer i = 0
    local player mainPlayer = Player(0) // The main hero player (Player 1 / Red)
    local player otherPlayer
    local Faction f
    local integer rep
    local string newStatus
    local string oldStatus
    local integer key

    call BJDebugMsg("[Reputation] Running UpdateFactionAlliances tick...")

    // Initialize table if null
    if prevStates == null then
        set prevStates = Table.create()
        call BJDebugMsg("[Reputation] prevStates table initialized.")
    endif

    // Loop through all factions
    loop
        exitwhen i >= Faction.total
        set f = Faction.all[i]
        if f.p != null then
            set otherPlayer = f.p
            set rep = Reputation.getRep(mainPlayer, f)

            // Determine current status string
            if rep <= -6000 then
                set newStatus = "Hostile"
            elseif rep < 3000 then
                set newStatus = "Neutral"
            else
                set newStatus = "Friendly"
            endif

            // Load previous status (if any) from table
            set key = f.id
            set oldStatus = prevStates.string[key]

            // If status changed, update alliances
            if oldStatus != newStatus then
                call BJDebugMsg("[Reputation] Alliance state changed for " + f.name + " → " + newStatus)
                if newStatus == "Hostile" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_UNALLIED)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_UNALLIED)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffff4040You are now Hostile toward " + f.name + "!|r")
                elseif newStatus == "Neutral" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_NEUTRAL)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_NEUTRAL)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffc0c0c0You are now Neutral with " + f.name + ".|r")
                elseif newStatus == "Friendly" then
                    call SetPlayerAllianceStateBJ(mainPlayer, otherPlayer, bj_ALLIANCE_ALLIED)
                    call SetPlayerAllianceStateBJ(otherPlayer, mainPlayer, bj_ALLIANCE_ALLIED)
                    call DisplayTextToPlayer(mainPlayer, 0, 0, "|cff40ff40You are now Friendly with " + f.name + "!|r")
                endif

                // Save current status as string
                set prevStates.string[key] = newStatus
            endif
        endif
        set i = i + 1
    endloop
    return
endfunction

//===================================================
// AUTOMATIC KILL REPUTATION
//===================================================
private function OnUnitDeathHandler takes nothing returns nothing
    local unit killer = GetKillingUnit()
    local unit victim = GetDyingUnit()
    
    // Only Player 1 kills count
    if GetOwningPlayer(killer) == Player(0) then
        call Reputation.OnUnitKilled(killer, victim)
    endif
    
    return
endfunction

//===================================================
// HELPER FUNCTION
//===================================================
private function AddUnitTypesToFaction takes string array codes, Faction f returns nothing
    local integer i = 0
    loop
        exitwhen i >= ArrayLength(codes)
        set UNIT_TYPE_FACTIONS[codes[i]] = f
        set i = i + 1
    endloop
endfunction

//===================================================
// INIT UNIT TYPE FACTIONS
//===================================================
private function InitUnitTypeFactions takes nothing returns nothing
    set UNIT_TYPE_FACTIONS = Table.create()

    // --- Gnolls ---
    call AddUnitTypesToFaction(
        [ "ngno", "ngns", "ngnb", "ngnv", "ngna", "ngnw", "ngow", "n626", "n60O", "n61A", "n634", "n609" ],
        Faction.getFaction("Gnolls")
    )

    // --- Wolves ---
    call AddUnitTypesToFaction(
        [ "nWlf", "nWlf2" ],   // add all wolf unit types here
        Faction.getFaction("Wolves")
    )

    // --- Satyrs ---
    call AddUnitTypesToFaction(
        [ "nSaty", "nSat2" ],  // add all satyr unit types here
        Faction.getFaction("Satyr")
    )

    // --- Fel Orcs ---
    call AddUnitTypesToFaction(
        [ "o608", "o609" ],    // add all fel orc unit types here
        Faction.getFaction("Fel Orcs")
    )

    // Add more factions and unit types as needed
endfunction

private function InitFactions takes nothing returns nothing
    local player p = Player(0)

    // Create factions
    local Faction horde        = Faction.createFaction("Horde", Player(5))
    local Faction satyr        = Faction.createFaction("Satyr", Player(12))
    local Faction riverbane    = Faction.createFaction("Riverbane", Player(14))
    local Faction alliance     = Faction.createFaction("Alliance", Player(8))
    local Faction felorcs      = Faction.createFaction("Fel Orcs", Player(3))
    local Faction undead       = Faction.createFaction("Undead", Player(20))
    local Faction goblins      = Faction.createFaction("Goblins", Player(13))
    local Faction elarindor    = Faction.createFaction("Elarindor", Player(15))
    local Faction bonecrushers = Faction.createFaction("Bonecrusher Clan", Player(10))
    local Faction realhorde    = Faction.createFaction("The True Horde", Player(7))
    local Faction humancitizen = Faction.createFaction("Human Citizen", Player(2))
    local Faction gnolls       = Faction.createFaction("Gnolls", null)

    call BJDebugMsg("[Reputation] Factions created: " + I2S(Faction.total))

    // Link factions
    call horde.linkFaction(alliance, -1.0)
    call alliance.linkFaction(horde, -1.0)
    call horde.linkFaction(felorcs, -0.5)
    call horde.linkFaction(satyr, -0.25)
    call BJDebugMsg("[Reputation] Faction links established.")

    // Setup kill deltas
    set REP_KILL_DELTA = Table.create()
    set REP_KILL_DELTA[horde.id] = 100
    set REP_KILL_DELTA[satyr.id] = -200
    set REP_KILL_DELTA[riverbane.id] = 50
    set REP_KILL_DELTA[alliance.id] = -200
    set REP_KILL_DELTA[felorcs.id] = -200
    set REP_KILL_DELTA[undead.id] = -100
    set REP_KILL_DELTA[goblins.id] = 100
    set REP_KILL_DELTA[elarindor.id] = 50
    set REP_KILL_DELTA[bonecrushers.id] = -100
    set REP_KILL_DELTA[realhorde.id] = 100
    set REP_KILL_DELTA[humancitizen.id] = 50
    set REP_KILL_DELTA[gnolls.id] = 50 

    // Set initial reputation values
    call Reputation.setRep(p, horde, 0)
    call Reputation.setRep(p, satyr, 0)
    call Reputation.setRep(p, riverbane, 0)
    call Reputation.setRep(p, alliance, -20000)
    call Reputation.setRep(p, felorcs, -20000)
    call Reputation.setRep(p, undead, -20000)
    call Reputation.setRep(p, goblins, 0)
    call Reputation.setRep(p, elarindor, 0)
    call Reputation.setRep(p, bonecrushers, 0)
    call Reputation.setRep(p, realhorde, 0)
    call Reputation.setRep(p, humancitizen, 0)

    set horde.iconPath        = "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp"
    set realhorde.iconPath    = "ReplaceableTextures\\CommandButtons\\BTNHellScream.blp"
    set alliance.iconPath     = "ReplaceableTextures\\CommandButtons\\BTNTheCaptain.blp"
    set felorcs.iconPath      = "ReplaceableTextures\\CommandButtons\\BTNChaosGrunt.blp"
    set satyr.iconPath        = "ReplaceableTextures\\CommandButtons\\BTNSatyrTrickster.blp"
    set gnolls.iconPath       = "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp"
    set riverbane.iconPath    = "ReplaceableTextures\\CommandButtons\\BTNPeasant.blp"
    set humancitizen.iconPath = "ReplaceableTextures\\CommandButtons\\BTNPeasant.blp"
    set bonecrushers.iconPath = "ReplaceableTextures\\CommandButtons\\BTNOgre.blp"
    set elarindor.iconPath    = "ReplaceableTextures\\CommandButtons\\BTNSylvanusWindrunner.blp"
    set goblins.iconPath      = "ReplaceableTextures\\CommandButtons\\BTNGoblinSapper.blp"
    
    // etc. for all factions

    // Start periodic alliance updates
    call TimerStart(CreateTimer(), RELATION_UPDATE_INTERVAL, true, function UpdateFactionAlliances)
    call BJDebugMsg("[Reputation] Alliance update timer started (" + R2S(RELATION_UPDATE_INTERVAL) + "s interval).")
endfunction

//===================================================
// INITIALIZATION
//===================================================
private function InitReputations takes nothing returns nothing
    // Init core systems
    call Faction.onInit()
    call Reputation.onInit()
    call InitFactions()
    call InitUnitTypeFactions()   
    call ReputationBoard.onInit()

    set tKillListener = CreateTrigger()
    // register unit death event
    call TriggerRegisterAnyUnitEventBJ(tKillListener, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(tKillListener, function OnUnitDeathHandler)
endfunction

endlibrary
