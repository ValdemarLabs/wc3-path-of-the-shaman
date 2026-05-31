library Reputation initializer InitReputations requires Table, UnitDeathEvent

/*
    Reputation system

    Author: [Valdemar]
    Version: 2.0

    Required global variables (Path of the Shaman)
        udg_InCinematic (when cinematic is turned on in trigger CinematicON)
        udg_Multiboard (stats multiboard, legacy reputation board support only)

    Description:
    - Faction registry holds names and linked relationships.
    - Reputation struct stores per-player values.
    - InitReputations sets your default reputation values.
    - ReputationBoard is kept as legacy code and is no longer activated.
    - ReputationUI now handles the active reputation display.

    - Every 5 seconds, the system calls UpdateFactionAlliances.
        Compares current status vs. stored status.
        If changed → updates alliance state and displays a colored floating alert.
        Stores the new status.
    
    MASTER ALLIANCE SYSTEM:
    - The reputation system is the MASTER controller for all alliances in the game
    - Player 0 (hero player) alliances with all factions are determined by reputation
    - When ENABLE_INTER_FACTION_ALLIANCES = true:
        * Computer-controlled factions' alliances with each other are also determined by reputation
        * Each faction pair uses the worse of their mutual reputations
        * This creates dynamic faction relationships (e.g., Horde vs Alliance)
    - Alliance states are mapped from reputation tiers:
        * Enemy/Hostile → UNALLIED (will attack)
        * Unfriendly/Neutral → NEUTRAL (won't attack unless provoked)
        * Friendly/Covenant/Exalted → ALLIED (will help each other)

    Seven-Tier Reputation System:
    
    1. ENEMY (-20000 to -12000) |cff8b0000Dark Red|r
       - Some factions will actively hunt you
       - Always attacked on sight
       - Cannot interact with faction NPCs
       - Unallied with vision (they can see you)
    
    2. HOSTILE (-12000 to -6000) |cffff4040Red|r
       - Always attacked on sight
       - Cannot buy items or hire companions
       - Cannot talk to quest givers or NPCs
       - Unallied state
    
    3. UNFRIENDLY (-3000 to 0) |cffff8040Orange|r
       - Not attacked on sight but wary
       - Cannot buy items or hire companions
       - Cannot talk to quest givers or NPCs
       - Neutral alliance state
    
    4. NEUTRAL (0 to 3000) |cffffffffWhite|r
       - Can buy basic items from vendors
       - Can talk to NPCs and quest givers
       - Cannot hire companion units
       - Neutral with vision
    
    5. FRIENDLY (3000 to 6000) |cff40ff40Green|r
       - Can buy more items from vendors
       - Can talk to NPCs and quest givers
       - Limited companion hiring may be available
       - Allied state
    
    6. COVENANT (6000 to 12000) |cff00ff00Bright Green|r
       - Can buy all regular items
       - Can hire companion units
       - Full access to faction services
       - Allied with vision
    
    7. EXALTED (12000 to 20000) |cffffd700Gold|r
       - Can buy all items including exclusive items
       - Can hire companion units
       - Special reward and title granted (once per faction)
       - Maximum reputation honor
       - Allied with vision

    - For each faction with a valid owner (f.p), it checks the reputation of Player 1 (Red) toward that faction.
    - You can change which player is considered the "main" hero controller by editing:
        local player main = Player(0)

    Adding Reputation Changes:
        addRaw - affects only the selected faction, use these in triggers for quest reputation,etc. note: not for killing units unless specific
        call Reputation.addRaw(Player(0), Faction.get("Horde"), 100)
        call Reputation.addRaw(Player(0), Faction.get("Satyr"), -200)

        addLinked - affects the faction and linked factions, used only when killing units

    Legacy Reputation Multiboard
        - Preserved in code for reference only.
        - Not initialized or shown during normal gameplay.

    Linking factions:
        call horde.link(felorcs, -0.5)

    Getting faction (no other use)
        local Faction f = Faction.getFaction("Horde")
        call Reputation.addRaw(Player(0), f, 100)
    
    Master Alliance System Configuration:
        Set ENABLE_INTER_FACTION_ALLIANCES = true to enable inter-faction alliance control
        When enabled, computer factions will be allied/hostile to each other based on reputation
        
        Example: If Horde has -15000 rep with Alliance, they will be enemies
                 If Goblins have +8000 rep with Horde, they will be allied
        
        This means changing one faction's reputation affects the entire political landscape!

*/

//===================================================
// CONFIGURATION
//===================================================

