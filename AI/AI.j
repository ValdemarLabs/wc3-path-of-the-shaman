/**
    AI

    Author: Valdemar
    Version:

    Description:
    Master JASS AI registry and shared behavior engine for PotS AI heroes and
    AI units. This library owns AI instance identity, class/profile caps,
    shared state transitions, travel, boss-cast evade, revive handling, common
    helpers, and ExSound/DialogSystem chatter dispatch. Class-specific logic
    belongs in small sublibraries that register profiles and callbacks.

    Credits:
    - Old GUI triggers under `AI/_OldGUI_triggers/`
    - Table v6 by Bribe

    How to install:
    Import this library before AI sublibraries and after the required shared
    systems: Table, CampFire, Companions, UnitDeathEvent, DamageEngine,
    DialogSystem, ExSound, and Reputation. AI professions also require
    DEquipment, GatherNodes, GatherNodeSkills, GatherNodeItems, and GatherNodeUnits. File
    names may use underscores, but vJASS library identifiers and generated
    public function prefixes must not.

    API:
    call AI_RegisterClass(className)
    call AI_RegisterProfile(classId, unitTypeId, profileName)
    call AI_RegisterUnit(whichUnit, profileId, uniqueId)
    call AI_RegisterUnitByType(whichUnit, uniqueId)
    call AI_UnregisterUnit(whichUnit)
    call AI_SpawnProfile(profileId, owner, x, y, facing, uniqueId)
    call AI_SetClassCap(classId, cap)
    call AI_SetProfileCap(profileId, cap)
    call AI_SetUnitTypeCap(unitTypeId, cap)
    call AI_SetProfileRandomUniqueId(profileId, uniqueId)
    call AI_SetUnitTypeDefaultProfile(unitTypeId, profileId)
    call AI_SetProfileFixedHeroLevel(profileId, level)
    call AI_SetProfileXpLockedUntilInvite(profileId, enabled)
    call AI_SetProfileAutonomous(profileId, enabled)
    call AI_SetProfileSpawnOwner(profileId, owner)
    call AI_SetProfileFaction(profileId, factionName)
    call AI_GetProfileFaction(profileId) returns string
    call AI_SetProfileRegisterCallback(profileId, callback)
    call AI_SetProfileThinkCallback(profileId, callback)
    call AI_SetProfileCompanionRetreat(profileId, enabled)
    call AI_AddProfileProfession(profileId, AI_PROFESSION_MINING)
    call AI_RemoveProfileProfession(profileId, AI_PROFESSION_MINING)
    call AI_GetProfessionSkill(whichUnit, professionId)
    call AI_AddProfileSpawnRect(profileId, whichRect)
    call AI_AddProfileRetreatRect(profileId, whichRect)
    call AI_AddProfileAllowedZoneRect(profileId, whichRect)
    call AI_AddProfileShopUnit(profileId, shopUnit)
    call AI_AddProfileShopUnitType(profileId, unitTypeId)
    call AI_AddRandomSpawnProfile(profileId)
    call AI_SetRandomSpawnFirstProfile(profileId)
    call AI_SetRandomSpawnHardCap(cap)
    call AI_SetRandomSpawnActiveCap(cap)
    call AI_GetRandomSpawnActiveCap() returns integer
    call AI_SetRandomSpawnActiveMin(cap)
    call AI_SetRandomSpawnOwner(owner)
    call AI_SpawnRandomHero(showMessage)
    call AI_AddProfileStartingAbility(profileId, abilityId)
    call AI_AddProfileAbility(profileId, abilityId)
    call AI_AddDefaultShopItems(profileId)
    call AI_RegisterBarkSequence(profileId, barkType, text, soundPrefix, first, last)
    call AI_RegisterBarkLineForReputation(profileId, barkType, text, soundKey, factionName, minRep, maxRep)
    call AI_RegisterBarkReply(primarySoundKey, responderProfileId, text, replySoundKey)
    call AI_RegisterBarkReplySequenceSuffix(primarySoundPrefix, first, last, responderProfileId, text, replySoundPrefix, replySoundSuffix)
    call AI_BeginBuy(whichUnit)
    call AI_BeginSell(whichUnit)
    call AI_BeginCamp(whichUnit, duration)
    call AI_DebugForceShopBuy() returns integer
    call AI_DebugForceShopSell() returns integer
    call AI_DebugForceShopByInventory() returns integer
    call AI_DebugForceNightCamp() returns integer
    call AI_DebugForceProfessionCraft() returns integer
    call AI_StartTravel(whichUnit, duration, returnX, returnY)
    call AI_RegisterBossCastAbility(abilityId, evadeRadius, evadeDistance)
    call AI_HandleBossCast(caster, abilityId, targetX, targetY)
    call AI_RequestBark(speaker, barkType)
    call AI_GetReviveTimer(whichUnit) returns timer
    call AI_CancelReviveTimer(whichUnit)
    call AI_SetReviveRemaining(whichUnit, remaining)
    call AI_GetReviveRemaining(whichUnit) returns real
    call AI_IsReviving(whichUnit) returns boolean
    call AI_IsAlive(whichUnit) returns boolean
    call AI_ReviveAt(whichUnit, x, y, showEffects) returns boolean
    call AI_ArePartyMembers(firstUnit, secondUnit) returns boolean
    call AI_GetFactionInfoText(whichUnit) returns string
    call AI_SetDebugMode(enabled)

**/
library AI initializer Init requires Table, CampFire, Companions, Events, UnitDeathEvent, DamageEngine, DialogSystem, ExSound, IconQuery, Reputation, DEquipment, GatherNodes, GatherNodeSkills, GatherNodeItems, GatherNodeUnits, CinematicMover, Professions, VoicelinesWarlock, VoicelinesUndeadWarlock, VoicelinesRestoShaman, VoicelinesEngineer, VoicelinesPaladin, FallenHeroState, optional Shop

globals
    constant integer AI_STATE_INACTIVE = 0
    constant integer AI_STATE_IDLE = 1
    constant integer AI_STATE_WANDER = 2
    constant integer AI_STATE_COMBAT = 3
    constant integer AI_STATE_RETREAT_COMBAT = 4
    constant integer AI_STATE_RETREAT_BASE = 5
    constant integer AI_STATE_BUY = 6
    constant integer AI_STATE_SELL = 7
    constant integer AI_STATE_CAMP = 8
    constant integer AI_STATE_TRAVEL = 9
    constant integer AI_STATE_DEAD = 10
    constant integer AI_STATE_COMPANION_CONTROLLED = 11
    constant integer AI_STATE_BOSS_EVADE = 12
    constant integer AI_STATE_SOCIAL = 13

    constant integer AI_PROFESSION_NONE = 0
    constant integer AI_PROFESSION_MINING = 1
    constant integer AI_PROFESSION_HERBALISM = 2
    constant integer AI_PROFESSION_SKINNING = 3
    constant integer AI_PROFESSION_FISHING = 4
    constant integer AI_PROFESSION_ALCHEMY = 5
    constant integer AI_PROFESSION_BLACKSMITHING = 6
    constant integer AI_PROFESSION_LEATHERWORKING = 7
    constant integer AI_PROFESSION_ENCHANTING = 8
    constant integer AI_PROFESSION_COOKING = 9
    constant integer AI_PROFESSION_MAX = AI_PROFESSION_COOKING

    constant integer AI_BARK_GREET = 1
    constant integer AI_BARK_PASSIVE = 2
    constant integer AI_BARK_NORMAL = 3
    constant integer AI_BARK_AGGRESSIVE = 4
    constant integer AI_BARK_HOLD = 5
    constant integer AI_BARK_DROP_ITEMS = 6
    constant integer AI_BARK_KICKED = 7
    constant integer AI_BARK_ITEM_GIVEN = 8
    constant integer AI_BARK_ATTACKING = 9
    constant integer AI_BARK_CASTING = 10
    constant integer AI_BARK_KILLING = 11
    constant integer AI_BARK_COMPANION_DIES = 12
    constant integer AI_BARK_IDLE = 13
    constant integer AI_BARK_MOVING = 14
    constant integer AI_BARK_FAREWELL = 15

    constant integer AI_REP_NO_MIN = -999999
    constant integer AI_REP_NO_MAX = 999999

    integer AI_EventInstance = 0
    unit AI_EventUnit = null
    integer AI_EventProfileId = 0
    integer AI_EventClassId = 0
    integer AI_EventState = AI_STATE_INACTIVE
    integer AI_EventBarkType = 0
    unit AI_EventTarget = null
    integer AI_EventAbilityId = 0

    private constant boolean DEBUG_DEFAULT = false
    private constant integer MAX_AI_INSTANCES = 512
    private constant integer MAX_BOSS_CASTS = 64
    private constant integer MAX_PROFILE_POINTS = 64
    private constant integer MAX_PROFILE_ITEMS = 64
    private constant integer MAX_BARK_LINES = 192
    private constant integer MAX_RANDOM_SPAWN_PROFILES = 64
    private constant integer MAX_PLAYER_COLOR_INDEX = 23
    private constant integer AI_RANDOM_DEFAULT_OWNER_INDEX = 1
    private constant real AI_THINK_INTERVAL = 0.50
    private constant real AI_DEFAULT_THINK_MIN = 0.80
    private constant real AI_DEFAULT_THINK_MAX = 1.20
    private constant real AI_DEFAULT_REVIVE_DELAY = 60.00
    private constant real AI_DEFAULT_ABILITY_GAP = 2.00
    private constant real AI_EQUIPMENT_CHECK_MIN = 6.00
    private constant real AI_EQUIPMENT_CHECK_MAX = 14.00
    private constant real AI_ABILITY_ORDER_JITTER = 0.35
    private constant real AI_RETREAT_COMBAT_TIME = 5.00
    private constant real AI_RETREAT_BASE_TIME = 30.00
    private constant real AI_BOSS_EVADE_TIME = 2.25
    private constant real AI_DIALOG_UNLOCK_PAD = 0.15
    private constant real AI_BARK_AUDIBLE_RANGE = 2600.00
    private constant real AI_BARK_REPLY_RANGE = 900.00
    private constant real AI_BARK_GLOBAL_GAP = 0.75
    private constant real AI_COMMAND_BARK_DELAY = 0.01
    private constant real AI_SHIELD_BLOCK_CHANCE = 33.34
    private constant real AI_RANDOM_SPAWN_MIN = 50.00
    private constant real AI_RANDOM_SPAWN_MAX = 150.00
    private constant real AI_RANDOM_TRAVEL_MIN = 120.00
    private constant real AI_RANDOM_TRAVEL_MAX = 260.00
    private constant real AI_RANDOM_TRAVEL_DURATION_MIN = 60.00
    private constant real AI_RANDOM_TRAVEL_DURATION_MAX = 180.00
    private constant real AI_SHOP_CHECK_MIN = 18.00
    private constant real AI_SHOP_CHECK_MAX = 45.00
    private constant real AI_SHOP_COOLDOWN_MIN = 120.00
    private constant real AI_SHOP_COOLDOWN_MAX = 240.00
    private constant integer AI_SHOP_EMPTY_BUY_CHANCE = 20
    private constant real AI_PROFESSION_SCAN_RANGE = 900.00
    private constant real AI_PROFESSION_DEBUG_STATION_RANGE = 99999.00
    private constant real AI_PROFESSION_ACTION_MIN = 12.00
    private constant real AI_PROFESSION_ACTION_MAX = 22.00
    private constant real AI_PROFESSION_IDLE_MIN = 18.00
    private constant real AI_PROFESSION_IDLE_MAX = 40.00
    private constant integer AI_PROFESSION_CRAFT_CHANCE = 25
    private constant real AI_PROFESSION_TOOL_DURATION = 45.00
    private constant real AI_PROFESSION_TOOL_CLEANUP_DELAY = 10.00
    private constant integer AI_PROFESSION_FAIL_LIMIT = 3
    private constant real AI_PROFESSION_FAIL_BACKOFF_MIN = 35.00
    private constant real AI_PROFESSION_FAIL_BACKOFF_MAX = 75.00
    private constant real AI_SOCIAL_SCAN_RANGE = 1400.00
    private constant real AI_SOCIAL_MIN_RANGE = 220.00
    private constant real AI_SOCIAL_FACE_RANGE = 330.00
    private constant real AI_SOCIAL_DURATION_MIN = 4.00
    private constant real AI_SOCIAL_DURATION_MAX = 8.00
    private constant real AI_SOCIAL_COOLDOWN_MIN = 35.00
    private constant real AI_SOCIAL_COOLDOWN_MAX = 90.00
    private constant real AI_COMPANION_CHAT_COOLDOWN_MIN = 45.00
    private constant real AI_COMPANION_CHAT_COOLDOWN_MAX = 100.00
    private constant real AI_COMPANION_CHAT_RETRY_MIN = 8.00
    private constant real AI_COMPANION_CHAT_RETRY_MAX = 18.00
    private constant integer AI_COMPANION_CHAT_CHANCE = 35
    private constant real AI_STUCK_MIN_MOVE = 24.00
    private constant real AI_STUCK_SECONDS = 4.00
    private constant real AI_STUCK_RETRY_RADIUS = 360.00
    private constant real AI_COMPANION_PICKUP_RANGE = 420.00
    private constant real AI_COMPANION_PICKUP_MIN_DELAY = 24.00
    private constant real AI_COMPANION_PICKUP_MAX_DELAY = 55.00
    private constant integer AI_SIDE_SCAN_MAX_PER_TICK = 2
    private constant real AI_COMPANION_RETREAT_TIME = 2.50
    private constant real AI_COMPANION_RETREAT_DISTANCE = 420.00
    private constant integer AI_RIVERBANE_GRAVEYARD_ID = 5
    private constant real AI_CAMP_NIGHT_MIN = 18.00
    private constant real AI_CAMP_NIGHT_MAX = 6.00
    private constant real AI_CAMP_DURATION_MIN = 60.00
    private constant real AI_CAMP_DURATION_MAX = 240.00
    private constant real AI_CAMP_COOLDOWN_MIN = 480.00
    private constant real AI_CAMP_COOLDOWN_MAX = 900.00
    private constant integer AI_CAMP_FIRE_PLACEMENT_ATTEMPTS = 10
    private constant real AI_CAMP_FIRE_MIN_OFFSET = 160.00
    private constant real AI_CAMP_FIRE_MAX_OFFSET = 260.00
    private constant real AI_CAMP_FIRE_UNIT_LIFETIME = 60.00
    private constant integer AI_RANDOM_ACTIVE_CAP_MAX = 32
    private constant integer AI_DEFAULT_BAG_TIER = DINV_BAG_TIER_SMALL
    private constant integer AI_PARTY_MAX_SIZE = 3
    private constant real AI_PARTY_ORGANIZE_MIN = 45.00
    private constant real AI_PARTY_ORGANIZE_MAX = 120.00
    private constant real AI_PARTY_SCAN_RANGE = 1300.00
    private constant real AI_PARTY_FOLLOW_RANGE = 700.00
    private constant real AI_PARTY_CLOSE_RANGE = 300.00

    private constant integer ITEM_MINOR_MANA_POTION = 'I6BS'
    private constant integer ITEM_MANA_POTION = 'pman'
    private constant integer ITEM_MAJOR_MANA_POTION = 'I6BT'
    private constant integer ITEM_MINOR_HEALING_POTION = 'I6BD'
    private constant integer ITEM_HEALING_POTION = 'phea'
    private constant integer ITEM_MAJOR_HEALING_POTION = 'I6BE'
    private constant integer ITEM_SPRING_WATER = 'I60Z'
    private constant integer ITEM_HEALING_SALVE = 'hslv'
    private constant integer ITEM_GREATER_HEALING_SALVE = 'I6BC'
    private constant integer ITEM_MINING_PICK = 'I672'
    private constant integer ITEM_SKINNING_KNIFE = 'I66M'
    private constant integer ITEM_CAMP_FIRE = 'I611'
    private constant integer ITEM_SPIRIT_SHARD = 'I00C'
    private constant integer UNIT_AVELINE_RIVERBANE = 'O009'
    private constant integer UNIT_CAMP_FIRE = 'n61C'

    private Table UnitInstance = 0
    private Table UniqueInstance = 0
    private Table ClassByName = 0
    private Table ProfileByName = 0

    private Table ClassName = 0
    private Table ClassCap = 0
    private Table ClassActiveCount = 0

    private Table ProfileName = 0
    private Table ProfileClass = 0
    private Table ProfileUnitType = 0
    private Table ProfileCap = 0
    private Table ProfileActiveCount = 0
    private Table ProfileReviveDelay = 0
    private Table ProfileRandomUniqueId = 0
    private Table ProfileFixedHeroLevel = 0
    private Table ProfileLockXpUntilInvite = 0
    private Table ProfileNoManaRestore = 0
    private Table ProfileAllowCompanionTravel = 0
    private Table ProfileAutonomousDisabled = 0
    private Table ProfileFaction = 0
    private Table ProfileSpawnOwnerSlot = 0
    private Table ProfileRegisterTrigger = 0
    private Table ProfileThinkTrigger = 0
    private Table ProfileDeathTrigger = 0
    private Table ProfileReviveTrigger = 0
    private Table ProfileCompanionRetreatDisabled = 0
    private Table ProfileProfession = 0
    private Table ProfileProfessionCount = 0

    private Table UnitTypeCap = 0
    private Table UnitTypeActiveCount = 0
    private Table UnitTypeDefaultProfile = 0

    private Table InstanceUnit = 0
    private Table InstanceClass = 0
    private Table InstanceProfile = 0
    private Table InstanceUnique = 0
    private Table InstanceUnitType = 0
    private Table InstanceState = 0
    private Table InstancePreviousState = 0
    private Table InstanceActiveSlot = 0
    private Table InstanceAlive = 0
    private Table InstanceTraveling = 0
    private Table InstanceRandomManaged = 0
    private Table InstanceHiddenByCap = 0
    private Table InstanceCompanionControlled = 0
    private Table InstanceCinematicParked = 0
    private Table InstanceInviteUnlocked = 0
    private Table InstanceAiPartyLeader = 0
    private Table InstanceAiPartyFollowerCount = 0
    private Table InstanceNextThink = 0
    private Table InstanceNextAbility = 0
    private Table InstanceNextItem = 0
    private Table InstanceNextEquipment = 0
    private Table InstanceNextPickup = 0
    private Table InstanceNextChat = 0
    private Table InstanceNextBark = 0
    private Table InstanceNextShop = 0
    private Table InstanceNextProfession = 0
    private Table InstanceProfessionFailCount = 0
    private Table InstanceProfessionBlockedUntil = 0
    private Table InstanceIgnoredGatherUnit = 0
    private Table InstanceIgnoredGatherItem = 0
    private Table InstanceNextCamp = 0
    private Table InstanceNextSocial = 0
    private Table InstanceSocialUntil = 0
    private Table InstanceLastOrder = 0
    private Table InstanceLastX = 0
    private Table InstanceLastY = 0
    private Table InstanceStuckSince = 0
    private Table InstanceRetreatUntil = 0
    private Table InstanceTravelReturnAt = 0
    private Table InstanceTravelReturnX = 0
    private Table InstanceTravelReturnY = 0
    private Table InstanceHomeX = 0
    private Table InstanceHomeY = 0
    private Table InstanceActionX = 0
    private Table InstanceActionY = 0
    private Table InstanceActionShopUnit = 0
    private Table InstanceReviveTimer = 0
    private Table ReviveTimerInstance = 0

    private Table ProfileSpawnCount = 0
    private Table ProfileSpawnX = 0
    private Table ProfileSpawnY = 0
    private Table ProfileRetreatCount = 0
    private Table ProfileRetreatX = 0
    private Table ProfileRetreatY = 0
    private Table ProfileShopCount = 0
    private Table ProfileShopX = 0
    private Table ProfileShopY = 0
    private Table ProfileShopUnit = 0
    private Table ProfileShopItemCount = 0
    private Table ProfileShopItemType = 0
    private Table ProfileAllowedZoneCount = 0
    private Table ProfileAllowedZoneMinX = 0
    private Table ProfileAllowedZoneMinY = 0
    private Table ProfileAllowedZoneMaxX = 0
    private Table ProfileAllowedZoneMaxY = 0
    private Table ProfileStartingAbilityCount = 0
    private Table ProfileStartingAbilityId = 0
    private Table ProfileAbilityCount = 0
    private Table ProfileAbilityId = 0

    private Table BarkLineCount = 0
    private Table BarkLineText = 0
    private Table BarkLineSound = 0
    private Table BarkLineFaction = 0
    private Table BarkLineMinRep = 0
    private Table BarkLineMaxRep = 0
    private Table ReplyLineCount = 0
    private Table ReplyLineResponderProfile = 0
    private Table ReplyLineText = 0
    private Table ReplyLineSound = 0
    private Table ReplyTimerSpeaker = 0
    private Table ReplyTimerResponder = 0
    private Table ReplyTimerText = 0
    private Table ReplyTimerSound = 0
    private Table AiCampFireCleanupUnit = 0

    private Table TempAbilityUnit = 0
    private Table TempAbilityRemove = 0
    private Table TempAbilityRestore = 0

    private integer ActiveCount = 0
    private integer array ActiveInstances
    private integer NextInstanceId = 1
    private integer NextClassId = 1
    private integer NextProfileId = 1
    private integer RandomSpawnProfileCount = 0
    private integer array RandomSpawnProfiles
    private integer RandomSpawnManagedCount = 0
    private integer RandomSpawnHardCap = 32
    private integer RandomSpawnActiveCap = 4
    private integer RandomSpawnActiveMin = 4
    private integer RandomSpawnOwnerIndex = AI_RANDOM_DEFAULT_OWNER_INDEX
    private integer RandomSpawnFirstProfile = 0
    private item array InstanceProfessionToolItem
    private integer array InstanceProfessionToolType
    private real array InstanceProfessionToolExpires
    private unit array InstanceProfessionTargetUnit
    private unit array InstanceSocialTarget
    private boolean array InstanceSocialStopped
    private minimapicon array InstanceDebugIcon

    private timer ClockTimer = null
    private timer ThinkTimer = null
    private timer RandomSpawnTimer = null
    private timer RandomTravelTimer = null
    private timer DialogUnlockTimer = null
    private timer PendingCommandBarkTimer = null
    private trigger UnitIndexTrigger = null
    private trigger DebugSpawnTrigger = null
    private trigger DebugModeTrigger = null
    private trigger DebugCampTrigger = null
    private trigger DebugCraftTrigger = null
    private trigger DebugShopTrigger = null
    private group TempGroup = null
    private rect TempRect = null
    private boolean DebugMode = DEBUG_DEFAULT
    private boolean RandomSpawnEnabled = true
    private boolean RandomSpawnFirstProfileDone = false
    private boolean RandomTravelEnabled = true
    private real NextGlobalBark = 0.00
    private unit PendingCommandBarkSpeaker = null
    private integer PendingCommandBarkType = 0
    private integer PendingCommandBarkSeen = 0
    private real NextAiPartyOrganize = 0.00
    private real RandomPointX = 0.00
    private real RandomPointY = 0.00
    private item ProfessionSearchItem = null
    private unit ProfessionSearchUnit = null
    private unit ProfessionSearchStation = null
    private unit ProfessionSearchSource = null
    private integer ProfessionSearchProfileId = 0
    private integer ProfessionSearchWantedProfession = 0
    private real ProfessionSearchBestDistance = 0.00
    private unit ItemSearchSource = null
    private item ItemSearchBest = null
    private real ItemSearchBestDistance = 0.00
    private boolean ItemSearchNoMana = false
    private real SideScanBudgetTime = -1.00
    private integer SideScanBudgetCount = 0
    private unit SocialSearchTarget = null
    private unit SocialSearchSource = null
    private integer SocialSearchSeen = 0

    private boolean BossFightActive = false
    private integer BossCastCount = 0
    private integer array BossCastAbility
    private real array BossCastRadius
    private real array BossCastDistance

    private unit SearchSource = null
    private unit SearchBestUnit = null
    private real SearchBestDistance = 0.00
    private real SearchRangeDistance = 0.00
    private real SearchBestScore = 0.00
    private unit AllySearchSource = null
    private unit AllySearchBestUnit = null
    private real AllySearchBestLife = 0.00
    private boolean AllySearchIncludeSelf = false
    private unit CountSource = null
    private integer CountResult = 0
    private unit CombatSearchSource = null
    private boolean CombatSearchFound = false
    private integer ShopScanProfileId = 0
    private integer ShopScanUnitTypeId = 0
    private integer ShopScanAdded = 0
endglobals

private function DebugMsg takes string msg returns nothing
    if DebugMode then
        call BJDebugMsg("[AI] " + msg)
    endif
endfunction

private function EnsureState takes nothing returns nothing
    if UnitInstance == 0 then
        set UnitInstance = Table.create()
        set UniqueInstance = Table.create()
        set ClassByName = Table.create()
        set ProfileByName = Table.create()
        set ClassName = Table.create()
        set ClassCap = Table.create()
        set ClassActiveCount = Table.create()
        set ProfileName = Table.create()
        set ProfileClass = Table.create()
        set ProfileUnitType = Table.create()
        set ProfileCap = Table.create()
        set ProfileActiveCount = Table.create()
        set ProfileReviveDelay = Table.create()
        set ProfileRandomUniqueId = Table.create()
        set ProfileFixedHeroLevel = Table.create()
        set ProfileLockXpUntilInvite = Table.create()
        set ProfileNoManaRestore = Table.create()
        set ProfileAllowCompanionTravel = Table.create()
        set ProfileAutonomousDisabled = Table.create()
        set ProfileFaction = Table.create()
        set ProfileSpawnOwnerSlot = Table.create()
        set ProfileRegisterTrigger = Table.create()
        set ProfileThinkTrigger = Table.create()
        set ProfileDeathTrigger = Table.create()
        set ProfileReviveTrigger = Table.create()
        set ProfileCompanionRetreatDisabled = Table.create()
        set ProfileProfession = Table.create()
        set ProfileProfessionCount = Table.create()
        set UnitTypeCap = Table.create()
        set UnitTypeActiveCount = Table.create()
        set UnitTypeDefaultProfile = Table.create()
        set InstanceUnit = Table.create()
        set InstanceClass = Table.create()
        set InstanceProfile = Table.create()
        set InstanceUnique = Table.create()
        set InstanceUnitType = Table.create()
        set InstanceState = Table.create()
        set InstancePreviousState = Table.create()
        set InstanceActiveSlot = Table.create()
        set InstanceAlive = Table.create()
        set InstanceTraveling = Table.create()
        set InstanceRandomManaged = Table.create()
        set InstanceHiddenByCap = Table.create()
        set InstanceCompanionControlled = Table.create()
        set InstanceCinematicParked = Table.create()
        set InstanceInviteUnlocked = Table.create()
        set InstanceAiPartyLeader = Table.create()
        set InstanceAiPartyFollowerCount = Table.create()
        set InstanceNextThink = Table.create()
        set InstanceNextAbility = Table.create()
        set InstanceNextItem = Table.create()
        set InstanceNextEquipment = Table.create()
        set InstanceNextPickup = Table.create()
        set InstanceNextChat = Table.create()
        set InstanceNextBark = Table.create()
        set InstanceNextShop = Table.create()
        set InstanceNextProfession = Table.create()
        set InstanceProfessionFailCount = Table.create()
        set InstanceProfessionBlockedUntil = Table.create()
        set InstanceIgnoredGatherUnit = Table.create()
        set InstanceIgnoredGatherItem = Table.create()
        set InstanceNextCamp = Table.create()
        set InstanceNextSocial = Table.create()
        set InstanceSocialUntil = Table.create()
        set InstanceLastOrder = Table.create()
        set InstanceLastX = Table.create()
        set InstanceLastY = Table.create()
        set InstanceStuckSince = Table.create()
        set InstanceRetreatUntil = Table.create()
        set InstanceTravelReturnAt = Table.create()
        set InstanceTravelReturnX = Table.create()
        set InstanceTravelReturnY = Table.create()
        set InstanceHomeX = Table.create()
        set InstanceHomeY = Table.create()
        set InstanceActionX = Table.create()
        set InstanceActionY = Table.create()
        set InstanceActionShopUnit = Table.create()
        set InstanceReviveTimer = Table.create()
        set ReviveTimerInstance = Table.create()
        set ProfileSpawnCount = Table.create()
        set ProfileSpawnX = Table.create()
        set ProfileSpawnY = Table.create()
        set ProfileRetreatCount = Table.create()
        set ProfileRetreatX = Table.create()
        set ProfileRetreatY = Table.create()
        set ProfileShopCount = Table.create()
        set ProfileShopX = Table.create()
        set ProfileShopY = Table.create()
        set ProfileShopUnit = Table.create()
        set ProfileShopItemCount = Table.create()
        set ProfileShopItemType = Table.create()
        set ProfileAllowedZoneCount = Table.create()
        set ProfileAllowedZoneMinX = Table.create()
        set ProfileAllowedZoneMinY = Table.create()
        set ProfileAllowedZoneMaxX = Table.create()
        set ProfileAllowedZoneMaxY = Table.create()
        set ProfileStartingAbilityCount = Table.create()
        set ProfileStartingAbilityId = Table.create()
        set ProfileAbilityCount = Table.create()
        set ProfileAbilityId = Table.create()
        set BarkLineCount = Table.create()
        set BarkLineText = Table.create()
        set BarkLineSound = Table.create()
        set BarkLineFaction = Table.create()
        set BarkLineMinRep = Table.create()
        set BarkLineMaxRep = Table.create()
        set ReplyLineCount = Table.create()
        set ReplyLineResponderProfile = Table.create()
        set ReplyLineText = Table.create()
        set ReplyLineSound = Table.create()
        set ReplyTimerSpeaker = Table.create()
        set ReplyTimerResponder = Table.create()
        set ReplyTimerText = Table.create()
        set ReplyTimerSound = Table.create()
        set AiCampFireCleanupUnit = Table.create()
        set TempAbilityUnit = Table.create()
        set TempAbilityRemove = Table.create()
        set TempAbilityRestore = Table.create()
    endif
    if TempGroup == null then
        set TempGroup = CreateGroup()
    endif
    if TempRect == null then
        set TempRect = Rect(0.00, 0.00, 0.00, 0.00)
    endif
    if ClockTimer == null then
        set ClockTimer = CreateTimer()
        call TimerStart(ClockTimer, 1000000.00, false, null)
    endif
endfunction

private function GetNow takes nothing returns real
    call EnsureState()
    return TimerGetElapsed(ClockTimer)
