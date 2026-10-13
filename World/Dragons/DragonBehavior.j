/**
    DragonBehavior

    Author: Valdemar
    Version: 1.2.0

    Description:
    Implements shared red/scorching dragon combat animations, opportunistic
    spell casts, high-dragon ambient Flame Strike targeting, and reusable
    ambient dragon sounds.

    Credits:
    - World/_oldGUI/Dragons

    How to install:
    Import after the map sound globals. Disable Dragon or Drake Melee Attack,
    Scorching Dragon or Drake Cast, and Dragon Sounds GUI triggers.

    API:
    - DragonBehavior_IsDragonType(unitTypeId) returns boolean
    - DragonBehavior_IsAudienceHero(whichUnit) returns boolean
    - DragonBehavior_HasAudience(audienceRect) returns boolean
    - DragonBehavior_TryAmbientFlameStrike(dragon, areaRect, targetRadius, randomRadius) returns boolean
    - DragonBehavior_TryPlayAmbientSound(whichUnit, audienceRect)

**/
library DragonBehavior initializer Init requires optional AI
    globals
        private constant integer UNIT_RED_DRAKE_10 = 'n63G'
        private constant integer UNIT_RED_DRAGON_10 = 'n644'
        private constant integer UNIT_RED_DRAGON_20 = 'n65B'
        private constant integer UNIT_SCORCHING_DRAKE_10 = 'n63D'
        private constant integer UNIT_SCORCHING_DRAGON_10 = 'n63F'
        private constant integer UNIT_SCORCHING_DRAGON_20 = 'n656'
        private constant integer UNIT_MORDRAX = 'n645'
        private constant integer ABILITY_HIGH_DRAGON_FLAME_STRIKE = 'A6CO'

        private trigger AttackedTrigger = null
        private group SearchGroup = null
        private group TargetGroup = null
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function IsRedMeleeType takes integer unitTypeId returns boolean
        return unitTypeId == UNIT_RED_DRAKE_10 or unitTypeId == UNIT_RED_DRAGON_10 or unitTypeId == UNIT_RED_DRAGON_20 or unitTypeId == UNIT_MORDRAX
    endfunction

    private function IsScorchingType takes integer unitTypeId returns boolean
        return unitTypeId == UNIT_SCORCHING_DRAKE_10 or unitTypeId == UNIT_SCORCHING_DRAGON_10 or unitTypeId == UNIT_SCORCHING_DRAGON_20 or unitTypeId == UNIT_MORDRAX
    endfunction

    public function IsDragonType takes integer unitTypeId returns boolean
        return IsRedMeleeType(unitTypeId) or IsScorchingType(unitTypeId) or unitTypeId == 'n647'
    endfunction

    public function IsAudienceHero takes unit whichUnit returns boolean
        if not IsAlive(whichUnit) or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            return false
        endif
        if IsPlayerInForce(GetOwningPlayer(whichUnit), udg_PlayerGroup) then
            return true
        endif
        static if LIBRARY_AI then
            return AI_IsAlive(whichUnit) and AI_IsUnitHiderRevealer(whichUnit)
        endif
        return false
    endfunction

    public function HasAudience takes rect audienceRect returns boolean
        local unit picked = null
        local boolean found = false

        if audienceRect == null then
            return true
        endif
        call GroupClear(SearchGroup)
        call GroupEnumUnitsInRect(SearchGroup, audienceRect, null)
        loop
            set picked = FirstOfGroup(SearchGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SearchGroup, picked)
            if IsAudienceHero(picked) then
                set found = true
                exitwhen true
            endif
        endloop
        call GroupClear(SearchGroup)
        set picked = null
        return found
    endfunction

    public function TryPlayAmbientSound takes unit whichUnit, rect audienceRect returns nothing
        local integer line

        if not IsAlive(whichUnit) or not DragonBehavior_HasAudience(audienceRect) or GetRandomInt(1, 8) != 1 then
            return
        endif
        set line = GetRandomInt(1, 6)
        if line == 1 then
            call PlaySoundOnUnitBJ(gg_snd_DragonWhat1, 100.00, whichUnit)
        elseif line == 2 then
            call PlaySoundOnUnitBJ(gg_snd_DragonYes1, 100.00, whichUnit)
        elseif line == 3 then
            call PlaySoundOnUnitBJ(gg_snd_DragonYes2, 100.00, whichUnit)
        elseif line == 4 then
            call PlaySoundOnUnitBJ(gg_snd_DragonYes3, 100.00, whichUnit)
        elseif line == 5 then
            call PlaySoundOnUnitBJ(gg_snd_DragonYesAttack2, 100.00, whichUnit)
        else
            call PlaySoundOnUnitBJ(gg_snd_DragonYesAttack3, 100.00, whichUnit)
        endif
    endfunction

    private function IsAmbientFlameStrikeTarget takes unit dragon, unit target, rect areaRect returns boolean
        if target == dragon or not IsAlive(target) or IsDragonType(GetUnitTypeId(target)) or GetUnitAbilityLevel(target, 'Aloc') > 0 or not RectContainsUnit(areaRect, target) then
            return false
        endif
        return IsPlayerInForce(GetOwningPlayer(target), udg_PlayerGroup) or IsAudienceHero(target) or IsUnitEnemy(target, GetOwningPlayer(dragon))
    endfunction

    public function TryAmbientFlameStrike takes unit dragon, rect areaRect, real targetRadius, real randomRadius returns boolean
        local unit picked = null
        local unit target = null
        local real angle
        local real distance
        local real x
        local real y

        if not IsAlive(dragon) or areaRect == null or GetUnitAbilityLevel(dragon, ABILITY_HIGH_DRAGON_FLAME_STRIKE) <= 0 then
            return false
        endif
        call GroupClear(SearchGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRange(SearchGroup, GetUnitX(dragon), GetUnitY(dragon), targetRadius, null)
        loop
            set picked = FirstOfGroup(SearchGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SearchGroup, picked)
            if IsAmbientFlameStrikeTarget(dragon, picked, areaRect) then
                call GroupAddUnit(TargetGroup, picked)
            endif
        endloop
        if BlzGroupGetSize(TargetGroup) > 0 and GetRandomInt(1, 2) == 1 then
            set target = GroupPickRandomUnit(TargetGroup)
            set x = GetUnitX(target)
            set y = GetUnitY(target)
        else
            set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
            set distance = GetRandomReal(250.00, randomRadius)
            set x = GetUnitX(dragon) + distance * Cos(angle)
            set y = GetUnitY(dragon) + distance * Sin(angle)
            if x < GetRectMinX(areaRect) then
                set x = GetRectMinX(areaRect)
            elseif x > GetRectMaxX(areaRect) then
                set x = GetRectMaxX(areaRect)
            endif
            if y < GetRectMinY(areaRect) then
                set y = GetRectMinY(areaRect)
            elseif y > GetRectMaxY(areaRect) then
                set y = GetRectMaxY(areaRect)
            endif
        endif
        call GroupClear(TargetGroup)
        set picked = null
        set target = null
        return IssuePointOrder(dragon, "flamestrike", x, y)
    endfunction

    private function PickRandomEnemy takes unit dragon, real radius returns unit
        local unit picked = null
        local unit target = null

        call GroupClear(SearchGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRange(SearchGroup, GetUnitX(dragon), GetUnitY(dragon), radius, null)
        loop
            set picked = FirstOfGroup(SearchGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SearchGroup, picked)
            if IsAlive(picked) and IsUnitEnemy(picked, GetOwningPlayer(dragon)) then
                call GroupAddUnit(TargetGroup, picked)
            endif
        endloop
        set target = GroupPickRandomUnit(TargetGroup)
        call GroupClear(TargetGroup)
        set picked = null
        return target
    endfunction

    private function OnUnitAttacked takes nothing returns nothing
        local unit attacked = GetTriggerUnit()
        local unit attacker = GetAttacker()
        local unit target = null

        if IsAlive(attacker) and IsRedMeleeType(GetUnitTypeId(attacker)) then
            call SetUnitAnimation(attacker, "spell devour")
            call QueueUnitAnimation(attacker, "stand")
        endif
        if IsAlive(attacked) and IsScorchingType(GetUnitTypeId(attacked)) then
            if IsAlive(attacker) and GetRandomInt(1, 5) == 1 then
                call IssuePointOrder(attacked, "breathoffire", GetUnitX(attacker), GetUnitY(attacker))
            endif
            if GetRandomInt(1, 5) == 2 then
                set target = PickRandomEnemy(attacked, 800.00)
                if target != null then
                    call IssuePointOrder(attacked, "flamestrike", GetUnitX(target), GetUnitY(target))
                endif
            endif
        endif
        set target = null
        set attacker = null
        set attacked = null
    endfunction

    private function Init takes nothing returns nothing
        local integer playerId = 0

        set SearchGroup = CreateGroup()
        set TargetGroup = CreateGroup()
        set AttackedTrigger = CreateTrigger()
        loop
            exitwhen playerId > 23
            call TriggerRegisterPlayerUnitEvent(AttackedTrigger, Player(playerId), EVENT_PLAYER_UNIT_ATTACKED, null)
            set playerId = playerId + 1
        endloop
        call TriggerAddAction(AttackedTrigger, function OnUnitAttacked)
    endfunction
endlibrary
