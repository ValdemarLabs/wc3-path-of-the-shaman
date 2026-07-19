/**
    CampFire

    Author: Valdemar
    Version:

    Description:
    Tracks constructed camp fires, applies their warmth abilities, creates
    light helpers, and grants rested progress to nearby heroes through the
    Experience library.

    Credits:

    How to install:
    Import after Experience. Disable the old GUI triggers under
    Leveling/_oldGUI/Camp Fire after importing.

    API:
    - call CampFire_Register(fire)
    - call CampFire_Unregister(fire)
    - Legacy wrappers: AddCampfire(fire), RemoveCampfire(fire)

**/
library CampFire initializer Init requires Experience, optional HintsUI
    globals
        // Object data configuration.
        public constant integer UNIT_ID = 'n61C'

        private constant integer CF_LIGHT_UNIT_ID = 'n619'
        private constant integer CF_BUILD_FIRE_ABILITY_ID = 'A61P'
        private constant integer CF_BUILD_TENT_ABILITY_ID = 'A6CH'
        private constant integer CF_WARMTH_ABILITY_ID = 'S600'
        private constant integer CF_WARMTH_HP_ABILITY_ID = 'A02W'
        private constant integer CF_WARMTH_MANA_ABILITY_ID = 'A02Y'
        private constant integer CF_MAX_FIRES = 128
        private constant integer CF_MAX_PLAYER_INDEX = 27

        private constant real CF_SCAN_INTERVAL = 1.00
        private constant real CF_RADIUS = 300.00
        private constant real CF_REST_REQUIRED = 15.00
        private constant real CF_LIFETIME = 60.00
        private constant real CF_LIGHT_CLEANUP_RADIUS = 80.00

        private unit array CF_Fire
        private integer CF_FireCount = 0

        private timer CF_ScanTimer = null
        private group CF_EnumGroup = null
        private boolexpr CF_HeroFilter = null
        private trigger CF_ConstructTrigger = null
        private trigger CF_DeathTrigger = null
        private trigger CF_SpellChannelTrigger = null
    endglobals

    private function CF_IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function CF_FilterRestingHero takes nothing returns boolean
        local unit hero = GetFilterUnit()
        local boolean result = hero != null and IsUnitType(hero, UNIT_TYPE_HERO) and GetWidgetLife(hero) > 0.405 and GetUnitAbilityLevel(hero, Experience_BUFF_WARMTH) > 0 and not Experience_IsRested(hero)

        set hero = null
        return result
    endfunction

    private function CF_IsInCombat takes unit whichUnit returns boolean
        local integer customValue = 0

        if whichUnit == null then
            return false
        endif

        set customValue = GetUnitUserData(whichUnit)
        return customValue > 0 and udg_GCSM_UnitInCombat[customValue]
    endfunction

    private function CF_PublishCombatLimitHint takes unit whichUnit returns nothing
        static if LIBRARY_HintsUI then
            call HintsUI_PublishForUnit(HintsUI_HINT_CAMP_FIRE_OR_TENT, whichUnit)
        else
            call DisplayTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, "|cffffcc00Hint:|r You must be out of combat to build a camp fire or tent.")
        endif
    endfunction

    private function CF_FindFireIndex takes unit fire returns integer
        local integer i = 0

        loop
            exitwhen i >= CF_FireCount
            if CF_Fire[i] == fire then
                return i
            endif
            set i = i + 1
        endloop

        return -1
    endfunction

    private function CF_RemoveFireAt takes integer fireIndex returns nothing
        if fireIndex < 0 or fireIndex >= CF_FireCount then
            return
        endif

        set CF_FireCount = CF_FireCount - 1
        set CF_Fire[fireIndex] = CF_Fire[CF_FireCount]
        set CF_Fire[CF_FireCount] = null

        if CF_FireCount <= 0 then
            call PauseTimer(CF_ScanTimer)
        endif
    endfunction

    private function CF_Scan takes nothing returns nothing
        local integer i = 0
        local unit fire
        local unit hero

        loop
            exitwhen i >= CF_FireCount
            set fire = CF_Fire[i]
            if not CF_IsAlive(fire) then
                call CF_RemoveFireAt(i)
                set i = i - 1
            else
                call GroupEnumUnitsInRange(CF_EnumGroup, GetUnitX(fire), GetUnitY(fire), CF_RADIUS, CF_HeroFilter)
                loop
                    set hero = FirstOfGroup(CF_EnumGroup)
                    exitwhen hero == null
                    call GroupRemoveUnit(CF_EnumGroup, hero)
                    call Experience_AddRestingProgress(hero, CF_SCAN_INTERVAL, CF_REST_REQUIRED)
                endloop
            endif
            set i = i + 1
        endloop

        set hero = null
        set fire = null
    endfunction

    public function Register takes unit fire returns nothing
        if fire == null or GetUnitTypeId(fire) != UNIT_ID or CF_FindFireIndex(fire) != -1 then
            return
        endif

        if CF_FireCount < CF_MAX_FIRES then
            set CF_Fire[CF_FireCount] = fire
            set CF_FireCount = CF_FireCount + 1
            call TimerStart(CF_ScanTimer, CF_SCAN_INTERVAL, true, function CF_Scan)
        endif
    endfunction

    public function Unregister takes unit fire returns nothing
        call CF_RemoveFireAt(CF_FindFireIndex(fire))
    endfunction

    private function CF_OnConstructFinish takes nothing returns nothing
        local unit fire = GetConstructedStructure()
        local real x
        local real y

        if fire != null and GetUnitTypeId(fire) == UNIT_ID then
            set x = GetUnitX(fire)
            set y = GetUnitY(fire)
            call UnitAddAbility(fire, CF_WARMTH_ABILITY_ID)
            call UnitAddAbility(fire, CF_WARMTH_HP_ABILITY_ID)
            call UnitAddAbility(fire, CF_WARMTH_MANA_ABILITY_ID)
            call UnitApplyTimedLife(fire, 'BTLF', CF_LIFETIME)
            call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), CF_LIGHT_UNIT_ID, x, y, 0.00)
            call Register(fire)
        endif

        set fire = null
    endfunction

    private function CF_RemoveNearbyLight takes nothing returns nothing
        local unit picked = GetEnumUnit()

        if picked != null and GetUnitTypeId(picked) == CF_LIGHT_UNIT_ID then
            call RemoveUnit(picked)
        endif

        set picked = null
    endfunction

    private function CF_OnDeath takes nothing returns nothing
        local unit fire = GetTriggerUnit()

        if fire != null and GetUnitTypeId(fire) == UNIT_ID then
            call Unregister(fire)
            call GroupEnumUnitsInRange(CF_EnumGroup, GetUnitX(fire), GetUnitY(fire), CF_LIGHT_CLEANUP_RADIUS, null)
            call ForGroup(CF_EnumGroup, function CF_RemoveNearbyLight)
            call GroupClear(CF_EnumGroup)
        endif

        set fire = null
    endfunction

    private function CF_OnSpellChannel takes nothing returns nothing
        local unit caster = GetTriggerUnit()
        local integer abilityId = GetSpellAbilityId()

        if caster != null and (abilityId == CF_BUILD_FIRE_ABILITY_ID or abilityId == CF_BUILD_TENT_ABILITY_ID) and CF_IsInCombat(caster) then
            call IssueImmediateOrder(caster, "stop")
            call CF_PublishCombatLimitHint(caster)
        endif

        set caster = null
    endfunction

    private function CF_RegisterPlayerUnitEvents takes trigger whichTrigger, playerunitevent whichEvent returns nothing
        local integer playerIndex = 0

        loop
            exitwhen playerIndex > CF_MAX_PLAYER_INDEX
            call TriggerRegisterPlayerUnitEvent(whichTrigger, Player(playerIndex), whichEvent, null)
            set playerIndex = playerIndex + 1
        endloop
    endfunction

    function AddCampfire takes unit fire returns nothing
        call Register(fire)
    endfunction

    function RemoveCampfire takes unit fire returns nothing
        call Unregister(fire)
    endfunction

    function InitCampFireBuffSystem takes nothing returns nothing
    endfunction

    private function Init takes nothing returns nothing
        set CF_ScanTimer = CreateTimer()
        set CF_EnumGroup = CreateGroup()
        set CF_HeroFilter = Filter(function CF_FilterRestingHero)

        set CF_ConstructTrigger = CreateTrigger()
        call CF_RegisterPlayerUnitEvents(CF_ConstructTrigger, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
        call TriggerAddAction(CF_ConstructTrigger, function CF_OnConstructFinish)

        set CF_DeathTrigger = CreateTrigger()
        call CF_RegisterPlayerUnitEvents(CF_DeathTrigger, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddAction(CF_DeathTrigger, function CF_OnDeath)

        set CF_SpellChannelTrigger = CreateTrigger()
        call CF_RegisterPlayerUnitEvents(CF_SpellChannelTrigger, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
        call TriggerAddAction(CF_SpellChannelTrigger, function CF_OnSpellChannel)
    endfunction
endlibrary