endfunction

private function IsAliveUnit takes unit whichUnit returns boolean
    return FallenHeroState_IsAlive(whichUnit)
endfunction

private function IsCompanionControlled takes unit whichUnit returns boolean
    if whichUnit == null then
        return false
    endif
    return udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group)
endfunction

private function GetLifePercent takes unit whichUnit returns real
    local real maxLife
    if whichUnit == null then
        return 0.00
    endif
    set maxLife = GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE)
    if maxLife <= 0.00 then
        return 0.00
    endif
    return GetWidgetLife(whichUnit) * 100.00 / maxLife
endfunction

private function GetManaPercent takes unit whichUnit returns real
    local real maxMana
    if whichUnit == null then
        return 0.00
    endif
    set maxMana = GetUnitState(whichUnit, UNIT_STATE_MAX_MANA)
    if maxMana <= 0.00 then
        return 100.00
    endif
    return GetUnitState(whichUnit, UNIT_STATE_MANA) * 100.00 / maxMana
endfunction

private function GetPointKey takes integer profileId, integer index returns integer
    return profileId * 100 + index
endfunction

private function IsPointInProfileAllowedZone takes integer profileId, real x, real y returns boolean
    local integer count = ProfileAllowedZoneCount[profileId]
    local integer index = 1
    local integer key
    if count <= 0 then
        return true
    endif
    loop
        exitwhen index > count
        set key = GetPointKey(profileId, index)
        if x >= ProfileAllowedZoneMinX.real[key] and x <= ProfileAllowedZoneMaxX.real[key] and y >= ProfileAllowedZoneMinY.real[key] and y <= ProfileAllowedZoneMaxY.real[key] then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function IsProfileZoneRestricted takes integer instanceId returns boolean
    if instanceId <= 0 or InstanceInviteUnlocked.boolean[instanceId] then
        return false
    endif
    return ProfileAllowedZoneCount[InstanceProfile[instanceId]] > 0
endfunction

private function PickProfileAllowedZonePoint takes integer profileId returns boolean
    local integer count = ProfileAllowedZoneCount[profileId]
    local integer index
    local integer key
    if count <= 0 then
        return false
    endif
    set index = GetRandomInt(1, count)
    set key = GetPointKey(profileId, index)
    set RandomPointX = GetRandomReal(ProfileAllowedZoneMinX.real[key], ProfileAllowedZoneMaxX.real[key])
    set RandomPointY = GetRandomReal(ProfileAllowedZoneMinY.real[key], ProfileAllowedZoneMaxY.real[key])
    return true
endfunction

private function GetBarkKey takes integer profileId, integer barkType returns integer
    return profileId * 100 + barkType
endfunction

private function GetBarkLineKey takes integer barkKey, integer index returns integer
    return barkKey * 100 + index
endfunction

private function GetInstanceBarkKey takes integer instanceId, integer barkType returns integer
    return instanceId * 100 + barkType
endfunction

private function GetReplyIndexKey takes integer replyKey, integer index returns integer
    return StringHash(I2S(replyKey) + ":" + I2S(index))
endfunction

private function ClearInstanceBarkCooldowns takes integer instanceId returns nothing
    local integer barkType = 1
    loop
        exitwhen barkType > AI_BARK_FAREWELL
        call InstanceNextBark.remove(GetInstanceBarkKey(instanceId, barkType))
        set barkType = barkType + 1
    endloop
endfunction

private function IsPlayerOwnedHeroListener takes unit hero returns boolean
    return hero != null and GetOwningPlayer(hero) == Player(0) and IsAliveUnit(hero)
endfunction

private function IsBarkNearPlayerHero takes unit speaker returns boolean
    if speaker == null then
        return false
    endif
    if IsPlayerOwnedHeroListener(udg_Nazgrek) and IsUnitInRange(speaker, udg_Nazgrek, AI_BARK_AUDIBLE_RANGE) then
        return true
    endif
    if IsPlayerOwnedHeroListener(udg_Zulkis) and IsUnitInRange(speaker, udg_Zulkis, AI_BARK_AUDIBLE_RANGE) then
        return true
    endif
    return false
endfunction

private function IsCompanionOnlyBark takes integer barkType returns boolean
    if barkType == AI_BARK_GREET or barkType == AI_BARK_PASSIVE or barkType == AI_BARK_NORMAL then
        return true
    endif
    if barkType == AI_BARK_AGGRESSIVE or barkType == AI_BARK_HOLD or barkType == AI_BARK_DROP_ITEMS then
        return true
    endif
    if barkType == AI_BARK_KICKED or barkType == AI_BARK_ITEM_GIVEN or barkType == AI_BARK_COMPANION_DIES then
        return true
    endif
    return barkType == AI_BARK_FAREWELL
endfunction

private function IsDialogBlockingBark takes nothing returns boolean
    return udg_InCinematic or DialogSystem_IsSequenceActive() or DialogSystem_IsDialogVisible() or DialogSystem_IsFieldLineQueueActive()
endfunction

private function IsBarkContextAllowed takes unit speaker, integer barkType returns boolean
    if IsDialogBlockingBark() then
        return false
    endif
    if not IsBarkNearPlayerHero(speaker) then
        return false
    endif
    if IsCompanionOnlyBark(barkType) and not IsCompanionControlled(speaker) then
        return false
    endif
    return true
endfunction

private function GetBarkCooldown takes integer barkType returns real
    if barkType == AI_BARK_IDLE or barkType == AI_BARK_MOVING then
        return GetRandomReal(60.00, 120.00)
    elseif barkType == AI_BARK_ATTACKING or barkType == AI_BARK_CASTING then
        return GetRandomReal(22.00, 40.00)
    elseif barkType == AI_BARK_KILLING then
        return GetRandomReal(18.00, 36.00)
    elseif barkType == AI_BARK_COMPANION_DIES then
        return GetRandomReal(25.00, 60.00)
    elseif IsCompanionOnlyBark(barkType) then
        return GetRandomReal(3.00, 8.00)
    endif
    return GetRandomReal(10.00, 20.00)
endfunction

private function IsCapAvailable takes integer cap, integer active returns boolean
    if cap <= 0 then
        return true
    endif
    return active < cap
endfunction

private function ClearEventContext takes nothing returns nothing
    set AI_EventInstance = 0
    set AI_EventUnit = null
    set AI_EventProfileId = 0
    set AI_EventClassId = 0
    set AI_EventState = AI_STATE_INACTIVE
    set AI_EventBarkType = 0
    set AI_EventTarget = null
    set AI_EventAbilityId = 0
endfunction

private function SetEventContext takes integer instanceId, unit whichUnit, integer barkType returns nothing
    set AI_EventInstance = instanceId
    set AI_EventUnit = whichUnit
    set AI_EventProfileId = InstanceProfile[instanceId]
    set AI_EventClassId = InstanceClass[instanceId]
    set AI_EventState = InstanceState[instanceId]
    set AI_EventBarkType = barkType
endfunction

private function RunProfileTrigger takes Table triggerTable, integer instanceId, unit whichUnit returns nothing
    local trigger profileTrigger
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set profileTrigger = triggerTable.trigger[profileId]
    if profileTrigger != null then
        call SetEventContext(instanceId, whichUnit, AI_EventBarkType)
        call TriggerExecute(profileTrigger)
        call ClearEventContext()
    endif
    set profileTrigger = null
endfunction

private function GetStateName takes integer state returns string
    if state == AI_STATE_IDLE then
        return "idle"
    elseif state == AI_STATE_WANDER then
        return "wander"
    elseif state == AI_STATE_COMBAT then
        return "combat"
    elseif state == AI_STATE_RETREAT_COMBAT then
        return "retreat-combat"
    elseif state == AI_STATE_RETREAT_BASE then
        return "retreat-base"
    elseif state == AI_STATE_BUY then
        return "buy"
    elseif state == AI_STATE_SELL then
        return "sell"
    elseif state == AI_STATE_CAMP then
        return "camp"
    elseif state == AI_STATE_TRAVEL then
        return "travel"
    elseif state == AI_STATE_DEAD then
        return "dead"
    elseif state == AI_STATE_COMPANION_CONTROLLED then
        return "companion"
    elseif state == AI_STATE_BOSS_EVADE then
        return "boss-evade"
    elseif state == AI_STATE_SOCIAL then
        return "social"
    endif
    return "inactive"
endfunction

private function SetInstanceState takes integer instanceId, integer newState returns nothing
    local integer oldState
    local integer classId
    local unit whichUnit
    local string unitName
    local string classLabel
    if instanceId <= 0 then
        return
    endif
    if InstanceState[instanceId] != newState then
        set oldState = InstanceState[instanceId]
        set InstancePreviousState[instanceId] = InstanceState[instanceId]
        set InstanceState[instanceId] = newState
        if DebugMode then
            set unitName = "unknown"
            set classLabel = "unregistered"
            set whichUnit = InstanceUnit.unit[instanceId]
            if whichUnit != null then
                if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
                    set unitName = GetHeroProperName(whichUnit)
                else
                    set unitName = GetUnitName(whichUnit)
                endif
            endif
            set classId = InstanceClass[instanceId]
            if classId > 0 and ClassName.string[classId] != "" then
                set classLabel = ClassName.string[classId]
            endif
            call DebugMsg(unitName + " [" + classLabel + "] state " + GetStateName(oldState) + " -> " + GetStateName(newState) + ".")
        endif
    endif
    set whichUnit = null
endfunction

private function AddActiveInstance takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    set ActiveCount = ActiveCount + 1
    set ActiveInstances[ActiveCount] = instanceId
    set InstanceActiveSlot[instanceId] = ActiveCount
endfunction

private function RemoveActiveInstance takes integer instanceId returns nothing
    local integer slot
    local integer moved
    if instanceId <= 0 then
        return
    endif
    set slot = InstanceActiveSlot[instanceId]
    if slot <= 0 or slot > ActiveCount then
        return
    endif
    set moved = ActiveInstances[ActiveCount]
    set ActiveInstances[slot] = moved
    set InstanceActiveSlot[moved] = slot
    set ActiveInstances[ActiveCount] = 0
    set ActiveCount = ActiveCount - 1
    call InstanceActiveSlot.remove(instanceId)
endfunction

private function IncrementCounts takes integer classId, integer profileId, integer unitTypeId returns nothing
    set ClassActiveCount[classId] = ClassActiveCount[classId] + 1
    set ProfileActiveCount[profileId] = ProfileActiveCount[profileId] + 1
    set UnitTypeActiveCount[unitTypeId] = UnitTypeActiveCount[unitTypeId] + 1
endfunction

private function DecrementCounts takes integer classId, integer profileId, integer unitTypeId returns nothing
    if ClassActiveCount[classId] > 0 then
        set ClassActiveCount[classId] = ClassActiveCount[classId] - 1
    endif
    if ProfileActiveCount[profileId] > 0 then
        set ProfileActiveCount[profileId] = ProfileActiveCount[profileId] - 1
    endif
    if UnitTypeActiveCount[unitTypeId] > 0 then
        set UnitTypeActiveCount[unitTypeId] = UnitTypeActiveCount[unitTypeId] - 1
    endif
endfunction

private function CanRegister takes integer profileId, integer uniqueId returns boolean
    local integer classId
    local integer unitTypeId
    if profileId <= 0 then
        return false
    endif
    set classId = ProfileClass[profileId]
    set unitTypeId = ProfileUnitType[profileId]
    if classId <= 0 or unitTypeId == 0 then
        return false
    endif
    if not IsCapAvailable(ClassCap[classId], ClassActiveCount[classId]) then
        return false
    endif
    if not IsCapAvailable(ProfileCap[profileId], ProfileActiveCount[profileId]) then
        return false
    endif
    if not IsCapAvailable(UnitTypeCap[unitTypeId], UnitTypeActiveCount[unitTypeId]) then
        return false
    endif
    if uniqueId != 0 and UniqueInstance[uniqueId] != 0 then
        return false
    endif
    return true
endfunction

private function GetGraveyardRect takes integer graveyardId returns rect
    if graveyardId == 2 then
        return gg_rct_Graveyard02
    elseif graveyardId == 3 then
        return gg_rct_Graveyard03
    elseif graveyardId == 4 then
        return gg_rct_Graveyard04
    elseif graveyardId == 5 then
        return gg_rct_Graveyard05
    elseif graveyardId == 6 then
        return gg_rct_Graveyard06
    elseif graveyardId == 7 then
        return gg_rct_Graveyard07
    elseif graveyardId == 8 then
        return gg_rct_Graveyard08
    elseif graveyardId == 9 then
        return gg_rct_Graveyard09
    endif
    return gg_rct_Graveyard
endfunction

private function GetReviveGraveyardId takes unit whichUnit returns integer
    local boolean companionControlled
    if whichUnit != null then
        set companionControlled = IsCompanionControlled(whichUnit)
        if companionControlled and udg_GraveyardSelect > 0 then
            return udg_GraveyardSelect
        endif
        if not companionControlled and GetUnitTypeId(whichUnit) == UNIT_AVELINE_RIVERBANE then
            return AI_RIVERBANE_GRAVEYARD_ID
        endif
    endif
    return GetRandomInt(1, 9)
endfunction

private function GetDisplayName takes unit whichUnit returns string
    if whichUnit == null then
        return ""
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

private function GetDebugInstanceName takes integer instanceId, unit whichUnit returns string
    local integer classId
    local string classLabel = "unregistered"
    if whichUnit == null then
        return "unknown"
    endif
    if instanceId > 0 then
        set classId = InstanceClass[instanceId]
        if classId > 0 and ClassName.string[classId] != "" then
            set classLabel = ClassName.string[classId]
        endif
    endif
    return GetDisplayName(whichUnit) + " [" + classLabel + "]"
endfunction

private function GetDebugUnitName takes unit whichUnit returns string
    if whichUnit == null then
        return "unknown"
    endif
    return GetDebugInstanceName(UnitInstance[GetHandleId(whichUnit)], whichUnit)
endfunction

private function EstimateDialogDuration takes string text returns real
    local real duration = I2R(StringLength(text)) / 13.00
    if duration < 1.25 then
        set duration = 1.25
    endif
    return duration
endfunction

private function UnlockDialog takes nothing returns nothing
    set udg_CompanionDialogueActive = false
endfunction

private function RestoreTemporaryAbility takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit whichUnit = TempAbilityUnit.unit[timerId]
    local integer removeAbilityId = TempAbilityRemove[timerId]
    local integer restoreAbilityId = TempAbilityRestore[timerId]
    if whichUnit != null then
        if removeAbilityId != 0 then
            call UnitRemoveAbility(whichUnit, removeAbilityId)
        endif
        if restoreAbilityId != 0 and GetUnitAbilityLevel(whichUnit, restoreAbilityId) <= 0 then
            call UnitAddAbility(whichUnit, restoreAbilityId)
        endif
    endif
    call TempAbilityUnit.unit.remove(timerId)
    call TempAbilityRemove.remove(timerId)
    call TempAbilityRestore.remove(timerId)
    call DestroyTimer(expired)
    set whichUnit = null
    set expired = null
endfunction

private function ClosestEnemyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    local real dx
    local real dy
    local real distance
    local real score
    local real lifePercent
    if SearchSource != null and IsAliveUnit(enumUnit) and IsUnitEnemy(enumUnit, GetOwningPlayer(SearchSource)) and not IsUnitHidden(enumUnit) and not GN_IsGatherUnit(enumUnit) then
        set dx = GetUnitX(enumUnit) - GetUnitX(SearchSource)
        set dy = GetUnitY(enumUnit) - GetUnitY(SearchSource)
        set distance = dx * dx + dy * dy
        if distance <= SearchRangeDistance then
            set lifePercent = GetLifePercent(enumUnit)
            set score = GetRandomReal(0.00, 25.00) + (100.00 - lifePercent) * 1.50
            set score = score + (SearchRangeDistance - distance) * 80.00 / SearchRangeDistance
            if distance <= 250.00 * 250.00 then
                set score = score + 120.00
            elseif distance <= 500.00 * 500.00 then
                set score = score + 55.00
            endif
            if IsUnitType(enumUnit, UNIT_TYPE_HERO) then
                set score = score + 80.00
            endif
            if IsUnitType(enumUnit, UNIT_TYPE_STRUCTURE) then
                set score = score - 300.00
            endif
            if SearchBestUnit == null or score > SearchBestScore or (score == SearchBestScore and distance < SearchBestDistance) then
                set SearchBestUnit = enumUnit
                set SearchBestDistance = distance
                set SearchBestScore = score
            endif
        endif
    endif
    set enumUnit = null
endfunction

private function LowestHealthAllyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    local real lifePercent
    if AllySearchSource != null and IsAliveUnit(enumUnit) and IsUnitAlly(enumUnit, GetOwningPlayer(AllySearchSource)) then
        if AllySearchIncludeSelf or enumUnit != AllySearchSource then
            set lifePercent = GetLifePercent(enumUnit)
            if AllySearchBestUnit == null or lifePercent < AllySearchBestLife then
                set AllySearchBestUnit = enumUnit
                set AllySearchBestLife = lifePercent
            endif
        endif
    endif
    set enumUnit = null
endfunction

private function CountEnemyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    if CountSource != null and IsAliveUnit(enumUnit) and IsUnitEnemy(enumUnit, GetOwningPlayer(CountSource)) then
        set CountResult = CountResult + 1
    endif
    set enumUnit = null
endfunction

private function CombatEnemyEnum takes nothing returns nothing
    local unit enumUnit = GetEnumUnit()
    if CombatSearchSource != null and not CombatSearchFound and IsAliveUnit(enumUnit) and IsUnitEnemy(enumUnit, GetOwningPlayer(CombatSearchSource)) and not GN_IsGatherUnit(enumUnit) then
        set CombatSearchFound = true
    endif
    set enumUnit = null
endfunction

private function MoveAwayFromPoint takes unit whichUnit, real originX, real originY, real distance returns nothing
    local real dx
    local real dy
    local real angle
    local real x
    local real y
    if whichUnit == null then
        return
    endif
    set dx = GetUnitX(whichUnit) - originX
    set dy = GetUnitY(whichUnit) - originY
    if dx == 0.00 and dy == 0.00 then
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    else
        set angle = Atan2(dy, dx)
    endif
    set x = GetUnitX(whichUnit) + distance * Cos(angle)
    set y = GetUnitY(whichUnit) + distance * Sin(angle)
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function BeginWander takes integer instanceId, unit whichUnit returns nothing
    local real x
    local real y
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    if IsProfileZoneRestricted(instanceId) and PickProfileAllowedZonePoint(profileId) then
        set x = RandomPointX
        set y = RandomPointY
    else
        set x = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
        set y = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))
    endif
    call SetInstanceState(instanceId, AI_STATE_WANDER)
    call IssuePointOrder(whichUnit, "attack", x, y)
endfunction

private function BeginCombatRetreat takes integer instanceId, unit whichUnit returns nothing
    local real angle
    local real distance
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    set distance = GetRandomReal(400.00, 1000.00)
    set x = GetUnitX(whichUnit) + distance * Cos(angle)
    set y = GetUnitY(whichUnit) + distance * Sin(angle)
    if IsProfileZoneRestricted(instanceId) and not IsPointInProfileAllowedZone(InstanceProfile[instanceId], x, y) and PickProfileAllowedZonePoint(InstanceProfile[instanceId]) then
        set x = RandomPointX
        set y = RandomPointY
    endif
    call SetInstanceState(instanceId, AI_STATE_RETREAT_COMBAT)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_RETREAT_COMBAT_TIME
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function BeginBaseRetreat takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index
    local integer key
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileRetreatCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set x = ProfileRetreatX.real[key]
        set y = ProfileRetreatY.real[key]
    else
        set x = InstanceHomeX.real[instanceId]
        set y = InstanceHomeY.real[instanceId]
    endif
    if IsProfileZoneRestricted(instanceId) and not IsPointInProfileAllowedZone(profileId, x, y) and PickProfileAllowedZonePoint(profileId) then
        set x = RandomPointX
        set y = RandomPointY
    endif
    call SetInstanceState(instanceId, AI_STATE_RETREAT_BASE)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_RETREAT_BASE_TIME
    call IssuePointOrder(whichUnit, "move", x, y)
endfunction

private function TryReturnToProfileAllowedZone takes integer instanceId, unit whichUnit returns boolean
    local integer profileId
    if instanceId <= 0 or whichUnit == null or not IsProfileZoneRestricted(instanceId) then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    if IsPointInProfileAllowedZone(profileId, GetUnitX(whichUnit), GetUnitY(whichUnit)) then
        return false
    endif
    if PickProfileAllowedZonePoint(profileId) then
        call SetInstanceState(instanceId, AI_STATE_WANDER)
        call IssuePointOrder(whichUnit, "attack", RandomPointX, RandomPointY)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " returns to its allowed initial zones.")
        return true
    endif
    return false
endfunction

private function IsNearActionPoint takes integer instanceId, unit whichUnit, real range returns boolean
    local real dx
    local real dy
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set dx = GetUnitX(whichUnit) - InstanceActionX.real[instanceId]
    set dy = GetUnitY(whichUnit) - InstanceActionY.real[instanceId]
    return dx * dx + dy * dy <= range * range
endfunction

private function FinishBuyState takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index
    local integer key
    local item boughtItem
    local unit shopUnit
    if instanceId <= 0 or whichUnit == null then
        return
    endif

    static if LIBRARY_Shop then
        set shopUnit = InstanceActionShopUnit.unit[instanceId]
        if shopUnit != null and Shop_GetVendorIdForUnit(shopUnit) > 0 then
            if Shop_AIBuySimple(whichUnit, shopUnit) then
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " buys from a PotS shop.")
            endif
            set boughtItem = null
            set shopUnit = null
            call SetInstanceState(instanceId, AI_STATE_IDLE)
            return
        endif
    endif

    set profileId = InstanceProfile[instanceId]
    set count = ProfileShopItemCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set boughtItem = CreateItem(ProfileShopItemType[key], GetUnitX(whichUnit), GetUnitY(whichUnit))
        if boughtItem != null then
            call UnitAddItem(whichUnit, boughtItem)
        endif
    endif
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    set boughtItem = null
    set shopUnit = null
endfunction

private function SelectProfileShop takes integer instanceId, unit whichUnit returns boolean
    local integer profileId
    local integer count
    local integer index
    local integer checked = 0
    local integer key
    local unit shopUnit
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileShopCount[profileId]
    if count <= 0 then
        return false
    endif
    set index = GetRandomInt(1, count)
    loop
        exitwhen checked >= count
        set key = GetPointKey(profileId, index)
        set shopUnit = ProfileShopUnit.unit[key]
        if shopUnit == null or IsAliveUnit(shopUnit) then
            if shopUnit != null then
                set InstanceActionX.real[instanceId] = GetUnitX(shopUnit)
                set InstanceActionY.real[instanceId] = GetUnitY(shopUnit)
            else
                set InstanceActionX.real[instanceId] = ProfileShopX.real[key]
                set InstanceActionY.real[instanceId] = ProfileShopY.real[key]
            endif
            set InstanceActionShopUnit.unit[instanceId] = shopUnit
            set shopUnit = null
            return true
        endif
        set index = index + 1
        if index > count then
            set index = 1
        endif
        set checked = checked + 1
    endloop
    call InstanceActionShopUnit.unit.remove(instanceId)
    set shopUnit = null
    return false
endfunction

private function SellInventoryItem takes integer instanceId, unit whichUnit returns boolean
    local integer slot = GetRandomInt(0, bj_MAX_INVENTORY - 1)
    local integer checked = 0
    local item slotItem
    local unit shopUnit
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set shopUnit = InstanceActionShopUnit.unit[instanceId]
    static if LIBRARY_Shop then
        if shopUnit != null and IsAliveUnit(shopUnit) and Shop_GetVendorIdForUnit(shopUnit) > 0 then
            if Shop_AISellSimple(whichUnit, shopUnit) then
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " sells an item to a PotS shop.")
                set slotItem = null
                set shopUnit = null
                return true
            endif
            set slotItem = null
            set shopUnit = null
            return false
        endif
    endif
    loop
        exitwhen checked >= bj_MAX_INVENTORY
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null then
            if shopUnit != null and IsAliveUnit(shopUnit) and UnitDropItemTarget(whichUnit, slotItem, shopUnit) then
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " sells an item to a shop.")
                set slotItem = null
                set shopUnit = null
                return true
            endif
            call UnitDropItemPoint(whichUnit, slotItem, GetUnitX(whichUnit), GetUnitY(whichUnit))
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " drops an item because no live shop target is available.")
            set slotItem = null
            set shopUnit = null
            return true
        endif
        set slot = slot + 1
        if slot >= bj_MAX_INVENTORY then
            set slot = 0
        endif
        set checked = checked + 1
    endloop
    set slotItem = null
    set shopUnit = null
    return false
endfunction

private function IsManaOnlyItemType takes integer itemTypeId returns boolean
    return itemTypeId == ITEM_MINOR_MANA_POTION or itemTypeId == ITEM_MANA_POTION or itemTypeId == ITEM_MAJOR_MANA_POTION or itemTypeId == ITEM_SPRING_WATER
endfunction

private function IsHealingConsumableItemType takes integer itemTypeId returns boolean
    return itemTypeId == ITEM_MINOR_HEALING_POTION or itemTypeId == ITEM_HEALING_POTION or itemTypeId == ITEM_MAJOR_HEALING_POTION or itemTypeId == ITEM_HEALING_SALVE or itemTypeId == ITEM_GREATER_HEALING_SALVE
endfunction

private function IsAIUtilityItemType takes integer itemTypeId returns boolean
    return itemTypeId == ITEM_MINING_PICK or itemTypeId == ITEM_SKINNING_KNIFE or itemTypeId == ITEM_CAMP_FIRE
endfunction

private function IsRandomManagedVisible takes integer instanceId returns boolean
    local unit whichUnit
    local boolean result = false
    if instanceId <= 0 or not InstanceRandomManaged.boolean[instanceId] or InstanceHiddenByCap.boolean[instanceId] or InstanceTraveling.boolean[instanceId] then
        return false
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    set result = whichUnit != null and IsAliveUnit(whichUnit) and not IsUnitHidden(whichUnit) and not IsCompanionControlled(whichUnit)
    set whichUnit = null
    return result
endfunction

private function CountRandomManagedVisible takes nothing returns integer
    local integer index = 1
    local integer count = 0
    loop
        exitwhen index > ActiveCount
        if IsRandomManagedVisible(ActiveInstances[index]) then
            set count = count + 1
        endif
        set index = index + 1
    endloop
    return count
endfunction

private function CanShowRandomManaged takes integer instanceId returns boolean
    local integer visible
    local unit whichUnit
    if instanceId <= 0 or not InstanceRandomManaged.boolean[instanceId] then
        return true
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    if IsCompanionControlled(whichUnit) then
        set whichUnit = null
        return true
    endif
    set whichUnit = null
    if RandomSpawnActiveCap <= 0 then
        return true
    endif
    set visible = CountRandomManagedVisible()
    if IsRandomManagedVisible(instanceId) then
        return visible <= RandomSpawnActiveCap
    endif
    return visible < RandomSpawnActiveCap
endfunction

private function HideRandomManagedByCap takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null or not InstanceRandomManaged.boolean[instanceId] or IsCompanionControlled(whichUnit) then
        return
    endif
    set InstanceHiddenByCap.boolean[instanceId] = true
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call IssueImmediateOrder(whichUnit, "stop")
    call PauseUnit(whichUnit, true)
    call ShowUnit(whichUnit, false)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " hidden by random active cap.")
endfunction

private function ShowRandomManagedFromCap takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null or not InstanceRandomManaged.boolean[instanceId] then
        return
    endif
    set InstanceHiddenByCap.boolean[instanceId] = false
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call ShowUnit(whichUnit, true)
    call PauseUnit(whichUnit, false)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " shown from random active cap reserve.")
endfunction

private function BeginBuyState takes integer instanceId, unit whichUnit returns boolean
    if instanceId <= 0 or whichUnit == null or IsCompanionControlled(whichUnit) then
        return false
    endif
    if not SelectProfileShop(instanceId, whichUnit) then
        return false
    endif
    call SetInstanceState(instanceId, AI_STATE_BUY)
    call IssuePointOrder(whichUnit, "move", InstanceActionX.real[instanceId], InstanceActionY.real[instanceId])
    return true
endfunction

private function BeginSellState takes integer instanceId, unit whichUnit returns boolean
    local integer profileId
    if instanceId <= 0 or whichUnit == null or IsCompanionControlled(whichUnit) then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    if SelectProfileShop(instanceId, whichUnit) then
        call SetInstanceState(instanceId, AI_STATE_SELL)
        call IssuePointOrder(whichUnit, "move", InstanceActionX.real[instanceId], InstanceActionY.real[instanceId])
        return true
    endif
    if ProfileShopCount[profileId] > 0 then
        return false
    endif
    set InstanceActionX.real[instanceId] = GetUnitX(whichUnit)
    set InstanceActionY.real[instanceId] = GetUnitY(whichUnit)
    call InstanceActionShopUnit.unit.remove(instanceId)
    call SetInstanceState(instanceId, AI_STATE_SELL)
    return true
endfunction

private function BeginCampState takes integer instanceId, unit whichUnit, real duration returns boolean
    if instanceId <= 0 or whichUnit == null or duration <= 0.00 or IsCompanionControlled(whichUnit) then
        return false
    endif
    call SetInstanceState(instanceId, AI_STATE_CAMP)
    set InstanceRetreatUntil.real[instanceId] = GetNow() + duration
    call IssueImmediateOrder(whichUnit, "stop")
    return true
endfunction

private function ApplyStartingAbilities takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer count
    local integer index = 1
    local integer abilityId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set count = ProfileStartingAbilityCount[profileId]
    loop
        exitwhen index > count
        set abilityId = ProfileStartingAbilityId[GetPointKey(profileId, index)]
        if abilityId != 0 and GetUnitAbilityLevel(whichUnit, abilityId) <= 0 then
            call UnitAddAbility(whichUnit, abilityId)
        endif
        set index = index + 1
    endloop
endfunction

private function LearnRandomProfileAbility takes unit whichUnit, integer profileId returns nothing
    local integer count
    local integer abilityId
    if whichUnit == null or profileId <= 0 then
        return
    endif
    set count = ProfileAbilityCount[profileId]
    if count <= 0 then
        return
    endif
    set abilityId = ProfileAbilityId[GetPointKey(profileId, GetRandomInt(1, count))]
    if abilityId == 0 then
        return
    endif
    if GetUnitAbilityLevel(whichUnit, abilityId) <= 0 then
        call UnitAddAbility(whichUnit, abilityId)
    else
        call IncUnitAbilityLevel(whichUnit, abilityId)
    endif
