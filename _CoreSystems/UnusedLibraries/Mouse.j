library LeftClick initializer init uses Track, Mouse, PanelCore, MouseUtils, UpgradeMenu
	
	globals
		private trackable Detector
		private real X
		private real X2
		private real Y
		private real Z
		private real RestartDelay
		private integer RestartId
		real array MouseX
		real array MouseY
		timer array RestartTimer
		timer array RightClickTimer
		timer array LeftClickTimer
		constant real EST_PING = 0.25
		constant integer STREAM_ACC = 4
		private integer array StreamCount
		private integer OrderIndex = 1
	endglobals
	
	private function CreateDest takes nothing returns nothing
		call CreateDestructableZ('B00J', X, Y, Z, 0, 1 , 0)
	endfunction
	
	private function InitDest2 takes nothing returns nothing
	
		loop
			exitwhen X > X2
			call ForForce(bj_FORCE_PLAYER[0], function CreateDest)
			set X = X + 1024
		endloop
			
	endfunction
	
	function InitDest takes rect r, real z returns nothing
	
		local real x = GetRectMinX(r)
		local real y = GetRectMinY(r)
		local real y2 = GetRectMaxY(r)
		
		set X2 = GetRectMaxX(r)
		set Z = z
		loop
			exitwhen y > y2
			set X = x
			set Y = y
			call ForForce(bj_FORCE_PLAYER[0], function InitDest2)
			set y = y + 1024
		endloop
		
	endfunction
	
	private function CreateTrack2 takes nothing returns nothing
		call CreateTrack("war3mapImported\\Track1024.mdx", X, Y, Z+10, 0)
	endfunction
	
	private function InitTrack2 takes nothing returns nothing
	
		loop
			exitwhen X > X2
			call ForForce(bj_FORCE_PLAYER[0], function CreateTrack2)
			set X = X + 1024
		endloop
		
	endfunction
	
	function InitTrack takes rect r, real z returns nothing
	
		local real x = GetRectMinX(r)
		local real y = GetRectMinY(r)
		local real y2 = GetRectMaxY(r)
		
		set X2 = GetRectMaxX(r)
		set Z = z
		loop
			exitwhen y > y2
			set X = x
			set Y = y
			call ForForce(bj_FORCE_PLAYER[0], function InitTrack2)
			set y = y + 1024
		endloop
		
	endfunction

	private function leftClick takes player p, integer id returns nothing
	
		local real x
		local real y
		
		if IsUnitAlive(MainUnit[id]) then
			if IsKeyVerified[id] then
				if IsUnitSelected(Controller[id], p) then
					if ShopMerchants_CurrentMerchant[id] != null then
						set ShopMerchants_CurrentMerchant[id] = null
						if ShopUI[id].visible then
							call ShopUI[id].show(false)
						endif
						if UpgradeMenu_Main[id].visible then
							call UpgradeMenu_CloseWindow(id)
						endif
					else
						if Fighter[id].isAttackReady then
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
							if x != 0 and y != 0 or USE_MEMORY_HACK then
								call SetUnitFacing(MainUnit[id], Atan2(y-GetUnitY(MainUnit[id]), x-GetUnitX(MainUnit[id]))*bj_RADTODEG)
							endif
						else
							call IssueImmediateOrder(MainUnit[id], "stop")
						endif
						if x != 0 and y != 0 or USE_MEMORY_HACK then
							call Fighter[id].attack()
						endif
					endif
				else
					if Locale == p then
						call ClearSelection()
						call SelectUnit(Controller[id], true)
					endif
				endif
			endif
		endif
		
	endfunction

	private function repeatLeftClick takes nothing returns nothing
		
		static if not USE_MEMORY_HACK then
		
		local timer t = GetExpiredTimer()
		local integer id = GetTimerData(t)
		local player p = Player(id)
		
		call leftClick(p, id)
		set t = null
		
		endif
		
	endfunction

	private function onClick takes nothing returns boolean
	
		local player p = GetTriggerTrackablePlayer()
		local integer id = GetPlayerId(p)
		
		call leftClick(p, id)
		static if not USE_MEMORY_HACK then
			if UserMouse[p].isMouseButtonClicked(MOUSE_BUTTON_TYPE_LEFT) and ShopMerchants_CurrentMerchant[id] == null then
				if LeftClickTimer[id] == null then
					set LeftClickTimer[id] = NewTimerEx(id)
				endif
				call TimerStart(LeftClickTimer[id], 0.1, true, function repeatLeftClick)
			endif
		endif
		
		return false
	endfunction

	private function rightClick takes player p, integer id returns nothing
	
		local real x
		local real y
		
		if UnitAlive(MainUnit[id]) then
			if IsKeyVerified[id] then
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
				if x != 0 and y != 0 or USE_MEMORY_HACK then
					if IsUnitSelected(Controller[id], p) then
						if ShopMerchants_CurrentMerchant[id] != null then
							set ShopMerchants_CurrentMerchant[id] = null
							if ShopUI[id].visible then
								call ShopUI[id].show(false)
							endif
							if UpgradeMenu_Main[id].visible then
								call UpgradeMenu_CloseWindow(id)
							endif
						else
							call Fighter[id].move(x, y)
						endif
					else
						if Locale == p then
							call ClearSelection()
							call SelectUnit(Controller[id], true)
						endif
					endif
				endif
			endif
		endif
		
	endfunction

	private function repeatRightClick takes nothing returns nothing
		
		static if not USE_MEMORY_HACK then
		
		local timer t = GetExpiredTimer()
		local integer id = GetTimerData(t)
		local player p = Player(id)
		
		call rightClick(p, id)
		set t = null
		
		endif
		
	endfunction

	public function onOrder takes nothing returns boolean
		
		local unit u = GetTriggerUnit()
		local player p = GetOwningPlayer(u)
		local integer id = GetPlayerId(p)
		
		if GetIssuedOrderId() != 851973 then
			call rightClick(p, id)
			static if not USE_MEMORY_HACK then
				if UserMouse[p].isMouseButtonClicked(MOUSE_BUTTON_TYPE_RIGHT) and ShopMerchants_CurrentMerchant[id] == null then
					if RightClickTimer[id] == null then
						set RightClickTimer[id] = NewTimerEx(id)
					endif
					call TimerStart(RightClickTimer[id], 0.25, true, function repeatRightClick)
				endif
			endif
		endif
		set u = null
		
		return false
	endfunction
	
	private function onMouseUp takes nothing returns boolean
		
		static if not USE_MEMORY_HACK then
		
		local integer id = GetPlayerId(GetTriggerPlayer())
		
		if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT then
			call ReleaseTimer(RightClickTimer[id])
			set RightClickTimer[id] = null
		elseif BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_LEFT then
			if CharacterWindowRotate_IsRotating[id] then
				//set CharacterWindowRotate_IsRotating[id] = false
			endif
			call ReleaseTimer(LeftClickTimer[id])
			set LeftClickTimer[id] = null
		endif
		endif
		
		return false
	endfunction
	
	private function onMouseDown takes nothing returns boolean
	
		static if not USE_MEMORY_HACK then
		
		local player p = GetTriggerPlayer()
		local integer id = GetPlayerId(p)

		if UnitAlive(MainUnit[id]) then
			if IsKeyVerified[id] then
				if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT and GetPlayerMouseX(p) != 0 and GetPlayerMouseY(p) != 0 then
					if not IsUnitSelected(Controller[id], p) then
						if Locale == p then
							call ClearSelection()
							call SelectUnit(Controller[id], true)
						endif
					endif
				else
				endif
			endif
		endif
		
		endif
		
		return false
	endfunction
	
	private function RestartStreamEx takes nothing returns nothing
		
		local timer t = GetExpiredTimer()
		
		set RestartDelay = TimerGetTimeout(t)
		set RestartId = GetTimerData(t)
		call ExecuteFunc("RestartStream")
		call ReleaseTimer(t)
		set t = null
		
	endfunction
	
	private function StreamReceived takes nothing returns boolean
	
        local SyncData d = GetSyncedData()
        local integer id = d.readInt(0)
		local real delay = d.readReal(2)
		local string s
		
		set MouseX[id] = d.readReal(0)
		set MouseY[id] = d.readReal(1)
		call d.destroy()
		
		if IsPlaying[id] then
			call TimerStart(NewTimerEx(id), RAbsBJ(delay), false, function RestartStreamEx)
		endif
		
		return false
	endfunction
	
	function RestartStream takes nothing returns nothing
		
        local SyncData d = SyncData.create(Player(RestartId))
		
		static if USE_MEMORY_HACK then
			call d.addReal(GetMouseX())
			call d.addReal(GetMouseY())
		endif
		call d.addReal(RestartDelay)
		call d.addInt(RestartId)
		set d.onComplete = Filter(function StreamReceived)
		call d.start()
		
	endfunction
	
	private function StartStreamEx takes nothing returns nothing
		
		local timer t = GetExpiredTimer()
		local integer id = GetTimerData(t)
        local SyncData data
		
		set data = SyncData.create(Player(id))
		static if USE_MEMORY_HACK then
			call data.addReal(GetMouseX())
			call data.addReal(GetMouseY())
		endif
		call data.addReal(EST_PING/STREAM_ACC*(4-StreamCount[id]))
		call data.addInt(id)
		set data.onComplete = Filter(function StreamReceived)
		call data.start()
		
		set StreamCount[id] = StreamCount[id] - 1
		if (StreamCount[id] > 0) then
			call TimerStart(t, EST_PING/STREAM_ACC, false, function StartStreamEx)
		else
			call ReleaseTimer(t)
		endif
		set t = null
		
	endfunction
	
	public function StartStream takes integer id returns nothing
		
		static if USE_MEMORY_HACK then
			set StreamCount[id] = STREAM_ACC
			call TimerStart(NewTimerEx(id), EST_PING/STREAM_ACC, false, function StartStreamEx)
		endif
		
	endfunction

	private function init takes nothing returns nothing
		
		call ShowDestructable(gg_dest_B038_1303, false)
		call InitDest(gg_rct_InitArea, 0)
		call InitDest(gg_rct_InteriorArea, 0)
		call CreateTrack("war3mapImported\\TrackHUGE.mdx", 0, 0, 2050, 0)
		call CreateTrack("war3mapImported\\TrackHUGE.mdx", 0, 0, 20, 0)
		call ShowDestructable(gg_dest_B038_1303, true)
		call RegisterAnyClickEvent(function onClick)
		static if not USE_MEMORY_HACK then
			call OnMouseEvent(function onMouseDown, EVENT_MOUSE_DOWN)
			call OnMouseEvent(function onMouseUp, EVENT_MOUSE_UP)
		endif
		
	endfunction
	
endlibrary