globals
    private constant integer MAX_FACTIONS           = 11
    private constant integer REP_MIN                = -20000
    private constant integer REP_MAX                =  20000
    
    // Seven-tier reputation system
    // These are MINIMUM thresholds - the value needed to reach each tier
    // Made public for use in quest systems (accessible as Reputation_REP_ENEMY, etc.)
    public constant integer REP_ENEMY              = -12000      // Enemy: -20000 to -12000, some factions will hunt you
    public constant integer REP_HOSTILE            = -3000     // Hostile: -12000 to -3000, always attacked on sight
    public constant integer REP_UNFRIENDLY         = 0      // Unfriendly: -3000 to 0, cannot buy items/companions, no quest talk
    public constant integer REP_NEUTRAL            = 3000      // Neutral: 0 to 3000, can buy basic items, can talk
    public constant integer REP_FRIENDLY           = 6000     // Friendly: 3000 to 6000, can buy more items, can talk
    public constant integer REP_COVENANT           = 12000    // Covenant: 6000 to 12000, can buy more items, hire companions, can talk
    public constant integer REP_EXALTED            = 18000     // Exalted: 18000 to 20000, same as Covenant + special reward & title

    private constant real BOARD_UPDATE_INTERVAL     = 1.50
    private constant real RELATION_UPDATE_INTERVAL  = 5.00
    
    // MASTER ALLIANCE SYSTEM
    // When true, reputation system controls alliances between ALL computer players
    // When false, only controls Player 0's alliances with factions
    private constant boolean ENABLE_INTER_FACTION_ALLIANCES = false
    
    // COMPANION ALLIANCE SYSTEM
    // When true, companion player (Player 18) will mirror Player 0's alliance status with all factions
    // When false, companion player alliances are not managed by this system
    private constant boolean ENABLE_COMPANION_ALLIANCE_SYNC = true
    private constant integer COMPANION_PLAYER_ID = 18  // Player(18) - configurable companion player
    
    // TEMPORAL HOSTILITY SYSTEM
    // When true, non-hostile factions become temporarily hostile when attacked/killed by Player(0)
    // After the duration expires, the faction returns to its original status
    private constant boolean ENABLE_TEMPORAL_HOSTILITY = true
    
    // Duration (in seconds) that a faction remains temporarily hostile
    private constant real TEMPORAL_HOSTILITY_DURATION = 120.0

    private constant string ICON_ENEMY              = "ReplaceableTextures\\PassiveButtons\\PASRepHated.blp"
    private constant string ICON_HOSTILE            = "ReplaceableTextures\\PassiveButtons\\PASRepHostile.blp"
    private constant string ICON_UNFRIENDLY         = "ReplaceableTextures\\PassiveButtons\\PASRepUnfriendly.blp"
    private constant string ICON_NEUTRAL            = "ReplaceableTextures\\PassiveButtons\\PASRepNeutral.blp"
    private constant string ICON_FRIENDLY           = "ReplaceableTextures\\PassiveButtons\\PASRepHonored.blp"
    private constant string ICON_COVENANT           = "ReplaceableTextures\\PassiveButtons\\PASRepRevered.blp"
    private constant string ICON_EXALTED            = "ReplaceableTextures\\PassiveButtons\\PASRepExalted.blp"

    // Reputation change values per faction (when killed)
    private Table REP_KILL_DELTA
    private Table UNIT_TYPE_FACTIONS
    private Table PLAYER_FACTION_MAP  // Maps player ID to faction
    private Table prevStates
    private Table exaltedRewards  // Track if player has received Exalted reward for each faction
    private string array tmpCodes
    
    // Temporal hostility tracking
    private Table temporalHostilityActive  // Tracks which factions are temporarily hostile (by faction ID)
    private Table temporalHostilityOriginalStatus  // Stores original alliance state before temporary hostility
    private hashtable temporalHostilityHash  // Hashtable for storing timers and data
    
    // Debug flag
    boolean RE_DEBUG = false  // Set to true to enable debug messages
    
    // Debug reputation multiplier (10x gains/losses when enabled)
    private boolean REPUTATION_MULTIPLIER_ENABLED = false
    private constant real REPUTATION_MULTIPLIER = 10.0
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
    boolean isVisible   // controls if faction is shown in multiboard and if rep change messages are displayed

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
        set this.isVisible = true  // Default: faction is visible in multiboard and shows messages
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
        local integer playerId = GetPlayerId(p)
        local integer i = 1
        
        // First check the player-to-faction mapping
        if PLAYER_FACTION_MAP.has(playerId) then
            return PLAYER_FACTION_MAP[playerId]
        endif
        
        // Fallback to checking primary faction owners
        loop
            exitwhen i >= total
            if all[i] != null and all[i].p == p then
                return all[i]
            endif
            set i = i + 1
        endloop
        return 0
    endmethod
    
    // Map a player to a faction (allows multiple players per faction)
    static method mapPlayerToFaction takes player p, Faction f returns nothing
        set PLAYER_FACTION_MAP[GetPlayerId(p)] = f
    endmethod

    static method onInit takes nothing returns nothing
        set byName = Table.create()
        set PLAYER_FACTION_MAP = Table.create()
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
        local integer adjustedDelta = delta

        if udg_InCinematic then
            return
        endif

        // Apply reputation multiplier if enabled
        if REPUTATION_MULTIPLIER_ENABLED then
            set adjustedDelta = R2I(delta * REPUTATION_MULTIPLIER)
        endif

        set newVal = .getRep(p, f) + adjustedDelta
        call .setRep(p, f, newVal)
        
        // Only show messages if faction is visible
        if f.isVisible then
            if adjustedDelta > 0 then
                call DisplayTimedTextToPlayer(p, 0, 0, 2.50, "|cff80a0ff" + f.name + "|r reputation |cff00ff00+" + I2S(adjustedDelta) + "|r")
            elseif adjustedDelta < 0 then
                call DisplayTimedTextToPlayer(p, 0, 0, 2.50, "|cff80a0ff" + f.name + "|r reputation |cffff4040" + I2S(adjustedDelta) + "|r")
            endif
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
                    //call BJDebugMsg("[Reputation] Linked reputation: " + f.name + " affects " + other.name + " by " + I2S(R2I(delta * f.weights.real[other.id])))
                    call .addRaw(p, other, R2I(delta * f.weights.real[other.id]))
                endif
                set i = i + 1
            endloop
        endif
    endmethod

    static method getStatus takes player p, Faction f returns string
        local integer val = .getRep(p, f)
        if val < REP_ENEMY then
            return "|cff8b0000Enemy|r"        // Dark red
        elseif val < REP_HOSTILE then
            return "|cffff4040Hostile|r"      // Red
        elseif val < REP_UNFRIENDLY then
            return "|cffff8040Unfriendly|r"   // Orange
        elseif val < REP_NEUTRAL then
            return "|cffffffffNeutral|r"      // White
        elseif val < REP_FRIENDLY then
            return "|cff40ff40Friendly|r"     // Green
        elseif val < REP_COVENANT then
            return "|cff00ff00Covenant|r"     // Bright green
        else
            return "|cffffd700Exalted|r"      // Gold
        endif
    endmethod

    static method OnUnitKilled takes unit killer, unit victim returns nothing
        local player pKiller = GetOwningPlayer(killer)
        local Faction fVictim = Faction.getByUnit(victim)
        local integer delta

        if fVictim == null then
            if RE_DEBUG then
                call BJDebugMsg("[Reputation] Victim has no associated faction. Skipping reputation adjustment.")
            endif
            return 
        endif

        if REP_KILL_DELTA == null then
            set delta = 0
        else
            set delta = R2I(REP_KILL_DELTA.real[fVictim.id])
        endif

        // === Debug message ===
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Kill event: " + GetUnitName(killer) + " killed a unit of faction " + fVictim.name + " (delta=" + I2S(delta) + ")")
        endif

        if delta != 0 then
            call .addLinked(pKiller, fVictim, delta)
        else
            if RE_DEBUG then
                call BJDebugMsg("[Reputation] No REP_KILL_DELTA defined for faction " + fVictim.name)
            endif
        endif
    endmethod

    static method onInit takes nothing returns nothing
        set rep = Table.create()
        // ensure the kill-delta and unit-type lookup tables exist immediately
        set REP_KILL_DELTA = Table.create()
        set UNIT_TYPE_FACTIONS = Table.create()
        set exaltedRewards = Table.create()
        set prevStates = Table.create()
        set temporalHostilityActive = Table.create()
        set temporalHostilityOriginalStatus = Table.create()
        set temporalHostilityHash = InitHashtable()
    endmethod
endstruct

//===================================================
// ALLIANCE HELPER FUNCTIONS
//===================================================

