/**
    AI_Aveline

    Author: Valdemar
    Version:

    Description:
    Unique Riverbane Warrior profile for Aveline. This profile reuses the
    shared Warrior ability setup while keeping Aveline's identity, owner,
    caps, barks, random spawning, and legacy `udg_Aveline` mapping separate
    from Horde Warrior instances.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j`, `AI_Warrior.j`, and `ResourceRage.j`. The generated map
    globals must include `udg_Aveline`.

    API:
    call AIAveline_Register(unit whichUnit)
    call AIAveline_SpawnAt(x, y, facing)

**/
library AIAveline initializer Init requires AI, AIWarrior, ResourceRage

globals
    constant integer AI_AVELINE_UNIT_RIVERBANE = 'O009'
    constant integer AI_AVELINE_UNIQUE_ID = 'AVLN'
    integer AI_Aveline_ProfileId = 0
endglobals

private function RegisterBarks takes nothing returns nothing
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "Aveline of Riverbane. Keep your blade ready.", "Aveline_Greet1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "If you stand against raiders, you stand with me.", "Aveline_Greet2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "Riverbane needs steady hands. Are yours ready?", "Aveline_Greet3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_GREET, "I have watched this road long enough to know trouble by its tracks.", "Aveline_Greet4")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_FAREWELL, "Riverbane roads are never quiet for long.", "Aveline_Farewell1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_FAREWELL, "If Riverbane calls, I answer.", "Aveline_Farewell2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_FAREWELL, "Keep clear of the river roads after dusk.", "Aveline_Farewell3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_PASSIVE, "I will watch the road and spare my strength.", "Aveline_Passive1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_PASSIVE, "I will stay close and save my strength.", "Aveline_Passive2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_PASSIVE, "No needless bloodshed. Good.", "Aveline_Passive3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_NORMAL, "Steady pace. Eyes open.", "Aveline_Normal1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_NORMAL, "We move with purpose, not haste.", "Aveline_Normal2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_NORMAL, "Keep your line tight and your eyes open.", "Aveline_Normal3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_AGGRESSIVE, "No mercy for bandits and raiders!", "Aveline_Aggressive1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_AGGRESSIVE, "Drive them back before they reach the villages!", "Aveline_Aggressive2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_AGGRESSIVE, "Break their charge!", "Aveline_Aggressive3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_HOLD, "I will hold this line.", "Aveline_HoldPositions1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_HOLD, "No one gets past me.", "Aveline_HoldPositions2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_HOLD, "This ground is under Riverbane steel.", "Aveline_HoldPositions3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_DROP_ITEMS, "Take what you need.", "Aveline_DropItems1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_DROP_ITEMS, "Better in your pack than weighing down my sword arm.", "Aveline_DropItems2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_DROP_ITEMS, "Here. Use it before the raiders do.", "Aveline_DropItems3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Riverbane still has people worth defending.", "Aveline_Idle1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Bandits follow coin. Orc raiders follow smoke. Either way, people suffer.", "Aveline_Idle2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Every quiet road in Riverbane was bought by someone keeping watch.", "Aveline_Idle3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Sereneglade's calm never lasts unless we defend it.", "Aveline_Idle4")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "I am checking the road ahead.", "Aveline_Moving1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "Riverbane first. Then the next fire.", "Aveline_Moving2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "Tracks are fresh. Stay ready.", "Aveline_Moving3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "I know this road. It knows me too well.", "Aveline_Moving4")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Now!", "Aveline_Casting1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Steel and courage!", "Aveline_Casting2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Stand firm!", "Aveline_Casting3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "Face me!", "Aveline_Attack1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "For Riverbane!", "Aveline_Attack2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "Away from my people!", "Aveline_Attack3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "One less threat to Riverbane.", "Aveline_UnitDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "That threat ends here.", "Aveline_UnitDies2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "Riverbane breathes easier.", "Aveline_UnitDies3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Then I return to my own patrol.", "Aveline_Kicked1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Then I go where Riverbane needs me.", "Aveline_Kicked2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Do not leave these roads undefended.", "Aveline_Kicked3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "Hold the line. We still have work to do.", "Aveline_CompanionDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "Fall back together or not at all!", "Aveline_CompanionDies2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "They paid for our mistake. Make it count.", "Aveline_CompanionDies3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "Useful. I will put it to work.", "Aveline_GiveItem1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "I will carry it until it saves a life.", "Aveline_GiveItem2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "This will help keep the road clear.", "Aveline_GiveItem3")
endfunction

private function RegisterChat takes string soundKey, string text returns nothing
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, text, soundKey)
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, text, soundKey)
endfunction

private function RegisterReply takes string primarySoundKey, string text returns nothing
    call AI_RegisterBarkReply(primarySoundKey, AI_Aveline_ProfileId, text, primarySoundKey + "Aveline")
