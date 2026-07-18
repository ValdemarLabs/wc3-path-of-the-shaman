/**
    VoicelinesCompanionReplies

    Author: Valdemar
    Version:

    Description:
    Shared primary key, responder, prefix, and fallback text constants for
    AI companion reply registration glue.

    Credits:
    - AI/AI_CompanionReplies.j

    How to install:
    Import after `Voicelines.j`. Consumers require this library directly.

    API:
    Global VL_COMPANIONREPLIES_* constants.

**/
library VoicelinesCompanionReplies requires Voicelines

globals
    // Fallback reply text.
    constant string VL_COMPANIONREPLIES_FALLBACK_TEXT = "A companion answers."

    // Responder names.
    constant string VL_COMPANIONREPLIES_PALADIN_RESPONDER = "Paladin"
    constant string VL_COMPANIONREPLIES_ROGUE_RESPONDER = "Rogue"
    constant string VL_COMPANIONREPLIES_SHAMAN_RESPONDER = "Shaman"
    constant string VL_COMPANIONREPLIES_WARLOCK_RESPONDER = "Warlock"
    constant string VL_COMPANIONREPLIES_WARRIOR_RESPONDER = "Warrior"
    constant string VL_COMPANIONREPLIES_ENGINEER_RESPONDER = "Engineer"

    // Primary key references.
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN1_PRIMARY = "HeroRogue_ChatPaladin1"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN2_PRIMARY = "HeroRogue_ChatPaladin2"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN3_PRIMARY = "HeroRogue_ChatPaladin3"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN5_PRIMARY = "HeroRogue_ChatPaladin5"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL1_PRIMARY = "HeroRogue_ChatGeneral1"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL2_PRIMARY = "HeroRogue_ChatGeneral2"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL4_PRIMARY = "HeroRogue_ChatGeneral4"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL5_PRIMARY = "HeroRogue_ChatGeneral5"

    // Primary key prefixes.
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX = "HeroEngineer_ChatGeneral"
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATPALADIN_PREFIX = "HeroEngineer_ChatPaladin"
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATROGUE_PREFIX = "HeroEngineer_ChatRogue"
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATSHAMAN_PREFIX = "HeroEngineer_ChatShaman"
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATWARLOCK_PREFIX = "HeroEngineer_ChatWarlock"
    constant string VL_COMPANIONREPLIES_HEROENGINEER_CHATWARRIOR_PREFIX = "HeroEngineer_ChatWarrior"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX = "HeroPaladin_ChatGeneral"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATENGINEER_PREFIX = "HeroPaladin_ChatEngineer"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATROGUE_PREFIX = "HeroPaladin_ChatRogue"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATSHAMAN_PREFIX = "HeroPaladin_ChatShaman"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATWARLOCK_PREFIX = "HeroPaladin_ChatWarlock"
    constant string VL_COMPANIONREPLIES_HEROPALADIN_CHATWARRIOR_PREFIX = "HeroPaladin_ChatWarrior"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATENGINEER_PREFIX = "HeroRogue_ChatEngineer"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATSHAMAN_PREFIX = "HeroRogue_ChatShaman"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATWARLOCK_PREFIX = "HeroRogue_ChatWarlock"
    constant string VL_COMPANIONREPLIES_HEROROGUE_CHATWARRIOR_PREFIX = "HeroRogue_ChatWarrior"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX = "HeroShaman_ChatGeneral"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATENGINEER_PREFIX = "HeroShaman_ChatEngineer"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATPALADIN_PREFIX = "HeroShaman_ChatPaladin"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATROGUE_PREFIX = "HeroShaman_ChatRogue"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATWARLOCK_PREFIX = "HeroShaman_ChatWarlock"
    constant string VL_COMPANIONREPLIES_HEROSHAMAN_CHATWARRIOR_PREFIX = "HeroShaman_ChatWarrior"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX = "HeroWarlock_ChatGeneral"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATENGINEER_PREFIX = "HeroWarlock_ChatEngineer"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATPALADIN_PREFIX = "HeroWarlock_ChatPaladin"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATROGUE_PREFIX = "HeroWarlock_ChatRogue"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATSHAMAN_PREFIX = "HeroWarlock_ChatShaman"
    constant string VL_COMPANIONREPLIES_HEROWARLOCK_CHATWARRIOR_PREFIX = "HeroWarlock_ChatWarrior"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX = "HeroWarrior_ChatGeneral"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATENGINEER_PREFIX = "HeroWarrior_ChatEngineer"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATPALADIN_PREFIX = "HeroWarrior_ChatPaladin"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATROGUE_PREFIX = "HeroWarrior_ChatRogue"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATSHAMAN_PREFIX = "HeroWarrior_ChatShaman"
    constant string VL_COMPANIONREPLIES_HEROWARRIOR_CHATWARLOCK_PREFIX = "HeroWarrior_ChatWarlock"

endglobals

endlibrary