// Get alliance state from reputation value
private function GetAllianceStateFromRep takes integer rep returns integer
    if rep < REP_ENEMY then
        return 1 // Enemy (Unallied with vision)
    elseif rep < REP_HOSTILE then
        return 2 // Hostile (Unallied)
    elseif rep < REP_UNFRIENDLY then
        return 3 // Unfriendly (Neutral)
    elseif rep < REP_NEUTRAL then
        return 4 // Neutral (Neutral with vision)
    elseif rep < REP_FRIENDLY then
        return 5 // Friendly (Allied)
    elseif rep < REP_COVENANT then
        return 6 // Covenant (Allied with vision)
    else
        return 7 // Exalted (Allied with vision)
    endif
endfunction

// Apply alliance state between two players
private function ApplyAllianceState takes player p1, player p2, integer allianceState returns nothing
    if RE_DEBUG then
        call BJDebugMsg("[ApplyAllianceState] Setting alliance state " + I2S(allianceState) + " between " + GetPlayerName(p1) + " and " + GetPlayerName(p2))
    endif
    
    if allianceState == 1 then
        // Enemy: Unallied with vision
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_UNALLIED)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_UNALLIED)
    elseif allianceState == 2 then
        // Hostile: Unallied
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_UNALLIED)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_UNALLIED)
    elseif allianceState == 3 then
        // Unfriendly: Neutral
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_NEUTRAL)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_NEUTRAL)
    elseif allianceState == 4 then
        // Neutral: Neutral with vision
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_NEUTRAL)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_NEUTRAL)
    elseif allianceState == 5 then
        // Friendly: Allied
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_ALLIED)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_ALLIED)
    else
        // Covenant/Exalted: Allied with vision
        call SetPlayerAllianceStateBJ(p1, p2, bj_ALLIANCE_ALLIED)
        call SetPlayerAllianceStateBJ(p2, p1, bj_ALLIANCE_ALLIED)
    endif
endfunction

// Apply alliance state for all players belonging to a faction
private function ApplyFactionAllianceState takes player mainPlayer, Faction f, integer allianceState returns nothing
    local integer i
    
    // Apply alliance to the faction's primary player
    if f.p != null then
        call ApplyAllianceState(mainPlayer, f.p, allianceState)
    endif
    
    // Apply alliance to all players mapped to this faction
    set i = 0
    loop
        exitwhen i > 23  // Check all player slots (0-23)
        if PLAYER_FACTION_MAP.has(i) then
            if PLAYER_FACTION_MAP[i] == f then
                call ApplyAllianceState(mainPlayer, Player(i), allianceState)
                if RE_DEBUG then
                    call BJDebugMsg("[ApplyFactionAllianceState] Applied alliance state " + I2S(allianceState) + " to mapped player " + I2S(i) + " (" + GetPlayerName(Player(i)) + ") of faction " + f.name)
                endif
            endif
        endif
        set i = i + 1
    endloop
endfunction

// Sync companion player's alliance to match Player 0's alliance with a faction
private function SyncCompanionAlliance takes player factionPlayer, integer allianceState returns nothing
    local player companionPlayer
    
    if not ENABLE_COMPANION_ALLIANCE_SYNC then
        return
    endif
    
    set companionPlayer = Player(COMPANION_PLAYER_ID)
    
    // Apply the same alliance state between companion and faction
    call ApplyAllianceState(companionPlayer, factionPlayer, allianceState)
    if RE_DEBUG then
        call BJDebugMsg("[CompanionSync] Synced " + GetPlayerName(companionPlayer) + " alliance with " + GetPlayerName(factionPlayer) + " to state " + I2S(allianceState))
    endif
endfunction

//===================================================
// TEMPORAL HOSTILITY SYSTEM
//===================================================

// Get remaining temporal hostility time for a faction
private function GetTemporalHostilityRemaining takes integer factionId returns real
    local timer t
    
    if not temporalHostilityActive.has(factionId) then
        return 0.0
    endif
    
    set t = LoadTimerHandle(temporalHostilityHash, factionId, 0)
    if t == null then
        return 0.0
    endif
    
    return TimerGetRemaining(t)
endfunction

struct TemporalHostility
    Faction faction
    integer originalAllianceState
    
    // Restore the faction to its original status
    method restore takes nothing returns nothing
        local player mainPlayer = Player(0)
        local integer factionId = this.faction.id
        
        if ENABLE_TEMPORAL_HOSTILITY and temporalHostilityActive.has(factionId) then
            // Restore original alliance state to all faction players
            call ApplyFactionAllianceState(mainPlayer, this.faction, this.originalAllianceState)
            
            // Sync companion player alliance if enabled
            call SyncCompanionAlliance(this.faction.p, this.originalAllianceState)
            
            // Clear temporal hostility tracking
            call temporalHostilityActive.remove(factionId)
            call temporalHostilityOriginalStatus.remove(factionId)
            call FlushChildHashtable(temporalHostilityHash, factionId)
            
            // Display message if faction is visible
            if this.faction.isVisible then
                call DisplayTimedTextToPlayer(mainPlayer, 0, 0, 3.0, "|cffff8040" + this.faction.name + " is no longer hostile to you.|r")
            endif
            
            if RE_DEBUG then
                call BJDebugMsg("[TemporalHostility] Restored " + this.faction.name + " to original state: " + I2S(this.originalAllianceState))
            endif
        endif
        
        call this.destroy()
    endmethod
    
    // Trigger temporary hostility for a faction
    static method trigger takes Faction f returns nothing
        local player mainPlayer = Player(0)
        local integer currentRep
        local integer currentState
        local integer factionId
        local TemporalHostility data
        local timer t
        
        if not ENABLE_TEMPORAL_HOSTILITY then
            return
        endif
        
        if f == null then
            return
        endif
        
        set factionId = f.id
        set currentRep = Reputation.getRep(mainPlayer, f)
        set currentState = GetAllianceStateFromRep(currentRep)
        
        // Only apply temporal hostility if faction is NOT already hostile or enemy
        // (allianceState 1 = Enemy, 2 = Hostile)
        if currentState > 2 then
            // Check if already temporarily hostile
            if not temporalHostilityActive.has(factionId) then
                // Store original alliance state
                set temporalHostilityOriginalStatus[factionId] = currentState
                
                // Mark as temporarily hostile
                set temporalHostilityActive[factionId] = 1
                
                // Apply hostile alliance state (state 2 = Hostile/Unallied) to all faction players
                call ApplyFactionAllianceState(mainPlayer, f, 2)
                
                // Sync companion player alliance if enabled
                call SyncCompanionAlliance(f.p, 2)
                
                // Display message if faction is visible
                if f.isVisible then
                    call DisplayTimedTextToPlayer(mainPlayer, 0, 0, 3.0, "|cffff4040" + f.name + " has become temporarily hostile!|r")
                endif
                
                if RE_DEBUG then
                    call BJDebugMsg("[TemporalHostility] " + f.name + " is now temporarily hostile (was state " + I2S(currentState) + ")")
                endif
                
                // Create timer to restore status
                set data = TemporalHostility.allocate()
                set data.faction = f
                set data.originalAllianceState = currentState
                
                set t = CreateTimer()
                call SaveTimerHandle(temporalHostilityHash, factionId, 0, t)
                call SaveInteger(temporalHostilityHash, GetHandleId(t), 0, data)
                call TimerStart(t, TEMPORAL_HOSTILITY_DURATION, false, function TemporalHostility.onExpire)
            else
                if RE_DEBUG then
                    call BJDebugMsg("[TemporalHostility] " + f.name + " is already temporarily hostile, not re-triggering")
                endif
            endif
        else
            if RE_DEBUG then
                call BJDebugMsg("[TemporalHostility] " + f.name + " is already hostile/enemy (state " + I2S(currentState) + "), skipping temporal hostility")
            endif
        endif
    endmethod
    
    // Timer callback to restore faction status
    static method onExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer timerId = GetHandleId(t)
        local TemporalHostility data = LoadInteger(temporalHostilityHash, timerId, 0)
        
        if data != 0 then
            call data.restore()
            call FlushChildHashtable(temporalHostilityHash, timerId)
        endif
        
        call DestroyTimer(t)
        set t = null
    endmethod
