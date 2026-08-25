/**
    qVelyssara

    Author: Valdemar
    Version:

    Description:
    Converts Velyssara's legacy Chains of Seduction quest, dialogue, charm,
    task progression, Sereneglade confinement, and combat reactions.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Velyssara and the related
    Outcast Jin'Zun dispel branch.

    How to install:
    Import after the required quest, dialogue, zone, death-event, sound, and
    voiceline libraries. Keep Velyssara's placed-unit global and the legacy
    quest rects, then disable the converted Succubus GUI trigger group.

    API:
    - qVelyssara_IsCharmed()
    - qVelyssara_IsHeroConfined()
    - qVelyssara_IsEscapeAttempt(hero)
    - qVelyssara_HandleEscapeAttempt(hero)
    - qVelyssara_CanDispelCharm(hero)
    - qVelyssara_DispelCharm(hero)
    - qVelyssara_RefreshAvailability()
    - qVelyssara_RefreshRespawnedUnitHooks()

**/
library qVelyssara initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, UnitDeathEvent, ZonesCore, ExSound, VoicelinesDemoness, VoicelinesNazgrek

globals
    private constant boolean DEBUG = false

    public constant string QUEST_CHAINS_OF_SEDUCTION = "Chains of Seduction"
    private constant string VELYSSARA_NAME = "Velyssara"

    private constant integer UNIT_GRUNT = 'ogru'
    private constant integer UNIT_KODO_MOUNT = 'o61F'
    private constant integer ITEM_GNOLL_PILLAGE = 'I6A4'
    private constant integer ITEM_ORB_OF_LIFESTEAL = 'I6A5'
    private constant integer ABILITY_LIFE_DRAIN = 'A696'
    private constant integer HORDE_OWNER = 5
    private constant integer TEMPORARY_GUARD_OWNER = 1

    private constant integer TASK_NONE = 0
    private constant integer TASK_RUMORS = 1
    private constant integer TASK_PILLAGE = 2
    private constant integer TASK_HORDE_KILL = 3
    private constant integer TASK_SELF_SACRIFICE = 4

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 1
    private constant real CINEMATIC_MOVE_OFFSET = 256.00
    private constant real CINEMATIC_MOVE_ANGLE = 210.00
    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 900.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 70.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private constant real FOLLOW_INTERVAL = 2.00
    private constant real CONFINEMENT_INTERVAL = 0.10
    private constant real GUARD_HOSTILE_DURATION = 10.00
    private constant real HORDE_HOSTILE_DURATION = 60.00
    private constant real SATYR_HOSTILE_DURATION = 300.00

    private unit Velyssara = null
    private unit Nazgrek = null
    private unit SelectedHero = null
    private unit CharmedHero = null
    private unit PillageGuard = null
    private item PillageItem = null
    private dialog VelyssaraDialog = null
    private timer VelyssaraDialogCooldown = null
    private timer FollowTimer = null
    private timer ConfinementTimer = null
    private timer GuardHostileTimer = null
    private timer HordeHostileTimer = null
    private timer SatyrHostileTimer = null
    private trigger PillageHutTrigger = null
    private trigger PillagePickupTrigger = null
    private trigger HeroReviveTrigger = null
    private trigger VelyssaraAttackedTrigger = null
    private trigger VelyssaraSpellTrigger = null
    private group RumorTargets = null
    private integer ActiveTask = TASK_NONE
    private integer RumorCount = 0
    private real LastSafeX = 0.00
    private real LastSafeY = 0.00
    private boolean HasLastSafePoint = false
    private boolean Charmed = false
    private boolean CharmDispelled = false
    private boolean RuntimeRegistered = false
    private boolean VelyssaraInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cffcc66ff[qVelyssara]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Succubus != null and udg_Succubus != Velyssara then
        set Velyssara = udg_Succubus
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
endfunction

private function GetChainsQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Velyssara == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_CHAINS_OF_SEDUCTION, Velyssara)
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Velyssara, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function IsChainsActive takes nothing returns boolean
    local QuestData q = GetChainsQuest()
    local boolean result = q != 0 and q.active and not q.completed
    set q = 0
    return result
endfunction

private function IsInsideSereneglade takes unit hero returns boolean
    return hero != null and RectContainsUnit(gg_rct_02SereneGlade, hero)
endfunction

