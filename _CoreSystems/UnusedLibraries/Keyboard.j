library Keyboard initializer init uses PanelCore, ShortcutBar, Mouse, MouseUtils
    
    globals
		boolean array IsKeyVerified
        real Smooth = 0//0.03//0.4
        unit array MainUnit
		real array CameraDistance
		real array LastRot
		boolean array CameraOn
		boolean array ItemOn
		CustomText array PlayerNameTag
        private timer array Tim
        player Locale
        integer PNumb
        private rect TempRect
        private integer TempInt
        real CamAng = bj_CAMERA_DEFAULT_AOA
        real CamRot = 163.97
		boolean IgnoreCooldown = false
	private destructable array OccludedDest
	private integer array OccludedDestTarget
	public real array Smoothing
	private real array OccludedDestX
	private real array OccludedDestY
	private integer OccludedDestCt = 0
		private player ItemFinderPlayer = null
		private unit ItemFinder = null
		private unit ClosestItem = null
		private real ClosestItemDist = 600
		private group TempGroup = CreateGroup()
	integer array LastNumbKey
	timer array HoldNumbTimer
    endglobals
    
    private function checkDest takes nothing returns nothing

        	local integer i = 0

		loop
			exitwhen i >= OccludedDestCt
			if not IsUnitInRangeXY(MainUnit[OccludedDestTarget[i]], OccludedDestX[i], OccludedDestY[i], OCCLUSION_DEST_DISTANCE+128) then
				call SetDestructableOccluderHeight(OccludedDest[i], 5.0)
       				call SetDestructableAnimation(OccludedDest[i], "birth alternate")
       				call QueueDestructableAnimation(OccludedDest[i], "stand")
				set OccludedDest[i] = OccludedDest[OccludedDestCt]
				set OccludedDestTarget[i] = OccludedDestTarget[OccludedDestCt]
				set OccludedDestX[i] = OccludedDestX[OccludedDestCt]
				set OccludedDestY[i] = OccludedDestY[OccludedDestCt]
				set OccludedDest[OccludedDestCt] = null
				set OccludedDestCt = OccludedDestCt - 1
				set i = i - 1
			endif
			set i = i + 1
		endloop
	endfunction
    
    private function hideDest takes nothing returns nothing

		local destructable d = GetEnumDestructable()
		local integer id
		
		if GetDestructableOccluderHeight(d) > 0.0 and IsUnitInRangeXY(MainUnit[TempInt], GetDestructableX(d), GetDestructableY(d), OCCLUSION_DEST_DISTANCE) then
			set id = GetDestructableTypeId(d)
			if id == 'B04M' or id == 'B04N' then
				call SetDestructableOccluderHeight(d, 0.0)
       				call SetDestructableAnimation(d, "death alternate")
				set OccludedDest[OccludedDestCt] = d
				set OccludedDestTarget[OccludedDestCt] = TempInt
				set OccludedDestX[OccludedDestCt] = GetDestructableX(d)
				set OccludedDestY[OccludedDestCt] = GetDestructableY(d)
				set OccludedDestCt = OccludedDestCt + 1
			endif
		endif
		set d = null

	endfunction
    
    private function def takes nothing returns nothing
        
        local real x
        local real y
        local real uz
        local real z2
        local real rot
        local real d
        local real cd
        local real mhx
        local real mh
        local real z
        local real cz
		local real a
		local timer t = GetExpiredTimer()
        local integer i = GetTimerData(t)
	local unit npc
        
		if CameraOn[i] and IsPlaying[i] then
			set x = GetUnitX(MainUnit[i])
			set y = GetUnitY(MainUnit[i])
			if InDungeon then
				set TempInt = i
				call SetRect(TempRect, x-OCCLUSION_DEST_DISTANCE, y-OCCLUSION_DEST_DISTANCE, x+OCCLUSION_DEST_DISTANCE, y+OCCLUSION_DEST_DISTANCE)
        			call EnumDestructablesInRect(TempRect, null, function hideDest)
			endif
			if SelectedMerchant[i] != null then
				set npc = SelectedMerchant[i]
			else
				set npc = ShopMerchants_CurrentMerchant[i]
			endif
			
			if npc != null then
				set rot = GetUnitFacing(npc) + 180.0
				call PlayerCamera[i].setField(CAMERA_FIELD_ANGLE_OF_ATTACK, 350.0, 0.25)
				call PlayerCamera[i].setField(CAMERA_FIELD_TARGET_DISTANCE, 400.0, 0.25)
				call PlayerCamera[i].setField(CAMERA_FIELD_ROTATION, rot, 0.0)
				if rot != LastRot[i] then
					call RefreshItemNames()
					call RefreshPortalText()
					call RefreshNPCText()
				endif
				set LastRot[i] = rot
			else
				call PlayerCamera[i].setField(CAMERA_FIELD_ANGLE_OF_ATTACK, CamAng, Smooth)
				call PlayerCamera[i].setField(CAMERA_FIELD_TARGET_DISTANCE, CameraDistance[i], Smooth)
				if InDoor[i] then
					call PlayerCamera[i].setField(CAMERA_FIELD_ROTATION, 90, Smooth)
					if 90 != LastRot[i] then
						call RefreshItemNames()
						call RefreshPortalText()
						call RefreshNPCText()
					endif
					set LastRot[i] = 90
				else
					call PlayerCamera[i].setField(CAMERA_FIELD_ROTATION, CamRot, Smooth)
					if CamRot != LastRot[i] then
						call RefreshItemNames()
						call RefreshPortalText()
						call RefreshNPCText()
					endif
					set LastRot[i] = CamRot
				endif
			endif
			//set cz = PlayerCamera[i].ZOffset+uz+CameraShaker_VMagnitude[i]-GetCameraTargetPositionZ()
			if npc != null then
				call PlayerCamera[i].setField(CAMERA_FIELD_ZOFFSET, DungeonZ+GetUnitFlyHeight(SelectedMerchant[i])+64, 0)
			else
				call PlayerCamera[i].setField(CAMERA_FIELD_ZOFFSET, DungeonZ+GetUnitFlyHeight(MainUnit[i])+CameraShaker_VMagnitude[i]*CameraShaker_Intensity[i]*DEFAULT_SHAKE_INTENSITY+128, 0)
			endif
			if MainUnit[i] != null then
				if npc != null then
					set x = GetUnitX(npc)
					set y = GetUnitY(npc)
				endif
				if CameraShaker_HMagnitude[i] > 0 then
					set a = PlayerCamera[i].Rotation-PanelCore_HP
					set x = x + (CameraShaker_HMagnitude[i]*CameraShaker_Intensity[i]*DEFAULT_SHAKE_INTENSITY) * Cos(a)
					set y = y + (CameraShaker_HMagnitude[i]*CameraShaker_Intensity[i]*DEFAULT_SHAKE_INTENSITY) * Sin(a)
				endif
				call PlayerCamera[i].move(x, y, Smoothing[i])
				call PlayerNameTag[i].move(x, y, 200)
			endif
		endif
		if IsPlaying[i] then
			if InDungeon then
				call SetCameraField(CAMERA_FIELD_FARZ, 6000.0, 0)
			else
				call SetCameraField(CAMERA_FIELD_FARZ, 10000.0, 0)
			endif
			call PlayerCamera[i].refresh()
		endif
		set t = null
        
    endfunction
    
	private function findClosestItem takes nothing returns boolean
		
		local unit i = GetFilterUnit()
		local real x = GetUnitX(i)
		local real y = GetUnitY(i)
		local real dx
		local real dy
		
		if GetUnitTypeId(i) == 'e02F' and IsUnitVisible(i, ItemFinderPlayer) and IsUnitInRangeXY(ItemFinder, x, y, ClosestItemDist) then
			set ClosestItem = i
			set dx = GetUnitX(ItemFinder)-x
			set dy = GetUnitY(ItemFinder)-y
			set ClosestItemDist = SquareRoot(dx*dx+dy*dy)
		endif
		set i = null
		
		return false
	endfunction
	
    private function onOrder takes nothing returns boolean
		
		local integer order
		local unit fog
		local integer id
		local player p
		
		if GetUnitTypeId(GetTriggerUnit()) == 'h001' then
			set order = GetIssuedOrderId()
			if order == ORDER_defend or order == ORDER_undefend then
				set p = GetTriggerPlayer()
				set id = GetPlayerId(p)
				if order == ORDER_defend then
					set ItemOn[id] = false
				elseif order == ORDER_undefend then
					set ItemOn[id] = true
				endif
				loop
					set fog = FirstOfGroup(ItemObject.AllItem)
					exitwhen fog == null
					call GroupRemoveUnit(ItemObject.AllItem, fog)
					call GroupAddUnit(TempGroup, fog)
					if Locale == p then
						set ItemObject[fog].selectable = ItemOn[id]
					endif
				endloop
				call DestroyGroup(ItemObject.AllItem)
				set ItemObject.AllItem = TempGroup
				set TempGroup = CreateGroup()
			endif
		endif
		
		return false
	endfunction
    private function onCast takes nothing returns boolean
        
		local unit u = GetTriggerUnit()
		local player p
		local unit fog
        local integer spell
		local integer id
		local integer i
		local integer data
		local integer best1
		local real value
		local real need
		local real best1data
		local Combatant c
		local ItemObject obj
        
		if GetUnitAbilityLevel(u, 'A007') > 0 then
			set spell = GetSpellAbilityId()
			set p = GetTriggerPlayer()
			set id = GetPlayerId(p)
			if spell == 'A007' then
				call Bag[id].show(not Bag[id].visible)
				call Bag[id].panel.refresh()
			elseif spell == 'A006' or spell == 'A00C' then
				call CharacterWindow_Show(id, not CharacterWindow_Visible[id])
				if CharacterWindow_Visible[id] then
					call ShopUI[id].show(false)
				endif
			elseif spell == 'A00D' then
				if InDungeon then
					if MiniMap_MaximizeButton.texture == "war3mapImported\\MinimapMinimize.blp" then
						set MiniMap_MaximizeButton.texture = "war3mapImported\\MinimapMaximize.blp"
						set MiniMap_TilePanel.visible = false
						set MiniMap_Frame.visible = false
					else
						call MiniMap_HideAll()
						set MiniMap_MaximizeButton.texture = "war3mapImported\\MinimapMinimize.blp"
						set MiniMap_TilePanel.visible = true
						set MiniMap_Frame.visible = true
						call MiniMap_UpdateMinimap()
					endif
				endif
			elseif spell == 'A009' then
				if CharacterWindow_Visible[id] then
					if CharacterWindow_TabIndex[id] < 2 then
						call CharacterWindow_OpenTab(id, CharacterWindow_TabIndex[id]+1)
					else
						call CharacterWindow_OpenTab(id, 0)
					endif
				endif
			elseif spell == 'A00P' then
				if IsUnitAlive(MainUnit[id]) then

				set c = Fighter[id]
				set need = c.hpMax-c.hp
				if need <= 1 then
					call DisplayTimedTextToPlayer(p, 0, 0, 1., "|cffffcc00Already at full health!|r")
					return false
				endif
				set best1 = -1
				set best1data = 999999999
				set i = 0
				loop
					exitwhen i == 20
					if Inventory_SlotIndex[Bag[id]][i].object.id.category == Items.CONSUMABLE then
						set value = Inventory_SlotIndex[Bag[id]][i].object.hp
						if value > 0 then
							set value = RAbsBJ(value-need)
							if value < best1data then
								set best1 = i
								set best1data = value
							endif
						endif
					endif
					set i = i + 1
				endloop
				if best1 != -1 then
					call Bag[id].useItemAtSlot(best1)
				else
					call DisplayTimedTextToPlayer(p, 0, 0, 1., "|cffff0000Out of health potion!|r")
				endif

				endif
			elseif spell == 'A00Q' then
				if IsUnitAlive(MainUnit[id]) then

				set c = Fighter[id]
				set need = c.spMax-c.sp
				if need <= 1 then
					call DisplayTimedTextToPlayer(p, 0, 0, 1., "|cffffcc00Already at full mana!|r")
					return false
				endif
				set best1 = -1
				set best1data = 999999999
				set i = 0
				loop
					exitwhen i == 20
					if Inventory_SlotIndex[Bag[id]][i].object.id.category == Items.CONSUMABLE then
						set value = Inventory_SlotIndex[Bag[id]][i].object.sp
						if value > 0 then
							set value = RAbsBJ(value-need)
							if value < best1data then
								set best1 = i
								set best1data = value
							endif
						endif
					endif
					set i = i + 1
				endloop
				if best1 != -1 then
					call Bag[id].useItemAtSlot(best1)
				else
					call DisplayTimedTextToPlayer(p, 0, 0, 1., "|cffff0000Out of mana potion!|r")
				endif

				endif
			elseif spell == 'A013' then
				call IssueImmediateOrder(Fighter[id].u, "stop")
			elseif spell == 'A014' then
				call Fighter[id].attack()
			elseif spell == 'A003' then
				set ClosestItemDist = 800
				set ClosestItem = null
				set ItemFinder = Fighter[id].u
				set ItemFinderPlayer = Fighter[id].owner
				call GroupEnumUnitsInRange(TempGroup, GetUnitX(ItemFinder), GetUnitY(ItemFinder), 600, Filter(function findClosestItem))
				call GroupClear(TempGroup)
				if ClosestItem != null then
					call IssueTargetOrder(Controller[id], "smart", ClosestItem)
				endif
			endif
		endif
		set u = null
        
        return false
    endfunction

    private function pressKey takes player p, integer numb returns nothing
		
		local integer id = GetPlayerId(p)
		local integer data
		local integer data2
		local integer data3
		local integer i
		local real cd
		local real x
		local real y
		local string s
		local PlayerSkill skill
		local SkillData sData
		
			set data = GetUnitUserData(MainUnit[id])
			if UnitAlive(MainUnit[id]) and not IsUnitPaused(MainUnit[id]) then
				if numb == 0 then
					set numb = 10
				endif
				set numb = numb - 1
				if not IsShortcutSlotInCooldown(id, numb) then
					set data3 = GetUnitUserData(ShortcutBar_Button[id][numb].dummy)
					if ShortcutBar_ButtonType[data3] == 1 then
						if not Fighter[id].isSilenced and not Fighter[id].isStunned and not Fighter[id].isDisarmed and not Fighter[id].isAttacking then
							set sData = ShortcutBar_ButtonSkill[data3]
							set skill = PlayerSkillData[id][sData]
							if Fighter[id].hp <= sData.lifecost[skill.level] then
								//call DisplayTimedTextToPlayer(p, 0, 0, 1., "Not enough HP.")
							elseif Fighter[id].sp < sData.manacost[skill.level] then
								//call DisplayTimedTextToPlayer(p, 0, 0, 1., "Not enough MP.")
							else
								set x = 0
								set y = 0
								static if USE_MEMORY_HACK then
									if IsLAN then
										set x = MouseX[id]
										set y = MouseY[id]
									else
										set x = GetMouseX()
										set y = GetMouseY()
									endif
								else
									set x = GetPlayerMouseX(p)
									set y = GetPlayerMouseY(p)
								endif
								
								if not Fighter[id].isChanneling then
									if ShortcutBar_SkillSelection[id].visible then
										call ShortcutBar_SkillSelection[id].clear()
										set ShortcutBar_SelectIndex[id] = -1
										call ShortcutBar_SkillSelection[id].show(false)
									endif
									if IgnoreCooldown then
										set cd = 0
									else
										set cd = sData.cooldown[skill.level]
										set Fighter[id].hp = Fighter[id].hp - sData.lifecost[skill.level]
										set Fighter[id].sp = Fighter[id].sp - sData.manacost[skill.level]
									endif
									if cd > 0 then
										set i = 0
										loop
											exitwhen i > 9
											set data2 = GetUnitUserData(ShortcutBar_Button[id][i].dummy)
											if ShortcutBar_ButtonType[data2] == 1 and ShortcutBar_ButtonSkill[data2] == sData then
												call ShortcutBar_PutToCooldown(id, i, cd, cd)
											endif
											set i = i + 1
										endloop
										call SkillCooldown.start(sData, cd)
									endif
								endif
								call Combatant[MainUnit[id]].cast(sData, x, y, "")
							endif
						endif
					elseif ShortcutBar_ButtonType[data3] == 2 then
						call Bag[id].useItemAtSlot(ShortcutBar_ButtonTarget[data3])
						set ShortcutBar_SelectIndex[id] = -1
						call ShortcutBar_SkillSelection[id].show(false)
					endif
				endif
			endif

	endfunction

	private function repeatNumbKey takes nothing returns nothing
		
		local timer t = GetExpiredTimer()
		local integer id = GetTimerData(t)
		local player p = Player(id)

		if Fighter[id].isChanneling then
			call SetUnitFacing(MainUnit[id], Atan2(GetPlayerMouseY(p)-GetUnitY(MainUnit[id]), GetPlayerMouseX(p)-GetUnitX(MainUnit[id]))*bj_RADTODEG)
		else
			call pressKey(p, LastNumbKey[id])
		endif
		set t = null

	endfunction

    private function onPress takes nothing returns boolean

	local oskeytype pressed
	local player p = GetTriggerPlayer()
	local boolean down = BlzGetTriggerPlayerIsKeyDown()
	local integer id = GetPlayerId(p)
	local integer numb

	if down then
		if HoldNumbTimer[id] == null then
			set HoldNumbTimer[id] = NewTimerEx(id)
		endif
		call TimerStart(HoldNumbTimer[id], 0.1, true, function repeatNumbKey)
	else
		call PauseTimer(HoldNumbTimer[id])
		if not Fighter[id].isChanneling then
			return false
		endif
	endif

	set pressed = BlzGetTriggerPlayerKey()
	if pressed == OSKEY_0 then
		set numb = 0
	elseif pressed == OSKEY_1 then
		set numb = 1
	elseif pressed == OSKEY_2 then
		set numb = 2
	elseif pressed == OSKEY_3 then
		set numb = 3
	elseif pressed == OSKEY_4 then
		set numb = 4
	elseif pressed == OSKEY_5 then
		set numb = 5
	elseif pressed == OSKEY_6 then
		set numb = 6
	elseif pressed == OSKEY_7 then
		set numb = 7
	elseif pressed == OSKEY_8 then
		set numb = 8
	elseif pressed == OSKEY_9 then
		set numb = 9
	endif
	set LastNumbKey[id] = numb

	call pressKey(p, numb)
        
        return false
    endfunction
	
	public function SetCamSmoothness takes integer id, integer level returns integer
		
		if level < 0 then
			set level = 0
		elseif level > 4 then
			set level = 4
		endif
        call TimerStart(Tim[id], 0.05-0.01*level, true, function def)
		
		return level
	endfunction
    
    private function checkArrow takes nothing returns nothing
		
		local integer i = 0
		local player p
		
		loop
			exitwhen i > 3
			if IsPlaying[i] and CameraOn[i] then
				set p = Player(i)
				if IsArrowKeyPressed(p, ARROW_KEY_UP) then
					if PlayerCamera[i].TargetDistance > 800 then
						set CameraDistance[i] = PlayerCamera[i].TargetDistance - 30
						if CameraDistance[i] < 800 then
							set CameraDistance[i] = 800
						endif
					endif
				elseif IsArrowKeyPressed(p, ARROW_KEY_DOWN) then
					if PlayerCamera[i].TargetDistance < 1600 then
						set CameraDistance[i] = PlayerCamera[i].TargetDistance + 30
						if CameraDistance[i] > 1600 then
							set CameraDistance[i] = 1600
						endif
					endif
				endif
			endif
			set i = i + 1
		endloop
        
    endfunction
    
    private function init takes nothing returns nothing
        
        local trigger t = CreateTrigger()
		local integer i = 0
	local player p
        
	set TempRect = Rect(0, 0, 0, 0)
        call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_SPELL_EFFECT)
        call TriggerAddCondition(t, Condition(function onCast)) 
		
        set t = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_ISSUED_ORDER)
        call TriggerAddCondition(t, Condition(function onOrder)) 
        
        set Locale = GetLocalPlayer()
        set PNumb = GetPlayerId(Locale)
        
        set t = CreateTrigger()
        call TriggerAddCondition(t, Condition(function onPress)) 
		loop
			exitwhen i > 3
			set p = Player(i)
			set Tim[i] = NewTimerEx(i)
			set CameraDistance[i] = 1200
			set IsKeyVerified[i] = true
			call TimerStart(Tim[i], PanelCamera_INTERVAL, true, function def)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_0, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_0, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_1, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_1, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_2, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_2, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_3, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_3, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_4, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_4, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_5, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_5, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_6, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_6, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_7, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_7, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_8, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_8, 0, false)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_9, 0, true)
			call BlzTriggerRegisterPlayerKeyEvent(t, p, OSKEY_9, 0, false)
			set i = i + 1
		endloop
    
        call FogEnable(false)
        call FogMaskEnable(false)
        call EnableDragSelect(true, false)
		call EnablePreSelect(false, false)
		call EnableSelect(true, false)
        //call SelectUnit(MainUnit[PNumb], true)
        call SetCameraPosition(GetUnitX(MainUnit[PNumb]), GetUnitY(MainUnit[PNumb]))

		
        //call RegisterAnyNumberKeyEvent(Condition(function onPress))
        call TimerStart(CreateTimer(), 0.03, true, function checkArrow)
        call TimerStart(CreateTimer(), 0.5, true, function checkDest)
        
    endfunction
    
endlibrary