/**
    PlayerHome

    Author: Valdemar
    Version: 1.0.0

    Description:
    Provides the Traveler's Journal home-binding interaction, Return Home
    channel, nearby-party relocation, and per-hero cooldown state.

    Credits:
    - The original PotS Player Home GUI triggers

    How to install:
    Import after the required event, dialog, inventory, companion, zone,
    camera, and sound libraries. Disable the legacy Player Home GUI triggers.

    API:
    - PlayerHome_RegisterJournal(unit, locationName, zoneId, factionOwner) returns integer
    - PlayerHome_HasHome() returns boolean
    - PlayerHome_GetHomeName() returns string
    - PlayerHome_GetHomeZoneId() returns integer
    - PlayerHome_GetHomeZoneName() returns string
    - PlayerHome_HeroHasJournal(unit) returns boolean
    - PlayerHome_GetCooldownRemaining(unit) returns real
    - PlayerHome_IsChanneling(unit) returns boolean
    - PlayerHome_UseJournal(unit) returns boolean
    - PlayerHome_PingHome()

**/
library PlayerHome initializer Init requires Table, Events, DamageEngine, DialogInteraction, DialogSystem, HeroItemCheck, SharedDInvLib, Companions, Pet, ZonesCore, ZoneEvent, ExSound, FallenHeroState, optional HintsUI
    globals
        // Configuration
        private constant boolean PH_DEBUG = false
        private constant integer PH_WORLD_JOURNAL_ID = 'n65G'
        private constant integer PH_JOURNAL_ITEM_ID = 'I6CL'
        private constant integer PH_RETURN_HOME_ABILITY_ID = 'A6DU'
        private constant integer PH_MAX_HOMES = 32
        private constant integer PH_MAX_PASSENGERS = 16
        private constant real PH_BIND_RANGE = 300.00
        private constant real PH_PARTY_RANGE = 900.00
        private constant real PH_CHANNEL_DURATION = 10.00
        private constant real PH_CHANNEL_MONITOR_PERIOD = 0.05
        private constant real PH_COOLDOWN_DURATION = 1800.00
        private constant real PH_FADE_DURATION = 1.00
        private constant real PH_FORMATION_RADIUS = 115.00
        private constant integer PH_CINEMATIC_MOVE_MODE = 1
        private constant real PH_CINEMATIC_MOVE_OFFSET = 220.00
        private constant real PH_CINEMATIC_MOVE_ANGLE = 210.00
        private constant real PH_CAMERA_DISTANCE = 900.00
        private constant real PH_CAMERA_Z_OFFSET = 35.00
        private constant real PH_CAMERA_ANGLE = 350.00
        private constant real PH_CAMERA_ROTATION_OFFSET = 180.00
        private constant real PH_CAMERA_FAR_Z = 10000.00
        private constant real PH_CAMERA_FOV = 60.00
        private constant real PH_CAMERA_BLOCK_RADIUS = 0.00
        private constant boolean PH_CAMERA_BLOCK_CHECK = true

        private integer PH_HomeCount = 0
        private integer PH_CurrentHomeId = 0
        private Table PH_JournalHome = 0
        private unit array PH_HomeJournal
        private string array PH_HomeName
        private integer array PH_HomeZoneId
        private player array PH_HomeFactionOwner
        private real array PH_HomeX
        private real array PH_HomeY

        private timer array PH_CooldownTimer
        private timer PH_ChannelTimer = null
        private timer PH_MonitorTimer = null
        private timer PH_TransferTimer = null
        private unit PH_ActiveCaster = null
        private integer PH_ActiveHeroIndex = 0
        private real PH_ChannelStartX = 0.00
        private real PH_ChannelStartY = 0.00
        private real PH_PreviousAcquireRange = 0.00
        private boolean PH_TransferInProgress = false

        private integer PH_PassengerCount = 0
        private unit array PH_Passenger
        private boolean array PH_PassengerWasPaused
        private boolean array PH_PassengerWasInvulnerable

        private dialog PH_BindDialog = null
        private unit PH_BindJournal = null
        private unit PH_BindHero = null
        private integer PH_BindHomeId = 0
        private boolean PH_BindingActive = false

        private unit PH_FoundJournal = null
    endglobals

    private function PH_Debug takes string message returns nothing
        if PH_DEBUG then
            call BJDebugMsg("|cff88ccff[PlayerHome]|r " + message)
        endif
    endfunction

    private function PH_GetHeroIndex takes unit hero returns integer
        if hero == udg_Nazgrek then
            return 1
        elseif hero == udg_Zulkis then
            return 2
        endif
        return 0
    endfunction

    private function PH_GetHeroName takes unit hero returns string
        if hero == udg_Nazgrek then
            return "Nazgrek"
        elseif hero == udg_Zulkis then
            return "Zul'kis"
        endif
        if hero != null then
            return GetUnitName(hero)
        endif
        return "Hero"
    endfunction

    private function PH_IsWithinRange takes unit firstUnit, unit secondUnit, real range returns boolean
        local real dx
        local real dy

        if firstUnit == null or secondUnit == null then
            return false
        endif
        set dx = GetUnitX(firstUnit) - GetUnitX(secondUnit)
        set dy = GetUnitY(firstUnit) - GetUnitY(secondUnit)
        return dx * dx + dy * dy <= range * range
    endfunction

    public function HasHome takes nothing returns boolean
        return PH_CurrentHomeId > 0 and PH_CurrentHomeId <= PH_HomeCount
    endfunction

    public function GetHomeName takes nothing returns string
        if HasHome() then
            return PH_HomeName[PH_CurrentHomeId]
        endif
        return "Not bound"
    endfunction

    public function GetHomeZoneId takes nothing returns integer
        if HasHome() then
            return PH_HomeZoneId[PH_CurrentHomeId]
        endif
        return 0
    endfunction

    public function GetHomeZoneName takes nothing returns string
        local integer zoneId = GetHomeZoneId()

        if zoneId > 0 then
            return ZonesCore_GetZoneName(zoneId)
        endif
        return "Unknown Zone"
    endfunction

    public function HeroHasJournal takes unit hero returns boolean
        return PH_GetHeroIndex(hero) > 0 and HeroItemCheck(hero, PH_JOURNAL_ITEM_ID, 1)
    endfunction

    public function GetCooldownRemaining takes unit hero returns real
        local integer heroIndex = PH_GetHeroIndex(hero)

        if heroIndex <= 0 or PH_CooldownTimer[heroIndex] == null then
            return 0.00
        endif
        return TimerGetRemaining(PH_CooldownTimer[heroIndex])
    endfunction

    public function IsChanneling takes unit hero returns boolean
        return hero != null and hero == PH_ActiveCaster
    endfunction

    private function PH_Display takes string message returns nothing
        call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffffcc00Traveler's Journal|r|cffffffff: " + message + "|r")
    endfunction

    private function PH_PlayError takes nothing returns nothing
        call ExSound_PlayLabel("Error", false)
    endfunction

    private function PH_GiveJournal takes unit hero returns boolean
        local item journal = null
        local real x
        local real y
        local boolean added = false

        if hero == null or not FallenHeroState_IsAlive(hero) then
            set hero = null
            return false
        endif
        if HeroHasJournal(hero) then
            set hero = null
            return true
        endif

        set x = GetUnitX(hero)
        set y = GetUnitY(hero)
        set journal = CreateItem(PH_JOURNAL_ITEM_ID, x, y)
        if journal != null then
            set added = UnitAddItem(hero, journal)
            if added then
                call ExSound_PlayLabel("ItemReceived", false)
                static if LIBRARY_HintsUI then
                    call HintsUI_PublishForUnit(HintsUI_HINT_TRAVELERS_JOURNAL_RETURN, hero)
                endif
            else
                call SetItemVisible(journal, true)
                call SetItemPosition(journal, x, y)
                call PH_Display("The Journal could not fit in " + PH_GetHeroName(hero) + "'s inventory and was left nearby.")
            endif
        endif

        set journal = null
        set hero = null
        return added
    endfunction

    private function PH_ClearPassengers takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > PH_PassengerCount
            set PH_Passenger[index] = null
            set PH_PassengerWasPaused[index] = false
            set PH_PassengerWasInvulnerable[index] = false
            set index = index + 1
        endloop
        set PH_PassengerCount = 0
    endfunction

    private function PH_HasPassenger takes unit whichUnit returns boolean
        local integer index = 1

        loop
            exitwhen index > PH_PassengerCount
            if PH_Passenger[index] == whichUnit then
                return true
            endif
            set index = index + 1
        endloop
        return false
    endfunction

    private function PH_AddPassenger takes unit whichUnit returns nothing
        if whichUnit == null or PH_ActiveCaster == null or PH_PassengerCount >= PH_MAX_PASSENGERS or PH_HasPassenger(whichUnit) then
            set whichUnit = null
            return
        endif
        if not FallenHeroState_IsAlive(whichUnit) or not PH_IsWithinRange(PH_ActiveCaster, whichUnit, PH_PARTY_RANGE) then
            set whichUnit = null
            return
        endif
        set PH_PassengerCount = PH_PassengerCount + 1
        set PH_Passenger[PH_PassengerCount] = whichUnit
        set whichUnit = null
    endfunction

    private function PH_BuildPassengerList takes nothing returns nothing
        local integer index = 1
        local unit candidate = null

        call PH_ClearPassengers()
        call PH_AddPassenger(PH_ActiveCaster)
        if PH_ActiveCaster == udg_Nazgrek then
            call PH_AddPassenger(udg_Zulkis)
        else
            call PH_AddPassenger(udg_Nazgrek)
        endif

        loop
            exitwhen index > Companions_GetControlledDisplayCount()
            set candidate = Companions_GetControlledDisplayUnit(index)
            if candidate != null and not Pet_IsPetUnit(candidate) then
                call PH_AddPassenger(candidate)
            endif
            set index = index + 1
        endloop
        if udg_TamedUnit != null and not Pet_IsDead(udg_TamedUnit) then
            call PH_AddPassenger(udg_TamedUnit)
        endif
        set candidate = null
    endfunction

    private function PH_RestorePassengerStates takes nothing returns nothing
        local integer index = 1
        local unit passenger = null

        loop
            exitwhen index > PH_PassengerCount
            set passenger = PH_Passenger[index]
            if passenger != null then
                call SetUnitInvulnerable(passenger, PH_PassengerWasInvulnerable[index])
                if not PH_PassengerWasPaused[index] then
                    call PauseUnit(passenger, false)
                endif
            endif
            set index = index + 1
        endloop
        set passenger = null
    endfunction

    private function PH_RestoreCaster takes nothing returns nothing
        if PH_ActiveCaster != null then
            call SetUnitAcquireRange(PH_ActiveCaster, PH_PreviousAcquireRange)
            call ResetUnitAnimation(PH_ActiveCaster)
        endif
    endfunction

    private function PH_ClearActiveReturn takes nothing returns nothing
        call PauseTimer(PH_ChannelTimer)
        call PauseTimer(PH_MonitorTimer)
        call PauseTimer(PH_TransferTimer)
        call PH_RestoreCaster()
        set PH_ActiveCaster = null
        set PH_ActiveHeroIndex = 0
        set PH_ChannelStartX = 0.00
        set PH_ChannelStartY = 0.00
        set PH_PreviousAcquireRange = 0.00
        set PH_TransferInProgress = false
    endfunction

    private function PH_CooldownExpired takes nothing returns nothing
    endfunction

    private function PH_FinishTransfer takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer index = 1
        local integer originZoneId = 0
        local real angle
        local real radius
        local real x
        local real y
        local unit passenger = null

        if PH_ActiveCaster == null or not HasHome() then
            call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 0.25, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
            call PH_RestorePassengerStates()
            call PH_ClearPassengers()
            call PH_ClearActiveReturn()
            set expiredTimer = null
            set passenger = null
            return
        endif

        set originZoneId = ZoneEvent_GetUnitZoneId(PH_ActiveCaster)
        if originZoneId <= 0 then
            set originZoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(PH_ActiveCaster), GetUnitY(PH_ActiveCaster))
        endif
        if originZoneId > 0 and originZoneId != PH_HomeZoneId[PH_CurrentHomeId] then
            call ZoneEvent_TriggerLeaveCleanup(originZoneId, PH_ActiveCaster)
        endif

        loop
            exitwhen index > PH_PassengerCount
            set passenger = PH_Passenger[index]
            if passenger != null then
                if index == 1 then
                    set x = PH_HomeX[PH_CurrentHomeId]
                    set y = PH_HomeY[PH_CurrentHomeId]
                else
                    set angle = I2R(index - 2) * 60.00
                    set radius = PH_FORMATION_RADIUS + I2R((index - 2) / 6) * 35.00
                    set x = PH_HomeX[PH_CurrentHomeId] + radius * Cos(angle * bj_DEGTORAD)
                    set y = PH_HomeY[PH_CurrentHomeId] + radius * Sin(angle * bj_DEGTORAD)
                endif
                call SetUnitPosition(passenger, x, y)
                call ZoneEvent_EnterTravelZone(PH_HomeZoneId[PH_CurrentHomeId], passenger)
            endif
            set index = index + 1
        endloop

        call PH_RestorePassengerStates()
        call PanCameraToTimedForPlayer(Player(0), PH_HomeX[PH_CurrentHomeId], PH_HomeY[PH_CurrentHomeId], 0.00)
        call TimerStart(PH_CooldownTimer[PH_ActiveHeroIndex], PH_COOLDOWN_DURATION, false, function PH_CooldownExpired)
        call PH_Display(PH_GetHeroName(PH_ActiveCaster) + " returned home to |cffffcc00" + PH_HomeName[PH_CurrentHomeId] + "|r|cffffffff.")
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, PH_FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        call PH_ClearPassengers()
        call PH_ClearActiveReturn()

        set expiredTimer = null
        set passenger = null
    endfunction

    private function PH_BeginTransfer takes nothing returns nothing
        local integer index = 1
        local unit passenger = null

        call PauseTimer(PH_MonitorTimer)
        set PH_TransferInProgress = true
        loop
            exitwhen index > PH_PassengerCount
            set passenger = PH_Passenger[index]
            if passenger != null then
                set PH_PassengerWasPaused[index] = IsUnitPaused(passenger)
                set PH_PassengerWasInvulnerable[index] = BlzIsUnitInvulnerable(passenger)
                call PauseUnit(passenger, true)
                call SetUnitInvulnerable(passenger, true)
            endif
            set index = index + 1
        endloop
        call PH_Display("Returning home...")
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, PH_FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        call TimerStart(PH_TransferTimer, PH_FADE_DURATION, false, function PH_FinishTransfer)
        set passenger = null
    endfunction

    private function PH_CancelReturn takes string reason returns nothing
        if PH_ActiveCaster == null or PH_TransferInProgress then
            return
        endif
        call PH_Display("Returning home failed" + reason + ".")
        call PH_PlayError()
        static if LIBRARY_HintsUI then
            call HintsUI_PublishForUnit(HintsUI_HINT_TRAVELERS_JOURNAL_CANCEL, PH_ActiveCaster)
        endif
        call PH_ClearPassengers()
        call PH_ClearActiveReturn()
    endfunction

    private function PH_MonitorChannel takes nothing returns nothing
        local real dx
        local real dy

        if PH_ActiveCaster == null then
            call PauseTimer(PH_MonitorTimer)
            return
        endif
        if not FallenHeroState_IsAlive(PH_ActiveCaster) then
            call PH_CancelReturn(" because " + PH_GetHeroName(PH_ActiveCaster) + " fell")
            return
        endif
        set dx = GetUnitX(PH_ActiveCaster) - PH_ChannelStartX
        set dy = GetUnitY(PH_ActiveCaster) - PH_ChannelStartY
        if dx * dx + dy * dy > 1.00 then
            call PH_CancelReturn(" because " + PH_GetHeroName(PH_ActiveCaster) + " moved")
        endif
    endfunction

    private function PH_ChannelComplete takes nothing returns nothing
        if PH_ActiveCaster == null then
            return
        endif
        if not FallenHeroState_IsAlive(PH_ActiveCaster) then
            call PH_CancelReturn(" because " + PH_GetHeroName(PH_ActiveCaster) + " fell")
            return
        endif
        call PH_BeginTransfer()
    endfunction

    private function PH_BeginReturn takes unit caster returns boolean
        local integer heroIndex = PH_GetHeroIndex(caster)
        local integer secondsRemaining

        if heroIndex <= 0 or GetOwningPlayer(caster) != Player(0) then
            call PH_Display("Only Nazgrek or Zul'kis can use the Journal.")
            call PH_PlayError()
            set caster = null
            return false
        endif
        if not FallenHeroState_IsAlive(caster) then
            call PH_Display(PH_GetHeroName(caster) + " cannot return home while fallen.")
            call PH_PlayError()
            set caster = null
            return false
        endif
        if not HeroHasJournal(caster) then
            call PH_Display(PH_GetHeroName(caster) + " does not have a Traveler's Journal.")
            call PH_PlayError()
            set caster = null
            return false
        endif
        if not HasHome() then
            call PH_Display("No home location has been bound.")
            call PH_PlayError()
            set caster = null
            return false
        endif
        if PH_ActiveCaster != null then
            call PH_Display(PH_GetHeroName(PH_ActiveCaster) + " is already channeling Return Home.")
            call PH_PlayError()
            set caster = null
            return false
        endif
        if GetCooldownRemaining(caster) > 0.00 then
            set secondsRemaining = R2I(GetCooldownRemaining(caster) + 0.99)
            call PH_Display(PH_GetHeroName(caster) + " must wait " + I2S(secondsRemaining) + " seconds before returning home again.")
            call PH_PlayError()
            set caster = null
            return false
        endif

        call IssueImmediateOrder(caster, "stop")
        set PH_ActiveCaster = caster
        set PH_ActiveHeroIndex = heroIndex
        set PH_ChannelStartX = GetUnitX(caster)
        set PH_ChannelStartY = GetUnitY(caster)
        set PH_PreviousAcquireRange = GetUnitAcquireRange(caster)
        call PH_BuildPassengerList()
        call SetUnitAcquireRange(caster, 0.00)
        call SetUnitAnimation(caster, "spell ready 2")
        call PH_Display(PH_GetHeroName(caster) + " is channeling Return Home for 10 seconds...")
        call TimerStart(PH_MonitorTimer, PH_CHANNEL_MONITOR_PERIOD, true, function PH_MonitorChannel)
        call TimerStart(PH_ChannelTimer, PH_CHANNEL_DURATION, false, function PH_ChannelComplete)
        set caster = null
        return true
    endfunction

    public function UseJournal takes unit hero returns boolean
        local integer slotIndex = 0
        local integer inventorySize
        local item journal = null
        local boolean used = false

        if not HasHome() or PH_GetHeroIndex(hero) <= 0 or not FallenHeroState_IsAlive(hero) or not HeroHasJournal(hero) or GetCooldownRemaining(hero) > 0.00 or PH_ActiveCaster != null then
            set hero = null
            return false
        endif
        if not DInvEnsureItemTypeInVanillaInventory(hero, PH_JOURNAL_ITEM_ID) then
            call PH_Display("The Journal could not be prepared for use from " + PH_GetHeroName(hero) + "'s inventory.")
            call PH_PlayError()
            set hero = null
            return false
        endif

        set inventorySize = UnitInventorySize(hero)
        loop
            exitwhen slotIndex >= inventorySize or journal != null
            set journal = UnitItemInSlot(hero, slotIndex)
            if journal != null and GetItemTypeId(journal) != PH_JOURNAL_ITEM_ID then
                set journal = null
            endif
            set slotIndex = slotIndex + 1
        endloop
        if journal != null then
            set used = UnitUseItem(hero, journal)
        endif
        if not used then
            call PH_Display("The Journal could not be used by " + PH_GetHeroName(hero) + ".")
            call PH_PlayError()
        endif

        set journal = null
        set hero = null
        return used
    endfunction

    public function PingHome takes nothing returns nothing
        if HasHome() then
            call PingMinimapForPlayer(Player(0), PH_HomeX[PH_CurrentHomeId], PH_HomeY[PH_CurrentHomeId], 5.00)
            call PH_Display("Home location: |cffffcc00" + PH_HomeName[PH_CurrentHomeId] + "|r|cffffffff (" + GetHomeZoneName() + ")")
        else
            call PH_Display("No home location has been bound.")
            call PH_PlayError()
        endif
    endfunction

    private function PH_OnSpellEffect takes nothing returns nothing
        local unit caster = GetTriggerUnit()

        if GetSpellAbilityId() == PH_RETURN_HOME_ABILITY_ID then
            call PH_BeginReturn(caster)
        endif
        set caster = null
    endfunction

    private function PH_OnIssuedOrder takes nothing returns nothing
        local unit orderedUnit = GetTriggerUnit()

        if orderedUnit != null and orderedUnit == PH_ActiveCaster then
            call PH_CancelReturn(" because " + PH_GetHeroName(orderedUnit) + " received another command")
        endif
        set orderedUnit = null
    endfunction

    private function PH_OnDamage takes nothing returns nothing
        local unit source = udg_DamageEventSource
        local unit target = udg_DamageEventTarget

        if PH_ActiveCaster != null and udg_DamageEventAmount > 0.00 then
            if source == PH_ActiveCaster then
                call PH_CancelReturn(" because " + PH_GetHeroName(source) + " dealt damage")
            elseif target == PH_ActiveCaster then
                call PH_CancelReturn(" because " + PH_GetHeroName(target) + " took damage")
            endif
        endif
        set source = null
        set target = null
    endfunction

    private function PH_UpdateJournalAnimations takes nothing returns nothing
        local integer homeId = 1

        loop
            exitwhen homeId > PH_HomeCount
            if PH_HomeJournal[homeId] != null then
                if homeId == PH_CurrentHomeId then
                    call SetUnitAnimation(PH_HomeJournal[homeId], "stand second")
                else
                    call SetUnitAnimation(PH_HomeJournal[homeId], "stand")
                endif
            endif
            set homeId = homeId + 1
        endloop
    endfunction

    private function PH_SetHome takes integer homeId, unit hero, boolean showFeedback returns boolean
        local effect bindEffect = null

        if homeId <= 0 or homeId > PH_HomeCount then
            set hero = null
            return false
        endif
        set PH_CurrentHomeId = homeId
        call PH_UpdateJournalAnimations()
        if hero != null then
            call PH_GiveJournal(hero)
        endif
        if showFeedback then
            call PH_Display("New home location set: |cffffcc00" + PH_HomeName[homeId] + "|r|cffffffff (" + ZonesCore_GetZoneName(PH_HomeZoneId[homeId]) + ")")
            if hero != null then
                set bindEffect = AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTo.mdl", hero, "origin")
                call DestroyEffect(bindEffect)
            endif
            if PH_HomeJournal[homeId] != null then
                call ExSound_PlayLabelOnUnit("PlayerHomeSet", PH_HomeJournal[homeId], false)
            endif
        endif
        set bindEffect = null
        set hero = null
        return true
    endfunction

    private function PH_ClearBindState takes nothing returns nothing
        set PH_BindJournal = null
        set PH_BindHero = null
        set PH_BindHomeId = 0
        set PH_BindingActive = false
    endfunction

    private function PH_FinishBindInteraction takes nothing returns nothing
        local unit journal = PH_BindJournal
        local unit hero = PH_BindHero

        call DialogSystem_ClearEscapeAction()
        if PH_BindDialog != null then
            call DialogSystem_HideDialog(PH_BindDialog, Player(0))
        endif
        call DialogInteraction_EndCombatSensitiveInteraction()
        if journal != null then
            call DialogInteraction_StartConfiguredDialogExitTransition(journal, hero, null, 0.00, true, true)
        endif
        call PH_ClearBindState()
        set journal = null
        set hero = null
    endfunction

    private function PH_BindHomeAction takes nothing returns nothing
        local player factionOwner = null

        if PH_BindHomeId > 0 and PH_BindHomeId <= PH_HomeCount then
            set factionOwner = PH_HomeFactionOwner[PH_BindHomeId]
            if factionOwner != null and IsPlayerEnemy(factionOwner, Player(0)) then
                call PH_Display("Home cannot be set while you are hostile to the faction here.")
                call PH_PlayError()
            else
                call PH_SetHome(PH_BindHomeId, PH_BindHero, true)
            endif
        endif
        call PH_FinishBindInteraction()
        set factionOwner = null
    endfunction

    private function PH_CancelBindAction takes nothing returns nothing
        call PH_FinishBindInteraction()
    endfunction

    private function PH_BuildBindDialog takes nothing returns nothing
        local button dialogButton = null

        call DialogSystem_ClearDialog(PH_BindDialog)
        call DialogSystem_SetTitle(PH_BindDialog, "Traveler's Journal")
        set dialogButton = DialogSystem_AddButton(PH_BindDialog, "Set " + PH_HomeName[PH_BindHomeId] + " as your home", 1)
        call DialogSystem_BindButtonCode(dialogButton, function PH_BindHomeAction)
        set dialogButton = DialogSystem_AddButton(PH_BindDialog, "Cancel", 2)
        call DialogSystem_BindButtonCode(dialogButton, function PH_CancelBindAction)
        call DialogSystem_SetEscapeAction(function PH_CancelBindAction)
        call DialogSystem_SetContext(PH_BindJournal, Player(0))
        call DialogSystem_ShowDialog(PH_BindDialog, Player(0))
        set dialogButton = null
    endfunction

    public function ContinueBindDialog takes nothing returns nothing
        if PH_BindingActive and PH_BindJournal != null and PH_BindHero != null then
            call PH_BuildBindDialog()
        else
            call PH_FinishBindInteraction()
        endif
    endfunction

    private function PH_InterruptBindInteraction takes nothing returns nothing
        if PH_BindingActive then
            call PH_Display("Setting a home was interrupted by combat.")
            call PH_FinishBindInteraction()
        endif
    endfunction

    private function PH_OnJournalSelected takes nothing returns nothing
        local unit journal = DialogInteraction_GetSelectedUnit()
        local unit hero = null
        local player factionOwner = null
        local integer homeId = 0

        if journal != null and PH_JournalHome != 0 then
            set homeId = PH_JournalHome.integer[GetHandleId(journal)]
        endif
        if homeId <= 0 or homeId > PH_HomeCount or not DialogInteraction_IsUnitAlive(journal) then
            set journal = null
            set hero = null
            set factionOwner = null
            return
        endif
        call DialogInteraction_ConsumeSelection()

        set hero = DialogInteraction_GetDialogSelectionHero(journal, PH_BIND_RANGE, true, true)
        if not DialogInteraction_PassDialogSelectionGate(journal, hero, PH_BIND_RANGE, null, true, true, false, false, true, true) then
            call PH_Debug("Journal selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
            set journal = null
            set hero = null
            set factionOwner = null
            return
        endif
        if homeId == PH_CurrentHomeId then
            call PH_Display("This is your current home location: |cffffcc00" + PH_HomeName[homeId] + "|r|cffffffff.")
            if not HeroHasJournal(hero) then
                static if LIBRARY_HintsUI then
                    call HintsUI_PublishForUnit(HintsUI_HINT_TRAVELERS_JOURNAL_LOST, hero)
                endif
            endif
            set journal = null
            set hero = null
            set factionOwner = null
            return
        endif

        set factionOwner = PH_HomeFactionOwner[homeId]
        if factionOwner != null and IsPlayerEnemy(factionOwner, Player(0)) then
            call PH_Display("Home cannot be set while you are hostile to the faction here.")
            call PH_PlayError()
            set journal = null
            set hero = null
            set factionOwner = null
            return
        endif
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(journal, hero, function PH_InterruptBindInteraction, true) then
            set journal = null
            set hero = null
            set factionOwner = null
            return
        endif

        set PH_BindJournal = journal
        set PH_BindHero = hero
        set PH_BindHomeId = homeId
        set PH_BindingActive = true
        call DialogSystem_SetEscapeAction(function PH_CancelBindAction)
        call DialogInteraction_StartConfiguredDialogEntryTransition(journal, hero, true, true, true, "PlayerHome_ContinueBindDialog")
        set journal = null
        set hero = null
        set factionOwner = null
    endfunction

    public function RegisterJournal takes unit journal, string locationName, integer zoneId, player factionOwner returns integer
        local integer homeId

        if journal == null or GetUnitTypeId(journal) != PH_WORLD_JOURNAL_ID or locationName == "" or zoneId <= 0 then
            set journal = null
            set factionOwner = null
            return 0
        endif
        if PH_JournalHome == 0 then
            set PH_JournalHome = Table.create()
        endif

        set homeId = PH_JournalHome.integer[GetHandleId(journal)]
        if homeId <= 0 then
            if PH_HomeCount >= PH_MAX_HOMES then
                set journal = null
                set factionOwner = null
                return 0
            endif
            set PH_HomeCount = PH_HomeCount + 1
            set homeId = PH_HomeCount
            set PH_JournalHome.integer[GetHandleId(journal)] = homeId
            call DialogInteraction_RegisterSelectionHandler(journal, function PH_OnJournalSelected)
        endif

        set PH_HomeJournal[homeId] = journal
        set PH_HomeName[homeId] = locationName
        set PH_HomeZoneId[homeId] = zoneId
        set PH_HomeFactionOwner[homeId] = factionOwner
        set PH_HomeX[homeId] = GetUnitX(journal)
        set PH_HomeY[homeId] = GetUnitY(journal)
        call DialogInteraction_ConfigureDialogTransition(journal, PH_CINEMATIC_MOVE_MODE, PH_CINEMATIC_MOVE_OFFSET, PH_CINEMATIC_MOVE_ANGLE, PH_CAMERA_DISTANCE, PH_CAMERA_Z_OFFSET, PH_CAMERA_ANGLE, PH_CAMERA_ROTATION_OFFSET, PH_CAMERA_FAR_Z, PH_CAMERA_FOV, PH_CAMERA_BLOCK_RADIUS, PH_CAMERA_BLOCK_CHECK)

        set journal = null
        set factionOwner = null
        return homeId
    endfunction

    private function PH_FindJournalEnum takes nothing returns nothing
        local unit enumUnit = GetEnumUnit()

        if PH_FoundJournal == null and GetUnitTypeId(enumUnit) == PH_WORLD_JOURNAL_ID then
            set PH_FoundJournal = enumUnit
        endif
        set enumUnit = null
    endfunction

    private function PH_RegisterRectJournal takes rect homeRect, string locationName, integer zoneId, player factionOwner returns integer
        local group searchGroup = CreateGroup()
        local unit journal = null
        local integer homeId = 0

        set PH_FoundJournal = null
        if homeRect != null then
            call GroupEnumUnitsInRect(searchGroup, homeRect, null)
            call ForGroup(searchGroup, function PH_FindJournalEnum)
        endif
        set journal = PH_FoundJournal
        set PH_FoundJournal = null
        if journal != null then
            set homeId = RegisterJournal(journal, locationName, zoneId, factionOwner)
        else
            call PH_Debug("No Traveler's Journal found for " + locationName + ".")
        endif

        call DestroyGroup(searchGroup)
        set searchGroup = null
        set journal = null
        set homeRect = null
        set factionOwner = null
        return homeId
    endfunction

    private function PH_DelayedInit takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local integer defaultHomeId

        set defaultHomeId = PH_RegisterRectJournal(gg_rct_PlayerHome1, "Nazgrek's Hut", 2, Player(5))
        call PH_RegisterRectJournal(gg_rct_PlayerHome2, "Horde Scout Base", 8810, Player(5))
        if defaultHomeId > 0 then
            call PH_SetHome(defaultHomeId, udg_Nazgrek, false)
        else
            call PH_Debug("Nazgrek's Hut could not be configured as the default home.")
        endif

        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set PH_JournalHome = Table.create()
        set PH_ChannelTimer = CreateTimer()
        set PH_MonitorTimer = CreateTimer()
        set PH_TransferTimer = CreateTimer()
        set PH_CooldownTimer[1] = CreateTimer()
        set PH_CooldownTimer[2] = CreateTimer()
        set PH_BindDialog = DialogCreate()

        call Events_RegisterSpellEffect(function PH_OnSpellEffect)
        call Events_RegisterPlayerUnitEvent(function PH_OnIssuedOrder, EVENT_PLAYER_UNIT_ISSUED_ORDER)
        call Events_RegisterPlayerUnitEvent(function PH_OnIssuedOrder, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
        call Events_RegisterPlayerUnitEvent(function PH_OnIssuedOrder, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
        call RegisterDamageEngine(function PH_OnDamage, "After", 1.00)
        call TimerStart(initTimer, 0.25, false, function PH_DelayedInit)

        set initTimer = null
    endfunction
endlibrary