endfunction

private function GetProfileProfessionKey takes integer profileId, integer professionId returns integer
    return profileId * 10 + professionId
endfunction

private function HasProfileProfession takes integer profileId, integer professionId returns boolean
    if profileId <= 0 or professionId <= AI_PROFESSION_NONE then
        return false
    endif
    return ProfileProfession.boolean[GetProfileProfessionKey(profileId, professionId)]
endfunction

private function GetFreeInventorySlots takes unit whichUnit returns integer
    local integer slot = 0
    local integer size
    local integer free = 0
    local item slotItem
    if whichUnit == null then
        return 0
    endif
    set size = UnitInventorySize(whichUnit)
    loop
        exitwhen slot >= size
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem == null then
            set free = free + 1
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return free
endfunction

private function IsInventoryEmpty takes unit whichUnit returns boolean
    if whichUnit == null or UnitInventorySize(whichUnit) <= 0 then
        return false
    endif
    return GetFreeInventorySlots(whichUnit) == UnitInventorySize(whichUnit)
endfunction

private function IsInventoryFull takes unit whichUnit returns boolean
    if whichUnit == null or UnitInventorySize(whichUnit) <= 0 then
        return false
    endif
    return GetFreeInventorySlots(whichUnit) <= 0
endfunction

private function IsNeededConsumableItemType takes integer itemTypeId, boolean needsLife, boolean needsMana returns boolean
    if needsLife and IsHealingConsumableItemType(itemTypeId) then
        return true
    endif
    if needsMana and IsManaOnlyItemType(itemTypeId) then
        return true
    endif
    return false
endfunction

private function FindVanillaItemByType takes unit whichUnit, integer itemTypeId returns item
    local integer slot = 0
    local item slotItem
    if whichUnit == null or itemTypeId == 0 then
        return null
    endif
    loop
        exitwhen slot >= bj_MAX_INVENTORY
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null and GetItemTypeId(slotItem) == itemTypeId then
            return slotItem
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return null
endfunction

private function TryStashUnneededVanillaItem takes unit whichUnit, boolean needsLife, boolean needsMana returns boolean
    local integer slot = 0
    local item slotItem
    local integer itemTypeId
    if whichUnit == null or BIDOfUnit(whichUnit) < 1 then
        return false
    endif
    loop
        exitwhen slot >= bj_MAX_INVENTORY
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null then
            set itemTypeId = GetItemTypeId(slotItem)
            if not IsAIUtilityItemType(itemTypeId) and not IsNeededConsumableItemType(itemTypeId, needsLife, needsMana) then
                if DInvMoveVanillaItemToDInventory(whichUnit, slotItem) then
                    set slotItem = null
                    return true
                endif
            endif
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return false
endfunction

private function StageDInvConsumableType takes unit whichUnit, integer itemTypeId, boolean needsLife, boolean needsMana returns item
    local item slotItem
    if whichUnit == null or itemTypeId == 0 then
        return null
    endif
    set slotItem = FindVanillaItemByType(whichUnit, itemTypeId)
    if slotItem != null then
        return slotItem
    endif
    if IsInventoryFull(whichUnit) and not TryStashUnneededVanillaItem(whichUnit, needsLife, needsMana) then
        set slotItem = null
        return null
    endif
    if DInvMoveStoredItemTypeToVanillaInventory(whichUnit, itemTypeId) then
        set slotItem = FindVanillaItemByType(whichUnit, itemTypeId)
        return slotItem
    endif
    set slotItem = null
    return null
endfunction

private function StageDInvHealingConsumable takes unit whichUnit, boolean urgent returns item
    local item slotItem
    if urgent then
        set slotItem = StageDInvConsumableType(whichUnit, ITEM_MAJOR_HEALING_POTION, true, false)
        if slotItem != null then
            return slotItem
        endif
        set slotItem = StageDInvConsumableType(whichUnit, ITEM_GREATER_HEALING_SALVE, true, false)
        if slotItem != null then
            return slotItem
        endif
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_HEALING_POTION, true, false)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_MINOR_HEALING_POTION, true, false)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_HEALING_SALVE, true, false)
    if slotItem != null then
        return slotItem
    endif
    if not urgent then
        set slotItem = StageDInvConsumableType(whichUnit, ITEM_GREATER_HEALING_SALVE, true, false)
        if slotItem != null then
            return slotItem
        endif
        set slotItem = StageDInvConsumableType(whichUnit, ITEM_MAJOR_HEALING_POTION, true, false)
        if slotItem != null then
            return slotItem
        endif
    endif
    set slotItem = null
    return null
endfunction

private function StageDInvManaConsumable takes unit whichUnit returns item
    local item slotItem = StageDInvConsumableType(whichUnit, ITEM_MAJOR_MANA_POTION, false, true)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_MANA_POTION, false, true)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_MINOR_MANA_POTION, false, true)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = StageDInvConsumableType(whichUnit, ITEM_SPRING_WATER, false, true)
    if slotItem != null then
        return slotItem
    endif
    set slotItem = null
    return null
endfunction

private function StageDInvOtherConsumable takes unit whichUnit, boolean needsLife, boolean needsMana returns item
    local item stagedItem
    local integer itemTypeId

    if whichUnit == null then
        return null
    endif
    if IsInventoryFull(whichUnit) and not TryStashUnneededVanillaItem(whichUnit, needsLife, needsMana) then
        return null
    endif
    set stagedItem = DInvStageFirstStoredActiveItem(whichUnit, ITEM_SPIRIT_SHARD)
    if stagedItem == null then
        return null
    endif
    set itemTypeId = GetItemTypeId(stagedItem)
    if IsAIUtilityItemType(itemTypeId) then
        call DInvMoveVanillaItemToDInventory(whichUnit, stagedItem)
        set stagedItem = null
        return null
    endif
    return stagedItem
endfunction

private function UnitHasItemType takes unit whichUnit, integer itemTypeId returns boolean
    local integer slot = 0
    local integer size
    local item slotItem
    if whichUnit == null or itemTypeId == 0 then
        return false
    endif
    set size = UnitInventorySize(whichUnit)
    loop
        exitwhen slot >= size
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null and GetItemTypeId(slotItem) == itemTypeId then
            set slotItem = null
            return true
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return false
endfunction

private function GetProfessionToolId takes integer professionId returns integer
    if professionId == AI_PROFESSION_MINING then
        return ITEM_MINING_PICK
    elseif professionId == AI_PROFESSION_SKINNING then
        return ITEM_SKINNING_KNIFE
    endif
    return 0
endfunction

private function RemoveTrackedProfessionTool takes integer instanceId returns nothing
    local item tool
    if instanceId <= 0 then
        return
    endif
    set tool = InstanceProfessionToolItem[instanceId]
    if tool != null and GetItemTypeId(tool) != 0 then
        call RemoveItem(tool)
    endif
    set InstanceProfessionToolItem[instanceId] = null
    set InstanceProfessionToolType[instanceId] = 0
    set InstanceProfessionToolExpires[instanceId] = 0.00
    set InstanceProfessionTargetUnit[instanceId] = null
    set tool = null
endfunction

private function CleanupProfessionTool takes integer instanceId, real now returns nothing
    local unit target
    if instanceId <= 0 or InstanceProfessionToolItem[instanceId] == null then
        set target = null
        return
    endif

    set target = InstanceProfessionTargetUnit[instanceId]
    if target != null then
        if GetUnitTypeId(target) != 0 and GN_IsGatherUnit(target) and IsAliveUnit(target) then
            set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_CLEANUP_DELAY
            set target = null
            return
        endif
        set InstanceProfessionTargetUnit[instanceId] = null
        set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_CLEANUP_DELAY
    endif

    if now >= InstanceProfessionToolExpires[instanceId] then
        call RemoveTrackedProfessionTool(instanceId)
    endif
    set target = null
endfunction

private function EnsureProfessionTool takes integer instanceId, unit whichUnit, integer itemTypeId, real now returns boolean
    local item tool
    if itemTypeId == 0 then
        return true
    endif
    if whichUnit == null or UnitInventorySize(whichUnit) <= 0 then
        return false
    endif
    if UnitHasItemType(whichUnit, itemTypeId) then
        if InstanceProfessionToolItem[instanceId] != null and InstanceProfessionToolType[instanceId] == itemTypeId then
            set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_DURATION
        endif
        return true
    endif
    if GetFreeInventorySlots(whichUnit) <= 0 then
        return false
    endif
    set tool = UnitAddItemById(whichUnit, itemTypeId)
    if tool == null then
        set tool = null
        return false
    endif
    if not UnitHasItemType(whichUnit, itemTypeId) then
        call RemoveItem(tool)
        set tool = null
        return false
    endif
    call RemoveTrackedProfessionTool(instanceId)
    set InstanceProfessionToolItem[instanceId] = tool
    set InstanceProfessionToolType[instanceId] = itemTypeId
    set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_DURATION
    set tool = null
    return true
endfunction

private function SetTrackedProfessionToolCleanup takes integer instanceId, real now returns nothing
    if instanceId > 0 and InstanceProfessionToolItem[instanceId] != null then
        set InstanceProfessionTargetUnit[instanceId] = null
        set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_CLEANUP_DELAY
    endif
endfunction

private function SetTrackedProfessionToolTargetUnit takes integer instanceId, unit target, real now returns nothing
    if instanceId > 0 and InstanceProfessionToolItem[instanceId] != null then
        set InstanceProfessionTargetUnit[instanceId] = target
        set InstanceProfessionToolExpires[instanceId] = now + AI_PROFESSION_TOOL_CLEANUP_DELAY
    endif
endfunction

private function ClearDebugIcon takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    if InstanceDebugIcon[instanceId] != null then
        call IconQuery_UnregisterIcon(InstanceDebugIcon[instanceId])
        set InstanceDebugIcon[instanceId] = null
    endif
endfunction

private function EnsureDebugIcon takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return
    endif
    if InstanceDebugIcon[instanceId] == null then
        set InstanceDebugIcon[instanceId] = IconQuery_RegisterCompanionFollowerUnitIcon(whichUnit)
        call DebugMsg("Debug icon registered for " + GetDebugInstanceName(instanceId, whichUnit) + ".")
    endif
endfunction

private function RefreshDebugIcons takes nothing returns nothing
    local integer index = 1
    local integer instanceId
    local unit whichUnit
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        if DebugMode then
            call EnsureDebugIcon(instanceId, whichUnit)
        else
            call ClearDebugIcon(instanceId)
        endif
        set index = index + 1
    endloop
    set whichUnit = null
endfunction

private function RefreshInstanceProfessionSkills takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    if ProfileProfessionCount[profileId] <= 0 then
        return
    endif
    call GNS_RegisterTrackedGatherer(whichUnit)
endfunction

private function ClearInstanceProfessionState takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 then
        return
    endif
    call RemoveTrackedProfessionTool(instanceId)
    call InstanceNextProfession.remove(instanceId)
    call InstanceProfessionFailCount.remove(instanceId)
    call InstanceProfessionBlockedUntil.remove(instanceId)
    set InstanceProfessionTargetUnit[instanceId] = null
    if whichUnit != null then
        call GNS_UnregisterTrackedGatherer(whichUnit)
    endif
endfunction

private function CompleteRevive takes integer instanceId, unit whichUnit, real x, real y, boolean showEffects returns nothing
    local integer profileId = InstanceProfile[instanceId]

    if IsUnitType(whichUnit, UNIT_TYPE_HERO) and GetWidgetLife(whichUnit) <= 0.405 then
        call ReviveHero(whichUnit, x, y, showEffects)
    else
        call SetUnitPosition(whichUnit, x, y)
        call ShowUnit(whichUnit, true)
        if showEffects and IsUnitType(whichUnit, UNIT_TYPE_HERO) then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", whichUnit, "origin"))
        endif
    endif
    call PauseUnit(whichUnit, false)
    call SetUnitTimeScale(whichUnit, 1.00)
    call SetUnitPathing(whichUnit, true)
    call ResetUnitAnimation(whichUnit)
    call SetUnitAnimation(whichUnit, "stand")
    call SetWidgetLife(whichUnit, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.50)
    if not ProfileNoManaRestore.boolean[profileId] then
        call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA) * 0.50)
    else
        call SetUnitState(whichUnit, UNIT_STATE_MANA, 0.00)
    endif
    set InstanceAlive.boolean[instanceId] = true
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    if InstanceRandomManaged.boolean[instanceId] then
        if CanShowRandomManaged(instanceId) then
            call ShowRandomManagedFromCap(instanceId, whichUnit)
        else
            call HideRandomManagedByCap(instanceId, whichUnit)
        endif
    endif
    if IsCompanionControlled(whichUnit) and not udg_InCinematic then
        call PingMinimapEx(x, y, 1.00, 255, 0, 0, true)
        call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 5.00, "|cffffff00|r" + GetDisplayName(whichUnit) + " |cffffffffis |r|cff00ff00revived.|r")
    endif
    call RunProfileTrigger(ProfileReviveTrigger, instanceId, whichUnit)
    call RefreshInstanceProfessionSkills(instanceId, whichUnit)
endfunction

public function ReviveAt takes unit whichUnit, real x, real y, boolean showEffects returns boolean
    local integer instanceId
    local timer reviveTimer

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return false
    endif
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        return false
    endif

    set reviveTimer = InstanceReviveTimer.timer[instanceId]
    if reviveTimer != null then
        call ReviveTimerInstance.remove(GetHandleId(reviveTimer))
        call InstanceReviveTimer.timer.remove(instanceId)
        call PauseTimer(reviveTimer)
        call DestroyTimer(reviveTimer)
    endif
    call CompleteRevive(instanceId, whichUnit, x, y, showEffects)

    set reviveTimer = null
    return true
endfunction

private function ReviveExpired takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local integer instanceId = ReviveTimerInstance[timerId]
    local unit whichUnit = InstanceUnit.unit[instanceId]
    local rect graveyardRect
    local integer graveyardId
    local real x
    local real y
    if instanceId > 0 and whichUnit != null and GetUnitTypeId(whichUnit) != 0 then
        set graveyardId = GetReviveGraveyardId(whichUnit)
        set graveyardRect = GetGraveyardRect(graveyardId)
        set x = GetRectCenterX(graveyardRect)
        set y = GetRectCenterY(graveyardRect)
        call CompleteRevive(instanceId, whichUnit, x, y, true)
    endif
    call ReviveTimerInstance.remove(timerId)
    call InstanceReviveTimer.timer.remove(instanceId)
    call DestroyTimer(expired)
    set whichUnit = null
    set graveyardRect = null
    set expired = null
endfunction

private function StartReviveTimer takes integer instanceId, unit whichUnit returns nothing
    local timer reviveTimer
    local real reviveDelay
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set reviveDelay = ProfileReviveDelay.real[profileId]
    if reviveDelay <= 0.00 then
        set reviveDelay = AI_DEFAULT_REVIVE_DELAY
    endif
    set reviveTimer = CreateTimer()
    set InstanceReviveTimer.timer[instanceId] = reviveTimer
    set ReviveTimerInstance[GetHandleId(reviveTimer)] = instanceId
    call TimerStart(reviveTimer, reviveDelay, false, function ReviveExpired)
    set reviveTimer = null
endfunction

public function CancelReviveTimer takes unit whichUnit returns nothing
    local integer instanceId
    local timer reviveTimer

    if whichUnit == null then
        return
    endif
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        set whichUnit = null
        return
    endif
    set reviveTimer = InstanceReviveTimer.timer[instanceId]
    if reviveTimer != null then
        call ReviveTimerInstance.remove(GetHandleId(reviveTimer))
        call InstanceReviveTimer.timer.remove(instanceId)
        call PauseTimer(reviveTimer)
        call DestroyTimer(reviveTimer)
    endif
    set reviveTimer = null
    set whichUnit = null
endfunction

public function SetReviveRemaining takes unit whichUnit, real remaining returns nothing
    local integer instanceId
    local timer reviveTimer

    if whichUnit == null then
        return
    endif
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        set whichUnit = null
        return
    endif
    call AI_CancelReviveTimer(whichUnit)
    if remaining > 0.00 then
        set reviveTimer = CreateTimer()
        set InstanceReviveTimer.timer[instanceId] = reviveTimer
        set ReviveTimerInstance[GetHandleId(reviveTimer)] = instanceId
        call TimerStart(reviveTimer, remaining, false, function ReviveExpired)
    endif
    set reviveTimer = null
    set whichUnit = null
endfunction

private function CompleteTravel takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    call SetUnitPosition(whichUnit, InstanceTravelReturnX.real[instanceId], InstanceTravelReturnY.real[instanceId])
    set InstanceTraveling.boolean[instanceId] = false
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " returned from travel.")
    if CanShowRandomManaged(instanceId) then
        if InstanceRandomManaged.boolean[instanceId] then
            call ShowRandomManagedFromCap(instanceId, whichUnit)
        else
            call PauseUnit(whichUnit, false)
            call ShowUnit(whichUnit, true)
        endif
    else
        call HideRandomManagedByCap(instanceId, whichUnit)
    endif
endfunction

private function IsAiPartyMember takes integer instanceId returns boolean
    return instanceId > 0 and InstanceAiPartyLeader[instanceId] > 0
endfunction

private function RemoveInstanceFromAiParty takes integer instanceId returns nothing
    local integer leaderId
    local integer memberId
    local integer index = 1
    local integer count
    if instanceId <= 0 or InstanceAiPartyLeader == 0 then
        return
    endif
    set leaderId = InstanceAiPartyLeader[instanceId]
    if leaderId <= 0 then
        return
    endif
    if leaderId == instanceId then
        loop
            exitwhen index > ActiveCount
            set memberId = ActiveInstances[index]
            if InstanceAiPartyLeader[memberId] == instanceId then
                call InstanceAiPartyLeader.remove(memberId)
                if memberId != instanceId and InstanceState[memberId] == AI_STATE_SOCIAL then
                    call SetInstanceState(memberId, AI_STATE_IDLE)
                endif
            endif
            set index = index + 1
        endloop
        call InstanceAiPartyFollowerCount.remove(instanceId)
    else
        call InstanceAiPartyLeader.remove(instanceId)
        set count = InstanceAiPartyFollowerCount[leaderId]
        if count > 1 then
            set InstanceAiPartyFollowerCount[leaderId] = count - 1
        elseif count == 1 then
            call InstanceAiPartyFollowerCount.remove(leaderId)
            call InstanceAiPartyLeader.remove(leaderId)
        endif
    endif
endfunction

private function PickRandomManagedTravelReturnPoint takes integer instanceId returns nothing
    local integer profileId = InstanceProfile[instanceId]
    local integer count = ProfileSpawnCount[profileId]
    local integer index
    local integer key
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set RandomPointX = ProfileSpawnX.real[key]
        set RandomPointY = ProfileSpawnY.real[key]
    else
        set RandomPointX = InstanceHomeX.real[instanceId]
        set RandomPointY = InstanceHomeY.real[instanceId]
    endif
endfunction

private function StartRandomManagedCapTravel takes integer instanceId returns boolean
    local unit whichUnit
    if instanceId <= 0 or InstanceTraveling.boolean[instanceId] or InstanceHiddenByCap.boolean[instanceId] or not InstanceRandomManaged.boolean[instanceId] then
        return false
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    if whichUnit == null or not IsAliveUnit(whichUnit) or IsCompanionControlled(whichUnit) then
        set whichUnit = null
        return false
    endif
    call RemoveInstanceFromAiParty(instanceId)
    call PickRandomManagedTravelReturnPoint(instanceId)
    set InstanceTraveling.boolean[instanceId] = true
    set InstanceTravelReturnAt.real[instanceId] = GetNow() + GetRandomReal(AI_RANDOM_TRAVEL_DURATION_MIN, AI_RANDOM_TRAVEL_DURATION_MAX)
    set InstanceTravelReturnX.real[instanceId] = RandomPointX
    set InstanceTravelReturnY.real[instanceId] = RandomPointY
    call RemoveTrackedProfessionTool(instanceId)
    set InstanceSocialTarget[instanceId] = null
    set InstanceSocialStopped[instanceId] = false
    call InstanceSocialUntil.remove(instanceId)
    call SetInstanceState(instanceId, AI_STATE_TRAVEL)
    call IssueImmediateOrder(whichUnit, "stop")
    call PauseUnit(whichUnit, true)
    call ShowUnit(whichUnit, false)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " went traveling after the active AI cap was lowered.")
    set whichUnit = null
    return true
endfunction

private function EnforceRandomSpawnActiveCap takes nothing returns nothing
    local integer guard = 0
    local integer index
    local integer instanceId
    local integer selected
    local integer seen
    if RandomSpawnActiveCap <= 0 then
        return
    endif
    loop
        exitwhen CountRandomManagedVisible() <= RandomSpawnActiveCap or guard >= ActiveCount
        set index = 1
        set selected = 0
        set seen = 0
        loop
            exitwhen index > ActiveCount
            set instanceId = ActiveInstances[index]
            if IsRandomManagedVisible(instanceId) then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = instanceId
                endif
            endif
            set index = index + 1
        endloop
        if selected <= 0 or not StartRandomManagedCapTravel(selected) then
            return
        endif
        set guard = guard + 1
    endloop
endfunction

public function RegisterClass takes string className returns integer
    local integer key
    local integer classId
    call EnsureState()
    if className == "" then
        return 0
    endif
    set key = StringHash(className)
    set classId = ClassByName[key]
    if classId > 0 then
        return classId
    endif
    set classId = NextClassId
    set NextClassId = NextClassId + 1
    set ClassByName[key] = classId
    set ClassName.string[classId] = className
    return classId
endfunction

public function RegisterProfile takes integer classId, integer unitTypeId, string profileName returns integer
    local integer key
    local integer profileId
    call EnsureState()
    if classId <= 0 or unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set key = StringHash(profileName)
    set profileId = ProfileByName[key]
    if profileId > 0 then
        return profileId
    endif
    set profileId = NextProfileId
    set NextProfileId = NextProfileId + 1
    set ProfileByName[key] = profileId
    set ProfileClass[profileId] = classId
    set ProfileUnitType[profileId] = unitTypeId
    set ProfileName.string[profileId] = profileName
    set ProfileReviveDelay.real[profileId] = AI_DEFAULT_REVIVE_DELAY
    if UnitTypeDefaultProfile[unitTypeId] == 0 then
        set UnitTypeDefaultProfile[unitTypeId] = profileId
    endif
    return profileId
endfunction

public function SetClassCap takes integer classId, integer cap returns nothing
    call EnsureState()
    set ClassCap[classId] = cap
endfunction

public function SetProfileCap takes integer profileId, integer cap returns nothing
    call EnsureState()
    set ProfileCap[profileId] = cap
endfunction

public function SetUnitTypeCap takes integer unitTypeId, integer cap returns nothing
    call EnsureState()
    set UnitTypeCap[unitTypeId] = cap
endfunction

public function SetProfileRandomUniqueId takes integer profileId, integer uniqueId returns nothing
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set ProfileRandomUniqueId[profileId] = uniqueId
endfunction

public function SetProfileFixedHeroLevel takes integer profileId, integer level returns nothing
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    if level <= 0 then
        call ProfileFixedHeroLevel.remove(profileId)
    else
        set ProfileFixedHeroLevel[profileId] = level
    endif
endfunction

public function SetProfileXpLockedUntilInvite takes integer profileId, boolean enabled returns nothing
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set ProfileLockXpUntilInvite.boolean[profileId] = enabled
endfunction

public function SetUnitTypeDefaultProfile takes integer unitTypeId, integer profileId returns nothing
    call EnsureState()
    if unitTypeId == 0 or profileId <= 0 or ProfileUnitType[profileId] != unitTypeId then
        return
    endif
    set UnitTypeDefaultProfile[unitTypeId] = profileId
endfunction

public function SetProfileFaction takes integer profileId, string factionName returns nothing
    local integer unitTypeId

    call EnsureState()
    if profileId <= 0 then
        return
    endif
    if factionName == "" then
        call ProfileFaction.remove(profileId)
        return
    endif

    set ProfileFaction.string[profileId] = factionName
    set unitTypeId = ProfileUnitType[profileId]
    if unitTypeId != 0 then
        call Reputation_RegisterUnitTypeFaction(unitTypeId, factionName)
    endif
endfunction

public function GetReviveTimer takes unit whichUnit returns timer
    local integer instanceId

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return null
    endif

    call EnsureState()

    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        return null
    endif

    return InstanceReviveTimer.timer[instanceId]
endfunction

private function InspectCinematicReviveState takes nothing returns nothing
    local integer instanceId

    if CinematicMover_EventUnit == null then
        return
    endif
    set instanceId = UnitInstance[GetHandleId(CinematicMover_EventUnit)]
    if instanceId > 0 then
        set CinematicMover_EventAiManaged = true
        set CinematicMover_EventReviveTimer = InstanceReviveTimer.timer[instanceId]
    endif
endfunction

private function CancelCinematicReviveTimer takes nothing returns nothing
    call AI_CancelReviveTimer(CinematicMover_EventUnit)
endfunction

private function RestoreCinematicReviveTimer takes nothing returns nothing
    if CinematicMover_EventHadReviveTimer and CinematicMover_EventReviveRemaining > 0.0 then
        call AI_SetReviveRemaining(CinematicMover_EventUnit, CinematicMover_EventReviveRemaining)
    else
        call AI_CancelReviveTimer(CinematicMover_EventUnit)
    endif
endfunction

public function GetReviveRemaining takes unit whichUnit returns real
    local timer reviveTimer = GetReviveTimer(whichUnit)
    local real remaining = 0.0

    if reviveTimer != null then
        set remaining = TimerGetRemaining(reviveTimer)
    endif

    set reviveTimer = null
    return remaining
endfunction

public function IsReviving takes unit whichUnit returns boolean
    return GetReviveTimer(whichUnit) != null
endfunction

public function ArePartyMembers takes unit firstUnit, unit secondUnit returns boolean
    local integer firstInstance
    local integer secondInstance
    local integer leaderInstance

    if firstUnit == null or secondUnit == null or firstUnit == secondUnit then
        return false
    endif
    set firstInstance = UnitInstance[GetHandleId(firstUnit)]
    set secondInstance = UnitInstance[GetHandleId(secondUnit)]
    if firstInstance <= 0 or secondInstance <= 0 then
        return false
    endif
    set leaderInstance = InstanceAiPartyLeader[firstInstance]
    return leaderInstance > 0 and leaderInstance == InstanceAiPartyLeader[secondInstance]
endfunction

public function SetProfileReviveDelay takes integer profileId, real delay returns nothing
    call EnsureState()
    set ProfileReviveDelay.real[profileId] = delay
endfunction

public function SetProfileNoManaRestore takes integer profileId, boolean noMana returns nothing
    call EnsureState()
    set ProfileNoManaRestore.boolean[profileId] = noMana
endfunction

public function SetProfileCompanionRetreat takes integer profileId, boolean enabled returns nothing
    call EnsureState()
    set ProfileCompanionRetreatDisabled.boolean[profileId] = not enabled
endfunction

public function SetProfileAllowCompanionTravel takes integer profileId, boolean allowed returns nothing
    call EnsureState()
    set ProfileAllowCompanionTravel.boolean[profileId] = allowed
endfunction

public function SetProfileAutonomous takes integer profileId, boolean enabled returns nothing
    call EnsureState()
    set ProfileAutonomousDisabled.boolean[profileId] = not enabled
endfunction

public function AddProfileProfession takes integer profileId, integer professionId returns nothing
    local integer key
    call EnsureState()
    if profileId <= 0 or professionId <= AI_PROFESSION_NONE or professionId > AI_PROFESSION_MAX then
        return
    endif
    set key = GetProfileProfessionKey(profileId, professionId)
    if not ProfileProfession.boolean[key] then
        set ProfileProfession.boolean[key] = true
        set ProfileProfessionCount[profileId] = ProfileProfessionCount[profileId] + 1
    endif
endfunction

public function RemoveProfileProfession takes integer profileId, integer professionId returns nothing
    local integer key
    call EnsureState()
    if profileId <= 0 or professionId <= AI_PROFESSION_NONE or professionId > AI_PROFESSION_MAX then
        return
    endif
    set key = GetProfileProfessionKey(profileId, professionId)
    if ProfileProfession.boolean[key] then
        call ProfileProfession.remove(key)
        if ProfileProfessionCount[profileId] > 0 then
            set ProfileProfessionCount[profileId] = ProfileProfessionCount[profileId] - 1
        endif
    endif
endfunction

public function SetProfileSpawnOwner takes integer profileId, player owner returns nothing
    call EnsureState()
    if profileId <= 0 or owner == null then
        return
    endif
    set ProfileSpawnOwnerSlot[profileId] = GetPlayerId(owner) + 1
endfunction

public function SetRandomSpawnOwner takes player owner returns nothing
    call EnsureState()
    if owner == null then
        return
    endif
    set RandomSpawnOwnerIndex = GetPlayerId(owner)
endfunction

public function SetRandomSpawnHardCap takes integer cap returns nothing
    call EnsureState()
    if cap < 1 then
        set cap = 1
    elseif cap > AI_RANDOM_ACTIVE_CAP_MAX then
        set cap = AI_RANDOM_ACTIVE_CAP_MAX
    endif
    set RandomSpawnHardCap = cap
    call DebugMsg("Random spawn hard cap set to " + I2S(cap) + ".")
endfunction

public function SetRandomSpawnActiveCap takes integer cap returns nothing
    call EnsureState()
    if cap < 1 then
        set cap = 1
    elseif cap > AI_RANDOM_ACTIVE_CAP_MAX then
        set cap = AI_RANDOM_ACTIVE_CAP_MAX
    endif
    set RandomSpawnActiveCap = cap
    if cap > 0 and RandomSpawnActiveMin > cap then
        set RandomSpawnActiveMin = cap
    endif
    call EnforceRandomSpawnActiveCap()
    call DebugMsg("Random spawn active cap set to " + I2S(cap) + ".")
endfunction

public function GetRandomSpawnActiveCap takes nothing returns integer
    call EnsureState()
    return RandomSpawnActiveCap
endfunction

