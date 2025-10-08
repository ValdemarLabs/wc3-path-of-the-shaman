// Only for your class

library DPersonalLootSys initializer Init requires DInventory, DEquipment
// DEquipment is not required if you are not using it

globals

endglobals



function AddToDropTablePercent takes integer DTID, real percent, integer ilvl, integer rarityid, integer namedid, integer itemtypeid, integer growthid, integer setid returns nothing
// DTID = DropTable ID
// This is how it works:
// The lowest percent calculated is 0.001% (one thousandth percent, so one in one hundred thousand chance)
// Every item gets its own roll. If you set 10% for a mana potion and 15% for a Ring, then both items may drop,
// as first there is a 10% chance roll for the potion and regardless of outcome, a 15% chance roll for the ring.
    //- - - > Instead make drop tables have an attribute?
// If you set ilvl = -1 then the item's ilvl will be calculated according to the default rule you set in the system.
    // For example, base ilvl on mob level or hero level
// If you set rarityid to -1 then it will be calculated according to the default rule you set in the system.
    // For example, you could have set that there is a 1% chance for legendaries, 10% for rare items, etc.
// If you set namedid, to a number other than -1 then itemtypeid does not matter, as named items are based on certain itemtypeids
// 
endfunction



function FireDropTable takes unit dying, integer DTID returns nothing
// DTID = DropTable ID
// 
endfunction

private function Init takes nothing returns nothing
// This tells the Inventory system that the Personal Loot System is also used
set PersonalLootSystemUsed = TRUE
endfunction

endlibrary