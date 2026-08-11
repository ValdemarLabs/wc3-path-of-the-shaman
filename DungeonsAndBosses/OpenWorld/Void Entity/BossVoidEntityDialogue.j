/**
    BossVoidEntityDialogue

    Author: Valdemar
    Version: 1.0.0

    Description:
    Replaces the Void Entity combat voice triggers with synchronized ExSound
    playback, subtitles, cooldowns, range checks, spell lines, and low-health
    lines.

    Credits:
    - Legacy Void Entity Chat GUI triggers

    How to install:
    Import before BossVoidEntity with ExSound, RangeCheck, and DamageEngine.

    API:
    - call BossVoidEntityDialogue_Bind(whichUnit)
    - call BossVoidEntityDialogue_PlayStart()
    - call BossVoidEntityDialogue_PlayDeath()
    - call BossVoidEntityDialogue_SetEnabled(enabled)

**/
library BossVoidEntityDialogue initializer Init requires ExSound, RangeCheck, DamageEngine, UnitDeathEvent
    globals
        private unit BossUnit = null
        private timer VoiceTimer = null
        private trigger SpellTrigger = null
        private trigger OrderTrigger = null
        private boolean Enabled = false
        private boolean LowHealthPlayed = false
    endglobals

    private function CanSpeak takes nothing returns boolean
        return Enabled and BossUnit != null and GetUnitTypeId(BossUnit) != 0 and GetWidgetLife(BossUnit) > 0.405 and TimerGetRemaining(VoiceTimer) <= 0.00 and RangeCheck_Unit(BossUnit, Player(0)) < 1500.00 and not udg_InCinematic
    endfunction

    private function VoiceCooldownExpired takes nothing returns nothing
    endfunction

    private function Play takes string soundKey, string text, real extraCooldown returns nothing
        call ExSound_Play(soundKey, text)
        call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, udg_ExSoundDuration, "|cffaa80ffVoid Entity:|r " + text)
        call TimerStart(VoiceTimer, udg_ExSoundDuration + extraCooldown, false, function VoiceCooldownExpired)
    endfunction

    public function PlayStart takes nothing returns nothing
        local integer line = GetRandomInt(1, 3)

        if not CanSpeak() then
            return
        endif
        if line == 1 then
            call Play("VoidEntity_0001", "It is too late... for me.", 3.00)
        elseif line == 2 then
            call Play("VoidEntity_0002", "You should not have come...", 3.00)
        else
            call Play("VoidEntity_0003", "Help... me...", 3.00)
        endif
    endfunction

    public function PlayDeath takes nothing returns nothing
        if RangeCheck_Unit(BossUnit, Player(0)) >= 1500.00 then
            return
        endif
        if GetRandomInt(1, 2) == 1 then
            call Play("VoidEntity_0032", "I see... nothing...?", 3.00)
        else
            call Play("VoidEntity_0033", "At last... I am free...", 3.00)
        endif
    endfunction

    private function OnSpell takes nothing returns nothing
        local integer line

        if GetTriggerUnit() == BossUnit and CanSpeak() and GetRandomInt(1, 100) <= 30 then
            set line = GetRandomInt(1, 5)
            if line == 1 then
                call Play("VoidEntity_0017", "Unmake.", 6.00)
            elseif line == 2 then
                call Play("VoidEntity_0018", "Despair.", 6.00)
            elseif line == 3 then
                call Play("VoidEntity_0019", "Surrender.", 6.00)
            elseif line == 4 then
                call Play("VoidEntity_0020", "You... will fail...", 6.00)
            else
                call Play("VoidEntity_0021", "Unravel.", 6.00)
            endif
        endif
    endfunction

    private function OnOrder takes nothing returns nothing
        local integer line
        local integer orderId = GetIssuedOrderId()

        if GetTriggerUnit() == BossUnit and (orderId == OrderId("attack") or orderId == OrderId("smart")) and CanSpeak() then
            set line = GetRandomInt(1, 6)
            if line == 1 then
                call Play("VoidEntity_0005", "Your fear... feeding me...", 15.00)
            elseif line == 2 then
                call Play("VoidEntity_0006", "Relinquish... yourself...", 15.00)
            elseif line == 3 then
                call Play("VoidEntity_0007", "Every strike... unravels you.", 15.00)
            elseif line == 4 then
                call Play("VoidEntity_0008", "This will... consume you...", 15.00)
            elseif line == 5 then
                call Play("VoidEntity_0009", "It is futile... to resist...", 15.00)
            else
                call Play("VoidEntity_0010", "There is nowhere... to run.", 15.00)
            endif
        endif
    endfunction

    private function OnDamage takes nothing returns nothing
        if not LowHealthPlayed and udg_DamageEventTarget == BossUnit and GetWidgetLife(BossUnit) <= GetUnitState(BossUnit, UNIT_STATE_MAX_LIFE) * 0.25 and CanSpeak() then
            set LowHealthPlayed = true
            call PlayStart()
        endif
    endfunction

    private function OnUnitDeath takes nothing returns nothing
        local unit dyingUnit = UnitDeathEvent_GetDyingUnit()
        local integer line

        if dyingUnit != null and GetUnitAbilityLevel(dyingUnit, 'Aloc') == 0 and (GetOwningPlayer(dyingUnit) == Player(0) or IsUnitInGroup(dyingUnit, udg_Companion_Group)) and CanSpeak() then
            set line = GetRandomInt(1, 3)
            if line == 1 then
                call Play("VoidEntity_0012", "Welcome... to the other side...", 3.00)
            elseif line == 2 then
                call Play("VoidEntity_0013", "Feel the void...", 3.00)
            else
                call Play("VoidEntity_0014", "You will see... darkness...", 3.00)
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
