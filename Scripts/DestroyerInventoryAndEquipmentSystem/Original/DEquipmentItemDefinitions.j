library DEquipmentItemDefinitions initializer Init requires DEquipment

function DEqPreDefineItemsHere takes nothing returns nothing
// Defining item costs for nonequipment items is also possible:
// Keep in mind that the price you describe will be the price of 1 stack. If the default stack of Wand of the Wind is 3
// and you set the price to 150, then a 3 stack Wand of the Wind will be worth 450g

// Scroll of healing
call DEqItemTypeDefineGoldValue('shea', 250)
// Tiny Great Hall
call DEqItemTypeDefineGoldValue('tgrh', 600)
// Ivory Tower
call DEqItemTypeDefineGoldValue('tsct', 30)
// Wand of the Wind
call DEqItemTypeDefineGoldValue('wcyc', 150)
// Potion of Greater Healing
call DEqItemTypeDefineGoldValue('pghe', 400)
// Potion of Healing
call DEqItemTypeDefineGoldValue('phea', 150)

// Ring of the Archtester
call DEqItemTypeDefineAllowedSlotByName('ram3', "Ring1")
call DEqItemTypeDefineAllowedSlotByName('ram3', "Ring2")
call DEqItemTypeDefineStatGrantedByName('ram3', "Movement Speed", 100.0)
call DEqItemTypeDefineStatGrantedByName('ram3', "Pierce DMG Taken Pct", 5.4)
call DEqItemTypeDefineStatGrantedByName('ram3', "SpellDMG Taken Pct", -0.75)
call DEqItemTypeDefineStatGrantedByName('ram3', "Lifesteal Pct", 0.8)
call DEqItemTypeDefineStatGrantedByName('ram3', "Armor Pct", 0.5)
call DEqItemTypeDefineStatGrantedByName('ram3', "Thorns", 100.0)
call DEqItemTypeDefineGoldValue('ram3', 666)

// Maul of Strength
call DEqItemTypeDefineAllowedSlotId('mlst', 19)
call DEqItemTypeDefineStatGrantedByName('mlst', "STR", 1)
call DEqItemTypeDefineAs2Handed('mlst')
call DEqItemTypeDefineStatGrantedByName('mlst', "Cleave Pct", 0.25)
call DEqItemTypeDefineStatGrantedByName('mlst', "Cleave Area", 100)
call DEqItemTypeDefineAbilityGranted('mlst', 'AHbh', 1)
call DEqItemTypeDefineGoldValue('mlst', 500)

// The Other Ring of Testing
call DEqItemTypeDefineAllowedSlotId('jdrn', 8)
call DEqItemTypeDefineAllowedSlotId('jdrn', 9)
call DEqItemTypeDefineStatGrantedByName('jdrn', "HP Pct Per Sec", 0.050)
call DEqItemTypeDefineStatGrantedByName('jdrn', "Mana Pct Per Sec", 0.050)
call DEqItemTypeDefineStatGrantedByName('jdrn', "MoveSPD Pct", 0.250)
call DEqItemTypeDefineStatGrantedByName('jdrn', "Attack Speed", 0.450)
call DEqItemTypeDefineStatGrantedByName('jdrn', "Lifesteal Pct", -0.8)
call DEqItemTypeDefineStatGrantedByName('jdrn', "Ranged DMG Pct", 2.5)
call DEqItemTypeDefineGoldValue('jdrn', 620)

// Ring of Testing
call DEqItemTypeDefineAllowedSlotId('rnsp', 8)
call DEqItemTypeDefineAllowedSlotId('rnsp', 9)
call DEqItemTypeDefineStatGrantedByName('rnsp', "HPS", 10.0)
call DEqItemTypeDefineStatGrantedByName('rnsp', "Sight Range", 500.0)
call DEqItemTypeDefineStatGrantedByName('rnsp', "Attack Range", 500.0)
call DEqItemTypeDefineStatGrantedByName('rnsp', "Attack Speed", 1.0)
call DEqItemTypeDefineStatGrantedByName('rnsp', "HP", 150.0)
call DEqItemTypeDefineStatGrantedByName('rnsp', "Evasion", 0.5)
call DEqItemTypeDefineStatGrantedByName('rnsp', "Melee DMG Pct", 2.5)
call DEqItemTypeDefineGoldValue('rnsp', 600)

