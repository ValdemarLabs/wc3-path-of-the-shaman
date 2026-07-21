/**
    Abilities

    Author: Valdemar
    Version:

    Description:
    Central learner and reset API for player shaman abilities. Uses
    AbilityPoints.j for AP spending and AbilitiesPlayer.j for all ability data.

    Credits:

    How to install:
    Import after AbilitiesPlayer and AbilityPoints. Disable the old GUI player
    ability item-learn triggers so AP is not spent twice.

    API:
    - set ok = Abilities_Learn(hero, entryIndex)
    - set canLearn = Abilities_CanLearn(hero, entryIndex)
    - set level = Abilities_GetEntryLevel(hero, entryIndex)
    - set text = Abilities_GetEntryStateText(hero, entryIndex)
    - set newHero = Abilities_ResetAbilities(hero)
    - set ok = Abilities_ResetSpecialization(hero)
    - set ok = Abilities_ResetTalents(hero)

**/
library Abilities initializer Init requires AbilitiesPlayer, AbilityPoints, optional Talents
    globals
        public constant integer RESULT_OK = 1
        public constant integer RESULT_INVALID = 2
        public constant integer RESULT_NOT_ENOUGH_AP = 3
        public constant integer RESULT_MAX_LEVEL = 4
        public constant integer RESULT_REQUIREMENT = 5
        public constant integer RESULT_HAS_SPECIALIZATION = 6

        private integer AB_LastResult = RESULT_OK
    endglobals

    private function AB_GetFeedbackPlayer takes unit hero returns player
        if hero != null then
            return GetOwningPlayer(hero)
        endif
        return Player(0)
    endfunction

    private function AB_PlaySoundForPlayer takes sound whichSound, player whichPlayer returns nothing
        if whichSound != null and whichPlayer != null and GetLocalPlayer() == whichPlayer then
            call StopSound(whichSound, false, false)
            call StartSound(whichSound)
        endif
    endfunction

    private function AB_PlayLearnSound takes player whichPlayer returns nothing
        call AB_PlaySoundForPlayer(gg_snd_NewAbility, whichPlayer)
    endfunction

    private function AB_PlayErrorSound takes player whichPlayer returns nothing
        call AB_PlaySoundForPlayer(gg_snd_Error, whichPlayer)
    endfunction

    private function AB_DisplayToHeroOwner takes unit hero, string message returns nothing
        local player feedbackPlayer = AB_GetFeedbackPlayer(hero)

        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, message)

        set feedbackPlayer = null
    endfunction

    private function AB_GetHeroDisplayName takes unit hero returns string
        if hero == null then
            return "Hero"
        endif
        if IsUnitType(hero, UNIT_TYPE_HERO) then
            return GetHeroProperName(hero)
        endif
        return GetUnitName(hero)
    endfunction

    private function AB_IsPlayerShamanHero takes unit hero returns boolean
        if hero == null or GetHandleId(hero) == 0 then
            return false
        endif
        if hero != udg_Nazgrek and hero != udg_Zulkis then
            return false
        endif
        return GetOwningPlayer(hero) == Player(0)
    endfunction

    private function AB_GetEntryLevelByAbilityId takes unit hero, integer abilityId returns integer
        if hero == null or abilityId == 0 then
            return 0
        endif
        return GetUnitAbilityLevel(hero, abilityId)
    endfunction

    private function AB_GetEntryLevelRaw takes unit hero, integer entryIndex returns integer
        return AB_GetEntryLevelByAbilityId(hero, AbilitiesPlayer_GetEntryAbilityId(entryIndex))
    endfunction

    private function AB_HasEntryRequirement takes unit hero, integer entryIndex returns boolean
        local integer requiredAbilityId = AbilitiesPlayer_GetEntryRequiredAbilityId(entryIndex)

        if requiredAbilityId == 0 then
            return true
        endif
        return AB_GetEntryLevelByAbilityId(hero, requiredAbilityId) > 0
    endfunction

    private function AB_GetRequiredEntryTitle takes integer entryIndex returns string
        local integer requiredEntry = AbilitiesPlayer_GetEntryByAbilityId(AbilitiesPlayer_GetEntryRequiredAbilityId(entryIndex))

        if requiredEntry != 0 then
            return AbilitiesPlayer_GetEntryTitle(requiredEntry)
        endif
        return "required ability"
    endfunction

    private function AB_HasOtherSpecialization takes unit hero, integer entryIndex returns boolean
        local integer otherEntry = 1
        local integer total = AbilitiesPlayer_GetEntryCount()

        loop
            exitwhen otherEntry > total
            if otherEntry != entryIndex and AbilitiesPlayer_GetEntryKind(otherEntry) == AbilitiesPlayer_ENTRY_SPECIALIZATION and AB_GetEntryLevelRaw(hero, otherEntry) > 0 then
                return true
            endif
            set otherEntry = otherEntry + 1
        endloop

        return false
    endfunction

    private function AB_GetLearnFailureResult takes unit hero, integer entryIndex returns integer
        local integer currentLevel
        local integer maxLevel

        if not AB_IsPlayerShamanHero(hero) or not AbilitiesPlayer_IsValidEntry(entryIndex) then
            return RESULT_INVALID
        endif

        set currentLevel = AB_GetEntryLevelRaw(hero, entryIndex)
        set maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)
        if maxLevel <= 0 then
            return RESULT_INVALID
        endif
        if currentLevel >= maxLevel then
            return RESULT_MAX_LEVEL
        endif
        if AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_SPECIALIZATION and currentLevel <= 0 and AB_HasOtherSpecialization(hero, entryIndex) then
            return RESULT_HAS_SPECIALIZATION
        endif
        if not AB_HasEntryRequirement(hero, entryIndex) then
            return RESULT_REQUIREMENT
        endif
        if AbilityPoints_Get(hero) < AbilitiesPlayer_GetEntryCost(entryIndex) then
            return RESULT_NOT_ENOUGH_AP
        endif

        return RESULT_OK
    endfunction

    private function AB_FailureMessage takes unit hero, integer entryIndex, integer resultCode returns string
        if resultCode == RESULT_NOT_ENOUGH_AP then
            return "|cffff8080" + AB_GetHeroDisplayName(hero) + " does not have enough ability points!|r"
        elseif resultCode == RESULT_MAX_LEVEL then
            return "|cffffcc00" + AbilitiesPlayer_GetEntryTitle(entryIndex) + " max level reached.|r"
        elseif resultCode == RESULT_REQUIREMENT then
            return "|cffff8080Requires " + AB_GetRequiredEntryTitle(entryIndex) + ".|r"
        elseif resultCode == RESULT_HAS_SPECIALIZATION then
            return "|cffff8080" + AB_GetHeroDisplayName(hero) + " already has a specialization!|r"
        endif
        return "|cffff8080Unable to learn " + AbilitiesPlayer_GetEntryTitle(entryIndex) + ".|r"
    endfunction

    private function AB_Fail takes unit hero, integer entryIndex, integer resultCode returns boolean
        local player feedbackPlayer = AB_GetFeedbackPlayer(hero)

        set AB_LastResult = resultCode
        call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, AB_FailureMessage(hero, entryIndex, resultCode))
        call AB_PlayErrorSound(feedbackPlayer)

        set feedbackPlayer = null
        return false
    endfunction

    private function AB_MakeAbilityPermanent takes unit hero, integer abilityId returns nothing
        if hero != null and abilityId != 0 then
            call UnitMakeAbilityPermanent(hero, true, abilityId)
        endif
    endfunction

    private function AB_AddEntryAbility takes unit hero, integer entryIndex returns nothing
        local integer abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        local integer addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
        local integer permanentAbilityId = AbilitiesPlayer_GetEntryPermanentAbilityId(entryIndex)

        if addAbilityId != 0 and GetUnitAbilityLevel(hero, addAbilityId) <= 0 then
            call UnitAddAbility(hero, addAbilityId)
        endif

        call AB_MakeAbilityPermanent(hero, addAbilityId)
        call AB_MakeAbilityPermanent(hero, abilityId)
        if permanentAbilityId != addAbilityId and permanentAbilityId != abilityId then
            call AB_MakeAbilityPermanent(hero, permanentAbilityId)
        endif
    endfunction

    private function AB_Success takes unit hero, integer entryIndex, integer oldLevel returns boolean
        local player feedbackPlayer = AB_GetFeedbackPlayer(hero)
        local integer newLevel = AB_GetEntryLevelRaw(hero, entryIndex)
        local string titleText = AbilitiesPlayer_GetEntryTitle(entryIndex)

        if oldLevel <= 0 then
            if AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_SPECIALIZATION then
                call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, "|cff00ff00New specialization learned:|r " + titleText)
            else
                call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, "|cff00ff00New ability learned:|r " + titleText)
            endif
        else
            if newLevel <= oldLevel then
                set newLevel = oldLevel + 1
            endif
            call DisplayTextToPlayer(feedbackPlayer, 0.00, 0.00, "|cff00ff00Learned:|r " + titleText + " Level " + I2S(newLevel))
        endif

        set AB_LastResult = RESULT_OK
        call AB_PlayLearnSound(feedbackPlayer)

        set feedbackPlayer = null
        return true
    endfunction

    private function AB_RemoveAbilityFromHero takes unit hero, integer abilityId returns nothing
        if hero != null and abilityId != 0 then
            call UnitMakeAbilityPermanent(hero, false, abilityId)
            call UnitRemoveAbility(hero, abilityId)
        endif
    endfunction

    private function AB_RemoveEntryFromHero takes unit hero, integer entryIndex returns nothing
        local integer abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        local integer addAbilityId = AbilitiesPlayer_GetEntryAddAbilityId(entryIndex)
        local integer permanentAbilityId = AbilitiesPlayer_GetEntryPermanentAbilityId(entryIndex)

        call AB_RemoveAbilityFromHero(hero, abilityId)
        if addAbilityId != abilityId then
            call AB_RemoveAbilityFromHero(hero, addAbilityId)
        endif
        if permanentAbilityId != abilityId and permanentAbilityId != addAbilityId then
            call AB_RemoveAbilityFromHero(hero, permanentAbilityId)
        endif
    endfunction

    public function GetLastResult takes nothing returns integer
        return AB_LastResult
    endfunction

    public function GetEntryLevel takes unit hero, integer entryIndex returns integer
        if not AbilitiesPlayer_IsValidEntry(entryIndex) then
            return 0
        endif
        return AB_GetEntryLevelRaw(hero, entryIndex)
    endfunction

    public function GetEntryNextLevel takes unit hero, integer entryIndex returns integer
        local integer currentLevel = GetEntryLevel(hero, entryIndex)
        local integer maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)

        if maxLevel <= 0 then
            return 0
        endif
        if currentLevel < 1 then
            return 1
        elseif currentLevel < maxLevel then
            return currentLevel + 1
        endif
        return maxLevel
    endfunction

    public function IsEntryLearned takes unit hero, integer entryIndex returns boolean
        return GetEntryLevel(hero, entryIndex) > 0
    endfunction

    public function IsEntryMaxed takes unit hero, integer entryIndex returns boolean
        local integer maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)
        return maxLevel > 0 and GetEntryLevel(hero, entryIndex) >= maxLevel
    endfunction

    public function CanLearn takes unit hero, integer entryIndex returns boolean
        return AB_GetLearnFailureResult(hero, entryIndex) == RESULT_OK
    endfunction

    public function GetEntryStateText takes unit hero, integer entryIndex returns string
        local integer currentLevel
        local integer maxLevel
        local integer cost
        local integer resultCode

        if not AbilitiesPlayer_IsValidEntry(entryIndex) then
            return ""
        endif

        set currentLevel = GetEntryLevel(hero, entryIndex)
        set maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)
        set cost = AbilitiesPlayer_GetEntryCost(entryIndex)

        if currentLevel >= maxLevel and maxLevel > 0 then
            if maxLevel > 1 then
                return "|cffffcc00" + I2S(currentLevel) + "/" + I2S(maxLevel) + "|r"
            endif
            return "|cffffcc00Known|r"
        endif

        set resultCode = AB_GetLearnFailureResult(hero, entryIndex)
        if resultCode == RESULT_NOT_ENOUGH_AP then
            return "|cffff8080AP " + I2S(cost) + "|r"
        elseif resultCode == RESULT_REQUIREMENT then
            return "|cffff8080Req|r"
        elseif resultCode == RESULT_HAS_SPECIALIZATION then
            return "|cffff8080Locked|r"
        endif

        if currentLevel > 0 and maxLevel > 1 then
            return I2S(currentLevel) + "/" + I2S(maxLevel)
        elseif cost > 0 then
            return I2S(cost) + " AP"
        endif
        return "Free"
    endfunction

    public function GetEntryInfoText takes unit hero, integer entryIndex returns string
        local integer currentLevel
        local integer maxLevel
        local integer cost
        local integer resultCode
        local integer treeId
        local string text

        if not AbilitiesPlayer_IsValidEntry(entryIndex) then
            return ""
        endif

        set currentLevel = GetEntryLevel(hero, entryIndex)
        set maxLevel = AbilitiesPlayer_GetEntryMaxLevel(entryIndex)
        set cost = AbilitiesPlayer_GetEntryCost(entryIndex)
        set treeId = AbilitiesPlayer_GetEntryTree(entryIndex)
        set text = AbilitiesPlayer_GetTreeColor(treeId) + AbilitiesPlayer_GetTreeName(treeId) + "|r |cff808080-|r " + AbilitiesPlayer_GetEntryKindName(entryIndex)

        if maxLevel > 1 and currentLevel > 0 then
            set text = text + " |cff808080-|r Level " + I2S(currentLevel) + "/" + I2S(maxLevel)
        elseif maxLevel > 1 then
            set text = text + " |cff808080-|r Level 0/" + I2S(maxLevel)
        elseif currentLevel > 0 then
            set text = text + " |cff808080-|r Known"
        endif

        if cost > 0 then
            set text = text + " |cff808080-|r Cost " + I2S(cost) + " AP"
        else
            set text = text + " |cff808080-|r No AP cost"
        endif

        set resultCode = AB_GetLearnFailureResult(hero, entryIndex)
        if resultCode == RESULT_REQUIREMENT then
            set text = text + " |cff808080-|r |cffff8080Requires " + AB_GetRequiredEntryTitle(entryIndex) + "|r"
        elseif resultCode == RESULT_HAS_SPECIALIZATION then
            set text = text + " |cff808080-|r |cffff8080Specialization already chosen|r"
        endif

        return text
    endfunction

    public function GetEntryBodyText takes unit hero, integer entryIndex returns string
        return AbilitiesPlayer_GetEntryBodyForLevel(entryIndex, GetEntryNextLevel(hero, entryIndex))
    endfunction

    public function Learn takes unit hero, integer entryIndex returns boolean
        local integer resultCode = AB_GetLearnFailureResult(hero, entryIndex)
        local integer oldLevel
        local integer abilityId

        if resultCode != RESULT_OK then
            return AB_Fail(hero, entryIndex, resultCode)
        endif

        set oldLevel = GetEntryLevel(hero, entryIndex)
        set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)

        if not AbilityPoints_Spend(hero, AbilitiesPlayer_GetEntryCost(entryIndex)) then
            return AB_Fail(hero, entryIndex, RESULT_NOT_ENOUGH_AP)
        endif

        if oldLevel <= 0 then
            call AB_AddEntryAbility(hero, entryIndex)
        else
            call SetUnitAbilityLevel(hero, abilityId, oldLevel + 1)
        endif

        return AB_Success(hero, entryIndex, oldLevel)
    endfunction

    public function ResetAbilities takes unit hero returns unit
        local unit replacement

        if not AB_IsPlayerShamanHero(hero) then
            call AB_Fail(hero, 0, RESULT_INVALID)
            return hero
        endif

        set replacement = AbilityPoints_ResetHeroAbilities(hero)
        call AB_DisplayToHeroOwner(replacement, "|cff00ff00Abilities reset.|r Ability points restored to " + I2S(AbilityPoints_Get(replacement)) + ".")
        set AB_LastResult = RESULT_OK
        return replacement
    endfunction

    public function ResetSpecialization takes unit hero returns boolean
        local integer entryIndex = 1
        local integer total = AbilitiesPlayer_GetEntryCount()
        local integer removed = 0

        if not AB_IsPlayerShamanHero(hero) then
            return AB_Fail(hero, 0, RESULT_INVALID)
        endif

        loop
            exitwhen entryIndex > total
            if AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_SPECIALIZATION and GetEntryLevel(hero, entryIndex) > 0 then
                call AB_RemoveEntryFromHero(hero, entryIndex)
                set removed = removed + 1
            endif
            set entryIndex = entryIndex + 1
        endloop

        if removed <= 0 then
            call AB_DisplayToHeroOwner(hero, "|cffff8080No specialization is learned.|r")
            call AB_PlayErrorSound(AB_GetFeedbackPlayer(hero))
            set AB_LastResult = RESULT_INVALID
            return false
        endif

        call AB_DisplayToHeroOwner(hero, "|cff00ff00Specialization reset.|r")
        set AB_LastResult = RESULT_OK
        return true
    endfunction

    public function ResetTalents takes unit hero returns boolean
        local integer entryIndex = 1
        local integer total = AbilitiesPlayer_GetEntryCount()
        local integer removed = 0

        if not AB_IsPlayerShamanHero(hero) then
            return AB_Fail(hero, 0, RESULT_INVALID)
        endif

        static if LIBRARY_Talents then
            return Talents_ResetHeroTalents(hero)
        endif

        loop
            exitwhen entryIndex > total
            if AbilitiesPlayer_GetEntryKind(entryIndex) == AbilitiesPlayer_ENTRY_TALENT and GetEntryLevel(hero, entryIndex) > 0 then
                call AB_RemoveEntryFromHero(hero, entryIndex)
                set removed = removed + 1
            endif
            set entryIndex = entryIndex + 1
        endloop

        if removed <= 0 then
            call AB_DisplayToHeroOwner(hero, "|cffff8080No talents are learned.|r")
            call AB_PlayErrorSound(AB_GetFeedbackPlayer(hero))
            set AB_LastResult = RESULT_INVALID
            return false
        endif

        call AB_DisplayToHeroOwner(hero, "|cff00ff00Talents reset.|r")
        set AB_LastResult = RESULT_OK
        return true
    endfunction

    private function Init takes nothing returns nothing
        call AbilitiesPlayer_EnsureInitialized()
    endfunction
endlibrary