public function SetRandomSpawnActiveMin takes integer cap returns nothing
    call EnsureState()
    if cap < 1 then
        set cap = 1
    elseif RandomSpawnActiveCap > 0 and cap > RandomSpawnActiveCap then
        set cap = RandomSpawnActiveCap
    endif
    set RandomSpawnActiveMin = cap
    call DebugMsg("Random spawn active minimum set to " + I2S(cap) + ".")
endfunction

public function AddRandomSpawnProfile takes integer profileId returns nothing
    local integer index = 1
    call EnsureState()
    if profileId <= 0 or ProfileUnitType[profileId] == 0 then
        return
    endif
    loop
        exitwhen index > RandomSpawnProfileCount
        if RandomSpawnProfiles[index] == profileId then
            return
        endif
        set index = index + 1
    endloop
    if RandomSpawnProfileCount >= MAX_RANDOM_SPAWN_PROFILES then
        call BJDebugMsg("[AI] ERROR: MAX_RANDOM_SPAWN_PROFILES reached.")
        return
    endif
    set RandomSpawnProfileCount = RandomSpawnProfileCount + 1
    set RandomSpawnProfiles[RandomSpawnProfileCount] = profileId
endfunction

public function SetRandomSpawnFirstProfile takes integer profileId returns nothing
    call EnsureState()
    if profileId <= 0 or ProfileUnitType[profileId] == 0 then
        return
    endif
    set RandomSpawnFirstProfile = profileId
    set RandomSpawnFirstProfileDone = false
endfunction

public function SetProfileRegisterCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileRegisterTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileRegisterTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function SetProfileThinkCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileThinkTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileThinkTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function SetProfileDeathCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileDeathTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileDeathTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function SetProfileReviveCallback takes integer profileId, code callback returns nothing
    local trigger oldTrigger
    local trigger newTrigger
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set oldTrigger = ProfileReviveTrigger.trigger[profileId]
    if oldTrigger != null then
        call DestroyTrigger(oldTrigger)
    endif
    set newTrigger = CreateTrigger()
    call TriggerAddAction(newTrigger, callback)
    set ProfileReviveTrigger.trigger[profileId] = newTrigger
    set oldTrigger = null
    set newTrigger = null
endfunction

public function AddProfileSpawnPoint takes integer profileId, real x, real y returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set count = ProfileSpawnCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileSpawnCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileSpawnX.real[key] = x
    set ProfileSpawnY.real[key] = y
endfunction

public function AddProfileSpawnRect takes integer profileId, rect whichRect returns nothing
    if whichRect == null then
        return
    endif
    call AI_AddProfileSpawnPoint(profileId, GetRectCenterX(whichRect), GetRectCenterY(whichRect))
endfunction

public function AddProfileRetreatPoint takes integer profileId, real x, real y returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set count = ProfileRetreatCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileRetreatCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileRetreatX.real[key] = x
    set ProfileRetreatY.real[key] = y
endfunction

public function AddProfileRetreatRect takes integer profileId, rect whichRect returns nothing
    if whichRect == null then
        return
    endif
    call AI_AddProfileRetreatPoint(profileId, GetRectCenterX(whichRect), GetRectCenterY(whichRect))
endfunction

public function AddProfileAllowedZoneRect takes integer profileId, rect whichRect returns nothing
    local integer count
    local integer key
    local real minX
    local real minY
    local real maxX
    local real maxY
    call EnsureState()
    if profileId <= 0 or whichRect == null then
        return
    endif
    set count = ProfileAllowedZoneCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set minX = GetRectMinX(whichRect)
    set minY = GetRectMinY(whichRect)
    set maxX = GetRectMaxX(whichRect)
    set maxY = GetRectMaxY(whichRect)
    if maxX < minX or maxY < minY then
        return
    endif
    set count = count + 1
    set ProfileAllowedZoneCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileAllowedZoneMinX.real[key] = minX
    set ProfileAllowedZoneMinY.real[key] = minY
    set ProfileAllowedZoneMaxX.real[key] = maxX
    set ProfileAllowedZoneMaxY.real[key] = maxY
endfunction

private function AddProfileShopPointInternal takes integer profileId, real x, real y, unit shopUnit returns boolean
    local integer count
    local integer key
    if profileId <= 0 then
        return false
    endif
    set count = ProfileShopCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return false
    endif
    set count = count + 1
    set ProfileShopCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileShopX.real[key] = x
    set ProfileShopY.real[key] = y
    if shopUnit != null then
        set ProfileShopUnit.unit[key] = shopUnit
    else
        call ProfileShopUnit.unit.remove(key)
    endif
    return true
endfunction

private function AddProfileShopUnitTypeEnum takes nothing returns nothing
    local unit shopUnit = GetEnumUnit()
    if shopUnit != null and GetUnitTypeId(shopUnit) == ShopScanUnitTypeId and IsAliveUnit(shopUnit) then
        if AddProfileShopPointInternal(ShopScanProfileId, GetUnitX(shopUnit), GetUnitY(shopUnit), shopUnit) then
            set ShopScanAdded = ShopScanAdded + 1
        endif
    endif
    set shopUnit = null
endfunction

public function AddProfileShopPoint takes integer profileId, real x, real y returns nothing
    call EnsureState()
    call AddProfileShopPointInternal(profileId, x, y, null)
endfunction

public function AddProfileShopUnit takes integer profileId, unit shopUnit returns nothing
    call EnsureState()
    if shopUnit == null then
        return
    endif
    call AddProfileShopPointInternal(profileId, GetUnitX(shopUnit), GetUnitY(shopUnit), shopUnit)
endfunction

public function AddProfileShopUnitType takes integer profileId, integer unitTypeId returns nothing
    call EnsureState()
    if profileId <= 0 or unitTypeId == 0 then
        return
    endif
    set ShopScanProfileId = profileId
    set ShopScanUnitTypeId = unitTypeId
    set ShopScanAdded = 0
    call GroupClear(TempGroup)
    call GroupEnumUnitsInRect(TempGroup, bj_mapInitialPlayableArea, null)
    call ForGroup(TempGroup, function AddProfileShopUnitTypeEnum)
    call GroupClear(TempGroup)
    call DebugMsg("Registered " + I2S(ShopScanAdded) + " shop units of type " + I2S(unitTypeId) + " for profile " + I2S(profileId) + ".")
    set ShopScanProfileId = 0
    set ShopScanUnitTypeId = 0
    set ShopScanAdded = 0
endfunction

public function AddProfileShopItem takes integer profileId, integer itemTypeId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or itemTypeId == 0 then
        return
    endif
    set count = ProfileShopItemCount[profileId]
    if count >= MAX_PROFILE_ITEMS then
        return
    endif
    set count = count + 1
    set ProfileShopItemCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileShopItemType[key] = itemTypeId
endfunction

public function AddDefaultShopItems takes integer profileId returns nothing
    if not ProfileNoManaRestore.boolean[profileId] then
        call AI_AddProfileShopItem(profileId, ITEM_MINOR_MANA_POTION)
        call AI_AddProfileShopItem(profileId, ITEM_MANA_POTION)
        call AI_AddProfileShopItem(profileId, ITEM_MAJOR_MANA_POTION)
        call AI_AddProfileShopItem(profileId, ITEM_SPRING_WATER)
    endif
    call AI_AddProfileShopItem(profileId, ITEM_MINOR_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_MAJOR_HEALING_POTION)
    call AI_AddProfileShopItem(profileId, ITEM_HEALING_SALVE)
    call AI_AddProfileShopItem(profileId, ITEM_GREATER_HEALING_SALVE)
endfunction

public function AddProfileStartingAbility takes integer profileId, integer abilityId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or abilityId == 0 then
        return
    endif
    set count = ProfileStartingAbilityCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileStartingAbilityCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileStartingAbilityId[key] = abilityId
endfunction

public function AddProfileAbility takes integer profileId, integer abilityId returns nothing
    local integer count
    local integer key
    call EnsureState()
    if profileId <= 0 or abilityId == 0 then
        return
    endif
    set count = ProfileAbilityCount[profileId]
    if count >= MAX_PROFILE_POINTS then
        return
    endif
    set count = count + 1
    set ProfileAbilityCount[profileId] = count
    set key = GetPointKey(profileId, count)
    set ProfileAbilityId[key] = abilityId
endfunction

private function RegisterBarkLineInternal takes integer profileId, integer barkType, string text, string soundKey, string factionName, integer minRep, integer maxRep returns nothing
    local integer barkKey
    local integer count
    local integer index
    local integer lineKey
    call EnsureState()
    if profileId <= 0 or barkType <= 0 or text == "" then
        return
    endif
    set barkKey = GetBarkKey(profileId, barkType)
    set count = BarkLineCount[barkKey]
    set index = 1
    loop
        exitwhen index > count
        set lineKey = GetBarkLineKey(barkKey, index)
        if soundKey != "" and BarkLineSound.string[lineKey] == soundKey then
            set BarkLineText.string[lineKey] = text
            set BarkLineFaction.string[lineKey] = factionName
            set BarkLineMinRep[lineKey] = minRep
            set BarkLineMaxRep[lineKey] = maxRep
            return
        endif
        set index = index + 1
    endloop
    if count >= MAX_BARK_LINES then
        return
    endif
    set count = count + 1
    set BarkLineCount[barkKey] = count
    set lineKey = GetBarkLineKey(barkKey, count)
    set BarkLineText.string[lineKey] = text
    set BarkLineSound.string[lineKey] = soundKey
    set BarkLineFaction.string[lineKey] = factionName
    set BarkLineMinRep[lineKey] = minRep
    set BarkLineMaxRep[lineKey] = maxRep
endfunction

public function RegisterBarkLine takes integer profileId, integer barkType, string text, string soundKey returns nothing
    call RegisterBarkLineInternal(profileId, barkType, text, soundKey, "", AI_REP_NO_MIN, AI_REP_NO_MAX)
endfunction

public function RegisterBarkLineForReputation takes integer profileId, integer barkType, string text, string soundKey, string factionName, integer minRep, integer maxRep returns nothing
    if factionName == "" then
        call RegisterBarkLineInternal(profileId, barkType, text, soundKey, "", AI_REP_NO_MIN, AI_REP_NO_MAX)
    else
        call RegisterBarkLineInternal(profileId, barkType, text, soundKey, factionName, minRep, maxRep)
    endif
endfunction

public function RegisterBarkSequence takes integer profileId, integer barkType, string text, string soundPrefix, integer first, integer last returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkLine(profileId, barkType, text, soundPrefix + I2S(index))
        set index = index + 1
    endloop
endfunction

public function RegisterBarkReply takes string primarySoundKey, integer responderProfileId, string text, string replySoundKey returns nothing
    local integer replyKey
    local integer count
    local integer index
    local integer lineKey
    call EnsureState()
    if primarySoundKey == "" or responderProfileId <= 0 or text == "" or replySoundKey == "" then
        return
    endif
    set replyKey = StringHash(primarySoundKey)
    set count = ReplyLineCount[replyKey]
    set index = 1
    loop
        exitwhen index > count
        set lineKey = GetReplyIndexKey(replyKey, index)
        if ReplyLineResponderProfile[lineKey] == responderProfileId and ReplyLineSound.string[lineKey] == replySoundKey then
            set ReplyLineText.string[lineKey] = text
            return
        endif
        set index = index + 1
    endloop
    if count >= MAX_BARK_LINES then
        return
    endif
    set count = count + 1
    set ReplyLineCount[replyKey] = count
    set lineKey = GetReplyIndexKey(replyKey, count)
    set ReplyLineResponderProfile[lineKey] = responderProfileId
    set ReplyLineText.string[lineKey] = text
    set ReplyLineSound.string[lineKey] = replySoundKey
endfunction

public function RegisterBarkReplySequence takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string text, string replySoundPrefix returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkReply(primarySoundPrefix + I2S(index), responderProfileId, text, replySoundPrefix + I2S(index))
        set index = index + 1
    endloop
endfunction

public function RegisterBarkReplySequenceSuffix takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string text, string replySoundPrefix, string replySoundSuffix returns nothing
    local integer index = first
    loop
        exitwhen index > last
        call AI_RegisterBarkReply(primarySoundPrefix + I2S(index), responderProfileId, text, replySoundPrefix + I2S(index) + replySoundSuffix)
        set index = index + 1
    endloop
endfunction

private function StartDialogUnlock takes real delay returns nothing
    if delay < 0.01 then
        set delay = 0.01
    endif
    if DialogUnlockTimer == null then
        set DialogUnlockTimer = CreateTimer()
    endif
    call TimerStart(DialogUnlockTimer, delay, false, function UnlockDialog)
endfunction

private function FindPattern takes string source, string pattern returns integer
    local integer sourceLength = StringLength(source)
    local integer patternLength = StringLength(pattern)
    local integer index = 0

    if patternLength <= 0 or sourceLength < patternLength then
        return -1
    endif

    loop
        exitwhen index > sourceLength - patternLength
        if SubString(source, index, index + patternLength) == pattern then
            return index
        endif
        set index = index + 1
    endloop

    return -1
endfunction

private function IsAvelineCompatibleWarriorChat takes string soundKey returns boolean
    if soundKey == VL_WARLOCK_HEROWARLOCK_CHATWARRIOR4_KEY then
        return true
    elseif soundKey == VL_UNDEADWARLOCK_HEROUNDEADWARLOCK_CHATWARRIOR1_KEY then
        return true
    elseif soundKey == VL_UNDEADWARLOCK_HEROUNDEADWARLOCK_CHATWARRIOR2_KEY then
        return true
    elseif soundKey == VL_UNDEADWARLOCK_HEROUNDEADWARLOCK_CHATWARRIOR3_KEY then
        return true
    elseif soundKey == VL_UNDEADWARLOCK_HEROUNDEADWARLOCK_CHATWARRIOR4_KEY then
        return true
    elseif soundKey == VL_RESTOSHAMAN_HEROSHAMAN_CHATWARRIOR1_KEY then
        return true
    elseif soundKey == VL_RESTOSHAMAN_HEROSHAMAN_CHATWARRIOR2_KEY then
        return true
    elseif soundKey == VL_RESTOSHAMAN_HEROSHAMAN_CHATWARRIOR3_KEY then
        return true
    elseif soundKey == VL_RESTOSHAMAN_HEROSHAMAN_CHATWARRIOR4_KEY then
        return true
    elseif soundKey == VL_ENGINEER_HEROENGINEER_CHATWARRIOR1_KEY then
        return true
    elseif soundKey == VL_ENGINEER_HEROENGINEER_CHATWARRIOR4_KEY then
        return true
    elseif soundKey == VL_PALADIN_HEROPALADIN_CHATWARRIOR2_KEY then
        return true
    elseif soundKey == VL_PALADIN_HEROPALADIN_CHATWARRIOR4_KEY then
        return true
    endif
    return false
endfunction

private function GetChatTargetClassName takes string soundKey returns string
    if FindPattern(soundKey, "_ChatEngineer") >= 0 then
        return "Engineer"
    elseif FindPattern(soundKey, "_ChatPaladin") >= 0 then
        return "Paladin"
    elseif FindPattern(soundKey, "_ChatRogue") >= 0 then
        return "Rogue"
    elseif FindPattern(soundKey, "_ChatShaman") >= 0 then
        return "Restoshaman"
    elseif FindPattern(soundKey, "_ChatWarlock") >= 0 then
        return "Warlock"
    endif
    return ""
endfunction

private function GetChatTargetProfileName takes string soundKey returns string
    if FindPattern(soundKey, "_ChatUndeadWarlock") >= 0 then
        return "Undead Warlock"
    endif
    return ""
endfunction

private function HasNearbyChatTarget takes unit speaker, string className, string profileName returns boolean
    local integer index = 1
    local integer instanceId
    local unit candidate
    if speaker == null or (className == "" and profileName == "") then
        return true
    endif
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set candidate = InstanceUnit.unit[instanceId]
        if candidate != null and candidate != speaker and IsAliveUnit(candidate) and not IsUnitHidden(candidate) and IsUnitAlly(candidate, GetOwningPlayer(speaker)) and IsUnitInRange(candidate, speaker, AI_SOCIAL_SCAN_RANGE) then
            if profileName != "" then
                if ProfileName.string[InstanceProfile[instanceId]] == profileName then
                    set candidate = null
                    return true
                endif
            elseif ClassName.string[InstanceClass[instanceId]] == className then
                set candidate = null
                return true
            endif
        endif
        set index = index + 1
    endloop
    set candidate = null
    return false
endfunction

private function HasNearbyWarriorChatTarget takes unit speaker, string soundKey returns boolean
    if HasNearbyChatTarget(speaker, "", "Horde Warrior") then
        return true
    endif
    if IsAvelineCompatibleWarriorChat(soundKey) then
        return HasNearbyChatTarget(speaker, "", "Aveline")
    endif
    return false
endfunction

private function IsBarkTargetContextAllowed takes unit speaker, string soundKey returns boolean
    local string className = GetChatTargetClassName(soundKey)
    local string profileName = GetChatTargetProfileName(soundKey)
    if FindPattern(soundKey, "_ChatWarrior") >= 0 then
        return HasNearbyWarriorChatTarget(speaker, soundKey)
    endif
    if className == "" and profileName == "" then
        return true
    endif
    return HasNearbyChatTarget(speaker, className, profileName)
endfunction

private function FindCompanionResponder takes integer profileId, unit speaker returns unit
    local integer i = 1
    local integer instanceId
    local unit candidate
    local unit responder = null
    local integer seen = 0
    loop
        exitwhen i > ActiveCount
        set instanceId = ActiveInstances[i]
        set candidate = InstanceUnit.unit[instanceId]
        if candidate != null and candidate != speaker and InstanceProfile[instanceId] == profileId then
            if IsAliveUnit(candidate) and IsCompanionControlled(candidate) and IsBarkNearPlayerHero(candidate) and (speaker == null or IsUnitInRange(candidate, speaker, AI_BARK_REPLY_RANGE)) then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set responder = candidate
                endif
            endif
        endif
        set i = i + 1
    endloop
    set candidate = null
    return responder
endfunction

private function PlayBarkReply takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit speaker = ReplyTimerSpeaker.unit[timerId]
    local unit responder = ReplyTimerResponder.unit[timerId]
    local string text = ReplyTimerText.string[timerId]
    local string soundKey = ReplyTimerSound.string[timerId]
    local integer responderInstance
    local real now = GetNow()
    local real duration
    if responder != null and IsAliveUnit(responder) and IsCompanionControlled(responder) and IsBarkNearPlayerHero(responder) and (speaker == null or IsUnitInRange(responder, speaker, AI_BARK_REPLY_RANGE)) and not IsDialogBlockingBark() then
        if speaker != null and IsAliveUnit(speaker) then
            call DialogSystem_MakeFaceEachOther(speaker, responder, 0.50)
        endif
        call DialogSystem_PlayLine(responder, "", text, soundKey, true)
        set duration = udg_ExSoundDuration
        if duration <= 0.00 then
            set duration = EstimateDialogDuration(text)
        endif
        set responderInstance = UnitInstance[GetHandleId(responder)]
        if responderInstance > 0 then
            set InstanceNextChat.real[responderInstance] = now + duration + AI_DIALOG_UNLOCK_PAD
        endif
        set NextGlobalBark = now + duration + AI_BARK_GLOBAL_GAP
        call StartDialogUnlock(duration + AI_DIALOG_UNLOCK_PAD)
    else
        call StartDialogUnlock(AI_DIALOG_UNLOCK_PAD)
    endif
    call ReplyTimerSpeaker.remove(timerId)
    call ReplyTimerResponder.remove(timerId)
    call ReplyTimerText.remove(timerId)
    call ReplyTimerSound.remove(timerId)
    call DestroyTimer(expired)
    set expired = null
    set speaker = null
    set responder = null
endfunction

private function ScheduleBarkReply takes unit speaker, string primarySoundKey, real delay returns boolean
    local integer replyKey
    local integer count
    local integer attempts
    local integer index
    local integer lineKey
    local integer responderProfileId
    local unit responder
    local timer replyTimer
    local integer timerId
    if primarySoundKey == "" then
        return false
    endif
    set replyKey = StringHash(primarySoundKey)
    set count = ReplyLineCount[replyKey]
    if count <= 0 then
        return false
    endif
    if not IsBarkTargetContextAllowed(speaker, primarySoundKey) then
        return false
    endif
    set attempts = count
    set index = GetRandomInt(1, count)
    loop
        exitwhen attempts <= 0
        set lineKey = GetReplyIndexKey(replyKey, index)
        set responderProfileId = ReplyLineResponderProfile[lineKey]
        set responder = FindCompanionResponder(responderProfileId, speaker)
        if responder != null then
            set replyTimer = CreateTimer()
            set timerId = GetHandleId(replyTimer)
            set ReplyTimerSpeaker.unit[timerId] = speaker
            set ReplyTimerResponder.unit[timerId] = responder
            set ReplyTimerText.string[timerId] = ReplyLineText.string[lineKey]
            set ReplyTimerSound.string[timerId] = ReplyLineSound.string[lineKey]
            call TimerStart(replyTimer, delay, false, function PlayBarkReply)
            set replyTimer = null
            set responder = null
            return true
        endif
        set index = index + 1
        if index > count then
            set index = 1
        endif
        set attempts = attempts - 1
    endloop
    set responder = null
    return false
endfunction

public function GetInstance takes unit whichUnit returns integer
    call EnsureState()
    if whichUnit == null then
        return 0
    endif
    return UnitInstance[GetHandleId(whichUnit)]
endfunction

public function IsAlive takes unit whichUnit returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)

    return instanceId > 0 and InstanceAlive.boolean[instanceId] and FallenHeroState_IsAlive(whichUnit)
endfunction

public function GetUnitByInstance takes integer instanceId returns unit
    call EnsureState()
    return InstanceUnit.unit[instanceId]
endfunction

public function GetUnitByUniqueId takes integer uniqueId returns unit
    local integer instanceId
    call EnsureState()
    if uniqueId == 0 then
        return null
    endif
    set instanceId = UniqueInstance[uniqueId]
    if instanceId <= 0 then
        return null
    endif
    return InstanceUnit.unit[instanceId]
endfunction

public function GetProfileId takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return 0
    endif
    return InstanceProfile[instanceId]
endfunction

public function GetProfileFaction takes integer profileId returns string
    call EnsureState()
    if profileId <= 0 then
        return ""
    endif
    return ProfileFaction.string[profileId]
endfunction

public function GetFactionInfoText takes unit whichUnit returns string
    local integer instanceId
    local integer profileId
    local string factionName

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return ""
    endif

    call EnsureState()
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId > 0 then
        set profileId = InstanceProfile[instanceId]
        set factionName = ProfileFaction.string[profileId]
        if factionName != "" then
            return factionName
        endif
    endif

    set factionName = Reputation_GetUnitFactionName(whichUnit)
    if factionName != "" then
        return factionName
    endif

    return ""
endfunction

public function GetClassId takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return 0
    endif
    return InstanceClass[instanceId]
endfunction

public function GetState takes unit whichUnit returns integer
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return AI_STATE_INACTIVE
    endif
    return InstanceState[instanceId]
endfunction

public function GetProfessionSkill takes unit whichUnit, integer professionId returns integer
    if whichUnit == null or professionId <= AI_PROFESSION_NONE then
        return 0
    endif
    return GNS_GetSkill(whichUnit, professionId)
endfunction

public function BeginBuy takes unit whichUnit returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginBuyState(instanceId, whichUnit)
endfunction

public function BeginSell takes unit whichUnit returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginSellState(instanceId, whichUnit)
endfunction

public function BeginCamp takes unit whichUnit, real duration returns boolean
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 then
        return false
    endif
    return BeginCampState(instanceId, whichUnit, duration)
endfunction

private function ApplyProfileHeroRules takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    local integer fixedLevel
    if instanceId <= 0 or whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set fixedLevel = ProfileFixedHeroLevel[profileId]
    if fixedLevel > 0 and not InstanceInviteUnlocked.boolean[instanceId] and GetHeroLevel(whichUnit) != fixedLevel then
        call SetHeroLevel(whichUnit, fixedLevel, false)
    endif
    if ProfileLockXpUntilInvite.boolean[profileId] and not InstanceInviteUnlocked.boolean[instanceId] then
        call SuspendHeroXP(whichUnit, true)
    endif
endfunction

private function ApplyDefaultBagSpace takes unit whichUnit returns nothing
    local player owner

    if whichUnit == null or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        set whichUnit = null
        return
    endif

    set owner = GetOwningPlayer(whichUnit)
    if GetPlayerController(owner) != MAP_CONTROL_COMPUTER then
        set owner = null
        set whichUnit = null
        return
    endif

    if DInvGetBagTierOfUnit(whichUnit) < AI_DEFAULT_BAG_TIER then
        call DInvSetBagTierForUnit(whichUnit, AI_DEFAULT_BAG_TIER)
    endif

    set owner = null
    set whichUnit = null
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    local integer existing
    local integer instanceId
    local integer classId
    local integer unitTypeId
    local integer customValue
    call EnsureState()
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or profileId <= 0 then
        return 0
    endif
    set unitTypeId = GetUnitTypeId(whichUnit)
    if ProfileUnitType[profileId] != unitTypeId then
        call DebugMsg("Registration rejected for " + GetDebugUnitName(whichUnit) + " because unit type does not match profile " + I2S(profileId))
        return 0
    endif
    set existing = UnitInstance[GetHandleId(whichUnit)]
    if existing > 0 then
        return existing
    endif
    if not CanRegister(profileId, uniqueId) then
        if uniqueId != 0 and UniqueInstance[uniqueId] != 0 then
            call DebugMsg("Removed duplicate unique unit " + GetDebugUnitName(whichUnit) + " profile=" + I2S(profileId) + " existingInstance=" + I2S(UniqueInstance[uniqueId]) + ".")
            if IsCompanionControlled(whichUnit) then
                call Companions_Remove(whichUnit)
            endif
            call RemoveUnit(whichUnit)
        else
            call DebugMsg("Cap prevented registration for " + GetDebugUnitName(whichUnit) + " profile=" + I2S(profileId))
        endif
        return 0
    endif
    if NextInstanceId > MAX_AI_INSTANCES then
        call BJDebugMsg("[AI] ERROR: MAX_AI_INSTANCES reached.")
        return 0
    endif
    set classId = ProfileClass[profileId]
    set instanceId = NextInstanceId
    set NextInstanceId = NextInstanceId + 1
    set UnitInstance[GetHandleId(whichUnit)] = instanceId
    set InstanceUnit.unit[instanceId] = whichUnit
    set InstanceClass[instanceId] = classId
    set InstanceProfile[instanceId] = profileId
    set InstanceUnique[instanceId] = uniqueId
    set InstanceUnitType[instanceId] = unitTypeId
    set InstanceAlive.boolean[instanceId] = IsAliveUnit(whichUnit)
    set InstanceRandomManaged.boolean[instanceId] = false
    set InstanceHiddenByCap.boolean[instanceId] = false
    set InstanceHomeX.real[instanceId] = GetUnitX(whichUnit)
    set InstanceHomeY.real[instanceId] = GetUnitY(whichUnit)
    set InstanceNextThink.real[instanceId] = GetNow() + GetRandomReal(0.00, AI_DEFAULT_THINK_MAX)
    set InstanceNextAbility.real[instanceId] = GetNow() + GetRandomReal(0.00, AI_DEFAULT_ABILITY_GAP)
    set InstanceNextItem.real[instanceId] = GetNow() + GetRandomReal(1.00, 3.00)
    set InstanceNextEquipment.real[instanceId] = GetNow() + GetRandomReal(2.00, 8.00)
    set InstanceNextPickup.real[instanceId] = GetNow() + GetRandomReal(AI_COMPANION_PICKUP_MIN_DELAY, AI_COMPANION_PICKUP_MAX_DELAY)
    set InstanceNextShop.real[instanceId] = GetNow() + GetRandomReal(AI_SHOP_CHECK_MIN, AI_SHOP_CHECK_MAX)
    set InstanceNextProfession.real[instanceId] = GetNow() + GetRandomReal(4.00, 12.00)
    set InstanceProfessionFailCount[instanceId] = 0
    call InstanceProfessionBlockedUntil.remove(instanceId)
    set InstanceNextCamp.real[instanceId] = GetNow() + GetRandomReal(30.00, 120.00)
    set InstanceNextSocial.real[instanceId] = GetNow() + GetRandomReal(10.00, 35.00)
    set InstanceLastOrder[instanceId] = 0
    set InstanceLastX.real[instanceId] = GetUnitX(whichUnit)
    set InstanceLastY.real[instanceId] = GetUnitY(whichUnit)
    set InstanceStuckSince.real[instanceId] = 0.00
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call AddActiveInstance(instanceId)
    call IncrementCounts(classId, profileId, unitTypeId)
    if uniqueId != 0 then
        set UniqueInstance[uniqueId] = instanceId
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        call InitializeDInventoryForUnit(whichUnit)
        call ApplyDefaultBagSpace(whichUnit)
        call InitializeDEquipmentForUnit(whichUnit)
    endif
    call ApplyStartingAbilities(instanceId, whichUnit)
    call ApplyProfileHeroRules(instanceId, whichUnit)
    call RefreshInstanceProfessionSkills(instanceId, whichUnit)
    call RunProfileTrigger(ProfileRegisterTrigger, instanceId, whichUnit)
    if DebugMode then
        call EnsureDebugIcon(instanceId, whichUnit)
    endif
    call DebugMsg("Registered " + GetDebugInstanceName(instanceId, whichUnit) + " instance=" + I2S(instanceId) + " profile=" + I2S(profileId) + " unitType=" + I2S(unitTypeId) + ".")
    set customValue = GetUnitUserData(whichUnit)
    if customValue > 0 then
        set udg_UnitHider_ReferenceUnits[customValue] = whichUnit
    endif
    return instanceId
endfunction

public function RegisterUnitByType takes unit whichUnit, integer uniqueId returns integer
    local integer profileId
    call EnsureState()
    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        return 0
    endif
    set profileId = UnitTypeDefaultProfile[GetUnitTypeId(whichUnit)]
    if profileId <= 0 then
        return 0
    endif
    if uniqueId == 0 then
        set uniqueId = ProfileRandomUniqueId[profileId]
    endif
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

