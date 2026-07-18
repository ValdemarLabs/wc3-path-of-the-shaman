/**
    AI_CompanionReplies

    Author: Valdemar
    Version:

    Description:
    Registers old GUI paired companion chat replies for the new AI bark system.
    Primary class barks live in each `AI_*` profile library; this file binds
    those primary ExSound keys to matching companion responder profiles.

    Credits:
    - Old GUI companion chat triggers

    How to install:
    Import after `AI.j` and the first-wave `AI_*` profile libraries.

    API:
    Automatic initializer only.

**/
library AICompanionReplies initializer Init requires AI, AIWarrior, AIRogue, AIWarlock, AIRestoshaman, AIPaladin, AIEngineer, VoicelinesCompanionReplies

private function RegisterReply takes string primarySoundKey, integer responderProfileId, string responderName returns nothing
    call AI_RegisterBarkReply(primarySoundKey, responderProfileId, VL_COMPANIONREPLIES_FALLBACK_TEXT, primarySoundKey + responderName)
endfunction

private function RegisterReplyRange takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string responderName returns nothing
    call AI_RegisterBarkReplySequenceSuffix(primarySoundPrefix, first, last, responderProfileId, VL_COMPANIONREPLIES_FALLBACK_TEXT, primarySoundPrefix, responderName)
endfunction

private function RegisterRogueGeneralReplies takes integer responderProfileId, string responderName returns nothing
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL1_PRIMARY, responderProfileId, responderName)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL2_PRIMARY, responderProfileId, responderName)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL4_PRIMARY, responderProfileId, responderName)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATGENERAL5_PRIMARY, responderProfileId, responderName)
endfunction

private function RegisterRoguePaladinReplies takes nothing returns nothing
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN1_PRIMARY, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN2_PRIMARY, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN3_PRIMARY, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReply(VL_COMPANIONREPLIES_HEROROGUE_CHATPALADIN5_PRIMARY, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
endfunction

private function RegisterEngineerReplies takes nothing returns nothing
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX, 1, 7, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX, 1, 7, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX, 1, 7, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX, 1, 7, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATGENERAL_PREFIX, 1, 7, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATPALADIN_PREFIX, 1, 4, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATROGUE_PREFIX, 1, 5, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATSHAMAN_PREFIX, 1, 4, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATWARLOCK_PREFIX, 1, 5, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROENGINEER_CHATWARRIOR_PREFIX, 1, 5, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
endfunction

private function RegisterPaladinReplies takes nothing returns nothing
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX, 1, 5, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX, 1, 7, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX, 1, 7, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX, 1, 7, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATGENERAL_PREFIX, 1, 7, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATENGINEER_PREFIX, 1, 5, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATROGUE_PREFIX, 1, 5, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATSHAMAN_PREFIX, 1, 5, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATWARLOCK_PREFIX, 1, 5, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROPALADIN_CHATWARRIOR_PREFIX, 1, 5, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
endfunction

private function RegisterRogueReplies takes nothing returns nothing
    call RegisterRogueGeneralReplies(AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterRogueGeneralReplies(AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterRogueGeneralReplies(AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterRogueGeneralReplies(AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterRogueGeneralReplies(AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROROGUE_CHATENGINEER_PREFIX, 1, 4, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterRoguePaladinReplies()
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROROGUE_CHATSHAMAN_PREFIX, 1, 4, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROROGUE_CHATWARLOCK_PREFIX, 1, 5, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROROGUE_CHATWARRIOR_PREFIX, 1, 4, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
endfunction

private function RegisterShamanReplies takes nothing returns nothing
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX, 1, 6, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX, 1, 6, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX, 1, 6, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX, 1, 6, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATGENERAL_PREFIX, 1, 6, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATENGINEER_PREFIX, 1, 4, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATPALADIN_PREFIX, 1, 4, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATROGUE_PREFIX, 1, 5, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATWARLOCK_PREFIX, 1, 4, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROSHAMAN_CHATWARRIOR_PREFIX, 1, 4, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
endfunction

private function RegisterWarlockReplies takes nothing returns nothing
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX, 1, 7, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX, 1, 7, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX, 1, 7, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX, 1, 7, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATGENERAL_PREFIX, 1, 7, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATENGINEER_PREFIX, 1, 4, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATPALADIN_PREFIX, 1, 6, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATROGUE_PREFIX, 1, 4, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATSHAMAN_PREFIX, 1, 4, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARLOCK_CHATWARRIOR_PREFIX, 1, 4, AI_Warrior_ProfileId, VL_COMPANIONREPLIES_WARRIOR_RESPONDER)
endfunction

private function RegisterWarriorReplies takes nothing returns nothing
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX, 1, 6, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX, 1, 6, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX, 1, 6, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX, 1, 6, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATGENERAL_PREFIX, 1, 6, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATENGINEER_PREFIX, 1, 4, AI_Engineer_ProfileId, VL_COMPANIONREPLIES_ENGINEER_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATPALADIN_PREFIX, 1, 4, AI_Paladin_ProfileId, VL_COMPANIONREPLIES_PALADIN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATROGUE_PREFIX, 1, 4, AI_Rogue_ProfileId, VL_COMPANIONREPLIES_ROGUE_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATSHAMAN_PREFIX, 1, 4, AI_Restoshaman_ProfileId, VL_COMPANIONREPLIES_SHAMAN_RESPONDER)
    call RegisterReplyRange(VL_COMPANIONREPLIES_HEROWARRIOR_CHATWARLOCK_PREFIX, 1, 4, AI_Warlock_ProfileId, VL_COMPANIONREPLIES_WARLOCK_RESPONDER)
endfunction

private function Init takes nothing returns nothing
    call RegisterEngineerReplies()
    call RegisterPaladinReplies()
    call RegisterRogueReplies()
    call RegisterShamanReplies()
    call RegisterWarlockReplies()
    call RegisterWarriorReplies()
endfunction

endlibrary
