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
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_PASSIVE, "No needless bloodshed.", "Aveline_Passive3")
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
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Bandits follow coin. Orc raiders follow smoke. Either way, people will suffer.", "Aveline_Idle2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "Every quiet road in Riverbane was bought by someone keeping watch.", "Aveline_Idle3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_IDLE, "The magical calm of the Twilight Grove never ceases to amaze me.", "Aveline_Idle4")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "I am checking the road ahead.", "Aveline_Moving1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "Be on your guard.", "Aveline_Moving2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "Tracks are fresh. Stay ready.", "Aveline_Moving3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_MOVING, "I know this road. It knows me too well.", "Aveline_Moving4")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Now!", "Aveline_Casting1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Steel and courage!", "Aveline_Casting2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_CASTING, "Stand firm!", "Aveline_Casting3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "Face me coward!", "Aveline_Attack1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "For Riverbane!", "Aveline_Attack2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ATTACKING, "I'll cut you down!", "Aveline_Attack3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "One less threat to Riverbane.", "Aveline_UnitDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "That threat ends here.", "Aveline_UnitDies2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KILLING, "And down you go!", "Aveline_UnitDies3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Then I return to my own patrol.", "Aveline_Kicked1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "Then I go where Riverbane needs me.", "Aveline_Kicked2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_KICKED, "I must go then.", "Aveline_Kicked3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "Hold the line. We still have work to do.", "Aveline_CompanionDies1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "Fall back together or not at all!", "Aveline_CompanionDies2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_COMPANION_DIES, "They paid for our mistake. Make it count.", "Aveline_CompanionDies3")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "Useful. I will put it to work.", "Aveline_GiveItem1")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "I will carry it until it saves a life.", "Aveline_GiveItem2")
    call AI_RegisterBarkLine(AI_Aveline_ProfileId, AI_BARK_ITEM_GIVEN, "What is that?", "Aveline_GiveItem3")
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
    call RegisterChat("Aveline_ChatGeneral3", "I do not hate every orc I meet. I hate the ones who come with murderous intent...")
    call RegisterChat("Aveline_ChatGeneral4", "This place is quiet enough to hear trouble coming.")
    call RegisterChat("Aveline_ChatGeneral5", "My people do not need a conqueror. They need another dawn.")
    call RegisterChat("Aveline_ChatGeneral6", "Sooner or later, we shall have revenge.")
    call RegisterChat("Aveline_ChatEngineer1", "Engineer, if you build anything for Riverbane, make sure it lasts longer than one fight.")
    call RegisterChat("Aveline_ChatEngineer2", "A quiet warning bell would help more than another smoking contraption.")
    call RegisterChat("Aveline_ChatEngineer3", "If your machines can hold a bridge, I have three bridges that need holding.")
    call RegisterChat("Aveline_ChatPaladin1", "Paladin, your Light is welcome on the roads, but keep your shield where villagers can see it.")
    call RegisterChat("Aveline_ChatPaladin2", "When fear spreads through Riverbane, a bright banner can steady more than soldiers.")
    call RegisterChat("Aveline_ChatPaladin3", "Pray if you must, paladin, but keep your sword ready when the smoke rises.")
    call RegisterChat("Aveline_ChatRogue1", "Rogue, if your hands wander near Riverbane purses, I will notice.")
    call RegisterChat("Aveline_ChatRogue2", "A scout who moves quietly is useful. A thief who moves quietly is still a thief.")
    call RegisterChat("Aveline_ChatRogue3", "If you know how bandits think, use it to stop them before they choose a victim.")
    call RegisterChat("Aveline_ChatShaman1", "Shaman, if the spirits know why raiders keep crossing our river, I would hear it.")
    call RegisterChat("Aveline_ChatShaman2", "Tell the wind to carry warning before it carries smoke.")
    call RegisterChat("Aveline_ChatShaman3", "Your healing is welcome, but I would rather prevent the wounds.")
    call RegisterChat("Aveline_ChatWarlock1", "Warlock, whatever power you carry, keep it pointed at our enemies.")
    call RegisterChat("Aveline_ChatWarlock2", "I have seen enough villages burn. Do not make me wonder if you enjoy the sight.")
    call RegisterChat("Aveline_ChatWarlock3", "If your demons turn hungry, I expect you to stand between them and my people.")
    call RegisterChat("Aveline_ChatUndeadWarlock1", "Undead or not, you still choose where your shadow falls.")
    call RegisterChat("Aveline_ChatUndeadWarlock2", "The dead may not fear smoke, but the living still choke on it.")
    call RegisterChat("Aveline_ChatUndeadWarlock3", "If death taught you patience, use it to guard those who still have time.")
    call RegisterChat("Aveline_ChatWarrior1", "Warrior, strength is useful. Discipline keeps it from becoming another danger.")
    call RegisterChat("Aveline_ChatWarrior2", "Hold the road with me and the raiders will think twice before crossing.")
    call RegisterChat("Aveline_ChatWarrior3", "A strong charge breaks enemies. A steady shield saves families.")
