/**
    PotSStateTracker

    Author: Valdemar
    Version: 2.0.0

    Description:
    Tracks bounded permanent hero-skill provenance through native learn events
    and an opt-in API for exceptional scripted permanent grants.

    Credits:
    - StateTracker by Tomotz, architectural inspiration

    How to install:
    Import after PotSSaveConfig and before PotSStateScanner.

    API:
    - PotSStateTracker_TrackPermanentAbility(hero, rawcode, level)
    - PotSStateTracker_ClearHero(hero)
    - PotSStateTracker_SetSuppressed(flag)
    - PotSStateTracker_GetCount/GetAbilityId/GetAbilityLevel(...)

**/
library PotSStateTracker initializer Init requires PotSSaveConfig, PotSStateData
    globals
        private constant integer PST_COUNT_KEY = 0
        private constant integer PST_ID_KEY = 100
        private constant integer PST_LEVEL_KEY = 300

        private hashtable PST_Table = InitHashtable()
        private trigger PST_LearnTrigger = null
        private boolean PST_Suppressed = false
    endglobals

    private function PST_Find takes unit hero, integer abilityId returns integer
        local integer parent
        local integer count
        local integer i = 0

        if hero == null or abilityId == 0 then
            return -1
        endif
        set parent = GetHandleId(hero)
        set count = LoadInteger(PST_Table, parent, PST_COUNT_KEY)
        loop
            exitwhen i >= count
            if LoadInteger(PST_Table, parent, PST_ID_KEY + i) == abilityId then
                return i
            endif
            set i = i + 1
        endloop
        return -1
    endfunction

    public function TrackPermanentAbility takes unit hero, integer abilityId, integer level returns boolean
        local integer parent
        local integer count
        local integer index

        if hero == null or abilityId == 0 or level <= 0 then
            return false
        endif
        set parent = GetHandleId(hero)
        set index = PST_Find(hero, abilityId)
        if index >= 0 then
            call SaveInteger(PST_Table, parent, PST_LEVEL_KEY + index, level)
            return true
        endif
        set count = LoadInteger(PST_Table, parent, PST_COUNT_KEY)
        if count >= PotSSaveConfig_MAX_ABILITIES then
            return false
        endif
        call SaveInteger(PST_Table, parent, PST_ID_KEY + count, abilityId)
        call SaveInteger(PST_Table, parent, PST_LEVEL_KEY + count, level)
        call SaveInteger(PST_Table, parent, PST_COUNT_KEY, count + 1)
        return true
    endfunction

    public function IsTracked takes unit hero, integer abilityId returns boolean
        return PST_Find(hero, abilityId) >= 0
    endfunction

    public function GetCount takes unit hero returns integer
        if hero == null then
            return 0
        endif
        return LoadInteger(PST_Table, GetHandleId(hero), PST_COUNT_KEY)
    endfunction

    public function GetAbilityId takes unit hero, integer index returns integer
        if hero == null or index < 0 or index >= GetCount(hero) then
            return 0
        endif
        return LoadInteger(PST_Table, GetHandleId(hero), PST_ID_KEY + index)
    endfunction

    public function GetAbilityLevel takes unit hero, integer index returns integer
        if hero == null or index < 0 or index >= GetCount(hero) then
            return 0
        endif
        return LoadInteger(PST_Table, GetHandleId(hero), PST_LEVEL_KEY + index)
    endfunction

    public function ClearHero takes unit hero returns nothing
        if hero != null then
            call FlushChildHashtable(PST_Table, GetHandleId(hero))
        endif
    endfunction

    public function SetSuppressed takes boolean suppressed returns nothing
        set PST_Suppressed = suppressed
    endfunction

    public function RestoreFromSnapshot takes unit hero returns nothing
        local integer i = 0

        call ClearHero(hero)
        loop
            exitwhen i >= PotSStateData_GetAbilityCount()
            if PotSStateData_GetAbilitySource(i) == PotSSaveConfig_ABILITY_SOURCE_TRACKED then
                call TrackPermanentAbility(hero, PotSStateData_GetAbilityId(i), PotSStateData_GetAbilityLevel(i))
            endif
            set i = i + 1
        endloop
    endfunction

    private function PST_OnLearn takes nothing returns nothing
        local unit hero = GetTriggerUnit()

        if not PST_Suppressed then
            call TrackPermanentAbility(hero, GetLearnedSkill(), GetLearnedSkillLevel())
        endif
        set hero = null
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0

        set PST_LearnTrigger = CreateTrigger()
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call TriggerRegisterPlayerUnitEvent(PST_LearnTrigger, Player(i), EVENT_PLAYER_HERO_SKILL, null)
            set i = i + 1
        endloop
        call TriggerAddAction(PST_LearnTrigger, function PST_OnLearn)
    endfunction
endlibrary
