/**
    ElementalEssenceDrops

    Author: Valdemar
    Version:

    Description:
    Registers each elemental essence only for its matching hostile elemental.

    Credits:

    How to install:
    Import after ItemLootSystem and before or alongside generated specific-drop
    definitions.

    API:
    No public API. Drops register automatically during initialization.

**/
library ElementalEssenceDrops initializer Init requires ItemLootSystem

globals
    private constant integer ESSENCE_DROP_CHANCE = 5500
endglobals

private function Init takes nothing returns nothing
    call RegisterSpecificDrop('h60D', 'I6C7', ESSENCE_DROP_CHANCE, false, 100) // Air
    call RegisterSpecificDrop('n615', 'I6C8', ESSENCE_DROP_CHANCE, false, 100) // Earth
    call RegisterSpecificDrop('n616', 'I6C5', ESSENCE_DROP_CHANCE, false, 100) // Fire
    call RegisterSpecificDrop('n00O', 'I6C6', ESSENCE_DROP_CHANCE, false, 100) // Water / Sea
    call RegisterSpecificDrop('h60C', 'I6C6', ESSENCE_DROP_CHANCE, false, 100) // Water summon data
endfunction

endlibrary
