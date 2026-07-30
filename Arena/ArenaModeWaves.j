/**
    ArenaModeWaves

    Author: Valdemar
    Version:

    Description:
    Waves arena mode for Arena.j. A session waits before the first wave, then
    spawns one themed creep family at a time. Cleared waves revive the selected
    party at the starting gate, award arena marks, and schedule the next wave.

    Credits:
    - Arena/ArenaPlan.md

    How to install:
    Import after Arena.j.

    API:
    Automatic Arena mode registration only.

**/
library ArenaModeWaves initializer Init requires Arena
    globals
        private constant real AWAV_FIRST_WAVE_DELAY = 60.00
        private constant real AWAV_NEXT_WAVE_DELAY = 60.00
        private constant real AWAV_THINK_INTERVAL = 3.00
        private constant real AWAV_POWERUP_INTERVAL = 8.00
        private constant integer AWAV_MAX_TRACKED_POWERUPS = 32
        private constant integer AWAV_POWERUP_HEALTH = 'rhe2'
        private constant integer AWAV_POWERUP_MANA = 'rman'

        private timer AWAV_WaveTimer = null
        private timer AWAV_ThinkTimer = null
        private timer AWAV_PowerupTimer = null
        private integer AWAV_SessionId = 0
        private integer AWAV_CurrentWave = 0
        private integer AWAV_MaxWave = 0
        private integer AWAV_Difficulty = ARENA_DIFFICULTY_EASY
        private boolean AWAV_WaveActive = false
        private item array AWAV_Powerups
        private integer AWAV_PowerupCount = 0
    endglobals

    private function AWAV_IsCurrentSession takes nothing returns boolean
        return Arena_IsActive() and not Arena_IsEnding() and Arena_GetActiveModeId() == ARENA_MODE_WAVES and Arena_GetSessionId() == AWAV_SessionId
    endfunction

    private function AWAV_GetMaxWave takes integer difficulty returns integer
        if difficulty == ARENA_DIFFICULTY_HARD then
            return 5
        elseif difficulty == ARENA_DIFFICULTY_MEDIUM then
            return 4
        endif
        return 3
    endfunction

    private function AWAV_GetWaveReward takes nothing returns integer
        local integer base = 6 + AWAV_CurrentWave * 3

        if AWAV_Difficulty == ARENA_DIFFICULTY_HARD then
            set base = base + 8
        elseif AWAV_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            set base = base + 4
        endif

        return base
    endfunction

    private function AWAV_GetCompletionReward takes nothing returns integer
        if AWAV_Difficulty == ARENA_DIFFICULTY_HARD then
            return 50
        elseif AWAV_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            return 35
        endif
        return 20
    endfunction

    private function AWAV_GetBaseUnitCount takes nothing returns integer
        local integer count = 2 + AWAV_CurrentWave

        if AWAV_Difficulty == ARENA_DIFFICULTY_HARD then
            set count = count + 4
        elseif AWAV_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            set count = count + 2
        endif
        if Arena_GetActiveArenaId() == ARENA_ID_COLISEUM_OF_AGES then
            set count = count + 1
        endif

        return count
    endfunction

    private function AWAV_GetMaxPowerups takes nothing returns integer
        local integer count = 1 + AWAV_CurrentWave / 2

        if AWAV_Difficulty == ARENA_DIFFICULTY_HARD then
            set count = count + 2
        elseif AWAV_Difficulty == ARENA_DIFFICULTY_MEDIUM then
            set count = count + 1
        endif
        if count > 7 then
            set count = 7
        endif

        return count
    endfunction

    private function AWAV_GetFamilyNormal takes integer familyId returns integer
        if familyId == 2 then
            return 'n65X'
        elseif familyId == 3 then
            return 'n027'
        elseif familyId == 4 then
            return 'n61Q'
        endif
        return 'n60G'
    endfunction

    private function AWAV_GetFamilySupport takes integer familyId returns integer
        if familyId == 2 then
            return 'n01O'
        elseif familyId == 3 then
            return 'n002'
        elseif familyId == 4 then
            return 'n017'
        endif
        return 'n60E'
    endfunction

    private function AWAV_GetFamilyHeavy takes integer familyId returns integer
        if familyId == 2 then
            return 'n60W'
        elseif familyId == 3 then
            return 'n028'
        elseif familyId == 4 then
            return 'n018'
        endif
        return 'n60H'
    endfunction

    private function AWAV_GetFamilyBoss takes integer familyId returns integer
        if familyId == 2 then
            return 'n60M'
        elseif familyId == 3 then
            return 'n62C'
        elseif familyId == 4 then
            return 'n620'
        endif
        return 'n60J'
    endfunction

    private function AWAV_GetFamilyName takes integer familyId returns string
        if familyId == 2 then
            return "Ogres"
        elseif familyId == 3 then
            return "Mana Beasts"
        elseif familyId == 4 then
            return "Wild Hunters"
        endif
        return "Gnolls"
    endfunction

    private function AWAV_ClearPowerups takes boolean removeItems returns nothing
        local integer index = 0
        local integer writeIndex = 0
        local item whichItem

        loop
            exitwhen index >= AWAV_PowerupCount
            set whichItem = AWAV_Powerups[index]
            if whichItem != null and GetItemTypeId(whichItem) != 0 then
                if removeItems then
                    call RemoveItem(whichItem)
                    set AWAV_Powerups[index] = null
                else
                    set AWAV_Powerups[writeIndex] = whichItem
                    set writeIndex = writeIndex + 1
                endif
            else
                set AWAV_Powerups[index] = null
            endif
            set index = index + 1
        endloop

        if removeItems then
            set AWAV_PowerupCount = 0
        else
            loop
                exitwhen writeIndex >= AWAV_PowerupCount
                set AWAV_Powerups[writeIndex] = null
                set writeIndex = writeIndex + 1
            endloop
            set AWAV_PowerupCount = writeIndex
        endif

        set whichItem = null
    endfunction

    private function AWAV_SpawnPowerup takes nothing returns nothing
        local rect arenaRect
        local integer itemTypeId = AWAV_POWERUP_HEALTH
        local item whichItem

        call AWAV_ClearPowerups(false)
        if AWAV_PowerupCount >= AWAV_GetMaxPowerups() or AWAV_PowerupCount >= AWAV_MAX_TRACKED_POWERUPS then
            return
        endif

        set arenaRect = Arena_GetActiveAreaRect()
        if arenaRect == null then
            set arenaRect = null
            return
        endif

        if GetRandomInt(1, 100) <= 40 then
            set itemTypeId = AWAV_POWERUP_MANA
        endif

        set whichItem = CreateItem(itemTypeId, Arena_GetRectRandomX(arenaRect), Arena_GetRectRandomY(arenaRect))
        if whichItem != null then
            set AWAV_Powerups[AWAV_PowerupCount] = whichItem
            set AWAV_PowerupCount = AWAV_PowerupCount + 1
        endif

        set arenaRect = null
        set whichItem = null
    endfunction

    private function AWAV_PowerupTick takes nothing returns nothing
        if not AWAV_IsCurrentSession() or not AWAV_WaveActive then
            call PauseTimer(AWAV_PowerupTimer)
            return
        endif

        if GetRandomInt(1, 100) <= 55 then
            call AWAV_SpawnPowerup()
        endif
    endfunction

    private function AWAV_ThinkTick takes nothing returns nothing
        if not AWAV_IsCurrentSession() or not AWAV_WaveActive then
            call PauseTimer(AWAV_ThinkTimer)
            return
        endif

        call Arena_OrderArenaUnitsToParticipants()
    endfunction

    private function AWAV_SpawnOne takes integer unitTypeId returns nothing
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

    private function AWAV_SpawnMany takes integer unitTypeId, integer count returns nothing
        local integer index = 0

        loop
            exitwhen index >= count
            call AWAV_SpawnOne(unitTypeId)
            set index = index + 1
        endloop
    endfunction

    private function AWAV_SpawnWave takes nothing returns nothing
        local integer familyId = GetRandomInt(1, 4)
        local integer count = AWAV_GetBaseUnitCount()
        local integer supportCount = count / 4
        local integer heavyCount = AWAV_CurrentWave / 3
        local integer normalCount = count - supportCount - heavyCount

        if supportCount < 1 and AWAV_CurrentWave > 1 then
            set supportCount = 1
            set normalCount = normalCount - 1
        endif
        if heavyCount < 1 and AWAV_CurrentWave == AWAV_MaxWave then
            set heavyCount = 1
            set normalCount = normalCount - 1
        endif
        if normalCount < 1 then
            set normalCount = 1
        endif

        set AWAV_WaveActive = true
        call AWAV_ClearPowerups(true)
        call AWAV_SpawnMany(AWAV_GetFamilyNormal(familyId), normalCount)
        call AWAV_SpawnMany(AWAV_GetFamilySupport(familyId), supportCount)
        call AWAV_SpawnMany(AWAV_GetFamilyHeavy(familyId), heavyCount)

        if AWAV_CurrentWave == AWAV_MaxWave then
            call AWAV_SpawnOne(AWAV_GetFamilyBoss(familyId))
        endif

        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00Wave " + I2S(AWAV_CurrentWave) + "/" + I2S(AWAV_MaxWave) + ": " + AWAV_GetFamilyName(familyId) + "|r")
        call TimerStart(AWAV_ThinkTimer, AWAV_THINK_INTERVAL, true, function AWAV_ThinkTick)
        call TimerStart(AWAV_PowerupTimer, AWAV_POWERUP_INTERVAL, true, function AWAV_PowerupTick)
        call Arena_OrderArenaUnitsToParticipants()

        if Arena_GetArenaUnitCount() <= 0 then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Wave spawn failed. Check unit rawcodes.|r")
            call Arena_End(false)
        endif
    endfunction

    private function AWAV_StartNextWave takes nothing returns nothing
        if not AWAV_IsCurrentSession() then
            call PauseTimer(AWAV_WaveTimer)
            return
        endif

        set AWAV_CurrentWave = AWAV_CurrentWave + 1
        call AWAV_SpawnWave()
    endfunction

    private function AWAV_FinishWave takes nothing returns nothing
        if not AWAV_IsCurrentSession() or not AWAV_WaveActive then
            return
        endif

        set AWAV_WaveActive = false
        call PauseTimer(AWAV_ThinkTimer)
        call PauseTimer(AWAV_PowerupTimer)
        call AWAV_ClearPowerups(true)
        call Arena_AwardMarks(AWAV_GetWaveReward())
        call Arena_ReviveDeadParticipantsAtGate()

        if AWAV_CurrentWave >= AWAV_MaxWave then
            call Arena_AwardMarks(AWAV_GetCompletionReward())
            call Arena_End(true)
        else
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cff80ff80Wave cleared. Next wave begins in 60 seconds.|r")
            call TimerStart(AWAV_WaveTimer, AWAV_NEXT_WAVE_DELAY, false, function AWAV_StartNextWave)
        endif
    endfunction

    private function AWAV_OnArenaUnitDeath takes nothing returns nothing
        if AWAV_IsCurrentSession() and AWAV_WaveActive and Arena_GetArenaUnitCount() <= 0 then
            call AWAV_FinishWave()
        endif
    endfunction

    private function AWAV_OnParticipantDeath takes nothing returns nothing
        if AWAV_IsCurrentSession() and Arena_EventParticipant != null and (Arena_EventParticipant == udg_Nazgrek or Arena_EventParticipant == udg_Zulkis) then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + GetHeroProperName(Arena_EventParticipant) + " has fallen in the arena.|r")
        endif
    endfunction

    private function AWAV_OnStart takes nothing returns nothing
        set AWAV_SessionId = Arena_GetSessionId()
        set AWAV_Difficulty = Arena_GetActiveDifficulty()
        set AWAV_CurrentWave = 0
        set AWAV_MaxWave = AWAV_GetMaxWave(AWAV_Difficulty)
        set AWAV_WaveActive = false
        call AWAV_ClearPowerups(true)

        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00Waves (" + Arena_GetDifficultyName(AWAV_Difficulty) + ") begins in 60 seconds.|r")
        call TimerStart(AWAV_WaveTimer, AWAV_FIRST_WAVE_DELAY, false, function AWAV_StartNextWave)
    endfunction

    private function AWAV_OnStop takes nothing returns nothing
        call PauseTimer(AWAV_WaveTimer)
        call PauseTimer(AWAV_ThinkTimer)
        call PauseTimer(AWAV_PowerupTimer)
        call AWAV_ClearPowerups(true)
        set AWAV_WaveActive = false
        set AWAV_SessionId = 0
        set AWAV_CurrentWave = 0
        set AWAV_MaxWave = 0
    endfunction

    private function Init takes nothing returns nothing
        set AWAV_WaveTimer = CreateTimer()
        set AWAV_ThinkTimer = CreateTimer()
        set AWAV_PowerupTimer = CreateTimer()

        call Arena_RegisterMode(ARENA_MODE_WAVES, "Waves", function AWAV_OnStart, function AWAV_OnStop, function AWAV_OnArenaUnitDeath, function AWAV_OnParticipantDeath)
    endfunction
endlibrary
