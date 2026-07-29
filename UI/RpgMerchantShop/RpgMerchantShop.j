library RpgMerchantShopSystem

/*------------------------------------------------------------------------------------------------------------------------------------------------------------
*
*    -------------------
*    | RpgMerchantShop |
*    -------------------
*
*    RpgMerchantShop class
*    --------------------
*        A configurable popup shop that displays a searchable, sortable catalog of goods.
*        The public API is intentionally limited to the methods listed below. Internal frame handles,
*        player state, catalog storage, sorting internals, and transaction bookkeeping are private.
*        The shop supports custom categories, custom rarities, real item rawcodes, virtual goods,
*        per-shop visuals, adjustable item-card counts, buy/sell transactions, and owned-count display.
*
*    RpgMerchantShop.create(string titleText) -> RpgMerchantShop
*        - Creates a new shop window with the specified title.
*        - The window starts hidden. Use shop.openFor(player) to display it.
*
*    shop.addCategory(string label) -> integer
*        - Registers a category and returns the category id.
*        - Store the returned id and pass it to addItem or addVirtualItem.
*        - Category order controls the Type sort order.
*
*    shop.addRarity(string label, string colorPrefix) -> integer
*        - Registers a rarity and returns the rarity id.
*        - colorPrefix should be a Warcraft color prefix such as "|cff66aaff".
*        - Rarity order controls the Rarity sort order. Add low rarities first and high rarities later when you want descending rarity to show the best items first.
*
*    shop.addItem(string name, string icon, integer categoryId, integer rarityId, integer price, integer attack, integer defense, integer rawId, string desc) -> integer
*        - Adds a real Warcraft item-backed shop entry and returns its shop item id.
*        - rawId should use a single-quoted rawcode literal such as 'phea'. Do not use FourCC.
*        - Bought real items are created as hidden storage items near a map corner and tracked by count.
*        - Returns -1 if categoryId or rarityId was not registered on this shop.
*
*    shop.addVirtualItem(string name, string icon, integer categoryId, integer rarityId, integer price, integer attack, integer defense, string desc) -> integer
*        - Adds a non-rawcode good and returns its shop item id.
*        - Use this for tokens, crafting materials, keys, currencies, reputation goods, quest counters, or other abstract goods.
*        - Virtual goods are tracked by count only.
*        - Returns -1 if categoryId or rarityId was not registered on this shop.
*
*    shop.clearCatalog()
*        - Removes all shop items and owned counts.
*        - Categories and rarities remain registered.
*
*    shop.clearTaxonomyAndCatalog()
*        - Removes all shop items, owned counts, categories, and rarities.
*        - Use this when fully rebuilding a shop from scratch.
*
*    shop.openFor(player p)
*        - Opens the shop for player p and refreshes its current state.
*
*    shop.closeFor(player p)
*        - Closes the shop for player p.
*
*    shop.toggleFor(player p)
*        - Opens the shop if it is hidden for player p, otherwise closes it.
*
*    shop.setSortByRarity(player p)
*        - Sets player p's current sort mode to rarity order.
*
*    shop.setSortByPrice(player p)
*        - Sets player p's current sort mode to price order.
*
*    shop.setSortByName(player p)
*        - Sets player p's current sort mode to name order.
*
*    shop.setSortByType(player p)
*        - Sets player p's current sort mode to category/type order.
*
*    shop.setSortAscending(player p)
*        - Sets player p's current sort direction to ascending.
*
*    shop.setSortDescending(player p)
*        - Sets player p's current sort direction to descending.
*
*    shop.setVisibleItemSlotCount(integer slotCount)
*        - Sets how many item cards are shown per page.
*        - Values below 1 are clamped to 1.
*        - Item cards reflow inside the content area so they do not cover the system text or page controls.
*
*    shop.getVisibleItemSlotCount() -> integer
*        - Returns the current item-card count for this shop.
*
*    shop.setShopFont(string fontPath)
*        - Changes the font used by this shop.
*
*    shop.setBlockerTexture(string texturePath)
*        - Changes the dark screen-blocker texture used behind this shop.
*
*    shop.setPanelTexture(string texturePath)
*        - Changes the main popup panel texture used by this shop.
*
*    shop.setTooltipTexture(string texturePath)
*        - Changes the item-card, details-panel, and smaller UI-panel texture used by this shop.
*
*    shop.setVisualStyle(string fontPath, string blockerPath, string panelPath, string tooltipPath)
*        - Changes the font, blocker texture, main panel texture, and tooltip/panel texture at once.
*
*    Built-in behavior
*    -----------------
*        - Search matches item names, category names, and rarity names.
*        - Category changes, sort changes, and search changes preserve the selected item unless the item no longer exists.
*        - Buy/sell feedback is shown inside the shop window.
*        - Gold text refreshes automatically while the shop is open.
*        - The quantity buttons, sort buttons, and transaction buttons use click guards to avoid duplicate click processing.
*        - The MAX quantity button chooses the highest useful amount based on owned count and/or affordable count, capped at 99.
*
*    Example
*    -------
*        local RpgMerchantShop shop = RpgMerchantShop.create("MERCHANT'S STORE")
*        local integer weapons = shop.addCategory("Weapons")
*        local integer potions = shop.addCategory("Potions")
*        local integer materials = shop.addCategory("Materials")
*        local integer common = shop.addRarity("COMMON", "|cffffffff")
*        local integer uncommon = shop.addRarity("UNCOMMON", "|cff66ff66")
*        local integer rare = shop.addRarity("RARE", "|cff66aaff")
*
*        call shop.setVisibleItemSlotCount(8)
*        call shop.addItem("Ironwood Bow", "ReplaceableTextures\\CommandButtons\\BTNImprovedBows.blp", weapons, uncommon, 2150, 64, 0, 'rat9', "A sturdy bow made from reinforced ironwood.")
*        call shop.addItem("Elixir of Superior Healing", "ReplaceableTextures\\CommandButtons\\BTNPotionRed.blp", potions, rare, 1250, 0, 0, 'phea', "Restores 750 Health.")
*        call shop.addVirtualItem("Soulstone Shard", "ReplaceableTextures\\CommandButtons\\BTNGem.blp", materials, common, 750, 0, 0, "Crafting material used to imbue powerful gear.")
*        call shop.setSortByRarity(Player(0))
*        call shop.setSortDescending(Player(0))
*        call shop.openFor(Player(0))
*
*------------------------------------------------------------------------------------------------------------------------------------------------------------*/

globals
    private constant integer ALL_CATEGORY_ID = -1
    private constant integer SORT_RARITY = 0
    private constant integer SORT_PRICE = 1
    private constant integer SORT_NAME = 2
    private constant integer SORT_TYPE = 3
    private constant integer SORT_ASCENDING = 0
    private constant integer SORT_DESCENDING = 1
    private timer RpgShopClock = CreateTimer()
    private integer RpgShopNextInstanceId = 0
    private real RpgShopBoundMinX = 0.0
    private real RpgShopBoundMinY = 0.0
    private real RpgShopBoundMaxX = 0.0
    private real RpgShopBoundMaxY = 0.0
endglobals

private function RpgShopGold takes player p returns integer
    return GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
endfunction

private function RpgShopAddGold takes player p, integer amount returns nothing
    call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, RpgShopGold(p) + amount)
endfunction

private function RpgShopSubGold takes player p, integer amount returns nothing
    call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, RpgShopGold(p) - amount)
endfunction

private function RpgShopFrameShowFor takes player p, framehandle f, boolean flag returns nothing
    if GetLocalPlayer() == p then
        call BlzFrameSetVisible(f, flag)
    endif
endfunction

private function RpgShopFrameEnableFor takes player p, framehandle f, boolean flag returns nothing
    if GetLocalPlayer() == p then
        call BlzFrameSetEnable(f, flag)
    endif
endfunction

private function RpgShopFrameShowEnableFor takes player p, framehandle f, boolean flag returns nothing
    if GetLocalPlayer() == p then
        call BlzFrameSetVisible(f, flag)
        call BlzFrameSetEnable(f, flag)
    endif
endfunction

private function RpgShopFrameTextFor takes player p, framehandle f, string text returns nothing
    if GetLocalPlayer() == p then
        call BlzFrameSetText(f, text)
    endif
endfunction

private function RpgShopFrameTextureFor takes player p, framehandle f, string texturePath returns nothing
    if GetLocalPlayer() == p then
        call BlzFrameSetTexture(f, texturePath, 0, true)
    endif
endfunction

private struct RpgShopCategoryData
    integer id
    string label
    thistype next
endstruct

private struct RpgShopRarityData
    integer id
    string label
    string colorPrefix
    thistype next
endstruct

private struct RpgShopItemData
    integer id
    string name
    string icon
    string desc
    integer categoryId
    integer rarityId
    integer price
    integer attack
    integer defense
    integer rawId
    thistype next
endstruct

private struct RpgShopItemNode
    RpgShopItemData data
    thistype next
endstruct

private struct RpgShopOwnedEntry
    integer itemId
    integer count
    item hiddenItem
    thistype next
endstruct

private struct RpgShopPlayerState
    player owner
    boolean isOpen
    integer pid
    integer selectedCategory
    integer categoryPage
    integer selectedItem
    integer sortMode
    integer sortOrder
    integer quantity
    integer currentPage
    string searchText
    string systemMessage
    real lastQuantityClick
    real lastTradeClick
    real lastSortClick
    real lastSortOrderClick
    RpgShopOwnedEntry ownedHead
    RpgShopOwnedEntry ownedTail
    thistype next
endstruct

private struct RpgShopCategoryButtonSlot
    integer index
    framehandle buttonFrame
    thistype next
endstruct

private struct RpgShopItemFrameSlot
    integer index
    framehandle backdrop
    framehandle icon
    framehandle text
    framehandle buttonFrame
    thistype next
endstruct

