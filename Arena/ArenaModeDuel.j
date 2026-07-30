/**
    ArenaModeDuel

    Author: Valdemar
    Version:

    Description:
    Duel arena mode registration scaffold. The arena core can already isolate
    and restore selected participants; this mode still needs opponent selection
    and temporary control rules before it can run real duels.

    Credits:
    - Arena/ArenaPlan.md

    How to install:
    Import after Arena.j.

    API:
    Automatic Arena mode registration only.

**/
library ArenaModeDuel initializer Init requires Arena
    private function ADUL_OnStart takes nothing returns nothing
        call Arena_Fail("Duel requires opponent selection before it can be started.")
    endfunction

    private function Init takes nothing returns nothing
        call Arena_RegisterMode(ARENA_MODE_DUEL, "Duel", function ADUL_OnStart, null, null, null)
    endfunction
endlibrary
