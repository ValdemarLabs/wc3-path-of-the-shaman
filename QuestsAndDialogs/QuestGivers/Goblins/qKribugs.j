/**
    qKribugs

    Author: Valdemar
    Version: 1.4.0

    Description:
    Quest, dialogue, patrol, ogre-fullness, and merchant integration for
    Kribugs. His bespoke quest dialog delegates ordinary trading to the shared
    vendor systems and his randomized Special Deal to GambleUI.

    Credits:
    - Legacy GUI triggers in QuestsAndDialogs/OLDGUI/Kribugs.

    How to install:
    Import after the required quest, dialogue, patrol, vendor, and voiceline
    libraries. Disable the converted Kribugs GUI trigger group.

    API:
    - call qKribugs_RefreshAvailability()
    - call qKribugs_RefreshRespawnedUnitHooks()

**/
library qKribugs initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, PatrolSystem, HeroItemCheck, UnitDeathEvent, VendorDialogs, Shop, ShopUI, GambleUI, VendorLines, ExSound, VoicelinesKribugs
    globals
        private constant boolean DEBUG = false

        public constant string QUEST_OGRE_SANDWICH = "Ogre Lost His Sandwich"
        public constant string QUEST_KRIBUGS_SATCHEL = "Kribugs Lost His Satchel"
        public constant string QUEST_OGRE_THIRSTY = "Ogre Is Very Thirsty"
        public constant string QUEST_MEAT_FOR_OGRE = "Meat For The Ogre"
        public constant string QUEST_OGRE_ATE_TOO_MUCH = "Ogre Ate Too Much"
        public constant string QUEST_ANGRY_CUSTOMERS = "Angry Customers"

        private constant integer UNIT_KRIBUGS = 'n61E'
        private constant integer UNIT_GNOLL = 'ngno'
        private constant integer ITEM_OLD_SANDWICH = 'I00L'
        private constant integer ITEM_KRIBUGS_SATCHEL = 'I00M'
        private constant integer ITEM_GUTCLEANSER_ELIXIR = 'I00N'
        private constant integer ITEM_CRYSTAL_WATER = 'I6BA'
        private constant integer ABILITY_FART_CLOUD = 'A039'
        private constant integer SPECIAL_DEAL_GOLD_COST = 1000

        private constant real DIALOG_RANGE = 500.00
        private constant real DIALOG_COOLDOWN = 6.00
        private constant real DIALOG_FADE_OUT = 1.00
        private constant real DIALOG_FADE_IN = 1.00
        private constant boolean ALLOW_NAZGREK = true
        private constant boolean ALLOW_ZULKIS = true
        private constant boolean END_ON_COMBAT = true
        private constant boolean USE_DIALOG_CAMERA = true
        private constant boolean CINEMATIC = true
        private constant integer CINEMATIC_MOVE_MODE = 1
        private constant real CINEMATIC_MOVE_OFFSET = 256.00
        private constant real CINEMATIC_MOVE_ANGLE = 210.00
        private constant real CAMERA_DIST = 850.00
        private constant real CAMERA_Z_OFFSET = 20.00
        private constant real CAMERA_ANGLE = 345.00
        private constant real CAMERA_ROT_OFFSET = 180.00
        private constant real CAMERA_FAR_Z = 10000.00
        private constant real CAMERA_FOV = 75.00
        private constant real CAMERA_BLOCK_RADIUS = 0.00
        private constant boolean CAMERA_BLOCK_CHECK = true

        private constant integer ACTION_ACCEPT_SANDWICH = 1
        private constant integer ACTION_COMPLETE_SANDWICH = 2
        private constant integer ACTION_ACCEPT_SATCHEL = 3
        private constant integer ACTION_COMPLETE_SATCHEL = 4
        private constant integer ACTION_ACCEPT_THIRSTY = 5
        private constant integer ACTION_COMPLETE_THIRSTY = 6
        private constant integer ACTION_ACCEPT_MEAT = 7
        private constant integer ACTION_COMPLETE_MEAT = 8
        private constant integer ACTION_ACCEPT_CURE = 9
        private constant integer ACTION_COMPLETE_CURE = 10
        private constant integer ACTION_ACCEPT_CUSTOMERS = 11
        private constant integer ACTION_COMPLETE_CUSTOMERS = 12
        private constant integer ACTION_SPECIAL_DEAL = 13
        private constant integer ACTION_TRADE = 14

        private unit Kribugs = null
        private unit SelectedHero = null
        private integer KribugsVendorId = 0
        private dialog KribugsDialog = null
        private timer KribugsDialogCooldown = null
        private timer OgreFullSoundTimer = null
        private string PendingQuestName = ""
        private boolean PendingQuestCompletion = false
        private integer OgreFullCount = 0
        private boolean OgreFull = false
        private boolean SatchelDropped = false
        private boolean InitWaitingLogged = false
        private boolean VendorLinesRegistered = false
    endglobals

    private function DebugMsg takes string msg returns nothing
        if DEBUG then
            call BJDebugMsg("|cff88ccff[qKribugs]|r " + msg)
        endif
    endfunction

    private function SyncUnitReferences takes nothing returns nothing
        if udg_Kribugs != null and udg_Kribugs != Kribugs then
            set Kribugs = udg_Kribugs
        endif
    endfunction

    private function ResolveDialogHero takes nothing returns unit
        call SyncUnitReferences()
        return DialogInteraction_ResolveDialogHero(SelectedHero, Kribugs, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    endfunction

    private function GetKribugsQuest takes string questName returns QuestData
        call SyncUnitReferences()
        if Kribugs == null then
            return 0
        endif
        return QuestGiver_GetByNameAndGiver(questName, Kribugs)
    endfunction

    private function StartPatrol takes nothing returns nothing
        local integer i = 0

        if not DialogInteraction_IsUnitAlive(Kribugs) then
            return
        endif

        set udg_PatrolSystem_Point[0] = GetRectCenter(gg_rct_Kribugs01)
        set udg_PatrolSystem_Wait[0] = 5.00
        set udg_PatrolSystem_Point[1] = GetRectCenter(gg_rct_Kribugs02)
        set udg_PatrolSystem_Wait[1] = 20.00
        set udg_PatrolSystem_Point[2] = GetRectCenter(gg_rct_Kribugs03)
        set udg_PatrolSystem_Wait[2] = 1.00
        set udg_PatrolSystem_Point[3] = GetRectCenter(gg_rct_Kribugs04)
        set udg_PatrolSystem_Wait[3] = 1.00
        set udg_PatrolSystem_Point[4] = GetRectCenter(gg_rct_Kribugs05)
        set udg_PatrolSystem_Wait[4] = 15.00
        set udg_PatrolSystem_Point[5] = GetRectCenter(gg_rct_Kribugs06)
        set udg_PatrolSystem_Wait[5] = 15.00
        set udg_PatrolSystem_Point[6] = GetRectCenter(gg_rct_Kribugs07)
        set udg_PatrolSystem_Wait[6] = 1.00
        set udg_PatrolSystem_Point[7] = GetRectCenter(gg_rct_Kribugs08)
        set udg_PatrolSystem_Wait[7] = 10.00
        call PatrolSystem_Start(Kribugs, 8, 10.00, 1, true, "move", 190.00)

        loop
            exitwhen i >= 8
            call RemoveLocation(udg_PatrolSystem_Point[i])
            set udg_PatrolSystem_Point[i] = null
            set i = i + 1
        endloop
    endfunction

    private function PausePatrol takes nothing returns nothing
        if DialogInteraction_IsUnitAlive(Kribugs) then
            call PatrolSystem_Pause(Kribugs)
        endif
    endfunction

    private function ContinuePatrol takes nothing returns nothing
        if DialogInteraction_IsUnitAlive(Kribugs) then
            call PatrolSystem_Continue(Kribugs)
        endif
    endfunction

    private function StartExitFadeOut takes nothing returns nothing
        call DialogInteraction_EndCombatSensitiveInteraction()
        call ContinuePatrol()
        call DialogInteraction_StartConfiguredDialogExitTransition(Kribugs, SelectedHero, KribugsDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    endfunction

    private function InterruptDialog takes nothing returns nothing
        local unit hero = SelectedHero

        call DialogInteraction_EndCombatSensitiveInteraction()
        call DialogSystem_CancelActiveSpeech()
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(KribugsDialog, Player(0))
        call GambleUI_Hide()
        call DialogSystem_StopDialogCamera(Player(0), 0.75, USE_DIALOG_CAMERA)
        call TriggerExecute(gg_trg_Cinematic_OFF)
        call DialogInteraction_EndCinematicSequence(CINEMATIC)
        set KribugsDialogCooldown = DialogInteraction_StartCooldown(KribugsDialogCooldown, DIALOG_COOLDOWN)
        call ContinuePatrol()
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, Player(0))
        endif
        set PendingQuestName = ""
        set PendingQuestCompletion = false
        set SelectedHero = null
        set hero = null
    endfunction

    private function HasAnyMeat takes nothing returns boolean
        return HeroItemCheckBoth('I61Q', 1) or HeroItemCheckBoth('I620', 1) or HeroItemCheckBoth('I623', 1) or HeroItemCheckBoth('I621', 1) or HeroItemCheckBoth('I61S', 1) or HeroItemCheckBoth('I61R', 1) or HeroItemCheckBoth('I61Z', 1) or HeroItemCheckBoth('I61T', 1) or HeroItemCheckBoth('I61W', 1) or HeroItemCheckBoth('I622', 1) or HeroItemCheckBoth('I61X', 1) or HeroItemCheckBoth('I61Y', 1) or HeroItemCheckBoth('I61P', 1) or HeroItemCheckBoth('I61V', 1) or HeroItemCheckBoth('I61U', 1) or HeroItemCheckBoth('I61O', 1)
    endfunction

    private function RemoveOneMeat takes nothing returns boolean
        if HeroItemCheckBothAndRemove('I61Q', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I620', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I623', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I621', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61S', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61R', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61Z', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61T', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61W', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I622', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61X', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61Y', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61P', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61V', 1) then
            return true
        elseif HeroItemCheckBothAndRemove('I61U', 1) then
            return true
        endif
        return HeroItemCheckBothAndRemove('I61O', 1)
    endfunction

    private function CanOfferMeat takes nothing returns boolean
        return not OgreFull
    endfunction

    private function CanOfferCure takes nothing returns boolean
        return OgreFull
    endfunction

    private function RefreshCustomReadyStates takes nothing returns nothing
        local QuestData q = GetKribugsQuest(QUEST_MEAT_FOR_OGRE)

        if q != 0 and q.active and not q.completed and not q.failed then
            if HasAnyMeat() then
                call q.markRequirementCompleted(1, true)
                if q.state != QUEST_STATE_READY_TURNIN then
                    call q.setState(QUEST_STATE_READY_TURNIN)
                    call q.addReturnRequirement()
                endif
            elseif q.state == QUEST_STATE_READY_TURNIN then
                call q.markRequirementCompleted(1, false)
                call q.setState(QUEST_STATE_IN_PROGRESS)
            endif
        endif
        set q = 0
    endfunction

    private function RefreshAvailabilityInternal takes nothing returns nothing
        if Kribugs == null then
            return
        endif
        call QuestGiver_RefreshAvailabilityForGiver(Kribugs)
        call RefreshCustomReadyStates()
    endfunction

    private function ResetCompletedRepeatable takes string questName returns nothing
        local QuestData q = GetKribugsQuest(questName)

        if q == 0 or not q.completed then
            set q = 0
            return
        endif

        if q.hasReturnReq and q.returnReqIndex > 0 then
            call q.setRequirement(q.returnReqIndex, "")
        endif
        set q.req1Completed = false
        set q.req2Completed = false
        set q.req3Completed = false
        set q.req4Completed = false
        set q.req5Completed = false
        set q.req6Completed = false
        set q.req7Completed = false
        set q.req8Completed = false
        set q.returnReqIndex = 0
        set q.hasReturnReq = false
        set q.discovered = false
        set q.active = false
        set q.completed = false
        set q.failed = false
        set q.failReasonText = ""
        if q.wcQuest != null then
            call QuestSetCompleted(q.wcQuest, false)
            call QuestSetDiscovered(q.wcQuest, false)
            call QuestSetFailed(q.wcQuest, false)
        endif
        call QuestGiver_ResetRequirements(q.id)
        call q.markRequirementCompleted(1, false)
        call q.setState(QUEST_STATE_UNAVAILABLE)
        call RefreshAvailabilityInternal()
        set q = 0
    endfunction

    private function ResetMeatQuest takes nothing returns nothing
        local timer t = GetExpiredTimer()
        call ResetCompletedRepeatable(QUEST_MEAT_FOR_OGRE)
        call DestroyTimer(t)
        set t = null
    endfunction

    private function ResetCureQuest takes nothing returns nothing
        local timer t = GetExpiredTimer()
        call ResetCompletedRepeatable(QUEST_OGRE_ATE_TOO_MUCH)
        call DestroyTimer(t)
        set t = null
    endfunction

    private function OnOgreFullSound takes nothing returns nothing
        if OgreFull and DialogInteraction_IsUnitAlive(Kribugs) then
            call ExSound_PlayLabelOnUnit(VL_MOGSNORT_LEGACY_FART_KEY, Kribugs, false)
            call TimerStart(OgreFullSoundTimer, GetRandomReal(10.00, 20.00), false, function OnOgreFullSound)
        endif
    endfunction

    private function SetOgreFull takes boolean flag returns nothing
        set OgreFull = flag
        if flag then
            call UnitAddAbility(Kribugs, ABILITY_FART_CLOUD)
            call SetUnitVertexColor(Kribugs, 155, 255, 175, 255)
            call TimerStart(OgreFullSoundTimer, GetRandomReal(10.00, 20.00), false, function OnOgreFullSound)
        else
            call UnitRemoveAbility(Kribugs, ABILITY_FART_CLOUD)
            call SetUnitVertexColor(Kribugs, 255, 255, 255, 255)
            call PauseTimer(OgreFullSoundTimer)
        endif
        call RefreshAvailabilityInternal()
    endfunction

    private function SpawnOldSandwich takes nothing returns nothing
        local real x = GetRectCenterX(gg_rct_KribugsSandwich)
        local real y = GetRectCenterY(gg_rct_KribugsSandwich)
        if not HeroItemCheckBoth(ITEM_OLD_SANDWICH, 1) then
            call CreateItem(ITEM_OLD_SANDWICH, x, y)
        endif
    endfunction

    private function IsGnollType takes integer unitTypeId returns boolean
        return unitTypeId == 'ngno' or unitTypeId == 'ngnb' or unitTypeId == 'ngna' or unitTypeId == 'ngnw' or unitTypeId == 'n61A' or unitTypeId == 'n626'
    endfunction

    private function OnAnyUnitDeath takes nothing returns nothing
        local unit dyingUnit = GetTriggerUnit()
        local QuestData q = GetKribugsQuest(QUEST_KRIBUGS_SATCHEL)

        if q != 0 and q.active and not q.completed and not q.failed and not SatchelDropped and not HeroItemCheckBoth(ITEM_KRIBUGS_SATCHEL, 1) and IsGnollType(GetUnitTypeId(dyingUnit)) and GetRandomInt(1, 5) == 1 then
            call CreateItem(ITEM_KRIBUGS_SATCHEL, GetUnitX(dyingUnit), GetUnitY(dyingUnit))
            set SatchelDropped = true
        endif
        set dyingUnit = null
        set q = 0
    endfunction

    private function AddKribugsLine takes integer seq, string text, string soundKey returns nothing
        call DialogSystem_AddLine(seq, Kribugs, "Kribugs", text, soundKey, true)
    endfunction

    // Both names use the same composite unit; only the transmission speaker changes.
    private function AddMogsnortLine takes integer seq, string text, string soundKey returns nothing
        call DialogSystem_AddLine(seq, Kribugs, "Mogsnort", text, soundKey, true)
    endfunction

    private function AddRandomLegacyMogsnortLine takes integer seq returns nothing
        local integer roll = GetRandomInt(1, 5)
        if roll == 1 then
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_WHAT_3_TEXT, VL_MOGSNORT_LEGACY_WHAT_3_KEY)
        elseif roll == 2 then
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_WHAT_4_TEXT, VL_MOGSNORT_LEGACY_WHAT_4_KEY)
        elseif roll == 3 then
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_YES_1_TEXT, VL_MOGSNORT_LEGACY_YES_1_KEY)
        elseif roll == 4 then
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_YES_4_TEXT, VL_MOGSNORT_LEGACY_YES_4_KEY)
        else
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_ATTACK_3_TEXT, VL_MOGSNORT_LEGACY_ATTACK_3_KEY)
        endif
    endfunction

    private function AddQuestSequenceLines takes integer seq, string questName, boolean completing returns nothing
        if questName == QUEST_OGRE_SANDWICH then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0022_TEXT, VL_KRIBUGS_0022_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_0022_TEXT, VL_MOGSNORT_0022_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0023_TEXT, VL_KRIBUGS_0023_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0024_TEXT, VL_KRIBUGS_0024_KEY, true)
            else
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0018_TEXT, VL_KRIBUGS_0018_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0019_TEXT, VL_KRIBUGS_0019_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_0019_TEXT, VL_MOGSNORT_0019_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0020_TEXT, VL_KRIBUGS_0020_KEY, true)
            endif
        elseif questName == QUEST_KRIBUGS_SATCHEL then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0030_TEXT, VL_KRIBUGS_0030_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0031_TEXT, VL_KRIBUGS_0031_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0032_TEXT, VL_KRIBUGS_0032_KEY, true)
            else
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0026_TEXT, VL_KRIBUGS_0026_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0027_TEXT, VL_KRIBUGS_0027_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0028_TEXT, VL_KRIBUGS_0028_KEY, true)
            endif
        elseif questName == QUEST_OGRE_THIRSTY then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0038_TEXT, VL_KRIBUGS_0038_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0039_TEXT, VL_KRIBUGS_0039_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0040_TEXT, VL_KRIBUGS_0040_KEY, true)
            else
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0034_TEXT, VL_KRIBUGS_0034_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0035_TEXT, VL_KRIBUGS_0035_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_WHAT_3_TEXT, VL_MOGSNORT_LEGACY_WHAT_3_KEY)
                call AddMogsnortLine(seq, VL_MOGSNORT_0035_TEXT, VL_MOGSNORT_0035_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0036_TEXT, VL_KRIBUGS_0036_KEY, true)
            endif
        elseif questName == QUEST_MEAT_FOR_OGRE then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0046_TEXT, VL_KRIBUGS_0046_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0047_TEXT, VL_KRIBUGS_0047_KEY, true)
            else
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0043_TEXT, VL_KRIBUGS_0043_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_HUNGRY_TEXT, VL_MOGSNORT_LEGACY_HUNGRY_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0044_TEXT, VL_KRIBUGS_0044_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0045_TEXT, VL_KRIBUGS_0045_KEY, true)
            endif
        elseif questName == QUEST_OGRE_ATE_TOO_MUCH then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0054_TEXT, VL_KRIBUGS_0054_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_YES_3_TEXT, VL_MOGSNORT_LEGACY_YES_3_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0055_TEXT, VL_KRIBUGS_0055_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_0055_TEXT, VL_MOGSNORT_0055_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0056_TEXT, VL_KRIBUGS_0056_KEY, true)
            else
                call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_FART_TEXT, VL_MOGSNORT_LEGACY_FART_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0050_TEXT, VL_KRIBUGS_0050_KEY, true)
                call AddRandomLegacyMogsnortLine(seq)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0051_TEXT, VL_KRIBUGS_0051_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0052_TEXT, VL_KRIBUGS_0052_KEY, true)
            endif
        elseif questName == QUEST_ANGRY_CUSTOMERS then
            if completing then
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0070_TEXT, VL_KRIBUGS_0070_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0071_TEXT, VL_KRIBUGS_0071_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0072_TEXT, VL_KRIBUGS_0072_KEY, true)
            else
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0067_TEXT, VL_KRIBUGS_0067_KEY, true)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0068_TEXT, VL_KRIBUGS_0068_KEY, true)
                call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_ATTACK_3_TEXT, VL_MOGSNORT_LEGACY_ATTACK_3_KEY)
                call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0069_TEXT, VL_KRIBUGS_0069_KEY, true)
            endif
        endif
    endfunction

    private function CompletePendingQuest takes nothing returns nothing
        local QuestData q = GetKribugsQuest(PendingQuestName)
        local boolean canComplete = false

        if q == 0 or not q.active or q.completed then
            set q = 0
            return
        endif

        if PendingQuestName == QUEST_OGRE_SANDWICH then
            set canComplete = HeroItemCheckBothAndRemove(ITEM_OLD_SANDWICH, 1)
        elseif PendingQuestName == QUEST_KRIBUGS_SATCHEL then
            set canComplete = HeroItemCheckBothAndRemove(ITEM_KRIBUGS_SATCHEL, 1)
        elseif PendingQuestName == QUEST_OGRE_THIRSTY then
            set canComplete = HeroItemCheckBothAndRemove(ITEM_CRYSTAL_WATER, 1)
        elseif PendingQuestName == QUEST_MEAT_FOR_OGRE then
            set canComplete = RemoveOneMeat()
        elseif PendingQuestName == QUEST_OGRE_ATE_TOO_MUCH then
            set canComplete = HeroItemCheckBothAndRemove(ITEM_GUTCLEANSER_ELIXIR, 1)
        elseif PendingQuestName == QUEST_ANGRY_CUSTOMERS then
            set canComplete = q.state == QUEST_STATE_READY_TURNIN
        endif

        if canComplete then
            call q.markRequirementCompleted(1, true)
            call QuestGiver_CompleteQuestByNameAndGiver(PendingQuestName, Kribugs)
            if PendingQuestName == QUEST_KRIBUGS_SATCHEL then
                set SatchelDropped = false
            elseif PendingQuestName == QUEST_MEAT_FOR_OGRE then
                set OgreFullCount = OgreFullCount + 1
                if OgreFullCount >= 5 then
                    call SetOgreFull(true)
                endif
                call TimerStart(CreateTimer(), 6.00, false, function ResetMeatQuest)
            elseif PendingQuestName == QUEST_OGRE_ATE_TOO_MUCH then
                set OgreFullCount = 0
                call SetOgreFull(false)
                call TimerStart(CreateTimer(), 6.00, false, function ResetCureQuest)
            endif
            call RefreshAvailabilityInternal()
        endif
        set q = 0
    endfunction

    private function OnQuestSequenceEnd takes nothing returns nothing
        if PendingQuestCompletion then
            call CompletePendingQuest()
        else
            call QuestGiver_AcceptQuestByNameAndGiver(PendingQuestName, Kribugs)
            if PendingQuestName == QUEST_OGRE_SANDWICH then
                call SpawnOldSandwich()
            elseif PendingQuestName == QUEST_KRIBUGS_SATCHEL then
                set SatchelDropped = HeroItemCheckBoth(ITEM_KRIBUGS_SATCHEL, 1)
            endif
            call RefreshAvailabilityInternal()
        endif
        set PendingQuestName = ""
        set PendingQuestCompletion = false
        call StartExitFadeOut()
    endfunction

    private function StartQuestSequence takes string questName, boolean completing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq

        set PendingQuestName = questName
        set PendingQuestCompletion = completing
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Kribugs, "Kribugs")
        call DialogSystem_AddMakeFaceEachOther(seq, Kribugs, hero, 0.50, 0.00)
        call AddQuestSequenceLines(seq, questName, completing)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnQuestSequenceEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Kribugs)
        set hero = null
    endfunction

    private function OnAcceptSandwich takes nothing returns nothing
        call StartQuestSequence(QUEST_OGRE_SANDWICH, false)
    endfunction

    private function OnCompleteSandwich takes nothing returns nothing
        call StartQuestSequence(QUEST_OGRE_SANDWICH, true)
    endfunction

    private function OnAcceptSatchel takes nothing returns nothing
        call StartQuestSequence(QUEST_KRIBUGS_SATCHEL, false)
    endfunction

    private function OnCompleteSatchel takes nothing returns nothing
        call StartQuestSequence(QUEST_KRIBUGS_SATCHEL, true)
    endfunction

    private function OnAcceptThirsty takes nothing returns nothing
        call StartQuestSequence(QUEST_OGRE_THIRSTY, false)
    endfunction

    private function OnCompleteThirsty takes nothing returns nothing
        call StartQuestSequence(QUEST_OGRE_THIRSTY, true)
    endfunction

    private function OnAcceptMeat takes nothing returns nothing
        call StartQuestSequence(QUEST_MEAT_FOR_OGRE, false)
    endfunction

    private function OnCompleteMeat takes nothing returns nothing
        call StartQuestSequence(QUEST_MEAT_FOR_OGRE, true)
    endfunction

    private function OnAcceptCure takes nothing returns nothing
        call StartQuestSequence(QUEST_OGRE_ATE_TOO_MUCH, false)
    endfunction

    private function OnFailedCureEnd takes nothing returns nothing
        call StartExitFadeOut()
    endfunction

    private function OnCompleteCure takes nothing returns nothing
        local integer seq
        if GetRandomInt(1, 2) == 1 then
            call StartQuestSequence(QUEST_OGRE_ATE_TOO_MUCH, true)
            return
        endif
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Kribugs, "Kribugs")
        call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0053_TEXT, VL_KRIBUGS_0053_KEY, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnFailedCureEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Kribugs)
    endfunction

    private function OnAcceptCustomers takes nothing returns nothing
        call StartQuestSequence(QUEST_ANGRY_CUSTOMERS, false)
    endfunction

    private function OnCompleteCustomers takes nothing returns nothing
        call StartQuestSequence(QUEST_ANGRY_CUSTOMERS, true)
    endfunction

    private function OpenTrade takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        if hero == null or not Shop_CanPlayerTradeWithVendor(GetOwningPlayer(hero), Kribugs) then
            set hero = null
            call StartExitFadeOut()
            return
        endif

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(KribugsDialog, Player(0))
        call VendorLines_PlayTradeLine(Kribugs)
        call ShowUnit(hero, true)
        set KribugsDialogCooldown = DialogInteraction_StartCooldown(KribugsDialogCooldown, DIALOG_COOLDOWN)
        call ShopUI_ShowForVendorWithReturnAndInterrupt(Kribugs, hero, END_ON_COMBAT, function InterruptDialog)
        set hero = null
    endfunction

    private function OnTrade takes nothing returns nothing
        call OpenTrade()
    endfunction

    private function OnGamblePurchaseEnd takes nothing returns nothing
        call StartExitFadeOut()
    endfunction

    private function OnGamblePurchase takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Kribugs, "Kribugs")
        if GetRandomInt(1, 3) == 1 then
            call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0062_TEXT, VL_KRIBUGS_0062_KEY, true)
        elseif GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0063_TEXT, VL_KRIBUGS_0063_KEY, true)
        else
            call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0064_TEXT, VL_KRIBUGS_0064_KEY, true)
        endif
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnGamblePurchaseEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Kribugs)
    endfunction

    private function OnSpecialDealEnd takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        if hero == null or not DialogInteraction_IsUnitAlive(Kribugs) then
            set hero = null
            call StartExitFadeOut()
            return
        endif

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(KribugsDialog, Player(0))
        call ShowUnit(hero, true)
        call PauseUnit(hero, false)
        call EnableUserControl(true)
        call GambleUI_Show(Kribugs, hero, SPECIAL_DEAL_GOLD_COST)
        set hero = null
    endfunction

    private function OnSpecialDeal takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Kribugs, "Kribugs")
        if GetRandomInt(1, 2) == 1 then
            call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0059_TEXT, VL_KRIBUGS_0059_KEY, true)
        else
            call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0060_TEXT, VL_KRIBUGS_0060_KEY, true)
        endif
        call DialogSystem_AddLine(seq, Kribugs, "Kribugs", VL_KRIBUGS_0061_TEXT, VL_KRIBUGS_0061_KEY, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnSpecialDealEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Kribugs)
    endfunction

    private function OnFarewellEnd takes nothing returns nothing
        call StartExitFadeOut()
    endfunction

    private function OnFarewell takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateFarewellSequence(Kribugs, "Kribugs", hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Kribugs)
        set hero = null
    endfunction

    private function BuildDialog takes nothing returns nothing
        local button b

        if KribugsDialog == null then
            set KribugsDialog = DialogSystem_CreateDialog("Kribugs")
        endif
        call RefreshAvailabilityInternal()
        call DialogSystem_ClearDialog(KribugsDialog)
        call DialogSystem_SetTitle(KribugsDialog, "Kribugs")

        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_OGRE_SANDWICH, Kribugs, ACTION_ACCEPT_SANDWICH, function OnAcceptSandwich, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_OGRE_SANDWICH, Kribugs, ACTION_COMPLETE_SANDWICH, function OnCompleteSandwich, true)
        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_KRIBUGS_SATCHEL, Kribugs, ACTION_ACCEPT_SATCHEL, function OnAcceptSatchel, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_KRIBUGS_SATCHEL, Kribugs, ACTION_COMPLETE_SATCHEL, function OnCompleteSatchel, true)
        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_OGRE_THIRSTY, Kribugs, ACTION_ACCEPT_THIRSTY, function OnAcceptThirsty, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_OGRE_THIRSTY, Kribugs, ACTION_COMPLETE_THIRSTY, function OnCompleteThirsty, true)
        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_MEAT_FOR_OGRE, Kribugs, ACTION_ACCEPT_MEAT, function OnAcceptMeat, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_MEAT_FOR_OGRE, Kribugs, ACTION_COMPLETE_MEAT, function OnCompleteMeat, false)
        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_OGRE_ATE_TOO_MUCH, Kribugs, ACTION_ACCEPT_CURE, function OnAcceptCure, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_OGRE_ATE_TOO_MUCH, Kribugs, ACTION_COMPLETE_CURE, function OnCompleteCure, true)
        call QuestGiver_AddAvailableQuestAcceptButton(KribugsDialog, QUEST_ANGRY_CUSTOMERS, Kribugs, ACTION_ACCEPT_CUSTOMERS, function OnAcceptCustomers, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(KribugsDialog, QUEST_ANGRY_CUSTOMERS, Kribugs, ACTION_COMPLETE_CUSTOMERS, function OnCompleteCustomers, false)

        set b = DialogSystem_AddButton(KribugsDialog, "Special Deal", ACTION_SPECIAL_DEAL)
        call DialogSystem_BindButtonCode(b, function OnSpecialDeal)
        set b = DialogSystem_AddButtonTrade(KribugsDialog, ACTION_TRADE)
        call DialogSystem_BindButtonCode(b, function OnTrade)
        set b = DialogSystem_AddFarewellButton(KribugsDialog)
        call DialogSystem_BindButtonCode(b, function OnFarewell)
        set b = null
    endfunction

    private function AddPreDialogBark takes integer seq returns nothing
        local integer roll
        if not DialogInteraction_IsFirstGreetDone(Kribugs) then
            call AddKribugsLine(seq, VL_KRIBUGS_0001_TEXT, VL_KRIBUGS_0001_KEY)
            return
        endif

        set roll = GetRandomInt(1, 8)
        if roll == 1 then
            call AddMogsnortLine(seq, VL_MOGSNORT_LEGACY_HUNGRY_TEXT, VL_MOGSNORT_LEGACY_HUNGRY_KEY)
            call AddKribugsLine(seq, VL_KRIBUGS_0010_TEXT, VL_KRIBUGS_0010_KEY)
        elseif roll == 2 then
            call AddKribugsLine(seq, VL_KRIBUGS_0011_TEXT, VL_KRIBUGS_0011_KEY)
            call AddRandomLegacyMogsnortLine(seq)
        elseif roll == 3 then
            call AddKribugsLine(seq, VL_KRIBUGS_0012_TEXT, VL_KRIBUGS_0012_KEY)
        elseif roll == 4 then
            call AddKribugsLine(seq, VL_KRIBUGS_0013_TEXT, VL_KRIBUGS_0013_KEY)
            call AddRandomLegacyMogsnortLine(seq)
        elseif roll == 5 then
            call AddKribugsLine(seq, VL_KRIBUGS_0014_TEXT, VL_KRIBUGS_0014_KEY)
            call AddRandomLegacyMogsnortLine(seq)
        elseif roll == 6 then
            call AddKribugsLine(seq, VL_KRIBUGS_0004_TEXT, VL_KRIBUGS_0004_KEY)
        elseif roll == 7 then
            call AddKribugsLine(seq, VL_KRIBUGS_0010_TEXT, VL_KRIBUGS_0010_KEY)
            call AddMogsnortLine(seq, VL_MOGSNORT_0010_TEXT, VL_MOGSNORT_0010_KEY)
        else
            call AddKribugsLine(seq, VL_KRIBUGS_0011_TEXT, VL_KRIBUGS_0011_KEY)
            call AddMogsnortLine(seq, VL_MOGSNORT_0011_TEXT, VL_MOGSNORT_0011_KEY)
        endif
    endfunction

    private function ContinueToDialogInternal takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq
        if hero == null or not DialogInteraction_IsUnitAlive(Kribugs) then
            set hero = null
            call StartExitFadeOut()
            return
        endif
        call BuildDialog()
        set seq = DialogInteraction_CreateGreetSequenceBase(Kribugs, "Kribugs", hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
        call AddPreDialogBark(seq)
        call DialogInteraction_PlayGreetSequenceEx(seq, Kribugs, Player(0), KribugsDialog, CINEMATIC)
        set hero = null
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        call ContinueToDialogInternal()
    endfunction

    private function OnSelected takes nothing returns nothing
        call SyncUnitReferences()
        set SelectedHero = DialogInteraction_GetDialogSelectionHero(Kribugs, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        if not DialogInteraction_PassDialogSelectionGate(Kribugs, SelectedHero, DIALOG_RANGE, KribugsDialogCooldown, true, true, true, true, false, true) then
            call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
            set SelectedHero = null
            return
        endif
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(Kribugs, SelectedHero, function InterruptDialog, END_ON_COMBAT) then
            set SelectedHero = null
            return
        endif
        call PausePatrol()
        call DialogInteraction_StartConfiguredDialogEntryTransition(Kribugs, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qKribugs_ContinueToDialogAfterSelection")
    endfunction

    private function ReturnFromTrade takes nothing returns boolean
        local unit vendor = ShopUI_GetVendorUnit()
        local unit hero = ShopUI_GetBuyerUnit()
        if vendor != Kribugs or hero == null or not DialogInteraction_IsUnitAlive(vendor) or not DialogInteraction_IsUnitAlive(hero) then
            set vendor = null
            set hero = null
            return false
        endif
        set SelectedHero = hero
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(vendor, hero, function InterruptDialog, END_ON_COMBAT) then
            set SelectedHero = null
            set vendor = null
            set hero = null
            return false
        endif
        call PauseUnit(hero, true)
        call BuildDialog()
        call DialogSystem_SetContext(vendor, GetOwningPlayer(hero))
        call DialogSystem_ShowDialog(KribugsDialog, GetOwningPlayer(hero))
        set vendor = null
        set hero = null
        return true
    endfunction

    private function OnGambleReturn takes nothing returns nothing
        local unit vendor = GambleUI_GetVendorUnit()
        local unit hero = GambleUI_GetBuyerUnit()
        if vendor != Kribugs or hero == null or not DialogInteraction_IsUnitAlive(vendor) or not DialogInteraction_IsUnitAlive(hero) then
            set vendor = null
            set hero = null
            call StartExitFadeOut()
            return
        endif
        set SelectedHero = hero
        call EnableUserControl(false)
        call PauseUnit(hero, true)
        call BuildDialog()
        call DialogSystem_SetContext(vendor, GetOwningPlayer(hero))
        call DialogSystem_ShowDialog(KribugsDialog, GetOwningPlayer(hero))
        set vendor = null
        set hero = null
    endfunction

    private function CreateQuests takes nothing returns nothing
        local QuestData q
        local string infoText = "|cffffcc00Quest giver:|r Kribugs\n"
        local trigger availabilityCondition

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_OGRE_SANDWICH, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_OGRE_SANDWICH, Kribugs, "normal", 1, null, QUEST_OGRE_SANDWICH, "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Food_11.TGA", "Find Kribugs' carrier ogre's lost sandwich along their usual travel road.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_RegisterItemRequirement(q.id, Kribugs, 1, ITEM_OLD_SANDWICH, 1)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_KRIBUGS_SATCHEL, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_KRIBUGS_SATCHEL, Kribugs, "normal", 2, null, QUEST_KRIBUGS_SATCHEL, "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Bag_04.TGA", "Find Kribugs' lost satchel. He suspects that the gnolls stole it.\n\n", infoText, "|cffffcc00Recommended level:|r 2\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_OGRE_SANDWICH, Kribugs)
            call QuestGiver_RegisterItemRequirement(q.id, Kribugs, 1, ITEM_KRIBUGS_SATCHEL, 1)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_OGRE_THIRSTY, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_OGRE_THIRSTY, Kribugs, "normal", 5, null, QUEST_OGRE_THIRSTY, "ReplaceableTextures\\CommandButtons\\BTNOneHeadedOgre.blp", "Find Crystal Water for Kribugs' ogre carrier.\n\n", infoText, "|cffffcc00Recommended level:|r 5\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_OGRE_SANDWICH, Kribugs)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_KRIBUGS_SATCHEL, Kribugs)
            call QuestGiver_RegisterItemRequirement(q.id, Kribugs, 1, ITEM_CRYSTAL_WATER, 1)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MEAT_FOR_OGRE, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_MEAT_FOR_OGRE, Kribugs, "repeatable", 2, null, QUEST_MEAT_FOR_OGRE, "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Food_18.TGA", "Find and bring any raw meat for Kribugs' ogre carrier.\n\n", infoText, "|cffffcc00Recommended level:|r 2\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_SetRequirements(q.id, "", "Bring any raw meat to Kribugs", "", "", "", "", "", "", "")
            set availabilityCondition = CreateTrigger()
            call TriggerAddCondition(availabilityCondition, Condition(function CanOfferMeat))
            call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_OGRE_ATE_TOO_MUCH, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_OGRE_ATE_TOO_MUCH, Kribugs, "repeatable", 2, null, QUEST_OGRE_ATE_TOO_MUCH, "ReplaceableTextures\\PassiveButtons\\PASBTNPlagueCloud.blp", "Find something to cure Kribugs' ogre carrier.\n\n", infoText, "|cffffcc00Recommended level:|r 2\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_RegisterItemRequirement(q.id, Kribugs, 1, ITEM_GUTCLEANSER_ELIXIR, 1)
            set availabilityCondition = CreateTrigger()
            call TriggerAddCondition(availabilityCondition, Condition(function CanOfferCure))
            call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
            call QuestGiver_SetStateByNameAndGiver(QUEST_OGRE_ATE_TOO_MUCH, Kribugs, QUEST_STATE_UNAVAILABLE)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_ANGRY_CUSTOMERS, Kribugs) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_ANGRY_CUSTOMERS, Kribugs, "normal", 3, null, QUEST_ANGRY_CUSTOMERS, "ReplaceableTextures\\CommandButtons\\BTNJunkGolem.blp", "Chase down the gnolls posing as Kribugs' angry customers.\n\n", infoText, "|cffffcc00Recommended level:|r 3\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", "Kribugs")
            call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_OGRE_SANDWICH, Kribugs)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_KRIBUGS_SATCHEL, Kribugs)
            call QuestGiver_RegisterUnitKillRequirement(q.id, Kribugs, 1, UNIT_GNOLL, 10)
        endif

        set availabilityCondition = null
        set q = 0
    endfunction

    private function RegisterDialogLines takes nothing returns nothing
        call DialogSystem_RegisterFarewellLineForUnit(Kribugs, VL_KRIBUGS_0007_TEXT, VL_KRIBUGS_0007_KEY, true)
        call DialogSystem_RegisterFarewellLineForUnit(Kribugs, VL_KRIBUGS_0008_TEXT, VL_KRIBUGS_0008_KEY, true)
        call DialogSystem_RegisterFarewellLineForUnit(Kribugs, VL_KRIBUGS_0009_TEXT, VL_KRIBUGS_0009_KEY, true)
    endfunction

    private function RegisterVendorLines takes nothing returns nothing
        if VendorLinesRegistered then
            return
        endif
        set VendorLinesRegistered = true
        call DialogSystem_RegisterTradeLine("Kribugs", VL_KRIBUGS_0006_TEXT, VL_KRIBUGS_0006_KEY, true)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_CHATTER, VL_KRIBUGS_0012_TEXT, VL_KRIBUGS_0012_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_CHATTER, VL_KRIBUGS_0013_TEXT, VL_KRIBUGS_0013_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_CHATTER, VL_KRIBUGS_0014_TEXT, VL_KRIBUGS_0014_KEY)
        call VendorLines_RegisterSpeakerLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_CHATTER, "Mogsnort", VL_MOGSNORT_VENDOR_CHATTER_TEXT, VL_MOGSNORT_VENDOR_CHATTER_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_BOUGHT, VL_KRIBUGS_VENDOR_BOUGHT_TEXT, VL_KRIBUGS_VENDOR_BOUGHT_KEY)
        call VendorLines_RegisterSpeakerLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_BOUGHT, "Mogsnort", VL_MOGSNORT_VENDOR_BOUGHT_TEXT, VL_MOGSNORT_VENDOR_BOUGHT_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_SOLD, VL_KRIBUGS_VENDOR_SOLD_TEXT, VL_KRIBUGS_VENDOR_SOLD_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_BOUGHT_AND_SOLD, VL_KRIBUGS_VENDOR_EXCHANGED_TEXT, VL_KRIBUGS_VENDOR_EXCHANGED_KEY)
        call VendorLines_RegisterLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_NO_TRANSACTION, VL_KRIBUGS_VENDOR_NO_TRADE_TEXT, VL_KRIBUGS_VENDOR_NO_TRADE_KEY)
        call VendorLines_RegisterSpeakerLine(VL_KRIBUGS_VENDOR_PROFILE, VendorLines_LINE_NO_TRANSACTION, "Mogsnort", VL_MOGSNORT_VENDOR_NO_TRADE_TEXT, VL_MOGSNORT_VENDOR_NO_TRADE_KEY)
    endfunction

    private function ConfigureVendor takes nothing returns nothing
        call RegisterVendorLines()
        if KribugsVendorId == 0 then
            set KribugsVendorId = Shop_CreateVendor("Kribugs", UNIT_KRIBUGS)
            call Shop_SetVendorTypeLabel(KribugsVendorId, "Goblin General Goods")
            call Shop_AddStock(KribugsVendorId, 'I611', 35, "Camp")
            call Shop_AddStock(KribugsVendorId, 'hslv', 45, "Recovery")
            call Shop_AddStock(KribugsVendorId, 'I60Z', 20, "Provisions")
            call Shop_AddStock(KribugsVendorId, 'I672', 75, "Tools")
            call Shop_AddStock(KribugsVendorId, 'I66M', 75, "Tools")
        endif
        call Shop_SetVendorUnitTypeName(UNIT_KRIBUGS, "Kribugs")
        call Shop_RegisterVendorUnit(Kribugs, KribugsVendorId)
        call VendorLines_BindUnitProfile(Kribugs, VL_KRIBUGS_VENDOR_PROFILE)
        call ShopUI_RegisterVendorReturnHandler(Kribugs, function ReturnFromTrade)
        call VendorDialogs_RegisterCustomVendor(Kribugs, function ReturnFromTrade)
    endfunction

    private function ConfigureGamble takes nothing returns nothing
        call GambleUI_ClearRewards()
        call GambleUI_AddReward('I6B1', 2)
        call GambleUI_AddReward('I6B2', 2)
        call GambleUI_AddReward('I6B6', 2)
        call GambleUI_AddReward('I66E', 2)
        call GambleUI_AddReward('phea', 3)
        call GambleUI_AddReward('pman', 3)
        call GambleUI_AddReward('hslv', 3)
        call GambleUI_AddReward('I6BC', 3)
        call GambleUI_AddReward('I60Y', 3)
        call GambleUI_AddReward('I689', 3)
        call GambleUI_AddReward('I67E', 3)
        call GambleUI_AddReward('I6A6', 3)
        call GambleUI_AddReward('I62Z', 1)
        call GambleUI_AddReward('I6CS', 1)
        call GambleUI_AddReward('I67K', 1)
        call GambleUI_RegisterPurchaseHandler(function OnGamblePurchase)
        call GambleUI_RegisterReturnHandler(function OnGambleReturn)
    endfunction

    private function InitDelayed takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        call SyncUnitReferences()
        if Kribugs == null then
            if not InitWaitingLogged then
                call DebugMsg("Waiting for udg_Kribugs.")
                set InitWaitingLogged = true
            endif
            call TimerStart(initTimer, 0.50, false, function InitDelayed)
            set initTimer = null
            return
        endif

        call ConfigureVendor()
        call QuestGiver_Register(Kribugs)
        call DialogInteraction_ConfigureDialogTransition(Kribugs, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_SetGreetOrder(Kribugs, DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC)
        call RegisterDialogLines()
        call CreateQuests()
        call RefreshAvailabilityInternal()
        call DialogInteraction_RegisterSelectionHandler(Kribugs, function OnSelected)
        call UnitDeathEvent_Register(function OnAnyUnitDeath)
        call StartPatrol()
        call DebugMsg("Initialized.")
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        set KribugsDialogCooldown = CreateTimer()
        set OgreFullSoundTimer = CreateTimer()
        call ConfigureGamble()
        call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
    endfunction

    public function RefreshAvailability takes nothing returns nothing
        call SyncUnitReferences()
        call RefreshAvailabilityInternal()
    endfunction

    public function RefreshRespawnedUnitHooks takes nothing returns nothing
        call SyncUnitReferences()
        if Kribugs == null then
            return
        endif
        call ConfigureVendor()
        call QuestGiver_Register(Kribugs)
        call DialogInteraction_ConfigureDialogTransition(Kribugs, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Kribugs, function OnSelected)
        call RefreshAvailabilityInternal()
        call StartPatrol()
    endfunction
endlibrary
