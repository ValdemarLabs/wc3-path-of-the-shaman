/**
    qOutcastJinzun

    Author: Valdemar
    Version: 1.0.0

    Description:
    Quest, dialogue, patrol, fishing, ward-placement, tree-restoration, and
    cross-quest interaction logic for Outcast Jin'Zun, converted from the
    legacy GUI trigger group.

    Credits:
    - Legacy GUI triggers in QuestsAndDialogs/OLDGUI/OutcastJinzun.

    How to install:
    Import after the required quest, dialogue, patrol, item, sound, and
    voiceline libraries. Disable the converted OutcastJinzun GUI trigger
    group. Keep the Unknown Entity encounter and Crypt encounter triggers,
    and connect them through the public update hooks below.

    API:
    - call qOutcastJinzun_UpdateUnknownEntityLure()
    - call qOutcastJinzun_UpdateUnknownEntityKill()
    - call qOutcastJinzun_UpdateUnknownEntitySlime()
    - call qOutcastJinzun_CompleteResurgenceOfDeadPart2Objective()
    - qOutcastJinzun_IsFishingPoleQuestActive()
    - call qOutcastJinzun_RefreshAvailability()
    - call qOutcastJinzun_RefreshRespawnedUnitHooks()

**/
library qOutcastJinzun initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, PatrolSystem, HeroItemCheck, ExSound, VoicelinesJinzun, VoicelinesNazgrek, VoicelinesDemoness
    globals
        private constant boolean DEBUG = false

        public constant string QUEST_PLAGUE_TREES = "Plague Upon Trees"
        public constant string QUEST_LURKING_SHADOWS = "Lurking In The Shadows"
        public constant string QUEST_UNKNOWN_ENTITY = "Unknown Entity"
        public constant string QUEST_SEEDS_LIFE = "Seeds of Life"
        public constant string QUEST_RESURGENCE_DEAD_1 = "Resurgence of Dead I"
        public constant string QUEST_RESURGENCE_DEAD_2 = "Resurgence of Dead II"
        public constant string QUEST_FISHING_POLE = "Da Fishing Pole Missing"

        private constant string JINZUN_NAME = "Outcast Jin'Zun"
        private constant integer UNIT_JINZUN = 'o60X'
        private constant integer UNIT_HEALING_WARD = 'o61R'
        private constant integer ITEM_HEALING_WARD = 'I624'
        private constant integer ITEM_SARGOTH_ICHOR = 'I66I'
        private constant integer ITEM_DISGUSTING_SLIME = 'I66O'
        private constant integer ITEM_ROTTEN_PART = 'I66P'
        private constant integer ITEM_JINZUN_FISHING_POLE = 'I6CJ'
        private constant integer ITEM_SEEDS_OF_LIFE = 'I6AL'
        private constant integer ITEM_RESTORATION_POTION = 'pres'
        private constant integer ABILITY_SEEDS_OF_LIFE = 'A6AM'
        private constant integer ABILITY_VENOMWEAVE_FLASK = 'A64Y'
        private constant integer ABILITY_JINZUN_FISHING_POLE = 'A6DN'
        private constant integer DESTRUCTIBLE_MIGHTY_TREE_ALIVE = 'B61I'

        private constant real DIALOG_RANGE = 500.00
        private constant real DIALOG_COOLDOWN = 6.00
        private constant real DIALOG_FADE_OUT = 1.00
        private constant real DIALOG_FADE_IN = 1.00
        private constant boolean ALLOW_NAZGREK = true
        private constant boolean ALLOW_ZULKIS = false
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
        private constant real FISHING_SPOT_ARRIVAL_RANGE = 450.00
        private constant string FISHING_ANIMATION = "stand work"
        private constant string FISHING_HERO_TEXT = "How are the fish biting at your favorite spot, Jin'Zun?"
        private constant string FISHING_JINZUN_TEXT = "Ahh, dis be da spot, mon. Best fish in da whole lake, if ya got da right pole."
        private constant string FISHING_JINZUN_NO_POLE_TEXT = "Dis still be da best spot, mon. Hard to catch anythin' without me old pole, though."

        private constant integer ACTION_ACCEPT_PLAGUE = 1
        private constant integer ACTION_COMPLETE_PLAGUE = 2
        private constant integer ACTION_ACCEPT_SHADOWS = 3
        private constant integer ACTION_COMPLETE_SHADOWS = 4
        private constant integer ACTION_ACCEPT_UNKNOWN = 5
        private constant integer ACTION_COMPLETE_UNKNOWN = 6
        private constant integer ACTION_ACCEPT_SEEDS = 7
        private constant integer ACTION_COMPLETE_SEEDS = 8
        private constant integer ACTION_ACCEPT_RESURGENCE_1 = 9
        private constant integer ACTION_COMPLETE_RESURGENCE_1 = 10
        private constant integer ACTION_COMPLETE_RESURGENCE_2 = 11
        private constant integer ACTION_ACCEPT_FISHING = 12
        private constant integer ACTION_COMPLETE_FISHING = 13
        private constant integer ACTION_RECOVER_WARDS = 14
        private constant integer ACTION_RECOVER_SEEDS = 15
        private constant integer ACTION_DECLINE = 16

        private unit Jinzun = null
        private unit Nazgrek = null
        private unit SelectedHero = null
        private dialog JinzunDialog = null
        private timer JinzunDialogCooldown = null
        private timer QuestPingTimer = null
        private timer FishingBehaviorTimer = null
        private trigger WardDropTrigger = null
        private trigger SeedsSpellTrigger = null
        private trigger MovementSoundTrigger = null
        private string PendingQuestName = ""
        private boolean PendingQuestCompletion = false
        private boolean JinzunTalking = false
        private boolean InitWaitingLogged = false
        private boolean UnknownSlimeRequirementRegistered = false
        private boolean FishingSpotMode = false
        private boolean FishingAnimationPlaying = false
        private integer PlagueWardsPlaced = 0
        private integer SeedsTreesRestored = 0
        private boolean array PlagueWardPlaced
        private boolean array SeedsTreeRestored
    endglobals

    private function DebugMsg takes string msg returns nothing
        if DEBUG then
            call BJDebugMsg("|cff88ccff[qOutcastJinzun]|r " + msg)
        endif
    endfunction

    private function SyncUnitReferences takes nothing returns nothing
        if udg_OutcastJinzun != null and udg_OutcastJinzun != Jinzun then
            set Jinzun = udg_OutcastJinzun
        endif
        if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
            set Nazgrek = udg_Nazgrek
        endif
    endfunction

    private function ResolveDialogHero takes nothing returns unit
        call SyncUnitReferences()
        set SelectedHero = DialogInteraction_ResolveDialogHero(SelectedHero, Jinzun, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        if SelectedHero == null and DialogInteraction_IsUnitAlive(Nazgrek) then
            set SelectedHero = Nazgrek
        endif
        return SelectedHero
    endfunction

    private function GetJinzunQuest takes string questName returns QuestData
        call SyncUnitReferences()
        if Jinzun == null then
            return 0
        endif
        return QuestGiver_GetByNameAndGiver(questName, Jinzun)
    endfunction

    private function IsQuestActive takes string questName returns boolean
        local QuestData q = GetJinzunQuest(questName)
        if q == 0 then
            return false
        endif
        return q.active and not q.completed and not q.failed
    endfunction

    private function HasFishingPole takes nothing returns boolean
        return DialogInteraction_IsUnitAlive(Jinzun) and GetUnitAbilityLevel(Jinzun, ABILITY_JINZUN_FISHING_POLE) > 0
    endfunction

    private function IsJinzunAtFishingSpot takes nothing returns boolean
        local real dx
        local real dy
        if not DialogInteraction_IsUnitAlive(Jinzun) then
            return false
        endif
        set dx = GetUnitX(Jinzun) - GetRectCenterX(gg_rct_LakeAmbient62)
        set dy = GetUnitY(Jinzun) - GetRectCenterY(gg_rct_LakeAmbient62)
        return dx * dx + dy * dy <= FISHING_SPOT_ARRIVAL_RANGE * FISHING_SPOT_ARRIVAL_RANGE
    endfunction

    private function FaceFishingSpot takes nothing returns nothing
        call SetUnitFacing(Jinzun, bj_RADTODEG * Atan2(GetRectCenterY(gg_rct_LakeAmbient62) - GetUnitY(Jinzun), GetRectCenterX(gg_rct_LakeAmbient62) - GetUnitX(Jinzun)))
    endfunction

    private function UpdateFishingAnimation takes nothing returns nothing
        if not FishingSpotMode or JinzunTalking or not IsJinzunAtFishingSpot() then
            return
        endif
        if HasFishingPole() then
            if not FishingAnimationPlaying then
                call FaceFishingSpot()
                call SetUnitAnimation(Jinzun, FISHING_ANIMATION)
                set FishingAnimationPlaying = true
            endif
        elseif FishingAnimationPlaying then
            call SetUnitAnimation(Jinzun, "stand")
            set FishingAnimationPlaying = false
        endif
    endfunction

    private function ResumeFishingSpotBehavior takes nothing returns nothing
        if not DialogInteraction_IsUnitAlive(Jinzun) then
            return
        endif
        set FishingAnimationPlaying = false
        if IsJinzunAtFishingSpot() then
            call UpdateFishingAnimation()
        else
            call IssuePointOrder(Jinzun, "move", GetRectCenterX(gg_rct_LakeAmbient62), GetRectCenterY(gg_rct_LakeAmbient62))
        endif
    endfunction

    private function EnterFishingSpotMode takes nothing returns nothing
        set FishingSpotMode = true
        set FishingAnimationPlaying = false
        if DialogInteraction_IsUnitAlive(Jinzun) then
            call PatrolSystem_Stop(Jinzun)
            if not JinzunTalking then
                call ResumeFishingSpotBehavior()
            endif
        endif
    endfunction

    private function OnFishingBehaviorTick takes nothing returns nothing
        if not FishingSpotMode or JinzunTalking or not DialogInteraction_IsUnitAlive(Jinzun) then
            return
        endif
        if IsJinzunAtFishingSpot() then
            call UpdateFishingAnimation()
        elseif GetUnitCurrentOrder(Jinzun) == 0 then
            call ResumeFishingSpotBehavior()
        endif
    endfunction

    private function StartPatrol takes nothing returns nothing
        local integer i = 0
        if not DialogInteraction_IsUnitAlive(Jinzun) then
            return
        endif

        set FishingSpotMode = false
        set FishingAnimationPlaying = false

        set udg_PatrolSystem_Point[0] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[0] = 15.00
        set udg_PatrolSystem_Point[1] = GetRectCenter(gg_rct_JinzunWander004)
        set udg_PatrolSystem_Wait[1] = 5.00
        set udg_PatrolSystem_Point[2] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[2] = 10.00
        set udg_PatrolSystem_Point[3] = GetRectCenter(gg_rct_JinzunWander002)
        set udg_PatrolSystem_Wait[3] = 5.00
        set udg_PatrolSystem_Point[4] = GetRectCenter(gg_rct_JinzunWander005)
        set udg_PatrolSystem_Wait[4] = 10.00
        set udg_PatrolSystem_Point[5] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[5] = 10.00
        set udg_PatrolSystem_Point[6] = GetRectCenter(gg_rct_JinzunWander007)
        set udg_PatrolSystem_Wait[6] = 15.00
        set udg_PatrolSystem_Point[7] = GetRectCenter(gg_rct_JinzunWander006)
        set udg_PatrolSystem_Wait[7] = 15.00
        set udg_PatrolSystem_Point[8] = GetRectCenter(gg_rct_JinzunWander003)
        set udg_PatrolSystem_Wait[8] = 10.00
        set udg_PatrolSystem_Point[9] = GetRectCenter(gg_rct_JinzunWander008)
        set udg_PatrolSystem_Wait[9] = 15.00
        set udg_PatrolSystem_Point[10] = GetRectCenter(gg_rct_JinzunWander009)
        set udg_PatrolSystem_Wait[10] = 15.00
        set udg_PatrolSystem_Point[11] = GetRectCenter(gg_rct_JinzunWander002)
        set udg_PatrolSystem_Wait[11] = 10.00
        set udg_PatrolSystem_Point[12] = GetRectCenter(gg_rct_JinzunWander010)
        set udg_PatrolSystem_Wait[12] = 15.00
        set udg_PatrolSystem_Point[13] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[13] = 10.00
        set udg_PatrolSystem_Point[14] = GetRectCenter(gg_rct_JinzunWander011)
        set udg_PatrolSystem_Wait[14] = 15.00
        set udg_PatrolSystem_Point[15] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[15] = 10.00
        set udg_PatrolSystem_Point[16] = GetRectCenter(gg_rct_JinzunWander012)
        set udg_PatrolSystem_Wait[16] = 15.00
        set udg_PatrolSystem_Point[17] = GetRectCenter(gg_rct_JinzunWander001)
        set udg_PatrolSystem_Wait[17] = 10.00
        set udg_PatrolSystem_Point[18] = GetRectCenter(gg_rct_JinzunWander013)
        set udg_PatrolSystem_Wait[18] = 10.00
        call PatrolSystem_Start(Jinzun, 19, 10.00, 1, true, "move", 150.00)

        loop
            exitwhen i >= 19
            call RemoveLocation(udg_PatrolSystem_Point[i])
            set udg_PatrolSystem_Point[i] = null
            set i = i + 1
        endloop
        set JinzunTalking = false
    endfunction

    private function PausePatrol takes nothing returns nothing
        set JinzunTalking = true
        if DialogInteraction_IsUnitAlive(Jinzun) then
            call PatrolSystem_Pause(Jinzun)
            if FishingSpotMode and FishingAnimationPlaying then
                call SetUnitAnimation(Jinzun, "stand")
                set FishingAnimationPlaying = false
            endif
        endif
    endfunction

    private function ContinuePatrol takes nothing returns nothing
        set JinzunTalking = false
        if DialogInteraction_IsUnitAlive(Jinzun) then
            if FishingSpotMode then
                call ResumeFishingSpotBehavior()
            else
                call PatrolSystem_Continue(Jinzun)
            endif
        endif
    endfunction

    private function StartExitFadeOut takes nothing returns nothing
        call ContinuePatrol()
        call DialogInteraction_StartConfiguredDialogExitTransition(Jinzun, SelectedHero, JinzunDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
    endfunction

    private function IsPlayerHeroNearJinzun takes real range returns boolean
        if DialogInteraction_IsUnitAlive(Nazgrek) and IsUnitInRange(Nazgrek, Jinzun, range) then
            return true
        endif
        return ALLOW_ZULKIS and DialogInteraction_IsUnitAlive(udg_Zulkis) and IsUnitInRange(udg_Zulkis, Jinzun, range)
    endfunction

    private function OnMovementOrder takes nothing returns nothing
        local integer roll
        call SyncUnitReferences()
        if GetOrderedUnit() != Jinzun or GetIssuedOrderId() != OrderId("move") or JinzunTalking or not IsPlayerHeroNearJinzun(1500.00) then
            return
        endif
        set roll = GetRandomInt(1, 3)
        if roll == 1 then
            call ExSound_PlayLabelOnUnit("WitchDoctorWarcry1", Jinzun, false)
        elseif roll == 2 then
            call ExSound_PlayLabelOnUnit("WitchDoctorYesAttack2", Jinzun, false)
        else
            call ExSound_PlayLabelOnUnit("WitchDoctorYesAttack3", Jinzun, false)
        endif
    endfunction

    private function GetPlagueRuneRect takes integer index returns rect
        if index == 1 then
            return gg_rct_PlagueTree1Rune
        elseif index == 2 then
            return gg_rct_PlagueTree2Rune
        endif
        return gg_rct_PlagueTree3Rune
    endfunction

    private function GetPlagueTreeRect takes integer index returns rect
        if index == 1 then
            return gg_rct_PlagueTree1
        elseif index == 2 then
            return gg_rct_PlagueTree2
        endif
        return gg_rct_PlagueTree3
    endfunction

    private function GetTreeBlightRect takes integer index returns rect
        if index == 1 then
            return gg_rct_DeadTree01Blight
        elseif index == 2 then
            return gg_rct_DeadTree02Blight
        endif
        return gg_rct_DeadTree03Blight
    endfunction

    private function PingRect takes rect targetRect returns nothing
        if targetRect != null then
            call PingMinimapForPlayer(Player(0), GetRectCenterX(targetRect), GetRectCenterY(targetRect), 6.00)
        endif
    endfunction

    private function OnQuestPing takes nothing returns nothing
        local integer i = 1
        if IsQuestActive(QUEST_PLAGUE_TREES) then
            loop
                exitwhen i > 3
                if not PlagueWardPlaced[i] then
                    call PingRect(GetPlagueTreeRect(i))
                endif
                set i = i + 1
            endloop
        endif
        if IsQuestActive(QUEST_UNKNOWN_ENTITY) then
            call PingRect(gg_rct_LakeAmbient62)
        endif
        if IsQuestActive(QUEST_RESURGENCE_DEAD_1) or IsQuestActive(QUEST_RESURGENCE_DEAD_2) then
            call PingRect(gg_rct_GraveyardFog01)
        endif
    endfunction

    private function UnhidePlagueNecromancer takes nothing returns nothing
        local unit u = GetEnumUnit()
        call ShowUnit(u, true)
        call SetUnitOwner(u, Player(11), true)
        call QueueUnitAnimation(u, "spell channel")
        set u = null
    endfunction

    private function EnableVenomweaveForCauldron takes nothing returns nothing
        local unit u = GetEnumUnit()
        call UnitAddAbility(u, ABILITY_VENOMWEAVE_FLASK)
        call BlzUnitDisableAbility(u, ABILITY_VENOMWEAVE_FLASK, false, false)
        set u = null
    endfunction

    private function PreparePlagueWorld takes nothing returns nothing
        set PlagueWardsPlaced = 0
        set PlagueWardPlaced[1] = false
        set PlagueWardPlaced[2] = false
        set PlagueWardPlaced[3] = false
        call ShowDestructable(udg_PlagueTree1Ritual, true)
        call ShowDestructable(udg_PlagueTree2Ritual, true)
        call ShowDestructable(udg_PlagueTree3Ritual, true)
        if udg_PlagueTreeNecros != null then
            call ForGroup(udg_PlagueTreeNecros, function UnhidePlagueNecromancer)
        endif
    endfunction

    private function GiveHealingWards takes unit hero returns nothing
        local integer amount = 3 - PlagueWardsPlaced
        if amount < 1 then
            set amount = 1
        endif
        loop
            exitwhen amount <= 0
            call QuestGiver_GiveQuestItemToHero(hero, ITEM_HEALING_WARD, 0, "Jin'Zun Healing Ward")
            set amount = amount - 1
        endloop
    endfunction

    private function MarkManualQuestReady takes QuestData q returns nothing
        if q == 0 or q.completed then
            return
        endif
        call QuestGiver_SetStateByNameAndGiver(q.name, Jinzun, QUEST_STATE_READY_TURNIN)
        call q.addReturnRequirement()
    endfunction

    private function RemovePlagueRitual takes integer index returns nothing
        if index == 1 then
            call KillDestructable(udg_PlagueTree1Ritual)
            call RemoveDestructable(udg_PlagueTree1Ritual)
        elseif index == 2 then
            call KillDestructable(udg_PlagueTree2Ritual)
            call RemoveDestructable(udg_PlagueTree2Ritual)
        else
            call KillDestructable(udg_PlagueTree3Ritual)
            call RemoveDestructable(udg_PlagueTree3Ritual)
        endif
        call KillDestructable(udg_TreeRune[index])
        call RemoveDestructable(udg_TreeRune[index])
    endfunction

    private function PlaceHealingWard takes integer index, unit hero, item wardItem returns nothing
        local QuestData q = GetJinzunQuest(QUEST_PLAGUE_TREES)
        local rect targetRect = GetPlagueRuneRect(index)
        local real x
        local real y
        local unit ward
        if q == 0 or not q.active or q.completed or PlagueWardPlaced[index] then
            set targetRect = null
            return
        endif

        if GetItemCharges(wardItem) > 1 then
            call SetItemCharges(wardItem, GetItemCharges(wardItem) - 1)
            call UnitAddItem(hero, wardItem)
        else
            call RemoveItem(wardItem)
        endif

        set x = GetRectCenterX(targetRect)
        set y = GetRectCenterY(targetRect)
        set ward = CreateUnit(Player(bj_PLAYER_NEUTRAL_PASSIVE), UNIT_HEALING_WARD, x, y, bj_UNIT_FACING)
        call ExSound_PlayLabelAtPoint("StasisTotem", x, y, false)
        call RemovePlagueRitual(index)
        set PlagueWardPlaced[index] = true
        set PlagueWardsPlaced = PlagueWardsPlaced + 1
        call QuestGiver_SetRequirementCompleted(q.id, index, true)
        if PlagueWardsPlaced >= 3 then
            call MarkManualQuestReady(q)
        endif

        set ward = null
        set targetRect = null
        set q = 0
    endfunction

    private function OnWardDropped takes nothing returns nothing
        local unit hero = GetManipulatingUnit()
        local item wardItem = GetManipulatedItem()
        local integer index = 0
        if hero == null or wardItem == null or GetOwningPlayer(hero) != Player(0) or GetItemTypeId(wardItem) != ITEM_HEALING_WARD or not IsQuestActive(QUEST_PLAGUE_TREES) then
            set hero = null
            set wardItem = null
            return
        endif
        if RectContainsUnit(gg_rct_PlagueTree1Rune, hero) then
            set index = 1
        elseif RectContainsUnit(gg_rct_PlagueTree2Rune, hero) then
            set index = 2
        elseif RectContainsUnit(gg_rct_PlagueTree3Rune, hero) then
            set index = 3
        endif
        if index > 0 then
            call PlaceHealingWard(index, hero, wardItem)
        endif
        set hero = null
        set wardItem = null
    endfunction

    private function GetRestoredTreeFacing takes integer index returns real
        if index == 1 then
            return 72.00
        elseif index == 2 then
            return 45.00
        endif
        return 266.00
    endfunction

    private function RestoreMightyTree takes integer index, unit hero returns nothing
        local QuestData q = GetJinzunQuest(QUEST_SEEDS_LIFE)
        local destructable oldTree
        local real x
        local real y
        if q == 0 or not q.active or q.completed or SeedsTreeRestored[index] then
            set oldTree = null
            return
        endif
        set oldTree = udg_MightyTree[index]
        if oldTree == null then
            set q = 0
            return
        endif
        set x = GetDestructableX(oldTree)
        set y = GetDestructableY(oldTree)
        call ExSound_PlayLabelOnUnit("SeedsOfLife", hero, false)
        call SetUnitAnimation(hero, "stand victory")
        call RemoveDestructable(oldTree)
        set udg_MightyTree[index] = CreateDestructable(DESTRUCTIBLE_MIGHTY_TREE_ALIVE, x, y, GetRestoredTreeFacing(index), 4.20, 0)
        call SetBlightRect(Player(bj_PLAYER_NEUTRAL_PASSIVE), GetTreeBlightRect(index), false)
        call ResetUnitAnimation(hero)
        set SeedsTreeRestored[index] = true
        set SeedsTreesRestored = SeedsTreesRestored + 1
        call QuestGiver_SetRequirementCompleted(q.id, index, true)
        if SeedsTreesRestored >= 3 then
            call MarkManualQuestReady(q)
        endif
        set oldTree = null
        set q = 0
    endfunction

    private function OnSeedsSpellEffect takes nothing returns nothing
        local unit hero = GetTriggerUnit()
        local integer index = 0
        if GetSpellAbilityId() != ABILITY_SEEDS_OF_LIFE or GetOwningPlayer(hero) != Player(0) or not IsQuestActive(QUEST_SEEDS_LIFE) then
            set hero = null
            return
        endif
        if RectContainsUnit(gg_rct_PlagueTree1, hero) then
            set index = 1
        elseif RectContainsUnit(gg_rct_PlagueTree2, hero) then
            set index = 2
        elseif RectContainsUnit(gg_rct_PlagueTree3, hero) then
            set index = 3
        endif
        if index > 0 then
            call RestoreMightyTree(index, hero)
        endif
        set hero = null
    endfunction

    private function RefreshAvailabilityInternal takes nothing returns nothing
        if Jinzun != null then
            call QuestGiver_RefreshAvailabilityForGiver(Jinzun)
        endif
    endfunction

    private function CompleteTrackedItemQuest takes string questName, integer itemTypeId returns boolean
        local QuestData q = GetJinzunQuest(questName)
        if q == 0 or not q.active or q.completed or not HeroItemCheckBothAndRemove(itemTypeId, 1) then
            set q = 0
            return false
        endif
        call QuestGiver_CompleteItemRequirements(q.id)
        call QuestGiver_CompleteQuestByNameAndGiver(questName, Jinzun)
        set q = 0
        return true
    endfunction

    private function AddQuestSequenceLines takes integer seq, string questName, boolean completing returns nothing
        if questName == QUEST_PLAGUE_TREES then
            if completing then
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0021_TEXT, VL_JINZUN_0021_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0033_TEXT, VL_NAZGREK_0033_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0022_TEXT, VL_JINZUN_0022_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0023_TEXT, VL_JINZUN_0023_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0034_TEXT, VL_NAZGREK_0034_KEY)
            else
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0016_TEXT, VL_JINZUN_0016_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0017_TEXT, VL_JINZUN_0017_KEY, true)
            endif
        elseif questName == QUEST_LURKING_SHADOWS then
            if completing then
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0052_TEXT, VL_JINZUN_0052_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0053_TEXT, VL_NAZGREK_0053_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0053_TEXT, VL_JINZUN_0053_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0054_TEXT, VL_NAZGREK_0054_KEY)
            else
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0051_TEXT, VL_NAZGREK_0051_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0050_TEXT, VL_JINZUN_0050_KEY, true)
            endif
        elseif questName == QUEST_UNKNOWN_ENTITY then
            if completing then
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0035_TEXT, VL_JINZUN_0035_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0042_TEXT, VL_NAZGREK_0042_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0036_TEXT, VL_JINZUN_0036_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0043_TEXT, VL_NAZGREK_0043_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0037_TEXT, VL_JINZUN_0037_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0044_TEXT, VL_NAZGREK_0044_KEY)
            else
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0040_TEXT, VL_NAZGREK_0040_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0033_TEXT, VL_JINZUN_0033_KEY, true)
            endif
        elseif questName == QUEST_SEEDS_LIFE then
            if completing then
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0130_TEXT, VL_JINZUN_0130_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0131_TEXT, VL_JINZUN_0131_KEY, true)
            else
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0120_TEXT, VL_JINZUN_0120_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0121_TEXT, VL_JINZUN_0121_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0122_TEXT, VL_JINZUN_0122_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0123_TEXT, VL_JINZUN_0123_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0124_TEXT, VL_JINZUN_0124_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0125_TEXT, VL_JINZUN_0125_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0128_TEXT, VL_JINZUN_0128_KEY, true)
            endif
        elseif questName == QUEST_RESURGENCE_DEAD_1 then
            if completing then
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0077_TEXT, VL_JINZUN_0077_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0108_TEXT, VL_NAZGREK_0108_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0078_TEXT, VL_JINZUN_0078_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0084_TEXT, VL_JINZUN_0084_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0085_TEXT, VL_JINZUN_0085_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0115_TEXT, VL_NAZGREK_0115_KEY)
            else
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0069_TEXT, VL_JINZUN_0069_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0100_TEXT, VL_NAZGREK_0100_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0070_TEXT, VL_JINZUN_0070_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0101_TEXT, VL_NAZGREK_0101_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0071_TEXT, VL_JINZUN_0071_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0072_TEXT, VL_JINZUN_0072_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0103_TEXT, VL_NAZGREK_0103_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0073_TEXT, VL_JINZUN_0073_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0104_TEXT, VL_NAZGREK_0104_KEY)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0102_TEXT, VL_NAZGREK_0102_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0075_TEXT, VL_JINZUN_0075_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0106_TEXT, VL_NAZGREK_0106_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0076_TEXT, VL_JINZUN_0076_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0107_TEXT, VL_NAZGREK_0107_KEY)
            endif
        elseif questName == QUEST_RESURGENCE_DEAD_2 then
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0086_TEXT, VL_JINZUN_0086_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0087_TEXT, VL_JINZUN_0087_KEY, true)
        elseif questName == QUEST_FISHING_POLE then
            if completing then
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0227_TEXT, VL_NAZGREK_0227_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0117_TEXT, VL_JINZUN_0117_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0118_TEXT, VL_JINZUN_0118_KEY, true)
            else
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0111_TEXT, VL_JINZUN_0111_KEY, true)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0112_TEXT, VL_JINZUN_0112_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0222_TEXT, VL_NAZGREK_0222_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0113_TEXT, VL_JINZUN_0113_KEY, true)
                call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0225_TEXT, VL_NAZGREK_0225_KEY)
                call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0115_TEXT, VL_JINZUN_0115_KEY, true)
            endif
        endif
    endfunction

    private function AcceptPendingQuest takes nothing returns nothing
        local QuestData q = GetJinzunQuest(PendingQuestName)
        if q == 0 then
            return
        endif
        call QuestGiver_AcceptQuestByNameAndGiver(PendingQuestName, Jinzun)
        if PendingQuestName == QUEST_PLAGUE_TREES then
            call QuestGiver_RemoveQuestItemsEverywhereEither(ITEM_HEALING_WARD, 0)
            call PreparePlagueWorld()
            call GiveHealingWards(SelectedHero)
        elseif PendingQuestName == QUEST_UNKNOWN_ENTITY then
            call ExecuteFunc("Trig_BOSS_Unknown_Entity_Init_Actions")
        elseif PendingQuestName == QUEST_SEEDS_LIFE then
            set SeedsTreesRestored = 0
            set SeedsTreeRestored[1] = false
            set SeedsTreeRestored[2] = false
            set SeedsTreeRestored[3] = false
            call QuestGiver_GiveUniqueQuestItemToHero(SelectedHero, ITEM_SEEDS_OF_LIFE, 0, "Seeds of Life")
        elseif PendingQuestName == QUEST_FISHING_POLE then
            call UnitRemoveAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        endif
        call QuestGiver_RefreshItemRequirementsForQuest(q.id)
        call OnQuestPing()
        set q = 0
    endfunction

    private function CompletePendingQuest takes nothing returns nothing
        local QuestData q = GetJinzunQuest(PendingQuestName)
        local QuestData fishingQuest
        if q == 0 or q.completed then
            set q = 0
            return
        endif
        if PendingQuestName == QUEST_PLAGUE_TREES and q.state == QUEST_STATE_READY_TURNIN then
            call QuestGiver_RemoveQuestItemsEverywhereEither(ITEM_HEALING_WARD, 0)
            call QuestGiver_CompleteQuestByNameAndGiver(PendingQuestName, Jinzun)
        elseif PendingQuestName == QUEST_LURKING_SHADOWS and CompleteTrackedItemQuest(PendingQuestName, ITEM_SARGOTH_ICHOR) then
            if udg_Cauldrons != null then
                call ForGroup(udg_Cauldrons, function EnableVenomweaveForCauldron)
            endif
            call UnitAddAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        elseif PendingQuestName == QUEST_UNKNOWN_ENTITY and CompleteTrackedItemQuest(PendingQuestName, ITEM_DISGUSTING_SLIME) then
            call UnitRemoveAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
            call RefreshAvailabilityInternal()
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_FISHING_POLE, Jinzun)
            set fishingQuest = GetJinzunQuest(QUEST_FISHING_POLE)
            if fishingQuest != 0 then
                call QuestGiver_RefreshItemRequirementsForQuest(fishingQuest.id)
            endif
            call EnterFishingSpotMode()
            call ExecuteFunc("qZaekolaerr_RefreshAvailability")
        elseif PendingQuestName == QUEST_SEEDS_LIFE and q.state == QUEST_STATE_READY_TURNIN then
            call QuestGiver_RemoveQuestItemsEverywhereEither(ITEM_SEEDS_OF_LIFE, 0)
            call QuestGiver_CompleteQuestByNameAndGiver(PendingQuestName, Jinzun)
        elseif PendingQuestName == QUEST_RESURGENCE_DEAD_1 and CompleteTrackedItemQuest(PendingQuestName, ITEM_ROTTEN_PART) then
            call RefreshAvailabilityInternal()
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RESURGENCE_DEAD_2, Jinzun)
        elseif PendingQuestName == QUEST_RESURGENCE_DEAD_2 and q.state == QUEST_STATE_READY_TURNIN then
            call QuestGiver_CompleteQuestByNameAndGiver(PendingQuestName, Jinzun)
        elseif PendingQuestName == QUEST_FISHING_POLE and CompleteTrackedItemQuest(PendingQuestName, ITEM_JINZUN_FISHING_POLE) then
            call UnitAddAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
            set FishingAnimationPlaying = false
            call ExecuteFunc("qZaekolaerr_RefreshAvailability")
        endif
        set fishingQuest = 0
        set q = 0
    endfunction

    private function OnQuestSequenceEnd takes nothing returns nothing
        if PendingQuestCompletion then
            call CompletePendingQuest()
        else
            call AcceptPendingQuest()
        endif
        call RefreshAvailabilityInternal()
        set PendingQuestName = ""
        set PendingQuestCompletion = false
        call StartExitFadeOut()
    endfunction

    private function StartQuestSequence takes string questName, boolean completing returns nothing
        local integer seq
        set PendingQuestName = questName
        set PendingQuestCompletion = completing
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Jinzun, JINZUN_NAME)
        call DialogSystem_AddMakeFaceEachOther(seq, Jinzun, SelectedHero, 0.50, 0.00)
        call AddQuestSequenceLines(seq, questName, completing)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnQuestSequenceEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function OnAcceptPlague takes nothing returns nothing
        call StartQuestSequence(QUEST_PLAGUE_TREES, false)
    endfunction

    private function OnCompletePlague takes nothing returns nothing
        call StartQuestSequence(QUEST_PLAGUE_TREES, true)
    endfunction

    private function OnAcceptShadows takes nothing returns nothing
        call StartQuestSequence(QUEST_LURKING_SHADOWS, false)
    endfunction

    private function OnCompleteShadows takes nothing returns nothing
        call StartQuestSequence(QUEST_LURKING_SHADOWS, true)
    endfunction

    private function OnAcceptUnknown takes nothing returns nothing
        call StartQuestSequence(QUEST_UNKNOWN_ENTITY, false)
    endfunction

    private function OnCompleteUnknown takes nothing returns nothing
        call StartQuestSequence(QUEST_UNKNOWN_ENTITY, true)
    endfunction

    private function OnAcceptSeeds takes nothing returns nothing
        call StartQuestSequence(QUEST_SEEDS_LIFE, false)
    endfunction

    private function OnCompleteSeeds takes nothing returns nothing
        call StartQuestSequence(QUEST_SEEDS_LIFE, true)
    endfunction

    private function OnAcceptResurgence1 takes nothing returns nothing
        call StartQuestSequence(QUEST_RESURGENCE_DEAD_1, false)
    endfunction

    private function OnCompleteResurgence1 takes nothing returns nothing
        call StartQuestSequence(QUEST_RESURGENCE_DEAD_1, true)
    endfunction

    private function OnCompleteResurgence2 takes nothing returns nothing
        call StartQuestSequence(QUEST_RESURGENCE_DEAD_2, true)
    endfunction

    private function OnAcceptFishing takes nothing returns nothing
        call StartQuestSequence(QUEST_FISHING_POLE, false)
    endfunction

    private function OnCompleteFishing takes nothing returns nothing
        call StartQuestSequence(QUEST_FISHING_POLE, true)
    endfunction

    private function OnRecoverWardsEnd takes nothing returns nothing
        call GiveHealingWards(SelectedHero)
        call StartExitFadeOut()
    endfunction

    private function OnRecoverWards takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Jinzun, JINZUN_NAME)
        call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0031_TEXT, VL_NAZGREK_0031_KEY)
        call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0020_TEXT, VL_JINZUN_0020_KEY, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnRecoverWardsEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function OnRecoverSeedsEnd takes nothing returns nothing
        call QuestGiver_GiveUniqueQuestItemToHero(SelectedHero, ITEM_SEEDS_OF_LIFE, 0, "Seeds of Life")
        call StartExitFadeOut()
    endfunction

    private function OnRecoverSeeds takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Jinzun, JINZUN_NAME)
        call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0129_TEXT, VL_JINZUN_0129_KEY, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnRecoverSeedsEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function HasAvailableQuest takes nothing returns boolean
        return QuestGiver_GetStateByNameAndGiver(QUEST_PLAGUE_TREES, Jinzun) == QUEST_STATE_AVAILABLE or QuestGiver_GetStateByNameAndGiver(QUEST_LURKING_SHADOWS, Jinzun) == QUEST_STATE_AVAILABLE or QuestGiver_GetStateByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) == QUEST_STATE_AVAILABLE or QuestGiver_GetStateByNameAndGiver(QUEST_SEEDS_LIFE, Jinzun) == QUEST_STATE_AVAILABLE or QuestGiver_GetStateByNameAndGiver(QUEST_RESURGENCE_DEAD_1, Jinzun) == QUEST_STATE_AVAILABLE or QuestGiver_GetStateByNameAndGiver(QUEST_FISHING_POLE, Jinzun) == QUEST_STATE_AVAILABLE
    endfunction

    private function OnDeclineEnd takes nothing returns nothing
        call StartExitFadeOut()
    endfunction

    private function OnDecline takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Jinzun, JINZUN_NAME)
        if QuestGiver_GetStateByNameAndGiver(QUEST_PLAGUE_TREES, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0029_TEXT, VL_NAZGREK_0029_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0018_TEXT, VL_JINZUN_0018_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_LURKING_SHADOWS, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0052_TEXT, VL_NAZGREK_0052_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0051_TEXT, VL_JINZUN_0051_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0041_TEXT, VL_NAZGREK_0041_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0034_TEXT, VL_JINZUN_0034_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_SEEDS_LIFE, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0126_TEXT, VL_JINZUN_0126_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_RESURGENCE_DEAD_1, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0105_TEXT, VL_NAZGREK_0105_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0074_TEXT, VL_JINZUN_0074_KEY, true)
        else
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0224_TEXT, VL_NAZGREK_0224_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0114_TEXT, VL_JINZUN_0114_KEY, true)
        endif
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnDeclineEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function OnFarewellEnd takes nothing returns nothing
        call StartExitFadeOut()
    endfunction

    private function OnFarewell takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateFarewellSequence(Jinzun, JINZUN_NAME, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function CanDispelChainsOfSeduction takes nothing returns boolean
        return udg_QuestChainsOfSeduction != null and IsQuestDiscovered(udg_QuestChainsOfSeduction) and not IsQuestCompleted(udg_QuestChainsOfSeduction) and not udg_QuestChainsOfSeductionDispelld
    endfunction

    private function OnDispelChainsEnd takes nothing returns nothing
        local effect dispelEffect
        set dispelEffect = AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", SelectedHero, "origin")
        call DestroyEffect(dispelEffect)
        set udg_QuestChainsOfSeductionDispelld = true
        set udg_SuccubusSeduced = false
        if udg_QuestChainsOfSeductionReq2 != null then
            call QuestItemSetCompleted(udg_QuestChainsOfSeductionReq2, true)
        endif
        call ExecuteFunc("Trig_Quest_Chains_of_Seduction_Update_Dispelled_Actions")
        if udg_Succubus != null then
            call SetPlayerAllianceStateBJ(Player(0), GetOwningPlayer(udg_Succubus), bj_ALLIANCE_UNALLIED)
            call SetPlayerAllianceStateBJ(GetOwningPlayer(udg_Succubus), Player(0), bj_ALLIANCE_UNALLIED)
            call SetUnitInvulnerable(udg_Succubus, false)
            call IssueTargetOrder(udg_Succubus, "attack", SelectedHero)
        endif
        set dispelEffect = null
        call StartExitFadeOut()
    endfunction

    private function PlayDispelChainsSequence takes nothing returns nothing
        local integer seq
        call DialogInteraction_BeginDialogSequence()
        set seq = DialogInteraction_CreateBaseSequence(Jinzun, JINZUN_NAME)
        call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0194_TEXT, VL_NAZGREK_0194_KEY)
        call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0100_TEXT, VL_JINZUN_0100_KEY, true)
        call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0101_TEXT, VL_JINZUN_0101_KEY, true)
        call DialogSystem_AddLine(seq, udg_Succubus, "Succubus", VL_DEMONESS_0042_TEXT, VL_DEMONESS_0042_KEY, true)
        call DialogSystem_AddLine(seq, udg_Succubus, "Succubus", VL_DEMONESS_0041_TEXT, VL_DEMONESS_0041_KEY, true)
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnDispelChainsEnd)
        call DialogSystem_PlaySequence(seq, Player(0), Jinzun)
    endfunction

    private function BuildDialog takes nothing returns nothing
        local button b
        if JinzunDialog == null then
            set JinzunDialog = DialogSystem_CreateDialog(JINZUN_NAME)
        endif
        call RefreshAvailabilityInternal()
        call DialogSystem_ClearDialog(JinzunDialog)
        call DialogSystem_SetTitle(JinzunDialog, JINZUN_NAME)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_PLAGUE_TREES, Jinzun, ACTION_ACCEPT_PLAGUE, function OnAcceptPlague, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_PLAGUE_TREES, Jinzun, ACTION_COMPLETE_PLAGUE, function OnCompletePlague, false)
        call QuestGiver_AddQuestItemRecoveryButton(JinzunDialog, QUEST_PLAGUE_TREES, Jinzun, ACTION_RECOVER_WARDS, ITEM_HEALING_WARD, 1, "Jin'Zun Healing Wards", function OnRecoverWards)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_LURKING_SHADOWS, Jinzun, ACTION_ACCEPT_SHADOWS, function OnAcceptShadows, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_LURKING_SHADOWS, Jinzun, ACTION_COMPLETE_SHADOWS, function OnCompleteShadows, true)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_UNKNOWN_ENTITY, Jinzun, ACTION_ACCEPT_UNKNOWN, function OnAcceptUnknown, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_UNKNOWN_ENTITY, Jinzun, ACTION_COMPLETE_UNKNOWN, function OnCompleteUnknown, true)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_SEEDS_LIFE, Jinzun, ACTION_ACCEPT_SEEDS, function OnAcceptSeeds, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_SEEDS_LIFE, Jinzun, ACTION_COMPLETE_SEEDS, function OnCompleteSeeds, false)
        call QuestGiver_AddQuestItemRecoveryButton(JinzunDialog, QUEST_SEEDS_LIFE, Jinzun, ACTION_RECOVER_SEEDS, ITEM_SEEDS_OF_LIFE, 1, "Seeds of Life", function OnRecoverSeeds)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_RESURGENCE_DEAD_1, Jinzun, ACTION_ACCEPT_RESURGENCE_1, function OnAcceptResurgence1, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_RESURGENCE_DEAD_1, Jinzun, ACTION_COMPLETE_RESURGENCE_1, function OnCompleteResurgence1, true)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_RESURGENCE_DEAD_2, Jinzun, ACTION_COMPLETE_RESURGENCE_2, function OnCompleteResurgence2, false)

        call QuestGiver_AddAvailableQuestAcceptButton(JinzunDialog, QUEST_FISHING_POLE, Jinzun, ACTION_ACCEPT_FISHING, function OnAcceptFishing, true, false)
        call QuestGiver_AddReadyQuestCompleteButton(JinzunDialog, QUEST_FISHING_POLE, Jinzun, ACTION_COMPLETE_FISHING, function OnCompleteFishing, true)

        if HasAvailableQuest() then
            set b = DialogSystem_AddButtonDecline(JinzunDialog, ACTION_DECLINE)
            call DialogSystem_BindButtonCode(b, function OnDecline)
        endif
        set b = DialogSystem_AddFarewellButton(JinzunDialog)
        call DialogSystem_BindButtonCode(b, function OnFarewell)
        set b = null
    endfunction

    private function AddPreDialogBark takes integer seq returns nothing
        if FishingSpotMode and IsJinzunAtFishingSpot() then
            call DialogSystem_AddLineNoSound(seq, SelectedHero, DialogInteraction_GetHeroName(SelectedHero), FISHING_HERO_TEXT)
            if HasFishingPole() then
                call DialogSystem_AddLineNoSound(seq, Jinzun, JINZUN_NAME, FISHING_JINZUN_TEXT)
            else
                call DialogSystem_AddLineNoSound(seq, Jinzun, JINZUN_NAME, FISHING_JINZUN_NO_POLE_TEXT)
            endif
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_PLAGUE_TREES, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0019_TEXT, VL_NAZGREK_0019_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0001_TEXT, VL_JINZUN_0001_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0020_TEXT, VL_NAZGREK_0020_KEY)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0022_TEXT, VL_NAZGREK_0022_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0012_TEXT, VL_JINZUN_0012_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0013_TEXT, VL_JINZUN_0013_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0024_TEXT, VL_NAZGREK_0024_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0014_TEXT, VL_JINZUN_0014_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0025_TEXT, VL_NAZGREK_0025_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0015_TEXT, VL_JINZUN_0015_KEY, true)
        elseif IsQuestActive(QUEST_PLAGUE_TREES) and PlagueWardsPlaced < 3 then
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0019_TEXT, VL_JINZUN_0019_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0030_TEXT, VL_NAZGREK_0030_KEY)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_LURKING_SHADOWS, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0047_TEXT, VL_NAZGREK_0047_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0046_TEXT, VL_JINZUN_0046_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0048_TEXT, VL_NAZGREK_0048_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0047_TEXT, VL_JINZUN_0047_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0048_TEXT, VL_JINZUN_0048_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0049_TEXT, VL_JINZUN_0049_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0037_TEXT, VL_NAZGREK_0037_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0030_TEXT, VL_JINZUN_0030_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0031_TEXT, VL_JINZUN_0031_KEY, true)
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0038_TEXT, VL_NAZGREK_0038_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0032_TEXT, VL_JINZUN_0032_KEY, true)
        elseif QuestGiver_GetStateByNameAndGiver(QUEST_SEEDS_LIFE, Jinzun) == QUEST_STATE_AVAILABLE then
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0121_TEXT, VL_JINZUN_0121_KEY, true)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0125_TEXT, VL_JINZUN_0125_KEY, true)
        elseif QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) then
            call DialogInteraction_AddHeroLookAtLine(seq, SelectedHero, Jinzun, VL_NAZGREK_0220_TEXT, VL_NAZGREK_0220_KEY)
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0110_TEXT, VL_JINZUN_0110_KEY, true)
        elseif not DialogInteraction_IsFirstGreetDone(Jinzun) then
            call DialogSystem_AddLine(seq, Jinzun, JINZUN_NAME, VL_JINZUN_0001_TEXT, VL_JINZUN_0001_KEY, true)
        endif
        call DialogInteraction_SetFirstGreetDone(Jinzun, true)
    endfunction

    private function ContinueToDialogInternal takes nothing returns nothing
        local unit hero = ResolveDialogHero()
        local integer seq
        if hero == null or not DialogInteraction_IsUnitAlive(Jinzun) then
            set hero = null
            call StartExitFadeOut()
            return
        endif
        if CanDispelChainsOfSeduction() then
            call PlayDispelChainsSequence()
            set hero = null
            return
        endif
        call BuildDialog()
        set seq = DialogInteraction_CreateGreetSequenceBase(Jinzun, JINZUN_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
        call AddPreDialogBark(seq)
        call DialogInteraction_PlayGreetSequenceEx(seq, Jinzun, Player(0), JinzunDialog, CINEMATIC)
        set hero = null
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        call ContinueToDialogInternal()
    endfunction

    private function OnSelected takes nothing returns nothing
        call SyncUnitReferences()
        set SelectedHero = DialogInteraction_GetDialogSelectionHero(Jinzun, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        if not DialogInteraction_PassDialogSelectionGate(Jinzun, SelectedHero, DIALOG_RANGE, JinzunDialogCooldown, true, true, true, true, false, false) then
            call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
            set SelectedHero = null
            return
        endif
        call PausePatrol()
        call DialogInteraction_StartConfiguredDialogEntryTransition(Jinzun, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qOutcastJinzun_ContinueToDialogAfterSelection")
    endfunction

    private function CreateQuests takes nothing returns nothing
        local QuestData q
        local string infoText = "|cffffcc00Quest giver:|r " + JINZUN_NAME + "\n"

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_PLAGUE_TREES, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_PLAGUE_TREES, Jinzun, "normal", 4, null, QUEST_PLAGUE_TREES, "ReplaceableTextures\\CommandButtons\\BTNDarkSummoning.blp", "Place Jin'Zun's Healing Wards at the three corrupted tree runes and stop the plague from spreading.\n\n", infoText, "|cffffcc00Recommended level:|r 4\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, true, 300, false, 0, false, 0, false)
            call q.setRewardItemType(ITEM_RESTORATION_POTION)
            call QuestGiver_SetRequirements(q.id, "", "Place a Healing Ward at the first corrupted tree", "Place a Healing Ward at the second corrupted tree", "Place a Healing Ward at the third corrupted tree", "", "", "", "", "")
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_LURKING_SHADOWS, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_LURKING_SHADOWS, Jinzun, "normal", 6, null, QUEST_LURKING_SHADOWS, "ReplaceableTextures\\CommandButtons\\BTNSpiderGreen.blp", "Defeat the mother spider Sargoth and bring her ichor to Jin'Zun.\n\n", infoText, "|cffffcc00Recommended level:|r 6\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_PLAGUE_TREES, Jinzun)
            call QuestGiver_RegisterItemRequirement(q.id, Jinzun, 1, ITEM_SARGOTH_ICHOR, 1)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_UNKNOWN_ENTITY, Jinzun, "normal", 8, null, QUEST_UNKNOWN_ENTITY, "ReplaceableTextures\\CommandButtons\\BTNTentacle.blp", "Investigate the unnatural entity disturbing Jin'Zun's fishing lake.\n\n", infoText, "|cffffcc00Recommended level:|r 8\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_PLAGUE_TREES, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_LURKING_SHADOWS, Jinzun)
            call QuestGiver_SetRequirements(q.id, "", "Investigate the lake", "", "", "", "", "", "", "")
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_SEEDS_LIFE, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_SEEDS_LIFE, Jinzun, "normal", 8, null, QUEST_SEEDS_LIFE, "ReplaceableTextures\\PassiveButtons\\PASBTNThorns.blp", "Use the Seeds of Life near the three mighty dead trees to restore them and cleanse the blight.\n\n", infoText, "|cffffcc00Recommended level:|r 8\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, false, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_PLAGUE_TREES, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_LURKING_SHADOWS, Jinzun)
            call QuestGiver_SetRequirements(q.id, "", "Restore the first mighty tree", "Restore the second mighty tree", "Restore the third mighty tree", "", "", "", "", "")
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_RESURGENCE_DEAD_1, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_RESURGENCE_DEAD_1, Jinzun, "normal", 8, null, QUEST_RESURGENCE_DEAD_1, "ReplaceableTextures\\CommandButtons\\BTNDalaranMutant.blp", "Investigate the crypt in the Dead Woods and bring Jin'Zun a moving rotten body part as proof of the undead resurgence.\n\n", infoText, "|cffffcc00Recommended level:|r 8\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_PLAGUE_TREES, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_LURKING_SHADOWS, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_UNKNOWN_ENTITY, Jinzun)
            call QuestGiver_RegisterItemRequirement(q.id, Jinzun, 1, ITEM_ROTTEN_PART, 1)
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_RESURGENCE_DEAD_2, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_RESURGENCE_DEAD_2, Jinzun, "normal", 10, null, QUEST_RESURGENCE_DEAD_2, "ReplaceableTextures\\CommandButtons\\BTNAnimateDead.blp", "Lay the undead of the crypt to rest and stop the necromancy within.\n\n", infoText, "|cffffcc00Recommended level:|r 10\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, false, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_RESURGENCE_DEAD_1, Jinzun)
            call QuestGiver_SetRequirements(q.id, "", "Lay the undead of the crypt to rest", "", "", "", "", "", "", "")
        endif

        if not QuestGiver_QuestExistsByNameAndGiver(QUEST_FISHING_POLE, Jinzun) then
            set q = QuestGiver_CreateConfiguredQuest(QUEST_FISHING_POLE, Jinzun, "normal", 6, null, QUEST_FISHING_POLE, "ReplaceableTextures\\CommandButtons\\BTNInv_fishingpole_02.blp", "Retrieve Jin'Zun's missing fishing pole from the kobolds or satyrs.\n\n", infoText, "|cffffcc00Recommended level:|r 6\n\n", 1, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "", JINZUN_NAME)
            call QuestGiver_SetQuestRewards(q, true, 0, false, 0, false, 0, false, 0, false)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_PLAGUE_TREES, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_LURKING_SHADOWS, Jinzun)
            call QuestGiver_AddQuestPrerequisite(q, QUEST_UNKNOWN_ENTITY, Jinzun)
            call QuestGiver_RegisterItemRequirement(q.id, Jinzun, 1, ITEM_JINZUN_FISHING_POLE, 1)
        endif
        set q = 0
    endfunction

    private function EnsureFishingQuestDiscovered takes nothing returns nothing
        local QuestData q
        if not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) or QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FISHING_POLE, Jinzun) then
            return
        endif
        call RefreshAvailabilityInternal()
        set q = GetJinzunQuest(QUEST_FISHING_POLE)
        if q != 0 and not q.active and q.state == QUEST_STATE_AVAILABLE then
            call QuestGiver_AcceptQuestByNameAndGiver(QUEST_FISHING_POLE, Jinzun)
            call QuestGiver_RefreshItemRequirementsForQuest(q.id)
        endif
        set q = 0
    endfunction

    private function RestoreJinzunEquipmentAndMovement takes nothing returns nothing
        if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FISHING_POLE, Jinzun) then
            call UnitAddAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        elseif QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) then
            call UnitRemoveAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        elseif QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_LURKING_SHADOWS, Jinzun) then
            call UnitAddAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        else
            call UnitRemoveAbility(Jinzun, ABILITY_JINZUN_FISHING_POLE)
        endif

        if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun) then
            call EnterFishingSpotMode()
        else
            call StartPatrol()
        endif
    endfunction

    private function RegisterDialogLines takes nothing returns nothing
        call DialogSystem_RegisterFarewellLineForUnit(Jinzun, VL_JINZUN_0002_TEXT, VL_JINZUN_0002_KEY, true)
        call DialogSystem_RegisterFarewellLineForUnit(Jinzun, VL_JINZUN_0003_TEXT, VL_JINZUN_0003_KEY, true)
    endfunction

    private function RegisterRuntimeTriggers takes nothing returns nothing
        if WardDropTrigger == null then
            set WardDropTrigger = CreateTrigger()
            call TriggerRegisterPlayerUnitEvent(WardDropTrigger, Player(0), EVENT_PLAYER_UNIT_DROP_ITEM, null)
            call TriggerAddAction(WardDropTrigger, function OnWardDropped)
        endif
        if SeedsSpellTrigger == null then
            set SeedsSpellTrigger = CreateTrigger()
            call TriggerRegisterPlayerUnitEvent(SeedsSpellTrigger, Player(0), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
            call TriggerAddAction(SeedsSpellTrigger, function OnSeedsSpellEffect)
        endif
        if MovementSoundTrigger == null then
            set MovementSoundTrigger = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(MovementSoundTrigger, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
            call TriggerAddAction(MovementSoundTrigger, function OnMovementOrder)
        endif
    endfunction

    public function UpdateUnknownEntityLure takes nothing returns nothing
        local QuestData q = GetJinzunQuest(QUEST_UNKNOWN_ENTITY)
        if q == 0 or not q.active or q.completed then
            set q = 0
            return
        endif
        call QuestGiver_SetRequirementCompleted(q.id, 1, true)
        call QuestGiver_SetRequirement(q.id, 2, "Use meat to lure the Unknown Entity from the lake")
        call QuestGiver_SetStateByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun, QUEST_STATE_IN_PROGRESS)
        set q = 0
    endfunction

    public function UpdateUnknownEntityKill takes nothing returns nothing
        local QuestData q = GetJinzunQuest(QUEST_UNKNOWN_ENTITY)
        if q == 0 or not q.active or q.completed then
            set q = 0
            return
        endif
        call QuestGiver_SetRequirementCompleted(q.id, 2, true)
        call QuestGiver_SetRequirement(q.id, 3, "Kill the Unknown Entity")
        call QuestGiver_SetStateByNameAndGiver(QUEST_UNKNOWN_ENTITY, Jinzun, QUEST_STATE_IN_PROGRESS)
        set q = 0
    endfunction

    public function UpdateUnknownEntitySlime takes nothing returns nothing
        local QuestData q = GetJinzunQuest(QUEST_UNKNOWN_ENTITY)
        if q == 0 or not q.active or q.completed then
            set q = 0
            return
        endif
        call QuestGiver_SetRequirementCompleted(q.id, 3, true)
        call QuestGiver_SetRequirement(q.id, 4, "Return to Outcast Jin'Zun with Disgusting Slime")
        if not UnknownSlimeRequirementRegistered then
            set UnknownSlimeRequirementRegistered = true
            call QuestGiver_RegisterItemRequirement(q.id, Jinzun, 4, ITEM_DISGUSTING_SLIME, 1)
        endif
        call QuestGiver_RefreshItemRequirementsForQuest(q.id)
        set q = 0
    endfunction

    public function CompleteResurgenceOfDeadPart2Objective takes nothing returns nothing
        local QuestData q = GetJinzunQuest(QUEST_RESURGENCE_DEAD_2)
        if q == 0 or not q.active or q.completed then
            set q = 0
            return
        endif
        call QuestGiver_SetRequirementCompleted(q.id, 1, true)
        call MarkManualQuestReady(q)
        set q = 0
    endfunction

    public function IsFishingPoleQuestActive takes nothing returns boolean
        call SyncUnitReferences()
        return IsQuestActive(QUEST_FISHING_POLE)
    endfunction

    private function InitDelayed takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        call SyncUnitReferences()
        if Jinzun == null or Nazgrek == null then
            if not InitWaitingLogged then
                call DebugMsg("Waiting for Outcast Jin'Zun and Nazgrek unit references.")
                set InitWaitingLogged = true
            endif
            call TimerStart(initTimer, 0.50, false, function InitDelayed)
            set initTimer = null
            return
        endif

        call QuestGiver_Register(Jinzun)
        call DialogInteraction_ConfigureDialogTransition(Jinzun, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_SetGreetOrder(Jinzun, DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC)
        call RegisterDialogLines()
        call CreateQuests()
        call RefreshAvailabilityInternal()
        call EnsureFishingQuestDiscovered()
        call DialogInteraction_RegisterSelectionHandler(Jinzun, function OnSelected)
        call RegisterRuntimeTriggers()
        call RestoreJinzunEquipmentAndMovement()
        call DebugMsg("Initialized.")
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        set JinzunDialogCooldown = CreateTimer()
        set QuestPingTimer = CreateTimer()
        set FishingBehaviorTimer = CreateTimer()
        call TimerStart(QuestPingTimer, 60.00, true, function OnQuestPing)
        call TimerStart(FishingBehaviorTimer, 2.00, true, function OnFishingBehaviorTick)
        call TimerStart(CreateTimer(), 0.00, false, function InitDelayed)
    endfunction

    public function RefreshAvailability takes nothing returns nothing
        call SyncUnitReferences()
        call RefreshAvailabilityInternal()
    endfunction

    public function RefreshRespawnedUnitHooks takes nothing returns nothing
        call SyncUnitReferences()
        if Jinzun == null then
            return
        endif
        call QuestGiver_UpdateGiverUnitReferenceByType(UNIT_JINZUN, Jinzun)
        call QuestGiver_Register(Jinzun)
        call DialogInteraction_ConfigureDialogTransition(Jinzun, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Jinzun, function OnSelected)
        call RefreshAvailabilityInternal()
        call EnsureFishingQuestDiscovered()
        call RestoreJinzunEquipmentAndMovement()
    endfunction
endlibrary
