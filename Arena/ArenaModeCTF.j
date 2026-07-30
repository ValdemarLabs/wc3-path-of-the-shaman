/**
    ArenaModeCTF

    Author: Valdemar
    Version:

    Description:
    Capture the Flag arena mode registration scaffold. Arena.j exposes the
    flag rect APIs this mode will need, but the carrier AI, score target, and
    ten-minute match timer are intentionally left for the dedicated CTF pass.

    Credits:
    - Arena/ArenaPlan.md

    How to install:
    Import after Arena.j.

    API:
    Automatic Arena mode registration only.

**/
library ArenaModeCTF initializer Init requires Arena
    private function ACTF_OnStart takes nothing returns nothing
        call Arena_Fail("Capture the Flag requires flag-carrier AI and score setup before it can be started.")
    endfunction

    private function Init takes nothing returns nothing
        call Arena_RegisterMode(ARENA_MODE_CTF, "Capture the Flag", function ACTF_OnStart, null, null, null)
    endfunction
endlibrary
