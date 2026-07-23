/**
    Talents

    Author: Valdemar
    Version:

    Description:
    Stores and learns player shaman talent ranks independently from Warcraft
    ability rawcodes. Talents provide reusable rank and effect bonus APIs for
    ability scripts and the talent tree UI. Talent points are primarily awarded
    from player hero level-up events; bonus points are reserved for secondary
    rewards such as quests or items.

    Credits:

    How to install:
    Import after AbilitiesPlayer. Import Events before this library to use the
    central player-unit event dispatcher; otherwise Talents registers its own
    player hero level trigger. Ability scripts can query the public effect
    helpers when applying damage, healing, cooldown, mana, or special behavior.
    Import TalentsElemental, TalentsEnhancement, TalentsRestoration, and
    TalentsTotemic after this library to load the default shaman trees.

    API:
    - set ok = Talents_Learn(hero, talentIndex)
    - set ok = Talents_Allocate(hero, talentIndex)
    - set ok = Talents_Deallocate(hero, talentIndex)
    - set ok = Talents_ConfirmPending(hero)
    - set ok = Talents_CancelPending(hero)
    - set ok = Talents_ResetHeroTalents(hero)
    - set rank = Talents_GetTalentRank(hero, talentIndex)
    - set rank = Talents_GetTalentPreviewRank(hero, talentIndex)
    - set gained = Talents_SyncLevelPoints(hero)
    - set points = Talents_GetAvailablePoints(hero)
    - set points = Talents_GetPreviewAvailablePoints(hero)
    - set bonus = Talents_GetDamageBonusPercent(hero, abilityId)
    - set damage = Talents_ApplyDamageBonus(hero, abilityId, damage)
    - set bonus = Talents_GetHealBonusPercent(hero, abilityId)
    - set healing = Talents_ApplyHealBonus(hero, abilityId, healing)
    - set rank = Talents_GetRankById(hero, talentId)
    - call Talents_RegisterTreeDimensions(treeId, rows, columns)
    - set talent = Talents_RegisterTalent(...)

**/
library Talents initializer Init requires AbilitiesPlayer, optional AbilityPoints, optional Events
    globals
        public constant integer RESULT_OK = 1
        public constant integer RESULT_INVALID = 2
        public constant integer RESULT_NOT_ENOUGH_POINTS = 3
        public constant integer RESULT_MAX_RANK = 4
        public constant integer RESULT_REQUIRES_POINTS = 5
        public constant integer RESULT_REQUIRES_TALENT = 6
        public constant integer RESULT_REQUIRES_ABILITY = 7
        public constant integer RESULT_NO_PENDING = 8

        public constant integer EFFECT_NONE = 0
        public constant integer EFFECT_DAMAGE_PERCENT = 1
        public constant integer EFFECT_HEAL_PERCENT = 2
        public constant integer EFFECT_MANA_PERCENT = 3
        public constant integer EFFECT_COOLDOWN_PERCENT = 4
        public constant integer EFFECT_SPECIAL = 5

        public constant integer TALENT_ELEMENTAL_CONVECTION = 101001
        public constant integer TALENT_ELEMENTAL_SHOCK_MASTERY = 101002
        public constant integer TALENT_ELEMENTAL_STORM_FOCUS = 101003
        public constant integer TALENT_ELEMENTAL_ELEMENTAL_PRECISION = 101004

        public constant integer TALENT_ENHANCEMENT_WEAPON_MASTERY = 102001
        public constant integer TALENT_ENHANCEMENT_PRIMAL_MOMENTUM = 102002
        public constant integer TALENT_ENHANCEMENT_FERAL_BOND = 102003
        public constant integer TALENT_ENHANCEMENT_SPIRIT_FURY = 102004

        public constant integer TALENT_RESTORATION_TIDAL_FOCUS = 103001
        public constant integer TALENT_RESTORATION_MENDING_RAIN = 103002
        public constant integer TALENT_RESTORATION_ANCESTRAL_GRACE = 103003
        public constant integer TALENT_RESTORATION_SPIRIT_FLOW = 103004

        public constant integer TALENT_TOTEMIC_EARTHEN_RESONANCE = 104001
        public constant integer TALENT_TOTEMIC_TOTEMIC_MIGHT = 104002
        public constant integer TALENT_TOTEMIC_SKYFURY_FOCUS = 104003
        public constant integer TALENT_TOTEMIC_TOTEMIC_HARMONY = 104004

        private constant integer TLT_MAX_TALENTS = 96
        private constant integer TLT_RANK_KEY_STRIDE = 128
        private constant integer TLT_FIRST_TALENT_LEVEL = 2
        private constant integer TLT_POINTS_PER_LEVEL = 1
        private constant integer TLT_HERO_NAZGREK = 1
        private constant integer TLT_HERO_ZULKIS = 2

        private boolean TLT_Initialized = false
        private integer TLT_TalentCount = 0
        private integer TLT_LastResult = RESULT_OK

        private integer array TLT_TalentId
        private integer array TLT_TalentTree
        private integer array TLT_TalentRow
        private integer array TLT_TalentColumn
        private integer array TLT_TalentMaxRank
        private integer array TLT_TalentRequiredTreePoints
        private integer array TLT_TalentRequiredTalentId
        private integer array TLT_TalentRequiredTalentRank
        private integer array TLT_TalentRequiredAbilityId
        private integer array TLT_TalentEffectType
        private integer array TLT_TalentEffectAbilityId
        private integer array TLT_TalentValuePerRank
        private string array TLT_TalentIconPath
        private string array TLT_TalentTitle
        private string array TLT_TalentBody
        private integer array TLT_TreeRows
        private integer array TLT_TreeColumns

        private integer array TLT_HeroLevelPoints
        private integer array TLT_HeroBonusPoints
        private integer array TLT_HeroTalentRank
        private integer array TLT_HeroPendingRank

        private trigger TLT_LevelTrigger = null
    endglobals

    private function TLT_GetRankKey takes integer heroSlot, integer talentIndex returns integer
        return heroSlot * TLT_RANK_KEY_STRIDE + talentIndex
    endfunction

    private function TLT_GetHeroSlot takes unit hero returns integer
        if hero == udg_Nazgrek then
            return TLT_HERO_NAZGREK
        elseif hero == udg_Zulkis then
            return TLT_HERO_ZULKIS
        endif
        return 0
    endfunction

    private function TLT_IsPlayerShamanHero takes unit hero returns boolean
        if hero == null or GetHandleId(hero) == 0 then
            return false
        endif
        return TLT_GetHeroSlot(hero) != 0 and GetOwningPlayer(hero) == Player(0)
    endfunction

    private function TLT_GetFeedbackPlayer takes unit hero returns player
        if hero != null then
            return GetOwningPlayer(hero)
        endif
        return Player(0)
    endfunction

    private function TLT_PlaySoundForPlayer takes sound whichSound, player whichPlayer returns nothing
        if whichSound != null and whichPlayer != null and GetLocalPlayer() == whichPlayer then
            call StopSound(whichSound, false, false)
            call StartSound(whichSound)
        endif
    endfunction

    private function TLT_PlayLearnSound takes player whichPlayer returns nothing
        call TLT_PlaySoundForPlayer(gg_snd_NewAbility, whichPlayer)
    endfunction

    private function TLT_PlayErrorSound takes player whichPlayer returns nothing
        call TLT_PlaySoundForPlayer(gg_snd_Error, whichPlayer)
    endfunction

    private function TLT_DisplayToHeroOwner takes unit hero, string message returns nothing
        local player feedbackPlayer = TLT_GetFeedbackPlayer(hero)

        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, message)

        set feedbackPlayer = null
    endfunction

    private function TLT_ShowPointGainText takes unit hero, integer amount returns nothing
        if amount <= 0 then
            return
        endif

        if amount == 1 then
            call TLT_DisplayToHeroOwner(hero, "|cff80ff80Talent point gained.|r")
        else
            call TLT_DisplayToHeroOwner(hero, "|cff80ff80Talent points gained:|r " + I2S(amount))
        endif
    endfunction

    private function TLT_GetTalentIndexByIdRaw takes integer talentId returns integer
        local integer talentIndex = 1

        if talentId == 0 then
            return 0
        endif

        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentId[talentIndex] == talentId then
                return talentIndex
            endif
            set talentIndex = talentIndex + 1
        endloop

        return 0
    endfunction

    public function RegisterTreeDimensions takes integer treeId, integer rows, integer columns returns nothing
        if treeId <= AbilitiesPlayer_TREE_NONE or rows <= 0 or columns <= 0 then
            return
        endif

        set TLT_TreeRows[treeId] = rows
        set TLT_TreeColumns[treeId] = columns
    endfunction

    public function RegisterTalent takes integer talentId, integer treeId, integer row, integer column, integer maxRank, integer requiredTreePoints, integer requiredTalentId, integer requiredTalentRank, integer requiredAbilityId, integer effectType, integer effectAbilityId, integer valuePerRank, string iconPath, string titleText, string bodyText returns integer
        local integer existingIndex = TLT_GetTalentIndexByIdRaw(talentId)

        if existingIndex != 0 then
            return existingIndex
        endif
        if TLT_TalentCount >= TLT_MAX_TALENTS or talentId == 0 or treeId <= AbilitiesPlayer_TREE_NONE or row <= 0 or column <= 0 or maxRank <= 0 then
            return 0
        endif

        set TLT_TalentCount = TLT_TalentCount + 1
        set TLT_TalentId[TLT_TalentCount] = talentId
        set TLT_TalentTree[TLT_TalentCount] = treeId
        set TLT_TalentRow[TLT_TalentCount] = row
        set TLT_TalentColumn[TLT_TalentCount] = column
        set TLT_TalentMaxRank[TLT_TalentCount] = maxRank
        set TLT_TalentRequiredTreePoints[TLT_TalentCount] = requiredTreePoints
        set TLT_TalentRequiredTalentId[TLT_TalentCount] = requiredTalentId
        set TLT_TalentRequiredTalentRank[TLT_TalentCount] = requiredTalentRank
        set TLT_TalentRequiredAbilityId[TLT_TalentCount] = requiredAbilityId
        set TLT_TalentEffectType[TLT_TalentCount] = effectType
        set TLT_TalentEffectAbilityId[TLT_TalentCount] = effectAbilityId
        set TLT_TalentValuePerRank[TLT_TalentCount] = valuePerRank
        set TLT_TalentIconPath[TLT_TalentCount] = iconPath
        set TLT_TalentTitle[TLT_TalentCount] = titleText
        set TLT_TalentBody[TLT_TalentCount] = bodyText

        return TLT_TalentCount
    endfunction

    private function TLT_RegisterTalentLibraries takes nothing returns nothing
        static if LIBRARY_TalentsElemental then
            call ExecuteFunc("TalentsElemental_Register")
        endif
        static if LIBRARY_TalentsEnhancement then
            call ExecuteFunc("TalentsEnhancement_Register")
        endif
        static if LIBRARY_TalentsRestoration then
            call ExecuteFunc("TalentsRestoration_Register")
        endif
        static if LIBRARY_TalentsTotemic then
            call ExecuteFunc("TalentsTotemic_Register")
        endif
    endfunction

    public function EnsureInitialized takes nothing returns nothing
        if TLT_Initialized then
            return
        endif

        set TLT_Initialized = true
        set TLT_TalentCount = 0
        call RegisterTreeDimensions(AbilitiesPlayer_TREE_ELEMENTAL, 8, 6)
        call RegisterTreeDimensions(AbilitiesPlayer_TREE_ENHANCEMENT, 8, 6)
        call RegisterTreeDimensions(AbilitiesPlayer_TREE_RESTORATION, 8, 6)
        call RegisterTreeDimensions(AbilitiesPlayer_TREE_TOTEMIC, 8, 6)
        call TLT_RegisterTalentLibraries()
    endfunction

    public function IsValidTalent takes integer talentIndex returns boolean
        call EnsureInitialized()
        return talentIndex >= 1 and talentIndex <= TLT_TalentCount
    endfunction

    public function GetTalentCount takes nothing returns integer
        call EnsureInitialized()
        return TLT_TalentCount
    endfunction

    public function GetTalentIndexById takes integer talentId returns integer
        local integer talentIndex = 1

        if talentId == 0 then
            return 0
        endif

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentId[talentIndex] == talentId then
                return talentIndex
            endif
            set talentIndex = talentIndex + 1
        endloop

        return 0
    endfunction

    public function GetTalentCountForTree takes integer treeId returns integer
        local integer talentIndex = 1
        local integer count = 0

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentTree[talentIndex] == treeId then
                set count = count + 1
            endif
            set talentIndex = talentIndex + 1
        endloop

        return count
    endfunction

    public function GetTreeRows takes integer treeId returns integer
        call EnsureInitialized()
        if TLT_TreeRows[treeId] <= 0 then
            return 5
        endif
        return TLT_TreeRows[treeId]
    endfunction

    public function GetTreeColumns takes integer treeId returns integer
        call EnsureInitialized()
        if TLT_TreeColumns[treeId] <= 0 then
            return 4
        endif
        return TLT_TreeColumns[treeId]
    endfunction

    public function GetTalentByTreeIndex takes integer treeId, integer filteredIndex returns integer
        local integer talentIndex = 1
        local integer count = 0

        if filteredIndex < 1 then
            return 0
        endif

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentTree[talentIndex] == treeId then
                set count = count + 1
                if count == filteredIndex then
                    return talentIndex
                endif
            endif
            set talentIndex = talentIndex + 1
        endloop

        return 0
    endfunction

    public function GetTalentByTreePosition takes integer treeId, integer row, integer column returns integer
        local integer talentIndex = 1

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentTree[talentIndex] == treeId and TLT_TalentRow[talentIndex] == row and TLT_TalentColumn[talentIndex] == column then
                return talentIndex
            endif
            set talentIndex = talentIndex + 1
        endloop

        return 0
    endfunction

    public function GetTalentId takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentId[talentIndex]
    endfunction

    public function GetTalentTree takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return AbilitiesPlayer_TREE_NONE
        endif
        return TLT_TalentTree[talentIndex]
    endfunction

    public function GetTalentRow takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentRow[talentIndex]
    endfunction

    public function GetTalentColumn takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentColumn[talentIndex]
    endfunction

    public function GetTalentMaxRank takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentMaxRank[talentIndex]
    endfunction

    public function GetTalentRequiredTreePoints takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentRequiredTreePoints[talentIndex]
    endfunction

    public function GetTalentRequiredTalentId takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentRequiredTalentId[talentIndex]
    endfunction

    public function GetTalentRequiredTalentRank takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentRequiredTalentRank[talentIndex]
    endfunction

    public function GetTalentRequiredAbilityId takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentRequiredAbilityId[talentIndex]
    endfunction

    public function GetTalentEffectType takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return EFFECT_NONE
        endif
        return TLT_TalentEffectType[talentIndex]
    endfunction

    public function GetTalentEffectAbilityId takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentEffectAbilityId[talentIndex]
    endfunction

    public function GetTalentValuePerRank takes integer talentIndex returns integer
        if not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_TalentValuePerRank[talentIndex]
    endfunction

    public function GetTalentTitle takes integer talentIndex returns string
        if not IsValidTalent(talentIndex) then
            return "Talent"
        endif
        return TLT_TalentTitle[talentIndex]
    endfunction

    public function GetTalentIcon takes integer talentIndex returns string
        local string iconPath
        local integer abilityId

        if not IsValidTalent(talentIndex) then
            return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        endif

        set iconPath = TLT_TalentIconPath[talentIndex]
        if iconPath != null and iconPath != "" then
            return iconPath
        endif

        set abilityId = TLT_TalentEffectAbilityId[talentIndex]
        if abilityId == 0 then
            set abilityId = TLT_TalentRequiredAbilityId[talentIndex]
        endif
        if abilityId != 0 then
            set iconPath = BlzGetAbilityIcon(abilityId)
            if iconPath != null and iconPath != "" then
                return iconPath
            endif
        endif

        return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    endfunction

    private function TLT_GetPendingRankBySlot takes integer heroSlot, integer talentIndex returns integer
        if heroSlot == 0 or not IsValidTalent(talentIndex) then
            return 0
        endif
        return TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)]
    endfunction

    private function TLT_GetTalentRankBySlotEx takes integer heroSlot, integer talentIndex, boolean includePending returns integer
        local integer rank

        if heroSlot == 0 or not IsValidTalent(talentIndex) then
            return 0
        endif

        set rank = TLT_HeroTalentRank[TLT_GetRankKey(heroSlot, talentIndex)]
        if includePending then
            set rank = rank + TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)]
        endif
        return rank
    endfunction

    private function TLT_GetTalentRankBySlot takes integer heroSlot, integer talentIndex returns integer
        return TLT_GetTalentRankBySlotEx(heroSlot, talentIndex, false)
    endfunction

    public function GetTalentRank takes unit hero, integer talentIndex returns integer
        return TLT_GetTalentRankBySlot(TLT_GetHeroSlot(hero), talentIndex)
    endfunction

    public function GetTalentPendingRank takes unit hero, integer talentIndex returns integer
        return TLT_GetPendingRankBySlot(TLT_GetHeroSlot(hero), talentIndex)
    endfunction

    public function GetTalentPreviewRank takes unit hero, integer talentIndex returns integer
        return TLT_GetTalentRankBySlotEx(TLT_GetHeroSlot(hero), talentIndex, true)
    endfunction

    public function GetRankById takes unit hero, integer talentId returns integer
        return GetTalentRank(hero, GetTalentIndexById(talentId))
    endfunction

    public function GetPreviewRankById takes unit hero, integer talentId returns integer
        return GetTalentPreviewRank(hero, GetTalentIndexById(talentId))
    endfunction

    public function HasTalent takes unit hero, integer talentIndex returns boolean
        return GetTalentRank(hero, talentIndex) > 0
    endfunction

    public function HasTalentById takes unit hero, integer talentId returns boolean
        return GetRankById(hero, talentId) > 0
    endfunction

    private function TLT_GetTreeSpentPointsBySlot takes integer heroSlot, integer treeId, boolean includePending returns integer
        local integer talentIndex = 1
        local integer spent = 0

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_TalentTree[talentIndex] == treeId then
                set spent = spent + TLT_GetTalentRankBySlotEx(heroSlot, talentIndex, includePending)
            endif
            set talentIndex = talentIndex + 1
        endloop

        return spent
    endfunction

    private function TLT_GetSpentPointsBySlot takes integer heroSlot, boolean includePending returns integer
        local integer talentIndex = 1
        local integer spent = 0

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            set spent = spent + TLT_GetTalentRankBySlotEx(heroSlot, talentIndex, includePending)
            set talentIndex = talentIndex + 1
        endloop

        return spent
    endfunction

    public function GetTreeSpentPoints takes unit hero, integer treeId returns integer
        return TLT_GetTreeSpentPointsBySlot(TLT_GetHeroSlot(hero), treeId, false)
    endfunction

    public function GetTreePreviewSpentPoints takes unit hero, integer treeId returns integer
        return TLT_GetTreeSpentPointsBySlot(TLT_GetHeroSlot(hero), treeId, true)
    endfunction

    public function GetSpentPoints takes unit hero returns integer
        return TLT_GetSpentPointsBySlot(TLT_GetHeroSlot(hero), false)
    endfunction

    public function GetPreviewSpentPoints takes unit hero returns integer
        return TLT_GetSpentPointsBySlot(TLT_GetHeroSlot(hero), true)
    endfunction

    public function GetPendingSpentPoints takes unit hero returns integer
        return GetPreviewSpentPoints(hero) - GetSpentPoints(hero)
    endfunction

    private function TLT_GetLevelPointTotalForHeroLevel takes integer heroLevel returns integer
        if heroLevel < TLT_FIRST_TALENT_LEVEL then
            return 0
        endif

        return (heroLevel - TLT_FIRST_TALENT_LEVEL + 1) * TLT_POINTS_PER_LEVEL
    endfunction

    private function TLT_AwardLevelPoints takes unit hero, integer amount, boolean showFeedback returns nothing
        local integer heroSlot = TLT_GetHeroSlot(hero)

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) or amount <= 0 then
            return
        endif

        set TLT_HeroLevelPoints[heroSlot] = TLT_HeroLevelPoints[heroSlot] + amount
        if showFeedback then
            call TLT_ShowPointGainText(hero, amount)
        endif
    endfunction

    private function TLT_SyncLevelPointsForHero takes unit hero, boolean showFeedback returns integer
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer targetPoints
        local integer gainedPoints

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) then
            return 0
        endif

        set targetPoints = TLT_GetLevelPointTotalForHeroLevel(GetHeroLevel(hero))
        if targetPoints <= TLT_HeroLevelPoints[heroSlot] then
            return 0
        endif

        set gainedPoints = targetPoints - TLT_HeroLevelPoints[heroSlot]
        set TLT_HeroLevelPoints[heroSlot] = targetPoints
        if showFeedback then
            call TLT_ShowPointGainText(hero, gainedPoints)
        endif

        return gainedPoints
    endfunction

    public function SyncLevelPoints takes unit hero returns integer
        return TLT_SyncLevelPointsForHero(hero, true)
    endfunction

    public function GetBasePoints takes unit hero returns integer
        return TLT_HeroLevelPoints[TLT_GetHeroSlot(hero)]
    endfunction

    public function GetBonusPoints takes unit hero returns integer
        return TLT_HeroBonusPoints[TLT_GetHeroSlot(hero)]
    endfunction

    public function GetTotalPoints takes unit hero returns integer
        return GetBasePoints(hero) + GetBonusPoints(hero)
    endfunction

    public function GetAvailablePoints takes unit hero returns integer
        local integer available = GetTotalPoints(hero) - GetSpentPoints(hero)

        if available < 0 then
            return 0
        endif
        return available
    endfunction

    public function GetPreviewAvailablePoints takes unit hero returns integer
        local integer available = GetTotalPoints(hero) - GetPreviewSpentPoints(hero)

        if available < 0 then
            return 0
        endif
        return available
    endfunction

    public function HasPendingChanges takes unit hero returns boolean
        return GetPendingSpentPoints(hero) > 0
    endfunction

    public function AddBonusPoints takes unit hero, integer amount returns nothing
        local integer heroSlot = TLT_GetHeroSlot(hero)

        if heroSlot == 0 or amount == 0 then
            return
        endif

        set TLT_HeroBonusPoints[heroSlot] = TLT_HeroBonusPoints[heroSlot] + amount
        if TLT_HeroBonusPoints[heroSlot] < 0 then
            set TLT_HeroBonusPoints[heroSlot] = 0
        endif
        if amount > 0 then
            call TLT_ShowPointGainText(hero, amount)
        endif
    endfunction

    public function SetBonusPoints takes unit hero, integer amount returns nothing
        local integer heroSlot = TLT_GetHeroSlot(hero)

        if heroSlot == 0 then
            return
        endif
        if amount < 0 then
            set amount = 0
        endif
        set TLT_HeroBonusPoints[heroSlot] = amount
    endfunction

    private function TLT_GetRequiredTalentTitle takes integer talentIndex returns string
        local integer requiredTalentIndex = GetTalentIndexById(TLT_TalentRequiredTalentId[talentIndex])

        if requiredTalentIndex != 0 then
            return GetTalentTitle(requiredTalentIndex)
        endif
        return "required talent"
    endfunction

    private function TLT_GetRequiredAbilityTitle takes integer abilityId returns string
        local integer entryIndex = AbilitiesPlayer_GetEntryByAbilityId(abilityId)
        local string titleText

        if entryIndex != 0 then
            return AbilitiesPlayer_GetEntryTitle(entryIndex)
        endif
        if abilityId != 0 then
            set titleText = BlzGetAbilityTooltip(abilityId, 0)
            if titleText != null and titleText != "" then
                return titleText
            endif
            set titleText = GetObjectName(abilityId)
            if titleText != null and titleText != "" then
                return titleText
            endif
        endif
        return "required ability"
    endfunction

    private function TLT_GetRequirementFailureResultEx takes unit hero, integer talentIndex, boolean includePending returns integer
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer requiredTalentIndex

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) or not IsValidTalent(talentIndex) then
            return RESULT_INVALID
        endif

        if TLT_GetTreeSpentPointsBySlot(heroSlot, TLT_TalentTree[talentIndex], includePending) < TLT_TalentRequiredTreePoints[talentIndex] then
            return RESULT_REQUIRES_POINTS
        endif
        if TLT_TalentRequiredTalentId[talentIndex] != 0 then
            set requiredTalentIndex = GetTalentIndexById(TLT_TalentRequiredTalentId[talentIndex])
            if requiredTalentIndex == 0 or TLT_GetTalentRankBySlotEx(heroSlot, requiredTalentIndex, includePending) < TLT_TalentRequiredTalentRank[talentIndex] then
                return RESULT_REQUIRES_TALENT
            endif
        endif
        if TLT_TalentRequiredAbilityId[talentIndex] != 0 and GetUnitAbilityLevel(hero, TLT_TalentRequiredAbilityId[talentIndex]) <= 0 then
            return RESULT_REQUIRES_ABILITY
        endif

        return RESULT_OK
    endfunction

    private function TLT_GetLearnFailureResultEx takes unit hero, integer talentIndex, boolean includePending returns integer
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer currentRank
        local integer resultCode

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) or not IsValidTalent(talentIndex) then
            return RESULT_INVALID
        endif

        set currentRank = TLT_GetTalentRankBySlotEx(heroSlot, talentIndex, includePending)
        if currentRank >= TLT_TalentMaxRank[talentIndex] then
            return RESULT_MAX_RANK
        endif
        if GetTotalPoints(hero) - TLT_GetSpentPointsBySlot(heroSlot, includePending) <= 0 then
            return RESULT_NOT_ENOUGH_POINTS
        endif

        set resultCode = TLT_GetRequirementFailureResultEx(hero, talentIndex, includePending)
        if resultCode != RESULT_OK then
            return resultCode
        endif

        return RESULT_OK
    endfunction

    private function TLT_GetLearnFailureResult takes unit hero, integer talentIndex returns integer
        return TLT_GetLearnFailureResultEx(hero, talentIndex, false)
    endfunction

    private function TLT_GetAllocateFailureResult takes unit hero, integer talentIndex returns integer
        return TLT_GetLearnFailureResultEx(hero, talentIndex, true)
    endfunction

    private function TLT_FailureMessage takes unit hero, integer talentIndex, integer resultCode returns string
        if resultCode == RESULT_NOT_ENOUGH_POINTS then
            return "|cffff8080No talent points available.|r"
        elseif resultCode == RESULT_MAX_RANK then
            return "|cffffcc00" + GetTalentTitle(talentIndex) + " max rank reached.|r"
        elseif resultCode == RESULT_REQUIRES_POINTS then
            return "|cffff8080Requires " + I2S(TLT_TalentRequiredTreePoints[talentIndex]) + " points in " + AbilitiesPlayer_GetTreeName(TLT_TalentTree[talentIndex]) + ".|r"
        elseif resultCode == RESULT_REQUIRES_TALENT then
            return "|cffff8080Requires " + TLT_GetRequiredTalentTitle(talentIndex) + ".|r"
        elseif resultCode == RESULT_REQUIRES_ABILITY then
            return "|cffff8080Requires " + TLT_GetRequiredAbilityTitle(TLT_TalentRequiredAbilityId[talentIndex]) + ".|r"
        elseif resultCode == RESULT_NO_PENDING then
            return "|cffff8080No pending talent changes.|r"
        endif
        return "|cffff8080Unable to learn talent.|r"
    endfunction

    public function GetLearnFailureText takes unit hero, integer talentIndex returns string
        local integer resultCode = TLT_GetLearnFailureResult(hero, talentIndex)

        if resultCode == RESULT_OK then
            return ""
        endif
        return TLT_FailureMessage(hero, talentIndex, resultCode)
    endfunction

    public function GetAllocateFailureText takes unit hero, integer talentIndex returns string
        local integer resultCode = TLT_GetAllocateFailureResult(hero, talentIndex)

        if resultCode == RESULT_OK then
            return ""
        endif
        return TLT_FailureMessage(hero, talentIndex, resultCode)
    endfunction

    private function TLT_Fail takes unit hero, integer talentIndex, integer resultCode returns boolean
        local player feedbackPlayer = TLT_GetFeedbackPlayer(hero)

        set TLT_LastResult = resultCode
        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, TLT_FailureMessage(hero, talentIndex, resultCode))
        call TLT_PlayErrorSound(feedbackPlayer)

        set feedbackPlayer = null
        return false
    endfunction

    public function CanLearn takes unit hero, integer talentIndex returns boolean
        return TLT_GetLearnFailureResult(hero, talentIndex) == RESULT_OK
    endfunction

    public function CanAllocate takes unit hero, integer talentIndex returns boolean
        return TLT_GetAllocateFailureResult(hero, talentIndex) == RESULT_OK
    endfunction

    public function CanDeallocate takes unit hero, integer talentIndex returns boolean
        return TLT_GetPendingRankBySlot(TLT_GetHeroSlot(hero), talentIndex) > 0
    endfunction

    private function TLT_PruneInvalidPending takes unit hero returns nothing
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer talentIndex
        local boolean changed = true

        if heroSlot == 0 then
            return
        endif

        call EnsureInitialized()
        loop
            exitwhen not changed
            set changed = false
            set talentIndex = 1
            loop
                exitwhen talentIndex > TLT_TalentCount
                if TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] > 0 and TLT_GetRequirementFailureResultEx(hero, talentIndex, true) != RESULT_OK then
                    set TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] = 0
                    set changed = true
                endif
                set talentIndex = talentIndex + 1
            endloop
        endloop
    endfunction

    private function TLT_ClearPendingRanksBySlot takes integer heroSlot returns integer
        local integer talentIndex = 1
        local integer removed = 0
        local integer key

        if heroSlot == 0 then
            return 0
        endif

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            set key = TLT_GetRankKey(heroSlot, talentIndex)
            if TLT_HeroPendingRank[key] > 0 then
                set removed = removed + TLT_HeroPendingRank[key]
                set TLT_HeroPendingRank[key] = 0
            endif
            set talentIndex = talentIndex + 1
        endloop

        return removed
    endfunction

    public function Allocate takes unit hero, integer talentIndex returns boolean
        local integer resultCode = TLT_GetAllocateFailureResult(hero, talentIndex)
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer nextRank

        if resultCode != RESULT_OK then
            return TLT_Fail(hero, talentIndex, resultCode)
        endif

        set TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] = TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] + 1
        set nextRank = TLT_GetTalentRankBySlotEx(heroSlot, talentIndex, true)
        set TLT_LastResult = RESULT_OK

        call TLT_DisplayToHeroOwner(hero, "|cff80ff80Pending talent:|r " + GetTalentTitle(talentIndex) + " Rank " + I2S(nextRank))
        return true
    endfunction

    public function Deallocate takes unit hero, integer talentIndex returns boolean
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer key

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) or not IsValidTalent(talentIndex) then
            return TLT_Fail(hero, talentIndex, RESULT_INVALID)
        endif

        set key = TLT_GetRankKey(heroSlot, talentIndex)
        if TLT_HeroPendingRank[key] <= 0 then
            return TLT_Fail(hero, talentIndex, RESULT_NO_PENDING)
        endif

        set TLT_HeroPendingRank[key] = TLT_HeroPendingRank[key] - 1
        call TLT_PruneInvalidPending(hero)
        set TLT_LastResult = RESULT_OK

        call TLT_DisplayToHeroOwner(hero, "|cffffcc80Pending talent point removed.|r")
        return true
    endfunction

    public function CancelPending takes unit hero returns boolean
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer removed

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) then
            return TLT_Fail(hero, 0, RESULT_INVALID)
        endif

        set removed = TLT_ClearPendingRanksBySlot(heroSlot)
        if removed <= 0 then
            return TLT_Fail(hero, 0, RESULT_NO_PENDING)
        endif

        set TLT_LastResult = RESULT_OK
        call TLT_DisplayToHeroOwner(hero, "|cffffcc80Pending talent changes cancelled.|r")
        return true
    endfunction

    public function ConfirmPending takes unit hero returns boolean
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer talentIndex = 1
        local integer key
        local integer pending
        local integer committed = 0
        local integer resultCode
        local player feedbackPlayer

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) then
            return TLT_Fail(hero, 0, RESULT_INVALID)
        endif
        if GetPendingSpentPoints(hero) <= 0 then
            return TLT_Fail(hero, 0, RESULT_NO_PENDING)
        endif
        if GetTotalPoints(hero) - GetPreviewSpentPoints(hero) < 0 then
            return TLT_Fail(hero, 0, RESULT_NOT_ENOUGH_POINTS)
        endif

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] > 0 then
                set resultCode = TLT_GetRequirementFailureResultEx(hero, talentIndex, true)
                if resultCode != RESULT_OK then
                    return TLT_Fail(hero, talentIndex, resultCode)
                endif
            endif
            set talentIndex = talentIndex + 1
        endloop

        set talentIndex = 1
        loop
            exitwhen talentIndex > TLT_TalentCount
            set key = TLT_GetRankKey(heroSlot, talentIndex)
            set pending = TLT_HeroPendingRank[key]
            if pending > 0 then
                set TLT_HeroTalentRank[key] = TLT_HeroTalentRank[key] + pending
                set TLT_HeroPendingRank[key] = 0
                set committed = committed + pending
            endif
            set talentIndex = talentIndex + 1
        endloop

        set TLT_LastResult = RESULT_OK
        set feedbackPlayer = TLT_GetFeedbackPlayer(hero)
        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, "|cff00ff00Talents confirmed:|r " + I2S(committed) + " point(s).")
        call TLT_PlayLearnSound(feedbackPlayer)

        set feedbackPlayer = null
        return true
    endfunction

    public function Learn takes unit hero, integer talentIndex returns boolean
        local integer resultCode = TLT_GetLearnFailureResult(hero, talentIndex)
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer nextRank
        local player feedbackPlayer

        if resultCode != RESULT_OK then
            return TLT_Fail(hero, talentIndex, resultCode)
        endif

        set nextRank = TLT_GetTalentRankBySlot(heroSlot, talentIndex) + 1
        set TLT_HeroTalentRank[TLT_GetRankKey(heroSlot, talentIndex)] = nextRank
        set TLT_LastResult = RESULT_OK

        set feedbackPlayer = TLT_GetFeedbackPlayer(hero)
        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, "|cff00ff00Talent learned:|r " + GetTalentTitle(talentIndex) + " Rank " + I2S(nextRank))
        call TLT_PlayLearnSound(feedbackPlayer)

        set feedbackPlayer = null
        return true
    endfunction

    public function LearnById takes unit hero, integer talentId returns boolean
        return Learn(hero, GetTalentIndexById(talentId))
    endfunction

    public function ResetHeroTalents takes unit hero returns boolean
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer talentIndex = 1
        local integer removed = 0

        if heroSlot == 0 or not TLT_IsPlayerShamanHero(hero) then
            return TLT_Fail(hero, 0, RESULT_INVALID)
        endif

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_HeroTalentRank[TLT_GetRankKey(heroSlot, talentIndex)] > 0 then
                set removed = removed + TLT_HeroTalentRank[TLT_GetRankKey(heroSlot, talentIndex)]
                set TLT_HeroTalentRank[TLT_GetRankKey(heroSlot, talentIndex)] = 0
            endif
            if TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] > 0 then
                set removed = removed + TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)]
                set TLT_HeroPendingRank[TLT_GetRankKey(heroSlot, talentIndex)] = 0
            endif
            set talentIndex = talentIndex + 1
        endloop

        if removed <= 0 then
            call TLT_DisplayToHeroOwner(hero, "|cffff8080No talents are learned.|r")
            call TLT_PlayErrorSound(TLT_GetFeedbackPlayer(hero))
            set TLT_LastResult = RESULT_INVALID
            return false
        endif

        call TLT_DisplayToHeroOwner(hero, "|cff00ff00Talents reset.|r")
        set TLT_LastResult = RESULT_OK
        return true
    endfunction

    public function GetLastResult takes nothing returns integer
        return TLT_LastResult
    endfunction

    public function IsTalentMaxed takes unit hero, integer talentIndex returns boolean
        return IsValidTalent(talentIndex) and GetTalentRank(hero, talentIndex) >= TLT_TalentMaxRank[talentIndex]
    endfunction

    public function IsTalentPreviewMaxed takes unit hero, integer talentIndex returns boolean
        return IsValidTalent(talentIndex) and GetTalentPreviewRank(hero, talentIndex) >= TLT_TalentMaxRank[talentIndex]
    endfunction

    public function GetTalentStateText takes unit hero, integer talentIndex returns string
        local integer rank
        local integer maxRank
        local integer resultCode

        if not IsValidTalent(talentIndex) then
            return ""
        endif

        set rank = GetTalentRank(hero, talentIndex)
        set maxRank = TLT_TalentMaxRank[talentIndex]
        if rank >= maxRank then
            return "|cffffcc00" + I2S(rank) + "/" + I2S(maxRank) + "|r"
        endif

        set resultCode = TLT_GetLearnFailureResult(hero, talentIndex)
        if resultCode == RESULT_NOT_ENOUGH_POINTS then
            return "|cffff8080TP|r"
        elseif resultCode == RESULT_REQUIRES_POINTS then
            return "|cffff8080" + I2S(TLT_TalentRequiredTreePoints[talentIndex]) + " pts|r"
        elseif resultCode == RESULT_REQUIRES_TALENT or resultCode == RESULT_REQUIRES_ABILITY then
            return "|cffff8080Req|r"
        endif

        return I2S(rank) + "/" + I2S(maxRank)
    endfunction

    private function TLT_GetTalentInfoTextEx takes unit hero, integer talentIndex, boolean includePending returns string
        local integer rank
        local integer maxRank
        local integer treeId
        local string text

        if not IsValidTalent(talentIndex) then
            return ""
        endif

        set rank = TLT_GetTalentRankBySlotEx(TLT_GetHeroSlot(hero), talentIndex, includePending)
        set maxRank = TLT_TalentMaxRank[talentIndex]
        set treeId = TLT_TalentTree[talentIndex]
        set text = AbilitiesPlayer_GetTreeColor(treeId) + AbilitiesPlayer_GetTreeName(treeId) + "|r |cff808080-|r Rank " + I2S(rank) + "/" + I2S(maxRank)

        if TLT_TalentRequiredTreePoints[talentIndex] > 0 then
            set text = text + " |cff808080-|r Req " + I2S(TLT_TalentRequiredTreePoints[talentIndex]) + " tree pts"
        endif
        if TLT_TalentRequiredAbilityId[talentIndex] != 0 then
            set text = text + " |cff808080-|r " + TLT_GetRequiredAbilityTitle(TLT_TalentRequiredAbilityId[talentIndex])
        endif

        return text
    endfunction

    public function GetTalentInfoText takes unit hero, integer talentIndex returns string
        return TLT_GetTalentInfoTextEx(hero, talentIndex, false)
    endfunction

    public function GetTalentPreviewInfoText takes unit hero, integer talentIndex returns string
        return TLT_GetTalentInfoTextEx(hero, talentIndex, true)
    endfunction

    private function TLT_GetEffectLineEx takes unit hero, integer talentIndex, boolean includePending returns string
        local integer rank = TLT_GetTalentRankBySlotEx(TLT_GetHeroSlot(hero), talentIndex, includePending)
        local integer nextRank = rank + 1
        local integer maxRank = TLT_TalentMaxRank[talentIndex]
        local integer value = TLT_TalentValuePerRank[talentIndex]
        local integer effectType = TLT_TalentEffectType[talentIndex]
        local string label = ""

        if value == 0 or effectType == EFFECT_NONE then
            return ""
        endif
        if nextRank > maxRank then
            set nextRank = maxRank
        endif
        if effectType == EFFECT_DAMAGE_PERCENT then
            set label = "damage"
        elseif effectType == EFFECT_HEAL_PERCENT then
            set label = "healing"
        elseif effectType == EFFECT_MANA_PERCENT then
            set label = "mana efficiency"
        elseif effectType == EFFECT_COOLDOWN_PERCENT then
            set label = "cooldown reduction"
        elseif effectType == EFFECT_SPECIAL then
            set label = "special hook value"
        endif

        return "|n|nCurrent " + label + ": +" + I2S(rank * value) + "%|nNext rank: +" + I2S(nextRank * value) + "%"
    endfunction

    private function TLT_GetEffectLine takes unit hero, integer talentIndex returns string
        return TLT_GetEffectLineEx(hero, talentIndex, false)
    endfunction

    public function GetTalentBodyText takes unit hero, integer talentIndex returns string
        if not IsValidTalent(talentIndex) then
            return ""
        endif
        return TLT_TalentBody[talentIndex] + TLT_GetEffectLine(hero, talentIndex)
    endfunction

    public function GetTalentPreviewBodyText takes unit hero, integer talentIndex returns string
        if not IsValidTalent(talentIndex) then
            return ""
        endif
        return TLT_TalentBody[talentIndex] + TLT_GetEffectLineEx(hero, talentIndex, true)
    endfunction

    private function TLT_EffectMatches takes integer talentIndex, integer effectType, integer abilityId returns boolean
        local integer targetAbilityId

        if TLT_TalentEffectType[talentIndex] != effectType then
            return false
        endif

        set targetAbilityId = TLT_TalentEffectAbilityId[talentIndex]
        return targetAbilityId == 0 or abilityId == 0 or targetAbilityId == abilityId
    endfunction

    public function GetEffectBonusPercent takes unit hero, integer effectType, integer abilityId returns integer
        local integer heroSlot = TLT_GetHeroSlot(hero)
        local integer talentIndex = 1
        local integer value = 0

        call EnsureInitialized()
        loop
            exitwhen talentIndex > TLT_TalentCount
            if TLT_EffectMatches(talentIndex, effectType, abilityId) then
                set value = value + TLT_GetTalentRankBySlot(heroSlot, talentIndex) * TLT_TalentValuePerRank[talentIndex]
            endif
            set talentIndex = talentIndex + 1
        endloop

        return value
    endfunction

    public function GetDamageBonusPercent takes unit hero, integer abilityId returns integer
        return GetEffectBonusPercent(hero, EFFECT_DAMAGE_PERCENT, abilityId)
    endfunction

    public function GetHealBonusPercent takes unit hero, integer abilityId returns integer
        return GetEffectBonusPercent(hero, EFFECT_HEAL_PERCENT, abilityId)
    endfunction

    public function GetCooldownBonusPercent takes unit hero, integer abilityId returns integer
        return GetEffectBonusPercent(hero, EFFECT_COOLDOWN_PERCENT, abilityId)
    endfunction

    public function ApplyDamageBonus takes unit hero, integer abilityId, real amount returns real
        return amount * (1.00 + I2R(GetDamageBonusPercent(hero, abilityId)) / 100.00)
    endfunction

    public function ApplyHealBonus takes unit hero, integer abilityId, real amount returns real
        return amount * (1.00 + I2R(GetHealBonusPercent(hero, abilityId)) / 100.00)
    endfunction

    private function TLT_OnHeroLevel takes nothing returns nothing
        local unit hero

        set hero = GetLevelingUnit()

        if not TLT_IsPlayerShamanHero(hero) then
            set hero = null
            return
        endif

        static if LIBRARY_AbilityPoints then
            if not AbilityPoints_IsHeroLevelUpEnabled() then
                set hero = null
                return
            endif
        endif

        if GetHeroLevel(hero) >= TLT_FIRST_TALENT_LEVEL then
            call TLT_AwardLevelPoints(hero, TLT_POINTS_PER_LEVEL, true)
        endif

        set hero = null
    endfunction

    private function TLT_RegisterLevelEvent takes nothing returns nothing
        static if LIBRARY_Events then
            call Events_RegisterPlayerUnitEvent(function TLT_OnHeroLevel, EVENT_PLAYER_HERO_LEVEL)
        else
            set TLT_LevelTrigger = CreateTrigger()
            call TriggerRegisterPlayerUnitEvent(TLT_LevelTrigger, Player(0), EVENT_PLAYER_HERO_LEVEL, null)
            call TriggerAddAction(TLT_LevelTrigger, function TLT_OnHeroLevel)
        endif
    endfunction

    private function TLT_SyncInitialLevelPoints takes nothing returns nothing
        call TLT_SyncLevelPointsForHero(udg_Nazgrek, false)
        call TLT_SyncLevelPointsForHero(udg_Zulkis, false)
    endfunction

    private function Init takes nothing returns nothing
        call EnsureInitialized()
        call TLT_SyncInitialLevelPoints()
        call TLT_RegisterLevelEvent()
    endfunction
endlibrary
