/**
    BaseCamp

    Author: Valdemar
    Version:

    Description:
    Handles tent/base-camp limits, Sleep-started resting progress for loaded
    player heroes, tent dismantling, and tent death cleanup. Rested progress
    and renewal are delegated to the Experience library.

    Credits:

    How to install:
    Import after Experience, Events, and UnitDeathEvent. Disable the old GUI triggers under
    Leveling/_oldGUI/Base Camp after importing.

    API:
    - call BaseCamp_RegisterTent(tent)
    - call BaseCamp_UnregisterTent(tent)
    - set hasTent = BaseCamp_PlayerHasTent(player)
    - Cast the tent's Sleep ability (`A0F2`) with Nazgrek or Zulkis loaded to
      start time skipping and rested progress or renewal.

**/
library BaseCamp initializer Init requires Experience, Events, UnitDeathEvent, optional HintsUI
    globals
        // Object data configuration.
        public constant integer TENT_UNIT_ID = 'n643'
        public constant integer TENT_ITEM_ID = 'I6C4'

        private constant integer BC_BUILD_TENT_ABILITY_ID = 'A6CH'
        private constant integer BC_DISMANTLE_ABILITY_ID = 'A02X'
        private constant integer BC_SLEEP_ABILITY_ID = 'A0F2'
        private constant integer BC_DEATH_ANIMATION_UNIT_ID = 'otrb'
        private constant integer BC_MAX_TENTS = 64
        private constant integer BC_MAX_REST_RECORDS = 128
        private constant integer BC_KEY_SLEEP_HIDDEN = 1
        private constant integer BC_KEY_SLEEP_WAS_PAUSED = 2
        private constant integer BC_KEY_SLEEP_WAS_HIDDEN = 3
        private constant integer BC_KEY_DISMANTLE_PENDING = 4
        private constant integer BC_KEY_DISMANTLE_X = 5
        private constant integer BC_KEY_DISMANTLE_Y = 6
        private constant integer BC_KEY_DISMANTLE_TENT_KEY = 7
        private constant integer BC_KEY_DISMANTLE_TENT_UNIT = 8

        private constant real BC_REST_TICK = 1.00
        private constant real BC_REST_REQUIRED = 8.00
        private constant real BC_TIME_OF_DAY_ADVANCE = 1.00
        private constant real BC_DISMANTLE_ITEM_CHECK_DELAY = 0.25
        private constant real BC_DISMANTLE_ITEM_CHECK_RADIUS = 96.00
        private constant real BC_DISMANTLE_ITEM_CHECK_RADIUS_SQ = 9216.00

        private unit array BC_Tent
        private integer BC_TentCount = 0

        private unit array BC_RestHero
        private unit array BC_RestTent
        private real array BC_RestElapsed
        private integer BC_RestCount = 0

        private timer BC_RestTimer = null
        private hashtable BC_Hash = null
        private rect BC_ItemSearchRect = null
        private real BC_ItemSearchX = 0.00
        private real BC_ItemSearchY = 0.00
        private boolean BC_ItemSearchFound = false
    endglobals

    private function BC_IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function BC_IsTrackedHero takes unit whichUnit returns boolean
        return whichUnit != null and IsUnitType(whichUnit, UNIT_TYPE_HERO)
    endfunction

    private function BC_IsPlayerHeroForTent takes unit whichHero, unit tent returns boolean
        return whichHero != null and tent != null and BC_IsTrackedHero(whichHero) and BC_IsAlive(whichHero) and GetOwningPlayer(whichHero) == GetOwningPlayer(tent) and (whichHero == udg_Nazgrek or whichHero == udg_Zulkis)
    endfunction

    private function BC_TentHasPlayerHeroInside takes unit tent returns boolean
        if tent == null or GetUnitTypeId(tent) != TENT_UNIT_ID then
            return false
        endif

        if BC_IsPlayerHeroForTent(udg_Nazgrek, tent) and IsUnitInTransport(udg_Nazgrek, tent) then
            return true
        endif

        if BC_IsPlayerHeroForTent(udg_Zulkis, tent) and IsUnitInTransport(udg_Zulkis, tent) then
            return true
        endif

        return false
    endfunction

    private function BC_RestoreHeroFromSleep takes unit whichHero returns nothing
        local integer heroKey

        if whichHero == null then
            return
        endif

        set heroKey = GetHandleId(whichHero)
        if not HaveSavedBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_HIDDEN) then
            return
        endif

        if not LoadBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_HIDDEN) then
            call ShowUnit(whichHero, true)
        endif
        if not LoadBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_PAUSED) then
            call PauseUnit(whichHero, false)
        endif

        call RemoveSavedBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_HIDDEN)
        call RemoveSavedBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_HIDDEN)
        call RemoveSavedBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_PAUSED)
    endfunction

    private function BC_RestoreSleepHiddenHeroes takes nothing returns nothing
        call BC_RestoreHeroFromSleep(udg_Nazgrek)
        call BC_RestoreHeroFromSleep(udg_Zulkis)
    endfunction

    private function BC_HideHeroForSleep takes unit whichHero returns nothing
        local integer heroKey

        if whichHero == null then
            return
        endif

        set heroKey = GetHandleId(whichHero)
        if HaveSavedBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_HIDDEN) then
            return
        endif

        call SaveBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_HIDDEN, true)
        call SaveBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_PAUSED, IsUnitPaused(whichHero))
        call SaveBoolean(BC_Hash, heroKey, BC_KEY_SLEEP_WAS_HIDDEN, IsUnitHidden(whichHero))
        call IssueImmediateOrder(whichHero, "stop")
        call PauseUnit(whichHero, true)
        call ShowUnit(whichHero, false)
    endfunction

    private function BC_HideOutsidePlayerHeroForSleep takes unit whichHero, unit tent returns nothing
        if BC_IsPlayerHeroForTent(whichHero, tent) and not IsUnitInTransport(whichHero, tent) then
            call BC_HideHeroForSleep(whichHero)
        endif
    endfunction

    private function BC_HideOutsidePlayerHeroesForSleep takes unit tent returns nothing
        call BC_HideOutsidePlayerHeroForSleep(udg_Nazgrek, tent)
        call BC_HideOutsidePlayerHeroForSleep(udg_Zulkis, tent)
    endfunction

    private function BC_PublishTentLimitHint takes unit whichUnit returns nothing
        static if LIBRARY_HintsUI then
            call HintsUI_PublishForUnit(HintsUI_HINT_TENT_LIMITATION, whichUnit)
        else
            call DisplayTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, "|cffffcc00Hint:|r You may have only one tent at a time.")
        endif
    endfunction

    public function PlayerHasTent takes player whichPlayer returns boolean
        local integer i = 0

        loop
            exitwhen i >= BC_TentCount
            if BC_Tent[i] != null and GetOwningPlayer(BC_Tent[i]) == whichPlayer and BC_IsAlive(BC_Tent[i]) then
                return true
            endif
            set i = i + 1
        endloop

        return false
    endfunction

    private function BC_FindTentIndex takes unit whichTent returns integer
        local integer i = 0

        loop
            exitwhen i >= BC_TentCount
            if BC_Tent[i] == whichTent then
                return i
            endif
            set i = i + 1
        endloop

        return -1
    endfunction

    public function RegisterTent takes unit whichTent returns nothing
        if whichTent == null or GetUnitTypeId(whichTent) != TENT_UNIT_ID or BC_FindTentIndex(whichTent) != -1 then
            return
        endif

        if BC_TentCount < BC_MAX_TENTS then
            set BC_Tent[BC_TentCount] = whichTent
            set BC_TentCount = BC_TentCount + 1
        endif
    endfunction

    public function UnregisterTent takes unit whichTent returns nothing
        local integer tentIndex = BC_FindTentIndex(whichTent)

        if tentIndex == -1 then
            return
        endif

        set BC_TentCount = BC_TentCount - 1
        set BC_Tent[tentIndex] = BC_Tent[BC_TentCount]
        set BC_Tent[BC_TentCount] = null
    endfunction

    private function BC_FindRestRecord takes unit hero, unit tent returns integer
        local integer i = 0

        loop
            exitwhen i >= BC_RestCount
            if BC_RestHero[i] == hero and BC_RestTent[i] == tent then
                return i
            endif
            set i = i + 1
        endloop

        return -1
    endfunction

    private function BC_TentHasRestRecord takes unit tent returns boolean
        local integer i = 0

        loop
            exitwhen i >= BC_RestCount
            if BC_RestTent[i] == tent then
                return true
            endif
            set i = i + 1
        endloop

        return false
    endfunction

    private function BC_StopRestTimerIfIdle takes nothing returns nothing
        if BC_RestCount <= 0 then
            call BC_RestoreSleepHiddenHeroes()
            call PauseTimer(BC_RestTimer)
        endif
    endfunction

    private function BC_FastForwardTime takes nothing returns nothing
        local real timeOfDay = GetFloatGameState(GAME_STATE_TIME_OF_DAY) + BC_TIME_OF_DAY_ADVANCE

        loop
            exitwhen timeOfDay < 24.00
            set timeOfDay = timeOfDay - 24.00
        endloop

        call SetFloatGameState(GAME_STATE_TIME_OF_DAY, timeOfDay)
    endfunction

    private function BC_ShowRestedMessage takes unit whichHero returns nothing
        if whichHero != null then
            call DisplayTextToPlayer(GetOwningPlayer(whichHero), 0.00, 0.00, "|cffffcc00" + GetHeroProperName(whichHero) + "|r is now |cff00ff00Rested|r.")
        endif
    endfunction

    private function BC_RemoveRestRecordAt takes integer index returns nothing
        if index < 0 or index >= BC_RestCount then
            return
        endif

        call Experience_ResetRestingProgress(BC_RestHero[index])
        set BC_RestCount = BC_RestCount - 1
        set BC_RestHero[index] = BC_RestHero[BC_RestCount]
        set BC_RestTent[index] = BC_RestTent[BC_RestCount]
        set BC_RestElapsed[index] = BC_RestElapsed[BC_RestCount]
        set BC_RestHero[BC_RestCount] = null
        set BC_RestTent[BC_RestCount] = null
        set BC_RestElapsed[BC_RestCount] = 0.00
    endfunction

    private function BC_RestingLoop takes nothing returns nothing
        local integer i = 0
        local unit hero
        local unit tent
        local boolean granted
        local boolean anyResting = false

        loop
            exitwhen i >= BC_RestCount
            set hero = BC_RestHero[i]
            set tent = BC_RestTent[i]

            if not BC_IsAlive(hero) or not BC_IsAlive(tent) or not IsUnitInTransport(hero, tent) then
                call BC_RemoveRestRecordAt(i)
                set i = i - 1
            else
                set anyResting = true
                set BC_RestElapsed[i] = BC_RestElapsed[i] + BC_REST_TICK
                if Experience_IsRested(hero) then
                    set granted = BC_RestElapsed[i] >= BC_REST_REQUIRED
                    if granted then
                        call Experience_GrantRested(hero)
                        call BC_ShowRestedMessage(hero)
                    endif
                else
                    set granted = Experience_AddRestingProgress(hero, BC_REST_TICK, BC_REST_REQUIRED)
                endif
                if granted then
                    call BC_RemoveRestRecordAt(i)
                    if not BC_TentHasRestRecord(tent) then
                        call IssueImmediateOrder(tent, "standdown")
                    endif
                    set i = i - 1
                endif
            endif

            set i = i + 1
        endloop

        if anyResting then
            call BC_FastForwardTime()
        endif

        call BC_StopRestTimerIfIdle()

        set tent = null
        set hero = null
    endfunction

    private function BC_AddRestRecord takes unit hero, unit tent returns boolean
        if BC_FindRestRecord(hero, tent) != -1 then
            return true
        endif

        if BC_RestCount < BC_MAX_REST_RECORDS then
            set BC_RestHero[BC_RestCount] = hero
            set BC_RestTent[BC_RestCount] = tent
            set BC_RestElapsed[BC_RestCount] = 0.00
            set BC_RestCount = BC_RestCount + 1
            call TimerStart(BC_RestTimer, BC_REST_TICK, true, function BC_RestingLoop)
            return true
        endif

        return false
    endfunction

    private function BC_TryAddSleepHero takes unit hero, unit tent returns boolean
        if BC_IsPlayerHeroForTent(hero, tent) and IsUnitInTransport(hero, tent) then
            return BC_AddRestRecord(hero, tent)
        endif

        return false
    endfunction

    private function BC_BeginSleepFromTent takes unit tent returns nothing
        local boolean started = false

        if tent == null or GetUnitTypeId(tent) != TENT_UNIT_ID or not BC_TentHasPlayerHeroInside(tent) then
            return
        endif

        set started = BC_TryAddSleepHero(udg_Nazgrek, tent) or started
        set started = BC_TryAddSleepHero(udg_Zulkis, tent) or started

        if started then
            call BC_HideOutsidePlayerHeroesForSleep(tent)
        endif
    endfunction

    private function BC_OnLoaded takes nothing returns nothing
        local unit hero = GetLoadedUnit()
        local unit tent = GetTransportUnit()

        if BC_IsTrackedHero(hero) and tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call RegisterTent(tent)
        endif

        set tent = null
        set hero = null
    endfunction

    private function BC_OnConstructFinish takes nothing returns nothing
        local unit tent = GetConstructedStructure()

        if tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call RegisterTent(tent)
        endif

        set tent = null
    endfunction

    private function BC_RemoveRestRecordsForTent takes unit tent returns nothing
        local integer i = 0

        loop
            exitwhen i >= BC_RestCount
            if BC_RestTent[i] == tent then
                call BC_RemoveRestRecordAt(i)
                set i = i - 1
            endif
            set i = i + 1
        endloop

        call BC_StopRestTimerIfIdle()
    endfunction

    private function BC_FindNearbyTentItem takes nothing returns nothing
        local item picked = GetEnumItem()
        local real dx
        local real dy

        if picked != null and GetItemTypeId(picked) == TENT_ITEM_ID and IsItemVisible(picked) then
            set dx = GetItemX(picked) - BC_ItemSearchX
            set dy = GetItemY(picked) - BC_ItemSearchY
            if dx * dx + dy * dy <= BC_DISMANTLE_ITEM_CHECK_RADIUS_SQ then
                set BC_ItemSearchFound = true
            endif
        endif

        set picked = null
    endfunction

    private function BC_HasNearbyTentItem takes real x, real y returns boolean
        set BC_ItemSearchX = x
        set BC_ItemSearchY = y
        set BC_ItemSearchFound = false
        call SetRect(BC_ItemSearchRect, x - BC_DISMANTLE_ITEM_CHECK_RADIUS, y - BC_DISMANTLE_ITEM_CHECK_RADIUS, x + BC_DISMANTLE_ITEM_CHECK_RADIUS, y + BC_DISMANTLE_ITEM_CHECK_RADIUS)
        call EnumItemsInRect(BC_ItemSearchRect, null, function BC_FindNearbyTentItem)
        return BC_ItemSearchFound
    endfunction

    private function BC_CreateDismantleItemDelayed takes nothing returns nothing
        local timer expired = GetExpiredTimer()
        local integer timerKey = GetHandleId(expired)
        local integer tentKey = LoadInteger(BC_Hash, timerKey, BC_KEY_DISMANTLE_TENT_KEY)
        local unit tent = LoadUnitHandle(BC_Hash, timerKey, BC_KEY_DISMANTLE_TENT_UNIT)
        local real x = LoadReal(BC_Hash, timerKey, BC_KEY_DISMANTLE_X)
        local real y = LoadReal(BC_Hash, timerKey, BC_KEY_DISMANTLE_Y)
        local item created = null

        if not BC_HasNearbyTentItem(x, y) then
            set created = CreateItem(TENT_ITEM_ID, x, y)
        endif
        if tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call RemoveUnit(tent)
        endif

        call RemoveSavedBoolean(BC_Hash, tentKey, BC_KEY_DISMANTLE_PENDING)
        call FlushChildHashtable(BC_Hash, timerKey)
        call PauseTimer(expired)
        call DestroyTimer(expired)

        set created = null
        set tent = null
        set expired = null
    endfunction

    private function BC_QueueDismantleItem takes unit tent, real x, real y returns nothing
        local timer delay = CreateTimer()
        local integer timerKey = GetHandleId(delay)

        call SaveInteger(BC_Hash, timerKey, BC_KEY_DISMANTLE_TENT_KEY, GetHandleId(tent))
        call SaveUnitHandle(BC_Hash, timerKey, BC_KEY_DISMANTLE_TENT_UNIT, tent)
        call SaveReal(BC_Hash, timerKey, BC_KEY_DISMANTLE_X, x)
        call SaveReal(BC_Hash, timerKey, BC_KEY_DISMANTLE_Y, y)
        call TimerStart(delay, BC_DISMANTLE_ITEM_CHECK_DELAY, false, function BC_CreateDismantleItemDelayed)

        set delay = null
    endfunction

    private function BC_OnDeath takes nothing returns nothing
        local unit tent = UnitDeathEvent_GetDyingUnit()
        local unit deathUnit = null

        if tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call BC_RemoveRestRecordsForTent(tent)
            call UnregisterTent(tent)
            set deathUnit = CreateUnit(GetOwningPlayer(tent), BC_DEATH_ANIMATION_UNIT_ID, GetUnitX(tent), GetUnitY(tent), GetUnitFacing(tent))
            call KillUnit(deathUnit)
            call UnitApplyTimedLife(deathUnit, 'BTLF', 2.00)
        endif

        set deathUnit = null
        set tent = null
    endfunction

    private function BC_OnSpellChannel takes nothing returns nothing
        local unit caster = GetTriggerUnit()
        local integer abilityId = GetSpellAbilityId()

        if abilityId == BC_BUILD_TENT_ABILITY_ID and caster != null then
            if PlayerHasTent(GetOwningPlayer(caster)) then
                call IssueImmediateOrder(caster, "stop")
                call BC_PublishTentLimitHint(caster)
            endif
        elseif abilityId == BC_SLEEP_ABILITY_ID and caster != null and GetUnitTypeId(caster) == TENT_UNIT_ID and not BC_TentHasPlayerHeroInside(caster) then
            call IssueImmediateOrder(caster, "stop")
        endif

        set caster = null
    endfunction

    private function BC_OnSpellEffect takes nothing returns nothing
        local unit tent = GetTriggerUnit()
        local integer abilityId = GetSpellAbilityId()
        local integer tentKey
        local real x
        local real y

        if abilityId == BC_SLEEP_ABILITY_ID and tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call BC_BeginSleepFromTent(tent)
        elseif abilityId == BC_DISMANTLE_ABILITY_ID and tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            set tentKey = GetHandleId(tent)
            if HaveSavedBoolean(BC_Hash, tentKey, BC_KEY_DISMANTLE_PENDING) then
                set tent = null
                return
            endif
            set x = GetUnitX(tent)
            set y = GetUnitY(tent)
            call SaveBoolean(BC_Hash, tentKey, BC_KEY_DISMANTLE_PENDING, true)
            call BC_RemoveRestRecordsForTent(tent)
            call UnregisterTent(tent)
            call BC_QueueDismantleItem(tent, x, y)
        endif

        set tent = null
    endfunction

    private function Init takes nothing returns nothing
        set BC_Hash = InitHashtable()
        set BC_RestTimer = CreateTimer()
        set BC_ItemSearchRect = Rect(0.00, 0.00, 0.00, 0.00)

        call Events_RegisterPlayerUnitEvent(function BC_OnLoaded, EVENT_PLAYER_UNIT_LOADED)
        call Events_RegisterPlayerUnitEvent(function BC_OnConstructFinish, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
        call UnitDeathEvent_Register(function BC_OnDeath)
        call Events_RegisterPlayerUnitEvent(function BC_OnSpellChannel, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
        call Events_RegisterPlayerUnitEvent(function BC_OnSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    endfunction
endlibrary
