/**
    BagVendorExample

    Author: Valdemar
    Version:

    Description:
    Minimal example for a direct vendor that upgrades a hero to the next fixed
    DInventory bag tier without allowing tiers to be skipped.

    Credits:

    How to install:
    Import after SharedDInvLib and call BagVendorExample_BuyNextBag from the
    synchronized vendor purchase trigger.

    API:
    - call BagVendorExample_BuyNextBag(hero)

**/
library BagVendorExample requires SharedDInvLib

public function BuyNextBag takes unit buyer returns boolean
    local integer currentTier = DInvGetBagTierOfUnit(buyer)
    local boolean success = false

    if currentTier >= DINV_BAG_TIER_STARTING and currentTier < DINV_BAG_TIER_BOTTOMLESS then
        set success = DInvUpgradeBagForHeroVendor(buyer, currentTier + 1)
    endif
    set buyer = null
    return success
endfunction

endlibrary
