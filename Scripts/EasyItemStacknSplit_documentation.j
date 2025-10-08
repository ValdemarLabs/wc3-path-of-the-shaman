//TESH.scrollpos=-1
//TESH.alwaysfold=0
//============================================================================
// Easy Item Stack 'n Split v2.7.4
//  by Dangerb0y
//============================================================================
//
// FEATURES:
//  - Automatically stacks obtained items to a configurable stack limit.
//  - Allows stacking items within a unit's inventory.
//  - Allows splitting item stacks within a unit's inventory.
//  - Allows units to seamlessly pick up items regardless of a full inventory.
//  - Copy-paste implementation.
// 
// STACKING ITEMS:
//  - Obtained items are automatically stacked with same-type items in a unit's inventory.
//  - Placing same-type items on top of each other will stack them together.
// 
// SPLITTING ITEMS:
//  - Double right-clicking or dropping an item stack on itself will split a set amount off the pile. (optional)
//  - Consecutively split items will stack together. (optional)
//  - If a unit's inventory slots are full when splitting an item stack, the split item will be dropped on the ground in front of the unit. (optional)
// 
// ITEM STACKS:
//  - The maximum stack size is set by the item's level in the Object Editor (Shift+Double-click allows entering levels greater than 8).
//  - Setting an item's level to 0 will give it an unlimited stack size.
//  - Items must have charges in order to be stacked; non-charged items will function as Blizzard intended.
// 
// RELEASE NOTES:
//  - This system can be implemented into any map.
//  - This system is completely leak-free.
//  - This system is completely lag-free.
//  - This system is fully MUI and MPI.
//  - This system works with all inventory sizes.
//  - This system does NOT use hashtables or gamecache, i.e. it is much faster.
//  - This system is available in vJASS and GUI.
//
// IMPLEMENTATION:
//  - See trigger comments.
//
// UPDATING? Make sure to first delete old EasyItemStacknSplit triggers and, if you use the GUI version, all the variables with the "EasyItem" prefix.

function InitTrig_Documentation takes nothing returns nothing
    call FogEnable( false )
    call FogMaskEnable( false )
    call DisplayTimedTextToForce( bj_FORCE_ALL_PLAYERS, 0, "|c0075DD07Easy Item Stack 'n Split|r |c00E6DC28v2.7.4|r\n by Dangerb0y" )
endfunction