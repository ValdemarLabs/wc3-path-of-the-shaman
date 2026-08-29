/**
    AbilityPoints

    Author: Valdemar
    Version:

    Description:
    Centralizes player hero ability points for Nazgrek and Zul'kis. The
    library owns the AP state directly so UI and gameplay systems use one API.

    Credits:

    How to install:
    Import after AbilitiesPlayer with the rest of the Leveling libraries.
    Disable the old GUI level-up and reset-abilities triggers after importing.

    API:
    - call AbilityPoints_Add(hero, amount)
    - call AbilityPoints_Reduce(hero, amount)
    - call AbilityPoints_Set(hero, amount)
    - set spent = AbilityPoints_Spend(hero, amount)
    - set points = AbilityPoints_Get(hero)
    - call AbilityPoints_ResetHeroAbilities(hero)
    - call AbilityPoints_SetHeroLevelUpEnabled(enabled)
    - call AbilityPoints_DisableHeroLevelUp()
    - call AbilityPoints_EnableHeroLevelUp()
    - set enabled = AbilityPoints_IsHeroLevelUpEnabled()
    - Debug: /debug ap add

**/
library AbilityPoints initializer Init requires AbilitiesPlayer, optional RegionTitles, optional DItemTransfer, optional DInventory, optional DEquipment, optional HintsUI
    globals
        public constant integer HERO_NAZGREK = 1
        public constant integer HERO_ZULKIS = 2

        private constant integer AP_RESET_ITEM_ID = 'I6A1'
        private constant integer AP_RESET_BONUS_POINTS = 3
        private constant integer AP_INITIAL_POINTS_NAZGREK = 1
        private constant integer AP_INITIAL_POINTS_ZULKIS = 1
        private constant integer AP_DEBUG_ADD_AMOUNT = 1
        private constant integer AP_MAX_PLAYER_INDEX = 27

        private integer array AP_Points
        private integer array AP_ResetQuestRank
        private boolean AP_HeroLevelUpEnabled = true
        private trigger AP_LevelTrigger = null
        private trigger AP_ItemTrigger = null
        private trigger AP_DebugChatTrigger = null
    endglobals

    private function AP_GetHeroSlot takes unit whichHero returns integer
        if whichHero == udg_Nazgrek then
            return HERO_NAZGREK
        elseif whichHero == udg_Zulkis then
            return HERO_ZULKIS
        endif

        return 0
    endfunction

    private function AP_GetCompanionGroupSizeForLevel takes integer level returns integer
        if level >= 25 then
            return 6
        elseif level >= 20 then
            return 5
        elseif level >= 15 then
            return 4
        elseif level >= 10 then
            return 3
        elseif level >= 5 then
            return 2
        endif

        return 1
    endfunction

    private function AP_SyncCompanionGroupSize takes nothing returns nothing
        local integer highestLevel = 1
        local boolean foundHero = false

        if udg_Nazgrek != null and GetHeroLevel(udg_Nazgrek) > highestLevel then
            set highestLevel = GetHeroLevel(udg_Nazgrek)
            set foundHero = true
        elseif udg_Nazgrek != null then
            set foundHero = true
        endif
        if udg_Zulkis != null and GetHeroLevel(udg_Zulkis) > highestLevel then
            set highestLevel = GetHeroLevel(udg_Zulkis)
            set foundHero = true
        elseif udg_Zulkis != null then
            set foundHero = true
        endif

        if not foundHero then
            return
        endif

        set udg_Companion_GroupSize = AP_GetCompanionGroupSizeForLevel(highestLevel)
    endfunction

    private function AP_ShowLevelText takes unit whichHero returns nothing
        static if LIBRARY_RegionTitles then
            call ShowSingleLineText("|cffffcc00" + GetHeroProperName(whichHero) + "|r has reached Level |cffffcc00" + I2S(GetHeroLevel(whichHero)) + "|r", 0.50, 3.00, 1.50, 1.50)
        else
            call DisplayTextToPlayer(GetOwningPlayer(whichHero), 0.00, 0.00, "|cffffcc00" + GetHeroProperName(whichHero) + "|r has reached Level |cffffcc00" + I2S(GetHeroLevel(whichHero)) + "|r")
        endif
    endfunction

    private function AP_ShowPointGainText takes unit whichHero, integer amount returns nothing
        if whichHero == null or amount <= 0 then
            return
        endif

        if amount == 1 then
            call DisplayTextToPlayer(GetOwningPlayer(whichHero), 0.00, 0.00, "|cff80ff80Ability point gained.|r")
        else
            call DisplayTextToPlayer(GetOwningPlayer(whichHero), 0.00, 0.00, "|cff80ff80Ability points gained:|r " + I2S(amount))
        endif
    endfunction

    private function AP_SetBySlot takes integer heroSlot, integer amount returns nothing
        if heroSlot == 0 then
            return
        endif

        if amount < 0 then
            set amount = 0
        endif

        set AP_Points[heroSlot] = amount
    endfunction

    public function Get takes unit whichHero returns integer
        return AP_Points[AP_GetHeroSlot(whichHero)]
    endfunction

    public function Set takes unit whichHero, integer amount returns nothing
        call AP_SetBySlot(AP_GetHeroSlot(whichHero), amount)
    endfunction

    public function Add takes unit whichHero, integer amount returns nothing
        local integer heroSlot = AP_GetHeroSlot(whichHero)

        if heroSlot == 0 or amount == 0 then
            return
        endif

        call AP_SetBySlot(heroSlot, AP_Points[heroSlot] + amount)
        if amount > 0 then
            call AP_ShowPointGainText(whichHero, amount)
        endif
    endfunction

    public function Reduce takes unit whichHero, integer amount returns nothing
        if amount <= 0 then
            return
        endif

        call Add(whichHero, -amount)
    endfunction

    public function Spend takes unit whichHero, integer amount returns boolean
        if amount <= 0 then
            return true
        endif

        if Get(whichHero) < amount then
            return false
        endif

        call Reduce(whichHero, amount)
        return true
    endfunction

    public function SetHeroLevelUpEnabled takes boolean enabled returns nothing
        set AP_HeroLevelUpEnabled = enabled

        if AP_LevelTrigger != null then
            if enabled then
                call EnableTrigger(AP_LevelTrigger)
            else
                call DisableTrigger(AP_LevelTrigger)
            endif
        endif
    endfunction

    public function DisableHeroLevelUp takes nothing returns nothing
        call SetHeroLevelUpEnabled(false)
    endfunction

    public function EnableHeroLevelUp takes nothing returns nothing
        call SetHeroLevelUpEnabled(true)
    endfunction

    public function IsHeroLevelUpEnabled takes nothing returns boolean
        return AP_HeroLevelUpEnabled
    endfunction

    private function AP_StoreQuestRanks takes unit whichHero returns nothing
        local integer entryIndex = 1
        local integer entryCount = AbilitiesPlayer_GetEntryCount()
        local integer currentLevel
        local integer lockedThroughRank

        loop
            exitwhen entryIndex > entryCount
            set currentLevel = GetUnitAbilityLevel(whichHero, AbilitiesPlayer_GetEntryAbilityId(entryIndex))
            set lockedThroughRank = AbilitiesPlayer_GetEntryQuestLockedThroughRank(entryIndex)
            if currentLevel > lockedThroughRank then
                set currentLevel = lockedThroughRank
            endif
            set AP_ResetQuestRank[entryIndex] = currentLevel
            set entryIndex = entryIndex + 1
        endloop
    endfunction

    private function AP_RestoreQuestRanks takes unit whichHero returns nothing
        local integer entryIndex = 1
        local integer entryCount = AbilitiesPlayer_GetEntryCount()
        local integer abilityId
        local integer addAbilityId
        local integer permanentAbilityId
        local integer rank

        loop
            exitwhen entryIndex > entryCount
            set rank = AP_ResetQuestRank[entryIndex]
            if rank > 0 then
                set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
                set addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
                set permanentAbilityId = AbilitiesPlayer_GetEntryPermanentAbilityId(entryIndex)
                if GetUnitAbilityLevel(whichHero, addAbilityId) <= 0 then
                    call UnitAddAbility(whichHero, addAbilityId)
                endif
                call UnitMakeAbilityPermanent(whichHero, true, addAbilityId)
                call UnitMakeAbilityPermanent(whichHero, true, abilityId)
                if permanentAbilityId != 0 and permanentAbilityId != abilityId and permanentAbilityId != addAbilityId then
                    call UnitMakeAbilityPermanent(whichHero, true, permanentAbilityId)
                endif
                if rank > 1 then
                    call SetUnitAbilityLevel(whichHero, abilityId, rank)
                endif
            endif
            set AP_ResetQuestRank[entryIndex] = 0
            set entryIndex = entryIndex + 1
        endloop
    endfunction

    public function ResetHeroAbilities takes unit whichHero returns unit
        local integer heroSlot = AP_GetHeroSlot(whichHero)
        local integer unitTypeId
        local unit replacement = null

        if heroSlot == 0 or whichHero == null then
            return whichHero
        endif

        set unitTypeId = GetUnitTypeId(whichHero)
        call AP_StoreQuestRanks(whichHero)

        static if LIBRARY_DItemTransfer then
            static if LIBRARY_DInventory then
                static if LIBRARY_DEquipment then
                    set udg_DInv_SourceUnit = whichHero
                    call DItemTransfer_StoreSourceUnit()
                endif
            endif
        endif

        set replacement = ReplaceUnitBJ(whichHero, unitTypeId, bj_UNIT_STATE_METHOD_RELATIVE)
        if heroSlot == HERO_NAZGREK then
            set udg_Nazgrek = replacement
        elseif heroSlot == HERO_ZULKIS then
            set udg_Zulkis = replacement
        endif
        call AP_RestoreQuestRanks(replacement)

        static if LIBRARY_DItemTransfer then
            static if LIBRARY_DInventory then
                static if LIBRARY_DEquipment then
                    set udg_DInv_TargetUnit = replacement
                    call InitializeDInventoryForUnit(replacement)
                    call InitializeDEquipmentForUnit(replacement)
                    call DItemTransfer_TransferDItemsGUI()
                endif
            endif
        endif

        call AP_SetBySlot(heroSlot, GetHeroLevel(replacement) + AP_RESET_BONUS_POINTS)

        return replacement
    endfunction

    private function AP_OnHeroLevel takes nothing returns nothing
        local unit levelingHero = GetLevelingUnit()
        local integer heroSlot = AP_GetHeroSlot(levelingHero)

        if AP_HeroLevelUpEnabled and heroSlot != 0 then
            call AP_ShowLevelText(levelingHero)
            call SetUnitState(levelingHero, UNIT_STATE_LIFE, GetUnitState(levelingHero, UNIT_STATE_MAX_LIFE))
            call SetUnitState(levelingHero, UNIT_STATE_MANA, GetUnitState(levelingHero, UNIT_STATE_MAX_MANA))
            call AP_SetBySlot(heroSlot, AP_Points[heroSlot] + 1)
            call AP_ShowPointGainText(levelingHero, 1)
            call AP_SyncCompanionGroupSize()
            static if LIBRARY_HintsUI then
                call HintsUI_PublishForUnit(HintsUI_HINT_ABILITY_POINTS, levelingHero)
            endif
        endif

        set levelingHero = null
    endfunction

    private function AP_OnItemPickup takes nothing returns nothing
        local unit hero = GetTriggerUnit()
        local item manipulatedItem = GetManipulatedItem()

        if manipulatedItem != null and GetItemTypeId(manipulatedItem) == AP_RESET_ITEM_ID then
            call ResetHeroAbilities(hero)
        endif

        set manipulatedItem = null
        set hero = null
    endfunction

    private function AP_OnDebugAdd takes nothing returns nothing
        call AP_SetBySlot(HERO_NAZGREK, AP_Points[HERO_NAZGREK] + AP_DEBUG_ADD_AMOUNT)
        call AP_SetBySlot(HERO_ZULKIS, AP_Points[HERO_ZULKIS] + AP_DEBUG_ADD_AMOUNT)
        call DisplayTextToPlayer(GetTriggerPlayer(), 0.00, 0.00, "|cff00ff00[AbilityPoints]|r Added " + I2S(AP_DEBUG_ADD_AMOUNT) + " ability point to Nazgrek and Zul'kis.")
    endfunction

    private function AP_RegisterLevelEvent takes nothing returns nothing
        set AP_LevelTrigger = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(AP_LevelTrigger, Player(0), EVENT_PLAYER_HERO_LEVEL, null)
        call TriggerAddAction(AP_LevelTrigger, function AP_OnHeroLevel)
        call SetHeroLevelUpEnabled(AP_HeroLevelUpEnabled)
    endfunction

    private function AP_RegisterItemEvents takes nothing returns nothing
        local integer playerIndex = 0

        set AP_ItemTrigger = CreateTrigger()
        loop
            exitwhen playerIndex > AP_MAX_PLAYER_INDEX
            call TriggerRegisterPlayerUnitEvent(AP_ItemTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(AP_ItemTrigger, function AP_OnItemPickup)
    endfunction

    private function AP_RegisterDebugCommands takes nothing returns nothing
        set AP_DebugChatTrigger = CreateTrigger()
        call TriggerRegisterPlayerChatEvent(AP_DebugChatTrigger, Player(0), "/debug ap add", true)
        call TriggerAddAction(AP_DebugChatTrigger, function AP_OnDebugAdd)
    endfunction

    private function Init takes nothing returns nothing
        set AP_Points[HERO_NAZGREK] = AP_INITIAL_POINTS_NAZGREK
        set AP_Points[HERO_ZULKIS] = AP_INITIAL_POINTS_ZULKIS

        call AP_SyncCompanionGroupSize()
        call AP_RegisterLevelEvent()
        call AP_RegisterItemEvents()
        call AP_RegisterDebugCommands()
    endfunction
endlibrary