endfunction

private function RegisterRogueReplies takes nothing returns nothing
    call RegisterReply("HeroRogue_ChatGeneral1", "A title is not what matters. What you do with your hands does.")
    call RegisterReply("HeroRogue_ChatGeneral2", "Stealing from dragons is a quick way to burn a village with your mistake.")
    call RegisterReply("HeroRogue_ChatGeneral4", "If it belongs to frightened villagers, leave it where it is.")
    call RegisterReply("HeroRogue_ChatGeneral5", "Shadows do not excuse what you choose inside them.")
    call RegisterReply("HeroRogue_ChatWarlock1", "If they talk back, listen for the moment they turn on us.")
    call RegisterReply("HeroRogue_ChatWarlock2", "Save the insults for enemies with blades drawn.")
    call RegisterReply("HeroRogue_ChatWarlock3", "Shadows are useful until people start hiding crimes in them.")
    call RegisterReply("HeroRogue_ChatWarlock4", "Keep that kind of talk away from my patrol.")
    call RegisterReply("HeroRogue_ChatWarlock5", "If something reeks, check the road for bodies first.")
    call RegisterReply("HeroRogue_ChatWarrior1", "Sneaking past trouble only helps if trouble stays gone.")
    call RegisterReply("HeroRogue_ChatWarrior2", "Doorways matter less than who stands in them when raiders come.")
    call RegisterReply("HeroRogue_ChatWarrior3", "If anyone charges through our line, I will plant them myself.")
    call RegisterReply("HeroRogue_ChatWarrior4", "Flowers are better in graves avoided, not graves filled.")
    call RegisterReply("HeroRogue_ChatShaman1", "Subtlety has its place. So does ending a threat before it spreads.")
    call RegisterReply("HeroRogue_ChatShaman2", "Totems or blades, use what keeps people alive.")
    call RegisterReply("HeroRogue_ChatShaman3", "Ask for what helps the line hold, not what helps your pride.")
    call RegisterReply("HeroRogue_ChatShaman4", "Lightning makes raiders reconsider their courage.")
    call RegisterReply("HeroRogue_ChatEngineer1", "If it blows up near villagers, it becomes my problem too.")
    call RegisterReply("HeroRogue_ChatEngineer2", "Fix the cloak after you fix the road watch.")
    call RegisterReply("HeroRogue_ChatEngineer3", "A quiet turret would be a blessing on patrol.")
    call RegisterReply("HeroRogue_ChatEngineer4", "Stand behind stone before you test the loud ones.")
    call RegisterReply("HeroRogue_ChatPaladin1", "Armor polish matters less than who steps between danger and a child.")
    call RegisterReply("HeroRogue_ChatPaladin2", "Light can blind. So can greed.")
    call RegisterReply("HeroRogue_ChatPaladin3", "The old wars left enough graves. Do not boast over them.")
    call RegisterReply("HeroRogue_ChatPaladin5", "A truce lasts when people decide it is worth defending.")
endfunction

