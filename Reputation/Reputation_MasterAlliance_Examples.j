//===========================================================================
// Example: Master Alliance System Usage
//===========================================================================
// This file demonstrates how to use the reputation system's master alliance
// control to create dynamic faction relationships.
//===========================================================================

// Example 1: Setting up faction warfare
function Example_FactionWarfare takes nothing returns nothing
    // Make Horde and Alliance enemies
    call Reputation.setRep(Player(1), Faction.get("Alliance"), -15000)  // Horde hates Alliance
    call Reputation.setRep(Player(2), Faction.get("Horde"), -15000)     // Alliance hates Horde
    
    // Result: Horde and Alliance units will attack each other on sight
    // The system automatically sets them to UNALLIED alliance state
endfunction

// Example 2: Creating allied factions
function Example_AlliedFactions takes nothing returns nothing
    // Make Goblins allied with Horde
    call Reputation.setRep(Player(3), Faction.get("Horde"), 8000)    // Goblins like Horde
    call Reputation.setRep(Player(1), Faction.get("Goblins"), 8000)  // Horde likes Goblins
    
    // Result: Goblin and Horde units will help defend each other
    // The system automatically sets them to ALLIED WITH VISION
endfunction

// Example 3: Quest that changes faction relations
function Example_PeaceTreaty takes nothing returns nothing
    // Player completes "Peace Treaty" quest between Horde and Alliance
    
    // Give massive reputation boost to both factions with each other
    call Reputation.addRaw(Player(1), Faction.get("Alliance"), 18000)  // Horde gains rep with Alliance
    call Reputation.addRaw(Player(2), Faction.get("Horde"), 18000)     // Alliance gains rep with Horde
    
    // Result: They go from Enemy (-15000) to Friendly (+3000)
    // Units stop fighting, become allied
    // System displays messages about the alliance change
    
    // Display quest completion message
    call DisplayTextToPlayer(Player(0), 0, 0, "|cff00ff00Peace Treaty completed! Horde and Alliance are now allied!|r")
endfunction

// Example 4: Betrayal scenario
function Example_Betrayal takes nothing returns nothing
    // Setup: Player is allied with Goblins
    // Player accidentally kills a Goblin merchant
    
    local unit victim = GetTriggerUnit()
    local Faction goblins = Faction.get("Goblins")
    
    // Check if victim is a Goblin
    if Faction.getByUnit(victim) == goblins then
        // Significant reputation loss
        call Reputation.addRaw(Player(0), goblins, -5000)
        
        // Display warning
        call DisplayTextToPlayer(Player(0), 0, 0, "|cffff4040Warning! You have lost reputation with the Goblins!|r")
        
        // Result: Player's alliance with Goblins may degrade
        // From Exalted -> Covenant -> Friendly -> Neutral -> Hostile
    endif
endfunction

// Example 5: Checking current alliance state
function Example_CheckAlliance takes nothing returns nothing
    local Faction horde = Faction.get("Horde")
    local Faction alliance = Faction.get("Alliance")
    local integer hordeRep
    local integer allianceRep
    local string status
    
    // Get Horde's reputation with Alliance
    set hordeRep = Reputation.getRep(Player(1), alliance)
    
    // Get Alliance's reputation with Horde
    set allianceRep = Reputation.getRep(Player(2), horde)
    
    // Display to player
    call DisplayTextToPlayer(Player(0), 0, 0, "Horde reputation with Alliance: " + I2S(hordeRep))
    call DisplayTextToPlayer(Player(0), 0, 0, "Alliance reputation with Horde: " + I2S(allianceRep))
    
    // Get status string
    set status = Reputation.getStatusText(hordeRep)
    call DisplayTextToPlayer(Player(0), 0, 0, "Status: " + status)
endfunction

// Example 6: Gradual reputation change over time
function Example_GradualChange takes nothing returns nothing
    // Create a repeating timer that slowly improves relations
    local timer t = CreateTimer()
    
    call TimerStart(t, 60.0, true, function GradualRepIncrease)
    
    // This could represent diplomacy efforts, trade relations, etc.
endfunction

function GradualRepIncrease takes nothing returns nothing
    // Each minute, slightly improve Horde-Alliance relations
    call Reputation.addRaw(Player(1), Faction.get("Alliance"), 100)
    call Reputation.addRaw(Player(2), Faction.get("Horde"), 100)
    
    // Over time, they'll go from Enemy -> Hostile -> Unfriendly -> Neutral -> Friendly
    // This creates a slow thawing of relations
endfunction