endstruct

//===================================================
// MULTIBOARD SYSTEM
//===================================================

// Legacy multiboard kept for reference only.
// ReputationUI is now the active reputation display and this board is never initialized.
struct ReputationBoard
    static multiboard array boards
    static timer updater

    static method show takes player p, boolean flag returns nothing
        // Legacy no-op: do not activate the old reputation multiboard.
        return
    endmethod

    static method createBoard takes player p returns nothing
        local multiboard mb = CreateMultiboard()
        local integer visibleCount = 0
        local integer i = 1
        local integer row = 1
        local multiboarditem mItem
        local Faction f
        local string value
        local integer repVal
        local string iconPath
        local string textColor

        // Count visible factions
        loop
            exitwhen i >= Faction.total
            set f = Faction.all[i]
            if f != null and f.isVisible then
                set visibleCount = visibleCount + 1
            endif
            set i = i + 1
        endloop

        call MultiboardSetTitleText(mb, "|cff20c0ff☯ Reputations|r")
        call MultiboardSetRowCount(mb, visibleCount + 1)  // +1 for header
        call MultiboardSetColumnCount(mb, 2)

        // Header row
        set mItem = MultiboardGetItem(mb, 0, 0)
        call MultiboardSetItemValue(mItem, "|cffffcc00Faction|r")
        call MultiboardSetItemWidth(mItem, 0.13)
        call MultiboardSetItemStyle(mItem, true, false)
        call MultiboardReleaseItem(mItem)

        set mItem = MultiboardGetItem(mb, 0, 1)
        call MultiboardSetItemValue(mItem, "|cffffcc00Status|r")
        call MultiboardSetItemWidth(mItem, 0.16)
        call MultiboardSetItemStyle(mItem, true, false)
        call MultiboardReleaseItem(mItem)

        // Faction rows
        set i = 1
        loop
            exitwhen i >= Faction.total
            set f = Faction.all[i]
            if f != null and f.isVisible then
                // Faction name cell
                set mItem = MultiboardGetItem(mb, row, 0)
                if ModuloInteger(i,2) == 0 then
                    call MultiboardSetItemValue(mItem, "|cffd0e0ff" + f.name + "|r")
                else
                    call MultiboardSetItemValue(mItem, "|cffb0c0e0" + f.name + "|r")
                endif
                call MultiboardSetItemWidth(mItem, 0.13)
                if f.iconPath != "" then 
                    call MultiboardSetItemIcon(mItem, f.iconPath)
                endif
                call MultiboardReleaseItem(mItem)
                
                // Reputation status cell
                set repVal = Reputation.getRep(p, f)
                if repVal < REP_ENEMY then
                    set iconPath = ICON_ENEMY
                    set textColor = "|cff8b0000"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_ENEMY) + ")|r"
                elseif repVal < REP_HOSTILE then
                    set iconPath = ICON_HOSTILE
                    set textColor = "|cffff4040"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_HOSTILE) + ")|r"
                elseif repVal < REP_UNFRIENDLY then
                    set iconPath = ICON_UNFRIENDLY
                    set textColor = "|cffff8040"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_UNFRIENDLY) + ")|r"
                elseif repVal < REP_NEUTRAL then
                    set iconPath = ICON_NEUTRAL
                    set textColor = "|cffffffff"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_NEUTRAL) + ")|r"
                elseif repVal < REP_FRIENDLY then
                    set iconPath = ICON_FRIENDLY
                    set textColor = "|cff40ff40"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_FRIENDLY) + ")|r"
                elseif repVal < REP_COVENANT then
                    set iconPath = ICON_COVENANT
                    set textColor = "|cff00ff00"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_COVENANT) + ")|r"
                else
                    set iconPath = ICON_EXALTED
                    set textColor = "|cffffd700"
                    set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_MAX) + ")|r"
                endif

                set mItem = MultiboardGetItem(mb, row, 1)
                call MultiboardSetItemIcon(mItem, iconPath)
                call MultiboardSetItemValue(mItem, value)
                call MultiboardSetItemWidth(mItem, 0.16)
                call MultiboardReleaseItem(mItem)
                
                set row = row + 1  // Increment row counter for next visible faction
            endif
            set i = i + 1
        endloop

        set boards[GetPlayerId(p)] = mb
        // hide multiboard initially
        call MultiboardDisplay(mb, false)

        // This duplicate code block should be removed or was intended elsewhere
        // Keeping it commented for safety
        // set mItem = MultiboardGetItem(mb, i, 1) // Status column
    endmethod

    static method update takes nothing returns nothing
        local player p = Player(0)
        local Faction f
        local multiboard mb
        local integer row
        local string value
        local integer repVal
        local string iconPath
        local string textColor
        local multiboarditem mItemStatus
        local integer i
        local integer displayRow

        if udg_InCinematic then 
            return 
        endif

        set mb = boards[GetPlayerId(p)]
        if mb == null then 
            return
        endif

        set i = 1
        set displayRow = 1  // Tracks actual multiboard row for visible factions
        
        loop
            exitwhen i >= Faction.total
            set f = Faction.all[i]

            if f != null and f.isVisible then
                set repVal = Reputation.getRep(p, f)

                // Check if faction is temporarily hostile - override icon/status if true
                if ENABLE_TEMPORAL_HOSTILITY and temporalHostilityActive.has(f.id) then
                    // Show Hostile icon and status with remaining time during temporal hostility
                    set iconPath = ICON_HOSTILE
                    set textColor = "|cffff4040"
                    set value = textColor + "|cffff4040Hostile|r |cff808080(" + I2S(R2I(GetTemporalHostilityRemaining(f.id))) + ")|r"
                else
                    // Determine icon and text color based on actual reputation
                    if repVal < REP_ENEMY then
                        set iconPath = ICON_ENEMY
                        set textColor = "|cff8b0000"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_ENEMY) + ")|r"
                    elseif repVal < REP_HOSTILE then
                        set iconPath = ICON_HOSTILE
                        set textColor = "|cffff4040"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_HOSTILE) + ")|r"
                    elseif repVal < REP_UNFRIENDLY then
                        set iconPath = ICON_UNFRIENDLY
                        set textColor = "|cffff8040"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_UNFRIENDLY) + ")|r"
                    elseif repVal < REP_NEUTRAL then
                        set iconPath = ICON_NEUTRAL
                        set textColor = "|cffffffff"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_NEUTRAL) + ")|r"
                    elseif repVal < REP_FRIENDLY then
                        set iconPath = ICON_FRIENDLY
                        set textColor = "|cff40ff40"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_FRIENDLY) + ")|r"
                    elseif repVal < REP_COVENANT then
                        set iconPath = ICON_COVENANT
                        set textColor = "|cff00ff00"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_COVENANT) + ")|r"
                    else
                        set iconPath = ICON_EXALTED
                        set textColor = "|cffffd700"
                        set value = textColor + Reputation.getStatus(p, f) + " |cff808080(" + I2S(repVal) + " / " + I2S(REP_MAX) + ")|r"
                    endif
                endif

                // Update status column using displayRow for visible factions
                set mItemStatus = MultiboardGetItem(mb, displayRow, 1)
                call MultiboardSetItemIcon(mItemStatus, iconPath)
                call MultiboardSetItemValue(mItemStatus, value)
                call MultiboardReleaseItem(mItemStatus)
                
                set displayRow = displayRow + 1
            endif

            set i = i + 1
        endloop
    endmethod

    static method onInit takes nothing returns nothing
        set updater = CreateTimer()
        call TimerStart(updater, BOARD_UPDATE_INTERVAL, true, function thistype.update)
    endmethod
