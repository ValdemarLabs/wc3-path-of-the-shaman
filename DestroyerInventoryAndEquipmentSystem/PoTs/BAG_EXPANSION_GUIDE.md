# DInventory bag tiers

Every DInventory begins with the 12-slot Starting Bag. A purchased bag replaces
that permanent capacity; it does not add its displayed size to the old bag.

| Tier | Constant | Total slots |
|---|---|---:|
| Starting Bag | `DINV_BAG_TIER_STARTING` | 12 |
| Small Bag | `DINV_BAG_TIER_SMALL` | 16 |
| Medium Bag | `DINV_BAG_TIER_MEDIUM` | 20 |
| Large Bag | `DINV_BAG_TIER_LARGE` | 24 |
| Traveler's Backpack | `DINV_BAG_TIER_TRAVELER` | 36 |
| Explorer's Backpack | `DINV_BAG_TIER_EXPLORER` | 48 |
| Adventurer's Backpack | `DINV_BAG_TIER_ADVENTURER` | 64 |
| Bottomless Bag | `DINV_BAG_TIER_BOTTOMLESS` | 80 |

All sizes align with the four-column inventory grid. A page contains at most 24
slots; partial final pages shrink to the rows they use.

## Vendor API

Use `Shop_AddBagUpgradeService` to register a target tier. Shop validates that
the selected hero owns the immediately preceding tier before taking gold.

```jass
call Shop_AddBagUpgradeService(vendorId, "Small Bag", DINV_BAG_TIER_SMALL, 1000, "Bags")
```

Direct vendor integrations can call:

```jass
if DInvUpgradeBagForHeroVendor(buyer, DINV_BAG_TIER_SMALL) then
    // Charge only after TRUE.
endif
```

`DInvUpgradeBagForPlayerVendor` provides the same sequential check for the
`1PerPlayer` paradigm. `DInvSetBagTierForUnit`, `DInvSetBagTierForPlayer`, and
`DInvSetBagTierForBID` are non-vendor initialization helpers and permit jumping
forward, but never downgrading.

Temporary equipment or scripted capacity modifiers still use the
`DInvDeltaAdditionalSlots*` APIs. They are applied on top of the permanent bag
tier and the effective total remains capped by `InventoryCapacityMaximum`.
