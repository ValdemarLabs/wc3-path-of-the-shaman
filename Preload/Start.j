/**
    Start

    Author: Valdemar
    Version:

    Description:
    Runs the player start flow after GameMode finishes. This replaces the old
    Game Start GUI trigger with explicit startup phases.

    Credits:
    - Old GUI "Game Start" trigger

    How to install:
    Import with GameMode.j and the required systems below. GameMode.j calls
    Start_Start() after mode and difficulty are selected. Disable the old Game
    Start GUI trigger's startup event so this library owns player start setup.

    API:
    call Start_Start()
    call Start_SetRunIntroCinematic(boolean enabled)
    call Start_SetStartingGoldBonus(integer amount)

**/
library Start requires ZonesCore, DInventory, DEquipment, WeatherSystem, TerrainDamage, BridgeSystem
    globals
        // Configuration
        private constant integer ST_PLAYER_ID = 0
        private constant integer ST_START_GOLD = 150
        private constant real ST_HERO_SETUP_DELAY = 1.00
        private constant real ST_INTRO_DELAY = 1.00


        // ============================================================
        // NAZGREK
        private constant integer ST_UNIT_NAZGREK = 'H600'

        // These (except Specialization ability) must be the dummy ability, not the "real one"
        private constant integer ST_ABILITY_EARTHWARDEN = 'A6A4'
        private constant integer ST_ABILITY_STORMSTRIKE = 'A681'        
        private constant integer ST_ABILITY_WHIRLWIND = 'A6DQ'
        private constant integer ST_ABILITY_PRIMAL_FORCE = 'A023'

        // Starting equipment
        private constant integer ST_ITEM_NAZGREKS_AXE = 'I68A'
        private constant integer ST_ITEM_CHEST = 'j4b1'
        private constant integer ST_ITEM_SHOULDERS = 'j4b0'
        private constant integer ST_ITEM_HANDS = 'j4b2'
        private constant integer ST_ITEM_BELT = 'j4b3'
        private constant integer ST_ITEM_LEGS = 'j4b4'
        private constant integer ST_ITEM_FOOT = 'j4b5'
        private constant integer ST_ITEM_BACK = 'j4b6'
        private constant integer ST_ITEM_NECK = 'j4b7'
        private constant integer ST_ITEM_RING = 'j4b8'
        private constant integer ST_ITEM_HEAD = 'j4b9'
        private constant integer ST_ITEM_BRACERS = 'j4c0'
        private constant integer ST_ITEM_TRINKET = 'j4c1'

        // starting consumables
        private constant integer ST_ITEM_HEALING_SALVE = 'hslv'
        private constant integer ST_ITEM_SPRING_WATER = 'I60Z'

        // ============================================================

        // Runtime state
        private timer ST_Timer = null
        private boolean ST_Started = false
        private boolean ST_RunIntroCinematic = true
        private integer ST_StartingGoldBonus = 0
    endglobals

    private function ST_StopTimer takes nothing returns nothing
        if ST_Timer != null then
            call PauseTimer(ST_Timer)
            call DestroyTimer(ST_Timer)
            set ST_Timer = null
        endif
    endfunction

    private function ST_HasNazgrek takes nothing returns boolean
        return udg_Nazgrek != null and GetUnitTypeId(udg_Nazgrek) != 0
    endfunction

    private function ST_GetFacingToPlayerStart takes real x, real y returns real
        local integer startLocation = GetPlayerStartLocation(Player(ST_PLAYER_ID))
        return Atan2(GetStartLocationY(startLocation) - y, GetStartLocationX(startLocation) - x) * bj_RADTODEG
    endfunction

    // Phase 1: mark game start and lock disabled starter zones.
    private function ST_PhaseInitialState takes nothing returns nothing
        set udg_START = 1
        call ZonesCore_EnableZone(1, false)
        call ZonesCore_EnableZone(2, false)
    endfunction

    private function ST_CreateNazgrek takes nothing returns nothing
        local real x = 0.00
        local real y = 0.00

        if gg_rct_IntroV2Nazgrek01 == null then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Start: gg_rct_IntroV2Nazgrek01 is missing.|r")
            return
        endif

        set x = GetRectCenterX(gg_rct_IntroV2Nazgrek01)
        set y = GetRectCenterY(gg_rct_IntroV2Nazgrek01)
        set udg_Nazgrek = CreateUnit(Player(ST_PLAYER_ID), ST_UNIT_NAZGREK, x, y, ST_GetFacingToPlayerStart(x, y))
        set bj_lastCreatedUnit = udg_Nazgrek

        if not ST_HasNazgrek() then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Start: Could not create Nazgrek unit 'H600'.|r")
        endif
    endfunction

    private function ST_InitHeroSystems takes nothing returns nothing
        if ST_HasNazgrek() then
            call InitializeDInventoryForUnit(udg_Nazgrek)
            call InitializeDEquipmentForUnit(udg_Nazgrek)
        endif
    endfunction

    private function ST_UnpauseHero takes nothing returns nothing
        if ST_HasNazgrek() then
            call PauseUnit(udg_Nazgrek, false)
        endif
    endfunction

    private function ST_AddStartingAbilities takes nothing returns nothing
        if ST_HasNazgrek() then
            call UnitAddAbility(udg_Nazgrek, ST_ABILITY_EARTHWARDEN)
            call UnitAddAbility(udg_Nazgrek, ST_ABILITY_STORMSTRIKE)
            call UnitAddAbility(udg_Nazgrek, ST_ABILITY_WHIRLWIND)
            call UnitAddAbility(udg_Nazgrek, ST_ABILITY_PRIMAL_FORCE)
        endif
    endfunction

    private function ST_AddStartingItems takes nothing returns nothing
        
        // Create items for Nazgrek
        if ST_HasNazgrek() then
            // gear
            call UnitAddItemByIdSwapped(ST_ITEM_NAZGREKS_AXE, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_BACK, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_BELT, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_BRACERS, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_CHEST, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_FOOT, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_HANDS, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_HEAD, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_LEGS, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_NECK, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_RING, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_SHOULDERS, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_TRINKET, udg_Nazgrek)

            // consumables
            call UnitAddItemByIdSwapped(ST_ITEM_HEALING_SALVE, udg_Nazgrek)
            call UnitAddItemByIdSwapped(ST_ITEM_SPRING_WATER, udg_Nazgrek)
        endif

        // Equip gear for Nazgrek
        loop
            exitwhen not DInvTryEquipBestStoredEquipmentForUnit(ST_UNIT_NAZGREK)
        endloop
    endfunction

    private function ST_SetStartingResources takes nothing returns nothing
        local integer gold = ST_START_GOLD + ST_StartingGoldBonus

        if gold < 0 then
            set gold = 0
        endif

        call SetPlayerState(Player(ST_PLAYER_ID), PLAYER_STATE_RESOURCE_GOLD, gold)
    endfunction

    // Phase 3: start intro cinematic, then enable world systems that need player units.
    private function ST_PhaseIntroAndWorldSystems takes nothing returns nothing
        call ST_StopTimer()

        if not ST_RunIntroCinematic then
            call EnableUserControl(true)
        elseif gg_trg_Intro_Cinematic_Orc_Q != null then
            call ConditionalTriggerExecute(gg_trg_Intro_Cinematic_Orc_Q)
        else
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Start: gg_trg_Intro_Cinematic_Orc_Q is missing.|r")
            call EnableUserControl(true)
        endif

        call WeatherSystem_EnableSeasonalWeather(true)
        call TerrainDamage_InitUnits()
        call TerrainDamage_InitGroups()

        if udg_CompDummy != null then
            call BridgeSystem_AddIgnoredUnit(udg_CompDummy)
        endif
    endfunction

    // Phase 2: create Nazgrek and apply starter systems, abilities, items, and resources.
    private function ST_PhaseHeroSetup takes nothing returns nothing
        call ST_CreateNazgrek()
        call ST_InitHeroSystems()
        call ST_UnpauseHero()
        call ST_AddStartingAbilities()
        call ST_AddStartingItems()
        call ST_SetStartingResources()

        call TimerStart(ST_Timer, ST_INTRO_DELAY, false, function ST_PhaseIntroAndWorldSystems)
    endfunction

    public function Start takes nothing returns nothing
        if ST_Started then
            return
        endif

        set ST_Started = true
        set ST_Timer = CreateTimer()

        call ST_PhaseInitialState()
        call TimerStart(ST_Timer, ST_HERO_SETUP_DELAY, false, function ST_PhaseHeroSetup)
    endfunction

    public function SetRunIntroCinematic takes boolean enabled returns nothing
        set ST_RunIntroCinematic = enabled
    endfunction

    public function SetStartingGoldBonus takes integer amount returns nothing
        set ST_StartingGoldBonus = amount
    endfunction
endlibrary
