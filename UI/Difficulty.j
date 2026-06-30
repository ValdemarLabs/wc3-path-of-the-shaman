/**
    Difficulty

    Author: Valdemar
    Version:

    Description:
    Central map difficulty profile manager. Applies the selected SettingsUI
    difficulty to supported Warcraft III native difficulty and handicap fields,
    and exposes profile multipliers for reward systems that need custom scaling.

    Credits:
    Blizzard native difficulty and handicap API.

    How to install:
    Import before SettingsUI. Tune the profile constants below to change what
    Story, Normal, and Hard mean for the map.

    API:
    call Difficulty_SetDifficulty(integer difficulty)
    call Difficulty_Apply()
    call Difficulty_GetDifficulty()
    call Difficulty_GetCreepHealthMultiplier()
    call Difficulty_GetCreepDamageMultiplier()
    call Difficulty_GetCreepGoldMultiplier()

**/
library Difficulty initializer Init
    globals
        constant integer DIFFICULTY_STORY = 1
        constant integer DIFFICULTY_NORMAL = 2
        constant integer DIFFICULTY_HARD = 3

        private constant boolean DEBUG = false

        // Profile: hostile-player health and damage handicap.
        private constant real DIFFICULTY_STORY_CREEP_HP = 0.85
        private constant real DIFFICULTY_NORMAL_CREEP_HP = 1.00
        private constant real DIFFICULTY_HARD_CREEP_HP = 1.20
        private constant real DIFFICULTY_STORY_CREEP_DAMAGE = 0.85
        private constant real DIFFICULTY_NORMAL_CREEP_DAMAGE = 1.00
        private constant real DIFFICULTY_HARD_CREEP_DAMAGE = 1.15

        // Profile: player-facing scaling. Custom gold systems can read the gold multiplier.
        private constant real DIFFICULTY_STORY_HERO_XP = 1.10
        private constant real DIFFICULTY_NORMAL_HERO_XP = 1.00
        private constant real DIFFICULTY_HARD_HERO_XP = 0.95
        private constant real DIFFICULTY_STORY_HERO_REVIVE = 0.85
        private constant real DIFFICULTY_NORMAL_HERO_REVIVE = 1.00
        private constant real DIFFICULTY_HARD_HERO_REVIVE = 1.15
        private constant real DIFFICULTY_STORY_CREEP_GOLD = 1.10
        private constant real DIFFICULTY_NORMAL_CREEP_GOLD = 1.00
        private constant real DIFFICULTY_HARD_CREEP_GOLD = 0.85

        private boolean DifficultyInitialized = false
        private integer DifficultyCurrent = DIFFICULTY_NORMAL
        private real DifficultyCreepHealthMultiplier = DIFFICULTY_NORMAL_CREEP_HP
        private real DifficultyCreepDamageMultiplier = DIFFICULTY_NORMAL_CREEP_DAMAGE
        private real DifficultyCreepGoldMultiplier = DIFFICULTY_NORMAL_CREEP_GOLD
        private real DifficultyHeroXPMultiplier = DIFFICULTY_NORMAL_HERO_XP
        private real DifficultyHeroReviveMultiplier = DIFFICULTY_NORMAL_HERO_REVIVE
    endglobals

    private function DebugMsg takes string msg returns nothing
        if DEBUG then
            call BJDebugMsg("[Difficulty] " + msg)
        endif
    endfunction

    private function ClampDifficulty takes integer difficulty returns integer
        if difficulty < DIFFICULTY_STORY then
            return DIFFICULTY_STORY
        endif
        if difficulty > DIFFICULTY_HARD then
            return DIFFICULTY_HARD
        endif
        return difficulty
    endfunction

    private function ApplyProfileValues takes nothing returns nothing
        if DifficultyCurrent == DIFFICULTY_STORY then
            set DifficultyCreepHealthMultiplier = DIFFICULTY_STORY_CREEP_HP
            set DifficultyCreepDamageMultiplier = DIFFICULTY_STORY_CREEP_DAMAGE
            set DifficultyCreepGoldMultiplier = DIFFICULTY_STORY_CREEP_GOLD
            set DifficultyHeroXPMultiplier = DIFFICULTY_STORY_HERO_XP
            set DifficultyHeroReviveMultiplier = DIFFICULTY_STORY_HERO_REVIVE
        elseif DifficultyCurrent == DIFFICULTY_HARD then
            set DifficultyCreepHealthMultiplier = DIFFICULTY_HARD_CREEP_HP
            set DifficultyCreepDamageMultiplier = DIFFICULTY_HARD_CREEP_DAMAGE
            set DifficultyCreepGoldMultiplier = DIFFICULTY_HARD_CREEP_GOLD
            set DifficultyHeroXPMultiplier = DIFFICULTY_HARD_HERO_XP
            set DifficultyHeroReviveMultiplier = DIFFICULTY_HARD_HERO_REVIVE
        else
            set DifficultyCreepHealthMultiplier = DIFFICULTY_NORMAL_CREEP_HP
            set DifficultyCreepDamageMultiplier = DIFFICULTY_NORMAL_CREEP_DAMAGE
            set DifficultyCreepGoldMultiplier = DIFFICULTY_NORMAL_CREEP_GOLD
            set DifficultyHeroXPMultiplier = DIFFICULTY_NORMAL_HERO_XP
            set DifficultyHeroReviveMultiplier = DIFFICULTY_NORMAL_HERO_REVIVE
        endif
    endfunction

    private function ApplyGameDifficultyNative takes nothing returns nothing
        if DifficultyCurrent == DIFFICULTY_STORY then
            call SetGameDifficulty(MAP_DIFFICULTY_EASY)
        elseif DifficultyCurrent == DIFFICULTY_HARD then
            call SetGameDifficulty(MAP_DIFFICULTY_HARD)
        else
            call SetGameDifficulty(MAP_DIFFICULTY_NORMAL)
        endif
    endfunction

    private function ApplyHostilePlayerProfile takes player whichPlayer returns nothing
        if whichPlayer == null then
            return
        endif
        call SetPlayerHandicap(whichPlayer, DifficultyCreepHealthMultiplier)
        call SetPlayerHandicapDamage(whichPlayer, DifficultyCreepDamageMultiplier)
        call SetPlayerState(whichPlayer, PLAYER_STATE_GIVES_BOUNTY, 1)
    endfunction

    private function ApplyConfiguredHostilePlayers takes nothing returns nothing
        call ApplyHostilePlayerProfile(Player(2))
        call ApplyHostilePlayerProfile(Player(3))
        call ApplyHostilePlayerProfile(Player(5))
        call ApplyHostilePlayerProfile(Player(9))
        call ApplyHostilePlayerProfile(Player(10))
        call ApplyHostilePlayerProfile(Player(12))
        call ApplyHostilePlayerProfile(Player(14))
        call ApplyHostilePlayerProfile(Player(20))
        call ApplyHostilePlayerProfile(Player(PLAYER_NEUTRAL_AGGRESSIVE))
    endfunction

    public function Apply takes nothing returns nothing
        call ApplyProfileValues()
        call ApplyGameDifficultyNative()
        call ApplyConfiguredHostilePlayers()
        call SetPlayerHandicapXP(Player(0), DifficultyHeroXPMultiplier)
        call SetPlayerHandicapReviveTime(Player(0), DifficultyHeroReviveMultiplier)
        call DebugMsg("Applied difficulty " + I2S(DifficultyCurrent))
    endfunction

    public function SetDifficulty takes integer difficulty returns nothing
        set DifficultyCurrent = ClampDifficulty(difficulty)
        call Apply()
    endfunction

    public function GetDifficulty takes nothing returns integer
        return DifficultyCurrent
    endfunction

    public function GetCreepHealthMultiplier takes nothing returns real
        return DifficultyCreepHealthMultiplier
    endfunction

    public function GetCreepDamageMultiplier takes nothing returns real
        return DifficultyCreepDamageMultiplier
    endfunction

    public function GetCreepGoldMultiplier takes nothing returns real
        return DifficultyCreepGoldMultiplier
    endfunction

    public function GetHeroXPMultiplier takes nothing returns real
        return DifficultyHeroXPMultiplier
    endfunction

    public function GetHeroReviveMultiplier takes nothing returns real
        return DifficultyHeroReviveMultiplier
    endfunction

    private function Init takes nothing returns nothing
        if DifficultyInitialized then
            return
        endif
        set DifficultyInitialized = true
        call Apply()
    endfunction
endlibrary
