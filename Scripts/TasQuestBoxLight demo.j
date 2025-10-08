function DemoInit takes nothing returns nothing    

/*
local string a
local string b
local string c
local string d
call TasQuestBox_Add("TRIGSTR_017", "TRIGSTR_018", "ReplaceableTextures\\CommandButtons\\BTNSunderingBlades.blp")
call TasQuestBox_Add("TRIGSTR_013", "TRIGSTR_014", "ReplaceableTextures\\CommandButtons\\BTNDizzy.blp")
call TasQuestBox_Add("TRIGSTR_015", "TRIGSTR_016", "ReplaceableTextures\\PassiveButtons\\PASBTNPillage.blp")
call TasQuestBox_Add("TRIGSTR_019", "TRIGSTR_020", "ReplaceableTextures\\CommandButtons\\BTNSorceressMaster.blp")
call TasQuestBox_Add("TRIGSTR_021", "TRIGSTR_022", "ReplaceableTextures\\CommandButtons\\BTNArthas.blp")
call TasQuestBox_Add("TRIGSTR_023", "TRIGSTR_024", "ReplaceableTextures\\CommandButtons\\BTNSacrificialSkull.blp")
call TasQuestBox_Add("TRIGSTR_025", "TRIGSTR_026", "ReplaceableTextures\\CommandButtons\\BTNGuldan.blp")
call TasQuestBox_Add("TRIGSTR_027", "TRIGSTR_028", "ReplaceableTextures\\CommandButtons\\BTNDeathCoil.blp")
call TasQuestBox_Add("TRIGSTR_029", "TRIGSTR_030", "ReplaceableTextures\\CommandButtons\\BTNRedDragon.blp")
call TasQuestBox_Add("TRIGSTR_031", "TRIGSTR_032", "ReplaceableTextures\\CommandButtons\\BTNPeon.blp")
call TasQuestBox_Add("TRIGSTR_033", "TRIGSTR_034", "ReplaceableTextures\\CommandButtons\\BTNThrall.blp")
call TasQuestBox_Add("TRIGSTR_035", "TRIGSTR_036", "ReplaceableTextures\\CommandButtons\\BTNShaman.blp")
call TasQuestBox_Add("TRIGSTR_037", "TRIGSTR_038", "ReplaceableTextures\\CommandButtons\\BTNKiljaedin.blp")
call TasQuestBox_Add("TRIGSTR_039", "TRIGSTR_040", "ReplaceableTextures\\PassiveButtons\\PASBTNFreezingBreath.blp")
call TasQuestBox_Add("TRIGSTR_041", "TRIGSTR_042", "ReplaceableTextures\\CommandButtons\\BTNCarrionScarabs.blp")
call TasQuestBox_Add("TRIGSTR_043", "TRIGSTR_044", "ReplaceableTextures\\CommandButtons\\BTNKelThuzad.blp")
call TasQuestBox_Add("TRIGSTR_045", "TRIGSTR_046", "ReplaceableTextures\\CommandButtons\\BTNAcolyte.blp")
call TasQuestBox_Add("TRIGSTR_047", "TRIGSTR_048", "ReplaceableTextures\\CommandButtons\\BTNHeroDreadLord.blp")
call TasQuestBox_Add("TRIGSTR_049", "TRIGSTR_050", "ReplaceableTextures\\CommandButtons\\BTNAmbush.blp")
call TasQuestBox_Add("TRIGSTR_051", "TRIGSTR_052", "ReplaceableTextures\\CommandButtons\\BTNPriest.blp")
call TasQuestBox_Add("TRIGSTR_053", "TRIGSTR_054", "ReplaceableTextures\\CommandButtons\\BTNEvilIllidan.blp")
call TasQuestBox_Add("TRIGSTR_055", "TRIGSTR_056", "ReplaceableTextures\\CommandButtons\\BTNMoonWell.blp")
call TasQuestBox_Add("TRIGSTR_057", "TRIGSTR_058", "ReplaceableTextures\\CommandButtons\\BTNTreeOfEternity.blp")
call TasQuestBox_Add("TRIGSTR_059", "TRIGSTR_060", "ReplaceableTextures\\CommandButtons\\BTNHumanDestroyer.blp")
call TasQuestBox_Add("TRIGSTR_061", "TRIGSTR_062", "ReplaceableTextures\\CommandButtons\\BTNWarden2.blp")

set a = "The enchanted keepers are the favored sons of the demigod, Cenarius. Like their lesser dryad sisters, the keepers appear to be half night elf and half stag. They have enormous antlers and manes of leaves that flow down their backs. Their right hands are disfigured and twisted like the gnarled rootlaws"
set b = "of the treants. Keepers possess many strange powers over nature and the animals. Though they typically remain within the sacred Moon Glades of Mount Hyjal, the keepers always heed the call to arms when the lands of Kalimdor are threatened.|n|cffffcc00 ENTANGLING ROOTS|r|n "
set c = "The sons of Cenarius are favored with the ability to cause roots to erupt from the ground and entrap enemy forces. These roots not only keep the enemy immobile, but also inflict damage.|n|cffffcc00 FORCE OF NATURE|r|n This ability allows the keeper to call forth allies from the surrounding forest. These stout treants will do as the keeper wills until the magic that animates them expires and the trees return once more to the earth.|n|cffffcc00 THORNS AURA|r"
set d = "|n While this aura is active, any forces that engage the keeper or his allies in hand to hand combat will be damaged by a druidic flurry of razor sharp thorns and brambles.|n |cffffcc00TRANQUILITY|r|n In a demonstration of his ultimate communion with nature, the keeper may call down a mighty shower of rain that will restore health to all friendly forces within its range for its entire duration. The keeper is also healed by the majestic powers of nature that are unleashed."
call TasQuestBox_Add("Keeper of the Grove, the strongest nightelf Hero there is. And this is a long title", a + b + c + d, "")


set a = "The fearless leaders of the Sentinel army, the priestesses of the moon epitomize the power and grace of their race's ancient moon goddess, Elune. The priestesses, equipped with silvery, glowing armor, ride the fearless Frostsaber tigers of Winterspring into battle. Charged with the safekeeping of the night elf lands and armed with magical energy bows, the priestesses will stop at nothing to rid their ancient land of evil."
set b = "|n|cffffcc00SHADOWMELD|r|n Empowered by the goddess Elune, night elf warriors possess the ability to completely blend in with their surroundings between sunset and sunrise, rendering them invisible to their enemy. This effect, however, can only be achieved while the warriors are standing completely still.|n |cffffcc00SCOUT|r|n The scout is an owl that may be sent to any area of the map for observation purposes and to reveal invisible enemies. The owl will only reveal for a limited amount of time."
set c = "|n|cffffcc00 SEARING ARROWS|r|n Calling upon the powers of the Moon Goddess Elune to imbue her arrows with searing magical energy, the priestess is able to fire deadly volleys at any foe.  |n|cffffcc00TRUESHOT AURA|r|n The commanding presence of the priestess boosts the morale of her warriors, enabling their attacks to strike with heightened accuracy and power."
set d = "|n|cffffcc00 STARFALL|r|n At the peak of her experience, the priestess may call down a furious shower of falling stars that cause massive destruction amongst enemy forces. This catastrophic power, given to the priestess by Elune herself, achieves its full duration as long as the priestess stays in the spell’s vicinity"
call TasQuestBox_Add("Priestess of the Moon", a +b+c+d, "ReplaceableTextures/CommandButtons/BTNPriestessOfTheMoon")

*/

//TasQuestBox_Add(string name, string text, string icon)

local string a = "|n|cffffcc00Sereneglade|r|n  A tranquil glade deep within the ancient forest of Ashenvale. The glade is bathed in perpetual twilight, with soft beams of light filtering through the dense canopy above. Towering trees with silver bark and luminescent leaves surround a crystal-clear pond at the center, its surface reflecting the ethereal glow of the surroundings. The air is filled with the gentle hum of nature, as fireflies dance among vibrant flowers and ferns. Ancient stone ruins, covered in moss and vines, hint at a long-forgotten civilization that once revered this sacred place. The Sereneglade exudes an aura of peace and magic, inviting all who enter to find solace and harmony within its embrace."
local string b = "|n|cffffcc00Zone level?|r|n = 1-10"
local string c = "|n|cffffcc00Notable entities|r|n Ancient Treants, Forest Spirits, Elven Rangers, Mystical Stags"
local string d = "|n|cffffcc00Else|r|n Random text I don't know what to write...."

call TasQuestBox_Add("Sereneglade", a + b + c + d, "ReplaceableTextures\\CommandButtons\\BTNSunderingBlades.blp")

endfunction

