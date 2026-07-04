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
library AICompanionReplies initializer Init requires AI, AIWarrior, AIRogue, AIWarlock, AIRestoshaman, AIPaladin, AIEngineer

private function RegisterReply takes string primarySoundKey, integer responderProfileId, string responderName returns nothing
    call AI_RegisterBarkReply(primarySoundKey, responderProfileId, "A companion answers.", primarySoundKey + responderName)
endfunction

private function RegisterReplyRange takes string primarySoundPrefix, integer first, integer last, integer responderProfileId, string responderName returns nothing
    call AI_RegisterBarkReplySequenceSuffix(primarySoundPrefix, first, last, responderProfileId, "A companion answers.", primarySoundPrefix, responderName)
endfunction

private function RegisterRogueGeneralReplies takes integer responderProfileId, string responderName returns nothing
    call RegisterReply("HeroRogue_ChatGeneral1", responderProfileId, responderName)
    call RegisterReply("HeroRogue_ChatGeneral2", responderProfileId, responderName)
    call RegisterReply("HeroRogue_ChatGeneral4", responderProfileId, responderName)
    call RegisterReply("HeroRogue_ChatGeneral5", responderProfileId, responderName)
endfunction

private function RegisterRoguePaladinReplies takes nothing returns nothing
    call RegisterReply("HeroRogue_ChatPaladin1", AI_Paladin_ProfileId, "Paladin")
    call RegisterReply("HeroRogue_ChatPaladin2", AI_Paladin_ProfileId, "Paladin")
    call RegisterReply("HeroRogue_ChatPaladin3", AI_Paladin_ProfileId, "Paladin")
    call RegisterReply("HeroRogue_ChatPaladin5", AI_Paladin_ProfileId, "Paladin")
endfunction

private function RegisterEngineerReplies takes nothing returns nothing
    call RegisterReplyRange("HeroEngineer_ChatGeneral", 1, 7, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroEngineer_ChatGeneral", 1, 7, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroEngineer_ChatGeneral", 1, 7, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroEngineer_ChatGeneral", 1, 7, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroEngineer_ChatGeneral", 1, 7, AI_Warrior_ProfileId, "Warrior")
    call RegisterReplyRange("HeroEngineer_ChatPaladin", 1, 4, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroEngineer_ChatRogue", 1, 5, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroEngineer_ChatShaman", 1, 4, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroEngineer_ChatWarlock", 1, 5, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroEngineer_ChatWarrior", 1, 5, AI_Warrior_ProfileId, "Warrior")
endfunction

private function RegisterPaladinReplies takes nothing returns nothing
    call RegisterReplyRange("HeroPaladin_ChatGeneral", 1, 5, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroPaladin_ChatGeneral", 1, 7, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroPaladin_ChatGeneral", 1, 7, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroPaladin_ChatGeneral", 1, 7, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroPaladin_ChatGeneral", 1, 7, AI_Warrior_ProfileId, "Warrior")
    call RegisterReplyRange("HeroPaladin_ChatEngineer", 1, 5, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroPaladin_ChatRogue", 1, 5, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroPaladin_ChatShaman", 1, 5, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroPaladin_ChatWarlock", 1, 5, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroPaladin_ChatWarrior", 1, 5, AI_Warrior_ProfileId, "Warrior")
endfunction

private function RegisterRogueReplies takes nothing returns nothing
    call RegisterRogueGeneralReplies(AI_Engineer_ProfileId, "Engineer")
    call RegisterRogueGeneralReplies(AI_Paladin_ProfileId, "Paladin")
    call RegisterRogueGeneralReplies(AI_Restoshaman_ProfileId, "Shaman")
    call RegisterRogueGeneralReplies(AI_Warlock_ProfileId, "Warlock")
    call RegisterRogueGeneralReplies(AI_Warrior_ProfileId, "Warrior")
    call RegisterReplyRange("HeroRogue_ChatEngineer", 1, 4, AI_Engineer_ProfileId, "Engineer")
    call RegisterRoguePaladinReplies()
    call RegisterReplyRange("HeroRogue_ChatShaman", 1, 4, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroRogue_ChatWarlock", 1, 5, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroRogue_ChatWarrior", 1, 4, AI_Warrior_ProfileId, "Warrior")
endfunction

private function RegisterShamanReplies takes nothing returns nothing
    call RegisterReplyRange("HeroShaman_ChatGeneral", 1, 6, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroShaman_ChatGeneral", 1, 6, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroShaman_ChatGeneral", 1, 6, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroShaman_ChatGeneral", 1, 6, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroShaman_ChatGeneral", 1, 6, AI_Warrior_ProfileId, "Warrior")
    call RegisterReplyRange("HeroShaman_ChatEngineer", 1, 4, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroShaman_ChatPaladin", 1, 4, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroShaman_ChatRogue", 1, 5, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroShaman_ChatWarlock", 1, 4, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroShaman_ChatWarrior", 1, 4, AI_Warrior_ProfileId, "Warrior")
endfunction

private function RegisterWarlockReplies takes nothing returns nothing
    call RegisterReplyRange("HeroWarlock_ChatGeneral", 1, 7, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroWarlock_ChatGeneral", 1, 7, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroWarlock_ChatGeneral", 1, 7, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroWarlock_ChatGeneral", 1, 7, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroWarlock_ChatGeneral", 1, 7, AI_Warrior_ProfileId, "Warrior")
    call RegisterReplyRange("HeroWarlock_ChatEngineer", 1, 4, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroWarlock_ChatPaladin", 1, 6, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroWarlock_ChatRogue", 1, 4, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroWarlock_ChatShaman", 1, 4, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroWarlock_ChatWarrior", 1, 4, AI_Warrior_ProfileId, "Warrior")
endfunction

private function RegisterWarriorReplies takes nothing returns nothing
    call RegisterReplyRange("HeroWarrior_ChatGeneral", 1, 6, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroWarrior_ChatGeneral", 1, 6, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroWarrior_ChatGeneral", 1, 6, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroWarrior_ChatGeneral", 1, 6, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroWarrior_ChatGeneral", 1, 6, AI_Warlock_ProfileId, "Warlock")
    call RegisterReplyRange("HeroWarrior_ChatEngineer", 1, 4, AI_Engineer_ProfileId, "Engineer")
    call RegisterReplyRange("HeroWarrior_ChatPaladin", 1, 4, AI_Paladin_ProfileId, "Paladin")
    call RegisterReplyRange("HeroWarrior_ChatRogue", 1, 4, AI_Rogue_ProfileId, "Rogue")
    call RegisterReplyRange("HeroWarrior_ChatShaman", 1, 4, AI_Restoshaman_ProfileId, "Shaman")
    call RegisterReplyRange("HeroWarrior_ChatWarlock", 1, 4, AI_Warlock_ProfileId, "Warlock")
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
