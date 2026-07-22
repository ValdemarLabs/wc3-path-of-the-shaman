/**
    AbilitiesPlayer

    Author: Valdemar
    Version:

    Description:
    Stores player shaman ability definitions for the JASS learning system and
    trainer UI. Each entry maps the displayed ability rawcode, old GUI dummy
    rawcode, AP cost, max level, tree, and optional prerequisite.

    Credits:

    How to install:
    Import before Abilities and AbilitiesUI. Disable the old GUI player ability
    item-learn triggers after the JASS learner is wired in.

    API:
    - call AbilitiesPlayer_EnsureInitialized()
    - set count = AbilitiesPlayer_GetEntryCount()
    - set entry = AbilitiesPlayer_GetEntryByTreePageIndex(treeId, pageId, index)
    - set treeId = AbilitiesPlayer_GetTrainerTreeByUnitType(unitTypeId)
    - set title = AbilitiesPlayer_GetEntryTitle(entry)
    - set body = AbilitiesPlayer_GetEntryBodyForLevel(entry, level)
    - set locked = AbilitiesPlayer_IsEntryInitialQuestLocked(entry)
    - set text = AbilitiesPlayer_GetEntryInitialQuestLockedText(entry)

**/
library AbilitiesPlayer initializer Init
    globals
        public constant integer TREE_NONE = 0
        public constant integer TREE_ELEMENTAL = 1
        public constant integer TREE_ENHANCEMENT = 2
        public constant integer TREE_RESTORATION = 3
        public constant integer TREE_TOTEMIC = 4

        public constant integer ENTRY_ABILITY = 1
        public constant integer ENTRY_SPECIALIZATION = 2
        public constant integer ENTRY_TALENT = 3

        public constant integer PAGE_ALL = 0
        public constant integer PAGE_ABILITIES = 1
        public constant integer PAGE_SPECIALIZATIONS = 2
        public constant integer PAGE_TALENTS = 3

        public constant integer TRAINER_TOTEMIC = 'o625'
        public constant integer TRAINER_RESTORATION = 'o626'
        public constant integer TRAINER_ELEMENTAL = 'o627'
        public constant integer TRAINER_ENHANCEMENT = 'o628'

        private constant integer ABP_MAX_ENTRIES = 128
        private constant integer ABP_DEFAULT_ABILITY_COST = 1
        private constant integer ABP_SPECIALIZATION_COST = 0

        private boolean ABP_Initialized = false
        private integer ABP_EntryCount = 0

        private integer array ABP_EntryTree
        private integer array ABP_EntryKind
        private integer array ABP_EntryAbilityId
        private integer array ABP_EntryAddAbilityId
        private integer array ABP_EntryPermanentAbilityId
        private integer array ABP_EntryRequiredAbilityId
        private integer array ABP_EntryMaxLevel
        private integer array ABP_EntryCost
        private boolean array ABP_EntryInitialQuestLocked
        private string array ABP_EntryInitialQuestLockedText
        private string array ABP_EntryTitleOverride
        private string array ABP_EntryBodyOverride
    endglobals

    private function ABP_FindPattern takes string source, string pattern returns integer
        local integer sourceLength
        local integer patternLength
        local integer i = 0

        if source == null or pattern == null then
            return -1
        endif

        set sourceLength = StringLength(source)
        set patternLength = StringLength(pattern)
        if patternLength <= 0 or sourceLength < patternLength then
            return -1
        endif

        loop
            exitwhen i + patternLength > sourceLength
            if SubString(source, i, i + patternLength) == pattern then
                return i
            endif
            set i = i + 1
        endloop

        return -1
    endfunction

    private function ABP_StripTooltipLevelSuffix takes string titleText returns string
        local integer cutIndex

        if titleText == null or titleText == "" then
            return titleText
        endif

        set cutIndex = ABP_FindPattern(titleText, " [Level ")
        if cutIndex >= 0 then
            return SubString(titleText, 0, cutIndex)
        endif

        set cutIndex = ABP_FindPattern(titleText, " - [")
        if cutIndex >= 0 then
            return SubString(titleText, 0, cutIndex)
        endif

        set cutIndex = ABP_FindPattern(titleText, " (Level ")
        if cutIndex >= 0 then
            return SubString(titleText, 0, cutIndex)
        endif

        set cutIndex = ABP_FindPattern(titleText, " - Level ")
        if cutIndex >= 0 then
            return SubString(titleText, 0, cutIndex)
        endif

        return titleText
    endfunction

    private function ABP_RegisterEntry takes integer treeId, integer kind, integer abilityId, integer addAbilityId, integer permanentAbilityId, integer maxLevel, integer cost, integer requiredAbilityId, string titleText, string bodyText returns integer
        if ABP_EntryCount >= ABP_MAX_ENTRIES or abilityId == 0 then
            return 0
        endif

        set ABP_EntryCount = ABP_EntryCount + 1
        set ABP_EntryTree[ABP_EntryCount] = treeId
        set ABP_EntryKind[ABP_EntryCount] = kind
        set ABP_EntryAbilityId[ABP_EntryCount] = abilityId
        set ABP_EntryAddAbilityId[ABP_EntryCount] = addAbilityId
        set ABP_EntryPermanentAbilityId[ABP_EntryCount] = permanentAbilityId
        set ABP_EntryMaxLevel[ABP_EntryCount] = maxLevel
        set ABP_EntryCost[ABP_EntryCount] = cost
        set ABP_EntryRequiredAbilityId[ABP_EntryCount] = requiredAbilityId
        set ABP_EntryInitialQuestLocked[ABP_EntryCount] = false
        set ABP_EntryInitialQuestLockedText[ABP_EntryCount] = ""
        set ABP_EntryTitleOverride[ABP_EntryCount] = titleText
        set ABP_EntryBodyOverride[ABP_EntryCount] = bodyText

        return ABP_EntryCount
    endfunction

    private function ABP_RegisterAbility takes integer treeId, integer abilityId, integer dummyAbilityId, integer maxLevel, integer requiredAbilityId returns integer
        return ABP_RegisterEntry(treeId, ENTRY_ABILITY, abilityId, dummyAbilityId, dummyAbilityId, maxLevel, ABP_DEFAULT_ABILITY_COST, requiredAbilityId, "", "")
    endfunction

    private function ABP_RegisterSpecialization takes integer treeId, integer abilityId, integer permanentAbilityId returns integer
        return ABP_RegisterEntry(treeId, ENTRY_SPECIALIZATION, abilityId, abilityId, permanentAbilityId, 1, ABP_SPECIALIZATION_COST, 0, "", "")
    endfunction

    private function ABP_SetEntryInitialQuestLocked takes integer entryIndex, string lockedText returns nothing
        if entryIndex <= 0 or entryIndex > ABP_MAX_ENTRIES then
            return
        endif

        set ABP_EntryInitialQuestLocked[entryIndex] = true
        set ABP_EntryInitialQuestLockedText[entryIndex] = lockedText
    endfunction

    private function ABP_RegisterElemental takes nothing returns nothing
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A6A0', 'A67F', 5, 0)     // Lightning Bolt
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A67H', 'A67I', 5, 0)     // Lightning Strike
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A67L', 'A67M', 5, 0)     // Chain Lightning
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A67J', 'A67K', 5, 0)     // Fire Shock
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A69L', 'A69P', 5, 0)     // Frost Shock
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A69N', 'A69Q', 5, 0)     // Nature Shock
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A68H', 'A67C', 5, 0)     // Lightning Shield
        call ABP_RegisterAbility(TREE_ELEMENTAL, 'A67Q', 'A67R', 5, 'A6A3') // Summon Elemental, requires Stormcaller
        call ABP_RegisterSpecialization(TREE_ELEMENTAL, 'A6A3', 0)         // Stormcaller
    endfunction

    private function ABP_RegisterEnhancement takes nothing returns nothing
        local integer entryIndex

        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A685', 'A681', 5, 0)   // Stormstrike
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A6DP', 'A6DQ', 5, 0)   // Whirlwind
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A026', 'A027', 1, 0)   // Wind Shear
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A022', 'A023', 5, 0)   // Primal Force
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A67N', 'A67O', 5, 0)   // Bloodlust
        set entryIndex = ABP_RegisterAbility(TREE_ENHANCEMENT, 'A68Y', 'A680', 5, 0) // Ghost Wolf / Spirit Wolf
        call ABP_SetEntryInitialQuestLocked(entryIndex, "Requires Spirit Wolf quest training.")
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A679', 'A67D', 5, 0)   // Feral Spirits
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A673', 'A674', 5, 0)   // Hex
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A675', 'A676', 5, 0)   // Voodoo Curse
        call ABP_RegisterAbility(TREE_ENHANCEMENT, 'A677', 'A678', 5, 0)   // Voodoo Spirits
        call ABP_RegisterSpecialization(TREE_ENHANCEMENT, 'A6A4', 0)       // Earthwarden
    endfunction

    private function ABP_RegisterRestoration takes nothing returns nothing
        call ABP_RegisterAbility(TREE_RESTORATION, 'A66Y', 'A66X', 5, 0)   // Healing Wave
        call ABP_RegisterAbility(TREE_RESTORATION, 'A672', 'A66Z', 5, 0)   // Chain Heal
        call ABP_RegisterAbility(TREE_RESTORATION, 'A66W', 'A671', 5, 0)   // Healing Rain
        call ABP_RegisterAbility(TREE_RESTORATION, 'A69W', 'A69X', 5, 0)   // Rejuvenation
        call ABP_RegisterAbility(TREE_RESTORATION, 'A62Z', 'A6CC', 5, 0)   // Water Shield
        call ABP_RegisterAbility(TREE_RESTORATION, 'A01Z', 'A639', 2, 0)   // Spirit Link
        call ABP_RegisterAbility(TREE_RESTORATION, 'A6AL', 'A6AJ', 5, 0)   // Ancestral Ward
        call ABP_RegisterAbility(TREE_RESTORATION, 'A638', 'A639', 1, 0)   // Spiritual Healing
        call ABP_RegisterAbility(TREE_RESTORATION, 'A69Y', 'A69Z', 1, 0)   // Totemic Resurgence
        call ABP_RegisterAbility(TREE_RESTORATION, 'A68A', 'A68B', 2, 0)   // Reincarnation
        call ABP_RegisterSpecialization(TREE_RESTORATION, 'A6A2', 'A6A8')  // Spiritmender
    endfunction

    private function ABP_RegisterTotemic takes nothing returns nothing
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A63F', 'A67S', 2, 0)       // Earth Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A63G', 'A67U', 2, 0)       // Fire Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A63H', 'A67T', 2, 0)       // Water Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A63I', 'A67V', 2, 0)       // Wind Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A68J', 'A67W', 2, 0)       // Stoneskin Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A68L', 'A67Z', 2, 0)       // Earthbind Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A68F', 'A68G', 2, 0)       // Cleansing Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A68T', 'A67Y', 2, 0)       // Windfury Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A01U', 'A67X', 2, 0)       // Skyfury Totem
        call ABP_RegisterAbility(TREE_TOTEMIC, 'A636', 'A637', 1, 0)       // Totem Master
        call ABP_RegisterSpecialization(TREE_TOTEMIC, 'A6A5', 'A6A9')      // Totemist
    endfunction

    private function ABP_EntryMatchesPage takes integer entryIndex, integer pageId returns boolean
        if pageId == PAGE_ALL then
            return true
        elseif pageId == PAGE_ABILITIES then
            return ABP_EntryKind[entryIndex] == ENTRY_ABILITY
        elseif pageId == PAGE_SPECIALIZATIONS then
            return ABP_EntryKind[entryIndex] == ENTRY_SPECIALIZATION
        elseif pageId == PAGE_TALENTS then
            return ABP_EntryKind[entryIndex] == ENTRY_TALENT
        endif
        return true
    endfunction

    public function EnsureInitialized takes nothing returns nothing
        if ABP_Initialized then
            return
        endif

        set ABP_Initialized = true
        set ABP_EntryCount = 0

        call ABP_RegisterElemental()
        call ABP_RegisterEnhancement()
        call ABP_RegisterRestoration()
        call ABP_RegisterTotemic()
    endfunction

    public function IsValidEntry takes integer entryIndex returns boolean
        call EnsureInitialized()
        return entryIndex >= 1 and entryIndex <= ABP_EntryCount
    endfunction

    public function GetEntryCount takes nothing returns integer
        call EnsureInitialized()
        return ABP_EntryCount
    endfunction

    public function GetEntryTree takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return TREE_NONE
        endif
        return ABP_EntryTree[entryIndex]
    endfunction

    public function GetEntryKind takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryKind[entryIndex]
    endfunction

    public function GetEntryAbilityId takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryAbilityId[entryIndex]
    endfunction

    public function GetEntryAddAbilityId takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        if ABP_EntryAddAbilityId[entryIndex] != 0 then
            return ABP_EntryAddAbilityId[entryIndex]
        endif
        return ABP_EntryAbilityId[entryIndex]
    endfunction

    public function GetEntryPermanentAbilityId takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryPermanentAbilityId[entryIndex]
    endfunction

    public function GetEntryRequiredAbilityId takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryRequiredAbilityId[entryIndex]
    endfunction

    public function GetEntryMaxLevel takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryMaxLevel[entryIndex]
    endfunction

    public function GetEntryCost takes integer entryIndex returns integer
        if not IsValidEntry(entryIndex) then
            return 0
        endif
        return ABP_EntryCost[entryIndex]
    endfunction

    public function IsEntryInitialQuestLocked takes integer entryIndex returns boolean
        if not IsValidEntry(entryIndex) then
            return false
        endif
        return ABP_EntryInitialQuestLocked[entryIndex]
    endfunction

    public function GetEntryInitialQuestLockedText takes integer entryIndex returns string
        if not IsValidEntry(entryIndex) then
            return ""
        endif
        if ABP_EntryInitialQuestLockedText[entryIndex] == "" then
            return "Requires quest training."
        endif
        return ABP_EntryInitialQuestLockedText[entryIndex]
    endfunction

    public function GetEntryByAbilityId takes integer abilityId returns integer
        local integer entryIndex = 1

        if abilityId == 0 then
            return 0
        endif

        call EnsureInitialized()
        loop
            exitwhen entryIndex > ABP_EntryCount
            if ABP_EntryAbilityId[entryIndex] == abilityId or ABP_EntryAddAbilityId[entryIndex] == abilityId or ABP_EntryPermanentAbilityId[entryIndex] == abilityId then
                return entryIndex
            endif
            set entryIndex = entryIndex + 1
        endloop

        return 0
    endfunction

    public function GetEntryCountForTreePage takes integer treeId, integer pageId returns integer
        local integer entryIndex = 1
        local integer count = 0

        call EnsureInitialized()
        loop
            exitwhen entryIndex > ABP_EntryCount
            if ABP_EntryTree[entryIndex] == treeId and ABP_EntryMatchesPage(entryIndex, pageId) then
                set count = count + 1
            endif
            set entryIndex = entryIndex + 1
        endloop

        return count
    endfunction

    public function GetEntryByTreePageIndex takes integer treeId, integer pageId, integer filteredIndex returns integer
        local integer entryIndex = 1
        local integer count = 0

        if filteredIndex < 1 then
            return 0
        endif

        call EnsureInitialized()
        loop
            exitwhen entryIndex > ABP_EntryCount
            if ABP_EntryTree[entryIndex] == treeId and ABP_EntryMatchesPage(entryIndex, pageId) then
                set count = count + 1
                if count == filteredIndex then
                    return entryIndex
                endif
            endif
            set entryIndex = entryIndex + 1
        endloop

        return 0
    endfunction

    public function IsTrainerUnitType takes integer unitTypeId returns boolean
        return unitTypeId == TRAINER_ELEMENTAL or unitTypeId == TRAINER_ENHANCEMENT or unitTypeId == TRAINER_RESTORATION or unitTypeId == TRAINER_TOTEMIC
    endfunction

    public function GetTrainerTreeByUnitType takes integer unitTypeId returns integer
        if unitTypeId == TRAINER_ELEMENTAL then
            return TREE_ELEMENTAL
        elseif unitTypeId == TRAINER_ENHANCEMENT then
            return TREE_ENHANCEMENT
        elseif unitTypeId == TRAINER_RESTORATION then
            return TREE_RESTORATION
        elseif unitTypeId == TRAINER_TOTEMIC then
            return TREE_TOTEMIC
        endif
        return TREE_NONE
    endfunction

    public function GetTreeName takes integer treeId returns string
        if treeId == TREE_ELEMENTAL then
            return "Elemental"
        elseif treeId == TREE_ENHANCEMENT then
            return "Enhancement"
        elseif treeId == TREE_RESTORATION then
            return "Restoration"
        elseif treeId == TREE_TOTEMIC then
            return "Totemic"
        endif
        return "Abilities"
    endfunction

    public function GetTreeColor takes integer treeId returns string
        if treeId == TREE_ELEMENTAL then
            return "|cff69ccf0"
        elseif treeId == TREE_ENHANCEMENT then
            return "|cffc79c6e"
        elseif treeId == TREE_RESTORATION then
            return "|cff00ff96"
        elseif treeId == TREE_TOTEMIC then
            return "|cffd9b56d"
        endif
        return "|cffbfbfbf"
    endfunction

    public function GetEntryKindName takes integer entryIndex returns string
        local integer kind = GetEntryKind(entryIndex)

        if kind == ENTRY_SPECIALIZATION then
            return "Specialization"
        elseif kind == ENTRY_TALENT then
            return "Talent"
        elseif kind == ENTRY_ABILITY then
            return "Ability"
        endif
        return ""
    endfunction

    public function GetEntryTitle takes integer entryIndex returns string
        local integer abilityId
        local string titleText

        if not IsValidEntry(entryIndex) then
            return "Ability"
        endif

        set titleText = ABP_EntryTitleOverride[entryIndex]
        if titleText != null and titleText != "" then
            return titleText
        endif

        set abilityId = ABP_EntryAbilityId[entryIndex]
        if abilityId != 0 then
            set titleText = BlzGetAbilityTooltip(abilityId, 0)
            if titleText != null and titleText != "" then
                return ABP_StripTooltipLevelSuffix(titleText)
            endif

            set titleText = GetObjectName(abilityId)
            if titleText != null and titleText != "" then
                return titleText
            endif
        endif

        return "Ability"
    endfunction

    public function GetEntryIcon takes integer entryIndex returns string
        local string iconPath

        if not IsValidEntry(entryIndex) then
            return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        endif

        set iconPath = BlzGetAbilityIcon(ABP_EntryAbilityId[entryIndex])
        if iconPath == null or iconPath == "" then
            return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        endif
        return iconPath
    endfunction

    public function GetEntryBodyForLevel takes integer entryIndex, integer abilityLevel returns string
        local integer abilityId
        local integer levelIndex
        local string bodyText

        if not IsValidEntry(entryIndex) then
            return ""
        endif

        set bodyText = ABP_EntryBodyOverride[entryIndex]
        if bodyText != null and bodyText != "" then
            return bodyText
        endif

        set abilityId = ABP_EntryAbilityId[entryIndex]
        if abilityId == 0 then
            return ""
        endif

        if abilityLevel < 1 then
            set abilityLevel = 1
        endif
        set levelIndex = abilityLevel - 1
        set bodyText = BlzGetAbilityExtendedTooltip(abilityId, levelIndex)
        if bodyText == null or bodyText == "" then
            set bodyText = BlzGetAbilityTooltip(abilityId, levelIndex)
        endif
        if bodyText == null or bodyText == "" then
            return "No description configured yet."
        endif
        return bodyText
    endfunction

    private function Init takes nothing returns nothing
        call EnsureInitialized()
    endfunction
endlibrary