private function RegisterWarlockReplies takes nothing returns nothing
    call RegisterReply("HeroWarlock_ChatGeneral1", "If demons do your fighting, make sure innocents do not pay their price.")
    call RegisterReply("HeroWarlock_ChatGeneral2", "Watching from safety is still a choice when others bleed.")
    call RegisterReply("HeroWarlock_ChatGeneral3", "Corruption admitted is not corruption mastered.")
    call RegisterReply("HeroWarlock_ChatGeneral4", "If your demon needs overtime, perhaps choose cleaner work.")
    call RegisterReply("HeroWarlock_ChatGeneral5", "Death is what I keep from doorsteps, not a tool for convenience.")
    call RegisterReply("HeroWarlock_ChatGeneral6", "Creative solutions still need a conscience.")
    call RegisterReply("HeroWarlock_ChatGeneral7", "Destruction is easy to notice. Protection is harder and worth more.")
    call RegisterReply("HeroWarlock_ChatRogue1", "If work needs doing, dance later and keep watch now.")
    call RegisterReply("HeroWarlock_ChatRogue2", "Some shadows hide people. Some hide knives. Know the difference.")
    call RegisterReply("HeroWarlock_ChatRogue3", "Plotting has its uses. Betrayal does not.")
    call RegisterReply("HeroWarlock_ChatRogue4", "In the shadows, usually someone afraid to be found.")
    call RegisterReply("HeroWarlock_ChatWarrior1", "Heavy steps can warn a village before the raid reaches it.")
    call RegisterReply("HeroWarlock_ChatWarrior2", "Temper breaks lines faster than enemy steel.")
    call RegisterReply("HeroWarlock_ChatWarrior3", "A tauren need not sneak when the road needs a wall.")
    call RegisterReply("HeroWarlock_ChatWarrior4", "Power offered in whispers usually collects in screams.")
    call RegisterReply("HeroWarlock_ChatShaman1", "Healing and restraint save more than careless fire.")
    call RegisterReply("HeroWarlock_ChatShaman2", "Loud voices are not always the wise ones.")
    call RegisterReply("HeroWarlock_ChatShaman3", "Fire solves little when homes are already ash.")
    call RegisterReply("HeroWarlock_ChatShaman4", "If you ask for healing, spend it protecting someone else.")
    call RegisterReply("HeroWarlock_ChatEngineer1", "Then stand clear of the village before anyone tests it.")
    call RegisterReply("HeroWarlock_ChatEngineer2", "Machines are for work. Do not teach them hunger.")
    call RegisterReply("HeroWarlock_ChatEngineer3", "Some people build because they care what remains.")
    call RegisterReply("HeroWarlock_ChatEngineer4", "Fel channeled through metal still stains the hands that made it.")
    call RegisterReply("HeroWarlock_ChatPaladin1", "A shining shield can still stop a blade.")
    call RegisterReply("HeroWarlock_ChatPaladin2", "Righteousness only blinds those who refuse to look at what it protects.")
    call RegisterReply("HeroWarlock_ChatPaladin3", "The Light tastes better than smoke over Riverbane.")
    call RegisterReply("HeroWarlock_ChatPaladin4", "Preaching has its place. So does standing firm.")
    call RegisterReply("HeroWarlock_ChatPaladin5", "Justice speeches are quieter than widows.")
    call RegisterReply("HeroWarlock_ChatPaladin6", "Talk first if you can. Strike when talking fails.")
endfunction