private function IsConfinedInternal takes nothing returns boolean
    return Charmed and not CharmDispelled and CharmedHero != null and IsChainsActive()
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogSystem_ClearEscapeAction()
    call DialogInteraction_StartConfiguredDialogExitTransition(Velyssara, SelectedHero, VelyssaraDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function OnVelyssaraEscape takes nothing returns nothing
    call DialogInteraction_CloseActiveDialog()
    call StartExitFadeOut()
endfunction

private function ShowQuestUpdate takes string text returns nothing
    local QuestData q = GetChainsQuest()
    if q != 0 then
        call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + text)
    endif
    set q = 0
endfunction

private function MarkAllRequirementsCompleted takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    local integer index = 1
    if q == 0 then
        return
    endif
    loop
        exitwhen index > 5
        call QuestGiver_SetRequirementCompleted(q.id, index, true)
        set index = index + 1
    endloop
    set q = 0
endfunction

private function RemoveTaskObjects takes nothing returns nothing
    if PillageGuard != null then
        call RemoveUnit(PillageGuard)
        set PillageGuard = null
    endif
    if PillageItem != null then
        call RemoveItem(PillageItem)
        set PillageItem = null
    endif
    if RumorTargets != null then
        call GroupClear(RumorTargets)
    endif
endfunction

private function StopCharmRuntime takes nothing returns nothing
    call PauseTimer(FollowTimer)
    call PauseTimer(ConfinementTimer)
endfunction

private function CompleteChainsInternal takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    if q == 0 or q.completed then
        set q = 0
        return
    endif
    set Charmed = false
    set udg_SuccubusSeduced = false
    set ActiveTask = TASK_NONE
    call StopCharmRuntime()
    call RemoveTaskObjects()
    call MarkAllRequirementsCompleted()
    if Velyssara != null then
        call SetUnitInvulnerable(Velyssara, false)
    endif
    call QuestGiver_CompleteQuestByNameAndGiver(QUEST_CHAINS_OF_SEDUCTION, Velyssara)
    call QuestGiver_RefreshAvailabilityForGiver(Velyssara)
    set CharmedHero = null
    set HasLastSafePoint = false
    set q = 0
endfunction

private function TeleportHeroBack takes unit hero returns nothing
    local real sourceX
    local real sourceY
    local real targetX
    local real targetY
    local effect sourceEffect
    local effect targetEffect
    if hero == null then
        return
    endif
    set sourceX = GetUnitX(hero)
    set sourceY = GetUnitY(hero)
    if HasLastSafePoint then
        set targetX = LastSafeX
        set targetY = LastSafeY
    else
        set targetX = GetRectCenterX(gg_rct_02SereneGlade)
        set targetY = GetRectCenterY(gg_rct_02SereneGlade)
    endif
    set sourceEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", sourceX, sourceY)
    call SetUnitPosition(hero, targetX, targetY)
    set targetEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", GetUnitX(hero), GetUnitY(hero))
    call DestroyEffect(sourceEffect)
    call DestroyEffect(targetEffect)
    call PanCameraToTimedForPlayer(Player(0), GetUnitX(hero), GetUnitY(hero), 0.00)
    call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 4.00, "|cffcc66ffVelyssara's chains drag you back into Sereneglade.|r")
    set sourceEffect = null
    set targetEffect = null
endfunction

private function HandleEscapeAttemptInternal takes unit hero returns boolean
    if hero == null or hero != CharmedHero or not IsConfinedInternal() or IsInsideSereneglade(hero) then
        return false
    endif
    call TeleportHeroBack(hero)
    return true
endfunction

private function OnConfinementTick takes nothing returns nothing
    if not IsConfinedInternal() then
        call PauseTimer(ConfinementTimer)
        return
    endif
    if not DialogInteraction_IsUnitAlive(CharmedHero) then
        return
    endif
    if IsInsideSereneglade(CharmedHero) then
        set LastSafeX = GetUnitX(CharmedHero)
        set LastSafeY = GetUnitY(CharmedHero)
        set HasLastSafePoint = true
    else
        call HandleEscapeAttemptInternal(CharmedHero)
    endif
endfunction

private function OnFollowTick takes nothing returns nothing
    if not IsConfinedInternal() then
        call PauseTimer(FollowTimer)
        return
    endif
    if DialogInteraction_IsUnitAlive(Velyssara) and DialogInteraction_IsUnitAlive(CharmedHero) then
        call IssueTargetOrder(Velyssara, "follow", CharmedHero)
    endif
endfunction

