
library TasInventoryEx initializer init_function requires optional Table
    /*  TasInventoryEx 1.5
        by Tasyen
        
        Uses the multiple InventorySkills on an unit to allow an unit to benefit from more than 6 items.
        Displays the items in additional Inventories in a customUI and allows to move Items from into the main inventory
    
        Destroys & Recreates Items drop/Moved between inventories
    
        Affected by HeroScoreFrame-Options, if found in the same map
    
        Requires: 
            (optional) Table by Bribe https://www.hiveworkshop.com/threads/snippet-new-table.188084/
            war3mapImported\TasInventoryEx.fdf
            war3mapImported\TasInventoryEx.toc
    
     */
    
     // Mode without Table
    private struct data extends array
        static if LIBRARY_Table then
            public static HashTable BagItem
        else
            public static hashtable Hash
        endif
    endstruct
    
    globals
        private real PosX = 0.4
        private real PosY = 0.19
        private framepointtype Pos = FRAMEPOINT_TOP
        private integer Cols = 9
        private integer Rows = 1
    
        private real ShowButtonPosX = 0.48
        private real ShowButtonPosY = 0.145
        private framepointtype ShowButtonPos = FRAMEPOINT_TOPLEFT
        private string ShowButtonTexture = "ReplaceableTextures/CommandButtons/BTNDustOfAppearance"
        private string ShowButtonTextureDisabled = "ReplaceableTextures/CommandButtonsDisabled/DISBTNDustOfAppearance"
        // show the showButton only when the inventory is shown?
        public boolean ShowButtonNeedsInventory = true

        // showButton closes the UI when clicked while the UI is shown?
        public boolean ShowButtonCloses = true
    
        private real TooltipWidth = 0.27
        public real TooltipScale = 1.0
        public boolean TooltipFixedPosition = true
        private real TooltipFixedPositionX = 0.79
        private real TooltipFixedPositionY = 0.16
        private framepointtype TooltipFixedPositionPoint = FRAMEPOINT_BOTTOMRIGHT    
    
        // The Inventory Abilities used by this system, the first in the array needs to be the default Inventory
        public integer array InventorySkills 
        private abilityintegerlevelfield AbilityField
        public timer TimerUpdate
        public trigger Trigger
        public trigger TriggerESC
        public trigger TriggerItemGain
        public trigger TriggerItemDrop
        public trigger TriggerUnitRevived
    
        public trigger TriggerLife
        public trigger TriggerReInkarnationDone
        
        public trigger TriggerUIOpen
        public trigger TriggerUIClose
        public trigger TriggerUIBagButton
        public trigger TriggerUISlider
        public trigger TriggerUIWheel
        
        public group WaitingGroup
    
        public integer array Offset
        public unit array Selected
        public item array ItemBackup
            
    endglobals
    
    // function ValidUnit filters out units that should not Use TasInventoryEx
    // Change it to your will
    private function ValidUnit takes unit u returns boolean
        // Units with the Locust skill do not use this System
        if GetUnitAbilityLevel(u, 'Aloc') > 0 then 
            return false
        endif
    
        // The extra Players don't use this
        if GetPlayerId(GetOwningPlayer(u)) >= bj_MAX_PLAYERS then
            return false
        endif
    
        if not IsUnitType(u, UNIT_TYPE_HERO) then 
            return false
        endif
        
        return true
    endfunction
    
    private function UserInit takes nothing returns nothing
        set InventorySkills[0] = 'A03H'
        set InventorySkills[1] = 'A03I'
        set InventorySkills[2] = 'A03J'
    //    set InventorySkills[1] = 'Apak'
    //    set InventorySkills[2] = 'Aiun'
        //set InventorySkills[3] = 'Aien'
    //    set InventorySkills[4] = 'Aihn'
        //set InventorySkills[5] = 'Aion'
    endfunction
    
    public function AddItem takes unit u, item i returns nothing
        local integer unitHandle = GetHandleId(u)
    static if LIBRARY_Table then    
        set data.BagItem[unitHandle].integer[0] = data.BagItem[unitHandle].integer[0] + 1
        set data.BagItem[unitHandle].item[data.BagItem[unitHandle].integer[0]] = i
    else
        call SaveInteger(data.Hash, unitHandle, 0, LoadInteger(data.Hash, unitHandle,0) + 1)
        call SaveItemHandle(data.Hash, unitHandle, LoadInteger(data.Hash, unitHandle,0), i)
    endif
    endfunction
    
    
    public function RemoveIndex takes unit u, integer index returns item
        local item i
        local integer unitHandle = GetHandleId(u)
    static if LIBRARY_Table then    
      
        if data.BagItem[unitHandle].integer[0] <= 0 then
            return null
        endif
        
        set i = data.BagItem[unitHandle].item[index]
        set data.BagItem[unitHandle].item[index] = data.BagItem[unitHandle].item[data.BagItem[unitHandle].integer[0]]
        set data.BagItem[unitHandle].item[data.BagItem[unitHandle].integer[0]] = null
        set data.BagItem[unitHandle].integer[0] = data.BagItem[unitHandle].integer[0] - 1
    else
        if LoadInteger(data.Hash, unitHandle,0) <= 0 then
            return null
        endif
    
        set i = LoadItemHandle(data.Hash, unitHandle, index)
        call SaveItemHandle(data.Hash, unitHandle, index, LoadItemHandle(data.Hash, unitHandle, LoadInteger(data.Hash, unitHandle,0)))
        call RemoveSavedHandle(data.Hash, unitHandle, LoadInteger(data.Hash, unitHandle,0))
        call SaveInteger(data.Hash, unitHandle, 0, LoadInteger(data.Hash, unitHandle,0) - 1)
    endif
        set bj_itemRandomCurrentPick = i
        set i = null
        return bj_itemRandomCurrentPick
    endfunction
    
    private function CopyItemData takes item source, item target returns nothing
        call SetItemCharges(target, GetItemCharges(source))
        call SetItemInvulnerable(target, IsItemInvulnerable(source))
        call SetItemUserData(target, GetItemUserData(source))
        call SetItemPlayer(target, GetItemPlayer(source), true)
        call SetWidgetLife(target, GetWidgetLife(source))
    endfunction
    
    private function FrameLoseFocus takes nothing returns nothing
        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        endif
    endfunction
    
    private function BagButtonAction takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pId = GetPlayerId(GetTriggerPlayer())
        local integer bagIndex = S2I(BlzFrameGetText(BlzGetTriggerFrame())) + Offset[pId]
        local unit u =  Selected[pId]
        local item i 
        local item newItem 
        local ability abi
        if GetPlayerAlliance(GetOwningPlayer(u), p, ALLIANCE_SHARED_CONTROL) then
            set i = RemoveIndex(u, bagIndex)
            set newItem = CreateItem(GetItemTypeId(i), GetUnitX(u), GetUnitY(u))
    
            call CopyItemData(i, newItem)        
            call RemoveItem(i)
    
            set abi = BlzGetUnitAbility(u, InventorySkills[1])
            call BlzSetAbilityIntegerLevelField(abi, AbilityField, 0, 0)
            
            call UnitAddItem(u, newItem)
            call BlzSetAbilityIntegerLevelField(abi, AbilityField, 0, 6)
        endif
        set u = null
        set i = null
        set newItem = null
        set abi = null
        call FrameLoseFocus()
    endfunction
    private function WheelAction takes nothing returns nothing
        local boolean upwards = BlzGetTriggerFrameValue() > 0
        if GetLocalPlayer() == GetTriggerPlayer() then
            if upwards then 
                call BlzFrameSetValue(BlzGetFrameByName("TasInventoryExSlider", 0), BlzFrameGetValue(BlzGetFrameByName("TasInventoryExSlider", 0)) + 1)
            else
                call BlzFrameSetValue(BlzGetFrameByName("TasInventoryExSlider", 0), BlzFrameGetValue(BlzGetFrameByName("TasInventoryExSlider", 0)) - 1)
            endif
        endif
    endfunction
    private function CloseButtonAction takes nothing returns nothing
        local integer pId = GetPlayerId(GetTriggerPlayer())
    
        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPanel", 0), false)
            call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPopUpPanel", 0), false)
        endif
        call FrameLoseFocus()
    endfunction
    private function ShowButtonAction takes nothing returns nothing
        local integer pId = GetPlayerId(GetTriggerPlayer())
        if GetLocalPlayer() == GetTriggerPlayer() then
            if ShowButtonCloses and BlzFrameIsVisible(BlzGetFrameByName("TasInventoryExPanel", 0)) then
                call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPanel", 0), false)
                call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPopUpPanel", 0), false)
            else
                call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPanel", 0), true)
                call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPopUpPanel", 0), false)
            endif
            
        endif
        call FrameLoseFocus()
    endfunction
    private function SliderAction takes nothing returns nothing
        set Offset[GetPlayerId(GetTriggerPlayer())] = R2I(BlzGetTriggerFrameValue()*Cols)
    endfunction
    
    private function SelectAction takes nothing returns nothing
        local integer pId = GetPlayerId(GetTriggerPlayer())
        set Selected[pId] = GetTriggerUnit()
        set Offset[pId] = 0
    endfunction
    private function ESCAction takes nothing returns nothing
        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPanel", 0), false)
        endif
    endfunction
    
    private function ItemGainAction takes nothing returns nothing
        local integer loopA
    
        local unit u
        local item i
        local integer unitHandle
        // powerups, destroyed item don't matter
        if IsItemPowerup(GetManipulatedItem()) or GetItemTypeId(GetManipulatedItem()) <= 0 or GetWidgetLife(GetManipulatedItem()) <= 0 then 
            return
        endif
        // dummies do not use the bag feature
        if not ValidUnit(GetTriggerUnit()) then
            return
        endif
    
        set u = GetTriggerUnit()
        set unitHandle = GetHandleId(u)
        set i = GetManipulatedItem()
    
        if GetUnitAbilityLevel(u, InventorySkills[1]) == 0  then
            // remember items already owned before getting TasInventory
            set loopA = bj_MAX_INVENTORY - 1
            loop
                if UnitItemInSlot(u, loopA) != null then
                    call AddItem(u, UnitItemInSlot(u, loopA))
                endif
                
                exitwhen loopA == 0
                set loopA = loopA - 1
            endloop
    
            set loopA = 0
            loop 
                exitwhen InventorySkills[loopA] == 0 
                if GetUnitAbilityLevel(u, InventorySkills[loopA]) == 0 then
                    call UnitAddAbility(u, InventorySkills[loopA])
                endif
                call UnitMakeAbilityPermanent(u, true, InventorySkills[loopA])
                set loopA = loopA + 1
            endloop
            call TriggerRegisterUnitLifeEvent(TriggerLife, u, LESS_THAN_OR_EQUAL, 0.41)
        elseif not UnitHasItem(u, i) then
            call AddItem(u, i)
        endif
        
        set u = null
        set i = null
    endfunction
    
    public function ReAddInventories takes unit u returns nothing
        local item i
        local item newItem
        local integer loopA
        local integer loopB
        local integer itemCount = 1
        local integer unitHandle = GetHandleId(u)
        if not ValidUnit(u) then 
            return
        endif
    
        // revived heroes
        if GetUnitAbilityLevel(u, InventorySkills[0]) > 0 and GetUnitAbilityLevel(u, InventorySkills[1]) > 0  then
    
            // remember items already owned before getting TasInventory
    
            call DisableTrigger(TriggerItemDrop)
            static if LIBRARY_Table then    
                set loopA = data.BagItem[unitHandle].integer[0]
            else
                set loopA = LoadInteger(data.Hash, unitHandle,0)
            endif
            loop
                exitwhen loopA <= 0
    
                static if LIBRARY_Table then    
                    set i = data.BagItem[unitHandle].item[loopA]
                    set data.BagItem[unitHandle].item[loopA] = null
                    set data.BagItem[unitHandle].integer[0] = 0
                else
                    set i = LoadItemHandle(data.Hash, unitHandle, loopA)
                    call RemoveSavedHandle(data.Hash, unitHandle, loopA)
                    call SaveInteger(data.Hash, unitHandle, 0, 0)
                endif
                set newItem = CreateItem(GetItemTypeId(i), GetUnitX(u), GetUnitY(u))
                call CopyItemData(i, newItem)
                call RemoveItem(i)
                set ItemBackup[loopA] = newItem
                set loopA = loopA - 1
            endloop
            call EnableTrigger(TriggerItemDrop)
    
            // dont remove & readd the first inventory skill, otherwise the inventory grows
    
            //for i, abi in ipairs(this.InventorySkills) do
            set loopA = 1
            loop
                exitwhen InventorySkills[loopA] == 0
                call UnitMakeAbilityPermanent(u, false, InventorySkills[loopA])
                call UnitRemoveAbility(u, InventorySkills[loopA])
                set loopA = loopA + 1
            endloop
            
            set itemCount = 1
            set loopA = 1
            loop
            //for i, abi in ipairs(this.InventorySkills) do
                exitwhen InventorySkills[loopA] == 0
                set loopB = 0
                loop
                    exitwhen loopB >= bj_MAX_INVENTORY
                    if GetHandleId(UnitItemInSlot(u, loopB)) > 0 then
                        call AddItem(u, UnitItemInSlot(u, loopB))
                    endif
                    set loopB = loopB + 1
                endloop
    
                if GetUnitAbilityLevel(u, InventorySkills[loopA]) == 0 then
                    call UnitAddAbility(u, InventorySkills[loopA])
                endif
                call UnitMakeAbilityPermanent(u, true, InventorySkills[loopA])
    
                set loopB = 0
                loop
                    exitwhen loopB >= UnitInventorySize(u)
                
                    set i = ItemBackup[itemCount]
                    set ItemBackup[itemCount] = null
                    set itemCount = itemCount + 1
                    if GetHandleId(i) > 0 then
                        call UnitAddItem(u, i)
                    endif
                    set loopB = loopB + 1
                endloop
                set loopA = loopA + 1
            endloop
    
    
        endif
       
        set u = null
        set i = null
        set newItem = null
    endfunction
    
    private function UnitReviveAction takes nothing returns nothing
        call ReAddInventories(GetTriggerUnit())
        call GroupRemoveUnit(WaitingGroup, GetTriggerUnit())
    endfunction
    
    private function UnitLifeAction takes nothing returns nothing
        call GroupAddUnit(WaitingGroup, GetTriggerUnit())
    endfunction
    
    private function UnitReInkarnationDoneAction takes nothing returns nothing
        local unit u
        local integer i = BlzGroupGetSize(WaitingGroup) - 1
        loop
            exitwhen i < 0
            set u = BlzGroupUnitAt(WaitingGroup, i)
            if not IsUnitType(u, UNIT_TYPE_DEAD) then
                call GroupRemoveUnit(WaitingGroup, u)
                call ReAddInventories(u)
            endif
            set i = i - 1
        endloop
        set u = null
    endfunction
    
    private function ItemDropAction takes nothing returns nothing
        local integer loopA
        local integer unitHandle
        local unit u
        local item i
        if not ValidUnit(GetTriggerUnit()) then 
            return
        endif
        // powerups don't matter
        if IsItemPowerup(GetManipulatedItem()) then
            return
        endif
        // print("Owned", IsItemOwned(GetManipulatedItem()), "Life", "HasItem", UnitHasItem(GetTriggerUnit(), GetManipulatedItem()))
        // Drops from main inventory? no work to do
        if UnitHasItem(GetTriggerUnit(), GetManipulatedItem()) then
            return
        endif
        set u = GetTriggerUnit()
        set unitHandle = GetHandleId(u)
        // it can happen that using an item triggers other items in the inventory, check for broken and remove them
        // happened for me with some of the charged summon items
    static if LIBRARY_Table then    
        set loopA = data.BagItem[unitHandle].integer[0]
    else
        set loopA = LoadInteger(data.Hash, unitHandle,0)
    endif
        loop
            exitwhen loopA <= 0
        static if LIBRARY_Table then    
            set i = data.BagItem[unitHandle].item[loopA]
        else
            set i = LoadItemHandle(data.Hash, unitHandle, loopA)
        endif
            if i == GetManipulatedItem() then
                call RemoveIndex(u, loopA)
                exitwhen true
            endif
            set loopA = loopA - 1
        endloop
        set u = null
        set i = null
    endfunction
    
    private function UpdateUI takes nothing returns nothing
        local integer pId = GetPlayerId(GetLocalPlayer())
        local integer unitHandle = GetHandleId(Selected[pId])
    static if LIBRARY_Table then    
        local integer itemCount = data.BagItem[unitHandle].integer[0]
    else
        local integer itemCount = LoadInteger(data.Hash, unitHandle,0)
    endif
        local integer offset = Offset[pId]
        local integer max
        local integer itemCode
        local item it
        local string text = ""
        local integer dataIndex
        local integer i
        // When the options from HeroScoreFrame are in this map use the tooltip&total scale slider
        if GetHandleId(BlzGetFrameByName("HeroScoreFrameOptionsSlider1", 0)) > 0 then
            set TooltipScale = BlzFrameGetValue(BlzGetFrameByName("HeroScoreFrameOptionsSlider1", 0))
        endif
        if GetHandleId(BlzGetFrameByName("HeroScoreFrameOptionsSlider3", 0)) > 0 then
            call BlzFrameSetScale(BlzGetFrameByName("TasInventoryExPanel", 0), BlzFrameGetValue(BlzGetFrameByName("HeroScoreFrameOptionsSlider3", 0)))
        endif
    
        call BlzFrameSetScale(BlzGetFrameByName("TasInventoryExTooltipPanel", 0), TooltipScale)
        call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExSlot", 0), ValidUnit(Selected[pId]) and (not ShowButtonNeedsInventory or BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, 0))))
        call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSlotButtonOverLayText", 0), I2S(itemCount))
    
        if BlzFrameIsVisible(BlzGetFrameByName("TasInventoryExPanel", 0)) then    
            if itemCount > 0 then
    
                // scroll by rows
                set max = IMaxBJ(0, (itemCount+Cols - Cols*Rows)/Cols)
                
                call BlzFrameSetMinMaxValue(BlzGetFrameByName("TasInventoryExSlider", 0), 0, max)
                call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSliderTooltip", 0), I2S(R2I(offset/Cols))+"/"+I2S(max))
            else
                call BlzFrameSetMinMaxValue(BlzGetFrameByName("TasInventoryExSlider", 0), 0, 0)
                call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSliderTooltip", 0), "")
            endif
    
            set i = 1
            loop
                exitwhen i > Cols*Rows
                set dataIndex = i + offset
                call BlzFrameSetEnable(BlzGetFrameByName("TasInventoryExSlotButton", i), dataIndex <= itemCount)
                if dataIndex <= itemCount  then
                static if LIBRARY_Table then  
                    set it = data.BagItem[unitHandle].item[dataIndex]
                else
                    set it = LoadItemHandle(data.Hash, unitHandle, dataIndex)
                endif
                    set itemCode = GetItemTypeId(it)
                    call BlzFrameSetTexture(BlzGetFrameByName("TasInventoryExSlotButtonBackdrop", i), BlzGetAbilityIcon(itemCode) , 0, true)
                    call BlzFrameSetTexture(BlzGetFrameByName("TasInventoryExSlotButtonBackdropPushed", i), BlzGetAbilityIcon(itemCode) , 0, true)
    
                    call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSlotButtonTooltip", i), GetObjectName(itemCode)+ "|n"+BlzGetAbilityExtendedTooltip(itemCode, 0))
                    
                    if GetItemCharges(it) > 0 then
                        call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSlotButtonOverLayText", i), I2S(GetItemCharges(it)))
                        call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExSlotButtonOverLay", i), true)
                    else
                        call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExSlotButtonOverLay", i), false)
                    endif
                else
                    call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExSlotButtonOverLay", i), false)
                    call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSlotButtonTooltip", i), "")
                endif
                set i = i + 1
            endloop
        endif
        set it = null
    endfunction
         
    private function CreateTextTooltip takes framehandle frame, string wantedframeName, integer wantedCreateContext, string text returns framehandle
        // this FRAME is important when the Box is outside of 4:3 it can be limited to 4:3.
        local framehandle toolTipParent = BlzCreateFrameByType("FRAME", "", BlzGetFrameByName("TasInventoryExTooltipPanel", 0), "", 0)
        local framehandle toolTipBox = BlzCreateFrame("TasToolTipBox", toolTipParent, 0, 0)
        local framehandle toolTip = BlzCreateFrameByType("TEXT", wantedframeName, toolTipBox, "TasTooltipText", wantedCreateContext)
    
        if TooltipFixedPosition then 
            call BlzFrameSetAbsPoint(toolTip, TooltipFixedPositionPoint, TooltipFixedPositionX, TooltipFixedPositionY)
        else
            call BlzFrameSetPoint(toolTip, FRAMEPOINT_TOP, frame, FRAMEPOINT_BOTTOM, 0, -0.008)
        endif
    
        call BlzFrameSetPoint(toolTipBox, FRAMEPOINT_TOPLEFT, toolTip, FRAMEPOINT_TOPLEFT, -0.008, 0.008)
        call BlzFrameSetPoint(toolTipBox, FRAMEPOINT_BOTTOMRIGHT, toolTip, FRAMEPOINT_BOTTOMRIGHT, 0.008, -0.008)
        call BlzFrameSetText(toolTip, text)
        call BlzFrameSetTooltip(frame, toolTipParent)
        call BlzFrameSetSize(toolTip, TooltipWidth, 0)
        return toolTip
    endfunction
    
    private function InitFrames takes nothing returns nothing
            local boolean loaded = BlzLoadTOCFile("war3mapImported/TasInventoryEx.toc")
            local framehandle panel
            local framehandle frame
            local framehandle frame2
            local framehandle frame3
            local integer count = 0
            local integer buttonIndex = 0
            local boolean backup
    
            set panel = BlzCreateFrameByType("BUTTON", "TasInventoryExPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
            call BlzFrameSetAbsPoint(panel, Pos, PosX, PosY)
            call BlzFrameSetAllPoints(BlzCreateFrame("TasInventoryExBox", panel, 0, 0), panel)
            call BlzTriggerRegisterFrameEvent(TriggerUIWheel, panel, FRAMEEVENT_MOUSE_WHEEL)
            call BlzCreateFrameByType("BUTTON", "TasInventoryExTooltipPanel", panel, "", 0)
                // Custom Bag
            set count = 0
            set buttonIndex = 1
            loop
                exitwhen buttonIndex > Rows*Cols
            
                set frame = BlzCreateFrame("TasInventoryExSlot", panel, 0, buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButton", buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButtonBackdrop", buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButtonBackdropDisabled", buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButtonBackdropPushed", buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButtonOverLay", buttonIndex)
                call BlzGetFrameByName("TasInventoryExSlotButtonOverLayText", buttonIndex)
                call CreateTextTooltip(BlzGetFrameByName("TasInventoryExSlotButton", buttonIndex), "TasInventoryExSlotButtonTooltip", buttonIndex, "")
                call BlzTriggerRegisterFrameEvent(TriggerUIBagButton, BlzGetFrameByName("TasInventoryExSlotButton", buttonIndex), FRAMEEVENT_CONTROL_CLICK)
                call BlzTriggerRegisterFrameEvent(TriggerUIWheel, BlzGetFrameByName("TasInventoryExSlotButton", buttonIndex), FRAMEEVENT_MOUSE_WHEEL)
                call BlzFrameSetText(BlzGetFrameByName("TasInventoryExSlotButton", buttonIndex), I2S(buttonIndex))
                
                set count = count + 1
                if count > Cols then
                    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, BlzGetFrameByName("TasInventoryExSlot", buttonIndex - Cols), FRAMEPOINT_BOTTOMLEFT, 0, -0.002)
                    set count = 1
                elseif buttonIndex > 1 then
                    call BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, BlzGetFrameByName("TasInventoryExSlot", buttonIndex - 1), FRAMEPOINT_TOPRIGHT, 0.002, 0)
                endif
                set buttonIndex = buttonIndex + 1
            endloop
            if GetHandleId(frame) == 0 then
                call BJDebugMsg("Error - Creating TasInventoryExSlot")
            endif
            call BlzFrameSetSize(panel, BlzFrameGetWidth(frame)*Cols + (Cols - 1)*0.002 + 0.02, BlzFrameGetHeight(frame)*Rows + (Rows - 1)*0.002 + 0.012)
            call BlzFrameSetPoint(BlzGetFrameByName("TasInventoryExSlot", 1), FRAMEPOINT_TOPLEFT, panel, FRAMEPOINT_TOPLEFT, 0.006, -0.006)
    
            set frame = BlzCreateFrameByType("SLIDER", "TasInventoryExSlider", panel, "QuestMainListScrollBar", 0)
            call BlzFrameClearAllPoints(frame)
            call BlzFrameSetPoint(frame, FRAMEPOINT_BOTTOMRIGHT, panel, FRAMEPOINT_BOTTOMRIGHT, -0.004, 0.008)
            call BlzFrameSetSize(frame, BlzFrameGetWidth(frame), BlzFrameGetHeight(panel) - 0.02)
            //BlzFrameSetStepSize(frame, Cols)
            set backup = TooltipFixedPosition
            set TooltipFixedPosition = false
            call CreateTextTooltip(frame, "TasInventoryExSliderTooltip", 0, "")
            call BlzFrameSetSize(BlzGetFrameByName("TasInventoryExSliderTooltip", 0), 0, 0)
            set TooltipFixedPosition = backup
            call BlzTriggerRegisterFrameEvent(TriggerUIWheel, frame, FRAMEEVENT_MOUSE_WHEEL)
            call BlzTriggerRegisterFrameEvent(TriggerUISlider, frame, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    
    
            // show Buttons
            set frame = BlzCreateFrame("TasInventoryExSlot", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
            call BlzFrameSetAbsPoint(frame, ShowButtonPos, ShowButtonPosX, ShowButtonPosY)
            call BlzFrameSetTexture(BlzGetFrameByName("TasInventoryExSlotButtonBackdrop", 0), ShowButtonTexture, 0, false)
            call BlzFrameSetTexture(BlzGetFrameByName("TasInventoryExSlotButtonBackdropDisabled", 0), ShowButtonTextureDisabled, 0, false)
            call BlzFrameSetTexture(BlzGetFrameByName("TasInventoryExSlotButtonBackdropPushed", 0), ShowButtonTexture, 0, false)
            call BlzGetFrameByName("TasInventoryExSlotButtonOverLay", 0)
            call BlzGetFrameByName("TasInventoryExSlotButtonOverLayText", 0)
            call BlzTriggerRegisterFrameEvent(TriggerUIOpen, BlzGetFrameByName("TasInventoryExSlotButton", 0), FRAMEEVENT_CONTROL_CLICK)
            call BlzFrameSetEnable(BlzGetFrameByName("TasInventoryExSlotButton", 0), true)
            
            
            set frame = BlzCreateFrameByType("GLUETEXTBUTTON", "TasInventoryExCloseButton", panel, "ScriptDialogButton", 0)
            call BlzFrameSetSize(frame, 0.03, 0.03)
            call BlzFrameSetText(frame, "X")
            call BlzFrameSetPoint(frame, FRAMEPOINT_CENTER, BlzFrameGetParent(frame), FRAMEPOINT_TOPRIGHT, -0.002, -0.002)
            call BlzTriggerRegisterFrameEvent(TriggerUIClose, frame, FRAMEEVENT_CONTROL_CLICK)
           // BlzFrameClick(BlzGetFrameByName("TasInventoryExCloseButton", 0))
    
            call BlzFrameSetLevel(BlzGetFrameByName("TasInventoryExTooltipPanel", 0), 8)
          
            
    
            call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPopUpPanel", 0), false)
            call BlzFrameSetVisible(BlzGetFrameByName("TasInventoryExPanel", 0), false)

            call BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, 0)
        endfunction
        private function At0s takes nothing returns nothing
            local integer i
            set AbilityField = ConvertAbilityIntegerLevelField('inv1')
     
            static if LIBRARY_Table then
                set data.BagItem = HashTable.create()
            else
                set data.Hash = InitHashtable()
            endif
            
            set TimerUpdate = CreateTimer()
            call TimerStart(TimerUpdate, 0.1, true, function UpdateUI)
            
            set Trigger = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(Trigger, EVENT_PLAYER_UNIT_SELECTED)
            call TriggerAddAction(Trigger, function SelectAction)
            
            set TriggerESC = CreateTrigger()
            set i = 0
            loop
                call BlzTriggerRegisterPlayerKeyEvent(TriggerESC, Player(i), OSKEY_ESCAPE, 0, true)
                set i = i + 1
                exitwhen i >= bj_MAX_PLAYERS
            endloop
            
            call TriggerAddAction(TriggerESC, function ESCAction)
    
            
            set TriggerItemGain = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(TriggerItemGain, EVENT_PLAYER_UNIT_PICKUP_ITEM)
            call TriggerAddAction(TriggerItemGain, function ItemGainAction)
    
            set TriggerItemDrop = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(TriggerItemDrop, EVENT_PLAYER_UNIT_DROP_ITEM)
            call TriggerAddAction(TriggerItemDrop, function ItemDropAction)
    
            set TriggerUnitRevived = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(TriggerUnitRevived, EVENT_PLAYER_HERO_REVIVE_FINISH)
            call TriggerAddAction(TriggerUnitRevived, function UnitReviveAction)
            
            set TriggerLife = CreateTrigger()
            call TriggerAddAction(TriggerLife, function UnitLifeAction)
    
            set WaitingGroup = CreateGroup()
            set TriggerReInkarnationDone = CreateTrigger()
            call TriggerRegisterTimerEvent(TriggerReInkarnationDone, 0.25, true)  
            call TriggerAddAction(TriggerReInkarnationDone, function UnitReInkarnationDoneAction)
    
    
    
            set TriggerUIOpen = CreateTrigger()
            call TriggerAddAction(TriggerUIOpen, function ShowButtonAction)
    
            set TriggerUIClose = CreateTrigger()
            call TriggerAddAction(TriggerUIClose, function CloseButtonAction)
    
            set TriggerUIBagButton = CreateTrigger()
            call TriggerAddAction(TriggerUIBagButton, function BagButtonAction)
    
            set TriggerUISlider = CreateTrigger()
            call TriggerAddAction(TriggerUISlider, function SliderAction)
    
            set TriggerUIWheel = CreateTrigger()
            call TriggerAddAction(TriggerUIWheel, function WheelAction)
    
            call UserInit()
            call InitFrames()
    
            static if LIBRARY_FrameLoader then
                call FrameLoaderAdd(function InitFrames)
            endif
            call DestroyTimer(GetExpiredTimer())
        endfunction
        private function init_function takes nothing returns nothing
            call TimerStart(CreateTimer(), 0, false, function At0s)
        endfunction
    endlibrary
    