library DItemRarity initializer Init requires DInventory

function SetDItemRarity takes integer iid, integer r returns nothing
set DItemRarityDB.integer[iid] = r
endfunction

private function Init takes nothing returns nothing
set DInvRarityModuleUsed = TRUE
endfunction

endlibrary