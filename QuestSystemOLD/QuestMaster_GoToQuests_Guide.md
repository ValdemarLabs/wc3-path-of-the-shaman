# QuestMaster GoToPlace/GoToZone Quest Guide

## Overview

This guide explains how to use the new **GoToPlace with Rect** and **GoToZone** quest templates, along with the **autocomplete** feature that allows quests to complete without returning to the quest giver.

---

## Autocomplete Feature

Some quests (like exploration quests) should complete automatically when the objective is reached, without requiring the player to return to the quest giver.

### How to Enable Autocomplete

**Option 1: Using Template Functions**
```jass
// TemplateGoToPlaceRect and TemplateGoToZone have autocomplete parameter
local QuestData q = QuestMaster_TemplateGoToPlaceRect(
    "Discover Ancient Ruins", 
    udg_QuestGiver, 
    "normal", 
    10, 
    "the Ancient Ruins", 
    gg_rct_AncientRuins,    // Target rect
    true                      // Auto-complete = true
)
```

**Option 2: Using API Function**
```jass
local QuestData q = QuestMaster_TemplateGoToPlace("Explore Valley", udg_Thrall, "normal", 5, "Hidden Valley")
call QuestMaster_SetAutoComplete(q.id, true)
```

**Option 3: By Name and Giver**
```jass
call QuestMaster_SetAutoCompleteByNameAndGiver("Explore Valley", udg_Thrall, true)
```

---

## GoToPlace with Rect

Create exploration quests that track when the player enters a specific rectangle region.

### Basic Usage

```jass
local QuestData q = QuestMaster_TemplateGoToPlaceRect(
    "Discover the Grove",           // Quest name
    udg_Aradion,                     // Quest giver
    "normal",                        // Quest type
    8,                               // Quest level
    "Twilight Grove",                // Place name (for objective text)
    gg_rct_TwilightGrove,           // Target rect (where player must go)
    true                             // Auto-complete when entering rect
)
set q.title = "Discover the Twilight Grove"
set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
set q.description = "Explore the mysterious Twilight Grove to the north.\n\n"
call q.setRewardParams(true, 0, true, 100, false, 0, true, 200, false)
```

### Checking if Hero is in Target Rect

You can check if a hero has reached the target rect:

```jass
// By quest ID
if QuestMaster_CheckHeroInTargetRect(questId, hero) then
    call QuestMaster_SetRequirementCompleted(questId, 1, true)
endif

// By quest name and giver
if QuestMaster_CheckHeroInTargetRectByNameAndGiver("Discover the Grove", udg_Aradion, hero) then
    call QuestMaster_SetRequirementCompleted(questId, 1, true)
endif
```

### Setting Target Rect After Creation

```jass
// By quest ID
call QuestMaster_SetTargetRect(questId, gg_rct_TargetLocation)

// By quest name and giver
call QuestMaster_SetTargetRectByNameAndGiver("Quest Name", udg_Giver, gg_rct_TargetLocation)
```

---

## GoToZone Quest

Create quests that complete when the player enters a specific zone (using ZonesCore/ZoneEvent systems).

### Basic Usage

```jass
local QuestData q = QuestMaster_TemplateGoToZone(
    "Enter Deadwoods",              // Quest name
    udg_Aradion,                    // Quest giver
    "normal",                       // Quest type
    15,                             // Quest level
    "Deadwoods",                    // Zone name (for objective text)
    11,                             // Zone ID (from ZonesCore)
    true                            // Auto-complete when entering zone
)
set q.title = "Journey to the Deadwoods"
set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHaunt.blp"
set q.description = "Travel to the dark Deadwoods forest.\n\n"
call q.setRewardParams(true, 0, true, 150, false, 0, true, 300, false)
```

### Zone IDs Reference

Common zone IDs (from your ZonesCore setup):
- **11** - Deadwoods
- **3** - Twilight Grove
- **18** - Underground areas
- *(Check your ZonesCore.j configuration for complete list)*