// Pendant of Testing
call DEqItemTypeDefineAllowedSlotId('penr', 2)
call DEqItemTypeDefineStatGrantedByName('penr', "Movement Speed", 260.0)
call DEqItemTypeDefineAbilityGranted('penr', 'Aroa', 1)
call DEqItemTypeDefineAbilityGranted('penr', 'Atau', 1)
call DEqItemTypeDefineAbilityGranted('penr', 'Amgr', 1)
call DEqItemTypeDefineAbilityGranted('penr', 'Arej', 1)
call DEqItemTypeDefineStatGrantedByName('penr', "Mana", 250.0)
call DEqItemTypeDefineStatGrantedByName('penr', "MPS", 50.0)
call DEqItemTypeDefineStatGrantedByName('penr', "Damage Pct", 2.5)
call DEqItemTypeDefineGoldValue('penr', 600)

// Ring of Protection +1
call DEqItemTypeDefineAllowedSlotId('rde0', 8)
call DEqItemTypeDefineAllowedSlotId('rde0', 9)
call DEqItemTypeDefineStatGrantedByName('rde0', "Armor", 1.0)
call DEqItemTypeDefineStatGrantedByName('rde0', "Melee DMG Taken Pct", -1.0)
call DEqItemTypeDefineGoldValue('rde0', 100)

// Ring of Requiring Protection +2
call DEqItemTypeDefineAllowedSlotId('rde1', 8)
call DEqItemTypeDefineAllowedSlotId('rde1', 9)
call DEqItemTypeDefineStatGrantedByName('rde1', "Armor", 2.0)
call DEqItemTypeDefineReqAbility('rde1', 'AHhb', 1)
call DEqItemTypeDefineReqAbility('rde1', 'AHad', 1)
call DEqItemTypeDefineReqHeroLevel('rde1', 3)
call DEqItemTypeDefineGoldValue('rde1', 160)

// Cloak of Shadows
call DEqItemTypeDefineAllowedSlotId('clsd', 4)
call DEqItemTypeDefineAbilityGranted('clsd', 'Ashm', 1)
call DEqItemTypeDefineStatGrantedByName('clsd', "Inventory Space", 5)
call DEqItemTypeDefineGoldValue('clsd', 100)

// Orc Loincloth
call DEqItemTypeDefineAllowedSlotId('clfm', 11)
call DEqItemTypeDefineStatGrantedByName('clfm', "INT", -2)
call DEqItemTypeDefineAbilityGranted('clfm', 'AIcf', 1)
call DEqItemTypeDefineGoldValue('clfm', 300)

// Forbidden blade of testing
call DEqItemTypeDefineAllowedSlotId('rat6', 19)
call DEqItemTypeDefineStatGrantedByName('rat6', "Attack Speed", 0.15)
call DEqItemTypeDefineStatGrantedByName('rat6', "Damage", 15)
call DEqItemTypeDefineReqClassForbiddden('rat6', 'Hblm')
call DEqItemTypeDefineReqClassForbiddden('rat6', 'Ntin')
call DEqItemTypeDefineGoldValue('rat6', 500)

// Sturdy war axe
call DEqItemTypeDefineAllowedSlotId('stwa', 19)
call DEqItemTypeDefineAs2Handed('stwa')
call DEqItemTypeDefineStatGrantedByName('stwa', "Damage", 3)
call DEqItemTypeDefineGoldValue('stwa', 200)

// Medallion of Courage
call DEqItemTypeDefineAllowedSlotId('mcou', 2)
call DEqItemTypeDefineStatGrantedByName('mcou', "STR", 5)
call DEqItemTypeDefineStatGrantedByName('mcou', "INT", 5)
call DEqItemTypeDefineGoldValue('mcou', 180)

