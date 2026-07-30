/**
    ArenaModeTeamDeathmatch

    Author: Valdemar
    Version:

    Description:
    Team Deathmatch arena mode for Arena.j. The selected party fights one
    arena-owned opponent team. The mode succeeds when every opponent is dead
    and fails through Arena.j when the selected player heroes are defeated.

    Credits:
    - Arena/ArenaPlan.md

    How to install:
    Import after Arena.j.

    API:
    Automatic Arena mode registration only.

**/
library ArenaModeTeamDeathmatch initializer Init requires Arena
    globals
        private constant real ATDM_THINK_INTERVAL = 2.50

        private timer ATDM_ThinkTimer = null
        private integer ATDM_SessionId = 0
        private integer ATDM_Difficulty = ARENA_DIFFICULTY_EASY
        private integer ATDM_FamilyId = 1
    endglobals

    private function ATDM_IsCurrentSession takes nothing returns boolean
        return Arena_IsActive() and not Arena_IsEnding() and Arena_GetActiveModeId() == ARENA_MODE_TEAM_DM and Arena_GetSessionId() == ATDM_SessionId
    endfunction

    private function ATDM_GetFamilyId takes nothing returns integer
        local unit master = Arena_GetActiveMaster()
        local integer masterType = 0

        if master != null then
            set masterType = GetUnitTypeId(master)
        endif

        set master = null

        if masterType == ARENA_MASTER_BONECRUSHER then
            return 2
        elseif masterType == ARENA_MASTER_SATYR then
            return 3
        elseif Arena_GetActiveArenaId() == ARENA_ID_COLISEUM_OF_AGES then
            return GetRandomInt(3, 4)
        endif

        return GetRandomInt(1, 2)
    endfunction

    private function ATDM_GetNormal takes integer familyId returns integer
        if familyId == 2 then
            return 'n65X'
        elseif familyId == 3 then
            return 'n61L'
        elseif familyId == 4 then
            return 'h604'
        endif
        return 'o62P'
    endfunction

    private function ATDM_GetSupport takes integer familyId returns integer
        if familyId == 2 then
            return 'n01O'
        elseif familyId == 3 then
            return 'n633'
        elseif familyId == 4 then
            return 'O606'
        endif
        return 'o62Q'
    endfunction

    private function ATDM_GetHeavy takes integer familyId returns integer
        if familyId == 2 then
            return 'n60W'
        elseif familyId == 3 then
            return 'O60Z'
        elseif familyId == 4 then
            return 'O632'
        endif
        return 'o003'
    endfunction

    private function ATDM_GetChampion takes integer familyId returns integer
        if familyId == 2 then
            return 'n60M'
        elseif familyId == 3 then
            return 'O610'
        elseif familyId == 4 then
            return 'H601'
        endif
        return 'o62V'
    endfunction

    private function ATDM_GetFamilyName takes integer familyId returns string
        if familyId == 2 then
            return "Bonecrusher Clan"
        elseif familyId == 3 then
            return "Fel challengers"
        elseif familyId == 4 then
            return "Riverbane challengers"
        endif
        return "Horde challengers"
    endfunction

    private function ATDM_GetReward takes nothing returns integer
        if ATDM_Difficulty == ARENA_DIFFICULTY_HARD then
            return 65
        elseif ATDM_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            return 45
        endif
        return 28
    endfunction

    private function ATDM_GetBaseUnitCount takes nothing returns integer
        local integer count = 3 + Arena_GetParticipantCount()

        if ATDM_Difficulty == ARENA_DIFFICULTY_HARD then
            set count = count + 4
        elseif ATDM_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            set count = count + 2
        endif
        if Arena_GetActiveArenaId() == ARENA_ID_COLISEUM_OF_AGES then
            set count = count + 2
        endif

        return count
    endfunction

    private function ATDM_SpawnOne takes integer unitTypeId returns nothing
        local rect spawnRect = Arena_GetActiveGate2Rect()
        local unit spawned
        local real x
        local real y

        if spawnRect == null then
            set spawnRect = Arena_GetActiveAreaRect()
        endif
        if spawnRect == null then
            set spawned = null
            return
        endif

        set x = Arena_GetRectRandomX(spawnRect)
        set y = Arena_GetRectRandomY(spawnRect)
        set spawned = Arena_SpawnArenaUnit(unitTypeId, Player(PLAYER_NEUTRAL_AGGRESSIVE), x, y, GetRandomReal(0.00, 360.00))
        if spawned != null then
            call IssuePointOrder(spawned, "attack", Arena_GetArenaCenterX(Arena_GetActiveArenaId()), Arena_GetArenaCenterY(Arena_GetActiveArenaId()))
        endif

        set spawnRect = null
        set spawned = null
    endfunction

    private function ATDM_SpawnMany takes integer unitTypeId, integer count returns nothing
        local integer index = 0

        loop
            exitwhen index >= count
            call ATDM_SpawnOne(unitTypeId)
            set index = index + 1
        endloop
    endfunction

    private function ATDM_SpawnTeam takes nothing returns nothing
        local integer count = ATDM_GetBaseUnitCount()
        local integer supportCount = count / 4
        local integer heavyCount = 0
        local integer normalCount

        if ATDM_Difficulty == ARENA_DIFFICULTY_HARD then
            set heavyCount = 2
        elseif ATDM_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            set heavyCount = 1
        endif

        set normalCount = count - supportCount - heavyCount
        if normalCount < 1 then
            set normalCount = 1
        endif

        call ATDM_SpawnMany(ATDM_GetNormal(ATDM_FamilyId), normalCount)
        call ATDM_SpawnMany(ATDM_GetSupport(ATDM_FamilyId), supportCount)
        call ATDM_SpawnMany(ATDM_GetHeavy(ATDM_FamilyId), heavyCount)

        if ATDM_Difficulty == ARENA_DIFFICULTY_HARD then
            call ATDM_SpawnOne(ATDM_GetChampion(ATDM_FamilyId))
        endif
    endfunction

    private function ATDM_CheckVictory takes nothing returns nothing
        if ATDM_IsCurrentSession() and Arena_GetArenaUnitCount() <= 0 then
            call PauseTimer(ATDM_ThinkTimer)
            call Arena_AwardMarks(ATDM_GetReward())
            call Arena_End(true)
        endif
    endfunction

    private function ATDM_ThinkTick takes nothing returns nothing
        if not ATDM_IsCurrentSession() then
            call PauseTimer(ATDM_ThinkTimer)
            return
        endif

        call Arena_OrderArenaUnitsToParticipants()
    endfunction

    private function ATDM_OnArenaUnitDeath takes nothing returns nothing
        call ATDM_CheckVictory()
    endfunction

    private function ATDM_OnParticipantDeath takes nothing returns nothing
        if ATDM_IsCurrentSession() and Arena_EventParticipant != null and (Arena_EventParticipant == udg_Nazgrek or Arena_EventParticipant == udg_Zulkis) then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + GetHeroProperName(Arena_EventParticipant) + " has fallen in Team Deathmatch.|r")
        endif
    endfunction

    private function ATDM_OnStart takes nothing returns nothing
        set ATDM_SessionId = Arena_GetSessionId()
        set ATDM_Difficulty = Arena_GetActiveDifficulty()
        set ATDM_FamilyId = ATDM_GetFamilyId()

        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00Team Deathmatch: " + ATDM_GetFamilyName(ATDM_FamilyId) + "|r")
        call ATDM_SpawnTeam()

        if Arena_GetArenaUnitCount() <= 0 then
            call Arena_Fail("Team Deathmatch spawn failed. Check unit rawcodes.")
            return
        endif

        call Arena_OrderArenaUnitsToParticipants()
        call TimerStart(ATDM_ThinkTimer, ATDM_THINK_INTERVAL, true, function ATDM_ThinkTick)
    endfunction

    private function ATDM_OnStop takes nothing returns nothing
        call PauseTimer(ATDM_ThinkTimer)
        set ATDM_SessionId = 0
        set ATDM_Difficulty = ARENA_DIFFICULTY_EASY
        set ATDM_FamilyId = 1
    endfunction

    private function Init takes nothing returns nothing
        set ATDM_ThinkTimer = CreateTimer()

        call Arena_RegisterMode(ARENA_MODE_TEAM_DM, "Team Deathmatch", function ATDM_OnStart, function ATDM_OnStop, function ATDM_OnArenaUnitDeath, function ATDM_OnParticipantDeath)
    endfunction
endlibrary