struct RpgMerchantShop
    private static thistype first = 0
    private static thistype last = 0

    private thistype nextShop
    private integer instanceId
    private integer nextCategoryId
    private integer nextRarityId
    private integer nextItemId
    private string framePrefix
    private string windowTitle
    private string shopFontPath
    private string blockerTexturePath
    private string panelTexturePath
    private string tooltipTexturePath
    private integer visibleItemSlotCount

    private RpgShopPlayerState playerHead
    private RpgShopPlayerState playerTail
    private RpgShopCategoryData categoryHead
    private RpgShopCategoryData categoryTail
    private RpgShopRarityData rarityHead
    private RpgShopRarityData rarityTail
    private RpgShopItemData itemHead
    private RpgShopItemData itemTail
    private RpgShopItemNode visibleHead
    private RpgShopItemNode visibleTail
    private RpgShopItemNode sortedHead
    private RpgShopItemNode sortedTail
    private integer visibleCount
    private integer sortedCount
    private RpgShopCategoryButtonSlot categoryButtonHead
    private RpgShopCategoryButtonSlot categoryButtonTail
    private integer categoryButtonSlotCount
    private RpgShopItemFrameSlot itemFrameHead
    private RpgShopItemFrameSlot itemFrameTail
    private integer itemFrameSlotCount

    private framehandle blocker
    private framehandle root
    private framehandle windowBackdrop
    private framehandle title
    private framehandle closeButton
    private framehandle searchBox
    private framehandle sortButton
    private framehandle sortOrderButton
    private framehandle goldText
    private framehandle systemText
    private framehandle detailsPanel
    private framehandle detailsIcon
    private framehandle detailsTitle
    private framehandle detailsBody
    private framehandle costText
    private framehandle ownedText
    private framehandle minusButton
    private framehandle plusButton
    private framehandle maxButton
    private framehandle quantityText
    private framehandle buyButton
    private framehandle sellButton
    private framehandle pageText
    private framehandle prevButton
    private framehandle nextButton
    private framehandle categoryPrevButton
    private framehandle categoryNextButton

    private static method timerNow takes nothing returns real
        return TimerGetElapsed(RpgShopClock)
    endmethod

    private static method registerClick takes framehandle f returns nothing
        local trigger t = CreateTrigger()
        call BlzTriggerRegisterFrameEvent(t, f, FRAMEEVENT_CONTROL_CLICK)
        call TriggerAddAction(t, function thistype.onFrameClick)
        set t = null
    endmethod

    private static method registerEditbox takes framehandle f returns nothing
        local trigger t = CreateTrigger()
        call BlzTriggerRegisterFrameEvent(t, f, FRAMEEVENT_EDITBOX_TEXT_CHANGED)
        call TriggerAddAction(t, function thistype.onEditboxChanged)
        set t = null
    endmethod

    private static method registerMouseDown takes framehandle f returns nothing
        local trigger t = CreateTrigger()
        call BlzTriggerRegisterFrameEvent(t, f, FRAMEEVENT_MOUSE_DOWN)
        call TriggerAddAction(t, function thistype.onMouseDown)
        set t = null
    endmethod

    static method create takes string titleText returns thistype
        local thistype this = thistype.allocate()
        set this.nextShop = 0
        set this.instanceId = RpgShopNextInstanceId
        set RpgShopNextInstanceId = RpgShopNextInstanceId + 1
        set this.nextCategoryId = 0
        set this.nextRarityId = 0
        set this.nextItemId = 0
        set this.framePrefix = "RpgShop" + I2S(this.instanceId) + "_"
        set this.windowTitle = titleText
        set this.shopFontPath = "Fonts\\FRIZQT__.TTF"
        set this.blockerTexturePath = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        set this.panelTexturePath = "UI\\Widgets\\EscMenu\\Human\\human-options-menu-background.blp"
        set this.tooltipTexturePath = "UI\\Widgets\\ToolTips\\Human\\human-tooltip-background.blp"
        set this.visibleItemSlotCount = 8
        set this.playerHead = 0
        set this.playerTail = 0
        set this.categoryHead = 0
        set this.categoryTail = 0
        set this.rarityHead = 0
        set this.rarityTail = 0
        set this.itemHead = 0
        set this.itemTail = 0
        set this.visibleHead = 0
        set this.visibleTail = 0
        set this.sortedHead = 0
        set this.sortedTail = 0
        set this.visibleCount = 0
        set this.sortedCount = 0
        set this.categoryButtonHead = 0
        set this.categoryButtonTail = 0
        set this.categoryButtonSlotCount = 0
        set this.itemFrameHead = 0
        set this.itemFrameTail = 0
        set this.itemFrameSlotCount = 0
        if thistype.first == 0 then
            set thistype.first = this
        else
            set thistype.last.nextShop = this
        endif
        set thistype.last = this
        call this.createFrames()
        call this.bindEvents()
        call BlzFrameSetVisible(this.root, false)
        call BlzFrameSetEnable(this.root, false)
        call BlzFrameSetVisible(this.blocker, false)
        call BlzFrameSetEnable(this.blocker, false)
        return this
    endmethod

    method openFor takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        set state.currentPage = 0
        set state.quantity = 1
        set state.systemMessage = "|cffaaaaaaSelect an item, then press BUY or SELL.|r"
        set state.isOpen = true
        call this.refreshFor(p)
        call RpgShopFrameShowEnableFor(p, this.root, true)
        call RpgShopFrameShowEnableFor(p, this.blocker, true)
        call RpgShopFrameShowEnableFor(p, this.searchBox, true)
    endmethod

    method closeFor takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        set state.isOpen = false
        call RpgShopFrameShowEnableFor(p, this.searchBox, false)
        call RpgShopFrameShowEnableFor(p, this.root, false)
        call RpgShopFrameShowEnableFor(p, this.blocker, false)
    endmethod

    method toggleFor takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if state.isOpen then
            call this.closeFor(p)
        else
            call this.openFor(p)
        endif
    endmethod

    method setShopFont takes string fontPath returns nothing
        set this.shopFontPath = fontPath
        call this.applyShopFont()
    endmethod

    method setBlockerTexture takes string texturePath returns nothing
        set this.blockerTexturePath = texturePath
        call BlzFrameSetTexture(this.blocker, this.blockerTexturePath, 0, true)
    endmethod

    method setPanelTexture takes string texturePath returns nothing
        set this.panelTexturePath = texturePath
        call BlzFrameSetTexture(this.root, this.panelTexturePath, 0, true)
        call BlzFrameSetTexture(this.windowBackdrop, this.panelTexturePath, 0, true)
    endmethod

    method setTooltipTexture takes string texturePath returns nothing
        set this.tooltipTexturePath = texturePath
        call this.applyTooltipTexture()
    endmethod

    method setVisualStyle takes string fontPath, string blockerPath, string panelPath, string tooltipPath returns nothing
        set this.shopFontPath = fontPath
        set this.blockerTexturePath = blockerPath
        set this.panelTexturePath = panelPath
        set this.tooltipTexturePath = tooltipPath
        call BlzFrameSetTexture(this.blocker, this.blockerTexturePath, 0, true)
        call BlzFrameSetTexture(this.root, this.panelTexturePath, 0, true)
        call BlzFrameSetTexture(this.windowBackdrop, this.panelTexturePath, 0, true)
        call this.applyTooltipTexture()
        call this.applyShopFont()
    endmethod

    method setVisibleItemSlotCount takes integer slotCount returns nothing
        local integer newSlotCount = slotCount
        if newSlotCount < 1 then
            set newSlotCount = 1
        endif
        set this.visibleItemSlotCount = newSlotCount
        call this.ensureItemCardFrames()
        call this.refreshOpenPlayers()
    endmethod

    method getVisibleItemSlotCount takes nothing returns integer
        return this.visibleItemSlotCount
    endmethod

    private method applySortOrder takes player p, integer order returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if order == SORT_ASCENDING then
            set state.sortOrder = SORT_ASCENDING
        else
            set state.sortOrder = SORT_DESCENDING
        endif
        call this.refreshFor(p)
    endmethod

    private method applySortMode takes player p, integer mode returns nothing
        if mode < SORT_RARITY or mode > SORT_TYPE then
            return
        endif
        set this.getState(p).sortMode = mode
        call this.refreshFor(p)
    endmethod

    method setSortByRarity takes player p returns nothing
        call this.applySortMode(p, SORT_RARITY)
    endmethod

    method setSortByPrice takes player p returns nothing
        call this.applySortMode(p, SORT_PRICE)
    endmethod

    method setSortByName takes player p returns nothing
        call this.applySortMode(p, SORT_NAME)
    endmethod

    method setSortByType takes player p returns nothing
        call this.applySortMode(p, SORT_TYPE)
    endmethod

    method setSortAscending takes player p returns nothing
        call this.applySortOrder(p, SORT_ASCENDING)
    endmethod

    method setSortDescending takes player p returns nothing
        call this.applySortOrder(p, SORT_DESCENDING)
    endmethod

    method addCategory takes string label returns integer
        local RpgShopCategoryData newCategory = RpgShopCategoryData.create()
        set newCategory.id = this.nextCategoryId
        set newCategory.label = label
        set newCategory.next = 0
        set this.nextCategoryId = this.nextCategoryId + 1
        if this.categoryHead == 0 then
            set this.categoryHead = newCategory
        else
            set this.categoryTail.next = newCategory
        endif
        set this.categoryTail = newCategory
        call this.refreshOpenPlayers()
        return newCategory.id
    endmethod

    method addRarity takes string label, string colorPrefix returns integer
        local RpgShopRarityData newRarity = RpgShopRarityData.create()
        set newRarity.id = this.nextRarityId
        set newRarity.label = label
        set newRarity.colorPrefix = colorPrefix
        set newRarity.next = 0
        set this.nextRarityId = this.nextRarityId + 1
        if this.rarityHead == 0 then
            set this.rarityHead = newRarity
        else
            set this.rarityTail.next = newRarity
        endif
        set this.rarityTail = newRarity
        call this.refreshOpenPlayers()
        return newRarity.id
    endmethod

    method addItem takes string name, string icon, integer categoryId, integer rarityId, integer price, integer attack, integer defense, integer rawId, string desc returns integer
        local RpgShopItemData newItem
        if (not this.validCategory(categoryId)) or (not this.validRarity(rarityId)) then
            return -1
        endif
        set newItem = RpgShopItemData.create()
        set newItem.id = this.nextItemId
        set newItem.name = name
        set newItem.icon = icon
        set newItem.categoryId = categoryId
        set newItem.rarityId = rarityId
        set newItem.price = price
        set newItem.attack = attack
        set newItem.defense = defense
        set newItem.rawId = rawId
        set newItem.desc = desc
        set newItem.next = 0
        set this.nextItemId = this.nextItemId + 1
        if this.itemHead == 0 then
            set this.itemHead = newItem
        else
            set this.itemTail.next = newItem
        endif
        set this.itemTail = newItem
        call this.refreshOpenPlayers()
        return newItem.id
    endmethod

    method addVirtualItem takes string name, string icon, integer categoryId, integer rarityId, integer price, integer attack, integer defense, string desc returns integer
        return this.addItem(name, icon, categoryId, rarityId, price, attack, defense, 0, desc)
    endmethod

    method clearCatalog takes nothing returns nothing
        local RpgShopPlayerState state = this.playerHead
        local RpgShopOwnedEntry entry
        local RpgShopOwnedEntry nextEntry
        local RpgShopItemData selected = this.itemHead
        local RpgShopItemData nextSelected
        loop
            exitwhen state == 0
            set entry = state.ownedHead
            loop
                exitwhen entry == 0
                set nextEntry = entry.next
                if entry.hiddenItem != null then
                    call RemoveItem(entry.hiddenItem)
                    set entry.hiddenItem = null
                endif
                call entry.destroy()
                set entry = nextEntry
            endloop
            set state.ownedHead = 0
            set state.ownedTail = 0
            set state.selectedItem = -1
            set state.currentPage = 0
            set state.quantity = 1
            set state = state.next
        endloop
        loop
            exitwhen selected == 0
            set nextSelected = selected.next
            call selected.destroy()
            set selected = nextSelected
        endloop
        set this.itemHead = 0
        set this.itemTail = 0
        call this.clearVisibleLists()
        set this.nextItemId = 0
        call this.refreshOpenPlayers()
    endmethod

    method clearTaxonomyAndCatalog takes nothing returns nothing
        local RpgShopCategoryData category
        local RpgShopCategoryData nextCategory
        local RpgShopRarityData rarity
        local RpgShopRarityData nextRarity
        local RpgShopPlayerState state
        call this.clearCatalog()
        set category = this.categoryHead
        loop
            exitwhen category == 0
            set nextCategory = category.next
            call category.destroy()
            set category = nextCategory
        endloop
        set rarity = this.rarityHead
        loop
            exitwhen rarity == 0
            set nextRarity = rarity.next
            call rarity.destroy()
            set rarity = nextRarity
        endloop
        set this.categoryHead = 0
        set this.categoryTail = 0
        set this.rarityHead = 0
        set this.rarityTail = 0
        set this.nextCategoryId = 0
        set this.nextRarityId = 0
        set state = this.playerHead
        loop
            exitwhen state == 0
            set state.selectedCategory = ALL_CATEGORY_ID
            set state.categoryPage = 0
            set state = state.next
        endloop
        call this.refreshOpenPlayers()
    endmethod

    private method getState takes player p returns RpgShopPlayerState
        local integer pid = GetPlayerId(p)
        local RpgShopPlayerState state = this.playerHead
        local RpgShopPlayerState newState
        loop
            exitwhen state == 0
            if state.pid == pid then
                return state
            endif
            set state = state.next
        endloop
        set newState = RpgShopPlayerState.create()
        set newState.owner = p
        set newState.isOpen = false
        set newState.pid = pid
        set newState.selectedCategory = ALL_CATEGORY_ID
        set newState.categoryPage = 0
        set newState.selectedItem = -1
        set newState.sortMode = SORT_RARITY
        set newState.sortOrder = SORT_DESCENDING
        set newState.quantity = 1
        set newState.currentPage = 0
        set newState.searchText = ""
        set newState.systemMessage = "|cffaaaaaaSelect an item, then press BUY or SELL.|r"
        set newState.lastQuantityClick = -1000.0
        set newState.lastTradeClick = -1000.0
        set newState.lastSortClick = -1000.0
        set newState.lastSortOrderClick = -1000.0
        set newState.ownedHead = 0
        set newState.ownedTail = 0
        set newState.next = 0
        if this.playerHead == 0 then
            set this.playerHead = newState
        else
            set this.playerTail.next = newState
        endif
        set this.playerTail = newState
        return newState
    endmethod

    private method createFrames takes nothing returns nothing
        local framehandle gameUi = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        set this.blocker = BlzCreateFrameByType("BACKDROP", this.framePrefix + "Blocker", gameUi, "", 0)
        call BlzFrameSetSize(this.blocker, 0.80, 0.60)
        call BlzFrameSetAbsPoint(this.blocker, FRAMEPOINT_CENTER, 0.40, 0.30)
        call BlzFrameSetTexture(this.blocker, this.blockerTexturePath, 0, true)
        call BlzFrameSetAlpha(this.blocker, 120)
        call BlzFrameSetLevel(this.blocker, 1)

        set this.root = BlzCreateFrameByType("BACKDROP", this.framePrefix + "Root", gameUi, "", 0)
        call BlzFrameSetSize(this.root, 0.72, 0.50)
        call BlzFrameSetAbsPoint(this.root, FRAMEPOINT_CENTER, 0.40, 0.30)
        call BlzFrameSetTexture(this.root, this.panelTexturePath, 0, true)
        call BlzFrameSetAlpha(this.root, 245)
        call BlzFrameSetLevel(this.root, 5)

        set this.windowBackdrop = BlzCreateFrameByType("BACKDROP", this.framePrefix + "WindowBackdrop", this.root, "", 0)
        call BlzFrameSetSize(this.windowBackdrop, 0.690, 0.465)
        call BlzFrameSetPoint(this.windowBackdrop, FRAMEPOINT_CENTER, this.root, FRAMEPOINT_CENTER, 0.0, -0.006)
        call BlzFrameSetTexture(this.windowBackdrop, this.panelTexturePath, 0, true)
        call BlzFrameSetAlpha(this.windowBackdrop, 135)
        call BlzFrameSetLevel(this.windowBackdrop, 0)
        call BlzFrameSetEnable(this.windowBackdrop, false)

        set this.title = BlzCreateFrameByType("TEXT", this.framePrefix + "Title", this.root, "", 0)
        call BlzFrameSetSize(this.title, 0.360, 0.030)
        call BlzFrameSetPoint(this.title, FRAMEPOINT_CENTER, this.root, FRAMEPOINT_TOP, 0.0, -0.027)
        call BlzFrameSetFont(this.title, this.shopFontPath, 0.022, 0)
        call BlzFrameSetText(this.title, "|cffffcc66" + this.windowTitle + "|r")
        call BlzFrameSetEnable(this.title, false)
        call BlzFrameSetTextAlignment(this.title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)

        set this.closeButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.closeButton, 0.045, 0.035)
        call BlzFrameSetPoint(this.closeButton, FRAMEPOINT_TOPRIGHT, this.root, FRAMEPOINT_TOPRIGHT, -0.014, -0.014)
        call BlzFrameSetText(this.closeButton, "X")

        set this.goldText = BlzCreateFrameByType("TEXT", this.framePrefix + "GoldText", this.root, "", 0)
        call BlzFrameSetSize(this.goldText, 0.145, 0.024)
        call BlzFrameSetPoint(this.goldText, FRAMEPOINT_CENTER, this.title, FRAMEPOINT_CENTER, 0.240, 0.0)
        call BlzFrameSetFont(this.goldText, this.shopFontPath, 0.014, 0)
        call BlzFrameSetText(this.goldText, "Gold: 0")
        call BlzFrameSetEnable(this.goldText, false)
        call BlzFrameSetTextAlignment(this.goldText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)

        set this.searchBox = BlzCreateFrame("EscMenuEditBoxTemplate", this.root, 0, 0)
        call BlzFrameSetSize(this.searchBox, 0.150, 0.030)
        call BlzFrameSetPoint(this.searchBox, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, 0.155, -0.046)
        call BlzFrameSetText(this.searchBox, "")
        call BlzFrameSetTextSizeLimit(this.searchBox, 32)
        call BlzFrameSetLevel(this.searchBox, 70)

        set this.sortButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.sortButton, 0.125, 0.034)
        call BlzFrameSetPoint(this.sortButton, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, 0.312, -0.045)
        call BlzFrameSetText(this.sortButton, "Sort: Rarity")
        call BlzFrameSetLevel(this.sortButton, 40)

        set this.sortOrderButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.sortOrderButton, 0.065, 0.034)
        call BlzFrameSetPoint(this.sortOrderButton, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, 0.443, -0.045)
        call BlzFrameSetText(this.sortOrderButton, "Desc")
        call BlzFrameSetLevel(this.sortOrderButton, 40)

        call this.createCategoryButtons()
        call this.createItemCards()
        call this.createDetailsPanel()

        set this.systemText = BlzCreateFrameByType("TEXT", this.framePrefix + "SystemText", this.root, "", 0)
        call BlzFrameSetSize(this.systemText, 0.345, 0.024)
        call BlzFrameSetPoint(this.systemText, FRAMEPOINT_BOTTOM, this.root, FRAMEPOINT_BOTTOM, -0.016, 0.063)
        call BlzFrameSetFont(this.systemText, this.shopFontPath, 0.011, 0)
        call BlzFrameSetText(this.systemText, "|cffaaaaaaSelect an item, then press BUY or SELL.|r")
        call BlzFrameSetEnable(this.systemText, false)
        call BlzFrameSetTextAlignment(this.systemText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)

        set this.prevButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.prevButton, 0.040, 0.030)
        call BlzFrameSetPoint(this.prevButton, FRAMEPOINT_CENTER, this.root, FRAMEPOINT_BOTTOM, -0.065, 0.035)
        call BlzFrameSetText(this.prevButton, "<")

        set this.pageText = BlzCreateFrameByType("TEXT", this.framePrefix + "PageText", this.root, "", 0)
        call BlzFrameSetSize(this.pageText, 0.060, 0.025)
        call BlzFrameSetPoint(this.pageText, FRAMEPOINT_CENTER, this.root, FRAMEPOINT_BOTTOM, 0.0, 0.035)
        call BlzFrameSetFont(this.pageText, this.shopFontPath, 0.013, 0)
        call BlzFrameSetText(this.pageText, "1 / 1")
        call BlzFrameSetEnable(this.pageText, false)
        call BlzFrameSetTextAlignment(this.pageText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)

        set this.nextButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.nextButton, 0.040, 0.030)
        call BlzFrameSetPoint(this.nextButton, FRAMEPOINT_CENTER, this.root, FRAMEPOINT_BOTTOM, 0.065, 0.035)
        call BlzFrameSetText(this.nextButton, ">")
        set gameUi = null
    endmethod

    private method createCategoryButtons takes nothing returns nothing
        local real buttonWidth = 0.132
        local real buttonHeight = 0.030
        local real buttonGap = 0.003
        local real leftInset = 0.012
        local real topInset = 0.048
        local real pagerReserve = 0.040
        local real mainBackdropHeight = 0.465
        local real usableHeight = mainBackdropHeight - topInset - pagerReserve
        local integer visibleButtonCount = R2I(usableHeight / (buttonHeight + buttonGap))
        local integer buttonIndex = 0
        local real y = -topInset
        local framehandle categoryButtonFrame
        local RpgShopCategoryButtonSlot slot
        if visibleButtonCount < 1 then
            set visibleButtonCount = 1
        endif
        loop
            exitwhen buttonIndex >= visibleButtonCount
            set categoryButtonFrame = BlzCreateFrame("ScriptDialogButton", this.root, 0, buttonIndex)
            call BlzFrameSetSize(categoryButtonFrame, buttonWidth, buttonHeight)
            call BlzFrameSetPoint(categoryButtonFrame, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, leftInset, y)
            call BlzFrameSetText(categoryButtonFrame, "")
            set slot = RpgShopCategoryButtonSlot.create()
            set slot.index = buttonIndex
            set slot.buttonFrame = categoryButtonFrame
            set slot.next = 0
            if this.categoryButtonHead == 0 then
                set this.categoryButtonHead = slot
            else
                set this.categoryButtonTail.next = slot
            endif
            set this.categoryButtonTail = slot
            set this.categoryButtonSlotCount = this.categoryButtonSlotCount + 1
            set buttonIndex = buttonIndex + 1
            set y = y - buttonHeight - buttonGap
        endloop

        set this.categoryPrevButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.categoryPrevButton, 0.062, 0.026)
        call BlzFrameSetPoint(this.categoryPrevButton, FRAMEPOINT_BOTTOMLEFT, this.windowBackdrop, FRAMEPOINT_BOTTOMLEFT, leftInset, 0.012)
        call BlzFrameSetText(this.categoryPrevButton, "<")

        set this.categoryNextButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.categoryNextButton, 0.062, 0.026)
        call BlzFrameSetPoint(this.categoryNextButton, FRAMEPOINT_BOTTOMLEFT, this.windowBackdrop, FRAMEPOINT_BOTTOMLEFT, leftInset + 0.070, 0.012)
        call BlzFrameSetText(this.categoryNextButton, ">")
        set categoryButtonFrame = null
    endmethod

    private method createItemCards takes nothing returns nothing
        call this.ensureItemCardFrames()
    endmethod

    private method ensureItemCardFrames takes nothing returns nothing
        loop
            exitwhen this.itemFrameSlotCount >= this.visibleItemSlotCount
            call this.createItemCardFrame(this.itemFrameSlotCount)
        endloop
        call this.layoutItemCardFrames()
    endmethod

    private method itemGridRows takes nothing returns integer
        local integer rows = (this.visibleItemSlotCount + 1) / 2
        if rows < 1 then
            return 1
        endif
        return rows
    endmethod

    private method itemCardHeight takes nothing returns real
        local real gridTopInset = 0.088
        local real gridBottomReserve = 0.105
        local real rowGap = 0.007
        local integer rows = this.itemGridRows()
        local real availableHeight = 0.465 - gridTopInset - gridBottomReserve
        local real height = (availableHeight - I2R(rows - 1) * rowGap) / I2R(rows)
        if height > 0.070 then
            set height = 0.070
        endif
        if height < 0.026 then
            set height = 0.026
        endif
        return height
    endmethod

    private method itemCardY takes integer row returns real
        local real gridTop = -0.088
        local real rowGap = 0.007
        local real height = this.itemCardHeight()
        local real y = gridTop
        local integer rowStep = 0
        loop
            exitwhen rowStep >= row
            set y = y - height - rowGap
            set rowStep = rowStep + 1
        endloop
        return y
    endmethod

    private method layoutItemCardFrames takes nothing returns nothing
        local RpgShopItemFrameSlot slot = this.itemFrameHead
        loop
            exitwhen slot == 0
            call this.layoutItemCardFrame(slot)
            set slot = slot.next
        endloop
    endmethod

    private method layoutItemCardFrame takes RpgShopItemFrameSlot slot returns nothing
        local real cardWidth = 0.170
        local real colGap = 0.007
        local integer col = ModuloInteger(slot.index, 2)
        local integer row = slot.index / 2
        local real x = 0.155
        local real y
        local real height
        local real iconSize
        local real textFontSize = 0.010
        if col == 1 then
            set x = x + cardWidth + colGap
        endif
        set y = this.itemCardY(row)
        set height = this.itemCardHeight()
        set iconSize = height - 0.016
        if iconSize > 0.052 then
            set iconSize = 0.052
        endif
        if iconSize < 0.018 then
            set iconSize = 0.018
        endif
        if height < 0.050 then
            set textFontSize = 0.008
        endif
        if height < 0.038 then
            set textFontSize = 0.007
        endif
        call BlzFrameClearAllPoints(slot.backdrop)
        call BlzFrameSetSize(slot.backdrop, cardWidth, height)
        call BlzFrameSetPoint(slot.backdrop, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameClearAllPoints(slot.icon)
        call BlzFrameSetSize(slot.icon, iconSize, iconSize)
        call BlzFrameSetPoint(slot.icon, FRAMEPOINT_TOPLEFT, slot.backdrop, FRAMEPOINT_TOPLEFT, 0.008, -0.008)
        call BlzFrameClearAllPoints(slot.text)
        call BlzFrameSetSize(slot.text, cardWidth - iconSize - 0.026, height - 0.010)
        call BlzFrameSetPoint(slot.text, FRAMEPOINT_TOPLEFT, slot.backdrop, FRAMEPOINT_TOPLEFT, iconSize + 0.014, -0.006)
        call BlzFrameSetFont(slot.text, this.shopFontPath, textFontSize, 0)
        call BlzFrameClearAllPoints(slot.buttonFrame)
        call BlzFrameSetSize(slot.buttonFrame, cardWidth, height)
        call BlzFrameSetPoint(slot.buttonFrame, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, x, y)
    endmethod

    private method createItemCardFrame takes integer slotIndex returns nothing
        local framehandle cardBackdrop
        local framehandle cardIcon
        local framehandle cardText
        local framehandle cardButtonFrame
        local RpgShopItemFrameSlot slot
        set cardBackdrop = BlzCreateFrameByType("BACKDROP", this.framePrefix + "ItemBackdrop" + I2S(slotIndex), this.root, "", slotIndex)
        call BlzFrameSetSize(cardBackdrop, 0.170, 0.070)
        call BlzFrameSetPoint(cardBackdrop, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, 0.155, -0.088)
        call BlzFrameSetTexture(cardBackdrop, this.tooltipTexturePath, 0, true)
        call BlzFrameSetAlpha(cardBackdrop, 235)
        call BlzFrameSetEnable(cardBackdrop, false)

        set cardIcon = BlzCreateFrameByType("BACKDROP", this.framePrefix + "ItemIcon" + I2S(slotIndex), this.root, "", slotIndex)
        call BlzFrameSetSize(cardIcon, 0.052, 0.052)
        call BlzFrameSetPoint(cardIcon, FRAMEPOINT_TOPLEFT, cardBackdrop, FRAMEPOINT_TOPLEFT, 0.008, -0.008)
        call BlzFrameSetTexture(cardIcon, "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", 0, true)
        call BlzFrameSetEnable(cardIcon, false)

        set cardText = BlzCreateFrameByType("TEXT", this.framePrefix + "ItemText" + I2S(slotIndex), this.root, "", slotIndex)
        call BlzFrameSetSize(cardText, 0.100, 0.060)
        call BlzFrameSetPoint(cardText, FRAMEPOINT_TOPLEFT, cardBackdrop, FRAMEPOINT_TOPLEFT, 0.066, -0.006)
        call BlzFrameSetFont(cardText, this.shopFontPath, 0.010, 0)
        call BlzFrameSetText(cardText, "")
        call BlzFrameSetEnable(cardText, false)

        set cardButtonFrame = BlzCreateFrame("ScriptDialogButton", this.root, 0, slotIndex)
        call BlzFrameSetSize(cardButtonFrame, 0.170, 0.070)
        call BlzFrameSetPoint(cardButtonFrame, FRAMEPOINT_TOPLEFT, this.windowBackdrop, FRAMEPOINT_TOPLEFT, 0.155, -0.088)
        call BlzFrameSetText(cardButtonFrame, "")
        call BlzFrameSetAlpha(cardButtonFrame, 0)

        set slot = RpgShopItemFrameSlot.create()
        set slot.index = slotIndex
        set slot.backdrop = cardBackdrop
        set slot.icon = cardIcon
        set slot.text = cardText
        set slot.buttonFrame = cardButtonFrame
        set slot.next = 0
        if this.itemFrameHead == 0 then
            set this.itemFrameHead = slot
        else
            set this.itemFrameTail.next = slot
        endif
        set this.itemFrameTail = slot
        set this.itemFrameSlotCount = this.itemFrameSlotCount + 1
        call thistype.registerClick(cardButtonFrame)
        set cardBackdrop = null
        set cardIcon = null
        set cardText = null
        set cardButtonFrame = null
    endmethod

    private method createDetailsPanel takes nothing returns nothing
        set this.detailsPanel = BlzCreateFrameByType("BACKDROP", this.framePrefix + "DetailsPanel", this.root, "", 0)
        call BlzFrameSetSize(this.detailsPanel, 0.182, 0.405)
        call BlzFrameSetPoint(this.detailsPanel, FRAMEPOINT_TOPRIGHT, this.root, FRAMEPOINT_TOPRIGHT, -0.018, -0.070)
        call BlzFrameSetTexture(this.detailsPanel, this.tooltipTexturePath, 0, true)
        call BlzFrameSetAlpha(this.detailsPanel, 240)
        call BlzFrameSetEnable(this.detailsPanel, false)

        set this.detailsIcon = BlzCreateFrameByType("BACKDROP", this.framePrefix + "DetailIcon", this.root, "", 0)
        call BlzFrameSetSize(this.detailsIcon, 0.086, 0.086)
        call BlzFrameSetPoint(this.detailsIcon, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, 0.0, -0.026)
        call BlzFrameSetTexture(this.detailsIcon, "ReplaceableTextures\\CommandButtons\\BTNArcaniteMelee.blp", 0, true)
        call BlzFrameSetEnable(this.detailsIcon, false)

        set this.detailsTitle = BlzCreateFrameByType("TEXT", this.framePrefix + "DetailTitle", this.root, "", 0)
        call BlzFrameSetSize(this.detailsTitle, 0.160, 0.040)
        call BlzFrameSetPoint(this.detailsTitle, FRAMEPOINT_TOPLEFT, this.detailsPanel, FRAMEPOINT_TOPLEFT, 0.012, -0.124)
        call BlzFrameSetFont(this.detailsTitle, this.shopFontPath, 0.013, 0)
        call BlzFrameSetText(this.detailsTitle, "")
        call BlzFrameSetEnable(this.detailsTitle, false)

        set this.detailsBody = BlzCreateFrameByType("TEXT", this.framePrefix + "DetailBody", this.root, "", 0)
        call BlzFrameSetSize(this.detailsBody, 0.158, 0.066)
        call BlzFrameSetPoint(this.detailsBody, FRAMEPOINT_TOPLEFT, this.detailsPanel, FRAMEPOINT_TOPLEFT, 0.012, -0.174)
        call BlzFrameSetFont(this.detailsBody, this.shopFontPath, 0.010, 0)
        call BlzFrameSetText(this.detailsBody, "")
        call BlzFrameSetEnable(this.detailsBody, false)

        set this.ownedText = BlzCreateFrameByType("TEXT", this.framePrefix + "OwnedText", this.root, "", 0)
        call BlzFrameSetSize(this.ownedText, 0.160, 0.020)
        call BlzFrameSetPoint(this.ownedText, FRAMEPOINT_TOPLEFT, this.detailsPanel, FRAMEPOINT_TOPLEFT, 0.012, -0.246)
        call BlzFrameSetFont(this.ownedText, this.shopFontPath, 0.011, 0)
        call BlzFrameSetText(this.ownedText, "|cffaaaaaaOwned: 0|r")
        call BlzFrameSetEnable(this.ownedText, false)

        set this.costText = BlzCreateFrameByType("TEXT", this.framePrefix + "CostText", this.root, "", 0)
        call BlzFrameSetSize(this.costText, 0.160, 0.020)
        call BlzFrameSetPoint(this.costText, FRAMEPOINT_TOPLEFT, this.detailsPanel, FRAMEPOINT_TOPLEFT, 0.012, -0.270)
        call BlzFrameSetFont(this.costText, this.shopFontPath, 0.012, 0)
        call BlzFrameSetText(this.costText, "")
        call BlzFrameSetEnable(this.costText, false)

        set this.minusButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.minusButton, 0.030, 0.028)
        call BlzFrameSetPoint(this.minusButton, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, -0.069, -0.296)
        call BlzFrameSetText(this.minusButton, "-")

        set this.quantityText = BlzCreateFrameByType("TEXT", this.framePrefix + "QuantityText", this.root, "", 0)
        call BlzFrameSetSize(this.quantityText, 0.045, 0.022)
        call BlzFrameSetPoint(this.quantityText, FRAMEPOINT_CENTER, this.detailsPanel, FRAMEPOINT_TOP, -0.025, -0.310)
        call BlzFrameSetFont(this.quantityText, this.shopFontPath, 0.012, 0)
        call BlzFrameSetText(this.quantityText, "1")
        call BlzFrameSetEnable(this.quantityText, false)
        call BlzFrameSetTextAlignment(this.quantityText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)

        set this.plusButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.plusButton, 0.030, 0.028)
        call BlzFrameSetPoint(this.plusButton, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, 0.019, -0.296)
        call BlzFrameSetText(this.plusButton, "+")

        set this.maxButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.maxButton, 0.043, 0.028)
        call BlzFrameSetPoint(this.maxButton, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, 0.063, -0.296)
        call BlzFrameSetText(this.maxButton, "MAX")

        set this.buyButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.buyButton, 0.158, 0.030)
        call BlzFrameSetPoint(this.buyButton, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, 0.0, -0.333)
        call BlzFrameSetText(this.buyButton, "BUY")

        set this.sellButton = BlzCreateFrame("ScriptDialogButton", this.root, 0, 0)
        call BlzFrameSetSize(this.sellButton, 0.158, 0.030)
        call BlzFrameSetPoint(this.sellButton, FRAMEPOINT_TOP, this.detailsPanel, FRAMEPOINT_TOP, 0.0, -0.368)
        call BlzFrameSetText(this.sellButton, "SELL")
    endmethod

    private method applyShopFont takes nothing returns nothing
        local RpgShopItemFrameSlot slot = this.itemFrameHead
        call BlzFrameSetFont(this.title, this.shopFontPath, 0.022, 0)
        call BlzFrameSetFont(this.goldText, this.shopFontPath, 0.014, 0)
        call BlzFrameSetFont(this.systemText, this.shopFontPath, 0.011, 0)
        call BlzFrameSetFont(this.pageText, this.shopFontPath, 0.013, 0)
        call BlzFrameSetFont(this.detailsTitle, this.shopFontPath, 0.013, 0)
        call BlzFrameSetFont(this.detailsBody, this.shopFontPath, 0.010, 0)
        call BlzFrameSetFont(this.ownedText, this.shopFontPath, 0.011, 0)
        call BlzFrameSetFont(this.costText, this.shopFontPath, 0.012, 0)
        call BlzFrameSetFont(this.quantityText, this.shopFontPath, 0.012, 0)
        loop
            exitwhen slot == 0
            call BlzFrameSetFont(slot.text, this.shopFontPath, 0.010, 0)
            set slot = slot.next
        endloop
    endmethod

    private method applyTooltipTexture takes nothing returns nothing
        local RpgShopItemFrameSlot slot = this.itemFrameHead
        call BlzFrameSetTexture(this.detailsPanel, this.tooltipTexturePath, 0, true)
        loop
            exitwhen slot == 0
            call BlzFrameSetTexture(slot.backdrop, this.tooltipTexturePath, 0, true)
            set slot = slot.next
        endloop
    endmethod

    private method bindEvents takes nothing returns nothing
        local RpgShopCategoryButtonSlot categorySlot
        call thistype.registerClick(this.closeButton)
        call thistype.registerEditbox(this.searchBox)
        call thistype.registerMouseDown(this.searchBox)
        call thistype.registerClick(this.sortButton)
        call thistype.registerClick(this.sortOrderButton)
        call thistype.registerClick(this.buyButton)
        call thistype.registerClick(this.sellButton)
        call thistype.registerClick(this.plusButton)
        call thistype.registerClick(this.minusButton)
        call thistype.registerClick(this.maxButton)
        call thistype.registerClick(this.prevButton)
        call thistype.registerClick(this.nextButton)
        call thistype.registerClick(this.categoryPrevButton)
        call thistype.registerClick(this.categoryNextButton)
        set categorySlot = this.categoryButtonHead
        loop
            exitwhen categorySlot == 0
            call thistype.registerClick(categorySlot.buttonFrame)
            set categorySlot = categorySlot.next
        endloop
    endmethod

    private method dispatchClick takes player p, framehandle clicked returns boolean
        local RpgShopItemFrameSlot itemSlot
        local RpgShopCategoryButtonSlot categorySlot
        if clicked == this.closeButton then
            call this.closeFor(p)
            return true
        elseif clicked == this.sortButton then
            call this.onSort(p)
            return true
        elseif clicked == this.sortOrderButton then
            call this.onSortOrder(p)
            return true
        elseif clicked == this.buyButton then
            call this.onBuy(p)
            return true
        elseif clicked == this.sellButton then
            call this.onSell(p)
            return true
        elseif clicked == this.plusButton then
            call this.onPlus(p)
            return true
        elseif clicked == this.minusButton then
            call this.onMinus(p)
            return true
        elseif clicked == this.maxButton then
            call this.onMax(p)
            return true
        elseif clicked == this.prevButton then
            call this.onPrevPage(p)
            return true
        elseif clicked == this.nextButton then
            call this.onNextPage(p)
            return true
        elseif clicked == this.categoryPrevButton then
            call this.onPrevCategoryPage(p)
            return true
        elseif clicked == this.categoryNextButton then
            call this.onNextCategoryPage(p)
            return true
        endif
        set itemSlot = this.itemFrameHead
        loop
            exitwhen itemSlot == 0
            if clicked == itemSlot.buttonFrame then
                call this.onItemClicked(p, itemSlot.index)
                return true
            endif
            set itemSlot = itemSlot.next
        endloop
        set categorySlot = this.categoryButtonHead
        loop
            exitwhen categorySlot == 0
            if clicked == categorySlot.buttonFrame then
                call this.onCategory(p, categorySlot.index)
                return true
            endif
            set categorySlot = categorySlot.next
        endloop
        return false
    endmethod

    private static method onFrameClick takes nothing returns nothing
        local framehandle clicked = BlzGetTriggerFrame()
        local player p = GetTriggerPlayer()
        local thistype shop = thistype.first
        loop
            exitwhen shop == 0
            if shop.dispatchClick(p, clicked) then
                call BlzFrameSetFocus(clicked, false)
                set clicked = null
                set p = null
                return
            endif
            set shop = shop.nextShop
        endloop
        set clicked = null
        set p = null
    endmethod

    private static method onEditboxChanged takes nothing returns nothing
        local framehandle changed = BlzGetTriggerFrame()
        local player p = GetTriggerPlayer()
        local thistype shop = thistype.first
        loop
            exitwhen shop == 0
            if changed == shop.searchBox then
                call shop.onSearchChanged(p)
                set changed = null
                set p = null
                return
            endif
            set shop = shop.nextShop
        endloop
        set changed = null
        set p = null
    endmethod

    private static method onMouseDown takes nothing returns nothing
        local framehandle clicked = BlzGetTriggerFrame()
        if clicked != null then
            call BlzFrameSetFocus(clicked, true)
        endif
        set clicked = null
    endmethod

    private method onSearchChanged takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        set state.searchText = BlzGetTriggerFrameText()
        set state.currentPage = 0
        set state.quantity = 1
        call this.refreshFor(p)
        call BlzFrameSetFocus(this.searchBox, true)
    endmethod

    private method onSort takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local integer keptSelection = state.selectedItem
        local integer keptPage = state.currentPage
        if not this.takeSortClick(state) then
            return
        endif
        set state.sortMode = state.sortMode + 1
        if state.sortMode > SORT_TYPE then
            set state.sortMode = SORT_RARITY
        endif
        set state.currentPage = keptPage
        call this.buildVisibleList(state)
        if keptSelection >= 0 and this.visibleContains(keptSelection) then
            set state.selectedItem = keptSelection
        endif
        call this.notify(p, "Sorted by " + this.sortLabel(state.sortMode) + " " + this.sortOrderLabel(state.sortOrder) + ".")
        call this.refreshFor(p)
    endmethod

    private method onSortOrder takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local integer keptSelection = state.selectedItem
        local integer keptPage = state.currentPage
        if not this.takeSortOrderClick(state) then
            return
        endif
        if state.sortOrder == SORT_DESCENDING then
            set state.sortOrder = SORT_ASCENDING
        else
            set state.sortOrder = SORT_DESCENDING
        endif
        set state.currentPage = keptPage
        call this.buildVisibleList(state)
        if keptSelection >= 0 and this.visibleContains(keptSelection) then
            set state.selectedItem = keptSelection
        endif
        call this.notify(p, "Sorted by " + this.sortLabel(state.sortMode) + " " + this.sortOrderLabel(state.sortOrder) + ".")
        call this.refreshFor(p)
    endmethod

    private method onCategory takes player p, integer slotIndex returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local integer categoryId = this.categoryIdForButton(state, slotIndex)
        if categoryId == ALL_CATEGORY_ID or this.validCategory(categoryId) then
            set state.selectedCategory = categoryId
            set state.currentPage = 0
            call this.refreshFor(p)
        endif
    endmethod

    private method onPrevCategoryPage takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if state.categoryPage > 0 then
            set state.categoryPage = state.categoryPage - 1
        endif
        call this.refreshFor(p)
    endmethod

    private method onNextCategoryPage takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if state.categoryPage < this.categoryPageCount() - 1 then
            set state.categoryPage = state.categoryPage + 1
        endif
        call this.refreshFor(p)
    endmethod

    private method onItemClicked takes player p, integer slotIndex returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local integer visibleIndex = state.currentPage * this.visibleItemSlotCount + slotIndex
        local RpgShopItemData clickedItem = this.visibleItemAt(visibleIndex)
        if clickedItem != 0 then
            set state.selectedItem = clickedItem.id
            set state.quantity = 1
        endif
        call this.refreshFor(p)
    endmethod

    private method onPlus takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if not this.takeQuantityClick(state) then
            return
        endif
        set state.quantity = state.quantity + 1
        if state.quantity > 99 then
            set state.quantity = 99
        endif
        call this.refreshFor(p)
    endmethod

    private method onMinus takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if not this.takeQuantityClick(state) then
            return
        endif
        set state.quantity = state.quantity - 1
        if state.quantity < 1 then
            set state.quantity = 1
        endif
        call this.refreshFor(p)
    endmethod

    private method maxQuantityFor takes player p, RpgShopPlayerState state, RpgShopItemData selected returns integer
        local integer maxAmount = this.getOwnedCount(state, selected.id)
        local integer affordable = 0
        if selected.price <= 0 then
            if maxAmount < 99 then
                set maxAmount = 99
            endif
        else
            set affordable = RpgShopGold(p) / selected.price
            if affordable > maxAmount then
                set maxAmount = affordable
            endif
        endif
        if maxAmount < 1 then
            set maxAmount = 1
        endif
        if maxAmount > 99 then
            set maxAmount = 99
        endif
        return maxAmount
    endmethod

    private method onMax takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local RpgShopItemData selected
        if not this.takeQuantityClick(state) then
            return
        endif
        set selected = this.getItemById(state.selectedItem)
        if selected == 0 then
            call this.notify(p, "No item selected.")
            call this.refreshFor(p)
            return
        endif
        set state.quantity = this.maxQuantityFor(p, state, selected)
        call this.notify(p, "Quantity set to " + I2S(state.quantity) + ".")
        call this.refreshFor(p)
    endmethod

    private method onPrevPage takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        if state.currentPage > 0 then
            set state.currentPage = state.currentPage - 1
        endif
        call this.refreshFor(p)
    endmethod

    private method onNextPage takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local integer maxPage
        call this.buildVisibleList(state)
        set maxPage = this.pageCount() - 1
        if state.currentPage < maxPage then
            set state.currentPage = state.currentPage + 1
        endif
        call this.refreshFor(p)
    endmethod

    private method onBuy takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local RpgShopItemData selected
        local integer amount
        local integer total
        if not this.takeTradeClick(state) then
            return
        endif
        set selected = this.getItemById(state.selectedItem)
        if selected == 0 then
            call this.notify(p, "No item selected.")
            return
        endif
        set amount = state.quantity
        set total = selected.price * amount
        if RpgShopGold(p) < total then
            call this.notify(p, "Not enough gold.")
            return
        endif
        if not this.addBoughtItems(p, selected, amount) then
            call this.notify(p, "Could not create this item's hidden storage handle. Check its rawcode.")
            call this.refreshGoldOnly(p)
            return
        endif
        call RpgShopSubGold(p, total)
        call this.notify(p, "Purchased " + I2S(amount) + "x " + selected.name + ".")
        call this.refreshFor(p)
    endmethod

    private method onSell takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local RpgShopItemData selected
        local integer owned
        local integer sold
        local integer gain
        if not this.takeTradeClick(state) then
            return
        endif
        set selected = this.getItemById(state.selectedItem)
        if selected == 0 then
            call this.notify(p, "No item selected.")
            return
        endif
        set owned = this.getOwnedCount(state, selected.id)
        if owned <= 0 then
            call this.notify(p, "You have not bought that item.")
            return
        endif
        set sold = state.quantity
        if sold > owned then
            set sold = owned
        endif
        call this.removeBoughtItems(state, selected.id, sold)
        set gain = (selected.price / 2) * sold
        call RpgShopAddGold(p, gain)
        call this.notify(p, "Sold " + I2S(sold) + "x " + selected.name + " for " + I2S(gain) + " gold.")
        call this.refreshFor(p)
    endmethod

    private method refreshFor takes player p returns nothing
        local RpgShopPlayerState state = this.getState(p)
        local RpgShopItemData firstVisible
        call this.buildVisibleList(state)
        if state.selectedItem >= 0 and this.getItemById(state.selectedItem) == 0 then
            set state.selectedItem = -1
        endif
        if state.selectedItem < 0 and this.sortedCount > 0 then
            set firstVisible = this.visibleItemAt(state.currentPage * this.visibleItemSlotCount)
            if firstVisible != 0 then
                set state.selectedItem = firstVisible.id
            endif
        endif
        call this.renderStaticState(p, state)
        call this.renderCards(p, state)
        call this.renderDetails(p, state)
    endmethod

    private method refreshOpenPlayers takes nothing returns nothing
        local RpgShopPlayerState state = this.playerHead
        loop
            exitwhen state == 0
            if state.isOpen then
                call this.refreshFor(state.owner)
            endif
            set state = state.next
        endloop
    endmethod

    private static method onGoldPoll takes nothing returns nothing
        local thistype shop = thistype.first
        loop
            exitwhen shop == 0
            call shop.refreshGoldForOpenPlayers()
            set shop = shop.nextShop
        endloop
    endmethod

    private method refreshGoldForOpenPlayers takes nothing returns nothing
        local RpgShopPlayerState state = this.playerHead
        loop
            exitwhen state == 0
            if state.isOpen then
                call this.refreshGoldOnly(state.owner)
            endif
            set state = state.next
        endloop
    endmethod

    private method refreshGoldOnly takes player p returns nothing
        call RpgShopFrameTextFor(p, this.goldText, "|cffffcc66Gold:|r " + I2S(RpgShopGold(p)))
    endmethod

    private method takeQuantityClick takes RpgShopPlayerState state returns boolean
        local real now = thistype.timerNow()
        if now - state.lastQuantityClick < 0.22 then
            return false
        endif
        set state.lastQuantityClick = now
        return true
    endmethod

    private method takeTradeClick takes RpgShopPlayerState state returns boolean
        local real now = thistype.timerNow()
        if now - state.lastTradeClick < 0.35 then
            return false
        endif
        set state.lastTradeClick = now
        return true
    endmethod

    private method takeSortClick takes RpgShopPlayerState state returns boolean
        local real now = thistype.timerNow()
        if now - state.lastSortClick < 0.18 then
            return false
        endif
        set state.lastSortClick = now
        return true
    endmethod

    private method takeSortOrderClick takes RpgShopPlayerState state returns boolean
        local real now = thistype.timerNow()
        if now - state.lastSortOrderClick < 0.18 then
            return false
        endif
        set state.lastSortOrderClick = now
        return true
    endmethod

    private method findOwnedEntry takes RpgShopPlayerState state, integer itemId returns RpgShopOwnedEntry
        local RpgShopOwnedEntry entry = state.ownedHead
        loop
            exitwhen entry == 0
            if entry.itemId == itemId then
                return entry
            endif
            set entry = entry.next
        endloop
        return 0
    endmethod

    private method getOwnedEntry takes RpgShopPlayerState state, integer itemId, boolean createMissing returns RpgShopOwnedEntry
        local RpgShopOwnedEntry existingEntry = this.findOwnedEntry(state, itemId)
        local RpgShopOwnedEntry newEntry
        if existingEntry != 0 or not createMissing then
            return existingEntry
        endif
        set newEntry = RpgShopOwnedEntry.create()
        set newEntry.itemId = itemId
        set newEntry.count = 0
        set newEntry.hiddenItem = null
        set newEntry.next = 0
        if state.ownedHead == 0 then
            set state.ownedHead = newEntry
        else
            set state.ownedTail.next = newEntry
        endif
        set state.ownedTail = newEntry
        return newEntry
    endmethod

    private method getOwnedCount takes RpgShopPlayerState state, integer itemId returns integer
        local RpgShopOwnedEntry entry = this.findOwnedEntry(state, itemId)
        if entry == 0 then
            return 0
        endif
        return entry.count
    endmethod

    private method hiddenStorageX takes integer pid returns real
        if pid < 6 or (pid >= 12 and pid < 18) then
            return RpgShopBoundMinX + 64.0
        endif
        return RpgShopBoundMaxX - 64.0
    endmethod

    private method hiddenStorageY takes integer pid returns real
        if pid < 12 then
            return RpgShopBoundMinY + 64.0
        endif
        return RpgShopBoundMaxY - 64.0
    endmethod

    private method ensureBoughtItemHandle takes player p, RpgShopPlayerState state, RpgShopItemData selected returns boolean
        local RpgShopOwnedEntry entry
        local item hiddenItem
        local real x
        local real y
        if selected.rawId == 0 then
            return true
        endif
        set entry = this.getOwnedEntry(state, selected.id, true)
        set x = this.hiddenStorageX(state.pid)
        set y = this.hiddenStorageY(state.pid)
        if entry.hiddenItem == null then
            set hiddenItem = CreateItem(selected.rawId, x, y)
            if hiddenItem == null then
                return false
            endif
            call SetItemPlayer(hiddenItem, p, false)
            call SetItemDropOnDeath(hiddenItem, false)
            call SetItemDroppable(hiddenItem, false)
            call SetItemPawnable(hiddenItem, false)
            call SetItemInvulnerable(hiddenItem, true)
            call SetItemVisible(hiddenItem, false)
            set entry.hiddenItem = hiddenItem
        else
            call SetItemPosition(entry.hiddenItem, x, y)
            call SetItemVisible(entry.hiddenItem, false)
        endif
        set hiddenItem = null
        return true
    endmethod

    private method updateBoughtItemHandle takes RpgShopPlayerState state, integer itemId returns nothing
        local RpgShopOwnedEntry entry = this.findOwnedEntry(state, itemId)
        local item hiddenItem
        if entry == 0 then
            return
        endif
        set hiddenItem = entry.hiddenItem
        if hiddenItem == null then
            return
        endif
        if entry.count <= 0 then
            call RemoveItem(hiddenItem)
            set entry.hiddenItem = null
        else
            call SetItemCharges(hiddenItem, entry.count)
            call SetItemPosition(hiddenItem, this.hiddenStorageX(state.pid), this.hiddenStorageY(state.pid))
            call SetItemVisible(hiddenItem, false)
        endif
        set hiddenItem = null
    endmethod

    private method addBoughtItems takes player p, RpgShopItemData selected, integer amount returns boolean
        local RpgShopPlayerState state = this.getState(p)
        local RpgShopOwnedEntry entry
        if not this.ensureBoughtItemHandle(p, state, selected) then
            return false
        endif
        set entry = this.getOwnedEntry(state, selected.id, true)
        set entry.count = entry.count + amount
        call this.updateBoughtItemHandle(state, selected.id)
        return true
    endmethod

    private method removeBoughtItems takes RpgShopPlayerState state, integer itemId, integer amount returns nothing
        local RpgShopOwnedEntry entry = this.findOwnedEntry(state, itemId)
        if entry == 0 then
            return
        endif
        set entry.count = entry.count - amount
        if entry.count < 0 then
            set entry.count = 0
        endif
        call this.updateBoughtItemHandle(state, itemId)
    endmethod

    private method renderStaticState takes player p, RpgShopPlayerState state returns nothing
        local RpgShopCategoryButtonSlot slot
        local integer categoryId
        call RpgShopFrameShowEnableFor(p, this.searchBox, true)
        call this.refreshGoldOnly(p)
        call RpgShopFrameTextFor(p, this.sortButton, "Sort: " + this.sortLabel(state.sortMode))
        call RpgShopFrameTextFor(p, this.sortOrderButton, this.sortOrderShortLabel(state.sortOrder))
        call RpgShopFrameTextFor(p, this.pageText, I2S(state.currentPage + 1) + " / " + I2S(this.pageCount()))
        call RpgShopFrameTextFor(p, this.quantityText, I2S(state.quantity))
        call RpgShopFrameTextFor(p, this.systemText, state.systemMessage)
        call this.clampCategoryPage(state)
        set slot = this.categoryButtonHead
        loop
            exitwhen slot == 0
            if this.categoryButtonIsVisible(state, slot.index) then
                call RpgShopFrameShowEnableFor(p, slot.buttonFrame, true)
                set categoryId = this.categoryIdForButton(state, slot.index)
                if state.selectedCategory == categoryId then
                    call RpgShopFrameTextFor(p, slot.buttonFrame, "|cffffcc66> " + this.categoryButtonLabel(state, slot.index) + "|r")
                else
                    call RpgShopFrameTextFor(p, slot.buttonFrame, this.categoryButtonLabel(state, slot.index))
                endif
            else
                call RpgShopFrameShowEnableFor(p, slot.buttonFrame, false)
            endif
            set slot = slot.next
        endloop
        if this.categoryCount() > this.categoryPageSize() then
            call RpgShopFrameShowEnableFor(p, this.categoryPrevButton, true)
            call RpgShopFrameShowEnableFor(p, this.categoryNextButton, true)
        else
            call RpgShopFrameShowEnableFor(p, this.categoryPrevButton, false)
            call RpgShopFrameShowEnableFor(p, this.categoryNextButton, false)
        endif
    endmethod

    private method renderCards takes player p, RpgShopPlayerState state returns nothing
        local RpgShopItemFrameSlot slot = this.itemFrameHead
        local integer visibleIndex
        local RpgShopItemData selected
        loop
            exitwhen slot == 0
            if slot.index < this.visibleItemSlotCount then
                set visibleIndex = state.currentPage * this.visibleItemSlotCount + slot.index
                set selected = this.visibleItemAt(visibleIndex)
                if selected != 0 then
                    call RpgShopFrameShowFor(p, slot.backdrop, true)
                    call RpgShopFrameShowEnableFor(p, slot.buttonFrame, true)
                    call RpgShopFrameShowFor(p, slot.icon, true)
                    call RpgShopFrameShowFor(p, slot.text, true)
                    call RpgShopFrameTextureFor(p, slot.icon, selected.icon)
                    call RpgShopFrameTextFor(p, slot.text, this.rarityColor(selected.rarityId) + selected.name + "|r|n" + this.rarityLabel(selected.rarityId) + "|n" + this.statLine(selected) + "|n|cffffcc66" + I2S(selected.price) + "g|r")
                else
                    call RpgShopFrameShowFor(p, slot.backdrop, false)
                    call RpgShopFrameShowEnableFor(p, slot.buttonFrame, false)
                    call RpgShopFrameShowFor(p, slot.icon, false)
                    call RpgShopFrameShowFor(p, slot.text, false)
                endif
            else
                call RpgShopFrameShowFor(p, slot.backdrop, false)
                call RpgShopFrameShowEnableFor(p, slot.buttonFrame, false)
                call RpgShopFrameShowFor(p, slot.icon, false)
                call RpgShopFrameShowFor(p, slot.text, false)
            endif
            set slot = slot.next
        endloop
    endmethod

    private method renderDetails takes player p, RpgShopPlayerState state returns nothing
        local RpgShopItemData selected = this.getItemById(state.selectedItem)
        if selected == 0 then
            call RpgShopFrameShowFor(p, this.detailsIcon, false)
            call RpgShopFrameTextFor(p, this.detailsTitle, "No items found")
            call RpgShopFrameTextFor(p, this.detailsBody, "Try another search or category.")
            call RpgShopFrameTextFor(p, this.ownedText, "")
            call RpgShopFrameTextFor(p, this.costText, "")
            call RpgShopFrameTextFor(p, this.quantityText, "1")
            return
        endif
        call RpgShopFrameShowFor(p, this.detailsIcon, true)
        call RpgShopFrameTextureFor(p, this.detailsIcon, selected.icon)
        call RpgShopFrameTextFor(p, this.detailsTitle, this.rarityColor(selected.rarityId) + selected.name + "|r|n" + this.rarityLabel(selected.rarityId))
        call RpgShopFrameTextFor(p, this.detailsBody, this.statLine(selected) + "|n|n" + selected.desc)
        call RpgShopFrameTextFor(p, this.ownedText, "|cffaaaaaaOwned:|r " + I2S(this.getOwnedCount(state, selected.id)))
        call RpgShopFrameTextFor(p, this.costText, "|cffffcc66Cost:|r " + I2S(selected.price * state.quantity) + " gold")
        call RpgShopFrameTextFor(p, this.quantityText, I2S(state.quantity))
    endmethod

    private method clearVisibleLists takes nothing returns nothing
        local RpgShopItemNode node = this.visibleHead
        local RpgShopItemNode nextNode
        loop
            exitwhen node == 0
            set nextNode = node.next
            call node.destroy()
            set node = nextNode
        endloop
        set node = this.sortedHead
        loop
            exitwhen node == 0
            set nextNode = node.next
            call node.destroy()
            set node = nextNode
        endloop
        set this.visibleHead = 0
        set this.visibleTail = 0
        set this.sortedHead = 0
        set this.sortedTail = 0
        set this.visibleCount = 0
        set this.sortedCount = 0
    endmethod

    private method addVisibleNode takes RpgShopItemData data returns nothing
        local RpgShopItemNode node = RpgShopItemNode.create()
        set node.data = data
        set node.next = 0
        if this.visibleHead == 0 then
            set this.visibleHead = node
        else
            set this.visibleTail.next = node
        endif
        set this.visibleTail = node
        set this.visibleCount = this.visibleCount + 1
    endmethod

    private method addSortedNode takes RpgShopItemData data returns nothing
        local RpgShopItemNode node = RpgShopItemNode.create()
        set node.data = data
        set node.next = 0
        if this.sortedHead == 0 then
            set this.sortedHead = node
        else
            set this.sortedTail.next = node
        endif
        set this.sortedTail = node
        set this.sortedCount = this.sortedCount + 1
    endmethod

    private method buildVisibleList takes RpgShopPlayerState state returns nothing
        local RpgShopItemData selected
        local RpgShopItemData nextItem
        local integer maxPage
        call this.clearVisibleLists()
        set selected = this.itemHead
        loop
            exitwhen selected == 0
            if this.itemMatches(state, selected) then
                call this.addVisibleNode(selected)
            endif
            set selected = selected.next
        endloop
        loop
            exitwhen this.sortedCount >= this.visibleCount
            set nextItem = this.bestRemainingVisibleItem(state)
            exitwhen nextItem == 0
            call this.addSortedNode(nextItem)
        endloop
        set maxPage = this.pageCount() - 1
        if state.currentPage > maxPage then
            set state.currentPage = maxPage
        endif
        if state.currentPage < 0 then
            set state.currentPage = 0
        endif
    endmethod

    private method bestRemainingVisibleItem takes RpgShopPlayerState state returns RpgShopItemData
        local RpgShopItemNode node = this.visibleHead
        local RpgShopItemData best = 0
        loop
            exitwhen node == 0
            if not this.sortedContains(node.data.id) then
                if best == 0 or this.itemGreater(state, node.data, best) then
                    set best = node.data
                endif
            endif
            set node = node.next
        endloop
        return best
    endmethod

    private method itemMatches takes RpgShopPlayerState state, RpgShopItemData selected returns boolean
        if state.selectedCategory != ALL_CATEGORY_ID and selected.categoryId != state.selectedCategory then
            return false
        endif
        if state.searchText != "" then
            if this.containsIgnoreCase(selected.name, state.searchText) then
                return true
            endif
            if this.containsIgnoreCase(this.categoryLabel(selected.categoryId), state.searchText) then
                return true
            endif
            if this.containsIgnoreCase(this.rarityLabel(selected.rarityId), state.searchText) then
                return true
            endif
            return false
        endif
        return true
    endmethod

    private method sortedContains takes integer itemId returns boolean
        local RpgShopItemNode node = this.sortedHead
        loop
            exitwhen node == 0
            if node.data.id == itemId then
                return true
            endif
            set node = node.next
        endloop
        return false
    endmethod

    private method visibleContains takes integer itemId returns boolean
        local RpgShopItemNode node = this.sortedHead
        loop
            exitwhen node == 0
            if node.data.id == itemId then
                return true
            endif
            set node = node.next
        endloop
        return false
    endmethod

    private method visibleItemAt takes integer index returns RpgShopItemData
        local integer currentIndex = 0
        local RpgShopItemNode node = this.sortedHead
        if index < 0 then
            return 0
        endif
        loop
            exitwhen node == 0
            if currentIndex == index then
                return node.data
            endif
            set currentIndex = currentIndex + 1
            set node = node.next
        endloop
        return 0
    endmethod

    private method itemGreater takes RpgShopPlayerState state, RpgShopItemData a, RpgShopItemData b returns boolean
        local boolean ascending = state.sortOrder == SORT_ASCENDING
        local boolean aBefore
        local boolean bBefore
        if state.sortMode == SORT_PRICE then
            if a.price != b.price then
                if ascending then
                    return a.price < b.price
                endif
                return a.price > b.price
            endif
            return this.nameComesBefore(a.name, b.name)
        endif
        if state.sortMode == SORT_NAME then
            set aBefore = this.nameComesBefore(a.name, b.name)
            set bBefore = this.nameComesBefore(b.name, a.name)
            if aBefore or bBefore then
                if ascending then
                    return aBefore
                endif
                return bBefore
            endif
            if a.price != b.price then
                return a.price > b.price
            endif
            return a.rarityId > b.rarityId
        endif
        if state.sortMode == SORT_TYPE then
            if a.categoryId != b.categoryId then
                if ascending then
                    return a.categoryId < b.categoryId
                endif
                return a.categoryId > b.categoryId
            endif
            if a.rarityId != b.rarityId then
                return a.rarityId > b.rarityId
            endif
            if a.price != b.price then
                return a.price > b.price
            endif
            return this.nameComesBefore(a.name, b.name)
        endif
        if a.rarityId != b.rarityId then
            if ascending then
                return a.rarityId < b.rarityId
            endif
            return a.rarityId > b.rarityId
        endif
        if a.price != b.price then
            return a.price > b.price
        endif
        return this.nameComesBefore(a.name, b.name)
    endmethod

    private method pageCount takes nothing returns integer
        if this.sortedCount <= 0 then
            return 1
        endif
        return ((this.sortedCount - 1) / this.visibleItemSlotCount) + 1
    endmethod

    private method categoryCount takes nothing returns integer
        local integer count = 0
        local RpgShopCategoryData category = this.categoryHead
        loop
            exitwhen category == 0
            set count = count + 1
            set category = category.next
        endloop
        return count
    endmethod

    private method categoryButtonCount takes nothing returns integer
        return this.categoryButtonSlotCount
    endmethod

    private method categoryPageSize takes nothing returns integer
        local integer size = this.categoryButtonCount() - 1
        if size < 1 then
            return 1
        endif
        return size
    endmethod

    private method categoryPageCount takes nothing returns integer
        if this.categoryCount() <= 0 then
            return 1
        endif
        return ((this.categoryCount() - 1) / this.categoryPageSize()) + 1
    endmethod

    private method clampCategoryPage takes RpgShopPlayerState state returns nothing
        local integer maxPage = this.categoryPageCount() - 1
        if state.categoryPage > maxPage then
            set state.categoryPage = maxPage
        endif
        if state.categoryPage < 0 then
            set state.categoryPage = 0
        endif
    endmethod

    private method categoryIdForButton takes RpgShopPlayerState state, integer slotIndex returns integer
        if slotIndex == 0 then
            return ALL_CATEGORY_ID
        endif
        return state.categoryPage * this.categoryPageSize() + slotIndex - 1
    endmethod

    private method categoryButtonIsVisible takes RpgShopPlayerState state, integer slotIndex returns boolean
        if slotIndex == 0 then
            return true
        endif
        return this.getCategoryById(this.categoryIdForButton(state, slotIndex)) != 0
    endmethod

    private method categoryButtonLabel takes RpgShopPlayerState state, integer slotIndex returns string
        if slotIndex == 0 then
            return "All Items"
        endif
        return this.categoryLabel(this.categoryIdForButton(state, slotIndex))
    endmethod

    private method getItemById takes integer itemId returns RpgShopItemData
        local RpgShopItemData selected = this.itemHead
        loop
            exitwhen selected == 0
            if selected.id == itemId then
                return selected
            endif
            set selected = selected.next
        endloop
        return 0
    endmethod

    private method getCategoryById takes integer categoryId returns RpgShopCategoryData
        local RpgShopCategoryData category = this.categoryHead
        loop
            exitwhen category == 0
            if category.id == categoryId then
                return category
            endif
            set category = category.next
        endloop
        return 0
    endmethod

    private method getRarityById takes integer rarityId returns RpgShopRarityData
        local RpgShopRarityData rarity = this.rarityHead
        loop
            exitwhen rarity == 0
            if rarity.id == rarityId then
                return rarity
            endif
            set rarity = rarity.next
        endloop
        return 0
    endmethod

    private method validCategory takes integer categoryId returns boolean
        return this.getCategoryById(categoryId) != 0
    endmethod

    private method validRarity takes integer rarityId returns boolean
        return this.getRarityById(rarityId) != 0
    endmethod

    private method categoryLabel takes integer categoryId returns string
        local RpgShopCategoryData category = this.getCategoryById(categoryId)
        if category != 0 then
            return category.label
        endif
        return "Unknown"
    endmethod

    private method rarityLabel takes integer rarityId returns string
        local RpgShopRarityData rarity = this.getRarityById(rarityId)
        if rarity != 0 then
            return rarity.label
        endif
        return "UNKNOWN"
    endmethod

    private method rarityColor takes integer rarityId returns string
        local RpgShopRarityData rarity = this.getRarityById(rarityId)
        if rarity != 0 and rarity.colorPrefix != "" then
            return rarity.colorPrefix
        endif
        return "|cffffffff"
    endmethod

    private method sortLabel takes integer mode returns string
        if mode == SORT_PRICE then
            return "Price"
        endif
        if mode == SORT_NAME then
            return "Name"
        endif
        if mode == SORT_TYPE then
            return "Type"
        endif
        return "Rarity"
    endmethod

    private method sortOrderLabel takes integer order returns string
        if order == SORT_ASCENDING then
            return "Ascending"
        endif
        return "Descending"
    endmethod

    private method sortOrderShortLabel takes integer order returns string
        if order == SORT_ASCENDING then
            return "Asc"
        endif
        return "Desc"
    endmethod

    private method statLine takes RpgShopItemData selected returns string
        if selected.attack > 0 then
            return I2S(selected.attack) + " Attack"
        endif
        if selected.defense > 0 then
            return I2S(selected.defense) + " Defense"
        endif
        return "Utility Item"
    endmethod

    private method containsIgnoreCase takes string text, string needle returns boolean
        local string hay = StringCase(text, false)
        local string ndl = StringCase(needle, false)
        local integer hayLen = StringLength(hay)
        local integer ndlLen = StringLength(ndl)
        local integer pos = 0
        if ndlLen <= 0 then
            return true
        endif
        if ndlLen > hayLen then
            return false
        endif
        loop
            exitwhen pos > hayLen - ndlLen
            if SubString(hay, pos, pos + ndlLen) == ndl then
                return true
            endif
            set pos = pos + 1
        endloop
        return false
    endmethod

    private method notify takes player p, string message returns nothing
        local RpgShopPlayerState state = this.getState(p)
        set state.systemMessage = "|cffffcc66" + message + "|r"
        call RpgShopFrameTextFor(p, this.systemText, state.systemMessage)
    endmethod

    private method charRank takes string c returns integer
        local string lower = StringCase(c, false)
        if lower == "0" then
            return 1
        elseif lower == "1" then
            return 2
        elseif lower == "2" then
            return 3
        elseif lower == "3" then
            return 4
        elseif lower == "4" then
            return 5
        elseif lower == "5" then
            return 6
        elseif lower == "6" then
            return 7
        elseif lower == "7" then
            return 8
        elseif lower == "8" then
            return 9
        elseif lower == "9" then
            return 10
        elseif lower == "a" then
            return 11
        elseif lower == "b" then
            return 12
        elseif lower == "c" then
            return 13
        elseif lower == "d" then
            return 14
        elseif lower == "e" then
            return 15
        elseif lower == "f" then
            return 16
        elseif lower == "g" then
            return 17
        elseif lower == "h" then
            return 18
        elseif lower == "i" then
            return 19
        elseif lower == "j" then
            return 20
        elseif lower == "k" then
            return 21
        elseif lower == "l" then
            return 22
        elseif lower == "m" then
            return 23
        elseif lower == "n" then
            return 24
        elseif lower == "o" then
            return 25
        elseif lower == "p" then
            return 26
        elseif lower == "q" then
            return 27
        elseif lower == "r" then
            return 28
        elseif lower == "s" then
            return 29
        elseif lower == "t" then
            return 30
        elseif lower == "u" then
            return 31
        elseif lower == "v" then
            return 32
        elseif lower == "w" then
            return 33
        elseif lower == "x" then
            return 34
        elseif lower == "y" then
            return 35
        elseif lower == "z" then
            return 36
        endif
        return 0
    endmethod

    private method nameComesBefore takes string a, string b returns boolean
        local string lowerA = StringCase(a, false)
        local string lowerB = StringCase(b, false)
        local integer lenA = StringLength(lowerA)
        local integer lenB = StringLength(lowerB)
        local integer pos = 0
        local integer rankA
        local integer rankB
        loop
            exitwhen pos >= lenA or pos >= lenB
            set rankA = this.charRank(SubString(lowerA, pos, pos + 1))
            set rankB = this.charRank(SubString(lowerB, pos, pos + 1))
            if rankA < rankB then
                return true
            endif
            if rankA > rankB then
                return false
            endif
            set pos = pos + 1
        endloop
        return lenA < lenB
    endmethod
    private static method onInit takes nothing returns nothing
        local rect bounds = GetWorldBounds()
        set RpgShopBoundMinX = GetRectMinX(bounds)
        set RpgShopBoundMinY = GetRectMinY(bounds)
        set RpgShopBoundMaxX = GetRectMaxX(bounds)
        set RpgShopBoundMaxY = GetRectMaxY(bounds)
        call BlzLoadTOCFile("war3mapImported\\RpgMerchantShop.toc")
        set bounds = null
        call TimerStart(RpgShopClock, 1000000.0, false, null)
        call TimerStart(CreateTimer(), 0.25, true, function thistype.onGoldPoll)
    endmethod
endstruct

endlibrary