### Checking if Hero is in Target Zone

```jass
// Get current zone from ZoneEvent
local integer currentZone = ZoneEvent_GetCurrentZone()

// By quest ID
if QuestMaster_CheckHeroInTargetZone(questId, currentZone) then
    call QuestMaster_SetRequirementCompleted(questId, 1, true)
endif

// By quest name and giver
if QuestMaster_CheckHeroInTargetZoneByNameAndGiver("Enter Deadwoods", udg_Aradion, currentZone) then
    call QuestMaster_SetRequirementCompleted(questId, 1, true)
endif
```

### Setting Target Zone After Creation

```jass
// By quest ID
call QuestMaster_SetTargetZone(questId, 11)

// By quest name and giver
call QuestMaster_SetTargetZoneByNameAndGiver("Quest Name", udg_Giver, 11)
```

---

## Integration Examples

### Example 1: GoToPlace with Periodic Check

Create a periodic trigger that checks if heroes are in the target rect:

```jass
function CheckGoToPlaceQuests takes nothing returns nothing
    local integer questId = // your quest ID
    local group g = GetUnitsOfPlayerAll(Player(0))
    local unit u
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        if IsUnitType(u, UNIT_TYPE_HERO) then
            if QuestMaster_CheckHeroInTargetRect(questId, u) then
                call QuestMaster_SetRequirementCompleted(questId, 1, true)
                // If autocomplete is enabled, quest will complete automatically
            endif
        endif
    endloop
    
    call DestroyGroup(g)
endfunction

function Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 1.0, true)  // Check every second
    call TriggerAddAction(t, function CheckGoToPlaceQuests)
endfunction
```

### Example 2: GoToZone with ZoneEvent Integration

Integrate with the ZoneEvent system:

```jass
function OnZoneEntered takes nothing returns nothing
    local integer questId = // your quest ID
    local integer enteredZoneId = ZoneEvent_GetCurrentZone()
    
    if QuestMaster_CheckHeroInTargetZone(questId, enteredZoneId) then
        call QuestMaster_SetRequirementCompleted(questId, 1, true)
        // If autocomplete is enabled, quest will complete automatically
    endif
endfunction

function Init takes nothing returns nothing
    // Hook into ZoneEvent system
    // (Implement based on your ZoneEvent callback system)
endfunction
```

### Example 3: Region Enter Event

Use native region events for immediate response:

```jass
function OnEnterQuestRegion takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer questId = // your quest ID
    
    if IsUnitType(u, UNIT_TYPE_HERO) and GetOwningPlayer(u) == Player(0) then
        if QuestMaster_CheckHeroInTargetRect(questId, u) then
            call QuestMaster_SetRequirementCompleted(questId, 1, true)
        endif
    endif
endfunction

function RegisterQuestRegion takes rect r returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, r)
    call TriggerAddAction(t, function OnEnterQuestRegion)
endfunction
```

---

## Complete Quest Lifecycle Example

```jass
function CreateExplorationQuest takes nothing returns nothing
    local QuestData q
    local string giverName = "Aradion the Farseer"
    
    // Create quest with rect and autocomplete
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Discover Hidden Valley",
        udg_Aradion,
        "normal",
        10,
        "the Hidden Valley",
        gg_rct_HiddenValley,
        true  // Auto-complete
    )
    
    // Set quest details
    set q.title = "Discover the Hidden Valley"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
    set q.description = "Find the legendary Hidden Valley deep in the forest.\n\n"
    set q.infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
    set q.info2Text = "|cffffcc00Recommended level:|r 10\n\n"
    set q.requiredLevel = 8
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 200, false, 0, true, 500, false)
    call q.setReceiverDisplayName(giverName)
endfunction

function CheckExplorationQuests takes nothing returns nothing
    local group g = GetUnitsOfPlayerAll(Player(0))
    local unit u
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        if IsUnitType(u, UNIT_TYPE_HERO) then
            // Check "Discover Hidden Valley"
            if QuestMaster_CheckHeroInTargetRectByNameAndGiver(
                "Discover Hidden Valley", 
                udg_Aradion, 
                u
            ) then
                // Mark objective complete
                call QuestMaster_SetRequirementCompleted(
                    QuestMaster_GetByNameAndGiver("Discover Hidden Valley", udg_Aradion).id,
                    1,
                    true
                )
                // Since autocomplete is enabled, quest completes automatically!
            endif
        endif
    endloop
    
    call DestroyGroup(g)
endfunction
```

