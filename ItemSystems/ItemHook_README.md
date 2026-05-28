# ItemHook - JASS Edition

A JASS system for detecting when items are created or destroyed in Warcraft 3, based on [Tasyen's Lua ItemHook](https://www.hiveworkshop.com/threads/itemhook-create-remove.318849/).

## Features

- **Item Creation Detection**: Detects items created via:
  - Code (`CreateItem`, `UnitAddItemById`, etc.)
  - Preplaced items (map editor)
  - Creep drops
  - Item pools
  - Shop purchases
  
- **Item Destruction Detection**: Detects items destroyed via:
  - Sold to shops
  - Consumed (charges reach 0)
  - Direct destruction (`RemoveItem`)
  - Item death

## Installation

1. Copy `ItemHook.j` into your map's script
2. Call `ItemHook_Init()` in your map initialization trigger
3. Register your item callbacks

## Usage

### Basic Example

```jass
// Your callback function for when an item is created
function OnMyItemCreated takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    local unit hero = ItemHookGetEventHero()
    
    if hero != null then
        call DisplayTextToPlayer(GetOwningPlayer(hero), 0, 0, "You got the item!")
    endif
    
    set whichItem = null
    set hero = null
endfunction

// Your callback function for when an item is destroyed
function OnMyItemDestroyed takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    
    call DisplayTextToForce(GetPlayersAll(), "Item was destroyed!")
    
    set whichItem = null
endfunction

// Register in your initialization
function InitTrig_MapInit takes nothing returns nothing
    call ItemHook_Init()
    
    // Register callbacks for item type 'I000'
    call ItemHookRegisterCreate('I000', "OnMyItemCreated")
    call ItemHookRegisterDestroy('I000', "OnMyItemDestroyed")
endfunction
```

### Event Response Functions

Use these functions inside your callback to get event data:

- `ItemHookGetEventItem()` - Returns the item that was created/destroyed
- `ItemHookGetEventSource()` - Returns the shop unit that sold the item (null otherwise)
- `ItemHookGetEventHero()` - Returns the hero the item was created for (null otherwise)

### Creating Items

To ensure items are tracked, use the ItemHook wrapper functions:

```jass
// Instead of: CreateItem('I000', x, y)
set myItem = ItemHook_CreateItem('I000', x, y)

// Instead of: UnitAddItemById(hero, 'I000')
set myItem = ItemHook_UnitAddItemById(hero, 'I000')

// Instead of: UnitAddItemToSlotById(hero, 'I000', slot)
call ItemHook_UnitAddItemToSlotById(hero, 'I000', slot)

// Instead of: PlaceRandomItem(pool, x, y)
set myItem = ItemHook_PlaceRandomItem(pool, x, y)
```

### Advanced Example

```jass
globals
    private integer TomeCount = 0
endglobals

function OnTomeOfExperienceCreated takes nothing returns nothing
    local item tome = ItemHookGetEventItem()
    local unit hero = ItemHookGetEventHero()
    local unit source = ItemHookGetEventSource()
    
    set TomeCount = TomeCount + 1
    
    if source != null then
        call DisplayTextToForce(GetPlayersAll(), "Tome bought from " + GetUnitName(source))
    endif
    
    if hero != null then
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIlm\\AIlmTarget.mdl", hero, "origin"))
    endif
    
    set tome = null
    set hero = null
    set source = null
endfunction

function OnTomeOfExperienceDestroyed takes nothing returns nothing
    local item tome = ItemHookGetEventItem()
    
    set TomeCount = TomeCount - 1
    call DisplayTextToForce(GetPlayersAll(), "Tome used! Remaining: " + I2S(TomeCount))
    
    set tome = null
endfunction

function InitTomes takes nothing returns nothing
    call ItemHook_Init()
    call ItemHookRegisterCreate('tome', "OnTomeOfExperienceCreated")
    call ItemHookRegisterDestroy('tome', "OnTomeOfExperienceDestroyed")
endfunction
```

## Important Notes

### JASS Limitations

Unlike the Lua version, JASS cannot override native functions. This means:

1. **You must use the wrapper functions** (`ItemHook_CreateItem`, etc.) instead of natives
2. **GUI-created items won't be detected** unless you convert to custom script and use wrappers
3. **Preplaced items** are detected automatically (no action needed)
4. **Shop purchases** are detected automatically (no action needed)
5. **Creep drops** should use wrappers if you want detection

### Function Name as String

JASS requires passing function names as strings to `ExecuteFunc`. This means:

```jass
// Correct:
call ItemHookRegisterCreate('I000', "MyFunction")

// Incorrect:
call ItemHookRegisterCreate('I000', function MyFunction)
```

### Not Detected

Items created by `RestoreUnit` are **not detected** by this system. This is a rare use case (mainly campaigns).

## API Reference

### Initialization

```jass
function ItemHook_Init takes nothing returns nothing
```
Call this once during map initialization.

### Registration

```jass
function ItemHookRegisterCreate takes integer itemCode, string funcName returns nothing
```
Register a callback for when an item type is created.

```jass
function ItemHookRegisterDestroy takes integer itemCode, string funcName returns nothing
```
Register a callback for when an item type is destroyed.

### Event Response

```jass
function ItemHookGetEventItem takes nothing returns item
```
Returns the item in the current event.

```jass
function ItemHookGetEventSource takes nothing returns unit
```
Returns the shop unit that sold the item (null if not from shop).

```jass
function ItemHookGetEventHero takes nothing returns unit
```
Returns the hero the item was created for (null if not applicable).

### Wrapper Functions

```jass
function ItemHook_CreateItem takes integer itemid, real x, real y returns item
function ItemHook_UnitAddItemToSlotById takes unit whichUnit, integer itemId, integer itemSlot returns boolean
function ItemHook_UnitAddItemById takes unit whichUnit, integer itemId returns item
function ItemHook_PlaceRandomItem takes itempool whichItemPool, real x, real y returns item
```

Use these instead of the native functions to ensure items are tracked.

## Credits

- Original Lua version by Tasyen
- JASS port by GitHub Copilot
- Based on discussion at [Hiveworkshop](https://www.hiveworkshop.com/threads/itemhook-create-remove.318849/)

## License

Free to use and modify for your Warcraft 3 maps.