private function StartCharmRuntime takes unit hero returns nothing
    set CharmedHero = hero
    set Charmed = true
    set CharmDispelled = false
    set udg_SuccubusSeduced = true
    set udg_QuestChainsOfSeductionDispelld = false
    if IsInsideSereneglade(hero) then
        set LastSafeX = GetUnitX(hero)
        set LastSafeY = GetUnitY(hero)
        set HasLastSafePoint = true
    else
        set HasLastSafePoint = false
        call TeleportHeroBack(hero)
    endif
    call SetUnitInvulnerable(Velyssara, true)
    call TimerStart(FollowTimer, FOLLOW_INTERVAL, true, function OnFollowTick)
    call TimerStart(ConfinementTimer, CONFINEMENT_INTERVAL, true, function OnConfinementTick)
endfunction

private function OnSatyrHostilityEnd takes nothing returns nothing
    if Velyssara != null and DialogInteraction_IsUnitAlive(Velyssara) then
        call SetPlayerAllianceStateBJ(Player(0), GetOwningPlayer(Velyssara), bj_ALLIANCE_ALLIED)
        call SetPlayerAllianceStateBJ(GetOwningPlayer(Velyssara), Player(0), bj_ALLIANCE_ALLIED)
    endif
endfunction

private function StartSatyrHostility takes unit target returns nothing
    if Velyssara == null or target == null then
        return
    endif
    call SetPlayerAllianceStateBJ(Player(0), GetOwningPlayer(Velyssara), bj_ALLIANCE_UNALLIED)
    call SetPlayerAllianceStateBJ(GetOwningPlayer(Velyssara), Player(0), bj_ALLIANCE_UNALLIED)
    call SetUnitInvulnerable(Velyssara, false)
    call IssueTargetOrder(Velyssara, "attack", target)
    call TimerStart(SatyrHostileTimer, SATYR_HOSTILE_DURATION, false, function OnSatyrHostilityEnd)
endfunction

private function StartTask4 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    set ActiveTask = TASK_SELF_SACRIFICE
    if q != 0 then
        call QuestGiver_UpdateRequirementText(q.id, 5, "Task 4: Kill yourself by any means")
        call ShowQuestUpdate("|cffddccffNew objective:|r Kill yourself by any means.")
    endif
    set q = 0
endfunction

private function OnTask3SequenceEnd takes nothing returns nothing
    call StartTask4()
endfunction

private function CompleteTask3 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    local integer seq
    if ActiveTask != TASK_HORDE_KILL or q == 0 then
        set q = 0
        return
    endif
    set ActiveTask = TASK_NONE
    call QuestGiver_SetRequirementCompleted(q.id, 4, true)
    call ShowQuestUpdate("|cff80ff80Task 3 complete:|r A member of the Horde has been slain.")
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0038_TEXT, VL_DEMONESS_0038_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0030_TEXT, VL_DEMONESS_0030_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0031_TEXT, VL_DEMONESS_0031_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnTask3SequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
    set q = 0
endfunction

private function StartTask3 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    set ActiveTask = TASK_HORDE_KILL
    if q != 0 then
        call QuestGiver_UpdateRequirementText(q.id, 4, "Task 3: Kill a member of the Horde")
        call ShowQuestUpdate("|cffddccffNew objective:|r Kill a member of the Horde.")
    endif
    set q = 0
endfunction

private function OnTask2SequenceEnd takes nothing returns nothing
    call StartTask3()
endfunction

private function CompleteTask2 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    local integer seq
    if ActiveTask != TASK_PILLAGE or q == 0 then
        set q = 0
        return
    endif
    set ActiveTask = TASK_NONE
    if PillageGuard != null then
        call RemoveUnit(PillageGuard)
        set PillageGuard = null
    endif
    if PillageItem != null then
        call UnitRemoveItem(CharmedHero, PillageItem)
        call SetItemPosition(PillageItem, GetRectCenterX(gg_rct_GnollPillageHut), GetRectCenterY(gg_rct_GnollPillageHut))
    endif
    call QuestGiver_SetRequirementCompleted(q.id, 3, true)
    call ShowQuestUpdate("|cff80ff80Task 2 complete:|r The stolen pillage has been planted in Ragno's hut.")
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0036_TEXT, VL_DEMONESS_0036_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0029_TEXT, VL_DEMONESS_0029_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnTask2SequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
    set q = 0
endfunction

private function OnPillageHutEntered takes nothing returns nothing
    local unit entering = GetEnteringUnit()
    if ActiveTask == TASK_PILLAGE and entering == CharmedHero and HeroItemCheck(entering, ITEM_GNOLL_PILLAGE, 1) then
        call CompleteTask2()
    endif
    set entering = null
endfunction

