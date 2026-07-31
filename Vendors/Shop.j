/**
    Shop

    Author: Valdemar
    Version:

    Description:
    Data and transaction backend for PotS merchant vendors. Shops register
    vendor definitions and stock entries, handle player buy/sell actions, expose
    a combined DInventory, DEquipment, and vanilla inventory view for ShopUI, and
    provide bounded helper actions for AI shop usage.

    Credits:
    - Elprede, for RpgMerchantShop as feature inspiration:
      https://www.hiveworkshop.com/threads/custom-rpg-shop-system.372995/

    How to install:
    Import after Table and the PotS DInventory/DEquipment stack. Import ShopUI
    after this file. Vendor files should live in Vendors/ and require Shop.

    API:
    - set vendorId = Shop_CreateVendor(name, unitTypeId)
    - call Shop_RegisterVendorUnit(unit, vendorId)
    - call Shop_RegisterVendorUnitType(vendorId, unitTypeId)
    - set entryId = Shop_AddStock(vendorId, itemTypeId, price, category)
    - set entryId = Shop_AddBagSlotService(vendorId, name, slots, price, category)
    - call Shop_BeginTradeSession(vendorId)
    - call Shop_EndTradeSession()
    - set categoryName = Shop_GetVendorCategoryName(vendorId, position)
    - call Shop_BuyStock(player, buyer, stockEntry)
    - call Shop_BuyRecentlySold(player, buyer, soldIndex)
    - call Shop_BuildUnitInventory(unit)
    - call Shop_SellViewItem(player, seller, viewIndex)
    - call Shop_AIBuySimple(aiUnit, vendor)
    - call Shop_AISellSimple(aiUnit, vendor)

**/
library Shop initializer Init requires Table, DEquipment
    globals
        // Public view/source constants used by ShopUI.
        constant integer SHOP_VIEW_MERCHANT = 1
        constant integer SHOP_VIEW_YOU = 2
        constant integer SHOP_SOURCE_DINV = 1
        constant integer SHOP_SOURCE_DEQUIP = 2
        constant integer SHOP_SOURCE_VANILLA = 3
        constant integer SHOP_STOCK_KIND_ITEM = 1
        constant integer SHOP_STOCK_KIND_BAG_SLOTS = 2

        // Configuration
        private constant integer SHP_MAX_VENDORS = 96
        private constant integer SHP_MAX_STOCK = 512
        private constant integer SHP_MAX_VIEW_ITEMS = 192
        private constant integer SHP_MAX_RECENT_SOLD_PER_VENDOR = 64
        private constant integer SHP_SELL_PERCENT = 50
        private constant integer SHP_AI_PRICE_BASE = 550
        private constant integer SHP_AI_PRICE_PER_LEVEL = 95
        private constant integer SHP_AI_PRICE_HARD_CAP = 2500
        private constant integer SHP_AI_MAX_DUPLICATE_ITEMS = 3
        private constant string SHP_CATEGORY_ALL = "All"
        private constant string SHP_CATEGORY_GOODS = "Goods"
        private constant string SHP_CATEGORY_RECENTLY_SOLD = "Recent"
        private constant string SHP_ICON_BAG_SERVICE_6 = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Bag_09.blp"    // use for 6 slot
        private constant string SHP_ICON_BAG_SERVICE_12 = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Bag_07.blp"    // use for 12 slot
        private constant string SHP_ICON_BAG_SERVICE_20 = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Bag_08.blp"    // use for 20 slot

        // Registered vendors and unit lookup.
        private Table SHP_VendorByUnit = 0
        private Table SHP_VendorByUnitType = 0
        private integer SHP_VendorCount = 0
        private string array SHP_VendorName
        private integer array SHP_VendorUnitType

        // Vendor stock.
        private integer SHP_StockCount = 0
        private integer array SHP_StockVendor
        private integer array SHP_StockKind
        private integer array SHP_StockItemType
        private integer array SHP_StockPrice
        private integer array SHP_StockAiPriceCap
        private integer array SHP_StockAiWeight
        private integer array SHP_StockPayload
        private string array SHP_StockCategory
        private string array SHP_StockName
        private string array SHP_StockIconPath
        private string array SHP_StockTooltip

        // Combined inventory view cache. ShopUI rebuilds this before rendering
        // the "You" page and after each sale.
        private integer SHP_ViewCount = 0
        private item array SHP_ViewItem
        private integer array SHP_ViewSource
        private integer array SHP_ViewSlot
        private integer array SHP_ViewBid
        private integer array SHP_ViewPid

        // Per-vendor buyback cache. Each vendor keeps a bounded recent list so
        // old entries cannot grow without limit.
        private integer SHP_SessionVendorId = 0
        private integer array SHP_RecentSoldCount
        private integer array SHP_RecentSoldItemType
        private integer array SHP_RecentSoldPrice
        private string array SHP_RecentSoldCategory

        private string SHP_LastMessage = ""
    endglobals

    private function SHP_SetMessage takes string message returns nothing
        set SHP_LastMessage = message
    endfunction

    private function SHP_NormalizeCategory takes string category returns string
        if category == null or category == "" then
            return SHP_CATEGORY_GOODS
        endif
        return category
    endfunction

    private function SHP_IsVendorIdValid takes integer vendorId returns boolean
        return vendorId > 0 and vendorId <= SHP_VendorCount
    endfunction

    private function SHP_IsStockIdValid takes integer stockId returns boolean
        return stockId > 0 and stockId <= SHP_StockCount and SHP_IsVendorIdValid(SHP_StockVendor[stockId]) and SHP_StockKind[stockId] > 0
    endfunction

    private function SHP_GetStockCategoryName takes integer stockId returns string
        if SHP_IsStockIdValid(stockId) then
            return SHP_NormalizeCategory(SHP_StockCategory[stockId])
        endif
        return SHP_CATEGORY_GOODS
    endfunction

    private function SHP_IsAllCategory takes string category returns boolean
        return category == null or category == "" or category == SHP_CATEGORY_ALL
    endfunction

    private function SHP_GetRecentSoldKey takes integer vendorId, integer soldIndex returns integer
        return (vendorId - 1) * SHP_MAX_RECENT_SOLD_PER_VENDOR + soldIndex
    endfunction

    private function SHP_GetBagSlotServiceIcon takes integer slots returns string
        if slots == 6 then
            return SHP_ICON_BAG_SERVICE_6
        elseif slots == 12 then
            return SHP_ICON_BAG_SERVICE_12
        elseif slots == 20 then
            return SHP_ICON_BAG_SERVICE_20
        endif

        // Preserve the previous icon as the fallback for unsupported values.
        return SHP_ICON_BAG_SERVICE_6
    endfunction

    private function SHP_GetBagSlotServiceTooltip takes integer slots returns string
        return "Permanently adds " + I2S(slots) + " DInventory slots to this hero.|nApplied immediately. This does not create a bag item."
    endfunction

    private function SHP_ItemTypeIcon takes integer itemTypeId returns string
        local string iconPath = ""

        if itemTypeId != 0 then
            set iconPath = BlzGetAbilityIcon(itemTypeId)
        endif
        if iconPath == null or iconPath == "" then
            return "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        endif
        return iconPath
    endfunction

    private function SHP_ItemTypeTooltip takes integer itemTypeId returns string
        local string tooltip = ""

        if itemTypeId != 0 then
            set tooltip = BlzGetAbilityExtendedTooltip(itemTypeId, 0)
        endif
        if tooltip == null then
            return ""
        endif
        return tooltip
    endfunction

    private function SHP_ItemStackCount takes item whichItem returns integer
        local integer charges

        if whichItem == null then
            return 0
        endif
        set charges = GetItemCharges(whichItem)
        if charges <= 0 then
            return 1
        endif
        return charges
    endfunction

    private function SHP_IsEquipmentItemType takes integer itemTypeId returns boolean
        if itemTypeId == 0 then
            return false
        endif
        return DEqItemTypeDefinitionDB[itemTypeId][0].integer[2] == 1
    endfunction

    private function SHP_IsQuestItem takes item whichItem returns boolean
        if whichItem == null then
            return false
        endif
        return GetItemType(whichItem) == ITEM_TYPE_CAMPAIGN
    endfunction

    private function SHP_IsAIUtilityItemType takes integer itemTypeId returns boolean
        return itemTypeId == 'I672' or itemTypeId == 'I66M' or itemTypeId == 'I611'
    endfunction

    private function SHP_GetRegisteredPriceForItemType takes integer itemTypeId returns integer
        local integer stockId = 1
        local integer best = 0

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockKind[stockId] == SHOP_STOCK_KIND_ITEM and SHP_StockItemType[stockId] == itemTypeId and SHP_StockPrice[stockId] > 0 then
                if best <= 0 or SHP_StockPrice[stockId] < best then
                    set best = SHP_StockPrice[stockId]
                endif
            endif
            set stockId = stockId + 1
        endloop
        return best
    endfunction

    private function SHP_GetRegisteredCategoryForItemType takes integer itemTypeId returns string
        local integer stockId = 1

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockKind[stockId] == SHOP_STOCK_KIND_ITEM and SHP_StockVendor[stockId] == SHP_SessionVendorId and SHP_StockItemType[stockId] == itemTypeId then
                return SHP_GetStockCategoryName(stockId)
            endif
            set stockId = stockId + 1
        endloop

        set stockId = 1
        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockKind[stockId] == SHOP_STOCK_KIND_ITEM and SHP_StockItemType[stockId] == itemTypeId then
                return SHP_GetStockCategoryName(stockId)
            endif
            set stockId = stockId + 1
        endloop
        return SHP_CATEGORY_GOODS
    endfunction

    private function SHP_GetItemBasePrice takes item whichItem returns integer
        local integer itemTypeId
        local integer price = 0

        if whichItem == null then
            return 0
        endif
        set itemTypeId = GetItemTypeId(whichItem)
        if itemTypeId != 0 then
            set price = GetItemGoldCost(whichItem)
            if price <= 0 then
                set price = SHP_GetRegisteredPriceForItemType(itemTypeId)
            endif
            if price <= 0 then
                set price = GetItemLevel(whichItem) * 20 + 10
            endif
        endif
        return price
    endfunction

    private function SHP_GetItemSaleValue takes item whichItem returns integer
        local integer value

        if whichItem == null then
            set whichItem = null
            return 0
        endif
        set value = (SHP_GetItemBasePrice(whichItem) * SHP_ItemStackCount(whichItem) * SHP_SELL_PERCENT) / 100
        if value < 1 then
            set value = 1
        endif
        set whichItem = null
        return value
    endfunction

    private function SHP_GetAIPriceCap takes unit buyer returns integer
        local integer heroLevel = 1
        local integer priceCap

        if buyer != null and IsUnitType(buyer, UNIT_TYPE_HERO) then
            set heroLevel = GetHeroLevel(buyer)
            if heroLevel < 1 then
                set heroLevel = 1
            endif
        endif
        set priceCap = SHP_AI_PRICE_BASE + heroLevel * SHP_AI_PRICE_PER_LEVEL
        if priceCap > SHP_AI_PRICE_HARD_CAP then
            set priceCap = SHP_AI_PRICE_HARD_CAP
        endif
        set buyer = null
        return priceCap
    endfunction

    private function SHP_AddViewItem takes item whichItem, integer sourceType, integer slotId, integer bid, integer pid returns nothing
        if whichItem == null or SHP_ViewCount >= SHP_MAX_VIEW_ITEMS then
            return
        endif

        set SHP_ViewCount = SHP_ViewCount + 1
        set SHP_ViewItem[SHP_ViewCount] = whichItem
        set SHP_ViewSource[SHP_ViewCount] = sourceType
        set SHP_ViewSlot[SHP_ViewCount] = slotId
        set SHP_ViewBid[SHP_ViewCount] = bid
        set SHP_ViewPid[SHP_ViewCount] = pid
    endfunction

    private function SHP_ClearView takes nothing returns nothing
        local integer index = 1

        loop
            exitwhen index > SHP_ViewCount
            set SHP_ViewItem[index] = null
            set SHP_ViewSource[index] = 0
            set SHP_ViewSlot[index] = 0
            set SHP_ViewBid[index] = 0
            set SHP_ViewPid[index] = 0
            set index = index + 1
        endloop
        set SHP_ViewCount = 0
    endfunction

    private function SHP_RemoveRecentSoldIndex takes integer soldIndex returns nothing
        local integer vendorId = SHP_SessionVendorId
        local integer count
        local integer key
        local integer nextKey

        if not SHP_IsVendorIdValid(vendorId) then
            return
        endif
        set count = SHP_RecentSoldCount[vendorId]
        if soldIndex <= 0 or soldIndex > count then
            return
        endif

        loop
            exitwhen soldIndex >= count
            set key = SHP_GetRecentSoldKey(vendorId, soldIndex)
            set nextKey = SHP_GetRecentSoldKey(vendorId, soldIndex + 1)
            set SHP_RecentSoldItemType[key] = SHP_RecentSoldItemType[nextKey]
            set SHP_RecentSoldPrice[key] = SHP_RecentSoldPrice[nextKey]
            set SHP_RecentSoldCategory[key] = SHP_RecentSoldCategory[nextKey]
            set soldIndex = soldIndex + 1
        endloop

        set key = SHP_GetRecentSoldKey(vendorId, count)
        set SHP_RecentSoldItemType[key] = 0
        set SHP_RecentSoldPrice[key] = 0
        set SHP_RecentSoldCategory[key] = ""
        set SHP_RecentSoldCount[vendorId] = count - 1
    endfunction

    private function SHP_AddRecentSoldItemForVendor takes integer vendorId, integer itemTypeId, integer price returns nothing
        local integer index = 1
        local integer count
        local integer key
        local integer nextKey

        if not SHP_IsVendorIdValid(vendorId) or itemTypeId == 0 then
            return
        endif
        if price <= 0 then
            set price = 1
        endif
        set count = SHP_RecentSoldCount[vendorId]
        if count >= SHP_MAX_RECENT_SOLD_PER_VENDOR then
            loop
                exitwhen index >= SHP_MAX_RECENT_SOLD_PER_VENDOR
                set key = SHP_GetRecentSoldKey(vendorId, index)
                set nextKey = SHP_GetRecentSoldKey(vendorId, index + 1)
                set SHP_RecentSoldItemType[key] = SHP_RecentSoldItemType[nextKey]
                set SHP_RecentSoldPrice[key] = SHP_RecentSoldPrice[nextKey]
                set SHP_RecentSoldCategory[key] = SHP_RecentSoldCategory[nextKey]
                set index = index + 1
            endloop
            set count = SHP_MAX_RECENT_SOLD_PER_VENDOR - 1
        endif

        set count = count + 1
        set key = SHP_GetRecentSoldKey(vendorId, count)
        set SHP_RecentSoldCount[vendorId] = count
        set SHP_RecentSoldItemType[key] = itemTypeId
        set SHP_RecentSoldPrice[key] = price
        set SHP_RecentSoldCategory[key] = SHP_GetRegisteredCategoryForItemType(itemTypeId)
    endfunction

    private function SHP_CountStoredItemType takes unit owner, integer itemTypeId returns integer
        local integer pid
        local integer bid
        local integer eqid
        local integer capacity
        local integer slotId = 0
        local integer count = 0
        local item whichItem = null

        if owner == null or itemTypeId == 0 then
            set owner = null
            return 0
        endif

        set pid = GetPlayerId(GetOwningPlayer(owner))
        set bid = BIDOfUnit(owner)
        set eqid = EQIDOfUnit(owner)
        if bid > 0 then
            set capacity = MaxBagCapacityOfBID(pid, bid)
            loop
                exitwhen slotId >= capacity
                set whichItem = DInventoryDB[bid].item[slotId]
                if whichItem != null and GetItemTypeId(whichItem) == itemTypeId then
                    set count = count + SHP_ItemStackCount(whichItem)
                endif
                set slotId = slotId + 1
            endloop
        endif

        if eqid > 0 then
            set slotId = 1
            loop
                exitwhen slotId > HighestSlotNumber
                set whichItem = EQIDDB[eqid][4].item[slotId]
                if whichItem != null and GetItemTypeId(whichItem) == itemTypeId then
                    set count = count + 1
                endif
                set slotId = slotId + 1
            endloop
        endif

        set slotId = 0
        loop
            exitwhen slotId >= UnitInventorySize(owner)
            set whichItem = UnitItemInSlot(owner, slotId)
            if whichItem != null and not IsItemStoredInDInv(whichItem) and GetItemTypeId(whichItem) == itemTypeId then
                set count = count + SHP_ItemStackCount(whichItem)
            endif
            set slotId = slotId + 1
        endloop

        set whichItem = null
        set owner = null
        return count
    endfunction

    private function SHP_TryStoreItemInDInventory takes unit owner, item whichItem returns boolean
        local integer pid
        local integer bid
        local integer eqid

        if owner == null or whichItem == null then
            set owner = null
            set whichItem = null
            return false
        endif

        set pid = GetPlayerId(GetOwningPlayer(owner))
        set bid = BIDOfUnit(owner)
        set eqid = EQIDOfUnit(owner)
        if bid > 0 and eqid > 0 and DInvCanBIDReceiveItem(whichItem, pid, bid) then
            call StoreItemForPIDBID(whichItem, pid, bid, eqid)
            call DInvRefreshOpenInventoryForBID(bid)
            set owner = null
            set whichItem = null
            return true
        endif

        set owner = null
        set whichItem = null
        return false
    endfunction

    private function SHP_TryAddItemToVanilla takes unit owner, item whichItem returns boolean
        local boolean added = false

        if owner == null or whichItem == null or UnitInventorySize(owner) <= 0 then
            set owner = null
            set whichItem = null
            return false
        endif
        if IsVanillaInventoryFull(owner) or not DInvCanItemUseVanillaInventory(whichItem) then
            set owner = null
            set whichItem = null
            return false
        endif

        call SetItemVisible(whichItem, true)
        set added = UnitAddItem(owner, whichItem)
        set owner = null
        set whichItem = null
        return added
    endfunction

    private function SHP_ShouldAIKeepItem takes unit owner, item whichItem returns boolean
        local integer itemTypeId

        if owner == null or whichItem == null then
            set owner = null
            set whichItem = null
            return false
        endif
        set itemTypeId = GetItemTypeId(whichItem)
        if itemTypeId == 0 then
            set owner = null
            set whichItem = null
            return false
        endif
        if SHP_IsQuestItem(whichItem) then
            set owner = null
            set whichItem = null
            return true
        endif
        if SHP_IsAIUtilityItemType(itemTypeId) then
            set owner = null
            set whichItem = null
            return true
        endif
        if SHP_IsEquipmentItemType(itemTypeId) then
            set owner = null
            set whichItem = null
            return true
        endif
        if SHP_CountStoredItemType(owner, itemTypeId) <= SHP_AI_MAX_DUPLICATE_ITEMS then
            set owner = null
            set whichItem = null
            return true
        endif
        set owner = null
        set whichItem = null
        return false
    endfunction

    private function SHP_RemoveViewItem takes player receiver, unit owner, integer viewIndex, integer vendorId, boolean payGold, boolean allowEquipped returns boolean
        local item whichItem
        local integer sourceType
        local integer slotId
        local integer bid
        local integer pid
        local integer value
        local integer itemTypeId

        if viewIndex <= 0 or viewIndex > SHP_ViewCount or owner == null then
            set receiver = null
            set owner = null
            return false
        endif

        set whichItem = SHP_ViewItem[viewIndex]
        set sourceType = SHP_ViewSource[viewIndex]
        set slotId = SHP_ViewSlot[viewIndex]
        set bid = SHP_ViewBid[viewIndex]
        set pid = SHP_ViewPid[viewIndex]

        if whichItem == null then
            call SHP_SetMessage("|cffff8080That item is no longer available.|r")
            set receiver = null
            set owner = null
            return false
        endif
        if SHP_IsQuestItem(whichItem) then
            call SHP_SetMessage("|cffff8080Quest items cannot be sold.|r")
            set whichItem = null
            set receiver = null
            set owner = null
            return false
        endif
        if sourceType == SHOP_SOURCE_DEQUIP and not allowEquipped then
            call SHP_SetMessage("|cffff8080Unequip the item before selling it.|r")
            set whichItem = null
            set receiver = null
            set owner = null
            return false
        endif

        set value = SHP_GetItemSaleValue(whichItem)
        set itemTypeId = GetItemTypeId(whichItem)
        if sourceType == SHOP_SOURCE_DINV then
            if bid <= 0 then
                set bid = BIDOfItem(whichItem)
            endif
            if bid <= 0 then
                call SHP_SetMessage("|cffff8080Could not find that DInventory item.|r")
                set whichItem = null
                set receiver = null
                set owner = null
                return false
            endif
            if DInventoryDB[bid].item[slotId] != whichItem then
                set slotId = GetDInvSlotIdOfItemOfBID(pid, bid, whichItem)
            endif
            if slotId < 0 then
                call SHP_SetMessage("|cffff8080Could not find that DInventory slot.|r")
                set whichItem = null
                set receiver = null
                set owner = null
                return false
            endif
            call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
            call RemoveItem(whichItem)
            call DInvRefreshOpenInventoryForBID(bid)
        elseif sourceType == SHOP_SOURCE_VANILLA then
            call RemoveItem(whichItem)
        elseif sourceType == SHOP_SOURCE_DEQUIP and allowEquipped then
            call SHP_SetMessage("|cffff8080AI equipped-item sale is disabled.|r")
            set whichItem = null
            set receiver = null
            set owner = null
            return false
        else
            call SHP_SetMessage("|cffff8080Unknown item source.|r")
            set whichItem = null
            set receiver = null
            set owner = null
            return false
        endif

        if payGold and receiver != null then
            call SHP_AddRecentSoldItemForVendor(vendorId, itemTypeId, value)
            call SetPlayerState(receiver, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(receiver, PLAYER_STATE_RESOURCE_GOLD) + value)
            call SHP_SetMessage("|cff80ff80Sold for " + I2S(value) + " gold.|r")
        endif

        set whichItem = null
        set receiver = null
        set owner = null
        return true
    endfunction

    public function GetLastMessage takes nothing returns string
        return SHP_LastMessage
    endfunction

    public function CreateVendor takes string displayName, integer unitTypeId returns integer
        if displayName == "" or SHP_VendorCount >= SHP_MAX_VENDORS then
            return 0
        endif

        set SHP_VendorCount = SHP_VendorCount + 1
        set SHP_VendorName[SHP_VendorCount] = displayName
        set SHP_VendorUnitType[SHP_VendorCount] = unitTypeId
        if unitTypeId != 0 then
            set SHP_VendorByUnitType.integer[unitTypeId] = SHP_VendorCount
        endif
        return SHP_VendorCount
    endfunction

    public function RegisterVendorUnitType takes integer vendorId, integer unitTypeId returns boolean
        if not SHP_IsVendorIdValid(vendorId) or unitTypeId == 0 then
            return false
        endif
        set SHP_VendorUnitType[vendorId] = unitTypeId
        set SHP_VendorByUnitType.integer[unitTypeId] = vendorId
        return true
    endfunction

    public function RegisterVendorUnit takes unit vendor, integer vendorId returns boolean
        if vendor == null or not SHP_IsVendorIdValid(vendorId) then
            set vendor = null
            return false
        endif
        set SHP_VendorByUnit.integer[GetHandleId(vendor)] = vendorId
        set vendor = null
        return true
    endfunction

    public function GetVendorIdForUnitType takes integer unitTypeId returns integer
        if unitTypeId == 0 then
            return 0
        endif
        return SHP_VendorByUnitType.integer[unitTypeId]
    endfunction

    public function GetVendorIdForUnit takes unit vendor returns integer
        local integer vendorId = 0

        if vendor == null then
            set vendor = null
            return 0
        endif
        if SHP_VendorByUnit.has(GetHandleId(vendor)) then
            set vendorId = SHP_VendorByUnit.integer[GetHandleId(vendor)]
        else
            set vendorId = SHP_VendorByUnitType.integer[GetUnitTypeId(vendor)]
        endif

        set vendor = null
        return vendorId
    endfunction

    public function GetVendorName takes integer vendorId returns string
        if SHP_IsVendorIdValid(vendorId) then
            return SHP_VendorName[vendorId]
        endif
        return "Merchant"
    endfunction

    private function SHP_AddStockEntry takes integer vendorId, integer stockKind, integer itemTypeId, integer price, string category, integer payload, string stockName, string iconPath, string tooltip, integer aiPriceCap, integer aiWeight returns integer
        if not SHP_IsVendorIdValid(vendorId) or SHP_StockCount >= SHP_MAX_STOCK then
            return 0
        endif
        if stockKind != SHOP_STOCK_KIND_ITEM and stockKind != SHOP_STOCK_KIND_BAG_SLOTS then
            return 0
        endif
        if stockKind == SHOP_STOCK_KIND_ITEM and itemTypeId == 0 then
            return 0
        endif
        if stockKind == SHOP_STOCK_KIND_BAG_SLOTS and payload <= 0 then
            return 0
        endif
        if price <= 0 then
            set price = 1
        endif
        if aiWeight < 0 then
            set aiWeight = 0
        endif
        set category = SHP_NormalizeCategory(category)
        if stockName == null then
            set stockName = ""
        endif
        if iconPath == null then
            set iconPath = ""
        endif
        if tooltip == null then
            set tooltip = ""
        endif

        set SHP_StockCount = SHP_StockCount + 1
        set SHP_StockVendor[SHP_StockCount] = vendorId
        set SHP_StockKind[SHP_StockCount] = stockKind
        set SHP_StockItemType[SHP_StockCount] = itemTypeId
        set SHP_StockPrice[SHP_StockCount] = price
        set SHP_StockCategory[SHP_StockCount] = category
        set SHP_StockPayload[SHP_StockCount] = payload
        set SHP_StockName[SHP_StockCount] = stockName
        set SHP_StockIconPath[SHP_StockCount] = iconPath
        set SHP_StockTooltip[SHP_StockCount] = tooltip
        set SHP_StockAiPriceCap[SHP_StockCount] = aiPriceCap
        set SHP_StockAiWeight[SHP_StockCount] = aiWeight
        return SHP_StockCount
    endfunction

    public function AddStockEx takes integer vendorId, integer itemTypeId, integer price, string category, integer aiPriceCap, integer aiWeight returns integer
        return SHP_AddStockEntry(vendorId, SHOP_STOCK_KIND_ITEM, itemTypeId, price, category, 0, "", "", "", aiPriceCap, aiWeight)
    endfunction

    public function AddStock takes integer vendorId, integer itemTypeId, integer price, string category returns integer
        return Shop_AddStockEx(vendorId, itemTypeId, price, category, 0, 1)
    endfunction

    public function AddStockNoAI takes integer vendorId, integer itemTypeId, integer price, string category returns integer
        return Shop_AddStockEx(vendorId, itemTypeId, price, category, 0, 0)
    endfunction

    public function AddBagSlotServiceEx takes integer vendorId, string serviceName, integer slots, integer price, string category, integer aiPriceCap, integer aiWeight returns integer
        if serviceName == null or serviceName == "" then
            set serviceName = "+" + I2S(slots) + " Bag Slots"
        endif
        return SHP_AddStockEntry(vendorId, SHOP_STOCK_KIND_BAG_SLOTS, 0, price, category, slots, serviceName, SHP_GetBagSlotServiceIcon(slots), SHP_GetBagSlotServiceTooltip(slots), aiPriceCap, aiWeight)
    endfunction

    public function AddBagSlotService takes integer vendorId, string serviceName, integer slots, integer price, string category returns integer
        return Shop_AddBagSlotServiceEx(vendorId, serviceName, slots, price, category, 0, 0)
    endfunction

    public function GetVendorStockCount takes integer vendorId returns integer
        local integer stockId = 1
        local integer count = 0

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId then
                set count = count + 1
            endif
            set stockId = stockId + 1
        endloop
        return count
    endfunction

    public function GetVendorStockEntry takes integer vendorId, integer position returns integer
        local integer stockId = 1
        local integer count = 0

        if position <= 0 then
            return 0
        endif
        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId then
                set count = count + 1
                if count == position then
                    return stockId
                endif
            endif
            set stockId = stockId + 1
        endloop
        return 0
    endfunction

    private function SHP_CategoryExistsBefore takes integer vendorId, string category, integer beforeStockId returns boolean
        local integer stockId = 1

        loop
            exitwhen stockId >= beforeStockId
            if SHP_StockVendor[stockId] == vendorId and SHP_GetStockCategoryName(stockId) == category then
                return true
            endif
            set stockId = stockId + 1
        endloop
        return false
    endfunction

    public function GetAllCategoryName takes nothing returns string
        return SHP_CATEGORY_ALL
    endfunction

    public function GetRecentlySoldCategoryName takes nothing returns string
        return SHP_CATEGORY_RECENTLY_SOLD
    endfunction

    public function BeginTradeSession takes integer vendorId returns nothing
        if SHP_IsVendorIdValid(vendorId) then
            set SHP_SessionVendorId = vendorId
        else
            set SHP_SessionVendorId = 0
        endif
        call SHP_SetMessage("")
    endfunction

    public function EndTradeSession takes nothing returns nothing
        set SHP_SessionVendorId = 0
        call SHP_SetMessage("")
    endfunction

    public function GetVendorCategoryCount takes integer vendorId, boolean includeRecentlySold returns integer
        local integer stockId = 1
        local integer count = 1
        local string category

        if not SHP_IsVendorIdValid(vendorId) then
            return 0
        endif

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId then
                set category = SHP_GetStockCategoryName(stockId)
                if not SHP_CategoryExistsBefore(vendorId, category, stockId) then
                    set count = count + 1
                endif
            endif
            set stockId = stockId + 1
        endloop

        if includeRecentlySold and SHP_RecentSoldCount[vendorId] > 0 then
            set count = count + 1
        endif
        return count
    endfunction

    public function GetVendorCategoryName takes integer vendorId, integer position returns string
        local integer stockId = 1
        local integer count = 1
        local string category

        if not SHP_IsVendorIdValid(vendorId) or position <= 0 then
            return ""
        endif
        if position == 1 then
            return SHP_CATEGORY_ALL
        endif

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId then
                set category = SHP_GetStockCategoryName(stockId)
                if not SHP_CategoryExistsBefore(vendorId, category, stockId) then
                    set count = count + 1
                    if count == position then
                        return category
                    endif
                endif
            endif
            set stockId = stockId + 1
        endloop

        if SHP_RecentSoldCount[vendorId] > 0 and count + 1 == position then
            return SHP_CATEGORY_RECENTLY_SOLD
        endif
        return ""
    endfunction

    public function GetVendorStockCountByCategory takes integer vendorId, string category returns integer
        local integer stockId = 1
        local integer count = 0

        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId and (SHP_IsAllCategory(category) or SHP_GetStockCategoryName(stockId) == category) then
                set count = count + 1
            endif
            set stockId = stockId + 1
        endloop
        return count
    endfunction

    public function GetVendorStockEntryByCategory takes integer vendorId, integer position, string category returns integer
        local integer stockId = 1
        local integer count = 0

        if position <= 0 then
            return 0
        endif
        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId and (SHP_IsAllCategory(category) or SHP_GetStockCategoryName(stockId) == category) then
                set count = count + 1
                if count == position then
                    return stockId
                endif
            endif
            set stockId = stockId + 1
        endloop
        return 0
    endfunction

    public function GetStockItemType takes integer stockId returns integer
        if SHP_IsStockIdValid(stockId) and SHP_StockKind[stockId] == SHOP_STOCK_KIND_ITEM then
            return SHP_StockItemType[stockId]
        endif
        return 0
    endfunction

    public function GetStockPrice takes integer stockId returns integer
        if SHP_IsStockIdValid(stockId) then
            return SHP_StockPrice[stockId]
        endif
        return 0
    endfunction

    public function GetStockCategory takes integer stockId returns string
        return SHP_GetStockCategoryName(stockId)
    endfunction

    public function GetStockName takes integer stockId returns string
        if SHP_IsStockIdValid(stockId) then
            if SHP_StockName[stockId] != null and SHP_StockName[stockId] != "" then
                return SHP_StockName[stockId]
            endif
            if SHP_StockKind[stockId] != SHOP_STOCK_KIND_ITEM then
                return ""
            endif
            return GetObjectName(SHP_StockItemType[stockId])
        endif
        return ""
    endfunction

    public function GetStockIconPath takes integer stockId returns string
        if SHP_IsStockIdValid(stockId) then
            if SHP_StockIconPath[stockId] != null and SHP_StockIconPath[stockId] != "" then
                return SHP_StockIconPath[stockId]
            endif
            if SHP_StockKind[stockId] != SHOP_STOCK_KIND_ITEM then
                return SHP_ItemTypeIcon(0)
            endif
            return SHP_ItemTypeIcon(SHP_StockItemType[stockId])
        endif
        return SHP_ItemTypeIcon(0)
    endfunction

    public function GetStockTooltip takes integer stockId returns string
        if SHP_IsStockIdValid(stockId) then
            if SHP_StockTooltip[stockId] != null and SHP_StockTooltip[stockId] != "" then
                return SHP_StockTooltip[stockId]
            endif
            if SHP_StockKind[stockId] != SHOP_STOCK_KIND_ITEM then
                return ""
            endif
            return SHP_ItemTypeTooltip(SHP_StockItemType[stockId])
        endif
        return ""
    endfunction

    public function GetSessionSoldCount takes nothing returns integer
        if SHP_IsVendorIdValid(SHP_SessionVendorId) then
            return SHP_RecentSoldCount[SHP_SessionVendorId]
        endif
        return 0
    endfunction

    public function GetSessionSoldItemType takes integer soldIndex returns integer
        local integer vendorId = SHP_SessionVendorId

        if SHP_IsVendorIdValid(vendorId) and soldIndex > 0 and soldIndex <= SHP_RecentSoldCount[vendorId] then
            return SHP_RecentSoldItemType[SHP_GetRecentSoldKey(vendorId, soldIndex)]
        endif
        return 0
    endfunction

    public function GetSessionSoldPrice takes integer soldIndex returns integer
        local integer vendorId = SHP_SessionVendorId

        if SHP_IsVendorIdValid(vendorId) and soldIndex > 0 and soldIndex <= SHP_RecentSoldCount[vendorId] then
            return SHP_RecentSoldPrice[SHP_GetRecentSoldKey(vendorId, soldIndex)]
        endif
        return 0
    endfunction

    public function GetSessionSoldCategory takes integer soldIndex returns string
        local integer vendorId = SHP_SessionVendorId

        if SHP_IsVendorIdValid(vendorId) and soldIndex > 0 and soldIndex <= SHP_RecentSoldCount[vendorId] then
            return SHP_NormalizeCategory(SHP_RecentSoldCategory[SHP_GetRecentSoldKey(vendorId, soldIndex)])
        endif
        return SHP_CATEGORY_GOODS
    endfunction

    public function GetSessionSoldName takes integer soldIndex returns string
        local integer itemTypeId = Shop_GetSessionSoldItemType(soldIndex)

        if itemTypeId != 0 then
            return GetObjectName(itemTypeId)
        endif
        return ""
    endfunction

    public function GetSessionSoldIconPath takes integer soldIndex returns string
        return SHP_ItemTypeIcon(Shop_GetSessionSoldItemType(soldIndex))
    endfunction

    public function GetSessionSoldTooltip takes integer soldIndex returns string
        return SHP_ItemTypeTooltip(Shop_GetSessionSoldItemType(soldIndex))
    endfunction

    public function GiveItemToUnit takes unit owner, item whichItem returns boolean
        local boolean result = false

        if owner == null or whichItem == null then
            set owner = null
            set whichItem = null
            return false
        endif

        if SHP_TryStoreItemInDInventory(owner, whichItem) then
            set result = true
        elseif SHP_TryAddItemToVanilla(owner, whichItem) then
            set result = true
        endif

        set owner = null
        set whichItem = null
        return result
    endfunction

    private function SHP_CanUnitUseBagSlotService takes unit buyer returns boolean
        local player owner
        local mapcontrol controller
        local boolean result = false

        if buyer == null then
            set buyer = null
            return false
        endif
        set owner = GetOwningPlayer(buyer)
        set controller = GetPlayerController(owner)
        if controller != MAP_CONTROL_USER then
            set owner = null
            set controller = null
            set buyer = null
            return false
        endif
        if InventoryParadigm == "1PerPlayer" then
            set result = true
        elseif BIDOfUnit(buyer) > 0 then
            set result = true
        endif

        set owner = null
        set controller = null
        set buyer = null
        return result
    endfunction

    private function SHP_BuyBagSlotService takes player buyerPlayer, unit buyer, integer stockId returns boolean
        local integer price
        local integer slots

        if buyer == null or not SHP_IsStockIdValid(stockId) then
            call SHP_SetMessage("|cffff8080No bag upgrade selected.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif
        if buyerPlayer == null then
            set buyerPlayer = GetOwningPlayer(buyer)
        endif
        if not SHP_CanUnitUseBagSlotService(buyer) then
            call SHP_SetMessage("|cffff8080This hero cannot use DInventory bag upgrades.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif

        set price = SHP_StockPrice[stockId]
        set slots = SHP_StockPayload[stockId]
        if GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) < price then
            call SHP_SetMessage("|cffff8080Not enough gold.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif

        if DInvAddSlotsForHeroVendor(buyer, slots) then
            call SetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) - price)
            call SHP_SetMessage("|cff80ff80Bought " + Shop_GetStockName(stockId) + " for " + I2S(price) + " gold.|r")
            set buyerPlayer = null
            set buyer = null
            return true
        endif

        call SHP_SetMessage("|cffff8080Cannot expand inventory further.|r")
        set buyerPlayer = null
        set buyer = null
        return false
    endfunction

    public function BuyStock takes player buyerPlayer, unit buyer, integer stockId returns boolean
        local integer itemTypeId
        local integer price
        local item boughtItem = null
        local boolean result

        if buyer == null or not SHP_IsStockIdValid(stockId) then
            call SHP_SetMessage("|cffff8080No item selected.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif
        if SHP_StockKind[stockId] == SHOP_STOCK_KIND_BAG_SLOTS then
            set result = SHP_BuyBagSlotService(buyerPlayer, buyer, stockId)
            set buyerPlayer = null
            set buyer = null
            return result
        endif
        if buyerPlayer == null then
            set buyerPlayer = GetOwningPlayer(buyer)
        endif

        set price = SHP_StockPrice[stockId]
        if GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) < price then
            call SHP_SetMessage("|cffff8080Not enough gold.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif

        set itemTypeId = SHP_StockItemType[stockId]
        set boughtItem = CreateItem(itemTypeId, GetUnitX(buyer), GetUnitY(buyer))
        if boughtItem != null and Shop_GiveItemToUnit(buyer, boughtItem) then
            call SetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) - price)
            call SHP_SetMessage("|cff80ff80Bought " + GetObjectName(itemTypeId) + " for " + I2S(price) + " gold.|r")
            set boughtItem = null
            set buyerPlayer = null
            set buyer = null
            return true
        endif

        if boughtItem != null then
            call RemoveItem(boughtItem)
        endif
        call SHP_SetMessage("|cffff8080Inventory is full.|r")
        set boughtItem = null
        set buyerPlayer = null
        set buyer = null
        return false
    endfunction

    public function BuyRecentlySold takes player buyerPlayer, unit buyer, integer soldIndex returns boolean
        local integer vendorId = SHP_SessionVendorId
        local integer itemTypeId
        local integer price
        local item boughtItem = null

        if buyer == null or not SHP_IsVendorIdValid(vendorId) or soldIndex <= 0 or soldIndex > SHP_RecentSoldCount[vendorId] then
            call SHP_SetMessage("|cffff8080No buyback item selected.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif
        if buyerPlayer == null then
            set buyerPlayer = GetOwningPlayer(buyer)
        endif

        set itemTypeId = SHP_RecentSoldItemType[SHP_GetRecentSoldKey(vendorId, soldIndex)]
        set price = SHP_RecentSoldPrice[SHP_GetRecentSoldKey(vendorId, soldIndex)]
        if itemTypeId == 0 then
            call SHP_SetMessage("|cffff8080That item is no longer available.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif
        if price <= 0 then
            set price = 1
        endif
        if GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) < price then
            call SHP_SetMessage("|cffff8080Not enough gold.|r")
            set buyerPlayer = null
            set buyer = null
            return false
        endif

        set boughtItem = CreateItem(itemTypeId, GetUnitX(buyer), GetUnitY(buyer))
        if boughtItem != null and Shop_GiveItemToUnit(buyer, boughtItem) then
            call SetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(buyerPlayer, PLAYER_STATE_RESOURCE_GOLD) - price)
            call SHP_RemoveRecentSoldIndex(soldIndex)
            call SHP_SetMessage("|cff80ff80Bought back " + GetObjectName(itemTypeId) + " for " + I2S(price) + " gold.|r")
            set boughtItem = null
            set buyerPlayer = null
            set buyer = null
            return true
        endif

        if boughtItem != null then
            call RemoveItem(boughtItem)
        endif
        call SHP_SetMessage("|cffff8080Inventory is full.|r")
        set boughtItem = null
        set buyerPlayer = null
        set buyer = null
        return false
    endfunction

    public function BuildUnitInventory takes unit owner returns integer
        local integer pid
        local integer bid
        local integer eqid
        local integer slotId
        local integer capacity
        local item whichItem = null

        call SHP_ClearView()
        if owner == null then
            set owner = null
            return 0
        endif

        set pid = GetPlayerId(GetOwningPlayer(owner))
        set bid = BIDOfUnit(owner)
        set eqid = EQIDOfUnit(owner)

        if bid > 0 then
            set capacity = MaxBagCapacityOfBID(pid, bid)
            set slotId = 0
            loop
                exitwhen slotId >= capacity
                set whichItem = DInventoryDB[bid].item[slotId]
                if whichItem != null then
                    call SHP_AddViewItem(whichItem, SHOP_SOURCE_DINV, slotId, bid, pid)
                endif
                set slotId = slotId + 1
            endloop
        endif

        if eqid > 0 then
            set slotId = 1
            loop
                exitwhen slotId > HighestSlotNumber
                set whichItem = EQIDDB[eqid][4].item[slotId]
                if whichItem != null then
                    call SHP_AddViewItem(whichItem, SHOP_SOURCE_DEQUIP, slotId, bid, pid)
                endif
                set slotId = slotId + 1
            endloop
        endif

        set slotId = 0
        loop
            exitwhen slotId >= UnitInventorySize(owner)
            set whichItem = UnitItemInSlot(owner, slotId)
            if whichItem != null and not IsItemStoredInDInv(whichItem) then
                call SHP_AddViewItem(whichItem, SHOP_SOURCE_VANILLA, slotId, bid, pid)
            endif
            set slotId = slotId + 1
        endloop

        set whichItem = null
        set owner = null
        return SHP_ViewCount
    endfunction

    public function GetViewCount takes nothing returns integer
        return SHP_ViewCount
    endfunction

    public function GetViewItem takes integer viewIndex returns item
        if viewIndex > 0 and viewIndex <= SHP_ViewCount then
            return SHP_ViewItem[viewIndex]
        endif
        return null
    endfunction

    public function GetViewSource takes integer viewIndex returns integer
        if viewIndex > 0 and viewIndex <= SHP_ViewCount then
            return SHP_ViewSource[viewIndex]
        endif
        return 0
    endfunction

    public function GetViewSourceLabel takes integer viewIndex returns string
        if viewIndex <= 0 or viewIndex > SHP_ViewCount then
            return ""
        endif
        if SHP_ViewSource[viewIndex] == SHOP_SOURCE_DEQUIP then
            return "|cffffcc00Equipt|r"
        elseif SHP_ViewSource[viewIndex] == SHOP_SOURCE_DINV then
            return "|cffaaaaffDInv|r"
        elseif SHP_ViewSource[viewIndex] == SHOP_SOURCE_VANILLA then
            return "|cffaaaaffBag|r"
        endif
        return ""
    endfunction

    public function GetViewName takes integer viewIndex returns string
        local item whichItem = Shop_GetViewItem(viewIndex)
        local string itemName = ""

        if whichItem != null then
            set itemName = GetItemName(whichItem)
        endif
        set whichItem = null
        return itemName
    endfunction

    public function GetViewIconPath takes integer viewIndex returns string
        local item whichItem = Shop_GetViewItem(viewIndex)
        local string iconPath = ""

        if whichItem != null then
            set iconPath = BlzGetItemIconPath(whichItem)
        endif
        if iconPath == null or iconPath == "" then
            set iconPath = SHP_ItemTypeIcon(0)
        endif
        set whichItem = null
        return iconPath
    endfunction

    public function GetViewTooltip takes integer viewIndex returns string
        local item whichItem = Shop_GetViewItem(viewIndex)
        local string tooltip = ""

        if whichItem != null then
            set tooltip = BlzGetItemExtendedTooltip(whichItem)
        endif
        if tooltip == null then
            set tooltip = ""
        endif
        set whichItem = null
        return tooltip
    endfunction

    public function GetItemSaleValue takes item whichItem returns integer
        return SHP_GetItemSaleValue(whichItem)
    endfunction

    public function GetViewSaleValue takes integer viewIndex returns integer
        local item whichItem = Shop_GetViewItem(viewIndex)
        local integer value = 0

        if whichItem != null and not SHP_IsQuestItem(whichItem) then
            set value = Shop_GetItemSaleValue(whichItem)
        endif
        set whichItem = null
        return value
    endfunction

    public function IsViewItemSellable takes integer viewIndex returns boolean
        local item whichItem = Shop_GetViewItem(viewIndex)
        local boolean result = false

        if whichItem != null and not SHP_IsQuestItem(whichItem) and Shop_GetViewSource(viewIndex) != SHOP_SOURCE_DEQUIP then
            set result = true
        endif
        set whichItem = null
        return result
    endfunction

    public function SellViewItem takes player receiver, unit owner, integer viewIndex returns boolean
        return SHP_RemoveViewItem(receiver, owner, viewIndex, SHP_SessionVendorId, true, false)
    endfunction

    public function AIBuySimple takes unit buyer, unit vendor returns boolean
        local integer vendorId
        local integer stockId = 1
        local integer selectedStock = 0
        local integer totalWeight = 0
        local integer priceCap
        local integer itemTypeId
        local integer price
        local integer weight
        local boolean candidate
        local item boughtItem = null

        if buyer == null or vendor == null then
            set buyer = null
            set vendor = null
            return false
        endif

        set vendorId = Shop_GetVendorIdForUnit(vendor)
        if vendorId <= 0 then
            set buyer = null
            set vendor = null
            return false
        endif

        set priceCap = SHP_GetAIPriceCap(buyer)
        loop
            exitwhen stockId > SHP_StockCount
            if SHP_StockVendor[stockId] == vendorId and SHP_StockAiWeight[stockId] > 0 then
                set candidate = false
                set price = SHP_StockPrice[stockId]
                set weight = SHP_StockAiWeight[stockId]
                if price <= priceCap and (SHP_StockAiPriceCap[stockId] <= 0 or price <= SHP_StockAiPriceCap[stockId]) then
                    if SHP_StockKind[stockId] == SHOP_STOCK_KIND_ITEM then
                        set itemTypeId = SHP_StockItemType[stockId]
                        set candidate = (not SHP_IsEquipmentItemType(itemTypeId) and SHP_CountStoredItemType(buyer, itemTypeId) < SHP_AI_MAX_DUPLICATE_ITEMS) or (SHP_IsEquipmentItemType(itemTypeId) and SHP_CountStoredItemType(buyer, itemTypeId) <= 0)
                    endif
                    if candidate then
                        set totalWeight = totalWeight + weight
                        if GetRandomInt(1, totalWeight) <= weight then
                            set selectedStock = stockId
                        endif
                    endif
                endif
            endif
            set stockId = stockId + 1
        endloop

        if selectedStock <= 0 then
            set buyer = null
            set vendor = null
            return false
        endif

        set boughtItem = CreateItem(SHP_StockItemType[selectedStock], GetUnitX(buyer), GetUnitY(buyer))
        if boughtItem != null and Shop_GiveItemToUnit(buyer, boughtItem) then
            set boughtItem = null
            set buyer = null
            set vendor = null
            return true
        endif
        if boughtItem != null then
            call RemoveItem(boughtItem)
        endif

        set boughtItem = null
        set buyer = null
        set vendor = null
        return false
    endfunction

    public function AISellSimple takes unit seller, unit vendor returns boolean
        local integer vendorId
        local integer viewIndex = 1
        local integer selected = 0
        local boolean sold = false
        local item whichItem = null

        if seller == null or vendor == null then
            set seller = null
            set vendor = null
            return false
        endif
        set vendorId = Shop_GetVendorIdForUnit(vendor)
        if vendorId <= 0 then
            set seller = null
            set vendor = null
            return false
        endif

        call Shop_BuildUnitInventory(seller)
        loop
            exitwhen viewIndex > SHP_ViewCount
            set whichItem = SHP_ViewItem[viewIndex]
            if whichItem != null and SHP_ViewSource[viewIndex] != SHOP_SOURCE_DEQUIP and not SHP_ShouldAIKeepItem(seller, whichItem) then
                set selected = viewIndex
                set viewIndex = SHP_ViewCount
            endif
            set viewIndex = viewIndex + 1
        endloop

        if selected > 0 then
            set whichItem = null
            set sold = SHP_RemoveViewItem(null, seller, selected, vendorId, false, false)
            set seller = null
            set vendor = null
            return sold
        endif

        set whichItem = null
        set seller = null
        set vendor = null
        return false
    endfunction

    private function Init takes nothing returns nothing
        set SHP_VendorByUnit = Table.create()
        set SHP_VendorByUnitType = Table.create()
    endfunction
endlibrary
