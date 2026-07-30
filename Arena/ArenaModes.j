/**
    ArenaModes

    Author: Valdemar
    Version:

    Description:
    Arena master dialog and mode launcher. Select an arena master, choose a
    mode, then choose which player heroes and party members enter the arena.

    Credits:
    - Arena/ArenaPlan.md
    - Abilities/AbilityTrainerDialogs.j

    How to install:
    Import after Arena.j, all ArenaMode*.j libraries, DialogInteraction, and
    DialogSystem. Events is optional and allows registering arena masters that
    enter the map after initialization.

    API:
    Automatic arena master registration only.

**/
library ArenaModes initializer Init requires Table, Arena, ArenaModeWaves, ArenaModeCTF, ArenaModeTeamDeathmatch, ArenaModeDuel, DialogInteraction, DialogSystem, optional Events
    globals
        private constant real AMD_DIALOG_RANGE = 900.00
        private constant real AMD_DIALOG_COOLDOWN = 1.50
        private constant boolean AMD_REQUIRE_DIALOG_HERO = true
        private constant boolean AMD_ALLOW_NAZGREK = true
        private constant boolean AMD_ALLOW_ZULKIS = true

        private constant integer AMD_ACTION_WAVES_EASY = 1
        private constant integer AMD_ACTION_WAVES_MEDIUM = 2
        private constant integer AMD_ACTION_WAVES_HARD = 3
        private constant integer AMD_ACTION_TEAM_DM = 4
        private constant integer AMD_ACTION_CTF = 5
        private constant integer AMD_ACTION_DUEL = 6
        private constant integer AMD_ACTION_SELECTED_HERO = 20
        private constant integer AMD_ACTION_BOTH_HEROES = 21
        private constant integer AMD_ACTION_SELECTED_PARTY = 22
        private constant integer AMD_ACTION_FULL_PARTY = 23
        private constant integer AMD_ACTION_FAREWELL = 99

        private dialog AMD_Dialog = null
        private timer AMD_DialogCooldown = null
        private Table AMD_RegisteredMaster = 0

        private unit AMD_SelectedMaster = null
        private unit AMD_SelectedHero = null
        private integer AMD_PendingModeId = ARENA_MODE_NONE
        private integer AMD_PendingArenaId = ARENA_ID_NONE
        private integer AMD_PendingDifficulty = ARENA_DIFFICULTY_EASY
    endglobals

    private function AMD_IsArenaMasterUnitType takes integer unitTypeId returns boolean
        return unitTypeId == ARENA_MASTER_HORDE or unitTypeId == ARENA_MASTER_SATYR or unitTypeId == ARENA_MASTER_BONECRUSHER or unitTypeId == ARENA_MASTER_RIVERBANE_PLACEHOLDER
    endfunction

    private function AMD_IsSelectedContextValid takes nothing returns boolean
        return AMD_SelectedMaster != null and GetUnitTypeId(AMD_SelectedMaster) != 0 and AMD_SelectedHero != null and DialogInteraction_IsUnitAlive(AMD_SelectedHero) and DialogInteraction_IsWithinRange(AMD_SelectedMaster, AMD_SelectedHero, AMD_DIALOG_RANGE)
    endfunction

    private function AMD_GetHeroDisplayName takes unit whichHero returns string
        if whichHero == udg_Nazgrek or whichHero == udg_Zulkis then
            return GetHeroProperName(whichHero)
        elseif whichHero != null then
            return GetUnitName(whichHero)
        endif

        return "Hero"
    endfunction

    private function AMD_GetOtherHero takes nothing returns unit
        if AMD_SelectedHero == udg_Nazgrek then
            return udg_Zulkis
        elseif AMD_SelectedHero == udg_Zulkis then
            return udg_Nazgrek
        endif

        return null
    endfunction

    private function AMD_IsOtherHeroAvailable takes nothing returns boolean
        local unit otherHero = AMD_GetOtherHero()
        local boolean result = otherHero != null and DialogInteraction_IsUnitAlive(otherHero) and DialogInteraction_IsWithinRange(AMD_SelectedMaster, otherHero, AMD_DIALOG_RANGE)

        set otherHero = null
        return result
    endfunction

    private function AMD_GetArenaForMode takes integer modeId, integer difficulty returns integer
        local integer masterType = 0

        if AMD_SelectedMaster != null then
            set masterType = GetUnitTypeId(AMD_SelectedMaster)
        endif

        if masterType == ARENA_MASTER_BONECRUSHER then
            return ARENA_ID_CIRCLE_OF_BLOOD
        elseif masterType == ARENA_MASTER_SATYR or masterType == ARENA_MASTER_RIVERBANE_PLACEHOLDER then
            return ARENA_ID_COLISEUM_OF_AGES
        endif

        if modeId == ARENA_MODE_WAVES and difficulty == ARENA_DIFFICULTY_EASY then
            return ARENA_ID_CIRCLE_OF_BLOOD
        elseif modeId == ARENA_MODE_DUEL then
            return ARENA_ID_CIRCLE_OF_BLOOD
        endif

        return ARENA_ID_COLISEUM_OF_AGES
    endfunction

    private function AMD_GetMasterTitle takes unit master returns string
        local integer masterType = 0

        if master != null then
            set masterType = GetUnitTypeId(master)
        endif

        if masterType == ARENA_MASTER_BONECRUSHER then
            return "Bonecrusher Arena"
        elseif masterType == ARENA_MASTER_SATYR then
            return "Satyr Arena"
        elseif masterType == ARENA_MASTER_RIVERBANE_PLACEHOLDER then
            return "Riverbane Arena"
        endif

        return "Horde Arena"
    endfunction

    private function AMD_ResetPendingMode takes nothing returns nothing
        set AMD_PendingModeId = ARENA_MODE_NONE
        set AMD_PendingArenaId = ARENA_ID_NONE
        set AMD_PendingDifficulty = ARENA_DIFFICULTY_EASY
    endfunction

    private function AMD_EndDialog takes boolean startCooldown returns nothing
        call DialogSystem_ClearEscapeAction()
        if AMD_Dialog != null then
            call DialogInteraction_HideDialog(AMD_Dialog, Player(0))
        endif
        if startCooldown then
            set AMD_DialogCooldown = DialogInteraction_StartCooldown(AMD_DialogCooldown, AMD_DIALOG_COOLDOWN)
        endif

        set AMD_SelectedMaster = null
        set AMD_SelectedHero = null
        call AMD_ResetPendingMode()
    endfunction

    private function AMD_StartPending takes boolean includeSelectedHero, boolean includeOtherHero, boolean includeCompanions, boolean includePet returns nothing
        local unit master = AMD_SelectedMaster
        local integer modeId = AMD_PendingModeId
        local integer arenaId = AMD_PendingArenaId
        local integer difficulty = AMD_PendingDifficulty
        local boolean includeNazgrek = false
        local boolean includeZulkis = false
        local unit otherHero

        if not AMD_IsSelectedContextValid() or modeId == ARENA_MODE_NONE or arenaId == ARENA_ID_NONE then
            call AMD_EndDialog(true)
            set master = null
            return
        endif

        if includeSelectedHero then
            if AMD_SelectedHero == udg_Nazgrek then
                set includeNazgrek = true
            elseif AMD_SelectedHero == udg_Zulkis then
                set includeZulkis = true
            endif
        endif

        if includeOtherHero then
            set otherHero = AMD_GetOtherHero()
            if otherHero != null and DialogInteraction_IsUnitAlive(otherHero) and DialogInteraction_IsWithinRange(AMD_SelectedMaster, otherHero, AMD_DIALOG_RANGE) then
                if otherHero == udg_Nazgrek then
                    set includeNazgrek = true
                elseif otherHero == udg_Zulkis then
                    set includeZulkis = true
                endif
            endif
        endif

        call AMD_EndDialog(true)
        call Arena_Start(modeId, arenaId, difficulty, master, includeNazgrek, includeZulkis, includeCompanions, includePet)

        set master = null
        set otherHero = null
    endfunction

    private function AMD_OnSelectedHero takes nothing returns nothing
        call AMD_StartPending(true, false, false, false)
    endfunction

    private function AMD_OnBothHeroes takes nothing returns nothing
        call AMD_StartPending(true, true, false, false)
    endfunction

    private function AMD_OnSelectedParty takes nothing returns nothing
        call AMD_StartPending(true, false, true, true)
    endfunction

    private function AMD_OnFullParty takes nothing returns nothing
        call AMD_StartPending(true, true, true, true)
    endfunction

    private function AMD_OnFarewell takes nothing returns nothing
        call AMD_EndDialog(true)
    endfunction

    private function AMD_BuildPartyDialog takes nothing returns nothing
        local button b
        local unit otherHero
        local string modeName

        if not AMD_IsSelectedContextValid() then
            set b = null
            set otherHero = null
            return
        endif

        set modeName = Arena_GetModeName(AMD_PendingModeId)
        if AMD_Dialog == null then
            set AMD_Dialog = DialogSystem_CreateDialog(modeName)
        endif

        call DialogSystem_ClearDialog(AMD_Dialog)
        call DialogSystem_SetTitle(AMD_Dialog, modeName + " - " + Arena_GetDifficultyName(AMD_PendingDifficulty))

        set b = DialogSystem_AddButton(AMD_Dialog, AMD_GetHeroDisplayName(AMD_SelectedHero), AMD_ACTION_SELECTED_HERO)
        call DialogSystem_BindButtonCode(b, function AMD_OnSelectedHero)

        if AMD_IsOtherHeroAvailable() then
            set otherHero = AMD_GetOtherHero()
            set b = DialogSystem_AddButton(AMD_Dialog, AMD_GetHeroDisplayName(AMD_SelectedHero) + " and " + AMD_GetHeroDisplayName(otherHero), AMD_ACTION_BOTH_HEROES)
            call DialogSystem_BindButtonCode(b, function AMD_OnBothHeroes)
            set b = DialogSystem_AddButton(AMD_Dialog, AMD_GetHeroDisplayName(AMD_SelectedHero) + " party", AMD_ACTION_SELECTED_PARTY)
            call DialogSystem_BindButtonCode(b, function AMD_OnSelectedParty)
            set b = DialogSystem_AddButton(AMD_Dialog, "Full party", AMD_ACTION_FULL_PARTY)
            call DialogSystem_BindButtonCode(b, function AMD_OnFullParty)
        else
            set b = DialogSystem_AddButton(AMD_Dialog, AMD_GetHeroDisplayName(AMD_SelectedHero) + " party", AMD_ACTION_SELECTED_PARTY)
            call DialogSystem_BindButtonCode(b, function AMD_OnSelectedParty)
        endif

        set b = DialogSystem_AddButton(AMD_Dialog, "Farewell", AMD_ACTION_FAREWELL)
        call DialogSystem_BindButtonCode(b, function AMD_OnFarewell)
        call DialogSystem_SetContext(AMD_SelectedMaster, Player(0))
        call DialogSystem_ShowDialog(AMD_Dialog, Player(0))

        set b = null
        set otherHero = null
    endfunction

    private function AMD_PrepareMode takes integer modeId, integer difficulty returns nothing
        if not AMD_IsSelectedContextValid() then
            call AMD_EndDialog(true)
            return
        endif

        set AMD_PendingModeId = modeId
        set AMD_PendingDifficulty = difficulty
        set AMD_PendingArenaId = AMD_GetArenaForMode(modeId, difficulty)
        call AMD_BuildPartyDialog()
    endfunction

    private function AMD_OnWavesEasy takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_WAVES, ARENA_DIFFICULTY_EASY)
    endfunction

    private function AMD_OnWavesMedium takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_WAVES, ARENA_DIFFICULTY_MEDIUM)
    endfunction

    private function AMD_OnWavesHard takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_WAVES, ARENA_DIFFICULTY_HARD)
    endfunction

    private function AMD_OnTeamDeathmatch takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_TEAM_DM, ARENA_DIFFICULTY_MEDIUM)
    endfunction

    private function AMD_OnCTF takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_CTF, ARENA_DIFFICULTY_MEDIUM)
    endfunction

    private function AMD_OnDuel takes nothing returns nothing
        call AMD_PrepareMode(ARENA_MODE_DUEL, ARENA_DIFFICULTY_EASY)
    endfunction

    private function AMD_BuildMainDialog takes nothing returns nothing
        local button b
        local string title

        if not AMD_IsSelectedContextValid() then
            set b = null
            return
        endif

        set title = AMD_GetMasterTitle(AMD_SelectedMaster)
        if AMD_Dialog == null then
            set AMD_Dialog = DialogSystem_CreateDialog(title)
        endif

        call AMD_ResetPendingMode()
        call DialogSystem_ClearDialog(AMD_Dialog)
        call DialogSystem_SetTitle(AMD_Dialog, title)

        set b = DialogSystem_AddButton(AMD_Dialog, "Waves: Easy", AMD_ACTION_WAVES_EASY)
        call DialogSystem_BindButtonCode(b, function AMD_OnWavesEasy)
        set b = DialogSystem_AddButton(AMD_Dialog, "Waves: Medium", AMD_ACTION_WAVES_MEDIUM)
        call DialogSystem_BindButtonCode(b, function AMD_OnWavesMedium)
        set b = DialogSystem_AddButton(AMD_Dialog, "Waves: Hard", AMD_ACTION_WAVES_HARD)
        call DialogSystem_BindButtonCode(b, function AMD_OnWavesHard)
        set b = DialogSystem_AddButton(AMD_Dialog, "Team Deathmatch", AMD_ACTION_TEAM_DM)
        call DialogSystem_BindButtonCode(b, function AMD_OnTeamDeathmatch)
        set b = DialogSystem_AddButton(AMD_Dialog, "Capture the Flag", AMD_ACTION_CTF)
        call DialogSystem_BindButtonCode(b, function AMD_OnCTF)
        set b = DialogSystem_AddButton(AMD_Dialog, "Duel", AMD_ACTION_DUEL)
        call DialogSystem_BindButtonCode(b, function AMD_OnDuel)
        set b = DialogSystem_AddButton(AMD_Dialog, "Farewell", AMD_ACTION_FAREWELL)
        call DialogSystem_BindButtonCode(b, function AMD_OnFarewell)

        set b = null
    endfunction

    private function AMD_ReportSelectionFailure takes nothing returns nothing
        local string reason = DialogInteraction_GetLastSelectionBlockReason()

        if reason == "" then
            set reason = "Cannot talk to the arena master right now"
        endif

        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080" + reason + ".|r")
    endfunction

    private function AMD_ShowDialogForSelection takes nothing returns nothing
        if not AMD_IsSelectedContextValid() then
            call AMD_EndDialog(false)
            return
        endif

        call AMD_BuildMainDialog()
        call DialogInteraction_ShowDialog(AMD_SelectedMaster, Player(0), AMD_Dialog)
    endfunction

    private function AMD_OnSelected takes nothing returns nothing
        local unit master = DialogInteraction_GetSelectedUnit()
        local unit hero
        local boolean gateOk

        if master == null or not AMD_IsArenaMasterUnitType(GetUnitTypeId(master)) then
            set master = null
            set hero = null
            return
        endif

        set hero = DialogInteraction_GetDialogSelectionHero(master, AMD_DIALOG_RANGE, AMD_ALLOW_NAZGREK, AMD_ALLOW_ZULKIS)
        set gateOk = DialogInteraction_PassDialogSelectionGate(master, hero, AMD_DIALOG_RANGE, AMD_DialogCooldown, AMD_REQUIRE_DIALOG_HERO, true, true, true, false, false)
        if not gateOk then
            call AMD_ReportSelectionFailure()
            set master = null
            set hero = null
            return
        endif

        set AMD_SelectedMaster = master
        set AMD_SelectedHero = hero
        call AMD_ShowDialogForSelection()

        set master = null
        set hero = null
    endfunction

    private function AMD_RegisterMaster takes unit master returns nothing
        local integer handleId

        if master == null or not DialogInteraction_IsUnitAlive(master) then
            return
        endif
        if not AMD_IsArenaMasterUnitType(GetUnitTypeId(master)) then
            return
        endif

        set handleId = GetHandleId(master)
        if AMD_RegisteredMaster.boolean[handleId] then
            return
        endif

        set AMD_RegisteredMaster.boolean[handleId] = true
        call DialogInteraction_Register(master)
        call DialogInteraction_SetGreetOrder(master, DIALOGINTERACTION_GREET_NONE)
        call DialogInteraction_RegisterSelectionHandler(master, function AMD_OnSelected)
    endfunction

    private function AMD_RegisterExistingMasters takes nothing returns nothing
        local group worldUnits = CreateGroup()
        local rect worldBounds = GetWorldBounds()
        local unit enumUnit

        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set enumUnit = FirstOfGroup(worldUnits)
            exitwhen enumUnit == null
            call GroupRemoveUnit(worldUnits, enumUnit)
            call AMD_RegisterMaster(enumUnit)
        endloop

        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set enumUnit = null
    endfunction

    private function AMD_OnUnitEnter takes nothing returns nothing
        call AMD_RegisterMaster(GetTriggerUnit())
    endfunction

    private function AMD_InitDelayed takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call AMD_RegisterExistingMasters()
        static if LIBRARY_Events then
            call Events_RegisterUnitEnter(function AMD_OnUnitEnter)
        endif

        call DestroyTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer

        set AMD_DialogCooldown = CreateTimer()
        set AMD_RegisteredMaster = Table.create()
        set initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function AMD_InitDelayed)
        set initTimer = null
    endfunction
endlibrary