private function OnGuardHostilityEnd takes nothing returns nothing
    if DialogInteraction_IsUnitAlive(PillageGuard) then
        call SetUnitOwner(PillageGuard, Player(HORDE_OWNER), true)
        call IssuePointOrder(PillageGuard, "patrol", GetRectCenterX(gg_rct_PillagePatrol01), GetRectCenterY(gg_rct_PillagePatrol01))
    endif
endfunction

private function OnHordeHostilityEnd takes nothing returns nothing
    call SetPlayerAllianceStateBJ(Player(0), Player(HORDE_OWNER), bj_ALLIANCE_ALLIED)
    call SetPlayerAllianceStateBJ(Player(HORDE_OWNER), Player(0), bj_ALLIANCE_ALLIED)
endfunction

private function StartHordeHostility takes nothing returns nothing
    call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 6.00, "|cffff8040The Horde considers you an enemy for killing the pillage guard.|r")
    call SetPlayerAllianceStateBJ(Player(0), Player(HORDE_OWNER), bj_ALLIANCE_UNALLIED)
    call SetPlayerAllianceStateBJ(Player(HORDE_OWNER), Player(0), bj_ALLIANCE_UNALLIED)
    call TimerStart(HordeHostileTimer, HORDE_HOSTILE_DURATION, false, function OnHordeHostilityEnd)
endfunction

private function OnPillagePickedUp takes nothing returns nothing
    local unit hero = GetTriggerUnit()
    if ActiveTask == TASK_PILLAGE and GetManipulatedItem() == PillageItem and DialogInteraction_IsUnitAlive(PillageGuard) and RectContainsUnit(gg_rct_PillageGuardArea, PillageGuard) then
        call ExSound_PlayAtUnit("PillageGuard", PillageGuard, "Time to die!")
        call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, PillageGuard, "Grunt", null, "Time to die!", bj_TIMETYPE_SET, 2.00, false)
        call SetUnitOwner(PillageGuard, Player(TEMPORARY_GUARD_OWNER), true)
        call IssueTargetOrder(PillageGuard, "attack", hero)
        call TimerStart(GuardHostileTimer, GUARD_HOSTILE_DURATION, false, function OnGuardHostilityEnd)
    endif
    set hero = null
endfunction

private function StartTask2 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    set ActiveTask = TASK_PILLAGE
    if PillageItem != null then
        call RemoveItem(PillageItem)
    endif
    if PillageGuard != null then
        call RemoveUnit(PillageGuard)
    endif
    set PillageItem = CreateItem(ITEM_GNOLL_PILLAGE, GetRectCenterX(gg_rct_GnollPillageSpawn), GetRectCenterY(gg_rct_GnollPillageSpawn))
    call SetItemInvulnerable(PillageItem, true)
    set PillageGuard = CreateUnit(Player(HORDE_OWNER), UNIT_GRUNT, GetRectCenterX(gg_rct_PillagePatrol02), GetRectCenterY(gg_rct_PillagePatrol02), bj_UNIT_FACING)
    call IssuePointOrder(PillageGuard, "patrol", GetRectCenterX(gg_rct_PillagePatrol01), GetRectCenterY(gg_rct_PillagePatrol01))
    if q != 0 then
        call QuestGiver_UpdateRequirementText(q.id, 3, "Task 2: Steal the gnoll pillage and place it in Ragno's hut")
        call ShowQuestUpdate("|cffddccffNew objective:|r Steal the gnoll pillage and plant it in Ragno's hut.")
    endif
    set q = 0
endfunction

private function OnTask1SequenceEnd takes nothing returns nothing
    call StartTask2()
endfunction

private function CompleteTask1 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    local integer seq
    if ActiveTask != TASK_RUMORS or q == 0 then
        set q = 0
        return
    endif
    set ActiveTask = TASK_NONE
    call QuestGiver_SetRequirementCompleted(q.id, 1, true)
    call ShowQuestUpdate("|cff80ff80Task 1 complete:|r Four Horde members have heard the false rumor.")
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0035_TEXT, VL_DEMONESS_0035_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0028_TEXT, VL_DEMONESS_0028_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnTask1SequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
    set q = 0
endfunction

private function OnRumorSequenceEnd takes nothing returns nothing
    if RumorCount >= 4 then
        call CompleteTask1()
    endif
endfunction

