RageEnergy.j
- create new jass library
- make it base of the provided old gui triggers
- note that it must work for all rogue/warrior classes. Energy for rogue. Rage for warrior.
- this system should consider mana sources that could inflict on the warrior/rogue (maybe mana is not even the best resource for abilities for these classes? Should we implement custom rage/energy resources that the AI uses for abilities casting (but how handle the abilities because vanilla wc3 abilities either cost mana or no mana) Maybe prevent using the ability if the custom rage/energy resource not enough.

RageEnergy Limit Mana Max From Items
    Events
        Unit - A unit Acquires an item
        Unit - A unit Loses an item
        Unit - A unit Uses an item
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of (Triggering unit)) Equal to Rogue (Companion)
                (Unit-type of (Triggering unit)) Equal to Tauren Warrior (Companion)
    Actions
        Set VariableSet RageEnergyUnit_CurrentMana = (Mana of (Triggering unit))
        Wait 0.10 seconds
        Custom script:   call SetUnitMaxState(GetTriggerUnit(),UNIT_STATE_MAX_MANA,100)
        Unit - Set Max Mana of (Triggering unit) to 100
        Unit - Set mana of (Triggering unit) to RageEnergyUnit_CurrentMana
        Custom script:   call SetUnitState(GetTriggerUnit(),UNIT_STATE_MANA,udg_RageEnergyUnit_CurrentMana)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Unit-type of (Triggering unit)) Equal to Tauren Warrior (Companion)
            Then - Actions
                -------- Start Rage Decay (for Warrior at this moment) --------
                Trigger - Turn on HeroWarrior Rage Decay <gen>
                -------- Prevent "Normal" mana regeneration --------
                Unit - Set Unit: (Triggering unit)'s Real Field: Mana Regeneration ('umpr') to Value: (-1.00 x (ManaRegenPerInt x (Real((Intelligence of (Triggering unit) (Include bonuses))))))
            Else - Actions