endfunction

private function RegisterCompanionChats takes nothing returns nothing
    call RegisterChat("Aveline_ChatGeneral1", "Riverbane taught me that a road is safe only because someone keeps watch.")
    call RegisterChat("Aveline_ChatGeneral2", "Bandits want coin, raiders want fear, and villagers just want tomorrow.")
    call RegisterChat("Aveline_ChatGeneral3", "I do not hate every orc I meet. I hate the ones who come with torches.")
    call RegisterChat("Aveline_ChatGeneral4", "Sereneglade is quiet enough to hear trouble coming, if you listen.")
    call RegisterChat("Aveline_ChatGeneral5", "My people do not need a conqueror. They need another dawn.")
    call RegisterChat("Aveline_ChatGeneral6", "The river marks every crossing. Sooner or later, every raider leaves tracks.")
endfunction

private function RegisterCompanionReplies takes nothing returns nothing
    call RegisterReply("HeroWarrior_ChatGeneral1", "Then we understand each other, warrior. Protecting your people is reason enough to fight.")
    call RegisterReply("HeroWarrior_ChatGeneral6", "Riverbane smiths can mend armor. Courage is harder to patch.")
    call RegisterReply("HeroRogue_ChatGeneral1", "A thief can still choose who suffers. Choose carefully near Riverbane.")
    call RegisterReply("HeroRogue_ChatPaladin5", "A truce is only strange until it keeps a child alive.")
    call RegisterReply("HeroWarlock_ChatGeneral1", "When demons do the dirty work, innocents still pay the price.")
    call RegisterReply("HeroWarlock_ChatGeneral5", "Death is not a tool, warlock. It is what I keep from my door.")
    call RegisterReply("HeroShaman_ChatGeneral4", "Then point me at the dark deed and I will put steel in its path.")
    call RegisterReply("HeroShaman_ChatWarrior1", "Balance is good. So is a shield between raiders and a village.")
    call RegisterReply("HeroPaladin_ChatGeneral1", "Glory is fine for banners. I care about who makes it home.")
    call RegisterReply("HeroPaladin_ChatWarlock1", "The Light may judge later. I need threats stopped now.")
    call RegisterReply("HeroEngineer_ChatGeneral2", "Duct tape will not hold a bridge under raiders. Use bolts.")
    call RegisterReply("HeroEngineer_ChatGeneral5", "Reckless under pressure is still reckless. Aim it away from Riverbane.")
endfunction

private function OnRegister takes nothing returns nothing
    set udg_Aveline = AI_EventUnit
    call ResourceRage_Register(AI_EventUnit)
endfunction

public function Register takes unit whichUnit returns integer
    local integer instanceId = AI_RegisterUnit(whichUnit, AI_Aveline_ProfileId, AI_AVELINE_UNIQUE_ID)
    if instanceId > 0 then
        set udg_Aveline = whichUnit
        call ResourceRage_Register(whichUnit)
    endif
    return instanceId
endfunction

public function SpawnAt takes real x, real y, real facing returns unit
    return AI_SpawnProfile(AI_Aveline_ProfileId, Player(14), x, y, facing, AI_AVELINE_UNIQUE_ID)
endfunction

private function Init takes nothing returns nothing
    set AI_Aveline_ProfileId = AI_RegisterProfile(AI_Warrior_ClassId, AI_AVELINE_UNIT_RIVERBANE, "Aveline")
    call AIWarrior_ConfigureProfile(AI_Aveline_ProfileId)
    call AIWarrior_RegisterAbilityTemplatesForUnitType(AI_AVELINE_UNIT_RIVERBANE)
    call AI_SetProfileSpawnOwner(AI_Aveline_ProfileId, Player(14))
    call AI_SetProfileCap(AI_Aveline_ProfileId, 1)
    call AI_SetUnitTypeCap(AI_AVELINE_UNIT_RIVERBANE, 1)
    call AI_SetProfileRandomUniqueId(AI_Aveline_ProfileId, AI_AVELINE_UNIQUE_ID)
    call AI_SetProfileFixedHeroLevel(AI_Aveline_ProfileId, 10)
    call AI_SetProfileXpLockedUntilInvite(AI_Aveline_ProfileId, true)
    call AI_SetRandomSpawnFirstProfile(AI_Aveline_ProfileId)
    call AI_SetUnitTypeDefaultProfile(AI_AVELINE_UNIT_RIVERBANE, AI_Aveline_ProfileId)
    call AI_SetProfileRegisterCallback(AI_Aveline_ProfileId, function OnRegister)
    call AI_AddRandomSpawnProfile(AI_Aveline_ProfileId)
    call RegisterBarks()
    call RegisterCompanionChats()
    call RegisterCompanionReplies()
endfunction

endlibrary