// Mantle of intelligence +3
call DEqItemTypeDefineAllowedSlotId('rin1', 3)
call DEqItemTypeDefineStatGrantedByName('rin1', "INT", 3)
call DEqItemTypeDefineGoldValue('mcou', 180)

// Claws of attack +12
call DEqItemTypeDefineAllowedSlotId('ratc', 19)
call DEqItemTypeDefineStatGrantedByName('ratc', "Damage", 12)
call DEqItemTypeDefineGoldValue('ratc', 280)

// Hood of cunning
call DEqItemTypeDefineAllowedSlotId('hcun', 1)
call DEqItemTypeDefineStatGrantedByName('hcun', "INT", 5)
call DEqItemTypeDefineStatGrantedByName('hcun', "AGI", 5)
call DEqItemTypeDefineGoldValue('hcun', 250)

// Boots of speed
call DEqItemTypeDefineAllowedSlotId('bspd', 12)
call DEqItemTypeDefineStatGrantedByName('bspd', "Movement Speed", 60)
call DEqItemTypeDefineGoldValue('bspd', 150)

// Gloves of haste
call DEqItemTypeDefineAllowedSlotId('gcel', 7)
call DEqItemTypeDefineStatGrantedByName('gcel', "Attack Speed", 0.15)
call DEqItemTypeDefineGoldValue('gcel', 190)

// Belt of Giant Strength
call DEqItemTypeDefineAllowedSlotId('bgst', 10)
call DEqItemTypeDefineStatGrantedByName('bgst', "STR", 6)
call DEqItemTypeDefineAbilityGranted('bgst', 'DQTG', 1)
call DEqItemTypeDefineGoldValue('bgst', 240)

// Slippers of Agility
call DEqItemTypeDefineAllowedSlotId('rag1', 12)
call DEqItemTypeDefineStatGrantedByName('rag1', "AGI", 3)
call DEqItemTypeDefineStatGrantedByName('rag1', "Melee DMG", 15)
call DEqItemTypeDefineStatGrantedByName('rag1', "Critical Chance", 0.15)
call DEqItemTypeDefineStatGrantedByName('rag1', "Critical DMG", 3)
call DEqItemTypeDefineGoldValue('rag1', 340)

// Ring of Regeneration
call DEqItemTypeDefineAllowedSlotId('rlif', 8)
call DEqItemTypeDefineAllowedSlotId('rlif', 9)
call DEqItemTypeDefineStatGrantedByName('rlif', "HPS", 2)
call DEqItemTypeDefineGoldValue('rlif', 230)

// Frost wyrm skull shield
call DEqItemTypeDefineAllowedSlotId('fwss', 20)
call DEqItemTypeDefineStatGrantedByName('fwss', "Armor", 2)
call DEqItemTypeDefineStatGrantedByName('fwss', "SpellDMG Taken Pct", -0.33)
call DEqItemTypeDefineGoldValue('fwss', 530)

// Bracer of Agility
call DEqItemTypeDefineAllowedSlotId('brag', 6)
call DEqItemTypeDefineStatGrantedByName('brag', "AGI", 1)
call DEqItemTypeDefineStatGrantedByName('brag', "Ranged DMG", 1)
call DEqItemTypeDefineStatGrantedByName('brag', "Thorns Pct", 4.5)
call DEqItemTypeDefineAbilityGranted('brag', 'DQDW', 1)
call DEqItemTypeDefineGoldValue('brag', 290)

// Bladebane Armor
call DEqItemTypeDefineAllowedSlotId('blba', 5)
call DEqItemTypeDefineStatGrantedByName('blba', "Armor", 7)
call DEqItemTypeDefineAbilityGranted('blba', 'AIad', 1)
call DEqItemTypeDefineGoldValue('blba', 390)

//call BJDebugMsg("Predefined items defined!")
endfunction



private function Init takes nothing returns nothing
call TriggerRegisterTimerEvent( trg_DEqPreDefinedItems, 0.1, false )
call TriggerAddAction(trg_DEqPreDefinedItems, function DEqPreDefineItemsHere)
endfunction

endlibrary