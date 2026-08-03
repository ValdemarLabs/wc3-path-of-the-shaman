/**
    Experience

    Author: Valdemar
    Version:

    Description:
    Centralizes player-hero experience modifiers, rested XP state, and
    item-based bonus XP. Rested is represented by a hidden unit ability so it
    does not trigger combat through Acid Bomb damage events.

    Credits:

    How to install:
    Import after Events and UnitDeathEvent, before systems that call the public API.
    Disable the old GUI triggers under Leveling/_oldGUI/Experience Rested and
    Leveling/_oldGUI/Leveling System/Rested Experience after importing.

    API:
    - call Experience_GrantRested(hero)
    - call Experience_GrantRestedTimed(hero, duration)
    - call Experience_ClearRested(hero)
    - set seconds = Experience_GetRestedRemaining(hero)
    - call Experience_AddRestingProgress(hero, seconds, requiredSeconds)
    - call Experience_ResetRestingProgress(hero)
    - call Experience_AddBonusMultiplier(hero, bonus)
    - call Experience_SetBonusMultiplier(hero, bonus)
    - call Experience_RegisterBonusItem(itemId, bonus)
    - call Experience_ApplyMultiplier(unit, baseAmount)
    - call Experience_SyncHeroXP(hero)
    - if Experience_IsRested(hero) then

**/
library Experience initializer Init requires Events, UnitDeathEvent, FallenHeroState
    globals
        // Rested is a hidden aura ability added directly to the hero.
        // UnitAddAbility/UnitRemoveAbility need this ability rawcode, not the generated buff rawcode.
        public constant integer RESTED_ABILITY_ID = 'S000'
        // Warmth remains a buff rawcode because camp-fire systems only check aura status.
        public constant integer BUFF_WARMTH = 'B607'

        private constant integer EXP_BONUS_ITEM_CROWN_OF_KINGS = 'ckng'
        private constant integer EXP_MAX_BONUS_ITEMS = 32
        private constant integer EXP_KEY_BONUS = 1
        private constant integer EXP_KEY_PROGRESS = 2
        private constant integer EXP_KEY_LAST_PROGRESS = 3
        private constant integer EXP_KEY_OLD_HERO_XP = 4
        private constant integer EXP_KEY_SEEN_HERO_XP = 5
        private constant integer EXP_KEY_RESTED_EXPIRES = 6
        private constant integer EXP_KEY_RESTED_TIMER = 7
        private constant integer EXP_KEY_RESTED_TIMER_HERO = 8

        private constant real EXP_RESTED_BONUS = 0.50
        private constant real EXP_RESTED_DURATION = 300.00
        private constant real EXP_DUPLICATE_PROGRESS_WINDOW = 0.75
        private constant real EXP_PROGRESS_BREAK_GRACE = 0.75
        private constant real EXP_BONUS_TEXT_Y_OFFSET = 64.00
        private constant real EXP_BONUS_TEXT_Z_OFFSET = 96.00
        private constant real EXP_BONUS_TEXT_SIZE = 0.021
        private constant real EXP_BONUS_TEXT_LIFESPAN = 1.30
        private constant real EXP_BONUS_TEXT_FADEPOINT = 0.90

        private hashtable EXP_Hash = null
        private timer EXP_GameTimer = null
        private integer array EXP_BonusItemId
        private real array EXP_BonusItemAmount
        private integer EXP_BonusItemCount = 0
    endglobals

    private function EXP_IsAliveHero takes unit whichUnit returns boolean
        return FallenHeroState_IsAlive(whichUnit) and IsUnitType(whichUnit, UNIT_TYPE_HERO)
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

    private function EXP_HasRestedAbility takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitAbilityLevel(whichUnit, RESTED_ABILITY_ID) > 0
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
        return EXP_HasRestedAbility(whichUnit)
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

    public function SetBonusMultiplier takes unit whichUnit, real bonus returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)

        if key == 0 then
            return
        endif

        call SaveReal(EXP_Hash, key, EXP_KEY_BONUS, bonus)
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

    private function EXP_MarkRested takes unit whichUnit returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)

        if key == 0 then
            return
        endif

        call ResetRestingProgress(whichUnit)
    endfunction

    public function ClearRested takes unit whichUnit returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)
        local timer restedTimer = null

        if key == 0 then
            return
        endif

        set restedTimer = LoadTimerHandle(EXP_Hash, key, EXP_KEY_RESTED_TIMER)
        if restedTimer != null then
            call FlushChildHashtable(EXP_Hash, GetHandleId(restedTimer))
            call PauseTimer(restedTimer)
            call DestroyTimer(restedTimer)
            call RemoveSavedHandle(EXP_Hash, key, EXP_KEY_RESTED_TIMER)
        endif

        if EXP_HasRestedAbility(whichUnit) then
            call UnitRemoveAbility(whichUnit, RESTED_ABILITY_ID)
        endif

        call RemoveSavedReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES)

        set restedTimer = null
    endfunction

    public function GetRestedRemaining takes unit whichUnit returns real
        local integer key = EXP_GetUnitKey(whichUnit)
        local real remaining

        if key == 0 or not EXP_HasRestedAbility(whichUnit) or not HaveSavedReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES) then
            return 0.00
        endif

        set remaining = LoadReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES) - EXP_GetNow()
        if remaining < 0.00 then
            return 0.00
        endif

        return remaining
    endfunction

    private function EXP_OnRestedExpired takes nothing returns nothing
        local timer expired = GetExpiredTimer()
        local integer timerKey = GetHandleId(expired)
        local unit hero = LoadUnitHandle(EXP_Hash, timerKey, EXP_KEY_RESTED_TIMER_HERO)
        local integer heroKey = EXP_GetUnitKey(hero)
        local timer savedTimer = null

        if heroKey != 0 and HaveSavedReal(EXP_Hash, heroKey, EXP_KEY_RESTED_EXPIRES) and EXP_GetNow() >= LoadReal(EXP_Hash, heroKey, EXP_KEY_RESTED_EXPIRES) - 0.05 then
            call ClearRested(hero)
        else
            if heroKey != 0 then
                set savedTimer = LoadTimerHandle(EXP_Hash, heroKey, EXP_KEY_RESTED_TIMER)
                if savedTimer == expired then
                    call RemoveSavedHandle(EXP_Hash, heroKey, EXP_KEY_RESTED_TIMER)
                endif
            endif
            call FlushChildHashtable(EXP_Hash, timerKey)
            call PauseTimer(expired)
            call DestroyTimer(expired)
        endif

        set savedTimer = null
        set hero = null
        set expired = null
    endfunction

    public function GrantRestedTimed takes unit whichUnit, real duration returns nothing
        local integer key = EXP_GetUnitKey(whichUnit)
        local timer restedTimer = null
        local boolean alreadyRested
        local real now
        local real expires

        if key == 0 or not EXP_IsAliveHero(whichUnit) or duration <= 0.00 then
            return
        endif

        set now = EXP_GetNow()
        set expires = now + duration
        set alreadyRested = EXP_HasRestedAbility(whichUnit)
        if not alreadyRested and not UnitAddAbility(whichUnit, RESTED_ABILITY_ID) then
            return
        endif

        if alreadyRested and HaveSavedReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES) and LoadReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES) > expires then
            set expires = LoadReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES)
            set duration = expires - now
        endif

        call BlzUnitHideAbility(whichUnit, RESTED_ABILITY_ID, true)
        call SaveReal(EXP_Hash, key, EXP_KEY_RESTED_EXPIRES, expires)
        call EXP_MarkRested(whichUnit)

        set restedTimer = LoadTimerHandle(EXP_Hash, key, EXP_KEY_RESTED_TIMER)
        if restedTimer == null then
            set restedTimer = CreateTimer()
            call SaveTimerHandle(EXP_Hash, key, EXP_KEY_RESTED_TIMER, restedTimer)
        endif
        call SaveUnitHandle(EXP_Hash, GetHandleId(restedTimer), EXP_KEY_RESTED_TIMER_HERO, whichUnit)
        call TimerStart(restedTimer, duration, false, function EXP_OnRestedExpired)

        if not alreadyRested then
            call DisplayTextToPlayer(GetOwningPlayer(whichUnit), 0.00, 0.00, "|cffffcc00" + GetHeroProperName(whichUnit) + "|r is now |cff00ff00Rested|r.")
        endif

        set restedTimer = null
    endfunction

    public function GrantRested takes unit whichUnit returns nothing
        call GrantRestedTimed(whichUnit, EXP_RESTED_DURATION)
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

    private function EXP_ShowBonusXPText takes unit whichHero, integer amount returns nothing
        local texttag tag = null
        local player owner = null

        if whichHero == null or amount <= 0 then
            return
        endif

        set owner = GetOwningPlayer(whichHero)
        set tag = CreateTextTag()
        call SetTextTagPermanent(tag, false)
        call SetTextTagLifespan(tag, EXP_BONUS_TEXT_LIFESPAN)
        call SetTextTagFadepoint(tag, EXP_BONUS_TEXT_FADEPOINT)
        call SetTextTagText(tag, "|cff7ebff1+" + I2S(amount) + " Bonus XP|r", EXP_BONUS_TEXT_SIZE)
        call SetTextTagPos(tag, GetUnitX(whichHero), GetUnitY(whichHero) + EXP_BONUS_TEXT_Y_OFFSET, EXP_BONUS_TEXT_Z_OFFSET)
        call SetTextTagColor(tag, 126, 191, 241, 255)
        call SetTextTagVelocity(tag, 0.00, 0.035)

        if GetLocalPlayer() == owner then
            call SetTextTagVisibility(tag, true)
        else
            call SetTextTagVisibility(tag, false)
        endif

        set owner = null
        set tag = null
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
                    call AddHeroXP(whichHero, extraGain, false)
                    call EXP_ShowBonusXPText(whichHero, extraGain)
                    set currentXp = GetHeroXP(whichHero)
                endif
            endif
        endif

        call SaveInteger(EXP_Hash, key, EXP_KEY_OLD_HERO_XP, currentXp)
    endfunction

    private function EXP_OnDeath takes nothing returns nothing
        local unit dying = UnitDeathEvent_GetDyingUnit()

        if IsRested(dying) then
            call ClearRested(dying)
        endif

        if not udg_InCinematic then
            call EXP_ApplyHeroBonusFromCurrentXP(udg_Nazgrek)
            call EXP_ApplyHeroBonusFromCurrentXP(udg_Zulkis)
        endif

        set dying = null
    endfunction

    private function EXP_ApplyItemBonus takes real multiplier returns nothing
        local unit hero = GetTriggerUnit()
        local item manipulatedItem = GetManipulatedItem()
        local real bonus = 0.00

        if hero != null and manipulatedItem != null then
            set bonus = EXP_GetRegisteredItemBonus(GetItemTypeId(manipulatedItem))
            if bonus != 0.00 then
                call AddBonusMultiplier(hero, bonus * multiplier)
            endif
        endif

        set manipulatedItem = null
        set hero = null
    endfunction

    private function EXP_OnItemPickup takes nothing returns nothing
        call EXP_ApplyItemBonus(1.00)
    endfunction

    private function EXP_OnItemDrop takes nothing returns nothing
        call EXP_ApplyItemBonus(-1.00)
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
        call Events_RegisterPlayerUnitEvent(function EXP_OnItemPickup, EVENT_PLAYER_UNIT_PICKUP_ITEM)
        call Events_RegisterPlayerUnitEvent(function EXP_OnItemDrop, EVENT_PLAYER_UNIT_DROP_ITEM)
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
