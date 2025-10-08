// Player stash,
// Cross player stash (for allied players)
// Enemy players?
// For Containers in survival / RPG maps

// should work with ability
// should work with unit

library DStash initializer Init requires DInventory
// And extra stash button on the DInv UI that works similar to slotbuttons. Items clicked into this slot will be transferred to the stash.
// 
globals

endglobals

private function Init takes nothing returns nothing
// This tells the Inventory system that the Equipment system is also used
set StashSystemUsed = TRUE
endfunction

endlibrary