private function PlayRumorSequence takes unit target returns nothing
    local integer roll = GetRandomInt(1, 4)
    local integer seq = DialogInteraction_CreateBaseSequence(target, GetUnitName(target))
    if roll == 1 then
        call DialogSystem_AddLineNoSound(seq, CharmedHero, DialogInteraction_GetHeroName(CharmedHero), "I saw Ragno steal some of the gnoll pillage for himself.")
        call DialogSystem_AddLineNoSound(seq, target, GetUnitName(target), "What?! He wouldn't dare, would he?")
    elseif roll == 2 then
        call DialogSystem_AddLineNoSound(seq, CharmedHero, DialogInteraction_GetHeroName(CharmedHero), "I saw Ragno steal some of the gnoll pillage for himself.")
        call DialogSystem_AddLineNoSound(seq, target, GetUnitName(target), "Why would Ragno do that? It doesn't sound like him... Should we confront him?")
    elseif roll == 3 then
        call DialogSystem_AddLineNoSound(seq, CharmedHero, DialogInteraction_GetHeroName(CharmedHero), "I saw someone steal some of the gnoll pillage for himself.")
        call DialogSystem_AddLineNoSound(seq, target, GetUnitName(target), "Who does this thief think he is, stealing from us like that?")
    else
        call DialogSystem_AddLineNoSound(seq, CharmedHero, DialogInteraction_GetHeroName(CharmedHero), "I saw some orc warrior steal some of the gnoll pillage for himself.")
        call DialogSystem_AddLineNoSound(seq, target, GetUnitName(target), "If that is true, we will have to discover this thief immediately!")
    endif
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnRumorSequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), target)
endfunction

private function IsValidRumorTarget takes unit target returns boolean
    return ActiveTask == TASK_RUMORS and target != null and target != CharmedHero and target != Velyssara and target != udg_Ragno and target != udg_OutcastJinzun and GetOwningPlayer(target) == Player(HORDE_OWNER) and GetUnitTypeId(target) != UNIT_KODO_MOUNT and not IsUnitType(target, UNIT_TYPE_STRUCTURE) and DialogInteraction_IsUnitAlive(target) and DialogInteraction_IsWithinRange(target, CharmedHero, DIALOG_RANGE) and not IsUnitInGroup(target, RumorTargets)
endfunction

private function OnPreSelected takes nothing returns nothing
    local unit target = DialogInteraction_GetSelectedUnit()
    local QuestData q
    if IsValidRumorTarget(target) and not DialogSystem_IsSequenceActive() then
        call DialogInteraction_ConsumeSelection()
        call GroupAddUnit(RumorTargets, target)
        set RumorCount = RumorCount + 1
        set q = GetChainsQuest()
        if q != 0 then
            call QuestGiver_UpdateRequirementText(q.id, 1, "Task 1: Spread a false rumor among the orcs (" + I2S(RumorCount) + " / 4)")
        endif
        call PlayRumorSequence(target)
        set q = 0
    endif
    set target = null
endfunction

private function StartTask1 takes nothing returns nothing
    local QuestData q = GetChainsQuest()
    set ActiveTask = TASK_RUMORS
    set RumorCount = 0
    call GroupClear(RumorTargets)
    if q != 0 then
        call QuestGiver_UpdateRequirementText(q.id, 1, "Task 1: Spread a false rumor among the orcs (0 / 4)")
        call QuestGiver_UpdateRequirementText(q.id, 2, "Alternative: Find a way to break Velyssara's charm")
        call ShowQuestUpdate("|cffddccffNew objective:|r Spread a false rumor among four Horde members.")
    endif
    set q = 0
endfunction

private function OnAcceptEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_CHAINS_OF_SEDUCTION, Velyssara)
    call StartCharmRuntime(SelectedHero)
    call StartTask1()
    call StartExitFadeOut()
endfunction

private function OnAccept takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0024_TEXT, VL_DEMONESS_0024_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0023_TEXT, VL_DEMONESS_0023_KEY, true)
    call DialogSystem_AddLine(seq, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), VL_NAZGREK_0198_TEXT, VL_NAZGREK_0198_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0026_TEXT, VL_DEMONESS_0026_KEY, true)
    call DialogSystem_AddLine(seq, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), VL_NAZGREK_0202_TEXT, VL_NAZGREK_0202_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
endfunction

private function OnDeclineEnd takes nothing returns nothing
    call StartSatyrHostility(SelectedHero)
    call StartExitFadeOut()
endfunction

private function OnDecline takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0040_TEXT, VL_DEMONESS_0040_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0041_TEXT, VL_DEMONESS_0041_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnDeclineEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
endfunction

private function OnChallengeEnd takes nothing returns nothing
    call StartSatyrHostility(SelectedHero)
    call StartExitFadeOut()
endfunction