// Example 7: Multi-faction politics
function Example_ComplexPolitics takes nothing returns nothing
    // Setup: 4 factions - Horde, Alliance, Goblins, Undead
    
    // Horde vs Alliance: Enemies
    call Reputation.setRep(Player(1), Faction.get("Alliance"), -15000)
    call Reputation.setRep(Player(2), Faction.get("Horde"), -15000)
    
    // Goblins: Allied with Horde, Neutral with Alliance
    call Reputation.setRep(Player(3), Faction.get("Horde"), 8000)
    call Reputation.setRep(Player(1), Faction.get("Goblins"), 8000)
    call Reputation.setRep(Player(3), Faction.get("Alliance"), 1000)
    call Reputation.setRep(Player(2), Faction.get("Goblins"), 1000)
    
    // Undead: Enemies with everyone
    call Reputation.setRep(Player(4), Faction.get("Horde"), -15000)
    call Reputation.setRep(Player(4), Faction.get("Alliance"), -15000)
    call Reputation.setRep(Player(4), Faction.get("Goblins"), -15000)
    call Reputation.setRep(Player(1), Faction.get("Undead"), -15000)
    call Reputation.setRep(Player(2), Faction.get("Undead"), -15000)
    call Reputation.setRep(Player(3), Faction.get("Undead"), -15000)
    
    // Result: Complex web of alliances
    // Horde + Goblins vs Alliance vs Undead
    // But Alliance won't attack Goblins (neutral)
    // Everyone attacks Undead on sight
endfunction

// Example 8: Player reputation affecting faction relations
function Example_PlayerInfluence takes nothing returns nothing
    // Player has high reputation with both Horde and Alliance
    call Reputation.setRep(Player(0), Faction.get("Horde"), 15000)     // Exalted
    call Reputation.setRep(Player(0), Faction.get("Alliance"), 15000)  // Exalted
    
    // But Horde and Alliance still hate each other
    // (Player reputation doesn't affect inter-faction relations)
    
    // To make them like each other, player must complete quests
    // that specifically improve their mutual reputation
endfunction

// Example 9: Disabling inter-faction alliance control
function Example_DisableInterFaction takes nothing returns nothing
    // In Reputation.j, set:
    // private constant boolean ENABLE_INTER_FACTION_ALLIANCES = false
    
    // Then only Player 0's alliances are controlled by reputation
    // Computer factions' alliances with each other must be set manually
    
    // This is useful if you want:
    // - Manual control over faction politics
    // - Scripted alliance changes at specific times
    // - Simpler alliance setup
endfunction

// Example 10: Reputation tiers and alliance states
function Example_AllReputationTiers takes nothing returns nothing
    local Faction testFaction = Faction.get("TestFaction")
    
    // Enemy: -20000 to -12000 -> Unallied with Vision
    call Reputation.setRep(Player(0), testFaction, -15000)
    // Player can see faction units, they attack on sight
    
    // Hostile: -12000 to -3000 -> Unallied
    call Reputation.setRep(Player(0), testFaction, -8000)
    // They attack on sight, no vision sharing
    
    // Unfriendly: -3000 to 0 -> Neutral
    call Reputation.setRep(Player(0), testFaction, -1500)
    // Won't attack first, but won't help either
    
    // Neutral: 0 to 3000 -> Neutral with Vision
    call Reputation.setRep(Player(0), testFaction, 1500)
    // Can see each other, won't attack unless provoked
    
    // Friendly: 3000 to 6000 -> Allied
    call Reputation.setRep(Player(0), testFaction, 4500)
    // Will defend each other, basic alliance
    
    // Covenant: 6000 to 12000 -> Allied with Vision
    call Reputation.setRep(Player(0), testFaction, 9000)
    // Full alliance, shared vision
    
    // Exalted: 12000+ -> Allied with Vision
    call Reputation.setRep(Player(0), testFaction, 15000)
    // Full alliance, shared vision, special rewards
endfunction

//===========================================================================
// HOW TO USE IN YOUR MAP
//===========================================================================
/*
    1. Enable/disable inter-faction alliances:
       In Reputation.j, set ENABLE_INTER_FACTION_ALLIANCES = true/false
    
    2. Set initial faction reputations in InitFactions():
       call Reputation.setRep(Player(1), Faction.get("Alliance"), -15000)
    
    3. Create quests that change faction relations:
       call Reputation.addRaw(Player(1), Faction.get("Alliance"), 5000)
    
    4. Let the system handle all alliance updates automatically
       (Updates every 5 seconds via UpdateFactionAlliances)
    
    5. Monitor changes via debug messages:
       [Reputation] Inter-faction alliance updated: Horde <-> Alliance = Friendly
    
    6. Use reputation for gameplay mechanics:
       - Item shop restrictions (check player rep with vendor faction)
       - Quest availability (require minimum rep)
       - Unit hiring (require Covenant or higher)
       - Special abilities (unlock at Exalted)
*/