endstruct

//===================================================
// RELATIONSHIP ADJUSTMENT
//===================================================

private function InitializePrevStates takes nothing returns nothing
    local integer i = 1
    local player mainPlayer = Player(0)
    local Faction f
    local integer rep
    local string status
    local integer key
    local integer allianceState

    if RE_DEBUG then
        call BJDebugMsg("[InitializePrevStates] Starting...")
    endif

    // prevStates table is now guaranteed to exist (created in Reputation.onInit)
    // Initialize all faction statuses AND apply initial alliance states
    loop
        exitwhen i >= Faction.total
        set f = Faction.all[i]
        if f.p != null then
            set rep = Reputation.getRep(mainPlayer, f)
            set key = f.id
            
            // Get alliance state from reputation
            set allianceState = GetAllianceStateFromRep(rep)

            // Determine initial status
            if allianceState == 1 then
                set status = "Enemy"
            elseif allianceState == 2 then
                set status = "Hostile"
            elseif allianceState == 3 then
                set status = "Unfriendly"
            elseif allianceState == 4 then
                set status = "Neutral"
            elseif allianceState == 5 then
                set status = "Friendly"
            elseif allianceState == 6 then
                set status = "Covenant"
            else
                set status = "Exalted"
            endif

            // Store status for future change detection
            set prevStates.string[key] = status
            
            // APPLY the initial alliance state to all faction players
            call ApplyFactionAllianceState(mainPlayer, f, allianceState)
            
            // Sync companion player alliance if enabled
            call SyncCompanionAlliance(f.p, allianceState)
            
            if RE_DEBUG then
                call BJDebugMsg("[InitializePrevStates] Set " + f.name + " to " + status + " (Rep: " + I2S(rep) + ", State: " + I2S(allianceState) + ")")
            endif
        endif
        set i = i + 1
    endloop

    if RE_DEBUG then
        call BJDebugMsg("[InitializePrevStates] Complete! Initialized " + I2S(i-1) + " faction states")
    endif
endfunction//===================================================
// INTER-FACTION ALLIANCE UPDATES
//===================================================

// Update alliances between computer-controlled factions based on their mutual reputations
private function UpdateInterFactionAlliances takes nothing returns nothing
    local integer i = 1
    local integer j = 1
    local Faction f1
    local Faction f2
    local player p1
    local player p2
    local integer rep1to2
    local integer rep2to1
    local integer finalRep
    local integer allianceState
    local integer key
    local string newStatus
    local string oldStatus
    
    if not ENABLE_INTER_FACTION_ALLIANCES then
        return
    endif
    
    // Loop through all faction pairs
    loop
        exitwhen i >= Faction.total
        set f1 = Faction.all[i]
        
        if f1.p != null then
            set p1 = f1.p
            set j = i + 1 // Only check pairs once (i < j)
            
            loop
                exitwhen j >= Faction.total
                set f2 = Faction.all[j]
                
                if f2.p != null then
                    set p2 = f2.p
                    
                    // Get mutual reputation (use the worse of the two)
                    set rep1to2 = Reputation.getRep(p1, f2)
                    set rep2to1 = Reputation.getRep(p2, f1)
                    
                    // Use the lower (worse) reputation to determine alliance
                    if rep1to2 < rep2to1 then
                        set finalRep = rep1to2
                    else
                        set finalRep = rep2to1
                    endif
                    
                    // Get alliance state from reputation
                    set allianceState = GetAllianceStateFromRep(finalRep)
                    
                    // Create unique key for this faction pair
                    set key = f1.id * 1000 + f2.id
                    
                    // Determine status string for tracking changes
                    if allianceState == 1 then
                        set newStatus = "Enemy"
                    elseif allianceState == 2 then
                        set newStatus = "Hostile"
                    elseif allianceState == 3 then
                        set newStatus = "Unfriendly"
                    elseif allianceState == 4 then
                        set newStatus = "Neutral"
                    elseif allianceState == 5 then
                        set newStatus = "Friendly"
                    elseif allianceState == 6 then
                        set newStatus = "Covenant"
                    else
                        set newStatus = "Exalted"
                    endif
                    
                    // Check if status changed
                    set oldStatus = prevStates.string[key]
                    
                    if oldStatus != newStatus then
                        // Apply new alliance state
                        call ApplyAllianceState(p1, p2, allianceState)
                        
                        // Save new status
                        set prevStates.string[key] = newStatus
                        
                        // Debug message
                        if RE_DEBUG then
                            call BJDebugMsg("[Reputation] Inter-faction alliance updated: " + f1.name + " <-> " + f2.name + " = " + newStatus)
                        endif
                    endif
                endif
                
                set j = j + 1
            endloop
        endif
        
        set i = i + 1
    endloop