private function OnChallenge takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0040_TEXT, VL_DEMONESS_0040_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0041_TEXT, VL_DEMONESS_0041_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnChallengeEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), VL_NAZGREK_0201_TEXT, VL_NAZGREK_0201_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0025_TEXT, VL_DEMONESS_0025_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
endfunction

private function OnActiveBarkEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function PlayActiveBark takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0036_TEXT, VL_DEMONESS_0036_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnActiveBarkEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
endfunction

private function BuildDialog takes nothing returns nothing
    local button b
    local QuestData q = GetChainsQuest()
    if VelyssaraDialog == null then
        set VelyssaraDialog = DialogSystem_CreateDialog(VELYSSARA_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Velyssara)
    call DialogSystem_ClearDialog(VelyssaraDialog)
    call DialogSystem_SetTitle(VelyssaraDialog, VELYSSARA_NAME)
    if q != 0 and q.state == QUEST_STATE_AVAILABLE and not q.completed then
        set b = DialogSystem_AddButton(VelyssaraDialog, "Accept Velyssara's bargain", 1)
        call DialogSystem_BindButtonCode(b, function OnAccept)
        set b = DialogSystem_AddButton(VelyssaraDialog, "Reject her bargain", 2)
        call DialogSystem_BindButtonCode(b, function OnDecline)
    elseif q != 0 and q.completed then
        set b = DialogSystem_AddButton(VelyssaraDialog, "Challenge Velyssara", 1)
        call DialogSystem_BindButtonCode(b, function OnChallenge)
    endif
    set b = DialogSystem_AddFarewellButton(VelyssaraDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
    set q = 0
endfunction

private function AddGreetingLines takes integer seq returns nothing
    if not DialogInteraction_IsFirstGreetDone(Velyssara) then
        call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0020_TEXT, VL_DEMONESS_0020_KEY, true)
        call DialogSystem_AddLine(seq, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), VL_NAZGREK_0196_TEXT, VL_NAZGREK_0196_KEY, true)
        call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0021_TEXT, VL_DEMONESS_0021_KEY, true)
        call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0022_TEXT, VL_DEMONESS_0022_KEY, true)
    else
        call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0021_TEXT, VL_DEMONESS_0021_KEY, true)
    endif
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Velyssara, VELYSSARA_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
    call AddGreetingLines(seq)
    if not DialogInteraction_IsFirstGreetDone(Velyssara) then
        call DialogInteraction_PlayFirstGreetSequenceEx(Velyssara, Player(0), VelyssaraDialog, seq, CINEMATIC)
    else
        call DialogInteraction_PlayGreetSequenceEx(seq, Velyssara, Player(0), VelyssaraDialog, CINEMATIC)
    endif
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Velyssara) then
        call StartExitFadeOut()
        return
    endif
    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        return
    endif
    if IsChainsActive() then
        call PlayActiveBark()
        set hero = null
        return
    endif
    call BuildDialog()
    call DialogSystem_SetEscapeAction(function OnVelyssaraEscape)
    call PlayDialogGreeting(hero)
    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Velyssara) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Velyssara, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Velyssara, SelectedHero, DIALOG_RANGE, VelyssaraDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Velyssara, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qVelyssara_ContinueToDialogAfterSelection")
endfunction

private function OnTask4SequenceEnd takes nothing returns nothing
    call DialogInteraction_EndCinematicSequence(CINEMATIC)
    call CompleteChainsInternal()
    if Velyssara != null then
        call IssuePointOrder(Velyssara, "move", GetRectCenterX(gg_rct_SuccubusLocation), GetRectCenterY(gg_rct_SuccubusLocation))
    endif
endfunction

private function CompleteTask4 takes unit hero returns nothing
    local integer seq
    local effect teleportEffect
    if ActiveTask != TASK_SELF_SACRIFICE or hero != CharmedHero then
        return
    endif
    set ActiveTask = TASK_NONE
    if not IsInsideSereneglade(hero) then
        call TeleportHeroBack(hero)
    endif
    if Velyssara != null then
        set teleportEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", GetUnitX(Velyssara), GetUnitY(Velyssara))
        call SetUnitPosition(Velyssara, GetUnitX(hero) + 128.00, GetUnitY(hero))
        call DestroyEffect(teleportEffect)
    endif
    call ShowQuestUpdate("|cff80ff80Task 4 complete:|r Your sacrifice has satisfied Velyssara.")
    call DialogInteraction_BeginCinematicSequence(CINEMATIC)
    set seq = DialogInteraction_CreateBaseSequence(Velyssara, VELYSSARA_NAME)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0037_TEXT, VL_DEMONESS_0037_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0032_TEXT, VL_DEMONESS_0032_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0208_TEXT, VL_NAZGREK_0208_KEY, true)
    call DialogSystem_AddLine(seq, Velyssara, VELYSSARA_NAME, VL_DEMONESS_0033_TEXT, VL_DEMONESS_0033_KEY, true)
    call DialogSystem_AddLine(seq, hero, DialogInteraction_GetHeroName(hero), VL_NAZGREK_0209_TEXT, VL_NAZGREK_0209_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnTask4SequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Velyssara)
    set teleportEffect = null
