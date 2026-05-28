# ItemHook - GUI Trigger Guide

This guide shows how to use ItemHook with GUI triggers (World Editor's visual trigger editor).

## Setup

**1. Create Global Variables:**

In the Variable Editor, create these two variables:
- Name: `ItemHook_CreateEvent`, Type: **Real**, Initial Value: `0.00`
- Name: `ItemHook_DestroyEvent`, Type: **Real**, Initial Value: `0.00`

**2. Add the script:**

Add `ItemHook.j` to your map (via Trigger Editor → Custom Script)

**3. Initialize:**

Create an initialization trigger to call `ItemHook_Init()`

## Method 1: Using Variable Events (Recommended)

This is the easiest way to respond to item events in GUI.

### Step-by-Step:

**1. Create an initialization trigger:**

```
Map Initialization
Events
    - Map initialization
Actions
    - Custom script: call ItemHook_Init()
```

**2. Create your item detection trigger:**

```
Item Created Event
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Conditions
    - Custom script: GetItemTypeId(ItemHookGetEventItem()) == 'rin1'
Actions
    - Game - Display to (All players) the text: "Ring of Protection was created!"
```

Alternatively, use a variable to check the item:
```
Item Created Event
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - (Item-type of TempItem) Equal to Ring of Protection +1
        - Then - Actions
            - Game - Display to (All players) the text: "Ring of Protection was created!"
        - Else - Actions
```

**3. For item destruction:**

```
Item Destroyed Event
Events
    - Game - ItemHook_DestroyEvent becomes Equal to 1.00
Conditions
    - Custom script: GetItemTypeId(ItemHookGetEventItem()) == 'phea'
Actions
    - Game - Display to (All players) the text: "Health Potion was destroyed!"
```

## Method 2: Using Event Response Functions

You can check which item was affected using these custom functions in conditions:

### Available Functions for GUI:

Add these as "Custom script" in conditions or save to variables:

```
Custom script: set udg_MyItem = ItemHookGetEventItem()
Custom script: set udg_MyUnit = ItemHookGetEventHero()
Custom script: set udg_MyShop = ItemHookGetEventSource()
Custom script: set udg_MyItemType = ItemHookGetEventItemType()
```

### Complete Example:

**Variables needed:**
- `ItemHook_CreateEvent` (type: Real) - **Required!**
- `ItemHook_DestroyEvent` (type: Real) - **Required!**
- `TempItem` (type: Item)
- `TempHero` (type: Unit)
- `TempItemType` (type: Integer)

**Trigger:**
```
Item Hook Response
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - Custom script: set udg_TempHero = ItemHookGetEventHero()
    - Custom script: set udg_TempItemType = ItemHookGetEventItemType()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - Custom script: udg_TempItemType == 'I000'
        - Then - Actions
            - Game - Display to (All players) the text: "Special item created!"
            - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                - If - Conditions
                    - TempHero Not equal to No unit
                - Then - Actions
                    - Special Effect - Create a special effect attached to the origin of TempHero using Abilities\Spells\Items\AIlm\AIlmTarget.mdl
                    - Special Effect - Destroy (Last created special effect)
                - Else - Actions
```

## Method 3: Using Custom Script (Advanced)

For more complex logic, convert your trigger to custom script.

**Example GUI Trigger:**
```
My Item Hook
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: call MyItemHookFunction()
```

**Then in custom script section:**
```jass
function MyItemHookFunction takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    local unit hero = ItemHookGetEventHero()
    local unit shop = ItemHookGetEventSource()
    local integer itemType = ItemHookGetEventItemType()
    
    if itemType == 'I000' then
        // Do something with the item
        call DisplayTextToForce(GetPlayersAll(), "My custom item was created!")
        
        if hero != null then
            call SetUnitLifePercentBJ(hero, 100)
        endif
    endif
    
    set whichItem = null
    set hero = null
    set shop = null
endfunction
```

## Practical Examples

### Example 1: Track Tome of Experience

```
Tome Tracking
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - (Item-type of TempItem) Equal to Tome of Experience
        - Then - Actions
            - Game - Display to (All players) the text: "A Tome of Experience has appeared!"
            - Quest - Display to (All players) the Quest Update message: New tome available!
        - Else - Actions
```

### Example 2: Grant Bonus When Item Acquired

```
Legendary Item Bonus
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - Custom script: set udg_TempHero = ItemHookGetEventHero()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - (Item-type of TempItem) Equal to Crown of Kings +5
            - TempHero Not equal to No unit
        - Then - Actions
            - Unit - Set life of TempHero to 100.00%
            - Unit - Set mana of TempHero to 100.00%
            - Special Effect - Create a special effect attached to the origin of TempHero using Abilities\Spells\Human\Resurrect\ResurrectTarget.mdl
            - Special Effect - Destroy (Last created special effect)
            - Game - Display to (All players) the text: ((Name of (Owner of TempHero)) + " has obtained the Crown of Kings!")
        - Else - Actions
```

### Example 3: Count Items Destroyed

**Variables:**
- `ItemDestroyCount` (type: Integer, initial value: 0)
- `TempItem` (type: Item)

```
Count Destroyed Potions
Events
    - Game - ItemHook_DestroyEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - (Item-type of TempItem) Equal to Health Potion
        - Then - Actions
            - Set ItemDestroyCount = (ItemDestroyCount + 1)
            - Game - Display to (All players) the text: ("Potions used: " + (String(ItemDestroyCount)))
        - Else - Actions
```

### Example 4: Prevent Item Creation (Advanced)

```
Block Cursed Item
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - If (All Conditions are True) then do (Then Actions) else do (Else Actions)
        - If - Conditions
            - (Item-type of TempItem) Equal to Cursed Ring
        - Then - Actions
            - Item - Remove TempItem
            - Game - Display to (All players) the text: "The cursed ring vanishes!"
        - Else - Actions
```

## Important Notes for GUI

1. **MUST create the event variables first:**
   - `ItemHook_CreateEvent` (Real)
   - `ItemHook_DestroyEvent` (Real)
2. **Always call `ItemHook_Init()` first** in map initialization
3. **Use the event:** `Game - ItemHook_CreateEvent becomes Equal to 1.00`
4. **Item creation in GUI** won't be detected unless you use wrapper functions
5. **Shop purchases ARE detected automatically** ✓
6. **Preplaced items ARE detected automatically** ✓

## Creating Items with Detection in GUI

To ensure GUI-created items are detected, use custom script:

Instead of:
```
Item - Create Ring of Protection +1 at (Center of (Playable map area))
```

Use:
```
Custom script: set udg_MyItem = ItemHook_CreateItem('rin1', 0, 0)
```

Or for adding to hero:
```
Custom script: set udg_MyItem = ItemHook_UnitAddItemById(udg_MyHero, 'rin1')
```

## Debugging Tips

Add this debug trigger to see all item events:

```
Debug - Item Create
Events
    - Game - ItemHook_CreateEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - Game - Display to (All players) the text: ("Item created: " + (Name of TempItem))

Debug - Item Destroy
Events
    - Game - ItemHook_DestroyEvent becomes Equal to 1.00
Actions
    - Custom script: set udg_TempItem = ItemHookGetEventItem()
    - Game - Display to (All players) the text: ("Item destroyed: " + (Name of TempItem))
```

## Common Issues

**Q: The event doesn't fire at all!**  
A: Did you create the global variables `ItemHook_CreateEvent` and `ItemHook_DestroyEvent` (Real type) in the Variable Editor?

**Q: My GUI-created items aren't detected!**  
A: Convert the action to custom script and use `ItemHook_CreateItem` instead.

**Q: The event doesn't fire for some items!**  
A: Make sure you called `ItemHook_Init()` in map initialization.

**Q: How do I check item type in GUI?**  
A: Save to variable first: `Custom script: set udg_TempItem = ItemHookGetEventItem()`, then use: `(Item-type of TempItem) Equal to YourItemType`

**Q: Can I use this with existing item systems?**  
A: Yes! ItemHook is passive and won't interfere with other systems.