endfunction

//===================================================
// PLAYER 0 ALLIANCE UPDATES
//===================================================

private function UpdateFactionAlliances takes nothing returns nothing
    local integer i = 1
    local player mainPlayer = Player(0) // The main hero player (Player 1 / Red)
    local player otherPlayer
    local Faction f
    local integer rep
    local string newStatus
    local string oldStatus
    local integer key
    local integer allianceState
    local boolean isTemporarilyHostile

    //call BJDebugMsg("[Reputation] Running UpdateFactionAlliances tick...")

    // Initialize table if null
    if prevStates == null then
        set prevStates = Table.create()
        //call BJDebugMsg("[Reputation] prevStates table initialized.")
    endif

    // Loop through all factions
    loop
        exitwhen i >= Faction.total
        set f = Faction.all[i]
        if f.p != null then
            set otherPlayer = f.p
            set rep = Reputation.getRep(mainPlayer, f)

            // Check if this faction is temporarily hostile
            set key = f.id
            set isTemporarilyHostile = temporalHostilityActive.has(key)
            
            // If temporarily hostile, skip alliance updates for this faction
            // The temporal hostility system will handle restoring the correct state
            if not isTemporarilyHostile then
                // Get alliance state from reputation
                set allianceState = GetAllianceStateFromRep(rep)
                
                // Determine current status string
                if allianceState == 1 then
                    set newStatus = "Enemy"
                elseif allianceState == 2 then
                    set newStatus = "Hostile"
                elseif allianceState == 3 then
                    set newStatus = "Unfriendly"
                elseif allianceState == 4 then
                    set newStatus = "Neutral"
                elseif allianceState == 5 then
                    set newStatus = "Friendly"
                elseif allianceState == 6 then
                    set newStatus = "Covenant"
                else
                    set newStatus = "Exalted"
                endif

                // Load previous status (if any) from table
                set oldStatus = prevStates.string[key]

                // If status changed, update alliances and display message
                if oldStatus != newStatus then
                    if RE_DEBUG then
                        call BJDebugMsg("[Reputation] Alliance state changed for " + f.name + " → " + newStatus + " (Rep: " + I2S(rep) + ", State: " + I2S(allianceState) + ")")
                    endif
                    
                    // Apply alliance state to all faction players
                    call ApplyFactionAllianceState(mainPlayer, f, allianceState)
                    
                    // Sync companion player alliance if enabled
                    call SyncCompanionAlliance(otherPlayer, allianceState)
                    
                    // Display appropriate message (only if faction is visible)
                    if f.isVisible then
                        if newStatus == "Enemy" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cff8b0000You are now an Enemy of " + f.name + "! They will hunt you!|r")
                        elseif newStatus == "Hostile" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffff4040You are now Hostile toward " + f.name + "!|r")
                        elseif newStatus == "Unfriendly" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffff8040You are now Unfriendly with " + f.name + ". You cannot buy items or hire companions.|r")
                        elseif newStatus == "Neutral" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffffffffYou are now Neutral with " + f.name + ". You can buy basic items.|r")
                        elseif newStatus == "Friendly" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cff40ff40You are now Friendly with " + f.name + "!|r")
                        elseif newStatus == "Covenant" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cff00ff00You have formed a Covenant with " + f.name + "! You can hire companions.|r")
                        elseif newStatus == "Exalted" then
                            call DisplayTextToPlayer(mainPlayer, 0, 0, "|cffffd700You are now Exalted with " + f.name + "! You have earned a special reward and title!|r")
                            
                            // Check if this is the first time reaching Exalted with this faction
                            if exaltedRewards[f.id] == 0 then
                                set exaltedRewards[f.id] = 1
                                // TODO: Grant special reward and title here
                                // Example: call GrantExaltedReward(mainPlayer, f)
                            endif
                        endif
                    endif

                    // Save current status as string
                    set prevStates.string[key] = newStatus
                endif
            endif
        endif
        set i = i + 1
    endloop
    
    // Update inter-faction alliances if enabled
    call UpdateInterFactionAlliances()
    
    return
endfunction

//===================================================
// AUTOMATIC KILL REPUTATION & TEMPORAL HOSTILITY
//===================================================
// PRIVATE - used with centralized death event system
private function OnUnitDeathHandler takes nothing returns nothing
    local unit killer = GetKillingUnit()
    local unit victim = GetDyingUnit()
    local Faction victimFaction
    
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] OnUnitDeathHandler triggered!")
    endif
    
    if killer == null then
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Killer is NULL!")
        endif
        return
    endif
    
    if victim == null then
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Victim is NULL!")
        endif
        return
    endif
    
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Killer: " + GetUnitName(killer) + " (Owner: " + GetPlayerName(GetOwningPlayer(killer)) + ")")
        call BJDebugMsg("[Reputation] Victim: " + GetUnitName(victim) + " (Owner: " + GetPlayerName(GetOwningPlayer(victim)) + ")")
    endif

    // Only Player 0 kills count
    if GetOwningPlayer(killer) == Player(0) then
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Player 0 is killer - calling OnUnitKilled")
        endif
        call Reputation.OnUnitKilled(killer, victim)
        
        // Trigger temporal hostility for the victim's faction
        set victimFaction = Faction.getByUnit(victim)
        if victimFaction != null then
            call TemporalHostility.trigger(victimFaction)
        endif
    else
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Killer is not Player 0, skipping reputation change")
        endif
    endif
endfunction

//===================================================
// UNIT ATTACK DETECTION FOR TEMPORAL HOSTILITY
//===================================================
private function OnUnitAttacked takes nothing returns nothing
    local unit attacker = GetAttacker()
    local unit target = GetTriggerUnit()
    local Faction targetFaction
    
    // Only track attacks by Player 0
    if GetOwningPlayer(attacker) == Player(0) then
        set targetFaction = Faction.getByUnit(target)
        if targetFaction != null then
            call TemporalHostility.trigger(targetFaction)
            if RE_DEBUG then
                call BJDebugMsg("[Reputation] Player 0 attacked " + targetFaction.name + " unit, triggering temporal hostility")
            endif
        endif
    endif
    
    set attacker = null
    set target = null