public function UnregisterUnit takes unit whichUnit returns nothing
    local integer instanceId
    local integer classId
    local integer profileId
    local integer unitTypeId
    local integer uniqueId
    local timer reviveTimer
    if whichUnit == null then
        return
    endif
    call EnsureState()
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 then
        return
    endif
    set classId = InstanceClass[instanceId]
    set profileId = InstanceProfile[instanceId]
    set unitTypeId = InstanceUnitType[instanceId]
    set uniqueId = InstanceUnique[instanceId]
    set reviveTimer = InstanceReviveTimer.timer[instanceId]
    if InstanceRandomManaged.boolean[instanceId] and RandomSpawnManagedCount > 0 then
        set RandomSpawnManagedCount = RandomSpawnManagedCount - 1
    endif
    if reviveTimer != null then
        call ReviveTimerInstance.remove(GetHandleId(reviveTimer))
        call PauseTimer(reviveTimer)
        call DestroyTimer(reviveTimer)
        call InstanceReviveTimer.timer.remove(instanceId)
    endif
    call RemoveInstanceFromAiParty(instanceId)
    call ClearDebugIcon(instanceId)
    call RemoveActiveInstance(instanceId)
    call DecrementCounts(classId, profileId, unitTypeId)
    if uniqueId != 0 and UniqueInstance[uniqueId] == instanceId then
        call UniqueInstance.remove(uniqueId)
    endif
    call UnitInstance.remove(GetHandleId(whichUnit))
    call ClearInstanceProfessionState(instanceId, whichUnit)
    call InstanceNextSocial.remove(instanceId)
    call InstanceSocialUntil.remove(instanceId)
    call InstanceLastOrder.remove(instanceId)
    call InstanceLastX.remove(instanceId)
    call InstanceLastY.remove(instanceId)
    call InstanceStuckSince.remove(instanceId)
    set InstanceSocialTarget[instanceId] = null
    set InstanceSocialStopped[instanceId] = false
    set InstanceDebugIcon[instanceId] = null
    call InstanceUnit.unit.remove(instanceId)
    call InstanceClass.remove(instanceId)
    call InstanceProfile.remove(instanceId)
    call InstanceUnique.remove(instanceId)
    call InstanceUnitType.remove(instanceId)
    call InstanceState.remove(instanceId)
    call InstancePreviousState.remove(instanceId)
    call InstanceAlive.remove(instanceId)
    call InstanceTraveling.remove(instanceId)
    call InstanceRandomManaged.remove(instanceId)
    call InstanceHiddenByCap.remove(instanceId)
    call InstanceCompanionControlled.remove(instanceId)
    call InstanceCinematicParked.remove(instanceId)
    call InstanceInviteUnlocked.remove(instanceId)
    call InstanceAiPartyLeader.remove(instanceId)
    call InstanceAiPartyFollowerCount.remove(instanceId)
    call InstanceNextThink.remove(instanceId)
    call InstanceNextAbility.remove(instanceId)
    call InstanceNextItem.remove(instanceId)
    call InstanceNextEquipment.remove(instanceId)
    call InstanceNextPickup.remove(instanceId)
    call InstanceNextChat.remove(instanceId)
    call InstanceNextShop.remove(instanceId)
    call ClearInstanceBarkCooldowns(instanceId)
    call InstanceNextCamp.remove(instanceId)
    call InstanceRetreatUntil.remove(instanceId)
    call InstanceTravelReturnAt.remove(instanceId)
    call InstanceTravelReturnX.remove(instanceId)
    call InstanceTravelReturnY.remove(instanceId)
    call InstanceHomeX.remove(instanceId)
    call InstanceHomeY.remove(instanceId)
    call InstanceActionX.remove(instanceId)
    call InstanceActionY.remove(instanceId)
    call InstanceActionShopUnit.unit.remove(instanceId)
    set reviveTimer = null
endfunction

public function SpawnProfile takes integer profileId, player owner, real x, real y, real facing, integer uniqueId returns unit
    local unit created
    local integer instanceId
    local integer unitTypeId
    call EnsureState()
    if profileId <= 0 or owner == null or not CanRegister(profileId, uniqueId) then
        return null
    endif
    set unitTypeId = ProfileUnitType[profileId]
    if unitTypeId == 0 then
        return null
    endif
    set created = CreateUnit(owner, unitTypeId, x, y, facing)
    if created != null then
        set instanceId = AI_RegisterUnit(created, profileId, uniqueId)
        if instanceId <= 0 then
            call DebugMsg("SpawnProfile removed unregistered " + GetDisplayName(created) + " profile=" + I2S(profileId) + ".")
            call RemoveUnit(created)
            set created = null
        endif
    endif
    return created
endfunction

public function SpawnProfileAtRandomPoint takes integer profileId, player owner, real facing, integer uniqueId returns unit
    local integer count
    local integer index
    local integer key
    call EnsureState()
    set count = ProfileSpawnCount[profileId]
    if count <= 0 then
        return null
    endif
    set index = GetRandomInt(1, count)
    set key = GetPointKey(profileId, index)
    return AI_SpawnProfile(profileId, owner, ProfileSpawnX.real[key], ProfileSpawnY.real[key], facing, uniqueId)
endfunction

public function FindClosestEnemy takes unit source, real range returns unit
    call EnsureState()
    if source == null or range <= 0.00 then
        return null
    endif
    call GroupClear(TempGroup)
    set SearchSource = source
    set SearchBestUnit = null
    set SearchBestDistance = range * range
    set SearchRangeDistance = SearchBestDistance
    set SearchBestScore = -1000000.00
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function ClosestEnemyEnum)
    call GroupClear(TempGroup)
    set SearchSource = null
    set SearchRangeDistance = 0.00
    return SearchBestUnit
endfunction

public function FindLowestHealthAlly takes unit source, real range, boolean includeSelf returns unit
    call EnsureState()
    if source == null or range <= 0.00 then
        return null
    endif
    call GroupClear(TempGroup)
    set AllySearchSource = source
    set AllySearchBestUnit = null
    set AllySearchBestLife = 101.00
    set AllySearchIncludeSelf = includeSelf
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function LowestHealthAllyEnum)
    call GroupClear(TempGroup)
    set AllySearchSource = null
    set AllySearchIncludeSelf = false
    return AllySearchBestUnit
endfunction

public function CountNearbyEnemies takes unit source, real range returns integer
    local integer result
    call EnsureState()
    if source == null or range <= 0.00 then
        return 0
    endif
    call GroupClear(TempGroup)
    set CountSource = source
    set CountResult = 0
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function CountEnemyEnum)
    call GroupClear(TempGroup)
    set result = CountResult
    set CountSource = null
    set CountResult = 0
    return result
endfunction

private function CanCreateRandomHero takes nothing returns boolean
    if not RandomSpawnEnabled or RandomSpawnProfileCount <= 0 then
        return false
    endif
    if RandomSpawnHardCap > 0 and RandomSpawnManagedCount >= RandomSpawnHardCap then
        return false
    endif
    if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() >= RandomSpawnActiveCap then
        return false
    endif
    return true
endfunction

private function GetRandomSpawnProfile takes nothing returns integer
    local integer start
    local integer index
    local integer checked = 0
    local integer profileId
    local integer uniqueId
    if RandomSpawnProfileCount <= 0 then
        return 0
    endif
    if not RandomSpawnFirstProfileDone and RandomSpawnFirstProfile > 0 then
        set profileId = RandomSpawnFirstProfile
        set uniqueId = ProfileRandomUniqueId[profileId]
        if CanRegister(profileId, uniqueId) then
            return profileId
        endif
        set RandomSpawnFirstProfileDone = true
    endif
    set start = GetRandomInt(1, RandomSpawnProfileCount)
    set index = start
    loop
        exitwhen checked >= RandomSpawnProfileCount
        set profileId = RandomSpawnProfiles[index]
        set uniqueId = ProfileRandomUniqueId[profileId]
        if CanRegister(profileId, uniqueId) then
            return profileId
        endif
        set checked = checked + 1
        set index = index + 1
        if index > RandomSpawnProfileCount then
            set index = 1
        endif
    endloop
    return 0
endfunction

private function PickProfileSpawnPoint takes integer profileId returns boolean
    local integer count
    local integer index
    local integer key
    if profileId <= 0 then
        return false
    endif
    set count = ProfileSpawnCount[profileId]
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set RandomPointX = ProfileSpawnX.real[key]
        set RandomPointY = ProfileSpawnY.real[key]
    else
        set RandomPointX = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
        set RandomPointY = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))
    endif
    return true
endfunction

private function GetSpawnOwnerForProfile takes integer profileId returns player
    local integer slot = ProfileSpawnOwnerSlot[profileId]
    if slot > 0 then
        return Player(slot - 1)
    endif
    return Player(RandomSpawnOwnerIndex)
endfunction

private function MarkRandomManaged takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    if not InstanceRandomManaged.boolean[instanceId] then
        set RandomSpawnManagedCount = RandomSpawnManagedCount + 1
    endif
    set InstanceRandomManaged.boolean[instanceId] = true
    set InstanceHiddenByCap.boolean[instanceId] = false
endfunction

private function ApplyRandomSpawnPresentation takes unit whichUnit returns nothing
    local integer newLevel
    local integer instanceId
    local integer profileId = 0
    local integer fixedLevel = 0
    if whichUnit == null then
        return
    endif
    call SetUnitColor(whichUnit, ConvertPlayerColor(GetRandomInt(0, MAX_PLAYER_COLOR_INDEX)))
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId > 0 then
        set profileId = InstanceProfile[instanceId]
        set fixedLevel = ProfileFixedHeroLevel[profileId]
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        if fixedLevel > 0 and not InstanceInviteUnlocked.boolean[instanceId] then
            if GetHeroLevel(whichUnit) != fixedLevel then
                call SetHeroLevel(whichUnit, fixedLevel, false)
            endif
            if ProfileLockXpUntilInvite.boolean[profileId] then
                call SuspendHeroXP(whichUnit, true)
            endif
        else
            set newLevel = GetHeroLevel(whichUnit) + GetRandomInt(1, 15)
            call SetHeroLevel(whichUnit, newLevel, false)
        endif
    endif
    if instanceId > 0 then
        call RefreshInstanceProfessionSkills(instanceId, whichUnit)
    endif
endfunction

private function AnnounceRandomSpawn takes unit whichUnit, integer profileId returns nothing
    if whichUnit == null then
        return
    endif
    call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 6.00, "|cff808000AI Heroes: |r" + ProfileName.string[profileId] + " entered the world...")
endfunction

public function SpawnRandomHero takes boolean showMessage returns unit
    local integer profileId
    local integer instanceId
    local integer uniqueId
    local player owner
    local unit created = null
    call EnsureState()
    if not CanCreateRandomHero() then
        if showMessage then
            call DebugMsg("Random spawn skipped: hard cap, active cap, or random profile pool is blocking it.")
        endif
        return null
    endif
    set profileId = GetRandomSpawnProfile()
    if profileId <= 0 then
        if showMessage then
            call DebugMsg("Random spawn skipped: all random profiles are currently capped.")
        endif
        return null
    endif
    set owner = GetSpawnOwnerForProfile(profileId)
    set uniqueId = ProfileRandomUniqueId[profileId]
    if PickProfileSpawnPoint(profileId) then
        set created = AI_SpawnProfile(profileId, owner, RandomPointX, RandomPointY, GetRandomReal(0.00, 360.00), uniqueId)
    endif
    if created == null then
        if showMessage then
            call DebugMsg("Random spawn failed for profile " + I2S(profileId) + ".")
        endif
        set owner = null
        return null
    endif
    set instanceId = AI_GetInstance(created)
    if instanceId > 0 then
        call MarkRandomManaged(instanceId)
        call ApplyRandomSpawnPresentation(created)
        if profileId == RandomSpawnFirstProfile then
            set RandomSpawnFirstProfileDone = true
        endif
        call DebugMsg("Random spawn created " + GetDebugInstanceName(instanceId, created) + " instance=" + I2S(instanceId) + " profile=" + I2S(profileId) + " active=" + I2S(CountRandomManagedVisible()) + "/" + I2S(RandomSpawnActiveCap) + " managed=" + I2S(RandomSpawnManagedCount) + "/" + I2S(RandomSpawnHardCap) + ".")
        if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() > RandomSpawnActiveCap then
            call HideRandomManagedByCap(instanceId, created)
        endif
    endif
    if showMessage then
        call AnnounceRandomSpawn(created, profileId)
    endif
    set owner = null
    return created
endfunction

private function TryUnhideRandomManaged takes boolean showMessage returns boolean
    local integer index = 1
    local integer instanceId
    local integer selected = 0
    local integer seen = 0
    local unit whichUnit
    if RandomSpawnActiveCap > 0 and CountRandomManagedVisible() >= RandomSpawnActiveCap then
        return false
    endif
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        if InstanceRandomManaged.boolean[instanceId] and InstanceHiddenByCap.boolean[instanceId] and not InstanceTraveling.boolean[instanceId] then
            set whichUnit = InstanceUnit.unit[instanceId]
            if whichUnit != null and IsAliveUnit(whichUnit) and not IsCompanionControlled(whichUnit) then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = instanceId
                endif
            endif
        endif
        set index = index + 1
    endloop
    if selected > 0 then
        set whichUnit = InstanceUnit.unit[selected]
        if CanShowRandomManaged(selected) then
            call ShowRandomManagedFromCap(selected, whichUnit)
            if showMessage then
                call DebugMsg("Random hero returned: " + GetDebugInstanceName(selected, whichUnit))
            endif
            set whichUnit = null
            return true
        endif
    endif
    set whichUnit = null
    return false
endfunction

private function GetRandomTravelInstance takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer selected = 0
    local integer seen = 0
    local integer state
    local unit whichUnit
    local unit enemy
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set state = InstanceState[instanceId]
        if IsRandomManagedVisible(instanceId) and not IsCompanionControlled(InstanceUnit.unit[instanceId]) and (state == AI_STATE_IDLE or state == AI_STATE_WANDER) then
            set whichUnit = InstanceUnit.unit[instanceId]
            set enemy = AI_FindClosestEnemy(whichUnit, 900.00)
            if enemy == null then
                set seen = seen + 1
                if GetRandomInt(1, seen) == 1 then
                    set selected = instanceId
                endif
            endif
            set enemy = null
        endif
        set index = index + 1
    endloop
    set whichUnit = null
    set enemy = null
    return selected
endfunction

public function GetUnitLifePercent takes unit whichUnit returns real
    return GetLifePercent(whichUnit)
endfunction

public function GetUnitManaPercent takes unit whichUnit returns real
    return GetManaPercent(whichUnit)
endfunction

public function TryUseConsumable takes unit whichUnit returns boolean
    local integer slot = 0
    local item slotItem
    local item stagedItem
    local integer itemTypeId
    local integer instanceId
    local integer profileId
    local boolean noMana = false
    local boolean needsLife
    local boolean needsMana
    if whichUnit == null then
        return false
    endif
    set instanceId = AI_GetInstance(whichUnit)
    if instanceId > 0 then
        set profileId = InstanceProfile[instanceId]
        set noMana = ProfileNoManaRestore.boolean[profileId]
    endif
    set needsLife = GetLifePercent(whichUnit) <= 50.00
    set needsMana = (not noMana) and GetManaPercent(whichUnit) <= 50.00
    if not needsLife and not needsMana and not noMana then
        return false
    endif
    if needsLife then
        set stagedItem = StageDInvHealingConsumable(whichUnit, GetLifePercent(whichUnit) <= 25.00)
        if stagedItem != null then
            call UnitUseItem(whichUnit, stagedItem)
            set stagedItem = null
            set slotItem = null
            return true
        endif
    endif
    if noMana then
        loop
            exitwhen slot >= bj_MAX_INVENTORY
            set slotItem = UnitItemInSlot(whichUnit, slot)
            if slotItem != null then
                set itemTypeId = GetItemTypeId(slotItem)
                if IsManaOnlyItemType(itemTypeId) then
                    call UnitDropItemPoint(whichUnit, slotItem, GetUnitX(whichUnit), GetUnitY(whichUnit))
                    call DebugMsg(GetDebugUnitName(whichUnit) + " dropped mana-only item " + GetObjectName(itemTypeId) + ".")
                    set slotItem = null
                    return true
                endif
            endif
            set slot = slot + 1
        endloop
    endif
    if needsMana then
        set stagedItem = StageDInvManaConsumable(whichUnit)
        if stagedItem != null then
            call UnitUseItem(whichUnit, stagedItem)
            set stagedItem = null
            set slotItem = null
            return true
        endif
    endif
    set stagedItem = StageDInvOtherConsumable(whichUnit, needsLife, needsMana)
    if stagedItem != null then
        call UnitUseItem(whichUnit, stagedItem)
        set stagedItem = null
        set slotItem = null
        return true
    endif
    set stagedItem = null
    set slotItem = null
    return false
endfunction

private function PickupItemEnum takes nothing returns nothing
    local item enumItem = GetEnumItem()
    local integer itemTypeId
    local real dx
    local real dy
    local real distance
    if enumItem == null or ItemSearchSource == null then
        set enumItem = null
        return
    endif
    set itemTypeId = GetItemTypeId(enumItem)
    if itemTypeId == 0 or GetWidgetLife(enumItem) <= 0.00 or IsItemOwned(enumItem) or IsItemPowerup(enumItem) or GN_IsGatherItem(enumItem) or IsAIUtilityItemType(itemTypeId) or (ItemSearchNoMana and IsManaOnlyItemType(itemTypeId)) then
        set enumItem = null
        return
    endif
    set dx = GetItemX(enumItem) - GetUnitX(ItemSearchSource)
    set dy = GetItemY(enumItem) - GetUnitY(ItemSearchSource)
    set distance = dx * dx + dy * dy
    if distance <= ItemSearchBestDistance then
        set ItemSearchBestDistance = distance
        set ItemSearchBest = enumItem
    endif
    set enumItem = null
endfunction

private function FindNearbyPickupItem takes integer instanceId, unit whichUnit, real range returns item
    if instanceId <= 0 or whichUnit == null or range <= 0.00 then
        return null
    endif
    set ItemSearchSource = whichUnit
    set ItemSearchBest = null
    set ItemSearchBestDistance = range * range
    set ItemSearchNoMana = ProfileNoManaRestore.boolean[InstanceProfile[instanceId]]
    call SetRect(TempRect, GetUnitX(whichUnit) - range, GetUnitY(whichUnit) - range, GetUnitX(whichUnit) + range, GetUnitY(whichUnit) + range)
    call EnumItemsInRect(TempRect, null, function PickupItemEnum)
    set ItemSearchSource = null
    set ItemSearchNoMana = false
    return ItemSearchBest
endfunction

private function TryUseSideScanBudget takes real now returns boolean
    if SideScanBudgetTime != now then
        set SideScanBudgetTime = now
        set SideScanBudgetCount = 0
    endif
    if SideScanBudgetCount >= AI_SIDE_SCAN_MAX_PER_TICK then
        return false
    endif
    set SideScanBudgetCount = SideScanBudgetCount + 1
    return true
endfunction

private function TryStartPickupAction takes integer instanceId, unit whichUnit, real now returns boolean
    local item targetItem
    local unit enemy
    if instanceId <= 0 or whichUnit == null or udg_InCinematic then
        return false
    endif
    if now < InstanceNextPickup.real[instanceId] or GetFreeInventorySlots(whichUnit) <= 0 then
        return false
    endif
    if not TryUseSideScanBudget(now) then
        set InstanceNextPickup.real[instanceId] = now + GetRandomReal(3.00, 8.00)
        return false
    endif
    set enemy = AI_FindClosestEnemy(whichUnit, 800.00)
    if enemy != null then
        set InstanceNextPickup.real[instanceId] = now + GetRandomReal(5.00, 10.00)
        set enemy = null
        return false
    endif
    set targetItem = FindNearbyPickupItem(instanceId, whichUnit, AI_COMPANION_PICKUP_RANGE)
    if targetItem != null and IssueTargetOrder(whichUnit, "smart", targetItem) then
        set InstanceNextPickup.real[instanceId] = now + GetRandomReal(AI_COMPANION_PICKUP_MIN_DELAY, AI_COMPANION_PICKUP_MAX_DELAY)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " pickup targets " + GetItemName(targetItem) + ".")
        set enemy = null
        set targetItem = null
        set ItemSearchBest = null
        return true
    endif
    set InstanceNextPickup.real[instanceId] = now + GetRandomReal(AI_COMPANION_PICKUP_MIN_DELAY, AI_COMPANION_PICKUP_MAX_DELAY)
    set enemy = null
    set targetItem = null
    set ItemSearchBest = null
    return false
endfunction

private function IsCastingLocked takes unit whichUnit returns boolean
    local integer customValue
    if whichUnit == null then
        return false
    endif
    set customValue = GetUnitUserData(whichUnit)
    return customValue > 0 and udg_UnitIsCasting[customValue]
endfunction

private function CanStartAbilityOrder takes unit caster, integer instanceId returns boolean
    if instanceId > 0 then
        if GetNow() < InstanceNextAbility.real[instanceId] then
            return false
        endif
        if IsCastingLocked(caster) then
            return false
        endif
    endif
    return true
endfunction

private function SetAbilityOrderCooldown takes integer instanceId, real cooldown returns nothing
    if instanceId <= 0 then
        return
    endif
    if cooldown <= 0.00 then
        set cooldown = AI_DEFAULT_ABILITY_GAP
    endif
    set InstanceNextAbility.real[instanceId] = GetNow() + cooldown + GetRandomReal(0.00, AI_ABILITY_ORDER_JITTER)
endfunction

public function IsUnitCastingLocked takes unit whichUnit returns boolean
    return IsCastingLocked(whichUnit)
endfunction

public function TryCastTarget takes unit caster, unit target, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or target == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueTargetOrder(caster, order, target) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastPoint takes unit caster, real x, real y, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssuePointOrder(caster, order, x, y) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastImmediate takes unit caster, integer abilityId, string order, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or order == "" then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueImmediateOrder(caster, order) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function TryCastImmediateById takes unit caster, integer abilityId, integer orderId, real cooldown returns boolean
    local integer instanceId = AI_GetInstance(caster)
    if caster == null or orderId == 0 then
        return false
    endif
    if abilityId != 0 and GetUnitAbilityLevel(caster, abilityId) <= 0 then
        return false
    endif
    if not CanStartAbilityOrder(caster, instanceId) then
        return false
    endif
    if IssueImmediateOrderById(caster, orderId) then
        call SetAbilityOrderCooldown(instanceId, cooldown)
        return true
    endif
    return false
endfunction

public function DefaultAttackThink takes nothing returns nothing
    local unit caster = AI_EventUnit
    local unit target = AI_EventTarget
    if caster != null and target != null and IsAliveUnit(target) then
        call IssueTargetOrder(caster, "attack", target)
    endif
    set caster = null
    set target = null
endfunction

public function TemporaryAbilitySwap takes unit whichUnit, integer removeAbilityId, integer addAbilityId, integer addLevel, real duration returns boolean
    local timer restoreTimer
    local integer timerId
    local boolean addWasPresent
    if whichUnit == null or addAbilityId == 0 or duration <= 0.00 then
        return false
    endif
    set addWasPresent = GetUnitAbilityLevel(whichUnit, addAbilityId) > 0
    if removeAbilityId != 0 then
        call UnitRemoveAbility(whichUnit, removeAbilityId)
    endif
    call UnitAddAbility(whichUnit, addAbilityId)
    if addLevel > 0 then
        call SetUnitAbilityLevel(whichUnit, addAbilityId, addLevel)
    endif
    set restoreTimer = CreateTimer()
    set timerId = GetHandleId(restoreTimer)
    set TempAbilityUnit.unit[timerId] = whichUnit
    if addWasPresent then
        set TempAbilityRemove[timerId] = 0
    else
        set TempAbilityRemove[timerId] = addAbilityId
    endif
    set TempAbilityRestore[timerId] = removeAbilityId
    call TimerStart(restoreTimer, duration, false, function RestoreTemporaryAbility)
    set restoreTimer = null
    return true
endfunction

private function IsBarkLineReputationAllowed takes integer lineKey returns boolean
    local string factionName = BarkLineFaction.string[lineKey]
    local Faction faction
    local integer currentRep
    local integer minRep
    local integer maxRep

    if factionName == "" then
        return true
    endif

    set faction = Faction.getFaction(factionName)
    if faction == 0 then
        return false
    endif

    set currentRep = Reputation.getRep(Player(0), faction)
    set minRep = BarkLineMinRep[lineKey]
    set maxRep = BarkLineMaxRep[lineKey]

    if currentRep < minRep then
        return false
    endif

    if currentRep > maxRep then
        return false
    endif

    return true
endfunction

private function PickEligibleBarkLineKey takes unit speaker, integer profileId, integer barkType returns integer
    local integer barkKey
    local integer count
    local integer index
    local integer lineKey
    local integer selectedLineKey = 0
    local integer eligibleCount = 0
    if profileId <= 0 or barkType <= 0 then
        return 0
    endif
    set barkKey = GetBarkKey(profileId, barkType)
    set count = BarkLineCount[barkKey]
    if count <= 0 then
        return 0
    endif
    set index = 1
    loop
        exitwhen index > count
        set lineKey = GetBarkLineKey(barkKey, index)
        if IsBarkLineReputationAllowed(lineKey) and IsBarkTargetContextAllowed(speaker, BarkLineSound.string[lineKey]) then
            set eligibleCount = eligibleCount + 1
            if GetRandomInt(1, eligibleCount) == 1 then
                set selectedLineKey = lineKey
            endif
        endif
        set index = index + 1
    endloop
    return selectedLineKey
endfunction

private function IsCommandBarkContextAllowed takes unit speaker, integer barkType returns boolean
    if udg_InCinematic or DialogSystem_IsSequenceActive() or DialogSystem_IsDialogVisible() then
        return false
    endif
    if not IsBarkNearPlayerHero(speaker) then
        return false
    endif
    if IsCompanionOnlyBark(barkType) and not IsCompanionControlled(speaker) then
        return false
    endif
    return true
endfunction

private function QueueCommandResponseBark takes unit speaker, integer barkType returns boolean
    local integer instanceId = AI_GetInstance(speaker)
    local integer profileId
    local integer cooldownKey
    local integer lineKey
    local string text
    local string soundKey
    local real now = GetNow()
    local real duration
    if instanceId <= 0 or speaker == null or barkType <= 0 then
        return false
    endif
    if not IsAliveUnit(speaker) or not IsCommandBarkContextAllowed(speaker, barkType) then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    set lineKey = PickEligibleBarkLineKey(speaker, profileId, barkType)
    if lineKey <= 0 then
        return false
    endif
    set cooldownKey = GetInstanceBarkKey(instanceId, barkType)
    set text = BarkLineText.string[lineKey]
    set soundKey = BarkLineSound.string[lineKey]
    set duration = DialogSystem_EstimateFieldLineDuration(text)
    set udg_CompanionDialogueActive = true
    call DialogSystem_QueueFieldLine(speaker, "", soundKey, text)
    set InstanceNextChat.real[instanceId] = now + duration + AI_DIALOG_UNLOCK_PAD
    set InstanceNextBark.real[cooldownKey] = now + GetBarkCooldown(barkType)
    set NextGlobalBark = now + duration + AI_BARK_GLOBAL_GAP
    call StartDialogUnlock(duration + AI_DIALOG_UNLOCK_PAD)
    return true
endfunction

public function RequestBark takes unit speaker, integer barkType returns boolean
    local integer instanceId = AI_GetInstance(speaker)
    local integer profileId
    local integer cooldownKey
    local integer lineKey
    local string text
    local string soundKey
    local real now = GetNow()
    local real duration
    local boolean replyScheduled
    if instanceId <= 0 or speaker == null or barkType <= 0 then
        return false
    endif
    if not IsAliveUnit(speaker) or udg_CompanionDialogueActive then
        return false
    endif
    if IsDialogBlockingBark() or not IsBarkContextAllowed(speaker, barkType) then
        return false
    endif
    set cooldownKey = GetInstanceBarkKey(instanceId, barkType)
    if now < NextGlobalBark or now < InstanceNextChat.real[instanceId] or now < InstanceNextBark.real[cooldownKey] then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    set lineKey = PickEligibleBarkLineKey(speaker, profileId, barkType)
    if lineKey <= 0 then
        return false
    endif
    set text = BarkLineText.string[lineKey]
    set soundKey = BarkLineSound.string[lineKey]
    set udg_CompanionDialogueActive = true
    call DialogSystem_PlayLine(speaker, "", text, soundKey, true)
    set duration = udg_ExSoundDuration
    if duration <= 0.00 then
        set duration = EstimateDialogDuration(text)
    endif
    set InstanceNextChat.real[instanceId] = now + duration + AI_DIALOG_UNLOCK_PAD
    set InstanceNextBark.real[cooldownKey] = now + GetBarkCooldown(barkType)
    set NextGlobalBark = now + duration + AI_BARK_GLOBAL_GAP
    set replyScheduled = ScheduleBarkReply(speaker, soundKey, duration)
    if not replyScheduled then
        call StartDialogUnlock(duration + AI_DIALOG_UNLOCK_PAD)
    endif
    return true
endfunction

public function SetDebugMode takes boolean enabled returns nothing
    set DebugMode = enabled
    call RefreshDebugIcons()
endfunction

public function IsDebugMode takes nothing returns boolean
    return DebugMode
endfunction

private function ClearSocialState takes integer instanceId returns nothing
    if instanceId <= 0 then
        return
    endif
    set InstanceSocialTarget[instanceId] = null
    set InstanceSocialStopped[instanceId] = false
    call InstanceSocialUntil.remove(instanceId)
endfunction

public function SetBossFightActive takes boolean active returns nothing
    set BossFightActive = active
endfunction

public function IsBossFightActive takes nothing returns boolean
    return BossFightActive
endfunction

public function RegisterBossCastAbility takes integer abilityId, real evadeRadius, real evadeDistance returns nothing
    if abilityId == 0 or BossCastCount >= MAX_BOSS_CASTS then
        return
    endif
    set BossCastCount = BossCastCount + 1
    set BossCastAbility[BossCastCount] = abilityId
    set BossCastRadius[BossCastCount] = evadeRadius
    set BossCastDistance[BossCastCount] = evadeDistance
endfunction