endfunction

private function OnHeroRevived takes nothing returns nothing
    call CompleteTask4(GetRevivingUnit())
endfunction

private function OnAnyUnitDeath takes nothing returns nothing
    local unit dying = UnitDeathEvent_GetDyingUnit()
    local unit killer = UnitDeathEvent_GetKillingUnit()
    local player dyingOwner
    if dying == null then
        set killer = null
        return
    endif
    if dying == Velyssara and IsChainsActive() then
        call CompleteChainsInternal()
    elseif dying == PillageGuard and ActiveTask == TASK_PILLAGE then
        set PillageGuard = null
        call StartHordeHostility()
    elseif ActiveTask == TASK_HORDE_KILL and killer != null and GetOwningPlayer(killer) == Player(0) then
        set dyingOwner = GetOwningPlayer(dying)
        if dyingOwner == Player(TEMPORARY_GUARD_OWNER) or dyingOwner == Player(HORDE_OWNER) then
            call CompleteTask3()
        endif
    endif
    set dyingOwner = null
    set dying = null
    set killer = null
endfunction

private function PlayCombatBark takes string text, string soundKey, real duration returns nothing
    call ExSound_PlayAtUnit(soundKey, Velyssara, text)
    call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, Velyssara, VELYSSARA_NAME, null, text, bj_TIMETYPE_SET, duration, false)
endfunction

private function OnVelyssaraSpellChannel takes nothing returns nothing
    local integer roll
    if GetTriggerUnit() != Velyssara or GetSpellAbilityId() != ABILITY_LIFE_DRAIN then
        return
    endif
    set roll = GetRandomInt(1, 4)
    if roll == 1 then
        call PlayCombatBark(VL_DEMONESS_0040_TEXT, VL_DEMONESS_0040_KEY, 3.00)
    elseif roll == 2 then
        call PlayCombatBark(VL_DEMONESS_0043_TEXT, VL_DEMONESS_0043_KEY, 2.00)
    elseif roll == 3 then
        call PlayCombatBark(VL_DEMONESS_0044_TEXT, VL_DEMONESS_0044_KEY, 3.00)
    else
        call PlayCombatBark(VL_DEMONESS_0045_TEXT, VL_DEMONESS_0045_KEY, 4.00)
    endif
endfunction

private function OnVelyssaraAttacked takes nothing returns nothing
    local integer roll
    local real x
    local real y
    if GetTriggerUnit() != Velyssara or GetUnitCurrentOrder(Velyssara) == OrderId("drain") then
        return
    endif
    set roll = GetRandomInt(1, 9)
    set x = GetUnitX(Velyssara)
    set y = GetUnitY(Velyssara)
    if roll == 1 then
        call IssuePointOrder(Velyssara, "blink", x + 300.00, y + 300.00)
    elseif roll == 2 then
        call IssuePointOrder(Velyssara, "blink", x + 150.00, y - 150.00)
    elseif roll == 3 then
        call IssuePointOrder(Velyssara, "blink", x - 300.00, y + 100.00)
    elseif roll == 4 then
        call IssuePointOrder(Velyssara, "blink", x + 200.00, y - 200.00)
    endif
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + VELYSSARA_NAME + "\n|cffffcc00Zone:|r Sereneglade (2)\n"
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_CHAINS_OF_SEDUCTION, Velyssara) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_CHAINS_OF_SEDUCTION, Velyssara, "normal", 6, null, QUEST_CHAINS_OF_SEDUCTION, "ReplaceableTextures\\CommandButtons\\BTNBlueDemoness.blp", "You have fallen under Velyssara's influence. Obey her escalating commands or find a way to break the charm. While bound, you cannot leave Sereneglade.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Satyr", VELYSSARA_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, false, 0, false)
        call q.setRewardItemType(ITEM_ORB_OF_LIFESTEAL)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Option 1: Do as Velyssara commands", "Option 2: Try to break free of Velyssara's seduction", "", "", "", "", "", "")
    endif
    set q = 0
endfunction

