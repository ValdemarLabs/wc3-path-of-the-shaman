/**
    BaseCamp

    Author: Valdemar
    Version:

    Description:
    Handles tent/base-camp limits, resting progress for loaded heroes, tent
    dismantling, and tent death cleanup. Rested state is delegated to the
    Experience library.

    Credits:

    How to install:
    Import after Experience. Disable the old GUI triggers under
    Leveling/_oldGUI/Base Camp after importing.

    API:
    - call BaseCamp_RegisterTent(tent)
    - call BaseCamp_UnregisterTent(tent)
    - set hasTent = BaseCamp_PlayerHasTent(player)

**/
library BaseCamp initializer Init requires Experience, optional HintsUI
    globals
        // Object data configuration.
        public constant integer TENT_UNIT_ID = 'n643'
        public constant integer TENT_ITEM_ID = 'I6C4'

        private constant integer BC_BUILD_TENT_ABILITY_ID = 'A6CH'
        private constant integer BC_DISMANTLE_ABILITY_ID = 'A02X'
        private constant integer BC_DEATH_ANIMATION_UNIT_ID = 'otrb'
        private constant integer BC_MAX_TENTS = 64
        private constant integer BC_MAX_REST_RECORDS = 128
        private constant integer BC_MAX_PLAYER_INDEX = 27

        private constant real BC_REST_TICK = 1.00
        private constant real BC_REST_REQUIRED = 8.00
        private constant real BC_TIME_OF_DAY_ADVANCE = 1.00

        private unit array BC_Tent
        private integer BC_TentCount = 0

        private unit array BC_RestHero
        private unit array BC_RestTent
        private integer BC_RestCount = 0

        private timer BC_RestTimer = null
        private trigger BC_LoadTrigger = null
        private trigger BC_SpellChannelTrigger = null
        private trigger BC_SpellEffectTrigger = null
        private trigger BC_ConstructTrigger = null
        private trigger BC_DeathTrigger = null
    endglobals

    private function BC_IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function BC_IsTrackedHero takes unit whichUnit returns boolean
        return whichUnit != null and IsUnitType(whichUnit, UNIT_TYPE_HERO)
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

    private function BC_StopRestTimerIfIdle takes nothing returns nothing
        if BC_RestCount <= 0 then
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

    private function BC_RemoveRestRecordAt takes integer index returns nothing
        if index < 0 or index >= BC_RestCount then
            return
        endif

        call Experience_ResetRestingProgress(BC_RestHero[index])
        set BC_RestCount = BC_RestCount - 1
        set BC_RestHero[index] = BC_RestHero[BC_RestCount]
        set BC_RestTent[index] = BC_RestTent[BC_RestCount]
        set BC_RestHero[BC_RestCount] = null
        set BC_RestTent[BC_RestCount] = null
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
                set granted = Experience_AddRestingProgress(hero, BC_REST_TICK, BC_REST_REQUIRED)
                if granted then
                    call IssueImmediateOrder(tent, "standdown")
                    call BC_RemoveRestRecordAt(i)
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

    private function BC_AddRestRecord takes unit hero, unit tent returns nothing
        if BC_FindRestRecord(hero, tent) != -1 then
            return
        endif

        if BC_RestCount < BC_MAX_REST_RECORDS then
            set BC_RestHero[BC_RestCount] = hero
            set BC_RestTent[BC_RestCount] = tent
            set BC_RestCount = BC_RestCount + 1
            call TimerStart(BC_RestTimer, BC_REST_TICK, true, function BC_RestingLoop)
        endif
    endfunction

    private function BC_OnLoaded takes nothing returns nothing
        local unit hero = GetLoadedUnit()
        local unit tent = GetTransportUnit()

        if BC_IsTrackedHero(hero) and tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            call RegisterTent(tent)
            call BC_AddRestRecord(hero, tent)
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

    private function BC_OnDeath takes nothing returns nothing
        local unit tent = GetTriggerUnit()
        local unit deathUnit = null

        if tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
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

        if GetSpellAbilityId() == BC_BUILD_TENT_ABILITY_ID and caster != null then
            if PlayerHasTent(GetOwningPlayer(caster)) then
                call IssueImmediateOrder(caster, "stop")
                call BC_PublishTentLimitHint(caster)
            endif
        endif

        set caster = null
    endfunction

    private function BC_OnSpellEffect takes nothing returns nothing
        local unit tent = GetTriggerUnit()
        local real x
        local real y

        if GetSpellAbilityId() == BC_DISMANTLE_ABILITY_ID and tent != null and GetUnitTypeId(tent) == TENT_UNIT_ID then
            set x = GetUnitX(tent)
            set y = GetUnitY(tent)
            call UnregisterTent(tent)
            call CreateItem(TENT_ITEM_ID, x, y)
            call RemoveUnit(tent)
        endif

        set tent = null
    endfunction

    private function BC_RegisterPlayerUnitEvents takes trigger whichTrigger, playerunitevent whichEvent returns nothing
        local integer playerIndex = 0

        loop
            exitwhen playerIndex > BC_MAX_PLAYER_INDEX
            call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
            set playerIndex = playerIndex + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        set BC_RestTimer = CreateTimer()

        set BC_LoadTrigger = CreateTrigger()
        call BC_RegisterPlayerUnitEvents(BC_LoadTrigger, EVENT_PLAYER_UNIT_LOADED)
        call TriggerAddAction(BC_LoadTrigger, function BC_OnLoaded)

        set BC_ConstructTrigger = CreateTrigger()
        call BC_RegisterPlayerUnitEvents(BC_ConstructTrigger, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
        call TriggerAddAction(BC_ConstructTrigger, function BC_OnConstructFinish)

        set BC_DeathTrigger = CreateTrigger()
        call BC_RegisterPlayerUnitEvents(BC_DeathTrigger, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddAction(BC_DeathTrigger, function BC_OnDeath)

        set BC_SpellChannelTrigger = CreateTrigger()
        call BC_RegisterPlayerUnitEvents(BC_SpellChannelTrigger, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
        call TriggerAddAction(BC_SpellChannelTrigger, function BC_OnSpellChannel)

        set BC_SpellEffectTrigger = CreateTrigger()
        call BC_RegisterPlayerUnitEvents(BC_SpellEffectTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
        call TriggerAddAction(BC_SpellEffectTrigger, function BC_OnSpellEffect)
    endfunction
endlibrary