public function HandleBossCast takes unit caster, integer abilityId, real targetX, real targetY returns nothing
    local integer castIndex = 1
    local integer activeIndex
    local integer instanceId
    local unit whichUnit
    local real originX
    local real originY
    local real dx
    local real dy
    if abilityId == 0 then
        return
    endif
    loop
        exitwhen castIndex > BossCastCount
        if BossCastAbility[castIndex] == abilityId then
            if targetX == 0.00 and targetY == 0.00 and caster != null then
                set originX = GetUnitX(caster)
                set originY = GetUnitY(caster)
            else
                set originX = targetX
                set originY = targetY
            endif
            set activeIndex = 1
            loop
                exitwhen activeIndex > ActiveCount
                set instanceId = ActiveInstances[activeIndex]
                set whichUnit = InstanceUnit.unit[instanceId]
                if whichUnit != null and IsAliveUnit(whichUnit) and not InstanceTraveling.boolean[instanceId] then
                    set dx = GetUnitX(whichUnit) - originX
                    set dy = GetUnitY(whichUnit) - originY
                    if dx * dx + dy * dy <= BossCastRadius[castIndex] * BossCastRadius[castIndex] then
                        call ClearSocialState(instanceId)
                        call SetInstanceState(instanceId, AI_STATE_BOSS_EVADE)
                        set InstanceRetreatUntil.real[instanceId] = GetNow() + AI_BOSS_EVADE_TIME
                        call MoveAwayFromPoint(whichUnit, originX, originY, BossCastDistance[castIndex])
                    endif
                endif
                set activeIndex = activeIndex + 1
            endloop
            set whichUnit = null
            return
        endif
        set castIndex = castIndex + 1
    endloop
    set whichUnit = null
endfunction

public function StartTravel takes unit whichUnit, real duration, real returnX, real returnY returns nothing
    local integer instanceId = AI_GetInstance(whichUnit)
    local integer profileId
    if instanceId <= 0 or whichUnit == null or duration <= 0.00 or InstanceHiddenByCap.boolean[instanceId] then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    if IsCompanionControlled(whichUnit) and not ProfileAllowCompanionTravel.boolean[profileId] then
        return
    endif
    call RemoveInstanceFromAiParty(instanceId)
    set InstanceTraveling.boolean[instanceId] = true
    set InstanceTravelReturnAt.real[instanceId] = GetNow() + duration
    set InstanceTravelReturnX.real[instanceId] = returnX
    set InstanceTravelReturnY.real[instanceId] = returnY
    call RemoveTrackedProfessionTool(instanceId)
    call ClearSocialState(instanceId)
    call SetInstanceState(instanceId, AI_STATE_TRAVEL)
    call IssueImmediateOrder(whichUnit, "stop")
    call PauseUnit(whichUnit, true)
    call ShowUnit(whichUnit, false)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " started travel for " + R2S(duration) + " seconds.")
endfunction

public function ReturnFromTravel takes unit whichUnit returns nothing
    local integer instanceId = AI_GetInstance(whichUnit)
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    call CompleteTravel(instanceId, whichUnit)
endfunction

private function PickRandomTravelReturnPoint takes integer instanceId returns nothing
    local integer profileId = InstanceProfile[instanceId]
    local integer count = ProfileSpawnCount[profileId]
    local integer index
    local integer key
    if count > 0 then
        set index = GetRandomInt(1, count)
        set key = GetPointKey(profileId, index)
        set RandomPointX = ProfileSpawnX.real[key]
        set RandomPointY = ProfileSpawnY.real[key]
    else
        set RandomPointX = InstanceHomeX.real[instanceId]
        set RandomPointY = InstanceHomeY.real[instanceId]
    endif
endfunction

private function StartRandomManagedTravel takes integer instanceId returns boolean
    local unit whichUnit
    if instanceId <= 0 or InstanceTraveling.boolean[instanceId] or InstanceHiddenByCap.boolean[instanceId] then
        return false
    endif
    set whichUnit = InstanceUnit.unit[instanceId]
    if whichUnit == null or not IsAliveUnit(whichUnit) or IsCompanionControlled(whichUnit) then
        set whichUnit = null
        return false
    endif
    call PickRandomTravelReturnPoint(instanceId)
    call AI_StartTravel(whichUnit, GetRandomReal(AI_RANDOM_TRAVEL_DURATION_MIN, AI_RANDOM_TRAVEL_DURATION_MAX), RandomPointX, RandomPointY)
    set whichUnit = null
    return InstanceTraveling.boolean[instanceId]
endfunction

private function MaintainRandomActiveMinimum takes boolean showDebug returns boolean
    local integer guard = 0
    local unit spawned = null
    local boolean changed = false
    if not RandomSpawnEnabled or RandomSpawnActiveMin <= 0 then
        return false
    endif
    loop
        exitwhen CountRandomManagedVisible() >= RandomSpawnActiveMin or guard >= RandomSpawnActiveMin
        if TryUnhideRandomManaged(showDebug) then
            set changed = true
        else
            set spawned = AI_SpawnRandomHero(showDebug)
            if spawned == null then
                set spawned = null
                return changed
            endif
            set changed = true
        endif
        set guard = guard + 1
    endloop
    if changed then
        call DebugMsg("Random active minimum maintained: visible=" + I2S(CountRandomManagedVisible()) + " min=" + I2S(RandomSpawnActiveMin) + " cap=" + I2S(RandomSpawnActiveCap) + ".")
    endif
    set spawned = null
    return changed
endfunction

private function RandomSpawnTimerAction takes nothing returns nothing
    local unit spawned = null
    local boolean maintained = false
    if RandomSpawnEnabled then
        set maintained = MaintainRandomActiveMinimum(false)
        if not maintained then
            set spawned = AI_SpawnRandomHero(false)
        endif
    endif
    set spawned = null
    call TimerStart(RandomSpawnTimer, GetRandomReal(AI_RANDOM_SPAWN_MIN, AI_RANDOM_SPAWN_MAX), false, function RandomSpawnTimerAction)
endfunction

private function RandomTravelTimerAction takes nothing returns nothing
    local integer instanceId
    local boolean started = false
    if RandomTravelEnabled then
        set started = TryUnhideRandomManaged(false)
        if GetRandomInt(1, 2) == 1 then
            set instanceId = GetRandomTravelInstance()
            if instanceId > 0 then
                set started = StartRandomManagedTravel(instanceId)
            endif
        endif
    endif
    call TimerStart(RandomTravelTimer, GetRandomReal(AI_RANDOM_TRAVEL_MIN, AI_RANDOM_TRAVEL_MAX), false, function RandomTravelTimerAction)
endfunction

private function DebugSpawnAction takes nothing returns nothing
    local unit spawned = AI_SpawnRandomHero(true)
    set spawned = null
endfunction

private function DebugModeAction takes nothing returns nothing
    call AI_SetDebugMode(not DebugMode)
    if DebugMode then
        call BJDebugMsg("[AI] Debug mode enabled.")
    else
        call BJDebugMsg("[AI] Debug mode disabled.")
    endif
endfunction

private function IsSideActionState takes integer state returns boolean
    return state == AI_STATE_IDLE or state == AI_STATE_WANDER
endfunction

private function HasNearbyCombatEnemy takes unit source, real range returns boolean
    local boolean result
    call EnsureState()
    if source == null or range <= 0.00 then
        return false
    endif
    call GroupClear(TempGroup)
    set CombatSearchSource = source
    set CombatSearchFound = false
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(source), GetUnitY(source), range, null)
    call ForGroup(TempGroup, function CombatEnemyEnum)
    call GroupClear(TempGroup)
    set result = CombatSearchFound
    set CombatSearchSource = null
    set CombatSearchFound = false
    return result
endfunction

private function IsShopActionCandidate takes integer instanceId, unit whichUnit, integer state, boolean requireNoOrder returns boolean
    if instanceId <= 0 or whichUnit == null or udg_InCinematic then
        return false
    endif
    if not IsSideActionState(state) or IsCompanionControlled(whichUnit) or ProfileAutonomousDisabled.boolean[InstanceProfile[instanceId]] then
        return false
    endif
    if ProfileShopCount[InstanceProfile[instanceId]] <= 0 or IsCastingLocked(whichUnit) or HasNearbyCombatEnemy(whichUnit, 900.00) then
        return false
    endif
    if requireNoOrder and GetUnitCurrentOrder(whichUnit) != 0 then
        return false
    endif
    return true
endfunction

private function TryBeginShopBuy takes integer instanceId, unit whichUnit, real now returns boolean
    local integer profileId
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set profileId = InstanceProfile[instanceId]
    if ProfileShopItemCount[profileId] <= 0 then
        static if LIBRARY_Shop then
            if BeginBuyState(instanceId, whichUnit) then
                set InstanceNextShop.real[instanceId] = now + GetRandomReal(AI_SHOP_COOLDOWN_MIN, AI_SHOP_COOLDOWN_MAX)
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts PotS shop buy.")
                return true
            endif
        endif
        return false
    endif
    if GetFreeInventorySlots(whichUnit) <= 0 then
        return false
    endif
    if BeginBuyState(instanceId, whichUnit) then
        set InstanceNextShop.real[instanceId] = now + GetRandomReal(AI_SHOP_COOLDOWN_MIN, AI_SHOP_COOLDOWN_MAX)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts shop buy.")
        return true
    endif
    return false
endfunction

private function TryBeginShopSell takes integer instanceId, unit whichUnit, real now returns boolean
    if instanceId <= 0 or whichUnit == null or UnitInventorySize(whichUnit) <= 0 or IsInventoryEmpty(whichUnit) then
        static if LIBRARY_Shop then
            if instanceId > 0 and whichUnit != null and BeginSellState(instanceId, whichUnit) then
                set InstanceNextShop.real[instanceId] = now + GetRandomReal(AI_SHOP_COOLDOWN_MIN, AI_SHOP_COOLDOWN_MAX)
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts PotS shop sell.")
                return true
            endif
        endif
        return false
    endif
    if BeginSellState(instanceId, whichUnit) then
        set InstanceNextShop.real[instanceId] = now + GetRandomReal(AI_SHOP_COOLDOWN_MIN, AI_SHOP_COOLDOWN_MAX)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts shop sell.")
        return true
    endif
    return false
endfunction

private function TryStartShopAction takes integer instanceId, unit whichUnit, integer state, real now returns boolean
    if not IsShopActionCandidate(instanceId, whichUnit, state, true) or now < InstanceNextShop.real[instanceId] then
        return false
    endif
    set InstanceNextShop.real[instanceId] = now + GetRandomReal(AI_SHOP_CHECK_MIN, AI_SHOP_CHECK_MAX)
    if IsInventoryFull(whichUnit) then
        return TryBeginShopSell(instanceId, whichUnit, now)
    endif
    if IsInventoryEmpty(whichUnit) and GetRandomInt(1, 100) <= AI_SHOP_EMPTY_BUY_CHANCE then
        return TryBeginShopBuy(instanceId, whichUnit, now)
    endif
    return false
endfunction

public function DebugForceShopBuy takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer started = 0
    local real now = GetNow()
    local unit whichUnit
    call EnsureState()
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        if IsShopActionCandidate(instanceId, whichUnit, InstanceState[instanceId], false) then
            if TryBeginShopBuy(instanceId, whichUnit, now) then
                set started = started + 1
            endif
        endif
        set whichUnit = null
        set index = index + 1
    endloop
    call BJDebugMsg("[AI] Forced shop buy for " + I2S(started) + " AI units.")
    return started
endfunction

public function DebugForceShopSell takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer started = 0
    local real now = GetNow()
    local unit whichUnit
    call EnsureState()
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        if IsShopActionCandidate(instanceId, whichUnit, InstanceState[instanceId], false) then
            if TryBeginShopSell(instanceId, whichUnit, now) then
                set started = started + 1
            endif
        endif
        set whichUnit = null
        set index = index + 1
    endloop
    call BJDebugMsg("[AI] Forced shop sell for " + I2S(started) + " AI units.")
    return started
endfunction

public function DebugForceShopByInventory takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer started = 0
    local real now = GetNow()
    local unit whichUnit
    call EnsureState()
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        if IsShopActionCandidate(instanceId, whichUnit, InstanceState[instanceId], false) then
            if IsInventoryFull(whichUnit) then
                if TryBeginShopSell(instanceId, whichUnit, now) then
                    set started = started + 1
                endif
            elseif IsInventoryEmpty(whichUnit) then
                if TryBeginShopBuy(instanceId, whichUnit, now) then
                    set started = started + 1
                endif
            endif
        endif
        set whichUnit = null
        set index = index + 1
    endloop
    call BJDebugMsg("[AI] Forced shop inventory check for " + I2S(started) + " AI units.")
    return started
endfunction

private function DebugShopAction takes nothing returns nothing
    local string msg = StringCase(GetEventPlayerChatString(), false)
    local integer started = 0
    if msg == "/debug aibuy" or msg == "aibuy" then
        set started = AI_DebugForceShopBuy()
    elseif msg == "/debug aisell" or msg == "aisell" then
        set started = AI_DebugForceShopSell()
    else
        set started = AI_DebugForceShopByInventory()
    endif
    set started = 0
endfunction

private function IsAiPartyOrganizeState takes integer state returns boolean
    return state == AI_STATE_IDLE or state == AI_STATE_WANDER or state == AI_STATE_SOCIAL
endfunction

private function IsAiPartyCandidate takes integer instanceId, unit whichUnit returns boolean
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    if IsAiPartyMember(instanceId) or not IsRandomManagedVisible(instanceId) or not IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return false
    endif
    if not IsAiPartyOrganizeState(InstanceState[instanceId]) or ProfileAutonomousDisabled.boolean[InstanceProfile[instanceId]] then
        return false
    endif
    return not HasNearbyCombatEnemy(whichUnit, 700.00)
endfunction

private function AddAiPartyMember takes integer leaderId, integer memberId returns nothing
    local integer count
    if leaderId <= 0 or memberId <= 0 or InstanceAiPartyLeader[memberId] > 0 then
        return
    endif
    if InstanceAiPartyLeader[leaderId] <= 0 then
        set InstanceAiPartyLeader[leaderId] = leaderId
        set InstanceAiPartyFollowerCount[leaderId] = 0
    endif
    set InstanceAiPartyLeader[memberId] = leaderId
    if memberId != leaderId then
        set count = InstanceAiPartyFollowerCount[leaderId] + 1
        set InstanceAiPartyFollowerCount[leaderId] = count
        call ClearSocialState(memberId)
        call SetInstanceState(memberId, AI_STATE_IDLE)
    endif
endfunction

private function TryCreateAiPartyForLeader takes integer leaderId returns boolean
    local integer index = 1
    local integer memberId
    local integer added = 1
    local unit leader = InstanceUnit.unit[leaderId]
    local unit member
    local real dx
    local real dy
    if not IsAiPartyCandidate(leaderId, leader) then
        set leader = null
        set member = null
        return false
    endif
    call AddAiPartyMember(leaderId, leaderId)
    loop
        exitwhen index > ActiveCount or added >= AI_PARTY_MAX_SIZE
        set memberId = ActiveInstances[index]
        if memberId != leaderId then
            set member = InstanceUnit.unit[memberId]
            if IsAiPartyCandidate(memberId, member) and IsUnitAlly(member, GetOwningPlayer(leader)) then
                set dx = GetUnitX(member) - GetUnitX(leader)
                set dy = GetUnitY(member) - GetUnitY(leader)
                if dx * dx + dy * dy <= AI_PARTY_SCAN_RANGE * AI_PARTY_SCAN_RANGE and GetRandomInt(1, 100) <= 50 then
                    call AddAiPartyMember(leaderId, memberId)
                    set added = added + 1
                endif
            endif
        endif
        set index = index + 1
    endloop
    if added <= 1 then
        call RemoveInstanceFromAiParty(leaderId)
        set leader = null
        set member = null
        return false
    endif
    call DebugMsg(GetDebugInstanceName(leaderId, leader) + " organized an AI companion party of " + I2S(added) + ".")
    set leader = null
    set member = null
    return true
endfunction

private function TryOrganizeAiParty takes real now returns nothing
    local integer index = 1
    local integer instanceId
    local integer selected = 0
    local integer seen = 0
    local unit whichUnit
    if now < NextAiPartyOrganize then
        return
    endif
    set NextAiPartyOrganize = now + GetRandomReal(AI_PARTY_ORGANIZE_MIN, AI_PARTY_ORGANIZE_MAX)
    if GetRandomInt(1, 100) > 45 then
        return
    endif
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        if IsAiPartyCandidate(instanceId, whichUnit) then
            set seen = seen + 1
            if GetRandomInt(1, seen) == 1 then
                set selected = instanceId
            endif
        endif
        set index = index + 1
    endloop
    if selected > 0 then
        call TryCreateAiPartyForLeader(selected)
    endif
    set whichUnit = null
endfunction

private function CanGatherProfession takes unit whichUnit, integer profileId, integer professionId, integer requiredSkill returns boolean
    if whichUnit == null or professionId <= AI_PROFESSION_NONE then
        return false
    endif
    if not HasProfileProfession(profileId, professionId) then
        return false
    endif
    return GNS_GetEffectiveSkill(whichUnit, professionId) >= requiredSkill
endfunction

private function GetIgnoredGatherNodeKey takes integer instanceId, integer nodeHandleId returns integer
    return StringHash(I2S(instanceId) + ":" + I2S(nodeHandleId))
endfunction

private function IsLowSkillIgnoredGatherUnit takes integer instanceId, unit whichUnit, unit node, integer professionId, integer requiredSkill returns boolean
    local integer key

    if instanceId <= 0 or whichUnit == null or node == null or professionId <= AI_PROFESSION_NONE then
        return false
    endif

    call EnsureState()
    set key = GetIgnoredGatherNodeKey(instanceId, GetHandleId(node))
    if InstanceIgnoredGatherUnit.has(key) then
        if not HasProfileProfession(InstanceProfile[instanceId], professionId) or GNS_GetEffectiveSkill(whichUnit, professionId) < requiredSkill then
            return true
        endif
        call InstanceIgnoredGatherUnit.remove(key)
    endif

    return false
endfunction

private function IsLowSkillIgnoredGatherItem takes integer instanceId, unit whichUnit, item nodeItem, integer professionId, integer requiredSkill returns boolean
    local integer key

    if instanceId <= 0 or whichUnit == null or nodeItem == null or professionId <= AI_PROFESSION_NONE then
        return false
    endif

    call EnsureState()
    set key = GetIgnoredGatherNodeKey(instanceId, GetHandleId(nodeItem))
    if InstanceIgnoredGatherItem.has(key) then
        if not HasProfileProfession(InstanceProfile[instanceId], professionId) or GNS_GetEffectiveSkill(whichUnit, professionId) < requiredSkill then
            return true
        endif
        call InstanceIgnoredGatherItem.remove(key)
    endif

    return false
endfunction

private function MarkLowSkillIgnoredGatherUnit takes integer instanceId, unit whichUnit, unit node, integer professionId, integer requiredSkill returns nothing
    local integer key
    local integer currentSkill

    if instanceId <= 0 or whichUnit == null or node == null or professionId <= AI_PROFESSION_NONE then
        return
    endif

    set currentSkill = GNS_GetEffectiveSkill(whichUnit, professionId)
    if HasProfileProfession(InstanceProfile[instanceId], professionId) and currentSkill >= requiredSkill then
        return
    endif

    call EnsureState()
    set key = GetIgnoredGatherNodeKey(instanceId, GetHandleId(node))
    if not InstanceIgnoredGatherUnit.has(key) then
        if HasProfileProfession(InstanceProfile[instanceId], professionId) then
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " ignores " + GN_GetGatherUnitName(node) + " until " + GNS_GetProfessionName(professionId) + " " + I2S(requiredSkill) + ".")
        else
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " ignores " + GN_GetGatherUnitName(node) + " because it does not know " + GNS_GetProfessionName(professionId) + ".")
        endif
    endif
    set InstanceIgnoredGatherUnit[key] = requiredSkill
endfunction

private function MarkLowSkillIgnoredGatherItem takes integer instanceId, unit whichUnit, item nodeItem, integer professionId, integer requiredSkill returns nothing
    local integer key
    local integer currentSkill

    if instanceId <= 0 or whichUnit == null or nodeItem == null or professionId <= AI_PROFESSION_NONE then
        return
    endif

    set currentSkill = GNS_GetEffectiveSkill(whichUnit, professionId)
    if HasProfileProfession(InstanceProfile[instanceId], professionId) and currentSkill >= requiredSkill then
        return
    endif

    call EnsureState()
    set key = GetIgnoredGatherNodeKey(instanceId, GetHandleId(nodeItem))
    if not InstanceIgnoredGatherItem.has(key) then
        if HasProfileProfession(InstanceProfile[instanceId], professionId) then
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " ignores " + GN_GetGatherItemName(nodeItem) + " until " + GNS_GetProfessionName(professionId) + " " + I2S(requiredSkill) + ".")
        else
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " ignores " + GN_GetGatherItemName(nodeItem) + " because it does not know " + GNS_GetProfessionName(professionId) + ".")
        endif
    endif
    set InstanceIgnoredGatherItem[key] = requiredSkill
endfunction

private function CanHoldGatherItem takes integer instanceId, unit whichUnit, integer professionId returns boolean
    local integer freeSlots
    local integer toolId
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set freeSlots = GetFreeInventorySlots(whichUnit)
    if freeSlots <= 0 then
        return false
    endif
    set toolId = GetProfessionToolId(professionId)
    if toolId != 0 and not UnitHasItemType(whichUnit, toolId) and freeSlots < 2 then
        return false
    endif
    return true
endfunction

private function ResetProfessionFailure takes integer instanceId returns nothing
    if instanceId > 0 then
        set InstanceProfessionFailCount[instanceId] = 0
        call InstanceProfessionBlockedUntil.remove(instanceId)
    endif
endfunction

private function StopProfessionOrder takes unit whichUnit returns nothing
    if whichUnit == null then
        return
    endif
    call PauseUnit(whichUnit, true)
    call PauseUnit(whichUnit, false)
    call IssueImmediateOrder(whichUnit, "stop")
endfunction

private function RequestProfessionFailureBark takes unit whichUnit returns nothing
    if whichUnit != null and IsCompanionControlled(whichUnit) and IsBarkNearPlayerHero(whichUnit) then
        call AI_RequestBark(whichUnit, AI_BARK_IDLE)
    endif
endfunction

private function BackoffProfessionWork takes integer instanceId, unit whichUnit, real now, string reason returns nothing
    local real blockedUntil
    call StopProfessionOrder(whichUnit)
    if instanceId <= 0 then
        return
    endif
    set blockedUntil = now + GetRandomReal(AI_PROFESSION_FAIL_BACKOFF_MIN, AI_PROFESSION_FAIL_BACKOFF_MAX)
    set InstanceProfessionFailCount[instanceId] = 0
    set InstanceProfessionBlockedUntil.real[instanceId] = blockedUntil
    set InstanceNextProfession.real[instanceId] = blockedUntil
    if InstanceState[instanceId] == AI_STATE_WANDER then
        call SetInstanceState(instanceId, AI_STATE_IDLE)
    endif
    call RemoveTrackedProfessionTool(instanceId)
    if whichUnit != null then
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " pauses profession work: " + reason + ".")
        call RequestProfessionFailureBark(whichUnit)
    endif
endfunction

private function RegisterProfessionFailure takes integer instanceId, unit whichUnit, real now, string reason returns nothing
    local integer failCount
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set failCount = InstanceProfessionFailCount[instanceId] + 1
    set InstanceProfessionFailCount[instanceId] = failCount
    if failCount >= AI_PROFESSION_FAIL_LIMIT then
        call BackoffProfessionWork(instanceId, whichUnit, now, reason)
    else
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(6.00, 12.00)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " profession attempt failed (" + reason + "), retry " + I2S(failCount) + "/" + I2S(AI_PROFESSION_FAIL_LIMIT) + ".")
    endif
endfunction

private function FindNearbyProfessionItem takes integer instanceId, unit whichUnit, real range returns item
    local integer profileId
    local integer count
    local integer index = 0
    local item nodeItem
    local integer professionId
    local integer requiredSkill
    local real dx
    local real dy
    local real distance
    local real bestDistance
    set ProfessionSearchItem = null
    if instanceId <= 0 or whichUnit == null then
        return null
    endif
    set profileId = InstanceProfile[instanceId]
    set count = GN_GetActiveItemCount()
    set bestDistance = range * range
    loop
        exitwhen index >= count
        set nodeItem = GN_GetActiveItemByIndex(index)
        if nodeItem != null and GN_IsGatherItem(nodeItem) then
            set professionId = GN_GetGatherItemProfessionId(nodeItem)
            set requiredSkill = GN_GetGatherItemSkillRequired(nodeItem)
            if not IsLowSkillIgnoredGatherItem(instanceId, whichUnit, nodeItem, professionId, requiredSkill) and CanGatherProfession(whichUnit, profileId, professionId, requiredSkill) and CanHoldGatherItem(instanceId, whichUnit, professionId) then
                set dx = GetItemX(nodeItem) - GetUnitX(whichUnit)
                set dy = GetItemY(nodeItem) - GetUnitY(whichUnit)
                set distance = dx * dx + dy * dy
                if distance <= bestDistance then
                    set bestDistance = distance
                    set ProfessionSearchItem = nodeItem
                endif
            endif
        endif
        set index = index + 1
    endloop
    set nodeItem = null
    return ProfessionSearchItem
endfunction

private function FindNearbyProfessionUnit takes integer instanceId, unit whichUnit, real range returns unit
    local integer profileId
    local integer count
    local integer index = 0
    local unit node
    local integer professionId
    local integer requiredSkill
    local real dx
    local real dy
    local real distance
    local real bestDistance
    set ProfessionSearchUnit = null
    if instanceId <= 0 or whichUnit == null then
        return null
    endif
    set profileId = InstanceProfile[instanceId]
    set count = GN_GetActiveUnitCount()
    set bestDistance = range * range
    loop
        exitwhen index >= count
        set node = GN_GetActiveUnitByIndex(index)
        if node != null and GN_IsGatherUnit(node) and IsAliveUnit(node) then
            set professionId = GN_GetGatherUnitProfessionId(node)
            set requiredSkill = GN_GetGatherUnitSkillRequired(node)
            if professionId == AI_PROFESSION_MINING and not IsLowSkillIgnoredGatherUnit(instanceId, whichUnit, node, professionId, requiredSkill) and CanGatherProfession(whichUnit, profileId, professionId, requiredSkill) and CanHoldGatherItem(instanceId, whichUnit, professionId) then
                set dx = GetUnitX(node) - GetUnitX(whichUnit)
                set dy = GetUnitY(node) - GetUnitY(whichUnit)
                set distance = dx * dx + dy * dy
                if distance <= bestDistance then
                    set bestDistance = distance
                    set ProfessionSearchUnit = node
                endif
            endif
        endif
        set index = index + 1
    endloop
    set node = null
    return ProfessionSearchUnit
endfunction

private function FindNearbyCraftStationEnum takes nothing returns nothing
    local unit station = GetEnumUnit()
    local integer professionId
    local integer recipeId
    local real dx
    local real dy
    local real distance

    if station != null and station != ProfessionSearchSource and IsAliveUnit(station) and Professions_IsStationUnit(station) and not Professions_IsStationReserved(station) then
        set professionId = Professions_GetStationProfession(station)
        if HasProfileProfession(ProfessionSearchProfileId, professionId) and (ProfessionSearchWantedProfession <= AI_PROFESSION_NONE or professionId == ProfessionSearchWantedProfession) then
            set recipeId = Professions_GetAiRecipeForStation(ProfessionSearchSource, station)
            if recipeId > 0 then
                set dx = GetUnitX(station) - GetUnitX(ProfessionSearchSource)
                set dy = GetUnitY(station) - GetUnitY(ProfessionSearchSource)
                set distance = dx * dx + dy * dy
                if distance <= ProfessionSearchBestDistance then
                    set ProfessionSearchBestDistance = distance
                    set ProfessionSearchStation = station
                endif
            endif
        endif
    endif

    set station = null
endfunction

private function FindNearbyCraftStationForProfession takes integer instanceId, unit whichUnit, real range, integer wantedProfession returns unit
    if instanceId <= 0 or whichUnit == null or Professions_IsUnitReserved(whichUnit) then
        return null
    endif

    set ProfessionSearchStation = null
    set ProfessionSearchSource = whichUnit
    set ProfessionSearchProfileId = InstanceProfile[instanceId]
    set ProfessionSearchWantedProfession = wantedProfession
    set ProfessionSearchBestDistance = range * range

    call GroupClear(TempGroup)
    call GroupEnumUnitsInRange(TempGroup, GetUnitX(whichUnit), GetUnitY(whichUnit), range, null)
    call ForGroup(TempGroup, function FindNearbyCraftStationEnum)
    call GroupClear(TempGroup)

    set ProfessionSearchSource = null
    set ProfessionSearchProfileId = 0
    set ProfessionSearchWantedProfession = 0
    return ProfessionSearchStation
endfunction

private function FindNearbyCraftStation takes integer instanceId, unit whichUnit, real range returns unit
    return FindNearbyCraftStationForProfession(instanceId, whichUnit, range, AI_PROFESSION_NONE)
endfunction

private function BeginGatherItem takes integer instanceId, unit whichUnit, item nodeItem, real now returns boolean
    local integer professionId
    local integer requiredSkill
    local integer toolId
    if instanceId <= 0 or whichUnit == null or nodeItem == null then
        return false
    endif
    set professionId = GN_GetGatherItemProfessionId(nodeItem)
    set requiredSkill = GN_GetGatherItemSkillRequired(nodeItem)
    set toolId = GetProfessionToolId(professionId)
    if not CanGatherProfession(whichUnit, InstanceProfile[instanceId], professionId, requiredSkill) then
        call MarkLowSkillIgnoredGatherItem(instanceId, whichUnit, nodeItem, professionId, requiredSkill)
        call BackoffProfessionWork(instanceId, whichUnit, now, "profession skill too low")
        return false
    endif
    if not CanHoldGatherItem(instanceId, whichUnit, professionId) then
        call RegisterProfessionFailure(instanceId, whichUnit, now, "inventory or tool space blocked")
        return false
    endif
    if not EnsureProfessionTool(instanceId, whichUnit, toolId, now) then
        call RegisterProfessionFailure(instanceId, whichUnit, now, "profession tool unavailable")
        return false
    endif
    if IssueTargetOrder(whichUnit, "smart", nodeItem) then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_ACTION_MIN, AI_PROFESSION_ACTION_MAX)
        call ResetProfessionFailure(instanceId)
        call SetTrackedProfessionToolCleanup(instanceId, now)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " gathers " + GN_GetGatherItemName(nodeItem) + ".")
        return true
    endif
    call RegisterProfessionFailure(instanceId, whichUnit, now, "gather order rejected")
    return false
endfunction