private function RegisterUndeadWarlockReplies takes nothing returns nothing
    call RegisterReply("HeroUndeadWarlock_ChatGeneral1", "Then use that silence to choose mercy where you still can.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral2", "Patience without purpose is just another grave.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral3", "Do not make the living pay for what death taught you.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral4", "Some libraries should remain closed until the village is safe.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral5", "Temporary lives still deserve tomorrow.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral6", "Honest bargains can still cost too much.")
    call RegisterReply("HeroUndeadWarlock_ChatGeneral7", "Wandering souls leave tracks too, if you know where to look.")
    call RegisterReply("HeroUndeadWarlock_ChatRogue1", "Darkness is not discipline, but it can teach caution.")
    call RegisterReply("HeroUndeadWarlock_ChatRogue2", "Ownership is temporary. Hunger should be too.")
    call RegisterReply("HeroUndeadWarlock_ChatRogue3", "Then point the biting things toward our enemies.")
    call RegisterReply("HeroUndeadWarlock_ChatRogue4", "If the corpse objects, I am already reaching for steel.")
    call RegisterReply("HeroUndeadWarlock_ChatWarrior1", "Hunger can be aimed. Aim it away from my people.")
    call RegisterReply("HeroUndeadWarlock_ChatWarrior2", "Death can be knocked down long enough for someone to run.")
    call RegisterReply("HeroUndeadWarlock_ChatWarrior3", "A living heartbeat means there is still something to defend.")
    call RegisterReply("HeroUndeadWarlock_ChatWarrior4", "I prefer enemies distracted by my shield, not my allies dying.")
    call RegisterReply("HeroUndeadWarlock_ChatShaman1", "Complaining spirits still know which roads are dangerous.")
    call RegisterReply("HeroUndeadWarlock_ChatShaman2", "What follows life should not be invited too early.")
    call RegisterReply("HeroUndeadWarlock_ChatShaman3", "Then do not waste the healing.")
    call RegisterReply("HeroUndeadWarlock_ChatShaman4", "If they ask, tell them Riverbane is not finished.")
    call RegisterReply("HeroUndeadWarlock_ChatEngineer1", "A heart helps, but purpose can carry metal far.")
    call RegisterReply("HeroUndeadWarlock_ChatEngineer2", "Use the remains after the battle, not before the warning bell.")
    call RegisterReply("HeroUndeadWarlock_ChatEngineer3", "If it warns us before raiders arrive, let it clatter.")
    call RegisterReply("HeroUndeadWarlock_ChatEngineer4", "Nothing should stop fearing death completely.")
    call RegisterReply("HeroUndeadWarlock_ChatPaladin1", "Being dead does not excuse becoming cruel.")
    call RegisterReply("HeroUndeadWarlock_ChatPaladin2", "Cold ash and holy fire both burn if misused.")
    call RegisterReply("HeroUndeadWarlock_ChatPaladin3", "Redemption starts before the shovel.")
    call RegisterReply("HeroUndeadWarlock_ChatPaladin4", "No one leaves battle clean. Some leave it better.")
    call RegisterReply("HeroUndeadWarlock_ChatPaladin5", "Then keep your shadows away from his flame.")
endfunction

private function RegisterShamanReplies takes nothing returns nothing
    call RegisterReply("HeroShaman_ChatGeneral1", "Wind is useful when it carries warnings before smoke.")
    call RegisterReply("HeroShaman_ChatGeneral2", "If the earth complains, Riverbane has a long list to add.")
    call RegisterReply("HeroShaman_ChatGeneral3", "Stories matter most when they teach people where not to stand.")
    call RegisterReply("HeroShaman_ChatGeneral4", "Name the dark deed and I will stand in its path.")
    call RegisterReply("HeroShaman_ChatGeneral5", "Doom is easier to face when someone keeps watch.")
    call RegisterReply("HeroShaman_ChatGeneral6", "Unnatural healing is still better than a grave, if it has no price.")
    call RegisterReply("HeroShaman_ChatRogue1", "Silent feet still need a clean purpose.")
    call RegisterReply("HeroShaman_ChatRogue2", "Sharp eyes matter more than quiet steps.")
    call RegisterReply("HeroShaman_ChatRogue3", "If the totem belongs to you, take it back before I do.")
    call RegisterReply("HeroShaman_ChatRogue4", "If innocents are being robbed, point me to the thief.")
    call RegisterReply("HeroShaman_ChatRogue5", "Some hide for thrill. Some hide because danger passed too close.")
    call RegisterReply("HeroShaman_ChatWarrior1", "Balance is good. So is a shield between raiders and a village.")
    call RegisterReply("HeroShaman_ChatWarrior2", "Patience keeps strength from wasting itself.")
    call RegisterReply("HeroShaman_ChatWarrior3", "Some problems need shielding before smashing.")
    call RegisterReply("HeroShaman_ChatWarrior4", "Keep your windfury secret if it keeps the line alive.")
    call RegisterReply("HeroShaman_ChatWarlock1", "Sulfur is tolerable if it burns the right target.")
    call RegisterReply("HeroShaman_ChatWarlock2", "Potential chained to chaos drags everyone behind it.")
    call RegisterReply("HeroShaman_ChatWarlock3", "Forgetting old voices is how people lose themselves.")
    call RegisterReply("HeroShaman_ChatWarlock4", "Respect matters less to demons than the leash holding them.")
    call RegisterReply("HeroShaman_ChatEngineer1", "Machines lack heart, but hands can give them purpose.")
    call RegisterReply("HeroShaman_ChatEngineer2", "Then use what the earth gives without poisoning it.")
    call RegisterReply("HeroShaman_ChatEngineer3", "This time is always the phrase before trouble.")
    call RegisterReply("HeroShaman_ChatEngineer4", "Quiet thinking would be a mercy on patrol.")
    call RegisterReply("HeroShaman_ChatPaladin1", "A future of peace still needs guards tonight.")
    call RegisterReply("HeroShaman_ChatPaladin2", "Strong faith is useful when fear starts spreading.")
    call RegisterReply("HeroShaman_ChatPaladin3", "If storm and Light both protect, let them speak together.")
    call RegisterReply("HeroShaman_ChatPaladin4", "Serving something greater should make us gentler, not weaker.")
