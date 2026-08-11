/**
    EmberpeakDragonfire

    Author: Valdemar
    Version: 1.1.0

    Description:
    Compatibility facade for encounter code that still uses the original
    EmberpeakDragonfire API. World/Dragons/EmberpeakDragons.j owns the actual
    dragons, wandering, sounds, flame strikes, and arena targeting state.

    Credits:
    - World/_oldGUI/Dragons/Emberpeak Dragonfire triggers

    How to install:
    Import after EmberpeakDragons. New code should call EmberpeakDragons
    directly; this facade may remain for older callers.

    API:
    - EmberpeakDragonfire_SetBoss(whichUnit)
    - EmberpeakDragonfire_SetMode(mode)

**/
library EmberpeakDragonfire requires EmberpeakDragons
    globals
        constant integer EMBERPEAK_DRAGONFIRE_IDLE = 0
        constant integer EMBERPEAK_DRAGONFIRE_PLAYERS = 1
        constant integer EMBERPEAK_DRAGONFIRE_COLOSSUS = 2
    endglobals

    public function SetBoss takes unit whichUnit returns nothing
        call EmberpeakDragons_SetColossus(whichUnit)
    endfunction

    public function SetMode takes integer mode returns nothing
        call EmberpeakDragons_SetArenaMode(mode)
    endfunction
endlibrary
