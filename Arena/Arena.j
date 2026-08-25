/**
    Arena

    Author: Valdemar
    Version:

    Description:
    Core arena session, participant, reward, death-routing, and cleanup system.
    Mode libraries register callbacks here, then use the public API to spawn
    arena-owned units, award arena marks, and finish with victory or defeat.

    Credits:
    - Arena/ArenaPlan.md

    How to install:
    Import after Table, UnitDeathEvent, ItemLootSystem, Experience, and
    Companions, and Death. Import Arena mode libraries after this file.

    API:
    - call Arena_RegisterMode(modeId, name, startCb, stopCb, unitDeathCb, participantDeathCb)
    - call Arena_RegisterEndCallback(callback)
    - call Arena_Start(modeId, arenaId, difficulty, master, nazgrek, zulkis, companions, pet)
    - call Arena_End(success)
    - call Arena_AwardMarks(baseAmount)
    - set u = Arena_SpawnArenaUnit(unitTypeId, owner, x, y, facing)
    - if Arena_IsActive() then
    - if Arena_IsArenaUnit(unit) then
    - if Arena_IsParticipant(unit) then

**/
library Arena initializer Init requires Table, UnitDeathEvent, ItemLootSystem, Experience, Companions, Death, FallenHeroState, optional RegionTitles
    globals
        // Public configuration and ids.
        constant integer ARENA_ID_NONE = 0
        constant integer ARENA_ID_CIRCLE_OF_BLOOD = 1
        constant integer ARENA_ID_COLISEUM_OF_AGES = 2

        constant integer ARENA_MODE_NONE = 0
        constant integer ARENA_MODE_WAVES = 1
        constant integer ARENA_MODE_CTF = 2
        constant integer ARENA_MODE_TEAM_DM = 3
        constant integer ARENA_MODE_DUEL = 4

        constant integer ARENA_DIFFICULTY_EASY = 1
        constant integer ARENA_DIFFICULTY_MEDIUM = 2
        constant integer ARENA_DIFFICULTY_HARD = 3

        constant integer ARENA_MASTER_HORDE = 'N60L'
        constant integer ARENA_MASTER_SATYR = 'n62V'
        constant integer ARENA_MASTER_BONECRUSHER = 'O61A'
        constant integer ARENA_MASTER_RIVERBANE_PLACEHOLDER = 'hRBA'

        // Event globals readable from registered callbacks.
        integer Arena_EventModeId = ARENA_MODE_NONE
        integer Arena_EventArenaId = ARENA_ID_NONE
        integer Arena_EventDifficulty = ARENA_DIFFICULTY_EASY
        unit Arena_EventUnit = null
        unit Arena_EventKiller = null
        unit Arena_EventParticipant = null
        boolean Arena_EventSuccess = false

        private constant integer ARENA_MAX_MODES = 16
        private constant real ARENA_END_DELAY = 2.00
        private constant real ARENA_PARTICIPANT_REWARD_PENALTY = 0.15
        private constant real ARENA_MAX_REWARD_PENALTY = 0.75
        private constant real ARENA_SPAWN_ACQUIRE_RANGE = 1600.00

        private trigger array Arena_ModeStartTrigger
        private trigger array Arena_ModeStopTrigger
        private trigger array Arena_ModeUnitDeathTrigger
        private trigger array Arena_ModeParticipantDeathTrigger
        private trigger Arena_EndCallbackTrigger = null
        private string array Arena_ModeName
        private boolean array Arena_ModeRegistered

        private group Arena_Participants = null
        private group Arena_ArenaUnits = null
        private Table Arena_ParticipantActive = 0
        private Table Arena_ArenaUnitActive = 0
        private Table Arena_HeroXpWasSuspended = 0
        private Table Arena_HeroXpStored = 0

        private boolean Arena_Active = false
        private boolean Arena_Ending = false
        private boolean Arena_LastResult = false
        private integer Arena_SessionId = 0
        private integer Arena_ActiveArenaId = ARENA_ID_NONE
        private integer Arena_ActiveModeId = ARENA_MODE_NONE
        private integer Arena_ActiveDifficulty = ARENA_DIFFICULTY_EASY
        private integer Arena_ParticipantCount = 0
        private integer Arena_SelectedHeroCount = 0
        private integer Arena_ArenaUnitCount = 0
        private unit Arena_ActiveMaster = null
        private unit Arena_PrimaryHero = null
        private real Arena_ReturnX = 0.00
        private real Arena_ReturnY = 0.00
        private timer Arena_EndTimer = null

        private unit Arena_SearchResult = null
        private unit Arena_OrderTarget = null
        private real Arena_OrderX = 0.00
        private real Arena_OrderY = 0.00
    endglobals

    private function Arena_IsExistingUnit takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0
    endfunction

    private function Arena_IsAliveUnit takes unit whichUnit returns boolean
        return FallenHeroState_IsAlive(whichUnit)
    endfunction

    private function Arena_IsPlayerMainHero takes unit whichUnit returns boolean
        return whichUnit != null and (whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis) and GetOwningPlayer(whichUnit) == Player(0)
    endfunction

    private function Arena_IsValidArenaId takes integer arenaId returns boolean
        return arenaId == ARENA_ID_CIRCLE_OF_BLOOD or arenaId == ARENA_ID_COLISEUM_OF_AGES
    endfunction

    private function Arena_IsValidModeId takes integer modeId returns boolean
        return modeId > ARENA_MODE_NONE and modeId <= ARENA_MAX_MODES
    endfunction

    public function IsActive takes nothing returns boolean
        return Arena_Active
    endfunction

    public function IsEnding takes nothing returns boolean
        return Arena_Ending
    endfunction

    public function GetSessionId takes nothing returns integer
        return Arena_SessionId
    endfunction

    public function GetActiveArenaId takes nothing returns integer
        return Arena_ActiveArenaId
    endfunction

    public function GetActiveModeId takes nothing returns integer
        return Arena_ActiveModeId
    endfunction

    public function GetActiveDifficulty takes nothing returns integer
        return Arena_ActiveDifficulty
    endfunction

    public function GetParticipantCount takes nothing returns integer
        return Arena_ParticipantCount
    endfunction

    public function GetSelectedHeroCount takes nothing returns integer
        return Arena_SelectedHeroCount
    endfunction

    public function GetArenaUnitCount takes nothing returns integer
        return Arena_ArenaUnitCount
    endfunction

    public function GetPrimaryHero takes nothing returns unit
        return Arena_PrimaryHero
    endfunction

    public function GetActiveMaster takes nothing returns unit
        return Arena_ActiveMaster
    endfunction

    public function GetArenaUnits takes nothing returns group
        return Arena_ArenaUnits
    endfunction

    public function GetParticipants takes nothing returns group
        return Arena_Participants
    endfunction

    public function GetModeName takes integer modeId returns string
        if Arena_IsValidModeId(modeId) and Arena_ModeName[modeId] != "" then
            return Arena_ModeName[modeId]
        endif
        return "Arena"
    endfunction

    public function GetArenaName takes integer arenaId returns string
        if arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return "Circle of Blood"
        elseif arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return "Coliseum of Ages"
        endif
        return "Arena"
    endfunction

    public function GetDifficultyName takes integer difficulty returns string
        if difficulty == ARENA_DIFFICULTY_HARD then
            return "Hard"
        elseif difficulty == ARENA_DIFFICULTY_MEDIUM then
            return "Medium"
        endif
        return "Easy"
    endfunction

    public function GetArenaAreaRect takes integer arenaId returns rect
        if arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return gg_rct_018ColiseumOfAges
        elseif arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return gg_rct_ArenaArea
        endif
        return null
    endfunction

    public function GetArenaGate1Rect takes integer arenaId returns rect
        if arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return gg_rct_Arena2Gate1
        elseif arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return gg_rct_Arena1Gate1
        endif
        return null
    endfunction

    public function GetArenaGate2Rect takes integer arenaId returns rect
        if arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return gg_rct_Arena2Gate2
        elseif arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return gg_rct_Arena1Gate2
        endif
        return null
    endfunction

    public function GetArenaFlag1Rect takes integer arenaId returns rect
        if arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return gg_rct_Arena2Flag1
        elseif arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return gg_rct_Arena1Flag1
        endif
        return null
    endfunction

    public function GetArenaFlag2Rect takes integer arenaId returns rect
        if arenaId == ARENA_ID_COLISEUM_OF_AGES then
            return gg_rct_Arena2Flag2
        elseif arenaId == ARENA_ID_CIRCLE_OF_BLOOD then
            return gg_rct_Arena1Flag2
        endif
        return null
    endfunction

    public function GetActiveAreaRect takes nothing returns rect
        return GetArenaAreaRect(Arena_ActiveArenaId)
    endfunction

    public function GetActiveGate1Rect takes nothing returns rect
        return GetArenaGate1Rect(Arena_ActiveArenaId)
    endfunction

    public function GetActiveGate2Rect takes nothing returns rect
        return GetArenaGate2Rect(Arena_ActiveArenaId)
    endfunction

    public function GetActiveFlag1Rect takes nothing returns rect
        return GetArenaFlag1Rect(Arena_ActiveArenaId)
    endfunction

    public function GetActiveFlag2Rect takes nothing returns rect
        return GetArenaFlag2Rect(Arena_ActiveArenaId)
    endfunction

    public function GetRectRandomX takes rect whichRect returns real
        if whichRect == null then
            return 0.00
        endif
        return GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect))
    endfunction

    public function GetRectRandomY takes rect whichRect returns real
        if whichRect == null then
            return 0.00
        endif
        return GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
    endfunction

    public function GetArenaCenterX takes integer arenaId returns real
        local rect whichRect = GetArenaAreaRect(arenaId)
        local real x = 0.00

        if whichRect != null then
            set x = GetRectCenterX(whichRect)
        endif

        set whichRect = null
        return x
    endfunction

    public function GetArenaCenterY takes integer arenaId returns real
        local rect whichRect = GetArenaAreaRect(arenaId)
        local real y = 0.00

        if whichRect != null then
            set y = GetRectCenterY(whichRect)
        endif

        set whichRect = null
        return y
    endfunction

    public function IsArenaUnit takes unit whichUnit returns boolean
        if whichUnit == null or Arena_ArenaUnitActive == 0 then
            return false
        endif
        return Arena_ArenaUnitActive.boolean[GetHandleId(whichUnit)]
    endfunction

    public function IsParticipant takes unit whichUnit returns boolean
        if whichUnit == null or Arena_ParticipantActive == 0 then
            return false
        endif
        return Arena_ParticipantActive.boolean[GetHandleId(whichUnit)]
    endfunction

    public function IsUnitInActiveArena takes unit whichUnit returns boolean
        local rect whichRect
        local boolean result = false

        if not Arena_Active or not Arena_IsExistingUnit(whichUnit) then
            return false
        endif

        set whichRect = GetActiveAreaRect()
        if whichRect != null then
            set result = RectContainsCoords(whichRect, GetUnitX(whichUnit), GetUnitY(whichUnit))
        endif

        set whichRect = null
        return result
    endfunction

    private function Arena_SaveHeroXpState takes unit whichHero returns nothing
        local integer handleId

        if not Arena_IsPlayerMainHero(whichHero) then
            return
        endif

        set handleId = GetHandleId(whichHero)
        if not Arena_HeroXpStored.boolean[handleId] then
            set Arena_HeroXpStored.boolean[handleId] = true
            set Arena_HeroXpWasSuspended.boolean[handleId] = IsSuspendedXP(whichHero)
        endif

        call SuspendHeroXP(whichHero, true)
        call Experience_ClearRested(whichHero)
    endfunction

    private function Arena_RestoreHeroXpState takes unit whichHero returns nothing
        local integer handleId

        if not Arena_IsPlayerMainHero(whichHero) then
            return
        endif

        set handleId = GetHandleId(whichHero)
        if Arena_HeroXpStored.boolean[handleId] then
            call SuspendHeroXP(whichHero, Arena_HeroXpWasSuspended.boolean[handleId])
            call Arena_HeroXpStored.remove(handleId)
            call Arena_HeroXpWasSuspended.remove(handleId)
            call Experience_SyncHeroXP(whichHero)
        endif
    endfunction

    private function Arena_AddParticipantInternal takes unit whichUnit returns boolean
        local integer handleId

        if not Arena_IsExistingUnit(whichUnit) then
            return false
        endif

        set handleId = GetHandleId(whichUnit)
        if Arena_ParticipantActive.boolean[handleId] then
            return false
        endif

        call GroupAddUnit(Arena_Participants, whichUnit)
        set Arena_ParticipantActive.boolean[handleId] = true
        set Arena_ParticipantCount = Arena_ParticipantCount + 1

        if Arena_IsPlayerMainHero(whichUnit) then
            set Arena_SelectedHeroCount = Arena_SelectedHeroCount + 1
            if Arena_PrimaryHero == null then
                set Arena_PrimaryHero = whichUnit
            endif
            call Arena_SaveHeroXpState(whichUnit)
        endif

        return true
    endfunction

    public function AddParticipant takes unit whichUnit returns boolean
        if not Arena_Active then
            return false
        endif
        return Arena_AddParticipantInternal(whichUnit)
    endfunction

    private function Arena_AddCompanions takes nothing returns nothing
        local integer index = 1
        local integer count = Companions_GetControlledDisplayCount()
        local unit controlledUnit

        loop
            exitwhen index > count
            set controlledUnit = Companions_GetControlledDisplayUnit(index)
            if Arena_IsAliveUnit(controlledUnit) then
                call Arena_AddParticipantInternal(controlledUnit)
            endif
            set index = index + 1
        endloop

        set controlledUnit = null
    endfunction

    private function Arena_BuildParticipants takes boolean includeNazgrek, boolean includeZulkis, boolean includeCompanions, boolean includePet returns nothing
        if includeNazgrek and Arena_IsExistingUnit(udg_Nazgrek) and GetOwningPlayer(udg_Nazgrek) == Player(0) then
            call Arena_AddParticipantInternal(udg_Nazgrek)
        endif
        if includeZulkis and Arena_IsExistingUnit(udg_Zulkis) and GetOwningPlayer(udg_Zulkis) == Player(0) then
            call Arena_AddParticipantInternal(udg_Zulkis)
        endif
        if includeCompanions then
            call Arena_AddCompanions()
        endif
        if includePet and Arena_IsExistingUnit(udg_TamedUnit) and Arena_IsAliveUnit(udg_TamedUnit) then
            call Arena_AddParticipantInternal(udg_TamedUnit)
        endif
    endfunction

    private function Arena_MoveParticipantToPoint takes unit whichUnit, real x, real y, boolean reviveDead returns nothing
        if not Arena_IsExistingUnit(whichUnit) then
            return
        endif

        if Death_IsFallen(whichUnit) then
            if reviveDead then
                call Death_ReviveAt(whichUnit, x, y, 100.00, 100.00, true)
            else
                return
            endif
        elseif IsUnitType(whichUnit, UNIT_TYPE_DEAD) then
            if reviveDead and IsUnitType(whichUnit, UNIT_TYPE_HERO) then
                call ReviveHero(whichUnit, x, y, true)
            else
                return
            endif
        endif

        call SetUnitX(whichUnit, x + GetRandomReal(-96.00, 96.00))
        call SetUnitY(whichUnit, y + GetRandomReal(-96.00, 96.00))
        call SetUnitState(whichUnit, UNIT_STATE_LIFE, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE))
        call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA))
        call PauseUnit(whichUnit, false)
        call IssueImmediateOrder(whichUnit, "stop")
    endfunction

    private function Arena_MoveParticipantEnum takes nothing returns nothing
        call Arena_MoveParticipantToPoint(GetEnumUnit(), Arena_OrderX, Arena_OrderY, true)
    endfunction

    private function Arena_MoveParticipantsToPoint takes real x, real y returns nothing
        set Arena_OrderX = x
        set Arena_OrderY = y
        call ForGroup(Arena_Participants, function Arena_MoveParticipantEnum)
    endfunction

    public function MoveParticipantsToGate takes nothing returns nothing
        local rect gate = GetActiveGate1Rect()

        if gate != null then
            call Arena_MoveParticipantsToPoint(GetRectCenterX(gate), GetRectCenterY(gate))
        endif

        set gate = null
    endfunction

    public function ReviveDeadParticipantsAtGate takes nothing returns nothing
        call Arena_MoveParticipantsToGate()
    endfunction

    private function Arena_RestoreParticipantEnum takes nothing returns nothing
        local unit whichUnit = GetEnumUnit()
        call Arena_RestoreHeroXpState(whichUnit)
        set whichUnit = null
    endfunction

    private function Arena_ClearParticipants takes nothing returns nothing
        local unit whichUnit
        call ForGroup(Arena_Participants, function Arena_RestoreParticipantEnum)

        loop
            set whichUnit = FirstOfGroup(Arena_Participants)
            exitwhen whichUnit == null
            call GroupRemoveUnit(Arena_Participants, whichUnit)
            call Arena_ParticipantActive.remove(GetHandleId(whichUnit))
        endloop

        set Arena_ParticipantCount = 0
        set Arena_SelectedHeroCount = 0
        set Arena_PrimaryHero = null
        set whichUnit = null
    endfunction

    public function RemoveArenaUnit takes unit whichUnit returns nothing
        local integer handleId

        if whichUnit == null then
            return
        endif

        set handleId = GetHandleId(whichUnit)
        if not Arena_ArenaUnitActive.boolean[handleId] then
            return
        endif

        set Arena_ArenaUnitActive.boolean[handleId] = false
        call Arena_ArenaUnitActive.remove(handleId)
        call GroupRemoveUnit(Arena_ArenaUnits, whichUnit)
        call ItemLoot_UnregisterExcludedUnit(whichUnit)
        set Arena_ArenaUnitCount = Arena_ArenaUnitCount - 1
        if Arena_ArenaUnitCount < 0 then
            set Arena_ArenaUnitCount = 0
        endif
    endfunction

    private function Arena_ClearArenaUnits takes nothing returns nothing
        local unit whichUnit

        loop
            set whichUnit = FirstOfGroup(Arena_ArenaUnits)
            exitwhen whichUnit == null
            call RemoveArenaUnit(whichUnit)
            if Arena_IsExistingUnit(whichUnit) then
                call RemoveUnit(whichUnit)
            endif
        endloop

        set Arena_ArenaUnitCount = 0
        set whichUnit = null
    endfunction

    public function SpawnArenaUnit takes integer unitTypeId, player owner, real x, real y, real facing returns unit
        local unit spawned
        local integer handleId

        if not Arena_Active or Arena_Ending or unitTypeId == 0 or owner == null then
            return null
        endif

        set spawned = CreateUnit(owner, unitTypeId, x, y, facing)
        if spawned == null or GetUnitTypeId(spawned) == 0 then
            set spawned = null
            return null
        endif

        set handleId = GetHandleId(spawned)
        set Arena_ArenaUnitActive.boolean[handleId] = true
        call GroupAddUnit(Arena_ArenaUnits, spawned)
        set Arena_ArenaUnitCount = Arena_ArenaUnitCount + 1

        call ItemLoot_RegisterExcludedUnit(spawned)
        call SetUnitAcquireRange(spawned, ARENA_SPAWN_ACQUIRE_RANGE)

        return spawned
    endfunction

    private function Arena_FindLivingParticipantEnum takes nothing returns nothing
        local unit whichUnit = GetEnumUnit()

        if Arena_SearchResult == null and Arena_IsAliveUnit(whichUnit) then
            set Arena_SearchResult = whichUnit
        endif

        set whichUnit = null
    endfunction

    public function GetFirstLivingParticipant takes nothing returns unit
        set Arena_SearchResult = null
        call ForGroup(Arena_Participants, function Arena_FindLivingParticipantEnum)
        return Arena_SearchResult
    endfunction

    private function Arena_FindLivingPlayerHeroEnum takes nothing returns nothing
        local unit whichUnit = GetEnumUnit()

        if Arena_SearchResult == null and Arena_IsPlayerMainHero(whichUnit) and Arena_IsAliveUnit(whichUnit) then
            set Arena_SearchResult = whichUnit
        endif

        set whichUnit = null
    endfunction

    public function GetFirstLivingSelectedHero takes nothing returns unit
        set Arena_SearchResult = null
        call ForGroup(Arena_Participants, function Arena_FindLivingPlayerHeroEnum)
        return Arena_SearchResult
    endfunction

    public function HasLivingSelectedHero takes nothing returns boolean
        return GetFirstLivingSelectedHero() != null
    endfunction

    private function Arena_OrderArenaUnitEnum takes nothing returns nothing
        local unit whichUnit = GetEnumUnit()
        local real x
        local real y
        local rect arenaRect

        if Arena_IsAliveUnit(whichUnit) then
            if Arena_OrderTarget != null and Arena_IsAliveUnit(Arena_OrderTarget) then
                call IssueTargetOrder(whichUnit, "attack", Arena_OrderTarget)
            else
                set arenaRect = GetActiveAreaRect()
                if arenaRect != null then
                    set x = GetRectRandomX(arenaRect)
                    set y = GetRectRandomY(arenaRect)
                    call IssuePointOrder(whichUnit, "attack", x, y)
                endif
                set arenaRect = null
            endif
        endif

        set whichUnit = null
    endfunction

    public function OrderArenaUnitsToParticipants takes nothing returns nothing
        set Arena_OrderTarget = GetFirstLivingParticipant()
        call ForGroup(Arena_ArenaUnits, function Arena_OrderArenaUnitEnum)
        set Arena_OrderTarget = null
    endfunction

    public function AwardMarks takes integer baseAmount returns integer
        local real penalty
        local real multiplier
        local integer amount

        if baseAmount <= 0 then
            return 0
        endif

        set penalty = I2R(Arena_ParticipantCount) * ARENA_PARTICIPANT_REWARD_PENALTY
        if penalty > ARENA_MAX_REWARD_PENALTY then
            set penalty = ARENA_MAX_REWARD_PENALTY
        endif
        set multiplier = 1.00 - penalty
        set amount = R2I(I2R(baseAmount) * multiplier + 0.50)
        if amount < 1 then
            set amount = 1
        endif

        call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_LUMBER) + amount)
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00+" + I2S(amount) + " Arena Marks|r")

        return amount
    endfunction

    private function Arena_RunStopCallback takes boolean success returns nothing
        local trigger stopTrigger

        if not Arena_IsValidModeId(Arena_ActiveModeId) then
            return
        endif

        set stopTrigger = Arena_ModeStopTrigger[Arena_ActiveModeId]
        if stopTrigger != null then
            set Arena_EventModeId = Arena_ActiveModeId
            set Arena_EventArenaId = Arena_ActiveArenaId
            set Arena_EventDifficulty = Arena_ActiveDifficulty
            set Arena_EventSuccess = success
            call TriggerExecute(stopTrigger)
            set Arena_EventSuccess = false
            set Arena_EventModeId = ARENA_MODE_NONE
            set Arena_EventArenaId = ARENA_ID_NONE
            set Arena_EventDifficulty = ARENA_DIFFICULTY_EASY
        endif

        set stopTrigger = null
    endfunction

    private function Arena_RunEndCallbacks takes boolean success returns nothing
        if Arena_EndCallbackTrigger == null then
            return
        endif

        set Arena_EventModeId = Arena_ActiveModeId
        set Arena_EventArenaId = Arena_ActiveArenaId
        set Arena_EventDifficulty = Arena_ActiveDifficulty
        set Arena_EventSuccess = success
        call TriggerExecute(Arena_EndCallbackTrigger)
        set Arena_EventSuccess = false
        set Arena_EventModeId = ARENA_MODE_NONE
        set Arena_EventArenaId = ARENA_ID_NONE
        set Arena_EventDifficulty = ARENA_DIFFICULTY_EASY
    endfunction

    private function Arena_ResetSessionState takes nothing returns nothing
        set Arena_Active = false
        set Arena_Ending = false
        set Arena_ActiveArenaId = ARENA_ID_NONE
        set Arena_ActiveModeId = ARENA_MODE_NONE
        set Arena_ActiveDifficulty = ARENA_DIFFICULTY_EASY
        set Arena_ActiveMaster = null
        set Arena_ReturnX = 0.00
        set Arena_ReturnY = 0.00
        set Arena_LastResult = false
    endfunction

    private function Arena_FinishEndNow takes nothing returns nothing
        call Arena_ClearArenaUnits()
        call Arena_MoveParticipantsToPoint(Arena_ReturnX, Arena_ReturnY)
        call Arena_ClearParticipants()
        call Arena_ResetSessionState()
    endfunction

    private function Arena_FinishEndDelay takes nothing returns nothing
        call PauseTimer(Arena_EndTimer)
        call Arena_FinishEndNow()
    endfunction

    public function End takes boolean success returns nothing
        if not Arena_Active or Arena_Ending then
            return
        endif

        set Arena_Ending = true
        set Arena_LastResult = success
        call Arena_RunStopCallback(success)
        call Arena_RunEndCallbacks(success)

        if success then
            static if LIBRARY_RegionTitles then
                call ShowRegionTitle("Arena Complete", GetModeName(Arena_ActiveModeId))
            else
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cff80ff80Arena complete.|r")
            endif
        else
            static if LIBRARY_RegionTitles then
                call ShowRegionTitle("Arena", "Defeat")
            else
                call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Defeat.|r")
            endif
        endif

        call TimerStart(Arena_EndTimer, ARENA_END_DELAY, false, function Arena_FinishEndDelay)
    endfunction

    public function Fail takes string reason returns nothing
        if reason != "" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + reason + "|r")
        endif
        call End(false)
    endfunction

    public function RegisterEndCallback takes code callback returns nothing
        if callback == null then
            return
        endif
        if Arena_EndCallbackTrigger == null then
            set Arena_EndCallbackTrigger = CreateTrigger()
        endif
        call TriggerAddAction(Arena_EndCallbackTrigger, callback)
    endfunction

    public function RegisterMode takes integer modeId, string modeName, code startCallback, code stopCallback, code unitDeathCallback, code participantDeathCallback returns nothing
        local trigger oldTrigger

        if not Arena_IsValidModeId(modeId) or startCallback == null then
            return
        endif

        set oldTrigger = Arena_ModeStartTrigger[modeId]
        if oldTrigger != null then
            call DestroyTrigger(oldTrigger)
        endif
        set Arena_ModeStartTrigger[modeId] = CreateTrigger()
        call TriggerAddAction(Arena_ModeStartTrigger[modeId], startCallback)

        set oldTrigger = Arena_ModeStopTrigger[modeId]
        if oldTrigger != null then
            call DestroyTrigger(oldTrigger)
            set Arena_ModeStopTrigger[modeId] = null
        endif
        if stopCallback != null then
            set Arena_ModeStopTrigger[modeId] = CreateTrigger()
            call TriggerAddAction(Arena_ModeStopTrigger[modeId], stopCallback)
        endif

        set oldTrigger = Arena_ModeUnitDeathTrigger[modeId]
        if oldTrigger != null then
            call DestroyTrigger(oldTrigger)
            set Arena_ModeUnitDeathTrigger[modeId] = null
        endif
        if unitDeathCallback != null then
            set Arena_ModeUnitDeathTrigger[modeId] = CreateTrigger()
            call TriggerAddAction(Arena_ModeUnitDeathTrigger[modeId], unitDeathCallback)
        endif

        set oldTrigger = Arena_ModeParticipantDeathTrigger[modeId]
        if oldTrigger != null then
            call DestroyTrigger(oldTrigger)
            set Arena_ModeParticipantDeathTrigger[modeId] = null
        endif
        if participantDeathCallback != null then
            set Arena_ModeParticipantDeathTrigger[modeId] = CreateTrigger()
            call TriggerAddAction(Arena_ModeParticipantDeathTrigger[modeId], participantDeathCallback)
        endif

        set Arena_ModeRegistered[modeId] = true
        set Arena_ModeName[modeId] = modeName
        set oldTrigger = null
    endfunction

    public function Start takes integer modeId, integer arenaId, integer difficulty, unit master, boolean includeNazgrek, boolean includeZulkis, boolean includeCompanions, boolean includePet returns boolean
        local trigger startTrigger
        local rect gate

        if Arena_Active then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080An arena battle is already active.|r")
            return false
        endif
        if not Arena_IsValidArenaId(arenaId) then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Arena area is not configured.|r")
            return false
        endif
        if not Arena_IsValidModeId(modeId) or not Arena_ModeRegistered[modeId] then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Arena mode is not available.|r")
            return false
        endif

        set startTrigger = Arena_ModeStartTrigger[modeId]
        if startTrigger == null then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Arena mode has no start handler.|r")
            set startTrigger = null
            return false
        endif

        set Arena_SessionId = Arena_SessionId + 1
        set Arena_Active = true
        set Arena_Ending = false
        set Arena_ActiveArenaId = arenaId
        set Arena_ActiveModeId = modeId
        set Arena_ActiveDifficulty = difficulty
        set Arena_ActiveMaster = master

        if master != null and GetUnitTypeId(master) != 0 then
            set Arena_ReturnX = GetUnitX(master)
            set Arena_ReturnY = GetUnitY(master)
        else
            set gate = GetArenaGate1Rect(arenaId)
            if gate != null then
                set Arena_ReturnX = GetRectCenterX(gate)
                set Arena_ReturnY = GetRectCenterY(gate)
            endif
            set gate = null
        endif

        call Arena_BuildParticipants(includeNazgrek, includeZulkis, includeCompanions, includePet)
        if Arena_SelectedHeroCount <= 0 then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Select at least one player hero for the arena.|r")
            call Arena_ClearParticipants()
            call Arena_ResetSessionState()
            set startTrigger = null
            return false
        endif

        call Arena_MoveParticipantsToGate()

        set Arena_EventModeId = modeId
        set Arena_EventArenaId = arenaId
        set Arena_EventDifficulty = difficulty
        call TriggerExecute(startTrigger)
        set Arena_EventModeId = ARENA_MODE_NONE
        set Arena_EventArenaId = ARENA_ID_NONE
        set Arena_EventDifficulty = ARENA_DIFFICULTY_EASY

        if not Arena_Ending then
            static if LIBRARY_RegionTitles then
                call ShowRegionTitle(GetArenaName(arenaId), GetModeName(modeId))
            endif
        endif

        set startTrigger = null
        return true
    endfunction

    private function Arena_OnDeath takes nothing returns nothing
        local unit dying = UnitDeathEvent_GetDyingUnit()
        local unit killer = UnitDeathEvent_GetKillingUnit()
        local trigger callbackTrigger

        if not Arena_Active or dying == null then
            set dying = null
            set killer = null
            return
        endif

        if IsArenaUnit(dying) then
            call RemoveArenaUnit(dying)
            set callbackTrigger = Arena_ModeUnitDeathTrigger[Arena_ActiveModeId]
            if callbackTrigger != null and not Arena_Ending then
                set Arena_EventModeId = Arena_ActiveModeId
                set Arena_EventArenaId = Arena_ActiveArenaId
                set Arena_EventDifficulty = Arena_ActiveDifficulty
                set Arena_EventUnit = dying
                set Arena_EventKiller = killer
                call TriggerExecute(callbackTrigger)
                set Arena_EventUnit = null
                set Arena_EventKiller = null
                set Arena_EventModeId = ARENA_MODE_NONE
                set Arena_EventArenaId = ARENA_ID_NONE
                set Arena_EventDifficulty = ARENA_DIFFICULTY_EASY
            endif
        elseif IsParticipant(dying) then
            set callbackTrigger = Arena_ModeParticipantDeathTrigger[Arena_ActiveModeId]
            if callbackTrigger != null and not Arena_Ending then
                set Arena_EventModeId = Arena_ActiveModeId
                set Arena_EventArenaId = Arena_ActiveArenaId
                set Arena_EventDifficulty = Arena_ActiveDifficulty
                set Arena_EventParticipant = dying
                set Arena_EventKiller = killer
                call TriggerExecute(callbackTrigger)
                set Arena_EventParticipant = null
                set Arena_EventKiller = null
                set Arena_EventModeId = ARENA_MODE_NONE
                set Arena_EventArenaId = ARENA_ID_NONE
                set Arena_EventDifficulty = ARENA_DIFFICULTY_EASY
            endif
            if not Arena_Ending and not HasLivingSelectedHero() then
                call End(false)
            endif
        endif

        set callbackTrigger = null
        set dying = null
        set killer = null
    endfunction

    private function Init takes nothing returns nothing
        set Arena_Participants = CreateGroup()
        set Arena_ArenaUnits = CreateGroup()
        set Arena_ParticipantActive = Table.create()
        set Arena_ArenaUnitActive = Table.create()
        set Arena_HeroXpWasSuspended = Table.create()
        set Arena_HeroXpStored = Table.create()
        set Arena_EndTimer = CreateTimer()

        call UnitDeathEvent_Register(function Arena_OnDeath)
    endfunction
endlibrary