endfunction

private function RegisterWarriorReplies takes nothing returns nothing
    call RegisterReply("HeroWarrior_ChatGeneral1", "Then we understand each other, warrior. Protecting your people is reason enough to fight.")
    call RegisterReply("HeroWarrior_ChatGeneral2", "Scars teach only if we remember who paid for them.")
    call RegisterReply("HeroWarrior_ChatGeneral3", "Courage told in tales should still protect someone living.")
    call RegisterReply("HeroWarrior_ChatGeneral4", "Will matters most when the line wants to break.")
    call RegisterReply("HeroWarrior_ChatGeneral5", "The battlefield may not care, but villages do.")
    call RegisterReply("HeroWarrior_ChatGeneral6", "Riverbane smiths can mend armor. Courage is harder to patch.")
    call RegisterReply("HeroWarrior_ChatRogue1", "A shadow still needs someone in the open drawing danger away.")
    call RegisterReply("HeroWarrior_ChatRogue2", "If your pockets are empty, keep them that way.")
    call RegisterReply("HeroWarrior_ChatRogue3", "Small blades can still spill too much blood.")
    call RegisterReply("HeroWarrior_ChatRogue4", "Poison wins fights and loses trust.")
    call RegisterReply("HeroWarrior_ChatWarlock1", "Dangerous power must stay leashed.")
    call RegisterReply("HeroWarrior_ChatWarlock2", "Standing strong is easier when no demon bites from behind.")
    call RegisterReply("HeroWarrior_ChatWarlock3", "If they betray us, I expect your axe first.")
    call RegisterReply("HeroWarrior_ChatWarlock4", "If it sounds like a curse, I treat it like one.")
    call RegisterReply("HeroWarrior_ChatShaman1", "Healing wins more battles than pride admits.")
    call RegisterReply("HeroWarrior_ChatShaman2", "A living healer is worth a slower march.")
    call RegisterReply("HeroWarrior_ChatShaman3", "Then guard the healer as fiercely as the front.")
    call RegisterReply("HeroWarrior_ChatShaman4", "If you die, we adapt. Better if you do not.")
    call RegisterReply("HeroWarrior_ChatEngineer1", "Strength and machines both serve if aimed well.")
    call RegisterReply("HeroWarrior_ChatEngineer2", "Old-fashioned smashing has its place. So does preparation.")
    call RegisterReply("HeroWarrior_ChatEngineer3", "A charge with turret cover sounds less foolish than most plans.")
    call RegisterReply("HeroWarrior_ChatEngineer4", "Raw power breaks. Built power breaks too. People suffer either way.")
    call RegisterReply("HeroWarrior_ChatPaladin1", "Steel wins the moment. Purpose decides what comes after.")
    call RegisterReply("HeroWarrior_ChatPaladin2", "Everyone tires. That is why we watch each other.")
    call RegisterReply("HeroWarrior_ChatPaladin3", "Ask plainly. Pride kills quietly.")
    call RegisterReply("HeroWarrior_ChatPaladin4", "If the Light protects civilians, I welcome every trick.")
