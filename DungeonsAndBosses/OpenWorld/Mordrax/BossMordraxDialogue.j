/**
    BossMordraxDialogue

    Author: Valdemar
    Version: 1.0.0

    Description:
    Replaces Mordrax's start, combat-order, spell, low-health, and defeat
    voice triggers using ExSound with synchronized subtitles and cooldowns.

    Credits:
    - Legacy Mordrax Chat GUI triggers

    How to install:
    Import before BossMordrax with ExSound, RangeCheck, and DamageEngine.

    API:
    - call BossMordraxDialogue_Bind(whichUnit)
    - call BossMordraxDialogue_PlayStart()
    - call BossMordraxDialogue_PlayDeath()
    - call BossMordraxDialogue_SetEnabled(enabled)

**/
library BossMordraxDialogue initializer Init requires ExSound, RangeCheck, DamageEngine, UnitDeathEvent
    globals
        private unit BossUnit = null
        private timer VoiceTimer = null
        private trigger SpellTrigger = null
        private trigger OrderTrigger = null
        private boolean Enabled = false
        private boolean LowHealthPlayed = false
    endglobals

    private function CooldownExpired takes nothing returns nothing
    endfunction

    private function CanSpeak takes nothing returns boolean
        return Enabled and BossUnit != null and GetUnitTypeId(BossUnit) != 0 and GetWidgetLife(BossUnit) > 0.405 and TimerGetRemaining(VoiceTimer) <= 0.00 and RangeCheck_Unit(BossUnit, Player(0)) < 1500.00 and not udg_InCinematic
    endfunction

    private function Play takes string soundKey, string text, real cooldown returns nothing
        call ExSound_Play(soundKey, text)
        call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, udg_ExSoundDuration, "|cffff6600Mordrax:|r " + text)
        call TimerStart(VoiceTimer, udg_ExSoundDuration + cooldown, false, function CooldownExpired)
    endfunction

    public function PlayStart takes nothing returns nothing
        if CanSpeak() then
            call Play("Mordrax_0001", "Who dares to challenge mighty Mordrax?!", 3.00)
        endif
    endfunction

    public function PlayDeath takes nothing returns nothing
        if BossUnit != null and RangeCheck_Unit(BossUnit, Player(0)) < 1500.00 then
            call Play("Mordrax_0010", "I have failed... my Queen...", 3.00)
        endif
    endfunction

    private function OnOrder takes nothing returns nothing
        local integer line
        local integer orderId = GetIssuedOrderId()

        if GetTriggerUnit() == BossUnit and (orderId == OrderId("attack") or orderId == OrderId("smart")) and CanSpeak() then
            set line = GetRandomInt(1, 3)
            if line == 1 then
                call Play("Mordrax_0002", "The skies shall burn by my wrath!", 10.00)
            elseif line == 2 then
                call Play("Mordrax_0003", "I will destroy you!", 10.00)
            else
                call Play("Mordrax_0004", "Pathetic weaklings!", 10.00)
            endif
        endif
    endfunction

    private function OnSpell takes nothing returns nothing
        if GetTriggerUnit() == BossUnit and CanSpeak() then
            if GetRandomInt(1, 2) == 1 then
                call Play("Mordrax_0005", "Everything shall burn!", 6.00)
            else
                call Play("Mordrax_0006", "I will turn you to cinder!", 6.00)
            endif
        endif
    endfunction

    private function OnDamage takes nothing returns nothing
        if not LowHealthPlayed and udg_DamageEventTarget == BossUnit and GetWidgetLife(BossUnit) <= GetUnitState(BossUnit, UNIT_STATE_MAX_LIFE) * 0.25 and CanSpeak() then
            set LowHealthPlayed = true
            call Play("Mordrax_0009", "No... I have endured for centuries - I will not fall!", 3.00)
        endif
    endfunction

    private function OnUnitDeath takes nothing returns nothing
        local unit dyingUnit = UnitDeathEvent_GetDyingUnit()

        if dyingUnit != null and GetUnitAbilityLevel(dyingUnit, 'Aloc') == 0 and (GetOwningPlayer(dyingUnit) == Player(0) or IsUnitInGroup(dyingUnit, udg_Companion_Group)) and CanSpeak() then
            if GetRandomInt(1, 2) == 1 then
                call Play("Mordrax_0007", "You are entertaining.", 3.00)
            else
                call Play("Mordrax_0008", "How amusing.", 3.00)
            endif
        endif
        set dyingUnit = null
    endfunction

    public function Bind takes unit whichUnit returns nothing
        set BossUnit = whichUnit
        set LowHealthPlayed = false
    endfunction

    public function SetEnabled takes boolean enabled returns nothing
        set Enabled = enabled
        if not enabled then
            call PauseTimer(VoiceTimer)
        endif
    endfunction

    private function Init takes nothing returns nothing
        local integer playerId = 0
        set VoiceTimer = CreateTimer()
        set SpellTrigger = CreateTrigger()
        set OrderTrigger = CreateTrigger()
        loop
            exitwhen playerId > 23
            call TriggerRegisterPlayerUnitEvent(SpellTrigger, Player(playerId), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
            call TriggerRegisterPlayerUnitEvent(OrderTrigger, Player(playerId), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, null)
            set playerId = playerId + 1
        endloop
        call TriggerAddAction(SpellTrigger, function OnSpell)
        call TriggerAddAction(OrderTrigger, function OnOrder)
        call RegisterDamageEngine(function OnDamage, "Modifier", 1.00)
        call UnitDeathEvent_Register(function OnUnitDeath)
    endfunction
endlibrary