endfunction

// Register all units for attack detection
private function RegisterUnitForAttackDetection takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(t, function OnUnitAttacked)
    set t = null
endfunction

//===================================================
// GUI FRIENDLY WRAPPERS
//===================================================
function AddReputation takes player whichPlayer, string factionName, integer delta returns nothing
    local Faction f = Faction.getFaction(factionName)
    if f == 0 then
        call BJDebugMsg("[Reputation] GUI Error: Faction '" + factionName + "' not found.")
        return
    endif
    call Reputation.addRaw(whichPlayer, f, delta)
endfunction

function AddReputationLinked takes player whichPlayer, string factionName, integer delta returns nothing
    local Faction f = Faction.getFaction(factionName)
    if f == 0 then
        call BJDebugMsg("[Reputation] GUI Error: Faction '" + factionName + "' not found.")
        return
    endif
    call Reputation.addLinked(whichPlayer, f, delta)
endfunction

//===================================================
// DEBUG FUNCTIONS
//===================================================

// Set faction reputation to a specific value (bypass normal gain/loss system)
// Usage: call SetFactionReputation(Player(0), "Horde", 5000)
function SetFactionReputation takes player whichPlayer, string factionName, integer repValue returns nothing
    local Faction f = Faction.getFaction(factionName)
    if f == 0 then
        call BJDebugMsg("[DEBUG] Error: Faction '" + factionName + "' not found.")
        return
    endif
    
    call Reputation.setRep(whichPlayer, f, repValue)
    call BJDebugMsg("[DEBUG] Set " + factionName + " reputation to " + I2S(repValue) + " for " + GetPlayerName(whichPlayer))
    
    // Display message to player
    call DisplayTimedTextToPlayer(whichPlayer, 0, 0, 3.0, "|cffffcc00[DEBUG] " + factionName + " reputation set to " + I2S(repValue) + "|r")
endfunction

// Manually trigger temporal hostility for a faction
// Usage: call TriggerFactionTemporalHostility("Horde")
function TriggerFactionTemporalHostility takes string factionName returns nothing
    local Faction f = Faction.getFaction(factionName)
    if f == 0 then
        call BJDebugMsg("[DEBUG] Error: Faction '" + factionName + "' not found.")
        return
    endif
    
    call TemporalHostility.trigger(f)
    call BJDebugMsg("[DEBUG] Triggered temporal hostility for " + factionName)
endfunction

// Toggle 10x reputation multiplier on/off
// Usage: call SetReputationMultiplier(true)  // Enable 10x gains/losses
// Usage: call SetReputationMultiplier(false) // Disable multiplier (normal gains/losses)
function SetReputationMultiplier takes boolean enable returns nothing
    set REPUTATION_MULTIPLIER_ENABLED = enable
    
    if enable then
        call BJDebugMsg("[DEBUG] Reputation multiplier ENABLED - all reputation changes will be " + R2S(REPUTATION_MULTIPLIER) + "x")
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "|cffffcc00[DEBUG] Reputation multiplier ENABLED (" + R2S(REPUTATION_MULTIPLIER) + "x)|r")
    else
        call BJDebugMsg("[DEBUG] Reputation multiplier DISABLED - normal reputation changes")
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "|cffffcc00[DEBUG] Reputation multiplier DISABLED (normal)|r")
    endif
endfunction

//===================================================
// HELPER FUNCTION
//===================================================
private function AddUnitTypesToFaction takes Faction f, integer count returns nothing
    local integer i = 0
    loop
        exitwhen i >= count
        // Convert string key into integer hash
        //set UNIT_TYPE_FACTIONS[StringHash(tmpCodes[i])] = f
        set UNIT_TYPE_FACTIONS[BlzS2FourCC(tmpCodes[i])] = f
        set i = i + 1
    endloop
endfunction

