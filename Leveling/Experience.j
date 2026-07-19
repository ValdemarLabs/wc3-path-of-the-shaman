/**
    Experience

    Author: Valdemar
    Version:

    Description:
    Centralizes player-hero experience modifiers, rested XP state, and
    item-based bonus XP. Rested remains backed by the existing Rested buff so
    older systems that check the buff continue to work.

    Credits:

    How to install:
    Import after UnitDeathEvent and before systems that call the public API.
    Disable the old GUI triggers under Leveling/_oldGUI/Experience Rested and
    Leveling/_oldGUI/Leveling System/Rested Experience after importing.

    API:
    - call Experience_GrantRested(hero)
    - call Experience_AddRestingProgress(hero, seconds, requiredSeconds)
    - call Experience_ResetRestingProgress(hero)
    - call Experience_AddBonusMultiplier(hero, bonus)
    - call Experience_SetBonusMultiplier(hero, bonus)
    - call Experience_RegisterBonusItem(itemId, bonus)
    - call Experience_ApplyMultiplier(unit, baseAmount)
    - call Experience_SyncHeroXP(hero)
    - if Experience_IsRested(hero) then

**/
library Experience initializer Init requires UnitDeathEvent
    globals
        // Object ids used by the existing rested/warmth object data.
        public constant integer BUFF_RESTED = 'B611'
        public constant integer BUFF_WARMTH = 'B607'

        private constant integer EXP_RESTED_ABILITY_ID = 'A6AI'
        private constant integer EXP_RESTED_DUMMY_ID = 'n63H'
        private constant integer EXP_BONUS_ITEM_CROWN_OF_KINGS = 'ckng'
        private constant integer EXP_MAX_BONUS_ITEMS = 32
        private constant integer EXP_MAX_PLAYER_INDEX = 27

        private constant integer EXP_KEY_BONUS = 1
        private constant integer EXP_KEY_PROGRESS = 2
        private constant integer EXP_KEY_LAST_PROGRESS = 3
        private constant integer EXP_KEY_OLD_HERO_XP = 4
        private constant integer EXP_KEY_SEEN_HERO_XP = 5

        private constant real EXP_RESTED_BONUS = 0.50
        private constant real EXP_DUPLICATE_PROGRESS_WINDOW = 0.75
        private constant real EXP_PROGRESS_BREAK_GRACE = 0.75

        private hashtable EXP_Hash = null
        private timer EXP_GameTimer = null
        private trigger EXP_ItemTrigger = null

        private integer array EXP_BonusItemId
        private real array EXP_BonusItemAmount
        private integer EXP_BonusItemCount = 0
    endglobals

    private function EXP_IsAliveHero takes unit whichUnit returns boolean
        return whichUnit != null and IsUnitType(whichUnit, UNIT_TYPE_HERO) and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function EXP_GetUnitKey takes unit whichUnit returns integer
        if whichUnit == null then
            return 0
        endif
        return GetHandleId(whichUnit)
    endfunction

    private function EXP_GetNow takes nothing returns real
        return TimerGetElapsed(EXP_GameTimer)
    endfunction

    private function EXP_GetRegisteredItemBonus takes integer itemTypeId returns real
        local integer i = 0

        loop
            exitwhen i >= EXP_BonusItemCount
            if EXP_BonusItemId[i] == itemTypeId then
                return EXP_BonusItemAmount[i]
            endif
            set i = i + 1
        endloop

        return 0.00
    endfunction

    public function IsRested takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitAbilityLevel(whichUnit, BUFF_RESTED) > 0
    endfunction

    public function GetBonusMultiplier takes unit whichUnit returns real
        local integer key = EXP_GetUnitKey(whichUnit)

        if key == 0 or not HaveSavedReal(EXP_Hash, key, EXP_KEY_BONUS) then
            return 0.00
        endif

        return LoadReal(EXP_Hash, key, EXP_KEY_BONUS)
    endfunction

    public function GetTotalMultiplier takes unit whichUnit returns real
        local real multiplier = 1.00 + GetBonusMultiplier(whichUnit)

        if IsRested(whichUnit) then
            set multiplier = multiplier + EXP_RESTED_BONUS
        endif

        if multiplier < 0.00 then
            return 0.00
        endif

        return multiplier
    endfunction

    private function EXP_SyncLegacyMultiplier takes unit whichUnit returns nothing
        local integer customValue = 0

        if whichUnit != null then
            set customValue = GetUnitUserData(whichUnit)
            if customValue > 0 then
                set udg_XP_ExpMultiplier[customValue] = GetTotalMultiplier(whichUnit)
            endif
        endif
    endfunction

    public function SetBonusMultiplier takes unit whichUnit, real bonus returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)

        if key == 0 then
            return
        endif

        call SaveReal(EXP_Hash, key, EXP_KEY_BONUS, bonus)
        call EXP_SyncLegacyMultiplier(whichUnit)
    endfunction

    public function AddBonusMultiplier takes unit whichUnit, real bonus returns nothing
        call SetBonusMultiplier(whichUnit, GetBonusMultiplier(whichUnit) + bonus)
    endfunction

    public function RegisterBonusItem takes integer itemTypeId, real bonus returns nothing
        local integer i = 0

        loop
            exitwhen i >= EXP_BonusItemCount
            if EXP_BonusItemId[i] == itemTypeId then
                set EXP_BonusItemAmount[i] = bonus
                return
            endif
            set i = i + 1
        endloop

        if EXP_BonusItemCount < EXP_MAX_BONUS_ITEMS then
            set EXP_BonusItemId[EXP_BonusItemCount] = itemTypeId
            set EXP_BonusItemAmount[EXP_BonusItemCount] = bonus
            set EXP_BonusItemCount = EXP_BonusItemCount + 1
        endif
    endfunction

    public function ApplyMultiplier takes unit whichUnit, integer baseAmount returns integer
        local real amount

        if baseAmount <= 0 then
            return 0
        endif

        set amount = I2R(baseAmount) * GetTotalMultiplier(whichUnit)
        return R2I(amount + 0.50)
    endfunction

    public function ResetRestingProgress takes unit whichUnit returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)

        if key == 0 then
            return
        endif

        call RemoveSavedReal(EXP_Hash, key, EXP_KEY_PROGRESS)
        call RemoveSavedReal(EXP_Hash, key, EXP_KEY_LAST_PROGRESS)
    endfunction

    public function GrantRested takes unit whichUnit returns nothing
        local unit dummy = null

        if not EXP_IsAliveHero(whichUnit) or IsRested(whichUnit) then
            return
        endif

        set dummy = CreateUnit(GetOwningPlayer(whichUnit), EXP_RESTED_DUMMY_ID, GetUnitX(whichUnit), GetUnitY(whichUnit), 0.00)
        call UnitAddAbility(dummy, EXP_RESTED_ABILITY_ID)
        call UnitApplyTimedLife(dummy, 'BTLF', 1.00)
        call IssueTargetOrder(dummy, "acidbomb", whichUnit)
        call DisplayTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, "|cffffcc00" + GetHeroProperName(whichUnit) + "|r is now |cff00ff00Rested|r.")
        call ResetRestingProgress(whichUnit)
        call EXP_SyncLegacyMultiplier(whichUnit)

        set dummy = null
    endfunction

    public function AddRestingProgress takes unit whichUnit, real seconds, real requiredSeconds returns boolean
        local integer key = EXP_GetUnitKey(whichUnit)
        local real now
        local real last
        local real progress

        if key == 0 or not EXP_IsAliveHero(whichUnit) or IsRested(whichUnit) then
            return false
        endif

        set now = EXP_GetNow()
        if HaveSavedReal(EXP_Hash, key, EXP_KEY_LAST_PROGRESS) then
            set last = LoadReal(EXP_Hash, key, EXP_KEY_LAST_PROGRESS)
            if now - last < EXP_DUPLICATE_PROGRESS_WINDOW then
                return false
            endif
            if now - last > seconds + EXP_PROGRESS_BREAK_GRACE then
                set progress = 0.00
            else
                set progress = LoadReal(EXP_Hash, key, EXP_KEY_PROGRESS)
            endif
        else
            set progress = 0.00
        endif

        set progress = progress + seconds
        call SaveReal(EXP_Hash, key, EXP_KEY_PROGRESS, progress)
        call SaveReal(EXP_Hash, key, EXP_KEY_LAST_PROGRESS, now)

        if progress >= requiredSeconds then
            call GrantRested(whichUnit)
            return true
        endif

        return false
    endfunction

    public function SyncHeroXP takes unit whichHero returns nothing
        local integer key = EXP_GetUnitKey(whichHero)

        if key == 0 or not IsUnitType(whichHero, UNIT_TYPE_HERO) then
            return
        endif

        call SaveInteger(EXP_Hash, key, EXP_KEY_OLD_HERO_XP, GetHeroXP(whichHero))
        call SaveInteger(EXP_Hash, key, EXP_KEY_SEEN_HERO_XP, 1)
    endfunction

    private function EXP_ApplyHeroBonusFromCurrentXP takes unit whichHero returns nothing
        local integer key = EXP_GetUnitKey(whichHero)
        local integer oldXp
        local integer currentXp
        local integer baseGain
        local integer extraGain
        local real extraMultiplier

        if key == 0 or not EXP_IsAliveHero(whichHero) then
            return
        endif

        set currentXp = GetHeroXP(whichHero)
        if not HaveSavedInteger(EXP_Hash, key, EXP_KEY_SEEN_HERO_XP) then
            call SyncHeroXP(whichHero)
            return
        endif

        set oldXp = LoadInteger(EXP_Hash, key, EXP_KEY_OLD_HERO_XP)
        if currentXp > oldXp then
            set baseGain = currentXp - oldXp
            set extraMultiplier = GetTotalMultiplier(whichHero) - 1.00
            if extraMultiplier > 0.00 then
                set extraGain = R2I(I2R(baseGain) * extraMultiplier + 0.50)
                if extraGain > 0 then
                    call AddHeroXP(whichHero, extraGain, true)
                    call DisplayTextToPlayer(GetOwningPlayer(whichHero), 0.00, 0.00, "|cff7ebff1Bonus XP:|r " + I2S(extraGain))
                    set currentXp = GetHeroXP(whichHero)
                endif
            endif
        endif

        call SaveInteger(EXP_Hash, key, EXP_KEY_OLD_HERO_XP, currentXp)
    endfunction

    private function EXP_OnDeath takes nothing returns nothing
        if udg_InCinematic then
            return
        endif

        call EXP_ApplyHeroBonusFromCurrentXP(udg_Nazgrek)
        call EXP_ApplyHeroBonusFromCurrentXP(udg_Zulkis)
    endfunction

    private function EXP_OnItemEvent takes nothing returns nothing
        local unit hero = GetTriggerUnit()
        local item manipulatedItem = GetManipulatedItem()
        local real bonus = 0.00

        if hero != null and manipulatedItem != null then
            set bonus = EXP_GetRegisteredItemBonus(GetItemTypeId(manipulatedItem))
            if bonus != 0.00 then
                if GetTriggerEventId() == EVENT_PLAYER_UNIT_PICKUP_ITEM then
                    call AddBonusMultiplier(hero, bonus)
                elseif GetTriggerEventId() == EVENT_PLAYER_UNIT_DROP_ITEM then
                    call AddBonusMultiplier(hero, -bonus)
                endif
            endif
        endif

        set manipulatedItem = null
        set hero = null
    endfunction

    private function EXP_DelayedStart takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call SyncHeroXP(udg_Nazgrek)
        call SyncHeroXP(udg_Zulkis)
        call UnitDeathEvent_Register(function EXP_OnDeath)

        call PauseTimer(expiredTimer)
        call DestroyTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function EXP_RegisterItemEvents takes nothing returns nothing
        local integer playerIndex = 0

        set EXP_ItemTrigger = CreateTrigger()
        loop
            exitwhen playerIndex > EXP_MAX_PLAYER_INDEX
            call TriggerRegisterPlayerUnitEvent(EXP_ItemTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
            call TriggerRegisterPlayerUnitEvent(EXP_ItemTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DROP_ITEM, null)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(EXP_ItemTrigger, function EXP_OnItemEvent)
    endfunction

    private function Init takes nothing returns nothing
        local timer startTimer = CreateTimer()

        set EXP_Hash = InitHashtable()
        set EXP_GameTimer = CreateTimer()
        call TimerStart(EXP_GameTimer, 999999.00, false, null)

        call RegisterBonusItem(EXP_BONUS_ITEM_CROWN_OF_KINGS, 0.25)
        call EXP_RegisterItemEvents()

        call TimerStart(startTimer, 5.00, false, function EXP_DelayedStart)
        set startTimer = null
    endfunction
endlibrary