private function BeginGatherUnit takes integer instanceId, unit whichUnit, unit node, real now returns boolean
    local integer professionId
    local integer requiredSkill
    if instanceId <= 0 or whichUnit == null or node == null then
        return false
    endif
    set professionId = GN_GetGatherUnitProfessionId(node)
    if professionId != AI_PROFESSION_MINING then
        return false
    endif
    set requiredSkill = GN_GetGatherUnitSkillRequired(node)
    if not CanGatherProfession(whichUnit, InstanceProfile[instanceId], professionId, requiredSkill) then
        call MarkLowSkillIgnoredGatherUnit(instanceId, whichUnit, node, professionId, requiredSkill)
        call BackoffProfessionWork(instanceId, whichUnit, now, "mining skill too low")
        return false
    endif
    if not CanHoldGatherItem(instanceId, whichUnit, professionId) then
        call RegisterProfessionFailure(instanceId, whichUnit, now, "inventory or mining pick space blocked")
        return false
    endif
    if not EnsureProfessionTool(instanceId, whichUnit, ITEM_MINING_PICK, now) then
        call RegisterProfessionFailure(instanceId, whichUnit, now, "mining pick unavailable")
        return false
    endif
    if IssueTargetOrder(whichUnit, "attack", node) then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_ACTION_MIN, AI_PROFESSION_ACTION_MAX)
        call ResetProfessionFailure(instanceId)
        call SetTrackedProfessionToolTargetUnit(instanceId, node, now)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " mines " + GN_GetGatherUnitName(node) + ".")
        return true
    endif
    call RegisterProfessionFailure(instanceId, whichUnit, now, "mining order rejected")
    return false
endfunction

private function BeginCraftStation takes integer instanceId, unit whichUnit, unit station, real now returns boolean
    local integer recipeId

    if instanceId <= 0 or whichUnit == null or station == null then
        return false
    endif

    set recipeId = Professions_GetAiRecipeForStation(whichUnit, station)
    if recipeId <= 0 then
        call RegisterProfessionFailure(instanceId, whichUnit, now, "no craftable recipe")
        return false
    endif

    if Professions_StartRecipeForAi(whichUnit, station, recipeId) then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_ACTION_MIN, AI_PROFESSION_ACTION_MAX)
        call ResetProfessionFailure(instanceId)
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " crafts " + Professions_GetRecipeName(recipeId) + ".")
        return true
    endif

    call RegisterProfessionFailure(instanceId, whichUnit, now, "craft order rejected")
    return false
endfunction

private function TryStartProfessionAction takes integer instanceId, unit whichUnit, integer state, real now, boolean useIdleRoll returns boolean
    local unit node
    local unit station
    local item nodeItem
    if instanceId <= 0 or whichUnit == null or udg_InCinematic or ProfileProfessionCount[InstanceProfile[instanceId]] <= 0 then
        return false
    endif
    if not IsSideActionState(state) or now < InstanceNextProfession.real[instanceId] or now < InstanceProfessionBlockedUntil.real[instanceId] or IsCastingLocked(whichUnit) then
        return false
    endif
    if Professions_IsUnitReserved(whichUnit) then
        return false
    endif
    if HasNearbyCombatEnemy(whichUnit, 700.00) then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(5.00, 10.00)
        return false
    endif
    if useIdleRoll and GetRandomInt(1, 100) > 35 then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_IDLE_MIN, AI_PROFESSION_IDLE_MAX)
        return false
    endif
    if not TryUseSideScanBudget(now) then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(3.00, 8.00)
        return false
    endif
    set node = FindNearbyProfessionUnit(instanceId, whichUnit, AI_PROFESSION_SCAN_RANGE)
    if node != null then
        if BeginGatherUnit(instanceId, whichUnit, node, now) then
            set node = null
            set station = null
            set ProfessionSearchUnit = null
            set ProfessionSearchStation = null
            return true
        elseif now < InstanceProfessionBlockedUntil.real[instanceId] then
            set node = null
            set station = null
            set ProfessionSearchUnit = null
            set ProfessionSearchItem = null
            set ProfessionSearchStation = null
            return false
        endif
    endif
    set nodeItem = FindNearbyProfessionItem(instanceId, whichUnit, AI_PROFESSION_SCAN_RANGE)
    if nodeItem != null then
        if BeginGatherItem(instanceId, whichUnit, nodeItem, now) then
            set node = null
            set nodeItem = null
            set station = null
            set ProfessionSearchUnit = null
            set ProfessionSearchItem = null
            set ProfessionSearchStation = null
            return true
        elseif now < InstanceProfessionBlockedUntil.real[instanceId] then
            set node = null
            set nodeItem = null
            set station = null
            set ProfessionSearchUnit = null
            set ProfessionSearchItem = null
            set ProfessionSearchStation = null
            return false
        endif
    endif
    if GetRandomInt(1, 100) <= AI_PROFESSION_CRAFT_CHANCE then
        set station = FindNearbyCraftStation(instanceId, whichUnit, AI_PROFESSION_SCAN_RANGE)
        if station != null then
            if BeginCraftStation(instanceId, whichUnit, station, now) then
                set node = null
                set nodeItem = null
                set station = null
                set ProfessionSearchUnit = null
                set ProfessionSearchItem = null
                set ProfessionSearchStation = null
                return true
            elseif now < InstanceProfessionBlockedUntil.real[instanceId] then
                set node = null
                set nodeItem = null
                set station = null
                set ProfessionSearchUnit = null
                set ProfessionSearchItem = null
                set ProfessionSearchStation = null
                return false
            endif
        endif
    endif
    if InstanceProfessionFailCount[instanceId] <= 0 then
        set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_IDLE_MIN, AI_PROFESSION_IDLE_MAX)
    endif
    set node = null
    set nodeItem = null
    set station = null
    set ProfessionSearchUnit = null
    set ProfessionSearchItem = null
    set ProfessionSearchStation = null
    return false
endfunction

private function IsDebugCraftCandidate takes integer instanceId, unit whichUnit returns boolean
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    if not IsAliveUnit(whichUnit) or IsUnitHidden(whichUnit) then
        return false
    endif
    if ProfileProfessionCount[InstanceProfile[instanceId]] <= 0 then
        return false
    endif
    if Professions_IsUnitReserved(whichUnit) or IsCastingLocked(whichUnit) then
        return false
    endif
    return true
endfunction

public function DebugForceProfessionCraft takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer profileId
    local integer professionId
    local integer seen
    local integer started = 0
    local integer candidates = 0
    local integer stations = 0
    local real now = GetNow()
    local unit whichUnit
    local unit station
    local unit selectedStation

    call EnsureState()

    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        set profileId = InstanceProfile[instanceId]
        set selectedStation = null
        set seen = 0

        if IsDebugCraftCandidate(instanceId, whichUnit) then
            set candidates = candidates + 1
            set professionId = AI_PROFESSION_MINING
            loop
                exitwhen professionId > AI_PROFESSION_MAX
                if HasProfileProfession(profileId, professionId) then
                    set station = FindNearbyCraftStationForProfession(instanceId, whichUnit, AI_PROFESSION_DEBUG_STATION_RANGE, professionId)
                    if station != null then
                        set stations = stations + 1
                        set seen = seen + 1
                        if GetRandomInt(1, seen) == 1 then
                            set selectedStation = station
                        endif
                    endif
                endif
                set professionId = professionId + 1
            endloop

            if selectedStation != null then
                call ClearSocialState(instanceId)
                call StopProfessionOrder(whichUnit)
                set InstanceNextProfession.real[instanceId] = now
                if BeginCraftStation(instanceId, whichUnit, selectedStation, now) then
                    set started = started + 1
                endif
            endif
        endif

        set whichUnit = null
        set station = null
        set selectedStation = null
        set index = index + 1
    endloop

    call BJDebugMsg("[AI] Forced profession craft for " + I2S(started) + " AI units. Candidates=" + I2S(candidates) + ", stations=" + I2S(stations) + ".")
    return started
endfunction

private function DebugCraftAction takes nothing returns nothing
    local integer started = AI_DebugForceProfessionCraft()
    set started = 0
endfunction

private function ShouldBlockAiGatherUnitAttack takes integer instanceId, unit attacker, unit node returns boolean
    local integer professionId
    local integer requiredSkill
    if instanceId <= 0 or attacker == null or node == null or not GN_IsGatherUnit(node) then
        return false
    endif
    set professionId = GN_GetGatherUnitProfessionId(node)
    set requiredSkill = GN_GetGatherUnitSkillRequired(node)
    if not CanGatherProfession(attacker, InstanceProfile[instanceId], professionId, requiredSkill) then
        call MarkLowSkillIgnoredGatherUnit(instanceId, attacker, node, professionId, requiredSkill)
        return true
    endif
    if not CanHoldGatherItem(instanceId, attacker, professionId) then
        return true
    endif
    if professionId == AI_PROFESSION_MINING and not UnitHasItemType(attacker, ITEM_MINING_PICK) then
        return true
    endif
    return false
endfunction

private function ShouldBlockAiGatherItemOrder takes integer instanceId, unit ordered, item nodeItem returns boolean
    local integer professionId
    local integer requiredSkill
    local integer toolId
    if instanceId <= 0 or ordered == null or nodeItem == null or not GN_IsGatherItem(nodeItem) then
        return false
    endif
    set professionId = GN_GetGatherItemProfessionId(nodeItem)
    set requiredSkill = GN_GetGatherItemSkillRequired(nodeItem)
    if not CanGatherProfession(ordered, InstanceProfile[instanceId], professionId, requiredSkill) then
        call MarkLowSkillIgnoredGatherItem(instanceId, ordered, nodeItem, professionId, requiredSkill)
        return true
    endif
    if not CanHoldGatherItem(instanceId, ordered, professionId) then
        return true
    endif
    set toolId = GetProfessionToolId(professionId)
    if toolId != 0 and not UnitHasItemType(ordered, toolId) then
        return true
    endif
    return false
endfunction

private function BackoffBlockedGatherUnitAttack takes integer instanceId, unit attacker, unit node returns nothing
    if node != null and GN_IsGatherUnit(node) then
        call BackoffProfessionWork(instanceId, attacker, GetNow(), "requirements not met for " + GN_GetGatherUnitName(node))
    else
        call BackoffProfessionWork(instanceId, attacker, GetNow(), "gather requirements not met")
    endif
endfunction

private function BackoffBlockedGatherItemOrder takes integer instanceId, unit ordered, item nodeItem returns nothing
    if nodeItem != null and GN_IsGatherItem(nodeItem) then
        call BackoffProfessionWork(instanceId, ordered, GetNow(), "requirements not met for " + GN_GetGatherItemName(nodeItem))
    else
        call BackoffProfessionWork(instanceId, ordered, GetNow(), "gather requirements not met")
    endif
endfunction

private function FaceSocialPair takes unit speaker, unit target returns nothing
    local real dx
    local real dy
    local real angle
    if speaker == null or target == null then
        return
    endif
    set dx = GetUnitX(target) - GetUnitX(speaker)
    set dy = GetUnitY(target) - GetUnitY(speaker)
    if dx == 0.00 and dy == 0.00 then
        return
    endif
    set angle = Atan2(dy, dx) * bj_RADTODEG
    call SetUnitFacing(speaker, angle + GetRandomReal(-8.00, 8.00))
    call SetUnitFacing(target, angle + 180.00 + GetRandomReal(-8.00, 8.00))
endfunction

private function BeginSocialState takes integer instanceId, unit whichUnit, unit target, real now returns boolean
    local real angle
    local real distance
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null or target == null then
        return false
    endif
    set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
    set distance = GetRandomReal(180.00, 280.00)
    set x = GetUnitX(target) + distance * Cos(angle)
    set y = GetUnitY(target) + distance * Sin(angle)
    set InstanceSocialTarget[instanceId] = target
    set InstanceSocialStopped[instanceId] = false
    set InstanceSocialUntil.real[instanceId] = now + GetRandomReal(AI_SOCIAL_DURATION_MIN, AI_SOCIAL_DURATION_MAX)
    set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_SOCIAL_COOLDOWN_MIN, AI_SOCIAL_COOLDOWN_MAX)
    call SetInstanceState(instanceId, AI_STATE_SOCIAL)
    call IssuePointOrder(whichUnit, "move", x, y)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " moves to socialize with " + GetDebugUnitName(target) + ".")
    return true
endfunction

private function ContinueSocialState takes integer instanceId, unit whichUnit, real now returns boolean
    local unit target
    local real angle
    local real distance
    local real x
    local real y
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    set target = InstanceSocialTarget[instanceId]
    if target == null or not IsAliveUnit(target) or IsUnitHidden(target) or not IsUnitAlly(target, GetOwningPlayer(whichUnit)) or now >= InstanceSocialUntil.real[instanceId] or HasNearbyCombatEnemy(whichUnit, 700.00) or (not BossFightActive and GetLifePercent(whichUnit) <= 25.00) then
        call ClearSocialState(instanceId)
        call SetInstanceState(instanceId, AI_STATE_IDLE)
        set target = null
        return false
    endif
    if IsUnitInRange(whichUnit, target, AI_SOCIAL_FACE_RANGE) then
        if not InstanceSocialStopped[instanceId] then
            call IssueImmediateOrder(whichUnit, "stop")
            set InstanceSocialStopped[instanceId] = true
            call AI_RequestBark(whichUnit, AI_BARK_IDLE)
        endif
        call FaceSocialPair(whichUnit, target)
    elseif GetUnitCurrentOrder(whichUnit) == 0 then
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
        set distance = GetRandomReal(180.00, 280.00)
        set x = GetUnitX(target) + distance * Cos(angle)
        set y = GetUnitY(target) + distance * Sin(angle)
        call IssuePointOrder(whichUnit, "move", x, y)
    endif
    set target = null
    return true
endfunction

private function FindFriendlyNpcSocialEnum takes nothing returns nothing
    local unit other = GetEnumUnit()
    local real dx
    local real dy
    local real distance
    if other == null or SocialSearchSource == null or other == SocialSearchSource then
        set other = null
        return
    endif
    if UnitInstance[GetHandleId(other)] > 0 or IsCompanionControlled(other) or IsUnitType(other, UNIT_TYPE_HERO) or IsUnitType(other, UNIT_TYPE_STRUCTURE) then
        set other = null
        return
    endif
    if IsAliveUnit(other) and not IsUnitHidden(other) and IsUnitAlly(other, GetOwningPlayer(SocialSearchSource)) then
        set dx = GetUnitX(other) - GetUnitX(SocialSearchSource)
        set dy = GetUnitY(other) - GetUnitY(SocialSearchSource)
        set distance = dx * dx + dy * dy
        if distance >= AI_SOCIAL_MIN_RANGE * AI_SOCIAL_MIN_RANGE and distance <= AI_SOCIAL_SCAN_RANGE * AI_SOCIAL_SCAN_RANGE then
            set SocialSearchSeen = SocialSearchSeen + 1
            if GetRandomInt(1, SocialSearchSeen) == 1 then
                set SocialSearchTarget = other
            endif
        endif
    endif
    set other = null
endfunction

private function FindSocialTarget takes integer instanceId, unit whichUnit returns unit
    local integer index = 1
    local integer otherInstance
    local integer otherState
    local integer seen = 0
    local unit other
    local real dx
    local real dy
    local real distance
    set SocialSearchTarget = null
    if instanceId <= 0 or whichUnit == null then
        return null
    endif
    loop
        exitwhen index > ActiveCount
        set otherInstance = ActiveInstances[index]
        if otherInstance != instanceId and not InstanceTraveling.boolean[otherInstance] and not InstanceHiddenByCap.boolean[otherInstance] then
            set other = InstanceUnit.unit[otherInstance]
            set otherState = InstanceState[otherInstance]
            if other != null and IsAliveUnit(other) and not IsUnitHidden(other) and IsUnitAlly(other, GetOwningPlayer(whichUnit)) and not IsCompanionControlled(other) and (otherState == AI_STATE_IDLE or otherState == AI_STATE_WANDER or otherState == AI_STATE_SOCIAL) then
                set dx = GetUnitX(other) - GetUnitX(whichUnit)
                set dy = GetUnitY(other) - GetUnitY(whichUnit)
                set distance = dx * dx + dy * dy
                if distance >= AI_SOCIAL_MIN_RANGE * AI_SOCIAL_MIN_RANGE and distance <= AI_SOCIAL_SCAN_RANGE * AI_SOCIAL_SCAN_RANGE then
                    set seen = seen + 1
                    if GetRandomInt(1, seen) == 1 then
                        set SocialSearchTarget = other
                    endif
                endif
            endif
        endif
        set index = index + 1
    endloop
    if SocialSearchTarget == null then
        call GroupClear(TempGroup)
        set SocialSearchSource = whichUnit
        set SocialSearchSeen = 0
        call GroupEnumUnitsInRange(TempGroup, GetUnitX(whichUnit), GetUnitY(whichUnit), AI_SOCIAL_SCAN_RANGE, null)
        call ForGroup(TempGroup, function FindFriendlyNpcSocialEnum)
        call GroupClear(TempGroup)
        set SocialSearchSource = null
        set SocialSearchSeen = 0
    endif
    set other = null
    return SocialSearchTarget
endfunction

private function TryStartCompanionChatAction takes integer instanceId, unit whichUnit, real now returns boolean
    local integer orderId
    local integer barkType = AI_BARK_IDLE
    local boolean barked
    if instanceId <= 0 or whichUnit == null or udg_InCinematic then
        return false
    endif
    if now < InstanceNextSocial.real[instanceId] or now < InstanceNextChat.real[instanceId] or HasNearbyCombatEnemy(whichUnit, 700.00) then
        return false
    endif
    if GetRandomInt(1, 100) > AI_COMPANION_CHAT_CHANCE then
        set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_COMPANION_CHAT_RETRY_MIN, AI_COMPANION_CHAT_RETRY_MAX)
        return false
    endif
    set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_COMPANION_CHAT_COOLDOWN_MIN, AI_COMPANION_CHAT_COOLDOWN_MAX)
    set orderId = GetUnitCurrentOrder(whichUnit)
    if orderId == OrderId("move") or orderId == OrderId("smart") or orderId == OrderId("attack") then
        set barkType = AI_BARK_MOVING
    endif
    set barked = AI_RequestBark(whichUnit, barkType)
    if not barked then
        set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_COMPANION_CHAT_RETRY_MIN, AI_COMPANION_CHAT_RETRY_MAX)
    endif
    return barked
endfunction

private function TryStartSocialAction takes integer instanceId, unit whichUnit, integer state, real now returns boolean
    local unit target
    if instanceId <= 0 or whichUnit == null or udg_InCinematic then
        return false
    endif
    if not IsSideActionState(state) or now < InstanceNextSocial.real[instanceId] or GetUnitCurrentOrder(whichUnit) != 0 or HasNearbyCombatEnemy(whichUnit, 700.00) then
        return false
    endif
    if GetRandomInt(1, 100) > 30 then
        set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_SOCIAL_COOLDOWN_MIN, AI_SOCIAL_COOLDOWN_MAX)
        return false
    endif
    set target = FindSocialTarget(instanceId, whichUnit)
    if target != null and BeginSocialState(instanceId, whichUnit, target, now) then
        set target = null
        set SocialSearchTarget = null
        return true
    endif
    set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_SOCIAL_COOLDOWN_MIN, AI_SOCIAL_COOLDOWN_MAX)
    set target = null
    set SocialSearchTarget = null
    return false
endfunction

private function IsNightTime takes nothing returns boolean
    local real timeOfDay = GetFloatGameState(GAME_STATE_TIME_OF_DAY)
    return timeOfDay >= AI_CAMP_NIGHT_MIN or timeOfDay < AI_CAMP_NIGHT_MAX
endfunction

private function CanPlaceAiCampFireAt takes real x, real y returns boolean
    return not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
endfunction

private function CleanupAiCampFire takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit fire = AiCampFireCleanupUnit.unit[timerId]

    call AiCampFireCleanupUnit.unit.remove(timerId)
    if fire != null then
        call RemoveCampfire(fire)
        if GetUnitTypeId(fire) != 0 then
            call RemoveUnit(fire)
        endif
    endif

    call DestroyTimer(expired)
    set fire = null
    set expired = null
endfunction

private function QueueAiCampFireCleanup takes unit fire returns nothing
    local timer cleanup
    if fire == null then
        return
    endif
    set cleanup = CreateTimer()
    set AiCampFireCleanupUnit.unit[GetHandleId(cleanup)] = fire
    call TimerStart(cleanup, AI_CAMP_FIRE_UNIT_LIFETIME + 1.00, false, function CleanupAiCampFire)
    set cleanup = null
endfunction

private function CreateAiCampFire takes real x, real y returns unit
    local unit fire = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_CAMP_FIRE, x, y, GetRandomReal(0.00, 360.00))
    if fire == null then
        return null
    endif
    if GetUnitTypeId(fire) == 0 then
        return null
    endif

    call AddCampfire(fire)
    call QueueAiCampFireCleanup(fire)

    return fire
endfunction

private function TryPlaceCampFireForCamp takes integer instanceId, unit whichUnit, real now, boolean forced returns boolean
    local real angle
    local real distance
    local real x
    local real y
    local unit fire
    local integer attempt = 0
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    loop
        exitwhen attempt >= AI_CAMP_FIRE_PLACEMENT_ATTEMPTS
        set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
        set distance = GetRandomReal(AI_CAMP_FIRE_MIN_OFFSET, AI_CAMP_FIRE_MAX_OFFSET)
        set x = GetUnitX(whichUnit) + distance * Cos(angle)
        set y = GetUnitY(whichUnit) + distance * Sin(angle)
        if CanPlaceAiCampFireAt(x, y) then
            set fire = CreateAiCampFire(x, y)
        endif
        if fire != null then
            call SetInstanceState(instanceId, AI_STATE_CAMP)
            set InstanceRetreatUntil.real[instanceId] = now + GetRandomReal(AI_CAMP_DURATION_MIN, AI_CAMP_DURATION_MAX)
            set InstanceNextCamp.real[instanceId] = now + GetRandomReal(AI_CAMP_COOLDOWN_MIN, AI_CAMP_COOLDOWN_MAX)
            if forced then
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts forced night camp.")
            else
                call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " starts night camp.")
            endif
            set fire = null
            return true
        endif
        set attempt = attempt + 1
    endloop
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " could not place camp fire.")
    set fire = null
    return false
endfunction

private function TryStartNightCampAction takes integer instanceId, unit whichUnit, integer state, real now returns boolean
    if instanceId <= 0 or whichUnit == null or udg_InCinematic then
        return false
    endif
    if not IsSideActionState(state) or IsCompanionControlled(whichUnit) or now < InstanceNextCamp.real[instanceId] or not IsNightTime() or GetUnitCurrentOrder(whichUnit) != 0 or HasNearbyCombatEnemy(whichUnit, 900.00) then
        return false
    endif
    if GetRandomInt(1, 100) > 12 then
        set InstanceNextCamp.real[instanceId] = now + GetRandomReal(120.00, 300.00)
        return false
    endif
    if TryPlaceCampFireForCamp(instanceId, whichUnit, now, false) then
        return true
    endif
    set InstanceNextCamp.real[instanceId] = now + GetRandomReal(120.00, 240.00)
    return false
endfunction

public function DebugForceNightCamp takes nothing returns integer
    local integer index = 1
    local integer instanceId
    local integer state
    local integer started = 0
    local real now = GetNow()
    local unit whichUnit
    if not IsNightTime() then
        call BJDebugMsg("[AI] Debug camp skipped: it is not night.")
        return 0
    endif
    loop
        exitwhen index > ActiveCount
        set instanceId = ActiveInstances[index]
        set whichUnit = InstanceUnit.unit[instanceId]
        set state = InstanceState[instanceId]
        if whichUnit != null and IsAliveUnit(whichUnit) and not IsUnitHidden(whichUnit) and not IsCompanionControlled(whichUnit) and not udg_InCinematic and IsSideActionState(state) and not HasNearbyCombatEnemy(whichUnit, 900.00) then
            set InstanceNextCamp.real[instanceId] = now
            if TryPlaceCampFireForCamp(instanceId, whichUnit, now, true) then
                set started = started + 1
            endif
        endif
        set whichUnit = null
        set index = index + 1
    endloop
    call BJDebugMsg("[AI] Forced night camp for " + I2S(started) + " AI units.")
    return started
endfunction

private function DebugCampAction takes nothing returns nothing
    local integer started = AI_DebugForceNightCamp()
    set started = 0
endfunction

private function CanCompanionCombatRetreat takes integer instanceId returns boolean
    if instanceId <= 0 then
        return false
    endif
    return not ProfileCompanionRetreatDisabled.boolean[InstanceProfile[instanceId]]
endfunction

private function TryCompanionCombatRetreat takes integer instanceId, unit whichUnit, real now returns boolean
    local unit enemy
    if instanceId <= 0 or whichUnit == null or BossFightActive or not CanCompanionCombatRetreat(instanceId) or now < InstanceRetreatUntil.real[instanceId] then
        return false
    endif
    if GetLifePercent(whichUnit) > GetRandomReal(18.00, 30.00) then
        return false
    endif
    set enemy = AI_FindClosestEnemy(whichUnit, 700.00)
    if enemy == null then
        set enemy = null
        return false
    endif
    call MoveAwayFromPoint(whichUnit, GetUnitX(enemy), GetUnitY(enemy), AI_COMPANION_RETREAT_DISTANCE)
    set InstanceRetreatUntil.real[instanceId] = now + AI_COMPANION_RETREAT_TIME
    set InstanceNextAbility.real[instanceId] = now + AI_COMPANION_RETREAT_TIME
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " repositions as companion at low health.")
    set enemy = null
    return true
endfunction

private function ResetMovementMemory takes integer instanceId, unit whichUnit, integer orderId, real now returns nothing
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set InstanceLastOrder[instanceId] = orderId
    set InstanceLastX.real[instanceId] = GetUnitX(whichUnit)
    set InstanceLastY.real[instanceId] = GetUnitY(whichUnit)
    set InstanceStuckSince.real[instanceId] = now
endfunction

private function TryClearStaleAvelineCompanionCastLock takes integer instanceId, unit whichUnit, real now returns boolean
    local integer customValue
    local integer orderId
    local real dx
    local real dy
    if instanceId <= 0 or whichUnit == null or GetUnitTypeId(whichUnit) != UNIT_AVELINE_RIVERBANE or not IsCastingLocked(whichUnit) then
        return false
    endif
    set customValue = GetUnitUserData(whichUnit)
    set orderId = GetUnitCurrentOrder(whichUnit)
    if customValue <= 0 or udg_UnitMoving[customValue] or (orderId != 0 and orderId != OrderId("stop")) then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if InstanceLastOrder[instanceId] != 0 or InstanceStuckSince.real[instanceId] <= 0.00 then
        call ResetMovementMemory(instanceId, whichUnit, 0, now)
        return false
    endif
    set dx = GetUnitX(whichUnit) - InstanceLastX.real[instanceId]
    set dy = GetUnitY(whichUnit) - InstanceLastY.real[instanceId]
    if dx * dx + dy * dy >= AI_STUCK_MIN_MOVE * AI_STUCK_MIN_MOVE then
        call ResetMovementMemory(instanceId, whichUnit, 0, now)
        return false
    endif
    if now - InstanceStuckSince.real[instanceId] < AI_STUCK_SECONDS then
        return false
    endif
    set udg_UnitIsCasting[customValue] = false
    call ResetMovementMemory(instanceId, whichUnit, 0, now)
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " cleared a stale companion cast lock.")
    return true
endfunction

private function TryRecoverStuck takes integer instanceId, unit whichUnit, integer state, real now returns boolean
    local integer orderId
    local real dx
    local real dy
    local unit target
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    if state != AI_STATE_IDLE and state != AI_STATE_WANDER and state != AI_STATE_BUY then
        return false
    endif
    set orderId = GetUnitCurrentOrder(whichUnit)
    if orderId == 0 or IsCastingLocked(whichUnit) then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if state != AI_STATE_BUY and HasNearbyCombatEnemy(whichUnit, 350.00) then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if InstanceLastOrder[instanceId] != orderId or InstanceStuckSince.real[instanceId] <= 0.00 then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    set dx = GetUnitX(whichUnit) - InstanceLastX.real[instanceId]
    set dy = GetUnitY(whichUnit) - InstanceLastY.real[instanceId]
    if dx * dx + dy * dy >= AI_STUCK_MIN_MOVE * AI_STUCK_MIN_MOVE then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if now - InstanceStuckSince.real[instanceId] < AI_STUCK_SECONDS then
        return false
    endif
    call ResetMovementMemory(instanceId, whichUnit, orderId, now + GetRandomReal(0.00, 1.25))
    if state == AI_STATE_BUY then
        call IssuePointOrder(whichUnit, "move", InstanceActionX.real[instanceId] + GetRandomReal(-AI_STUCK_RETRY_RADIUS, AI_STUCK_RETRY_RADIUS), InstanceActionY.real[instanceId] + GetRandomReal(-AI_STUCK_RETRY_RADIUS, AI_STUCK_RETRY_RADIUS))
    else
        set target = AI_FindClosestEnemy(whichUnit, 800.00)
        if target != null then
            call IssueTargetOrder(whichUnit, "attack", target)
        else
            call BeginWander(instanceId, whichUnit)
        endif
    endif
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " recovered from a stale order in " + GetStateName(state) + ".")
    set target = null
    return true
endfunction

private function TryRefreshCompanionStuckOrder takes integer instanceId, unit whichUnit, real now returns boolean
    local integer orderId
    local real dx
    local real dy
    local unit enemy
    if instanceId <= 0 or whichUnit == null or udg_InCinematic or IsCastingLocked(whichUnit) then
        return false
    endif
    set enemy = AI_FindClosestEnemy(whichUnit, 650.00)
    if enemy != null then
        call ResetMovementMemory(instanceId, whichUnit, GetUnitCurrentOrder(whichUnit), now)
        set enemy = null
        return false
    endif
    set enemy = null
    set orderId = GetUnitCurrentOrder(whichUnit)
    if orderId == 0 then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if InstanceLastOrder[instanceId] != orderId or InstanceStuckSince.real[instanceId] <= 0.00 then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    set dx = GetUnitX(whichUnit) - InstanceLastX.real[instanceId]
    set dy = GetUnitY(whichUnit) - InstanceLastY.real[instanceId]
    if dx * dx + dy * dy >= AI_STUCK_MIN_MOVE * AI_STUCK_MIN_MOVE then
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        return false
    endif
    if now - InstanceStuckSince.real[instanceId] < AI_STUCK_SECONDS then
        return false
    endif
    call Companions_RefreshOrders(whichUnit)
    call ResetMovementMemory(instanceId, whichUnit, orderId, now + GetRandomReal(0.00, 1.25))
    call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " refreshed stale companion order.")
    return true
