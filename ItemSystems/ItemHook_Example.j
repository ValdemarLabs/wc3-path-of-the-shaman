//===========================================================================
// ItemHook Usage Example
//===========================================================================
// This file demonstrates how to use the ItemHook system
//===========================================================================

//===========================================================================
// Example: Track when a specific item is created
//===========================================================================
function Example_OnHealthPotionCreated takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    local unit source = ItemHookGetEventSource()
    local unit hero = ItemHookGetEventHero()
    
    call DisplayTextToForce(GetPlayersAll(), "Health Potion created!")
    
    if hero != null then
        call DisplayTextToForce(GetPlayersAll(), "Created for: " + GetUnitName(hero))
    endif
    
    if source != null then
        call DisplayTextToForce(GetPlayersAll(), "Sold by: " + GetUnitName(source))
    endif
    
    set whichItem = null
    set source = null
    set hero = null
endfunction

//===========================================================================
// Example: Track when a specific item is destroyed
//===========================================================================
function Example_OnHealthPotionDestroyed takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    
    call DisplayTextToForce(GetPlayersAll(), "Health Potion was destroyed!")
    
    set whichItem = null
endfunction

//===========================================================================
// Example: Track Tome of Experience
//===========================================================================
function Example_OnTomeCreated takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    call DisplayTextToForce(GetPlayersAll(), "Tome of Experience created!")
    set whichItem = null
endfunction

function Example_OnTomeDestroyed takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    call DisplayTextToForce(GetPlayersAll(), "Tome of Experience was used/destroyed!")
    set whichItem = null
endfunction

//===========================================================================
// Example: Item creation counter
//===========================================================================
globals
    private integer ItemCreationCount = 0
endglobals

function Example_CountItemCreations takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    set ItemCreationCount = ItemCreationCount + 1
    call DisplayTextToForce(GetPlayersAll(), "Total Rings of Protection created: " + I2S(ItemCreationCount))
    set whichItem = null
endfunction

//===========================================================================
// Example: Custom item behavior on pickup
//===========================================================================
function Example_OnSpecialSwordCreated takes nothing returns nothing
    local item whichItem = ItemHookGetEventItem()
    local unit hero = ItemHookGetEventHero()
    
    // Add special effect when item is created for a hero
    if hero != null then
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", hero, "origin"))
        call SetUnitLifePercentBJ(hero, 100)
        call DisplayTextToPlayer(GetOwningPlayer(hero), 0, 0, "|cffffcc00You obtained a Legendary Sword!|r")
    endif
    
    set whichItem = null
    set hero = null
endfunction

//===========================================================================
// Initialization - Register all your item hooks here
//===========================================================================
function InitItemHookExamples takes nothing returns nothing
    // Health Potion (example - replace with actual item code)
    call ItemHookRegisterCreate('phea', "Example_OnHealthPotionCreated")
    call ItemHookRegisterDestroy('phea', "Example_OnHealthPotionDestroyed")
    
    // Tome of Experience
    call ItemHookRegisterCreate('tome', "Example_OnTomeCreated")
    call ItemHookRegisterDestroy('tome', "Example_OnTomeDestroyed")
    
    // Ring of Protection
    call ItemHookRegisterCreate('rin1', "Example_CountItemCreations")
    
    // Custom item (replace 'XXXX' with your item code)
    // call ItemHookRegisterCreate('XXXX', "Example_OnSpecialSwordCreated")
    
    call DisplayTextToForce(GetPlayersAll(), "ItemHook Examples initialized!")
endfunction

//===========================================================================
// Usage with the ItemHook wrapper functions
//===========================================================================
function TestItemCreation takes nothing returns nothing
    local item testItem
    
    // Use ItemHook wrappers instead of native functions
    set testItem = ItemHook_CreateItem('phea', 0, 0)
    
    // This will trigger the create event!
    
    set testItem = null
endfunction
