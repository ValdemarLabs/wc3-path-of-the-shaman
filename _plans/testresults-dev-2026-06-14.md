# Test results 2026-06-14

## QuestSystems / qAradion test
- Ranger Missing: When WithinRange of Valeria and starting encounter with her Nazgrek slowly turns facing to random direction and not to Valeria. Nazgrek only faces Valeria after Valeria second line.
- Ranger Missing: When pressing ESC and selecting dialog choice ESC key must not be able to be pressed to bring dialog choices during when player unit speaks.
- Ranger Missing: When selecting Aradion when completing Ranger Missing quest Nazgrek is not facing Aradion and should make random facings during the dialog looking at each speaker when they start speaking.
- Rifts of Corruption: when accepting the quest and starting dialog with Aradion - Valeria should be teleported more further away (so we dont see her teleporting) and issue forced move to her rect place near aradion.
- Rifts of Corruption: when starting the ritual the voicelines all started at the same time for Aradion and Valeria - they must be one by one and not simultaneously.
- Rifts of Corruption: if aradion or valeria dies when Rift closing is not started. We must not have fail text "XXX fell during the ritual". We must have text "XXX has died." Texts are different depending have we started the ritual or not.
- Rifts of Corruption: during the ritual Aradion channeling animation gets stuck. The channel animation must be looping. Not really sure if this WE objecti editor thing I need to edit for the channel ability itself.
- Rifts of Corruption: the rift unit was not killed when the ritual was completed.
- Rifts of Corruption: when the ritual is completed aradion and valeria speak at the same time - the voicelines must not be overlapped.
- Rifts of Corruption: if aradion or valeria dies at any point - the other (valeria or Aradion depending who dies) must go the location of the other and then speak the lines. See old GUI triggers related to Rifts of Corruption. After some time 30s teleport them back to init location revived.
- here is example how to not prevent unit fully dying that we must do for aradion and valeria if they get "killed":
"Tamed Unit Dies
    Events
        Unit - A unit Takes damage
    Conditions
        (Damage Target) Equal to XXX
        (Damage taken) Greater than or equal to ((Life of XXX) - 0.41)
    Actions
        -------- We don't really want the XXX unit to die --------
        Event Response - Set Damage of Unit Damaged Event to ((Life of XXX) - 1.00)
        Unit - Order XXX to Stop.
        Unit - Make XXX Invulnerable
        Unit - Change ownership of XXX to Neutral Passive and Retain color
        Animation - Play XXX's death animation
        Unit - Pause XXX
	----- we dont want to actually use "waits" those are bad in jass and overall
        Wait (Unit: XXX's Real Field: Death Time (seconds) ('udtm')) seconds
        Animation - Change XXX's animation speed to 0.00% of its original speed"
- Rifts of Corruption: when quest was failed Aradion and Valeria where still part of FollowSystem which must not be the case when quest is failed.
- Quest must be marked failed in the quest log if quest is failed.

## Quest Systems rewards related
- Reputation reward: ReputationUI is still not showing that Quest reputation reward actually increased the reputation level - is this ReputationUI refresh problem? It should refresh when opening the ReputationUI or when there is reputation change (ie event driven).
- XP reward: XP reward is still not really given to player units when completing quest.

## ItemLoot systems related
==== ei annettu
@ItemLootDestructibles
Relational comparission between special type and native type in function "ProcessLootTableDrops ": if GetRandomInt(1, 10000) > ItemLootDestructibles___destTableDropChance[destTypeId] then

## Other todo tasks
==== ei annettu
Other
- add as todo to changelog: Companions GUI triggers merge into jass library - this requires some time to implement properly and we have many system calling those companion GUI trigger related udg_variables. It is very likely that somethings get broken at the merge and will require troubleshooting time.