endfunction

private function RegisterEngineerReplies takes nothing returns nothing
    call RegisterReply("HeroEngineer_ChatGeneral1", "Machines do not choose who suffers. Engineers do.")
    call RegisterReply("HeroEngineer_ChatGeneral2", "Duct tape will not hold a bridge under raiders. Use bolts.")
    call RegisterReply("HeroEngineer_ChatGeneral3", "If something glows red, put it down outside the village.")
    call RegisterReply("HeroEngineer_ChatGeneral4", "Potential becomes danger when no one asks who stands nearby.")
    call RegisterReply("HeroEngineer_ChatGeneral5", "Reckless under pressure is still reckless. Aim it away from Riverbane.")
    call RegisterReply("HeroEngineer_ChatGeneral6", "Better matters only if it survives first contact.")
    call RegisterReply("HeroEngineer_ChatGeneral7", "Old stone has kept more people safe than clever scrap.")
    call RegisterReply("HeroEngineer_ChatRogue1", "Do not pay thieves with excuses to steal more.")
    call RegisterReply("HeroEngineer_ChatRogue2", "A helmet will not save someone launched into a tree.")
    call RegisterReply("HeroEngineer_ChatRogue3", "Sneaking in quietly is wasted if the exit is a crater.")
    call RegisterReply("HeroEngineer_ChatRogue4", "Delivery service or not, pay people fairly.")
    call RegisterReply("HeroEngineer_ChatRogue5", "Professional theft is still theft.")
    call RegisterReply("HeroEngineer_ChatWarrior1", "Long range saves lives when it keeps raiders off the gate.")
    call RegisterReply("HeroEngineer_ChatWarrior2", "Then build with people like him in mind.")
    call RegisterReply("HeroEngineer_ChatWarrior3", "Do not tempt warriors with exploding hammers.")
    call RegisterReply("HeroEngineer_ChatWarrior4", "Spikes are fine. Electricity near allies is not.")
    call RegisterReply("HeroEngineer_ChatWarrior5", "Do not strap a turret to anyone without asking twice.")
    call RegisterReply("HeroEngineer_ChatShaman1", "Wheels on totems sounds like a way to anger everyone involved.")
    call RegisterReply("HeroEngineer_ChatShaman2", "Nature listens better than unstable machinery.")
    call RegisterReply("HeroEngineer_ChatShaman3", "If your flame turret behaves like a spirit, treat it with respect.")
    call RegisterReply("HeroEngineer_ChatShaman4", "Healing dispensers should not explode. Start there.")
    call RegisterReply("HeroEngineer_ChatWarlock1", "Hellfire and flamethrowers both burn homes.")
    call RegisterReply("HeroEngineer_ChatWarlock2", "If demons sometimes disobey, that is the answer.")
    call RegisterReply("HeroEngineer_ChatWarlock3", "Groundbreaking is not comforting when the ground is under Riverbane.")
    call RegisterReply("HeroEngineer_ChatWarlock4", "A flashlight would be safer than half your inventions.")
    call RegisterReply("HeroEngineer_ChatWarlock5", "Do not let fel magic anywhere near a battery.")
    call RegisterReply("HeroEngineer_ChatPaladin1", "A rocket launcher is not a prayer.")
    call RegisterReply("HeroEngineer_ChatPaladin2", "Light does not need capacitors to be useful.")
    call RegisterReply("HeroEngineer_ChatPaladin3", "Grease and wisdom can coexist if you choose carefully.")
    call RegisterReply("HeroEngineer_ChatPaladin4", "Bless the wrench after you make it safe.")