//===================================================
// INIT UNIT TYPE FACTIONS
//===================================================
private function InitUnitTypeFactions takes nothing returns nothing
    local Faction f

    // === Gnolls ===
    set f = Faction.getFaction("Gnolls")
    set tmpCodes[0]     = "ngno"
    set tmpCodes[1]     = "ngns"
    set tmpCodes[2]     = "ngnb"
    set tmpCodes[3]     = "ngnv"
    set tmpCodes[4]     = "ngna"
    set tmpCodes[5]     = "ngnw"
    set tmpCodes[6]     = "ngow"
    set tmpCodes[7]     = "n626"
    set tmpCodes[8]     = "n60O"
    set tmpCodes[9]     = "n61A"
    set tmpCodes[10]    = "n634"
    set tmpCodes[11]    = "n609"
    call AddUnitTypesToFaction(f, 12)

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
    local Faction jungletrolls = Faction.createFaction("Jungle trolls", null)
    local Faction foresttrolls  = Faction.createFaction("Forest trolls", null)
    local Faction kobolds      = Faction.createFaction("Kobolds", null)

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] All factions created successfully")
    endif

    // Map additional players to factions (multiple players can share the same faction)
    call Faction.mapPlayerToFaction(Player(1), horde)  // Player 2 is also Horde
    // Example: call Faction.mapPlayerToFaction(Player(9), horde)  // Player 10 is also Horde

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Starting faction linking...")
    endif

    // Link factions
    // When enemy factions are killed, allied factions gain reputation
    // Negative weight means: when killed faction loses rep, linked faction gains rep
    call horde.linkFaction(alliance, -1.0)
    call horde.linkFaction(satyr, -1.0)
    call horde.linkFaction(gnolls, -1.0)
    call horde.linkFaction(humancitizen, -1.0)
    call horde.linkFaction(riverbane, -1.0)
    
    call satyr.linkFaction(horde, -1.0)     // Kill satyr = +horde rep
    call gnolls.linkFaction(horde, -1.0)    // Kill gnolls = +horde rep
    call riverbane.linkFaction(horde, -1.0) // Kill riverbane = +horde rep
    call alliance.linkFaction(horde, -1.0)  // Kill alliance = +horde rep
    call humancitizen.linkFaction(horde, -1.0) // Kill citizens = +horde rep
    call felorcs.linkFaction(horde, -1.0)   // Kill fel orcs = +horde rep

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Faction linking complete")
        call BJDebugMsg("[InitFactions] Setting up kill deltas...")
    endif

    // Setup kill deltas
    // Positive = friendly, negative = hostile
    //set REP_KILL_DELTA.real[satyr.id] = 200    // increases Horde rep
    set REP_KILL_DELTA.real[horde.id] = -50
    set REP_KILL_DELTA.real[satyr.id] = -50
    set REP_KILL_DELTA.real[riverbane.id] = -50
    set REP_KILL_DELTA.real[alliance.id] = -50
    set REP_KILL_DELTA.real[felorcs.id] = -50
    set REP_KILL_DELTA.real[undead.id] = -50
    set REP_KILL_DELTA.real[goblins.id] = -50
    set REP_KILL_DELTA.real[elarindor.id] = -50
    set REP_KILL_DELTA.real[bonecrushers.id] = -50
    set REP_KILL_DELTA.real[realhorde.id] = -50
    set REP_KILL_DELTA.real[humancitizen.id] = -50
    set REP_KILL_DELTA.real[gnolls.id] = -50
    set REP_KILL_DELTA.real[jungletrolls.id] = -50
    set REP_KILL_DELTA.real[foresttrolls.id] = -50
    set REP_KILL_DELTA.real[kobolds.id] = -50

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Kill deltas set")
        call BJDebugMsg("[InitFactions] Setting initial reputation values...")
    endif

    // Set initial reputation values
    call Reputation.setRep(p, horde, 2000)
    call Reputation.setRep(p, satyr, -2000)
    call Reputation.setRep(p, riverbane, -2000)
    call Reputation.setRep(p, alliance, -7000)
    call Reputation.setRep(p, felorcs, -20000)
    call Reputation.setRep(p, undead, -20000)
    call Reputation.setRep(p, goblins, 0)
    call Reputation.setRep(p, elarindor, 0)
    call Reputation.setRep(p, bonecrushers, -2000)
    call Reputation.setRep(p, realhorde, -20000)
    call Reputation.setRep(p, humancitizen, -2000)
    call Reputation.setRep(p, gnolls, -6000)
    call Reputation.setRep(p, jungletrolls, -6000)
    call Reputation.setRep(p, foresttrolls, -6000)
    call Reputation.setRep(p, kobolds, -6000)

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Initial reputation values set")
        call BJDebugMsg("[InitFactions] Setting up faction icons...")
    endif

    //set horde.iconPath        = "ReplaceableTextures\\CommandButtons\\BTNGrunt.blp"
    set horde.iconPath        = "ReplaceableTextures\\PassiveButtons\\PASFactionHorde.blp"
    set realhorde.iconPath    = "ReplaceableTextures\\PassiveButtons\\PASFactionTrueHorde.blp"
    set alliance.iconPath     = "ReplaceableTextures\\PassiveButtons\\PASFactionHumanAlliance.blp"
    set felorcs.iconPath      = "ReplaceableTextures\\CommandButtons\\BTNChaosGrunt.blp"
    set satyr.iconPath        = "ReplaceableTextures\\PassiveButtons\\PASFactionOther1.blp"
    set gnolls.iconPath       = "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp"
    set riverbane.iconPath    = "ReplaceableTextures\\PassiveButtons\\PASFactionHuman.blp"
    set humancitizen.iconPath = "ReplaceableTextures\\PassiveButtons\\PASFactionHuman.blp"
    set bonecrushers.iconPath = "ReplaceableTextures\\PassiveButtons\\PASFactionOther2.blp"
    set elarindor.iconPath    = "ReplaceableTextures\\PassiveButtons\\PASFactionElf1.blp"
    set goblins.iconPath      = "ReplaceableTextures\\PassiveButtons\\PASFactionGoblin.blp"
    set undead.iconPath       = "ReplaceableTextures\\PassiveButtons\\PASFactionUndead.blp"
    set jungletrolls.iconPath = "ReplaceableTextures\\PassiveButtons\\PASFactionTroll.blp"
    set foresttrolls.iconPath = "ReplaceableTextures\\PassiveButtons\\PASFactionTroll.blp"
    set kobolds.iconPath      = "ReplaceableTextures\\PassiveButtons\\PASFactionOther1.blp"

    // Note: Status icons (Enemy, Hostile, Unfriendly, Neutral, Friendly, Covenant, Exalted)
    // are now standardized across all factions using the global ICON_* constants
    // Previously, each faction had custom iconFriendly, iconNeutral, and iconHostile properties
    // Now all factions use the same reputation-based icons defined in the global constants section

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Icons set")
    endif
    
    // Configure faction visibility (optional - all factions are visible by default)
    // Set isVisible = false to hide faction from multiboard and suppress reputation messages
    // Example: set gnolls.isVisible = false  // Gnolls won't appear in reputation board
    set gnolls.isVisible = false  // Gnolls won't appear in reputation board
    set undead.isVisible = false  // Gnolls won't appear in reputation board
    set felorcs.isVisible = false  // Gnolls won't appear in reputation board
    set jungletrolls.isVisible = false  // Gnolls won't appear in reputation board
    set foresttrolls.isVisible = false  // Gnolls won't appear in reputation board
    set kobolds.isVisible = false  // Gnolls won't appear in reputation board
    
    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Calling InitializePrevStates()...")
    endif

    // Initialize previous states before starting the timer
    call InitializePrevStates()

    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] InitializePrevStates() complete")
        call BJDebugMsg("[InitFactions] Starting alliance update timer...")
    endif

    // Start periodic alliance updates
    call TimerStart(CreateTimer(), RELATION_UPDATE_INTERVAL, true, function UpdateFactionAlliances)
    
    if RE_DEBUG then
        call BJDebugMsg("[InitFactions] Complete!")
    endif
endfunction

//===================================================
// INITIALIZATION
//===================================================
private function InitReputations takes nothing returns nothing
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Starting initialization...")
    endif
    
    // Init core systems
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Calling Faction.onInit()...")
    endif
    call Faction.onInit()
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Calling Reputation.onInit()...")
    endif
    call Reputation.onInit()
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Calling InitFactions()...")
    endif
    call InitFactions()
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Calling InitUnitTypeFactions()...")
    endif
    call InitUnitTypeFactions()   // Must be called AFTER InitFactions so factions exist!
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Skipping legacy ReputationBoard initialization; ReputationUI handles display.")
    endif

    // Register with centralized death event system
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Registering death event handler...")
    endif
    call UnitDeathEvent_Register(function OnUnitDeathHandler)
    
    // Register attack detection for temporal hostility
    if ENABLE_TEMPORAL_HOSTILITY then
        if RE_DEBUG then
            call BJDebugMsg("[Reputation] Registering attack detection for temporal hostility...")
        endif
        call RegisterUnitForAttackDetection()
    endif
    
    if RE_DEBUG then
        call BJDebugMsg("[Reputation] Initialization complete!")
    endif
endfunction

endlibrary