endfunction

private function RunProfileThink takes integer instanceId, unit whichUnit returns nothing
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    if IsCompanionControlled(whichUnit) and IsDialogBlockingBark() then
        return
    endif
    if IsCastingLocked(whichUnit) then
        return
    endif
    set AI_EventTarget = AI_FindClosestEnemy(whichUnit, 700.00)
    call RunProfileTrigger(ProfileThinkTrigger, instanceId, whichUnit)
    set AI_EventTarget = null
endfunction

private function ResetCompanionCommandState takes integer instanceId, unit whichUnit, boolean keepCompanionOrders returns nothing
    local real now
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    set now = GetNow()
    call ClearSocialState(instanceId)
    call RemoveTrackedProfessionTool(instanceId)
    call InstanceRetreatUntil.remove(instanceId)
    set InstanceCompanionControlled.boolean[instanceId] = keepCompanionOrders
    set InstanceNextThink.real[instanceId] = 0.00
    set InstanceNextAbility.real[instanceId] = 0.00
    set InstanceNextPickup.real[instanceId] = now + 1.00
    call SetInstanceState(instanceId, AI_STATE_IDLE)
    call ResetMovementMemory(instanceId, whichUnit, 0, now)
    if keepCompanionOrders and not udg_InCinematic then
        call Companions_RefreshOrders(whichUnit)
    elseif not IsCastingLocked(whichUnit) then
        call IssueImmediateOrder(whichUnit, "stop")
    endif
endfunction

private function TryProcessAiPartyFollower takes integer instanceId, unit whichUnit, integer state, real now returns boolean
    local integer leaderId = InstanceAiPartyLeader[instanceId]
    local unit leader
    local unit target
    local real dx
    local real dy
    local integer orderId
    if leaderId <= 0 or leaderId == instanceId then
        return false
    endif
    set leader = InstanceUnit.unit[leaderId]
    if leader == null or not IsAliveUnit(leader) or IsUnitHidden(leader) or InstanceTraveling.boolean[leaderId] or InstanceHiddenByCap.boolean[leaderId] or IsCompanionControlled(leader) then
        call RemoveInstanceFromAiParty(instanceId)
        set target = null
        set leader = null
        return false
    endif
    if state == AI_STATE_RETREAT_COMBAT or state == AI_STATE_RETREAT_BASE or state == AI_STATE_BOSS_EVADE then
        set target = null
        set leader = null
        return false
    endif
    if IsCastingLocked(whichUnit) then
        set target = null
        set leader = null
        return true
    endif
    set dx = GetUnitX(whichUnit) - GetUnitX(leader)
    set dy = GetUnitY(whichUnit) - GetUnitY(leader)
    if dx * dx + dy * dy > AI_PARTY_FOLLOW_RANGE * AI_PARTY_FOLLOW_RANGE then
        call IssueTargetOrder(whichUnit, "smart", leader)
        call ResetMovementMemory(instanceId, whichUnit, GetUnitCurrentOrder(whichUnit), now)
        set target = null
        set leader = null
        return true
    endif
    set target = AI_FindClosestEnemy(leader, 850.00)
    if target != null then
        call IssueTargetOrder(whichUnit, "attack", target)
        if now >= InstanceNextAbility.real[instanceId] then
            call RunProfileThink(instanceId, whichUnit)
        endif
        set target = null
        set leader = null
        return true
    endif
    set orderId = GetUnitCurrentOrder(whichUnit)
    if dx * dx + dy * dy > AI_PARTY_CLOSE_RANGE * AI_PARTY_CLOSE_RANGE and orderId != OrderId("smart") then
        call IssueTargetOrder(whichUnit, "smart", leader)
        call ResetMovementMemory(instanceId, whichUnit, GetUnitCurrentOrder(whichUnit), now)
    endif
    set target = null
    set leader = null
    return true
endfunction

private function ParkCompanionForCinematic takes integer instanceId, unit whichUnit, real now returns nothing
    local integer orderId
    if instanceId <= 0 or whichUnit == null then
        return
    endif
    call ClearSocialState(instanceId)
    call SetInstanceState(instanceId, AI_STATE_COMPANION_CONTROLLED)
    call RemoveTrackedProfessionTool(instanceId)
    set InstanceNextProfession.real[instanceId] = now + GetRandomReal(AI_PROFESSION_IDLE_MIN, AI_PROFESSION_IDLE_MAX)
    set InstanceNextPickup.real[instanceId] = now + GetRandomReal(AI_COMPANION_PICKUP_MIN_DELAY, AI_COMPANION_PICKUP_MAX_DELAY)
    set InstanceNextSocial.real[instanceId] = now + GetRandomReal(AI_COMPANION_CHAT_COOLDOWN_MIN, AI_COMPANION_CHAT_COOLDOWN_MAX)
    if not InstanceCinematicParked.boolean[instanceId] then
        set orderId = GetUnitCurrentOrder(whichUnit)
        if orderId != 0 and not IsCastingLocked(whichUnit) then
            call IssueImmediateOrder(whichUnit, "stop")
            set orderId = 0
        endif
        call ResetMovementMemory(instanceId, whichUnit, orderId, now)
        set InstanceCinematicParked.boolean[instanceId] = true
    endif
endfunction

private function ShouldHoldReservedProfessionJob takes integer instanceId, unit whichUnit, real now returns boolean
    if instanceId <= 0 or whichUnit == null then
        return false
    endif
    if not Professions_IsUnitReserved(whichUnit) then
        return false
    endif

    if Professions_IsUnitAiCrafting(whichUnit) and HasNearbyCombatEnemy(whichUnit, 700.00) then
        if Professions_CancelUnitCraft(whichUnit) then
            call BackoffProfessionWork(instanceId, whichUnit, now, "craft interrupted by combat")
        endif
        return false
    endif

    call ClearSocialState(instanceId)
    call ResetMovementMemory(instanceId, whichUnit, GetUnitCurrentOrder(whichUnit), now)
    return true
endfunction

private function TryEquipStoredEquipmentForInstance takes integer instanceId, unit whichUnit, real now returns nothing
    if instanceId <= 0 or whichUnit == null or now < InstanceNextEquipment.real[instanceId] then
        return
    endif
    if DInvTryEquipBestStoredEquipmentForUnit(whichUnit) then
        set InstanceNextEquipment.real[instanceId] = now + GetRandomReal(AI_EQUIPMENT_CHECK_MIN, AI_EQUIPMENT_CHECK_MAX)
    else
        set InstanceNextEquipment.real[instanceId] = now + GetRandomReal(AI_EQUIPMENT_CHECK_MAX, AI_EQUIPMENT_CHECK_MAX + 8.00)
    endif
endfunction

private function ProcessInstance takes integer instanceId, real now returns nothing
    local unit whichUnit = InstanceUnit.unit[instanceId]
    local boolean companionControlled
    local integer companionMode
    local integer state
    if instanceId <= 0 or whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
        set whichUnit = null
        return
    endif
    set state = InstanceState[instanceId]
    if state == AI_STATE_TRAVEL then
        if now >= InstanceTravelReturnAt.real[instanceId] then
            call CompleteTravel(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    endif
    if InstanceHiddenByCap.boolean[instanceId] then
        set whichUnit = null
        return
    endif
    if state == AI_STATE_DEAD or not IsAliveUnit(whichUnit) or IsUnitHidden(whichUnit) then
        set whichUnit = null
        return
    endif
    if now < InstanceNextThink.real[instanceId] then
        set whichUnit = null
        return
    endif
    set InstanceNextThink.real[instanceId] = now + GetRandomReal(AI_DEFAULT_THINK_MIN, AI_DEFAULT_THINK_MAX)
    call CleanupProfessionTool(instanceId, now)
    set companionControlled = IsCompanionControlled(whichUnit)
    set InstanceCompanionControlled.boolean[instanceId] = companionControlled
    if companionControlled and IsDialogBlockingBark() then
        call ParkCompanionForCinematic(instanceId, whichUnit, now)
        set whichUnit = null
        return
    endif
    if not udg_InCinematic then
        call InstanceCinematicParked.remove(instanceId)
    endif
    if ShouldHoldReservedProfessionJob(instanceId, whichUnit, now) then
        set whichUnit = null
        return
    endif

    if companionControlled then
        call ClearSocialState(instanceId)
        call SetInstanceState(instanceId, AI_STATE_COMPANION_CONTROLLED)
        set companionMode = Companions_GetMode(whichUnit)
        if TryClearStaleAvelineCompanionCastLock(instanceId, whichUnit, now) then
            call Companions_RefreshOrders(whichUnit)
        endif
        if now >= InstanceNextItem.real[instanceId] then
            if AI_TryUseConsumable(whichUnit) then
                set InstanceNextItem.real[instanceId] = now + 5.00 + GetRandomReal(0.50, 1.50)
            else
                set InstanceNextItem.real[instanceId] = now + 2.00 + GetRandomReal(0.10, 0.80)
            endif
        endif
        call TryEquipStoredEquipmentForInstance(instanceId, whichUnit, now)
        if TryStartCompanionChatAction(instanceId, whichUnit, now) then
            set whichUnit = null
            return
        endif
        if companionMode == COMPANION_MODE_PASSIVE then
            if TryRefreshCompanionStuckOrder(instanceId, whichUnit, now) then
                set whichUnit = null
                return
            endif
            if GetUnitCurrentOrder(whichUnit) == 0 and not IsCastingLocked(whichUnit) then
                call Companions_RefreshOrders(whichUnit)
            endif
            set whichUnit = null
            return
        endif
        if TryCompanionCombatRetreat(instanceId, whichUnit, now) then
            set whichUnit = null
            return
        endif
        if companionMode != COMPANION_MODE_HOLD and TryStartProfessionAction(instanceId, whichUnit, AI_STATE_IDLE, now, false) then
            set whichUnit = null
            return
        endif
        if now >= InstanceNextPickup.real[instanceId] and not IsCastingLocked(whichUnit) and TryStartPickupAction(instanceId, whichUnit, now) then
            set whichUnit = null
            return
        endif
        if now >= InstanceNextAbility.real[instanceId] then
            call RunProfileThink(instanceId, whichUnit)
        endif
        if TryRefreshCompanionStuckOrder(instanceId, whichUnit, now) then
            set whichUnit = null
            return
        endif
        if GetUnitCurrentOrder(whichUnit) == 0 and not IsCastingLocked(whichUnit) then
            call Companions_RefreshOrders(whichUnit)
        endif
        set whichUnit = null
        return
    endif

    if TryReturnToProfileAllowedZone(instanceId, whichUnit) then
        set whichUnit = null
        return
    endif

    if state == AI_STATE_RETREAT_COMBAT or state == AI_STATE_RETREAT_BASE or state == AI_STATE_BOSS_EVADE then
        if now < InstanceRetreatUntil.real[instanceId] then
            set whichUnit = null
            return
        endif
        call SetInstanceState(instanceId, AI_STATE_IDLE)
    elseif state == AI_STATE_BUY then
        if IsNearActionPoint(instanceId, whichUnit, 250.00) then
            call FinishBuyState(instanceId, whichUnit)
        else
            call TryRecoverStuck(instanceId, whichUnit, state, now)
        endif
        set whichUnit = null
        return
    elseif state == AI_STATE_SELL then
        if IsNearActionPoint(instanceId, whichUnit, 250.00) then
            call SellInventoryItem(instanceId, whichUnit)
            call SetInstanceState(instanceId, AI_STATE_IDLE)
        else
            call TryRecoverStuck(instanceId, whichUnit, state, now)
        endif
        set whichUnit = null
        return
    elseif state == AI_STATE_CAMP then
        if now >= InstanceRetreatUntil.real[instanceId] then
            call SetInstanceState(instanceId, AI_STATE_IDLE)
        endif
        set whichUnit = null
        return
    elseif state == AI_STATE_SOCIAL then
        if ContinueSocialState(instanceId, whichUnit, now) then
            set whichUnit = null
            return
        endif
        set state = InstanceState[instanceId]
    endif

    if ProfileAutonomousDisabled.boolean[InstanceProfile[instanceId]] then
        if now >= InstanceNextAbility.real[instanceId] then
            call RunProfileThink(instanceId, whichUnit)
        endif
        set whichUnit = null
        return
    endif

    if not BossFightActive then
        if GetLifePercent(whichUnit) <= 10.00 then
            call BeginBaseRetreat(instanceId, whichUnit)
            set whichUnit = null
            return
        elseif GetLifePercent(whichUnit) <= GetRandomReal(10.00, 25.00) then
            call BeginCombatRetreat(instanceId, whichUnit)
            set whichUnit = null
            return
        endif
    endif

    if now >= InstanceNextItem.real[instanceId] then
        if AI_TryUseConsumable(whichUnit) then
            set InstanceNextItem.real[instanceId] = now + 5.00 + GetRandomReal(0.50, 1.50)
        else
            set InstanceNextItem.real[instanceId] = now + 2.00 + GetRandomReal(0.10, 0.80)
        endif
    endif
    call TryEquipStoredEquipmentForInstance(instanceId, whichUnit, now)

    if now >= InstanceNextPickup.real[instanceId] and not IsCastingLocked(whichUnit) and TryStartPickupAction(instanceId, whichUnit, now) then
        set whichUnit = null
        return
    endif

    if TryProcessAiPartyFollower(instanceId, whichUnit, state, now) then
        set whichUnit = null
        return
    endif

    if TryStartShopAction(instanceId, whichUnit, state, now) then
        set whichUnit = null
        return
    endif

    if TryRecoverStuck(instanceId, whichUnit, state, now) then
        set whichUnit = null
        return
    endif

    if TryStartProfessionAction(instanceId, whichUnit, state, now, true) then
        set whichUnit = null
        return
    endif

    if TryStartSocialAction(instanceId, whichUnit, state, now) then
        set whichUnit = null
        return
    endif

    if TryStartNightCampAction(instanceId, whichUnit, state, now) then
        set whichUnit = null
        return
    endif

    if now >= InstanceNextAbility.real[instanceId] then
        call RunProfileThink(instanceId, whichUnit)
    endif

    if GetUnitCurrentOrder(whichUnit) == 0 and GetLifePercent(whichUnit) >= GetRandomReal(25.00, 30.00) and GetRandomInt(1, 10) == 1 then
        call BeginWander(instanceId, whichUnit)
    endif
    set whichUnit = null
endfunction

private function Think takes nothing returns nothing
    local integer i = 1
    local real now = GetNow()
    loop
        exitwhen i > ActiveCount
        call ProcessInstance(ActiveInstances[i], now)
        set i = i + 1
    endloop
    call TryOrganizeAiParty(now)
endfunction

private function RequestCompanionDeathBark takes unit victim returns nothing
    local integer i = 1
    local integer instanceId
    local unit speaker
    loop
        exitwhen i > ActiveCount
        set instanceId = ActiveInstances[i]
        set speaker = InstanceUnit.unit[instanceId]
        if speaker != null and speaker != victim and IsCompanionControlled(speaker) and IsAliveUnit(speaker) and GetRandomInt(1, 2) == 1 then
            set AI_EventTarget = victim
            call AI_RequestBark(speaker, AI_BARK_COMPANION_DIES)
            set AI_EventTarget = null
            set speaker = null
            return
        endif
        set i = i + 1
    endloop
    set speaker = null
endfunction

private function HandleDeath takes nothing returns nothing
    local unit victim = UnitDeathEvent_GetDyingUnit()
    local unit killer = UnitDeathEvent_GetKillingUnit()
    local integer instanceId = UnitInstance[GetHandleId(victim)]
    if instanceId <= 0 and IsCompanionControlled(victim) then
        set instanceId = AI_RegisterUnitByType(victim, 0)
    endif
    if instanceId > 0 then
        set InstanceAlive.boolean[instanceId] = false
        set InstanceTraveling.boolean[instanceId] = false
        call RemoveTrackedProfessionTool(instanceId)
        set InstanceSocialTarget[instanceId] = null
        set InstanceSocialStopped[instanceId] = false
        call SetInstanceState(instanceId, AI_STATE_DEAD)
        if IsCompanionControlled(victim) and not udg_InCinematic then
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 5.00, "|cffff4040" + GetDisplayName(victim) + " has fallen.|r")
            call RequestCompanionDeathBark(victim)
        endif
        call RunProfileTrigger(ProfileDeathTrigger, instanceId, victim)
        call StartReviveTimer(instanceId, victim)
    endif
    if killer != null then
        set instanceId = UnitInstance[GetHandleId(killer)]
        if instanceId > 0 then
            set AI_EventTarget = victim
            call AI_RequestBark(killer, AI_BARK_KILLING)
            set AI_EventTarget = null
        endif
    endif
    set victim = null
    set killer = null
endfunction

private function HandleTargetOrder takes nothing returns nothing
    local unit ordered = GetTriggerUnit()
    local unit targetUnit = GetOrderTargetUnit()
    local item targetItem = GetOrderTargetItem()
    local integer instanceId = UnitInstance[GetHandleId(ordered)]
    if targetItem != null and ShouldBlockAiGatherItemOrder(instanceId, ordered, targetItem) then
        call BackoffBlockedGatherItemOrder(instanceId, ordered, targetItem)
    elseif targetUnit != null and ShouldBlockAiGatherUnitAttack(instanceId, ordered, targetUnit) then
        call BackoffBlockedGatherUnitAttack(instanceId, ordered, targetUnit)
    endif
    set ordered = null
    set targetUnit = null
    set targetItem = null
endfunction

private function HandleAttack takes nothing returns nothing
    local unit attacker = GetAttacker()
    local unit attacked = GetTriggerUnit()
    local integer instanceId = UnitInstance[GetHandleId(attacker)]
    if ShouldBlockAiGatherUnitAttack(instanceId, attacker, attacked) then
        call BackoffBlockedGatherUnitAttack(instanceId, attacker, attacked)
        set attacker = null
        set attacked = null
        return
    endif
    if instanceId > 0 and IsCompanionControlled(attacker) and GetRandomInt(1, 16) == 1 then
        set AI_EventTarget = attacked
        call AI_RequestBark(attacker, AI_BARK_ATTACKING)
        set AI_EventTarget = null
    endif
    set instanceId = UnitInstance[GetHandleId(attacked)]
    if instanceId > 0 and GetRandomReal(0.00, 100.00) <= AI_SHIELD_BLOCK_CHANCE then
        call IssueImmediateOrder(attacked, "berserk")
    endif
    set attacker = null
    set attacked = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local integer instanceId = UnitInstance[GetHandleId(caster)]
    if instanceId > 0 and IsCompanionControlled(caster) and GetRandomInt(1, 8) == 1 then
        set AI_EventAbilityId = abilityId
        call AI_RequestBark(caster, AI_BARK_CASTING)
        set AI_EventAbilityId = 0
    endif
    call AI_HandleBossCast(caster, abilityId, GetSpellTargetX(), GetSpellTargetY())
    set caster = null
endfunction

private function HandleLevel takes nothing returns nothing
    local unit whichUnit = GetLevelingUnit()
    local integer instanceId = UnitInstance[GetHandleId(whichUnit)]
    local integer profileId
    local integer fixedLevel
    if instanceId > 0 then
        set profileId = InstanceProfile[instanceId]
        set fixedLevel = ProfileFixedHeroLevel[profileId]
        if fixedLevel > 0 and not InstanceInviteUnlocked.boolean[instanceId] and GetHeroLevel(whichUnit) > fixedLevel then
            call SetHeroLevel(whichUnit, fixedLevel, false)
        endif
        if ProfileLockXpUntilInvite.boolean[profileId] and not InstanceInviteUnlocked.boolean[instanceId] then
            call SuspendHeroXP(whichUnit, true)
        endif
        call SetWidgetLife(whichUnit, GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE))
        if ProfileNoManaRestore.boolean[profileId] then
            call SetUnitState(whichUnit, UNIT_STATE_MANA, 0.00)
        else
            call SetUnitState(whichUnit, UNIT_STATE_MANA, GetUnitState(whichUnit, UNIT_STATE_MAX_MANA))
        endif
        call LearnRandomProfileAbility(whichUnit, profileId)
        call RefreshInstanceProfessionSkills(instanceId, whichUnit)
    endif
    set whichUnit = null
endfunction

private function HandleItemDrop takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local item manipulatedItem = GetManipulatedItem()

    if GetOwningPlayer(whichUnit) == Player(0) then
        set udg_LastDroppedItem = manipulatedItem
    endif

    set whichUnit = null
    set manipulatedItem = null
endfunction

private function HandleItemPickup takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local item manipulatedItem = GetManipulatedItem()
    local integer instanceId = UnitInstance[GetHandleId(whichUnit)]
    local integer itemTypeId

    if instanceId > 0 and manipulatedItem != null then
        set itemTypeId = GetItemTypeId(manipulatedItem)
        if ProfileNoManaRestore.boolean[InstanceProfile[instanceId]] and IsManaOnlyItemType(itemTypeId) then
            call UnitDropItemPoint(whichUnit, manipulatedItem, GetUnitX(whichUnit), GetUnitY(whichUnit))
            call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " rejected mana-only item " + GetObjectName(itemTypeId) + ".")
        elseif manipulatedItem == udg_LastDroppedItem then
            call AI_RequestBark(whichUnit, AI_BARK_ITEM_GIVEN)
        endif
        if IsCompanionControlled(whichUnit) and not udg_InCinematic then
            call Companions_RefreshOrders(whichUnit)
        endif
    endif

    set whichUnit = null
    set manipulatedItem = null
endfunction

private function HandleSoldUnit takes nothing returns nothing
    local unit soldUnit = GetSoldUnit()
    local integer instanceId
    if soldUnit == null then
        return
    endif
    set instanceId = AI_RegisterUnitByType(soldUnit, 0)
    if instanceId > 0 then
        call DebugMsg("Sold unit initialized as " + GetDebugInstanceName(instanceId, soldUnit) + " instance=" + I2S(instanceId) + ".")
    endif
    set soldUnit = null
endfunction

private function HandleIndexedUnit takes nothing returns nothing
    local unit indexedUnit = udg_UDexUnits[udg_UDex]
    if indexedUnit != null and GetUnitTypeId(indexedUnit) != 0 then
        call AI_RegisterUnitByType(indexedUnit, 0)
    endif
    set indexedUnit = null
endfunction

private function UnlockInviteGatedProfileState takes integer instanceId, unit whichUnit returns nothing
    local integer profileId
    if instanceId <= 0 or InstanceInviteUnlocked.boolean[instanceId] then
        return
    endif
    set profileId = InstanceProfile[instanceId]
    set InstanceInviteUnlocked.boolean[instanceId] = true
    if whichUnit != null and IsUnitType(whichUnit, UNIT_TYPE_HERO) and ProfileLockXpUntilInvite.boolean[profileId] then
        call SuspendHeroXP(whichUnit, false)
    endif
    if ProfileLockXpUntilInvite.boolean[profileId] or ProfileAllowedZoneCount[profileId] > 0 then
        call DebugMsg(GetDebugInstanceName(instanceId, whichUnit) + " unlocked invite-gated AI restrictions.")
    endif
endfunction

private function FlushPendingCommandBark takes nothing returns nothing
    local unit speaker = PendingCommandBarkSpeaker
    local integer barkType = PendingCommandBarkType
    set PendingCommandBarkSpeaker = null
    set PendingCommandBarkType = 0
    set PendingCommandBarkSeen = 0
    if speaker != null and barkType > 0 then
        call QueueCommandResponseBark(speaker, barkType)
    endif
    set speaker = null
endfunction

private function QueueCommandBark takes unit speaker, integer barkType returns nothing
    local integer instanceId
    local integer barkKey
    if speaker == null or barkType <= 0 then
        return
    endif
    set instanceId = UnitInstance[GetHandleId(speaker)]
    if instanceId <= 0 then
        return
    endif
    set barkKey = GetBarkKey(InstanceProfile[instanceId], barkType)
    if BarkLineCount[barkKey] <= 0 then
        return
    endif
    if PendingCommandBarkSpeaker != null and PendingCommandBarkType != barkType then
        call FlushPendingCommandBark()
    endif
    if PendingCommandBarkTimer == null then
        set PendingCommandBarkTimer = CreateTimer()
    endif
    set PendingCommandBarkType = barkType
    set PendingCommandBarkSeen = PendingCommandBarkSeen + 1
    if PendingCommandBarkSpeaker == null or GetRandomInt(1, PendingCommandBarkSeen) == 1 then
        set PendingCommandBarkSpeaker = speaker
    endif
    call TimerStart(PendingCommandBarkTimer, AI_COMMAND_BARK_DELAY, false, function FlushPendingCommandBark)
endfunction

private function HandleCompanionCommand takes nothing returns nothing
    local unit whichUnit = Companions_EventUnit
    local integer commandId = Companions_EventCommand
    local integer mode = Companions_EventMode
    local integer barkType = 0
    local integer instanceId

    if whichUnit == null then
        set whichUnit = null
        return
    endif
    set instanceId = UnitInstance[GetHandleId(whichUnit)]
    if instanceId <= 0 and commandId == Companions_COMMAND_INVITE then
        set instanceId = AI_RegisterUnitByType(whichUnit, 0)
    endif
    if instanceId <= 0 then
        set whichUnit = null
        return
    endif

    if commandId == Companions_COMMAND_INVITE then
        call RemoveInstanceFromAiParty(instanceId)
        call UnlockInviteGatedProfileState(instanceId, whichUnit)
        call ResetCompanionCommandState(instanceId, whichUnit, true)
        set barkType = AI_BARK_GREET
    elseif commandId == Companions_COMMAND_KICK then
        call ResetCompanionCommandState(instanceId, whichUnit, false)
        if GetRandomInt(1, 2) == 1 then
            set barkType = AI_BARK_KICKED
        else
            set barkType = AI_BARK_FAREWELL
        endif
    elseif commandId == Companions_COMMAND_DROP_ITEMS then
        set barkType = AI_BARK_DROP_ITEMS
    elseif commandId == Companions_COMMAND_MODE then
        if mode == COMPANION_MODE_PASSIVE then
            set barkType = AI_BARK_PASSIVE
        elseif mode == COMPANION_MODE_HOLD then
            set barkType = AI_BARK_HOLD
        elseif mode == COMPANION_MODE_AGGRESSIVE then
            set barkType = AI_BARK_AGGRESSIVE
        else
            set barkType = AI_BARK_NORMAL
        endif
        call ResetCompanionCommandState(instanceId, whichUnit, true)
    elseif commandId == Companions_COMMAND_MOVE or commandId == Companions_COMMAND_ATTACK then
        call ResetCompanionCommandState(instanceId, whichUnit, true)
    endif

    if commandId == Companions_COMMAND_MODE then
        call QueueCommandBark(whichUnit, barkType)
    elseif barkType > 0 then
        call QueueCommandResponseBark(whichUnit, barkType)
    endif

    set whichUnit = null
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    call CinematicMover_RegisterAiReviveCallbacks(function InspectCinematicReviveState, function CancelCinematicReviveTimer, function RestoreCinematicReviveTimer)
    set ThinkTimer = CreateTimer()
    call TimerStart(ThinkTimer, AI_THINK_INTERVAL, true, function Think)

    set RandomSpawnTimer = CreateTimer()
    call TimerStart(RandomSpawnTimer, 5.00, false, function RandomSpawnTimerAction)

    set RandomTravelTimer = CreateTimer()
    call TimerStart(RandomTravelTimer, GetRandomReal(AI_RANDOM_TRAVEL_MIN, AI_RANDOM_TRAVEL_MAX), false, function RandomTravelTimerAction)

    set DebugSpawnTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugSpawnTrigger, Player(0), "/debug aispawn", true)
    call TriggerRegisterPlayerChatEvent(DebugSpawnTrigger, Player(0), "aispawn", true)
    call TriggerAddAction(DebugSpawnTrigger, function DebugSpawnAction)

    set DebugModeTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugModeTrigger, Player(0), "/debug ai", true)
    call TriggerRegisterPlayerChatEvent(DebugModeTrigger, Player(0), "/debug aidebug", true)
    call TriggerAddAction(DebugModeTrigger, function DebugModeAction)

    set DebugCampTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugCampTrigger, Player(0), "/debug aicamp", true)
    call TriggerRegisterPlayerChatEvent(DebugCampTrigger, Player(0), "aicamp", true)
    call TriggerAddAction(DebugCampTrigger, function DebugCampAction)

    set DebugCraftTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugCraftTrigger, Player(0), "/debug aicraft", true)
    call TriggerRegisterPlayerChatEvent(DebugCraftTrigger, Player(0), "aicraft", true)
    call TriggerAddAction(DebugCraftTrigger, function DebugCraftAction)

    set DebugShopTrigger = CreateTrigger()
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "/debug aibuy", true)
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "aibuy", true)
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "/debug aisell", true)
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "aisell", true)
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "/debug aishop", true)
    call TriggerRegisterPlayerChatEvent(DebugShopTrigger, Player(0), "aishop", true)
    call TriggerAddAction(DebugShopTrigger, function DebugShopAction)

    call Events_RegisterPlayerUnitEvent(function HandleTargetOrder, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    call Events_RegisterPlayerUnitEvent(function HandleAttack, EVENT_PLAYER_UNIT_ATTACKED)
    call Events_RegisterPlayerUnitEvent(function HandleSpellEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function HandleLevel, EVENT_PLAYER_HERO_LEVEL)
    call Events_RegisterPlayerUnitEvent(function HandleItemDrop, EVENT_PLAYER_UNIT_DROP_ITEM)
    call Events_RegisterPlayerUnitEvent(function HandleItemPickup, EVENT_PLAYER_UNIT_PICKUP_ITEM)
    call Events_RegisterPlayerUnitEvent(function HandleSoldUnit, EVENT_PLAYER_UNIT_SELL)

    set UnitIndexTrigger = CreateTrigger()
    call TriggerRegisterVariableEvent(UnitIndexTrigger, "udg_UnitIndexEvent", EQUAL, 1.50)
    call TriggerAddAction(UnitIndexTrigger, function HandleIndexedUnit)

    call UnitDeathEvent_Register(function HandleDeath)
    call Companions_RegisterCommandEvent(function HandleCompanionCommand)
endfunction

endlibrary