---

## API Reference

### Template Functions

```jass
// Original (no rect tracking)
function QuestMaster_TemplateGoToPlace takes string questName, unit questGiver, string questType, integer questLevel, string placeName returns QuestData

// New (with rect and autocomplete)
function QuestMaster_TemplateGoToPlaceRect takes string questName, unit questGiver, string questType, integer questLevel, string placeName, rect targetRect, boolean autoComplete returns QuestData

// Zone-based
function QuestMaster_TemplateGoToZone takes string questName, unit questGiver, string questType, integer questLevel, string zoneName, integer zoneId, boolean autoComplete returns QuestData
```

### Autocomplete Functions

```jass
function QuestMaster_SetAutoComplete takes integer questId, boolean flag returns nothing
function QuestMaster_SetAutoCompleteByNameAndGiver takes string questName, unit questGiver, boolean flag returns nothing
```

### Target Rect Functions

```jass
function QuestMaster_SetTargetRect takes integer questId, rect r returns nothing
function QuestMaster_SetTargetRectByNameAndGiver takes string questName, unit questGiver, rect r returns nothing
function QuestMaster_CheckHeroInTargetRect takes integer questId, unit hero returns boolean
function QuestMaster_CheckHeroInTargetRectByNameAndGiver takes string questName, unit questGiver, unit hero returns boolean
```

### Target Zone Functions

```jass
function QuestMaster_SetTargetZone takes integer questId, integer zoneId returns nothing
function QuestMaster_SetTargetZoneByNameAndGiver takes string questName, unit questGiver, integer zoneId returns nothing
function QuestMaster_CheckHeroInTargetZone takes integer questId, integer currentZoneId returns boolean
function QuestMaster_CheckHeroInTargetZoneByNameAndGiver takes string questName, unit questGiver, integer currentZoneId returns boolean
```

---

## Best Practices

1. **Use Autocomplete for Exploration**: GoToPlace and GoToZone quests should almost always use autocomplete
2. **Region vs Zone**: Use rect-based quests for specific areas, zone-based for entire zones
3. **Performance**: Use region enter events for immediate response instead of periodic checks when possible
4. **Clear Objectives**: Make quest descriptions clear about where to go
5. **Rewards**: Exploration quests typically give good XP and reputation rewards

---

## Troubleshooting

**Quest doesn't complete when entering rect:**
- Verify rect exists in map: `gg_rct_YourRectName`
- Check autocomplete is enabled
- Ensure you're checking requirement completion
- Verify hero is actually in rect with debug message

**Zone quest doesn't work:**
- Verify ZoneEvent system is initialized
- Check zone ID matches ZonesCore configuration
- Test with `ZoneEvent_GetCurrentZone()` to verify zone detection

**Quest requires return even with autocomplete:**
- Make sure you're using `SetRequirementCompleted` not just changing state
- Autocomplete only works when ALL requirements are complete
- Check quest isn't adding return requirement (hasReturnReq flag)

---

## Related Systems

- **ZonesCore.j** - Zone definitions and configuration
- **ZoneEvent.j** - Zone enter/leave event handling
- **QuestGiver.j** - Quest acceptance and turn-in
- **QuestMaster.j** - Core quest system

---

**Version**: 1.0  
**Author**: Valdemar  
**Date**: February 2026