RageEnergy Limit Mana Regen From Items
    Events
        Unit - A unit Begins casting an ability
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of (Triggering unit)) Equal to Rogue (Companion)
                (Unit-type of (Triggering unit)) Equal to Tauren Warrior (Companion)
        Or - Any (Conditions) are true
            Conditions
                (Ability being cast) Equal to Item Mana Regain (Minor Mana Potion)
                (Ability being cast) Equal to Item Mana Regain (Mana Potion)
                (Ability being cast) Equal to Item Mana Regain (Major Mana Potion)
                (Ability being cast) Equal to Item Mana Regain (Lesser)
                (Ability being cast) Equal to Item Mana Regain (Greater)
                (Ability being cast) Equal to Item Mana Regain (Greater Mana Potion)
    Actions
        -------- expand the LIST within OR-condition with other abilities that regenerate mana --------
        -------- ================================== --------
        Unit - Order (Triggering unit) to Stop.
        Hero - Drop (Target item of ability being cast) from (Triggering unit).
        Game - Display to (All players) the text: ((Proper name of (Triggering unit)) +  can't use this item)


RageEnergy Remove Aura Buffs Loop (THIS IS NOT the best way to remove unwanted buffs from Rage / Energy units!)
    Events
        Time - Every 0.30 seconds of game time
    Conditions
    Actions
        Custom script:   set bj_wantDestroyGroup = true
        Unit Group - Pick every unit in (Units in (Playable map area)) and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Or - Any (Conditions) are true
                            Conditions
                                (Picked unit) Equal to NPC_Horde_AI_Rogue
                                (Picked unit) Equal to NPC_Horde_AI_Warrior
                    Then - Actions
                        Set VariableSet CV_RageEnergy = (Custom value of (Picked unit))
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                IsUnitAlive[CV_RageEnergy] Equal to True
                                ((Picked unit) has buff Water Totem Aura ) Equal to True
                            Then - Actions
                                Unit - Remove Water Totem Aura  buff from (Picked unit)
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                IsUnitAlive[CV_RageEnergy] Equal to True
                                ((Picked unit) has buff Mana Regeneration Aura) Equal to True
                            Then - Actions
                                Unit - Remove Mana Regeneration Aura buff from (Picked unit)
                            Else - Actions
                    Else - Actions


RageEnergy Energy Tick
    Events
        Time - Every 1.00 seconds of game time
    Conditions
    Actions
        Unit Group - Pick every unit in Energy_Group and do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        IsUnitAlive[(Custom value of (Picked unit))] Equal to True
                        (Unit-type of (Picked unit)) Equal to Rogue (Companion)
                        (Percentage mana of (Picked unit)) Less than 100.00
                    Then - Actions
                        Unit - Set mana of (Picked unit) to ((Mana of (Picked unit)) + 20.00)
                    Else - Actions


Heres old gui:
RageEnergy Rage Generation
    Events
        Game - DamageEvent becomes Equal to 1.00
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Unit-type of DamageEventSource) Equal to Tauren Warrior (Companion)
                (Unit-type of DamageEventTarget) Equal to Tauren Warrior (Companion)
    Actions
        -------- =============================== --------
        -------- Rage Gain for Attacker (Warrior) --------
        -------- ---------------------- Rage should not be gained from attacking with Spells (abilities) --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Unit-type of DamageEventSource) Equal to Tauren Warrior (Companion)
                IsDamageSpell Equal to False
            Then - Actions
                Set VariableSet Rage_TempLevel = (Real((Hero level of DamageEventSource)))
                Set VariableSet Rage_TempFactorDamage = (DamageEventAmount x Rage_AttackScaleReal)
                Set VariableSet Rage_TempFactorLevel = (1.00 - (Rage_TempLevel x Rage_LevelScaleReal))
                Set VariableSet Rage_RageGain = (Rage_TempFactorDamage x Rage_TempFactorLevel)
                -------- Bloodrage Bonus --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (DamageEventSource has buff Bloodrage ) Equal to True
                    Then - Actions
                        Set VariableSet Rage_RageGain = (Rage_RageGain + 2.00)
                    Else - Actions
                -------- ----------------- Cap MAX rage gain per Attack --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Rage_RageGain Greater than or equal to 60.00
                    Then - Actions
                        Set VariableSet Rage_RageGain = 60.00
                    Else - Actions
                -------- ----------------- Cap MIN rage gain --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Rage_RageGain Less than or equal to 3.00
                    Then - Actions
                        Set VariableSet Rage_RageGain = 3.00
                    Else - Actions
                -------- =============================== --------
                -------- Give "Rage" --------
                Unit - Set mana of DamageEventSource to ((Mana of DamageEventSource) + Rage_RageGain)
                -------- Prevent shooting over 100 mana --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Mana of DamageEventSource) Greater than or equal to 100.00
                    Then - Actions
                        Unit - Set mana of DamageEventSource to 100.00
                    Else - Actions
                -------- Start Rage Decay (for Warrior at this moment) --------
                Trigger - Turn on HeroWarrior Rage Decay <gen>
                Countdown Timer - Start Rage_DecayTimer as a One-shot timer that will expire in 5.00 seconds
                -------- =============================== --------
            Else - Actions
        -------- =============================== --------
        -------- Rage Gain when Attacked (Warrior) --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Unit-type of DamageEventTarget) Equal to Tauren Warrior (Companion)
            Then - Actions
                Set VariableSet Rage_TempLevel = (Real((Hero level of DamageEventTarget)))
                Set VariableSet Rage_TempFactorDamage = (DamageEventAmount x Rage_DefenseScaleReal)
                Set VariableSet Rage_TempFactorLevel = (1.00 - (Rage_TempLevel x Rage_LevelScaleReal))
                Set VariableSet Rage_RageGain = (Rage_TempFactorDamage x Rage_TempFactorLevel)
                -------- Bloodrage Bonus --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (DamageEventSource has buff Bloodrage ) Equal to True
                    Then - Actions
                        Set VariableSet Rage_RageGain = (Rage_RageGain + 1.00)
                    Else - Actions
                -------- ----------------- Cap MAX rage gain per Attacked --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Rage_RageGain Greater than or equal to 60.00
                    Then - Actions
                        Set VariableSet Rage_RageGain = 60.00
                    Else - Actions
                -------- ----------------- Cap MIN rage gain --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Rage_RageGain Less than or equal to 3.00
                    Then - Actions
                        Set VariableSet Rage_RageGain = 3.00
                        -------- =============================== --------
                        -------- Give "Rage" --------
                        Unit - Set mana of DamageEventTarget to ((Mana of DamageEventTarget) + Rage_RageGain)
                        -------- Prevent shooting over 100 mana --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Mana of DamageEventTarget) Greater than or equal to 100.00
                            Then - Actions
                                Unit - Set mana of DamageEventTarget to 100.00
                            Else - Actions
                        -------- Start Rage Decay (for Warrior at this moment) --------
                        Trigger - Turn on HeroWarrior Rage Decay <gen>
                        Countdown Timer - Start Rage_DecayTimer as a One-shot timer that will expire in 5.00 seconds
                        -------- =============================== --------
                    Else - Actions
            Else - Actions
HeroWarrior Rage Decay
    Events
        Time - Every 1.50 seconds of game time
    Conditions
        (Mana of NPC_Horde_AI_Warrior) Greater than 0.00
        (Remaining time for Rage_DecayTimer) Equal to 0.00
    Actions
        Unit - Set mana of NPC_Horde_AI_Warrior to ((Mana of NPC_Horde_AI_Warrior) - 5.00)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Mana of NPC_Horde_AI_Warrior) Less than or equal to 0.00
            Then - Actions
                Unit - Set mana of NPC_Horde_AI_Warrior to 0.00
                Trigger - Turn off (This trigger)
            Else - Actions