private function RegisterRuntime takes nothing returns nothing
    if RuntimeRegistered then
        return
    endif
    set RuntimeRegistered = true
    call DialogInteraction_RegisterPreSelectionHandler(function OnPreSelected)
    call UnitDeathEvent_Register(function OnAnyUnitDeath)
    call TriggerRegisterEnterRectSimple(PillageHutTrigger, gg_rct_GnollPillageHut)
    call TriggerAddAction(PillageHutTrigger, function OnPillageHutEntered)
    call TriggerRegisterPlayerUnitEvent(PillagePickupTrigger, Player(0), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
    call TriggerAddAction(PillagePickupTrigger, function OnPillagePickedUp)
    call TriggerRegisterPlayerUnitEvent(HeroReviveTrigger, Player(0), EVENT_PLAYER_HERO_REVIVE_FINISH, null)
    call TriggerAddAction(HeroReviveTrigger, function OnHeroRevived)
    call TriggerRegisterAnyUnitEventBJ(VelyssaraAttackedTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerAddAction(VelyssaraAttackedTrigger, function OnVelyssaraAttacked)
    call TriggerRegisterAnyUnitEventBJ(VelyssaraSpellTrigger, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call TriggerAddAction(VelyssaraSpellTrigger, function OnVelyssaraSpellChannel)
endfunction

private function InitDelayed takes nothing returns nothing
    local timer initTimer = GetExpiredTimer()
    call SyncUnitReferences()
    if Velyssara == null or Nazgrek == null then
        if not VelyssaraInitWaitingLogged then
            call DebugMsg("Waiting for Velyssara and Nazgrek.")
            set VelyssaraInitWaitingLogged = true
        endif
        call TimerStart(initTimer, 0.50, false, function InitDelayed)
        set initTimer = null
        return
    endif
    call QuestGiver_Register(Velyssara)
    call DialogInteraction_ConfigureDialogTransition(Velyssara, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RegisterRuntime()
    call DialogInteraction_RegisterSelectionHandler(Velyssara, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Velyssara)
    call DestroyTimer(initTimer)
    set initTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set VelyssaraDialogCooldown = CreateTimer()
    set FollowTimer = CreateTimer()
    set ConfinementTimer = CreateTimer()
    set GuardHostileTimer = CreateTimer()
    set HordeHostileTimer = CreateTimer()
    set SatyrHostileTimer = CreateTimer()
    set PillageHutTrigger = CreateTrigger()
    set PillagePickupTrigger = CreateTrigger()
    set HeroReviveTrigger = CreateTrigger()
    set VelyssaraAttackedTrigger = CreateTrigger()
    set VelyssaraSpellTrigger = CreateTrigger()
    set RumorTargets = CreateGroup()
    call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
endfunction

public function IsCharmed takes nothing returns boolean
    return Charmed and not CharmDispelled
endfunction

public function IsHeroConfined takes nothing returns boolean
    return IsConfinedInternal()
endfunction

public function IsEscapeAttempt takes unit hero returns boolean
    return hero != null and hero == CharmedHero and IsConfinedInternal() and not IsInsideSereneglade(hero)
endfunction

public function HandleEscapeAttempt takes unit hero returns boolean
    return HandleEscapeAttemptInternal(hero)
endfunction

public function CanDispelCharm takes unit hero returns boolean
    return hero != null and hero == CharmedHero and Charmed and not CharmDispelled and IsChainsActive()
endfunction

public function DispelCharm takes unit hero returns boolean
    local QuestData q
    if not CanDispelCharm(hero) then
        return false
    endif
    set q = GetChainsQuest()
    set CharmDispelled = true
    set Charmed = false
    set udg_QuestChainsOfSeductionDispelld = true
    set udg_SuccubusSeduced = false
    set ActiveTask = TASK_NONE
    call StopCharmRuntime()
    call RemoveTaskObjects()
    if q != 0 then
        call QuestGiver_SetRequirementCompleted(q.id, 2, true)
        call QuestGiver_UpdateRequirementText(q.id, 1, "Kill Velyssara")
        call ShowQuestUpdate("|cffddccffNew objective:|r Kill Velyssara.")
    endif
    call StartSatyrHostility(hero)
    set CharmedHero = null
    set HasLastSafePoint = false
    set q = 0
    return true
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Velyssara != null then
        call QuestGiver_RefreshAvailabilityForGiver(Velyssara)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Velyssara != null then
        call QuestGiver_Register(Velyssara)
        call DialogInteraction_ConfigureDialogTransition(Velyssara, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Velyssara, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