endfunction

private function RegisterPaladinReplies takes nothing returns nothing
    call RegisterReply("HeroPaladin_ChatGeneral1", "Healing scars starts with protecting people now.")
    call RegisterReply("HeroPaladin_ChatGeneral2", "Different people can guard the same road.")
    call RegisterReply("HeroPaladin_ChatGeneral3", "Hope survives longer when armed with preparation.")
    call RegisterReply("HeroPaladin_ChatGeneral4", "Cycles break when someone refuses to pass the knife on.")
    call RegisterReply("HeroPaladin_ChatGeneral5", "Strength needs purpose, or it becomes another raid.")
    call RegisterReply("HeroPaladin_ChatGeneral6", "A good meal has saved more tempers than sermons.")
    call RegisterReply("HeroPaladin_ChatGeneral7", "Sharp rocks are humbling enemies.")
    call RegisterReply("HeroPaladin_ChatRogue1", "Doubt is fair. Judge the blade by where it points.")
    call RegisterReply("HeroPaladin_ChatRogue2", "Gold and lives both reveal a person's honor.")
    call RegisterReply("HeroPaladin_ChatRogue3", "Justice must see clearly, even in shadows.")
    call RegisterReply("HeroPaladin_ChatRogue4", "Skill deserves purpose beyond profit.")
    call RegisterReply("HeroPaladin_ChatRogue5", "Fighting beside others is a start.")
    call RegisterReply("HeroPaladin_ChatWarrior1", "Honor is clearest when strength shields the weak.")
    call RegisterReply("HeroPaladin_ChatWarrior2", "Dignity holds a line when fear spreads.")
    call RegisterReply("HeroPaladin_ChatWarrior3", "A good heart matters more than the banner above it.")
    call RegisterReply("HeroPaladin_ChatWarrior4", "Then focus on getting people behind us.")
    call RegisterReply("HeroPaladin_ChatWarrior5", "Ferocity with purpose is a shield. Without it, a threat.")
    call RegisterReply("HeroPaladin_ChatShaman1", "Different methods can still mend the same wound.")
    call RegisterReply("HeroPaladin_ChatShaman2", "Wisdom is welcome if it keeps the peace honest.")
    call RegisterReply("HeroPaladin_ChatShaman3", "Earth, Light, river, road. All can warn those who listen.")
    call RegisterReply("HeroPaladin_ChatShaman4", "Comfort is rare. Guard it carefully.")
    call RegisterReply("HeroPaladin_ChatShaman5", "Protecting and healing leave less room for old hate.")
    call RegisterReply("HeroPaladin_ChatEngineer1", "If it explodes near civilians, intention will not matter.")
    call RegisterReply("HeroPaladin_ChatEngineer2", "Invention needs virtue most when it is powerful.")
    call RegisterReply("HeroPaladin_ChatEngineer3", "Reassurance starts with distance from the blast.")
    call RegisterReply("HeroPaladin_ChatEngineer4", "A tool for every problem still needs judgment.")
    call RegisterReply("HeroPaladin_ChatEngineer5", "If it sends us to the moon, I will be very annoyed.")
    call RegisterReply("HeroPaladin_ChatWarlock1", "Foul magic has a long memory in human lands.")
    call RegisterReply("HeroPaladin_ChatWarlock2", "A useful ally should still answer hard questions.")
    call RegisterReply("HeroPaladin_ChatWarlock3", "Purifying someone by force makes another wound.")
    call RegisterReply("HeroPaladin_ChatWarlock4", "No power fills a hollow purpose.")
    call RegisterReply("HeroPaladin_ChatWarlock5", "Chaos is not courage.")
endfunction

private function RegisterCompanionReplies takes nothing returns nothing
    call RegisterRogueReplies()
    call RegisterWarlockReplies()
    call RegisterUndeadWarlockReplies()
    call RegisterShamanReplies()
    call RegisterWarriorReplies()
    call RegisterEngineerReplies()
    call RegisterPaladinReplies()
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
