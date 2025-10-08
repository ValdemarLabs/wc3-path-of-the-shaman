/* Slots:
1 - Head					7 - Gloves
2 - Neck					8 - Ring1
3 - Shoulders				9 - Ring2
4 - Back					10 - Belt
5 - Chest					11 - Legs
6 - Bracer					12 - Boots
19 - Main Hand				20 - Offhand ( 2h weapons dummy to this slot )
*/

/* Functions:
DEqItemTypeDefineStatGrantedByName takes integer iid, string statname, real amount
DEqItemTypeDefineStatGrantedById takes integer iid, integer statid, real amount
DEqItemTypeDefineAllowedSlotId takes integer iid, integer slotid
DEqItemTypeDefineAllowedSlotByName takes integer iid, string name
DEqItemTypeDefineReqStatByName takes integer iid, string statname, real amount
DEqItemTypeDefineReqStatById takes integer iid, integer statid, real amount
DEqItemTypeDefineReqAbilityForbiddden takes integer iid, integer abid, integer ablev
DEqItemTypeDefineReqAbility takes integer iid, integer abid, integer ablev
DEqItemTypeDefineReqClassForbiddden takes integer iid, integer uid
DEqItemTypeDefineReqClass takes integer iid, integer uid
DEqItemTypeDefineAs2Handed takes integer iid
DEqItemTypeDefineReqHeroLevel takes integer iid, integer hlvl
DEqItemTypeDefineGoldValue takes integer iid, integer g
*/

/*
Negative values are possible with most, if not all stats.
However, breaching some limits might make Warcraft crash, so make sure you test funny sounding stuff, like negative STR values, or adding STR / etc. to non-hero unit.
Once I have time I will research and implement safeguards when necessary.
*/

/* Default stat names:
set DEqStatNames[1] = "STR"
set DEqStatNames[2] = "AGI"
set DEqStatNames[3] = "INT"
set DEqStatNames[4] = "HP"
set DEqStatNames[5] = "HPS"
set DEqStatNames[6] = "HP Pct Per Sec"
    A value of 1.0 means 100pct HP regained over 1 second. So 1pct HP would be a value of 0.01
set DEqStatNames[7] = "Mana"
set DEqStatNames[8] = "MPS"
set DEqStatNames[9] = "Mana Pct Per Sec"
    A value of 1.0 means 100pct MP regained over 1 second. So 1pct MP would be a value of 0.01
set DEqStatNames[10] = "Critical Chance"
    Important: Warcraft 3 is very funny about Critical Strike and by default it will handle a 4.99pct chance Critical Strike as 0pct.
    A few years ago this bug was fixed, but you have to enable the fix.
    In your map go to Scenario / Map Options and enable Use Accurate Probability For Calculations!
	If your unit has another Critical Strike ability, then it should stack with the one from Equipment.
set DEqStatNames[11] = "Critical DMG"
    The crit ability used in this system by default increased damage by 50pct.
    You can adjust this default value with variable DefaultCritMultiplier in SharedDInvLib.
set DEqStatNames[12] = "Damage"
set DEqStatNames[13] = "Damage Pct"
set DEqStatNames[14] = "Melee DMG"
set DEqStatNames[15] = "Melee DMG Pct"
    A value of 1.0 means 100pct. So 1pct Melee DMG Pct would be 0.01
set DEqStatNames[16] = "Ranged DMG"
set DEqStatNames[17] = "Ranged DMG Pct"
    A value of 1.0 means 100pct. So 1pct Ranged DMG Pct would be 0.01
set DEqStatNames[18] = "Cleave Pct"
    Counts as magic damage.
set DEqStatNames[19] = "Cleave Area"
    Base value is 150. Adjust it in global variable CleaveBaseArea in SharedDInvLib
set DEqStatNames[20] = "Attack Speed"
    0.15 gives the equivalent bonus that a vanilla Gloves of Haste gives. So on paper 15pct.
    Although attack speed is calculated by Warcraft in a weirder way. https://liquipedia.net/warcraft/Attack_Speed
set DEqStatNames[21] = "Attack Range"
    Affects both attack 1 and 2.
set DEqStatNames[22] = "Lifesteal Pct"
    Value of 1.0 means 100pct. So 1pct Lifesteal would be 0.01
    Negative values cause this unit to take damage instead.
    Ignores "Invulnerable"
set DEqStatNames[23] = "Thorns"
    Thorns is magic damage.
    Flat damage reflected to melee attackers.
    A value of 10 will cause melee attackers to take 10 DMG (before armor reduction).
set DEqStatNames[24] = "Thorns Pct"
set DEqStatNames[25] = "Armor"
set DEqStatNames[26] = "Armor Pct"
    This affects only Armor received by Equipment. (From Agi, Object Editor, Buffs, etc not included)
set DEqStatNames[27] = "Evasion"
    Evasion 1.0 means 100pct Evasion. So add 0.01 Evasion for 1pct Evasion 
set DEqStatNames[28] = "SpellDMG Taken Pct"
    By default units take 1.0 in other words 100pct spell DMG.
    Put -0.3 on an item = Unit will now take 30pct less spell DMG.
    Put 0.3 on an item = Unit will now take 30pct more spell DMG.
    If the unit has -1.0 from items (so 0.0 overall) it will be immune to spell DMG.
    If the unit has -2.0 from items (so -1.0 overall) it will heal 100pct of the spell DMG instead, and so on.
    You may adjust the value of global variable MagicDMGTakenPctLowCap in SharedDInvLib to the minimum amount of pct a unit should take from piercing attacks.
    This stat is using the Elune’s Grace ability. In case you are using that ability on the unit already, the lowest value set for the field seems to apply.
set DEqStatNames[29] = "Melee DMG Taken Pct"
    By default units take 1.0 in other words 100pct melee DMG.
    Put -0.3 on an item = Unit will now take 30pct less melee DMG.
    Put 0.3 on an item = Unit will now take 30pct more melee DMG.
    If the unit has -1.0 from items (so 0.0 overall) it will be immune to melee DMG.
    If the unit has -2.0 from items (so -1.0 overall) it will heal 100pct of the melee DMG instead.
    You may adjust the value of global variable MeleeDMGTakenPctLowCap in SharedDInvLib to the minimum amount of pct a unit should take from piercing attacks.
    This stat is using the Spiked Carapace ability. In case you are using that ability on the unit already, the lowest value set for the field seems to apply.
set DEqStatNames[30] = "Pierce DMG Taken Pct"
    By default units take 1.0 in other words 100pct piercing DMG.
    Put -0.3 on an item = Unit will now take 30pct less piercing DMG.
    Put 0.3 on an item = Unit will now take 30pct more piercing DMG.
    If the unit has -1.0 from items (so 0.0 overall) it will be immune to piercing DMG.
    If the unit has -2.0 from items (so -1.0 overall) it will heal 100pct of the piercing DMG instead.
    You may adjust the value of global variable PierceDMGTakenPctLowCap in SharedDInvLib to the minimum amount of pct a unit should take from piercing attacks.
    This stat is using the Elune’s Grace ability. In case you are using that ability on the unit already, the lowest value set for the field seems to apply.
set DEqStatNames[31] = "Movement Speed"
    Go to Advanced / Gameplay constants / Click on Use Custom Gameplay Constants then in the last few dozen lines you will find MaxUnitSpeed and MinUnitSpeed.
    Adjust them to 522 and 0 (with shift click), otherwise unit movement speed will be restricted to the default values.
set DEqStatNames[32] = "MoveSPD Pct"
    A value of 0.01 means 1pct increase.
set DEqStatNames[33] = "Sight Range"
*/