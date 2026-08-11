/**
    DragonBehavior

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements shared red/scorching dragon combat animations, opportunistic
    spell casts, and reusable ambient dragon sounds.

    Credits:
    - World/_oldGUI/Dragons

    How to install:
    Import after the map sound globals. Disable Dragon or Drake Melee Attack,
    Scorching Dragon or Drake Cast, and Dragon Sounds GUI triggers.

    API:
    - DragonBehavior_IsDragonType(unitTypeId) returns boolean
    - DragonBehavior_TryPlayAmbientSound(whichUnit, audienceRect)

**/
library DragonBehavior initializer Init
    globals
        private constant integer UNIT_RED_DRAKE_10 = 'n63G'
        private constant integer UNIT_RED_DRAGON_10 = 'n644'
        private constant integer UNIT_RED_DRAGON_20 = 'n65B'
        private constant integer UNIT_SCORCHING_DRAKE_10 = 'n63D'
        private constant integer UNIT_SCORCHING_DRAGON_10 = 'n63F'
        private constant integer UNIT_SCORCHING_DRAGON_20 = 'n656'
        private constant integer UNIT_MORDRAX = 'n645'

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

    private function HasAudience takes rect audienceRect returns boolean
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
            if IsAlive(picked) and IsPlayerInForce(GetOwningPlayer(picked), udg_PlayerGroup) then
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

        if not IsAlive(whichUnit) or not HasAudience(audienceRect) or GetRandomInt(1, 8) != 1 then
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
