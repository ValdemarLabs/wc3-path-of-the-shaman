library Inventory uses UnitIndexer, CharacterManager, UpgradeMenu
	
    ///! runtextmacro DECLARE_ARRAY_2D("", "InventoryContent", "SlotIndex", "8", "21")
    ///! runtextmacro DECLARE_ARRAY_2D("", "PanelPlatform", "ContextButton", "8", "7")
    ///! runtextmacro DECLARE_ARRAY_2D("", "PanelPlatform", "SlotMoveHighlight", "8", "20")
	
	globals
		public Inventory array UnitBag
		public Inventory array SlotBag
		public Inventory array PorterBag
		public Inventory array ExitBag
		public Inventory array SortBag
		public Inventory array ContextButtonBag
		public Inventory array ContextButtonIndex
		public Inventory array InventoryIndex
		public InventoryContent array ButtonSlot
		public InventoryContent array SlotIndex[4][21]
		public PanelPlatform array ContextButton[4][7]
		public PanelPlatform array SlotMoveHighlight[4][20]
		public timer array PickItemTimer
		public unit array PickItemTarget
		public integer array PickItemOrder
		unit LastSelection = null
	endglobals

    private function CreateNewSaveThread takes nothing returns nothing
        call CharacterManager_SaveData(GetEnumPlayer())
    endfunction
	
	struct InventoryContent extends array
		
		implement LinkedList
		
		Inventory parent
		PanelPlatform plat
		PanelPlatform rarity
		PanelPlatform cool
		PanelTextEx text
		
		integer index
		ItemObject object
		
	endstruct
	
	struct Inventory
		
		Panel panel
		InventoryContent contents
		PanelPlatform highlight
		PanelPlatform context
		PanelPlatform sort
		PanelPlatform exit
		PanelTextEx  gold
		
		unit main
		player play
		integer pid
		integer page
		integer index
		timer time
		timer dClick
		boolean open // context opened
		boolean moving // if item moving mode
		boolean socketing // if item socketing mode
		boolean visible // inventory opened
		
		static boolean skipDetect = false

		static constant real CONTEXT_X_CLOSE = -104.0
		static constant real CONTEXT_X_OPEN  = -201.0
		static constant real ANIM_SPEED = 10
		
		method getEmptySlot takes nothing returns integer
			
			local integer i = 0
			
			loop
				exitwhen i == 20 or SlotIndex[this][i].object == 0
				set i = i + 1
			endloop
			
			return i
		endmethod
		
		method getStackableSlot takes ItemObject object returns integer
			
			local integer i = 0
			
			loop
				exitwhen i == 20/* or SlotIndex[this][i].object == 0*/ or (SlotIndex[this][i].object.id == object.id and SlotIndex[this][i].object.charge < object.id.maxCharge)
				set i = i + 1
			endloop
			if i == 20 then
				return getEmptySlot()
			endif
			
			return i
		endmethod
		
		method selectSlot takes integer dex, integer data returns nothing
		
			local integer i = 0
			
			set open = true
			set index = dex
			call context.show(true)
			call highlight.show(true)
			call context.move(ButtonSlot[data].plat.xOffset-85, ButtonSlot[data].plat.yOffset-83, context.level)
			call highlight.move(ButtonSlot[data].plat.xOffset, ButtonSlot[data].plat.yOffset, 4)
			call highlight.refresh()
			call context.refresh()
			set i = 0
			loop
				exitwhen i == 5
				call ContextButton[this][i].show(true)
				call ContextButton[this][i].move(context.xOffset, context.yOffset+85-28*i, context.level+1)
				call ContextButton[this][i].refresh()
				set i = i + 1
			endloop
			
		endmethod
		
		method closeContextMenu takes nothing returns nothing
		
			local integer i = 0
			
			set open = false
			set index = -1
			call context.show(false)
			call highlight.show(false)
			set i = 0
			loop
				exitwhen i == 5
				call ContextButton[this][i].show(false)
				set i = i + 1
			endloop
			
		endmethod
		
		method verifyRequirements takes integer index, boolean print returns boolean
			
			local boolean b = true
			
			if UpgradeMenu_Main[pid].visible then
				return true
			endif
			if SlotIndex[this][index].object.id.reqCount > 0 then
				if b and SlotIndex[this][index].object.id.job != 0 then
					if GetUnitTypeId(MainUnit[pid]) != SlotIndex[this][index].object.id.job then
						if print then
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires class of " + GetObjectName(SlotIndex[this][index].object.id.job) + ".")
						endif
						set b = false
					endif
				endif
				if b and SlotIndex[this][index].object.reqLevel != 0 then
					if SlotIndex[this][index].object.id.category != Items.GEM and SlotIndex[this][index].object.id.category != Items.MISC and Level[pid] < SlotIndex[this][index].object.reqLevel then
						if print then
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires higher level (" + I2S(SlotIndex[this][index].object.reqLevel) + ").")
						endif
						set b = false
					endif
				endif
				if b and SlotIndex[this][index].object.id.reqStrength != 0 then
					if Strength[pid] < SlotIndex[this][index].object.id.reqStrength then
						if print then
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires higher strength (" + I2S(SlotIndex[this][index].object.id.reqStrength) + ").")
						endif
						set b = false
					endif
				endif
				if b and SlotIndex[this][index].object.id.reqDexterity != 0 then
					if Dexterity[pid] < SlotIndex[this][index].object.id.reqDexterity then
						if print then
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires higher dexterity (" + I2S(SlotIndex[this][index].object.id.reqDexterity) + ").")
						endif
						set b = false
					endif
				endif
				if b and SlotIndex[this][index].object.id.reqWisdom != 0 then
					if Wisdom[pid] < SlotIndex[this][index].object.id.reqWisdom then
						if print then
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires higher wisdom (" + I2S(SlotIndex[this][index].object.id.reqWisdom) + ").")
						endif
						set b = false
					endif
				endif
				if b and SlotIndex[this][index].object.id.reqFortitude != 0 then
					if Fortitude[pid] < SlotIndex[this][index].object.id.reqFortitude then
						call DisplayTimedTextToPlayer(play, 0, 0, 1., "Requires higher fortitude (" + I2S(SlotIndex[this][index].object.id.reqFortitude) + ").")
						set b = false
					endif
				endif
			endif
			
			return b
		endmethod
		
		public static method ApplyBonus takes Combatant c, ItemObject itm returns nothing
		
			local ItemSet iDex
			local integer bonusDex
			local real heal
			local integer vol
			local integer tier
			
			if itm.goldGiven > 0 then
				if Locale == c.owner then
					set vol = 150
				else
					set vol = 0
				endif
				call ItemBuySound.play(0, 0, 0, vol)
				call SetPlayerState(c.owner, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(c.owner, PLAYER_STATE_RESOURCE_GOLD)+itm.goldGiven)
			endif
			if itm.id.category == Items.RIGHT_HAND or itm.id.category == Items.LEFT_HAND and StringLength(itm.id.upgradeSfx) > 0 then
				if itm.upgradeLevel < 3 then
					set tier = 0
				elseif itm.upgradeLevel < 6 then
					set tier = 1
				elseif itm.upgradeLevel < 9 then
					set tier = 2
				elseif itm.upgradeLevel < 11 then
					set tier = 3
				elseif itm.upgradeLevel < 12 then
					set tier = 4
				else
					set tier = 5
				endif
				if itm.id.category == Items.LEFT_HAND then
					if c.upgradeSfx != null then
						call DestroyEffect(c.upgradeSfx)
					endif
					set c.upgradeSfx = AddSpecialEffectTarget("war3mapImported\\Upgrade_FX_" + itm.id.upgradeSfx + "_" + I2S(tier) + ".mdx", c.u, "weapon")
				else
					if c.upgradeSfx2 != null then
						call DestroyEffect(c.upgradeSfx2)
					endif
					set c.upgradeSfx2 = AddSpecialEffectTarget("war3mapImported\\Upgrade_FX_" + itm.id.upgradeSfx + "_" + I2S(tier) + ".mdx", c.u, "hand,right")
				endif
			endif
			call AddAttPoints(c.pid, 0, itm.strength)
			call AddAttPoints(c.pid, 1, itm.dexterity)
			call AddAttPoints(c.pid, 2, itm.wisdom)
			call AddAttPoints(c.pid, 3, itm.fortitude)
			call Regeneration.add(c.u, true, itm.hpRegen)
			call Regeneration.add(c.u, false, itm.spRegen)
			set c.physicDmgMin = c.physicDmgMin + itm.physicDmg
			set c.physicDmgMax = c.physicDmgMax + itm.physicDmg
			set c.physicDmgMin = c.physicDmgMin + itm.physicDmgMin
			set c.physicDmgMax = c.physicDmgMax + itm.physicDmgMax
			set c.physicDefense = c.physicDefense + itm.physicDefense
			set c.magicDmgMin = c.magicDmgMin + itm.magicDmg
			set c.magicDmgMax = c.magicDmgMax + itm.magicDmg
			set c.magicDmgMin = c.magicDmgMin + itm.magicDmgMin
			set c.magicDmgMax = c.magicDmgMax + itm.magicDmgMax
			set c.magicDefense = c.magicDefense + itm.magicDefense
			set c.attackRange = c.attackRange + itm.attackRange
			set c.blockRate = c.blockRate + itm.blockRate
			set c.criticalRate = c.criticalRate + itm.criticalRate
			set c.criticalPower = c.criticalPower + itm.criticalPower
			set c.evasionRate = c.evasionRate + itm.evasionRate
			set c.knockback = c.knockback + itm.knockback
			set c.knockbackResist = c.knockbackResist + itm.knockbackResist
			set c.interrupt = c.interrupt + itm.interrupt
			set c.interruptResist = c.interruptResist + itm.interruptResist
			set c.stun = c.stun + itm.stun
			set c.stunResist = c.stunResist + itm.stunResist
			
			if BuffBars[c.pid].has(5) then
				set heal = itm.hp * (1.+ExcellentRecoveryAmplification(c.pid))
			else
				set heal = itm.hp
			endif	
			set c.hp = c.hp + heal
			if heal > 0 then
				call DamageText_Show(I2S(R2I(heal)), 0, c.u, HEAL_R, HEAL_G, HEAL_B, TEXTTAG_NORMAL_SIZE)
			elseif heal < 0 then
				call DamageText_Show(I2S(R2I(-heal)), 0, c.u, NORMAL_DAMAGE_R, NORMAL_DAMAGE_G, NORMAL_DAMAGE_B, TEXTTAG_NORMAL_SIZE)
			endif
			set c.sp = c.sp + itm.sp
			if itm.sp > 0 then
				call DamageText_Show(I2S(R2I(itm.sp)), 0, c.u, MANA_R, MANA_G, MANA_B, TEXTTAG_NORMAL_SIZE)
			endif
			set c.hpMax = c.hpMax + itm.hpMax
			set c.spMax = c.spMax + itm.spMax
			set c.attackRate = c.attackRate - itm.aspd
			set c.fireElement = c.fireElement + itm.fireElement
			set c.fireElementResist = c.fireElementResist + itm.fireElementResist
			set c.waterElement = c.waterElement + itm.waterElement
			set c.waterElementResist = c.waterElementResist + itm.waterElementResist
			set c.earthElement = c.earthElement + itm.earthElement
			set c.earthElementResist = c.earthElementResist + itm.earthElementResist
			set c.windElement = c.windElement + itm.windElement
			set c.windElementResist = c.windElementResist + itm.windElementResist
			set c.holyElement = c.holyElement + itm.holyElement
			set c.darkElement = c.darkElement + itm.darkElement
			call SetUnitMoveSpeed(c.u, GetUnitMoveSpeed(c.u) + itm.mspd)
			
			if ItemSet.ItemIndex[itm.id] != 0 then
				set iDex = ItemSet.ItemIndex[itm.id]
				set bonusDex = ItemSet.ActiveIndex[c.pid].integer[iDex]
				if bonusDex < iDex.count then
					call AddAttPoints(c.pid, 0, iDex.bonus[bonusDex].strength)
					call AddAttPoints(c.pid, 1, iDex.bonus[bonusDex].dexterity)
					call AddAttPoints(c.pid, 2, iDex.bonus[bonusDex].wisdom)
					call AddAttPoints(c.pid, 3, iDex.bonus[bonusDex].fortitude)
					call Regeneration.add(c.u, true, iDex.bonus[bonusDex].hpRegen)
					call Regeneration.add(c.u, false, iDex.bonus[bonusDex].spRegen)
					set c.physicDmgMin = c.physicDmgMin + iDex.bonus[bonusDex].physicDmg
					set c.physicDmgMax = c.physicDmgMax + iDex.bonus[bonusDex].physicDmg
					set c.physicDefense = c.physicDefense + iDex.bonus[bonusDex].physicDefense
					set c.magicDmgMin = c.magicDmgMin + iDex.bonus[bonusDex].magicDmg
					set c.magicDmgMax = c.magicDmgMax + iDex.bonus[bonusDex].magicDmg
					set c.magicDefense = c.magicDefense + iDex.bonus[bonusDex].magicDefense
					set c.attackRange = c.attackRange + iDex.bonus[bonusDex].attackRange
					set c.blockRate = c.blockRate + iDex.bonus[bonusDex].blockRate
					set c.criticalRate = c.criticalRate + iDex.bonus[bonusDex].criticalRate
					set c.criticalPower = c.criticalPower + iDex.bonus[bonusDex].criticalPower
					set c.evasionRate = c.evasionRate + iDex.bonus[bonusDex].evasionRate
					set c.knockback = c.knockback + iDex.bonus[bonusDex].knockback
					set c.knockbackResist = c.knockbackResist + iDex.bonus[bonusDex].knockbackResist
					set c.interrupt = c.interrupt + iDex.bonus[bonusDex].interrupt
					set c.interruptResist = c.interruptResist + iDex.bonus[bonusDex].interruptResist
					set c.stun = c.stun + iDex.bonus[bonusDex].stun
					set c.stunResist = c.stunResist + iDex.bonus[bonusDex].stunResist
					set c.hp = c.hp + iDex.bonus[bonusDex].hp
					set c.sp = c.sp + iDex.bonus[bonusDex].sp
					set c.hpMax = c.hpMax + iDex.bonus[bonusDex].hpMax
					set c.spMax = c.spMax + iDex.bonus[bonusDex].spMax
					set c.attackRate = c.attackRate - iDex.bonus[bonusDex].aspd
					set c.fireElement = c.fireElement + iDex.bonus[bonusDex].fireElement
					set c.fireElementResist = c.fireElementResist + iDex.bonus[bonusDex].fireElementResist
					set c.waterElement = c.waterElement + iDex.bonus[bonusDex].waterElement
					set c.waterElementResist = c.waterElementResist + iDex.bonus[bonusDex].waterElementResist
					set c.earthElement = c.earthElement + iDex.bonus[bonusDex].earthElement
					set c.earthElementResist = c.earthElementResist + iDex.bonus[bonusDex].earthElementResist
					set c.windElement = c.windElement + iDex.bonus[bonusDex].windElement
					set c.windElementResist = c.windElementResist + iDex.bonus[bonusDex].windElementResist
					set c.holyElement = c.holyElement + iDex.bonus[bonusDex].holyElement
					set c.darkElement = c.darkElement + iDex.bonus[bonusDex].darkElement
					call SetUnitMoveSpeed(c.u, GetUnitMoveSpeed(c.u) + iDex.bonus[bonusDex].mspd)
					set ItemSet.ActiveIndex[c.pid].integer[iDex] = bonusDex+1
					if ItemSet.ItemIndex[Tooltips1[c.pid].itmObject.id] == ItemSet.ItemIndex[itm.id] then
						call Tooltips1[c.pid].setItem(Tooltips1[c.pid].itmObject)
					endif
				endif
			endif
			
			if c.hp > c.hpMax then
				set c.hp = c.hpMax
			endif
			if c.sp > c.spMax then
				set c.sp = c.spMax
			endif
			if Tooltips1[c.pid].control.visible then
				if Tooltips1[c.pid].skill != 0 then
					call Tooltips1[c.pid].setSkill(Tooltips1[c.pid].skill)
				elseif Tooltips1[c.pid].itmObject != 0 then
					call Tooltips1[c.pid].setItem(Tooltips1[c.pid].itmObject)
				endif
			endif
			
		endmethod
		
		public static method RemoveBonus takes Combatant c, ItemObject itm returns nothing
			
			local ItemSet iDex
			local ItemObject obj
			local integer bonusDex
			
			if itm.id.category == Items.RIGHT_HAND or itm.id.category == Items.LEFT_HAND and StringLength(itm.id.upgradeSfx) > 0 then
				if itm.id.category == Items.LEFT_HAND then
					if c.upgradeSfx != null then
						call DestroyEffect(c.upgradeSfx)
						set c.upgradeSfx = null
					endif
				else
					if c.upgradeSfx2 != null then
						call DestroyEffect(c.upgradeSfx2)
						set c.upgradeSfx2 = null
					endif
				endif
			endif
			call AddAttPoints(c.pid, 0, -itm.strength)
			call AddAttPoints(c.pid, 1, -itm.dexterity)
			call AddAttPoints(c.pid, 2, -itm.wisdom)
			call AddAttPoints(c.pid, 3, -itm.fortitude)
			call Regeneration.add(c.u, true, -itm.hpRegen)
			call Regeneration.add(c.u, false, -itm.spRegen)
			set c.physicDmgMin = c.physicDmgMin - itm.physicDmg
			set c.physicDmgMax = c.physicDmgMax - itm.physicDmg
			set c.physicDmgMin = c.physicDmgMin - itm.physicDmgMin
			set c.physicDmgMax = c.physicDmgMax - itm.physicDmgMax
			set c.physicDefense = c.physicDefense - itm.physicDefense
			set c.magicDmgMin = c.magicDmgMin - itm.magicDmg
			set c.magicDmgMax = c.magicDmgMax - itm.magicDmg
			set c.magicDmgMin = c.magicDmgMin - itm.magicDmgMin
			set c.magicDmgMax = c.magicDmgMax - itm.magicDmgMax
			set c.magicDefense = c.magicDefense - itm.magicDefense
			set c.attackRange = c.attackRange - itm.attackRange
			set c.blockRate = c.blockRate - itm.blockRate
			set c.criticalRate = c.criticalRate - itm.criticalRate
			set c.criticalPower = c.criticalPower - itm.criticalPower
			set c.evasionRate = c.evasionRate - itm.evasionRate
			set c.knockback = c.knockback - itm.knockback
			set c.knockbackResist = c.knockbackResist - itm.knockbackResist
			set c.interrupt = c.interrupt - itm.interrupt
			set c.interruptResist = c.interruptResist - itm.interruptResist
			set c.stun = c.stun - itm.stun
			set c.stunResist = c.stunResist - itm.stunResist
			
			set c.hp = c.hp - itm.hp
			set c.sp = c.sp - itm.sp
			set c.hpMax = c.hpMax - itm.hpMax
			set c.spMax = c.spMax - itm.spMax
			set c.attackRate = c.attackRate + itm.aspd
			set c.fireElement = c.fireElement - itm.fireElement
			set c.fireElementResist = c.fireElementResist - itm.fireElementResist
			set c.waterElement = c.waterElement - itm.waterElement
			set c.waterElementResist = c.waterElementResist - itm.waterElementResist
			set c.earthElement = c.earthElement - itm.earthElement
			set c.earthElementResist = c.earthElementResist - itm.earthElementResist
			set c.windElement = c.windElement - itm.windElement
			set c.windElementResist = c.windElementResist - itm.windElementResist
			set c.holyElement = c.holyElement - itm.holyElement
			set c.darkElement = c.darkElement - itm.darkElement
			call SetUnitMoveSpeed(c.u, GetUnitMoveSpeed(c.u) - itm.mspd)
			
			if ItemSet.ItemIndex[itm.id] != 0 then
				set iDex = ItemSet.ItemIndex[itm.id]
				set bonusDex = ItemSet.ActiveIndex[c.pid].integer[iDex]
				if bonusDex > 0 then
					//set obj = CharacterWindow_SlotObject[c.pid][itm.id.category]
					//if iDex != ItemSet.ItemIndex[obj.id] then
						set bonusDex = bonusDex-1
						set ItemSet.ActiveIndex[c.pid].integer[iDex] = bonusDex
						call AddAttPoints(c.pid, 0, -iDex.bonus[bonusDex].strength)
						call AddAttPoints(c.pid, 1, -iDex.bonus[bonusDex].dexterity)
						call AddAttPoints(c.pid, 2, -iDex.bonus[bonusDex].wisdom)
						call AddAttPoints(c.pid, 3, -iDex.bonus[bonusDex].fortitude)
						call Regeneration.add(c.u, true, -iDex.bonus[bonusDex].hpRegen)
						call Regeneration.add(c.u, false, -iDex.bonus[bonusDex].spRegen)
						set c.physicDmgMin = c.physicDmgMin - iDex.bonus[bonusDex].physicDmg
						set c.physicDmgMax = c.physicDmgMax - iDex.bonus[bonusDex].physicDmg
						set c.physicDefense = c.physicDefense - iDex.bonus[bonusDex].physicDefense
						set c.magicDmgMin = c.magicDmgMin - iDex.bonus[bonusDex].magicDmg
						set c.magicDmgMax = c.magicDmgMax - iDex.bonus[bonusDex].magicDmg
						set c.magicDefense = c.magicDefense - iDex.bonus[bonusDex].magicDefense
						set c.attackRange = c.attackRange - iDex.bonus[bonusDex].attackRange
						set c.blockRate = c.blockRate - iDex.bonus[bonusDex].blockRate
						set c.criticalRate = c.criticalRate - iDex.bonus[bonusDex].criticalRate
						set c.criticalPower = c.criticalPower - iDex.bonus[bonusDex].criticalPower
						set c.evasionRate = c.evasionRate - iDex.bonus[bonusDex].evasionRate
						set c.knockback = c.knockback - iDex.bonus[bonusDex].knockback
						set c.knockbackResist = c.knockbackResist - iDex.bonus[bonusDex].knockbackResist
						set c.interrupt = c.interrupt - iDex.bonus[bonusDex].interrupt
						set c.interruptResist = c.interruptResist - iDex.bonus[bonusDex].interruptResist
						set c.stun = c.stun - iDex.bonus[bonusDex].stun
						set c.stunResist = c.stunResist - iDex.bonus[bonusDex].stunResist
						set c.hp = c.hp - iDex.bonus[bonusDex].hp
						set c.sp = c.sp - iDex.bonus[bonusDex].sp
						set c.hpMax = c.hpMax - iDex.bonus[bonusDex].hpMax
						set c.spMax = c.spMax - iDex.bonus[bonusDex].spMax
						set c.attackRate = c.attackRate + iDex.bonus[bonusDex].aspd
						set c.fireElement = c.fireElement - iDex.bonus[bonusDex].fireElement
						set c.fireElementResist = c.fireElementResist - iDex.bonus[bonusDex].fireElementResist
						set c.waterElement = c.waterElement - iDex.bonus[bonusDex].waterElement
						set c.waterElementResist = c.waterElementResist - iDex.bonus[bonusDex].waterElementResist
						set c.earthElement = c.earthElement - iDex.bonus[bonusDex].earthElement
						set c.earthElementResist = c.earthElementResist - iDex.bonus[bonusDex].earthElementResist
						set c.windElement = c.windElement - iDex.bonus[bonusDex].windElement
						set c.windElementResist = c.windElementResist - iDex.bonus[bonusDex].windElementResist
						set c.holyElement = c.holyElement - iDex.bonus[bonusDex].holyElement
						set c.darkElement = c.darkElement - iDex.bonus[bonusDex].darkElement
						call SetUnitMoveSpeed(c.u, GetUnitMoveSpeed(c.u) - iDex.bonus[bonusDex].mspd)
						if ItemSet.ItemIndex[Tooltips1[c.pid].itmObject.id] == ItemSet.ItemIndex[itm.id] then
							call Tooltips1[c.pid].setItem(Tooltips1[c.pid].itmObject)
						endif
					//endif
				endif
			endif
			
			if c.hp > c.hpMax then
				set c.hp = c.hpMax
			endif
			if c.sp > c.spMax then
				set c.sp = c.spMax
			endif
			if Tooltips1[c.pid].control.visible then
				if Tooltips1[c.pid].skill != 0 then
					call Tooltips1[c.pid].setSkill(Tooltips1[c.pid].skill)
				elseif Tooltips1[c.pid].itmObject != 0 then
					call Tooltips1[c.pid].setItem(Tooltips1[c.pid].itmObject)
				endif
			endif
			
		endmethod
		
		method dropItemFromSlot takes integer slot, boolean restoreObject returns boolean
		
			local InventoryContent node = SlotIndex[this][slot]
			local integer data
			local integer i
			
			if node.object != 0 then
				if Tooltips1[pid].control.visible and Tooltips1[pid].itmObject == node.object then
					call Tooltips1[pid].show(false)
					set Tooltips1[pid].itmObject = -1
					call Tooltips2[pid].show(false)
					set Tooltips2[pid].itmObject = -1
				endif
				if ShortcutBar_SkillSelection[pid].visible then
					call ShortcutBar_SkillSelection[pid].clear()
					set ShortcutBar_SelectIndex[pid] = -1
					call ShortcutBar_SkillSelection[pid].show(false)
				endif
				set i = 0
				loop
					exitwhen i == 10
					set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
					if ShortcutBar_ButtonType[data] == 2 and ShortcutBar_ButtonTarget[data] == slot then
						call ShortcutBar_ChargeText[pid][i].show(false)
						set ShortcutBar_Button[pid][i].texture = 'BSAL'
						set ShortcutBar_ButtonType[data] = 0
						call ShortcutBar_Button[pid][i].refresh()
						call ShortcutBar_PutToCooldown(pid, i, 0.0001, 0.0001)
					endif
					set i = i + 1
				endloop
				if restoreObject then
					call node.object.move(GetUnitX(main), GetUnitY(main))
					call node.object.show(true)
				else
					call node.object.destroy()
				endif
				set node.object = 0
				set node.plat.texture = 'BSAL'
				call node.rarity.show(false)
				call node.plat.show(false)
				call node.text.show(false)
				return true
			endif
			
			return false
		endmethod
		
		method useItemAtSlot takes integer index returns boolean
		
			local integer i
			local integer j
			local integer data
			local real dur
			local ItemObject obj
			
			if UnitAlive(MainUnit[pid]) then
				if SlotIndex[this][index].object.id.category < Items.CONSUMABLE then
					//call DisplayTimedTextToPlayer(play, 0, 0, 3., "Item equipped: " + SlotIndex[this][index].object.id.name + " (" + QualityNames[SlotIndex[this][index].object.quality] + ")")
					if UpgradeMenu_Main[pid].visible then
						if UpgradeMenu_EffectAnimation[pid] == 0 and UpgradeMenu_SetItem(pid, 0, SlotIndex[this][index].object) then
							set obj = SlotIndex[this][index].object
							call dropItemFromSlot(index, true)
							call obj.show(false)
							call closeContextMenu()
						endif
					else
						call CharacterWindow_Attach(pid, index)
						call closeContextMenu()
					endif
				elseif SlotIndex[this][index].object.id.category == Items.GEM then
					if UpgradeMenu_Main[pid].visible then
						call DisplayTimedTextToPlayer(play, 0, 0, 5., "Unable to use this item when upgrading.")
					else
						call enableItemSocket(not socketing)
					endif
				elseif SlotIndex[this][index].object.id.category == Items.SCROLL then
					if UpgradeMenu_Main[pid].visible then
						call DisplayTimedTextToPlayer(play, 0, 0, 5., "Unable to use this item when upgrading.")
					else
						call Gate_UseScroll(pid, index)
					endif
				elseif SlotIndex[this][index].object.id.category == Items.MISC and SlotIndex[this][index].object.id.class != "Misc" then
					if UpgradeMenu_Main[pid].visible then
						set obj = ItemObject.create(SlotIndex[this][index].object.id, 1, 0, WorldBounds.maxX, WorldBounds.maxY)
						if UpgradeMenu_EffectAnimation[pid] == 0 and UpgradeMenu_SetItem(pid, SlotIndex[this][index].object.id.strength, obj) then
							if SlotIndex[this][index].object.charge > 1 then
								set SlotIndex[this][index].object.charge = SlotIndex[this][index].object.charge - 1
								call SlotIndex[this][index].text.setText(I2S(SlotIndex[this][index].object.charge), FONTSTYLE_FrizQTShaded)
								if SlotIndex[this][index].object.charge > 9 then
									call SlotIndex[this][index].text.move(SlotIndex[this][index].plat.xOffset+10, SlotIndex[this][index].text.yOffset, SlotIndex[this][index].text.level)
								else
									call SlotIndex[this][index].text.move(SlotIndex[this][index].plat.xOffset+15, SlotIndex[this][index].text.yOffset, SlotIndex[this][index].text.level)
								endif
								call SlotIndex[this][index].text.refresh()
							else
								call dropItemFromSlot(index, false)
							endif
							call closeContextMenu()
						endif
					else
						call DisplayTimedTextToPlayer(play, 0, 0, 5., "Use this item with the uprade menu open to insert.")
					endif
				elseif SlotIndex[this][index].object.id.category == Items.CONSUMABLE then
					if not SlotIndex[this][index].object.id.onCooldown() then
						set dur = SlotIndex[this][index].object.cooldown
						set i = 0
						loop
							exitwhen i == 20
							if i != index and SlotIndex[this][i].object.id.cooldownGroup == SlotIndex[this][index].object.id.cooldownGroup then
								call CooldownAnimation.create(SlotIndex[this][i].cool, dur, dur)
								call SlotIndex[this][i].object.id.startCooldown(dur)
							endif
							set i = i + 1
						endloop
						set i = 0
						loop
							exitwhen i == 10
							set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
							if ShortcutBar_ButtonType[data] == 2 then
								if SlotIndex[this][ShortcutBar_ButtonTarget[data]].object.id.cooldownGroup == SlotIndex[this][index].object.id.cooldownGroup then
									call ShortcutBar_PutToCooldown(pid, i, dur, dur)
								endif
							endif
							set i = i + 1
						endloop
						call SlotIndex[this][index].object.id.startCooldown(dur)
						if SlotIndex[this][index].object.charge > 0 then
							call ApplyBonus(Fighter[pid], SlotIndex[this][index].object)
						endif
						if SlotIndex[this][index].object.charge > 1 then
							call CooldownAnimation.create(SlotIndex[this][index].cool, dur, dur)
							set SlotIndex[this][index].object.charge = SlotIndex[this][index].object.charge - 1
							call SlotIndex[this][index].text.setText(I2S(SlotIndex[this][index].object.charge), FONTSTYLE_FrizQTShaded)
							if SlotIndex[this][index].object.charge > 9 then
								call SlotIndex[this][index].text.move(SlotIndex[this][index].plat.xOffset+10, SlotIndex[this][index].text.yOffset, SlotIndex[this][index].text.level)
							else
								call SlotIndex[this][index].text.move(SlotIndex[this][index].plat.xOffset+15, SlotIndex[this][index].text.yOffset, SlotIndex[this][index].text.level)
							endif
							call SlotIndex[this][index].text.refresh()
							set i = 0
							loop
								exitwhen i == 10
								set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
								if ShortcutBar_ButtonType[data] == 2 and ShortcutBar_ButtonTarget[data] == index then
									call ShortcutBar_ChargeText[pid][i].setText(I2S(SlotIndex[this][index].object.charge), FONTSTYLE_FrizQTShaded)
									call ShortcutBar_ChargeText[pid][i].refresh()
								endif
								set i = i + 1
							endloop
							if Tooltips1[pid].control.visible and Tooltips1[pid].itmObject == SlotIndex[this][index].object then
								call Tooltips1[pid].setItem(SlotIndex[this][index].object)
							endif
						else
							set j = 0
							loop
								exitwhen j == 20
								if j != index and SlotIndex[this][j].object.id == SlotIndex[this][index].object.id then
									exitwhen true
								endif
								set j = j + 1
							endloop
							if j < 20 then
								set i = 0
								loop
									exitwhen i == 10
									set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
									if ShortcutBar_ButtonType[data] == 2 and ShortcutBar_ButtonTarget[data] == index then
										set ShortcutBar_ButtonTarget[data] = j
										call ShortcutBar_ChargeText[pid][i].setText(I2S(SlotIndex[this][j].object.charge), FONTSTYLE_FrizQTShaded)
										call ShortcutBar_ChargeText[pid][i].refresh()
									endif
									set i = i + 1
								endloop
							endif
							call dropItemFromSlot(index, false)
							call closeContextMenu()
							return false
						endif
					else
						call DisplayTimedTextToPlayer(play, 0, 0, 1., "Still on cooldown.")
					endif
				endif
			endif
			
			return true
		endmethod
		
		method moveItemToSlot takes integer from, integer to returns boolean
		
			local InventoryContent node1
			local InventoryContent node2
			local ItemObject object
			local integer charge
			local integer skin
			local integer data
			local integer i
			local real cooldown
			local PanelPlatform cool
			
			if from > -1 and to > -1 and from < 20 and to < 20 and from != to then
				if ShortcutBar_SkillSelection[pid].visible then
					call ShortcutBar_SkillSelection[pid].clear()
					set ShortcutBar_SelectIndex[pid] = -1
					call ShortcutBar_SkillSelection[pid].show(false)
				endif
				
				set node1 = SlotIndex[this][from]
				set node2 = SlotIndex[this][to]
				set object = node1.object
				if node1.object.id.category == Items.CONSUMABLE and node2.object.id.category == Items.CONSUMABLE and /*
					*/ node2.object.charge < node2.object.id.maxCharge and node1.object.id == node2.object.id then
					set charge = node2.object.id.maxCharge-node2.object.charge
					if charge > node1.object.charge then
						set node2.object.charge = node2.object.charge + node1.object.charge
						call dropItemFromSlot(from, false)
					else
						set node2.object.charge = node2.object.id.maxCharge
						set node1.object.charge = node1.object.charge - charge
						if node1.object.charge > 9 then
							call node1.text.move(node1.plat.xOffset+10, node1.text.yOffset, node1.text.level)
						else
							call node1.text.move(node1.plat.xOffset+15, node1.text.yOffset, node1.text.level)
						endif
						call node1.text.setText(I2S(node1.object.charge), FONTSTYLE_FrizQTShaded)
						call node1.text.refresh()
					endif
					if node2.object.charge > 9 then
						call node2.text.move(node2.plat.xOffset+10, node2.text.yOffset, node2.text.level)
					else
						call node2.text.move(node2.plat.xOffset+15, node2.text.yOffset, node2.text.level)
					endif
					call node2.text.setText(I2S(node2.object.charge), FONTSTYLE_FrizQTShaded)
					call node2.text.refresh()
					set i = 0
					loop
						exitwhen i == 10
						set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
						if ShortcutBar_ButtonType[data] == 2 then
							if ShortcutBar_ButtonTarget[data] == from then
								call ShortcutBar_ChargeText[pid][i].setText(I2S(node1.object.charge), FONTSTYLE_FrizQTShaded)
								call ShortcutBar_ChargeText[pid][i].refresh()
							elseif ShortcutBar_ButtonTarget[data] == to then
								call ShortcutBar_ChargeText[pid][i].setText(I2S(node2.object.charge), FONTSTYLE_FrizQTShaded)
								call ShortcutBar_ChargeText[pid][i].refresh()
							endif
						endif
						set i = i + 1
					endloop
				else
					set i = 0
					loop
						exitwhen i == 10
						set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
						if ShortcutBar_ButtonType[data] == 2 then
							if ShortcutBar_ButtonTarget[data] == from then
								set ShortcutBar_ButtonTarget[data] = to
							elseif ShortcutBar_ButtonTarget[data] == to then
								set ShortcutBar_ButtonTarget[data] = from
							endif
						endif
						set i = i + 1
					endloop
					
					set cool = node1.cool
					set skin = node1.plat.texture
					
					set node1.object = node2.object
					set node1.cool = node2.cool
					set node1.plat.texture = node2.plat.texture
					call SetUnitVertexColor(node1.rarity.dummy, RarityColorR[node2.object.rarity], RarityColorG[node2.object.rarity], RarityColorB[node2.object.rarity], RARITY_BORDER_ALPHA)
					if node1.object.id.maxCharge > 0 then
						if node1.object.charge > 9 then
							call node1.text.move(node1.plat.xOffset+10, node1.text.yOffset, node1.text.level)
						else
							call node1.text.move(node1.plat.xOffset+15, node1.text.yOffset, node1.text.level)
						endif
						call node1.text.setText(I2S(node1.object.charge), FONTSTYLE_FrizQTShaded)
						call node1.text.show(true)
						call node1.text.refresh()
					else
						call node1.text.show(false)
					endif
					call node1.plat.show(node1.object != 0)
					call node1.rarity.show(node1.object != 0)
					
					set node2.object = object
					set node2.cool = cool
					call SetUnitVertexColor(node2.rarity.dummy, RarityColorR[object.rarity], RarityColorG[object.rarity], RarityColorB[object.rarity], RARITY_BORDER_ALPHA)
					if object == 0 then
						set node2.plat.texture = 'BSAL'
					else
						set node2.plat.texture = skin
					endif
					if node2.object.id.maxCharge > 0 then
						if node2.object.charge > 9 then
							call node2.text.move(node2.plat.xOffset+10, node2.text.yOffset, node2.text.level)
						else
							call node2.text.move(node2.plat.xOffset+15, node2.text.yOffset, node2.text.level)
						endif
						call node2.text.setText(I2S(node2.object.charge), FONTSTYLE_FrizQTShaded)
						call node2.text.show(true)
						call node2.text.refresh()
					else
						call node2.text.show(false)
					endif
					call node2.plat.show(node2.object != 0)
					call node2.rarity.show(node2.object != 0)
					
					call node1.cool.move(node1.plat.xOffset, node1.plat.yOffset, node1.cool.level)
					call node2.cool.move(node2.plat.xOffset, node2.plat.yOffset, node2.cool.level)
					
					call node1.plat.refresh()
					call node2.plat.refresh()
					call node1.rarity.refresh()
					call node2.rarity.refresh()
					call node1.cool.refresh()
					call node2.cool.refresh()
					if Locale == play then
						call InventorySwapSound.play(0, 0, 0, 100)
					else
						call InventorySwapSound.play(0, 0, 0, 0)
					endif
				endif
				call selectSlot(to, GetUnitUserData(node2.plat.dummy))
				
				return true
			else
				call closeContextMenu()
			endif
			
			return false
		endmethod
		
		method sortContent takes boolean repeat returns nothing
			
			local integer i = 0
			local integer j
			local integer lowestIndex
			local integer lowestCategory
			local integer lowestLevel
			local integer lowestId
			local ItemObject obj
			
			loop
				exitwhen i >= 20
				set lowestIndex = 50
				set obj = SlotIndex[this][i].object
				if obj > 0 then
					set lowestCategory = obj.id.category
					set lowestLevel = obj.reqLevel
					set lowestId = obj.idToInt
				else
					set lowestCategory = 50
					set lowestLevel = MAXIMUM_LEVEL + 1
					set lowestId = 9999
				endif
				set j = i + 1
				loop
					exitwhen j >= 20
					set obj = SlotIndex[this][j].object
					if obj > 0 then
						if obj.id.category < lowestCategory then
							set lowestCategory = obj.id.category
							set lowestIndex = j
						elseif obj.id.category == lowestCategory then
							if obj.idToInt < lowestId then
								set lowestId = obj.idToInt
								set lowestIndex = j
							elseif obj.idToInt == lowestId then
								if obj.reqLevel < lowestLevel then
									set lowestLevel = obj.reqLevel
									set lowestIndex = j
								endif
							endif
						endif
					endif
					set j = j + 1
				endloop
				if lowestIndex < 50 and i != lowestIndex then
					call moveItemToSlot(lowestIndex, i)
				endif
				set i = i + 1
			endloop
			call enableItemMove(false)
			call enableItemSocket(false)
			call closeContextMenu()
			if repeat then
				call sortContent(false)
			endif
			
		endmethod
		
		method addItemToSlot takes ItemObject object, integer slot returns boolean
			
			local InventoryContent node
			local integer id
			local integer i
			local integer data
			
			if object <= 0 then
				return false
			endif
			if ShortcutBar_SkillSelection[pid].visible then
				call ShortcutBar_SkillSelection[pid].clear()
				set ShortcutBar_SelectIndex[pid] = -1
				call ShortcutBar_SkillSelection[pid].show(false)
			endif
			set node = SlotIndex[this][slot]
			loop
				exitwhen node.index == 20
				if node.object == 0 then
					set node.object = ItemObject.duplicate(object, GetUnitX(main), GetUnitY(main))
					set node.object.charge = 0
					set node.plat.texture = object.id.texture
					call node.object.show(false)
					call node.plat.show(true)
					call node.plat.refresh()
					call SetUnitVertexColor(node.rarity.dummy, RarityColorR[node.object.rarity], RarityColorG[node.object.rarity], RarityColorB[node.object.rarity], RARITY_BORDER_ALPHA)
					call node.rarity.show(true)
					call node.rarity.refresh()
					if node.object.id.onCooldown() then
						call CooldownAnimation.create(node.cool, node.object.id.getCooldown(), node.object.cooldown)
						call node.cool.refresh()
					endif
					if socketing then
						call enableItemSocket(false)
					endif
				endif
				if node.object.charge + object.charge < node.object.id.maxCharge then
					set node.object.charge = node.object.charge + object.charge
					set object.charge = 0
				else
					if node.object.id.maxCharge > 0 then
						set object.charge = object.charge-(node.object.id.maxCharge-node.object.charge)
					else
						set object.charge = object.charge-1
					endif
					set node.object.charge = node.object.id.maxCharge
				endif
				if node.object.id.maxCharge > 0 then
					if node.object.charge > 9 then
						call node.text.move(node.plat.xOffset+10, node.text.yOffset, node.text.level)
					else
						call node.text.move(node.plat.xOffset+15, node.text.yOffset, node.text.level)
					endif
					call node.text.setText(I2S(node.object.charge), FONTSTYLE_FrizQTShaded)
					call node.text.show(true)
					call node.text.refresh()
					set i = 0
					loop
						exitwhen i == 10
						set data = GetUnitUserData(ShortcutBar_Button[pid][i].dummy)
						if ShortcutBar_ButtonType[data] == 2 then
							if ShortcutBar_ButtonTarget[data] == node.index then
								call ShortcutBar_ChargeText[pid][i].setText(I2S(node.object.charge), FONTSTYLE_FrizQTShaded)
								call ShortcutBar_ChargeText[pid][i].refresh()
							endif
						endif
						set i = i + 1
					endloop
					if Tooltips1[pid].control.visible and Tooltips1[pid].itmObject == node.object then
						call Tooltips1[pid].setItem(node.object)
					endif
				else
					call node.text.show(false)
				endif
				if not IsDataLoading and not UpgradeMenu_Main[pid].visible and node.object.id.category < 11 then
					set id = GetPlayerId(play)
					if CharacterWindow_SlotObject[id][node.object.id.category] == 0 then
						//call CharacterWindow_Attach(id, node.index)
						//call useItemAtSlot(node.index)
						if verifyRequirements(node.index, false) then
							call useItemAtSlot(node.index)
						endif
					endif
				endif
				exitwhen object.charge <= 0
				set node = SlotIndex[this][getStackableSlot(object)]
			endloop
			if node.index == 20 then
				call DisplayTimedTextToPlayer(play, 0, 0, 1., "Inventory is full.")
				call object.move(GetUnitX(object.object), GetUnitY(object.object))
				return false
			else
				call object.destroy()
				return true
			endif
			
		endmethod
		
		method addItem takes ItemObject object returns boolean
			if object.id.category == Items.CONSUMABLE or (object.id.category == Items.MISC and object.id.maxCharge > 0) then
				return addItemToSlot(object, getStackableSlot(object))
			else
				return addItemToSlot(object, getEmptySlot())
			endif
		endmethod
		
		method addItemEx takes unit u returns boolean
			return addItem(ItemObject[u])
		endmethod
		
		method addItemCreate takes Items id, integer amount, integer quality returns boolean
			return addItem(ItemObject.create(id, amount, quality, GetUnitX(main), GetUnitY(main)))
		endmethod
		
		method enableItemMove takes boolean b returns nothing
			
			local integer i
			
			if b then
				call context.show(false)
				set i = 0
				loop
					exitwhen i == 5
					call ContextButton[this][i].show(false)
					set i = i + 1
				endloop
				call enableItemSocket(false)
				set moving = true
				set socketing = false
				set i = 0
				loop
					exitwhen i == 20
					if i != index then
						call SlotIndex[this][i].plat.show(true)
						call SlotMoveHighlight[this][i].show(true)
						call SlotMoveHighlight[this][i].setColor(0, 255, 0, 255)
						call SlotIndex[this][i].plat.refresh()
						call SlotMoveHighlight[this][i].refresh()
					endif
					set i = i + 1
				endloop
			elseif moving then
				set moving = false
				set i = 0
				loop
					exitwhen i == 20
					call SlotIndex[this][i].plat.show(SlotIndex[this][i].object != 0)
					call SlotMoveHighlight[this][i].show(false)
					set i = i + 1
				endloop
				call highlight.move(SlotIndex[this][index].plat.xOffset, SlotIndex[this][index].plat.yOffset, 4)
				call highlight.refresh()
			endif
			
		endmethod
		
		method enableItemSocket takes boolean b returns nothing
			
			local integer i
			local boolean available
			
			if b then
				call context.show(false)
				set i = 0
				loop
					exitwhen i == 5
					call ContextButton[this][i].show(false)
					set i = i + 1
				endloop
				call enableItemMove(false)
				set socketing = true
				set moving = false
				set available = false
				set i = 0
				loop
					exitwhen i == 20
					if i != index and SlotIndex[this][i].object.id.category < Items.CONSUMABLE and SlotIndex[this][i].object.socketCountMax > 0 and SlotIndex[this][i].object.socketCount < SlotIndex[this][i].object.socketCountMax then
						if SlotIndex[this][i].object.reqLevel >= SlotIndex[this][index].object.reqLevel then
							set available = true
							call SlotIndex[this][i].plat.show(true)
							call SlotMoveHighlight[this][i].show(true)
							call SlotMoveHighlight[this][i].setColor(255, 255, 0, 255)
							call SlotIndex[this][i].plat.refresh()
							call SlotMoveHighlight[this][i].refresh()
						endif
					endif
					set i = i + 1
				endloop
				if not available then
					call enableItemSocket(false)
					call DisplayTimedTextToPlayer(play, 0, 0, 5., "No item is available for socketing!")
				endif
			elseif socketing then
				set socketing = false
				set i = 0
				loop
					exitwhen i == 20
					call SlotIndex[this][i].plat.show(SlotIndex[this][i].object != 0)
					call SlotMoveHighlight[this][i].show(false)
					set i = i + 1
				endloop
				call highlight.move(SlotIndex[this][index].plat.xOffset, SlotIndex[this][index].plat.yOffset, 4)
				call highlight.refresh()
			endif
			
		endmethod
		
		method show takes boolean b returns nothing
			if IsKeyVerified[pid] or not b then
				if b != visible then
					set visible = b
					if b then
						if Locale == play then
							call TooltipsDisplaySound.play(0, 0, 0, 100)
						else
							call TooltipsDisplaySound.play(0, 0, 0, 0)
						endif
					else
						call enableItemMove(false)
						call enableItemSocket(false)
						call closeContextMenu()
					endif
					call panel.show(b)
				endif
			endif
		endmethod
		
		static method create takes unit whichUnit returns thistype
			
			local thistype this = allocate()
			local integer index = -1
			local integer i
			local integer j
			local integer data
			local InventoryContent node
			local BJObjectId id = 'eIP0'
			
			set play = GetOwningPlayer(whichUnit)
			set panel = Panel.create(play, 'e00F', 'B00V', 448.0, -100, 0)
			//set panel = Panel.create('h00B', 'B005', 560.0, -135, 0)
			set panel.scale = 0.9
			set highlight = PanelPlatform.create(panel, 'e008', 0, 0, 0, 4)
			call highlight.show(false)
			set contents = InventoryContent.createNode()
			set main = whichUnit
			set pid = GetPlayerId(play)
			set InventoryIndex[pid] = this
			set index = -1
			set time = NewTimerEx(this)
			set dClick = NewTimerEx(this)
			set open = false
			set visible = true
			set moving = false
			set context = PanelPlatform.create(panel, 'e00B', 'B00R', CONTEXT_X_CLOSE, -24.0, 6)
			call context.show(false)
			set sort = PanelPlatform.create(panel, 'e02J', 'B01F', 116, 96, 1)
			set sort.scale = 0.405
			set exit = PanelPlatform.create(panel, 'e001', 0, 127.5, 130.0, 1)
			set exit.scale = 0.7
			call exit.setColor(255, 255, 255, 0)
			set UnitBag[GetUnitUserData(main)] = this
			set ExitBag[GetUnitUserData(exit.dummy)] = this
			set SortBag[GetUnitUserData(sort.dummy)] = this
			set gold = PanelTextEx.create(panel, "0", FONTSTYLE_FrizQTShaded, -120, 96, 1)
			set gold.scale = 0.3
			
			set i = 0
			loop
				exitwhen i > 3
				set j = 0
				loop
					exitwhen j > 4
					set index = index + 1
					set id = id.plus_1()
					set node = InventoryContent.allocate()
					set node.parent = this
					set node.plat = PanelPlatform.create(panel, id, 'BSAL', -115.0+54.5*j, 52.0-53.5*i, 1)
					set node.plat.scale = 0.8
					set node.rarity = PanelPlatform.create(panel, 'e00Y', 0, node.plat.xOffset, node.plat.yOffset, 2)
					set node.rarity.scale = 0.8
					set node.text = PanelTextEx.create(panel, "", FONTSTYLE_FrizQTShaded, node.plat.xOffset+15, node.plat.yOffset-17, 5)
					set node.text.scale = 0.3
					call node.rarity.show(false)
					call node.plat.show(false)
					call node.text.show(false)
					set SlotMoveHighlight[this][index] = PanelPlatform.create(panel, 'e008', 0, node.plat.xOffset, node.plat.yOffset, 4)
					call SlotMoveHighlight[this][index].setColor(0, 255, 0, 255)
					call SlotMoveHighlight[this][index].show(false)
					set node.index = index
					set node.object = 0
					set node.cool = PanelPlatform.create(panel, 'e007', 'BSAL', node.plat.xOffset, node.plat.yOffset, 3)
					set node.cool.scale = 0.85
					call node.cool.setColor(0, 0, 0, 155)
					call node.cool.show(false)
					call contents.insertNode(node)
					set data = GetUnitUserData(node.plat.dummy)
					set SlotBag[data] = this
					set ButtonSlot[data] = node
					set SlotIndex[this][index] = node
					set j = j + 1
				endloop
				set i = i + 1
			endloop
			set SlotIndex[this][20].index = 20 // end of list
			
			set id = 'eCB0'
			set i = 0
			loop
				exitwhen i == 5
				set id = id.plus_1()
				set ContextButton[this][i] = PanelPlatform.create(panel, id, 'B099', -200.0, 59.0-28.0*i, 0)
				call ContextButton[this][i].setColor(255, 255, 255, 64)
				call ContextButton[this][i].show(false)
				set ContextButtonBag[GetUnitUserData(ContextButton[this][i].dummy)] = this
				set ContextButtonIndex[GetUnitUserData(ContextButton[this][i].dummy)] = i+1
				set i = i + 1
			endloop
			
			return this
		endmethod
		
		private static method onSelect takes nothing returns boolean
		
			local unit u = GetTriggerUnit()
			local integer data = GetUnitUserData(u)
			local integer data2
			local integer charge
			local integer i
			local real cool
			local boolean b
			local thistype this
			local InventoryContent slot
			local ItemObject object
			
			if ExitBag[data] != 0 then
				set this = ExitBag[data]
				call show(false)
				if Locale == play then
					call SelectUnit(u, false)
					call SelectUnit(Controller[pid], true)
				endif
			elseif SortBag[data] != 0 then
				set this = SortBag[data]
				call sortContent(true)
				if Locale == play then
					call SelectUnit(u, false)
					call SelectUnit(Controller[pid], true)
				endif
			elseif SlotBag[data] != 0 then
				set this = SlotBag[data]
				if ButtonSlot[data].object != -1 then
					if moving then
						if moveItemToSlot(index, ButtonSlot[data].index) then
							set index = ButtonSlot[data].index
						endif
						call enableItemMove(false)
					elseif socketing then
						set object = SlotIndex[this][index].object
						if ButtonSlot[data].object.socket(object) then
							call DisplayTimedTextToPlayer(play, 0, 0, 5., "The gem has been inserted.")
							call dropItemFromSlot(index, true)
							call object.show(false)
							if Tooltips1[pid].control.visible and Tooltips1[pid].itmObject == ButtonSlot[data].object then
								call Tooltips1[pid].setItem(ButtonSlot[data].object)
							endif
							if Locale == play then
								call ItemSocketSound.play(0, 0, 0, 135)
							else
								call ItemSocketSound.play(0, 0, 0, 0)
							endif
							call ForForce(bj_FORCE_PLAYER[pid], function CreateNewSaveThread)
						endif
						set index = ButtonSlot[data].index
						call enableItemSocket(false)
						call selectSlot(index, data)
					else
						if index != ButtonSlot[data].index then
							if visible then
								set index = ButtonSlot[data].index
								call selectSlot(index, data)
								call TimerStart(dClick, DOUBLE_CLICK_WAIT_TIME, false, null)
							endif
						else
							if TimerGetRemaining(dClick) > 0.01 then
								if ShopUI[pid].visible and ShopMerchants_CurrentMerchant[pid] != null then
									if not SlotIndex[this][index].object.id.onCooldown() then
										if Locale == play then
											call InventorySellSound.play(0, 0, 0, 100)
										else
											call InventorySellSound.play(0, 0, 0, 0)
										endif
										set charge = SlotIndex[this][index].object.charge
										if charge == 0 then
											set charge = 1
										endif
										call SetPlayerState(play, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(play, PLAYER_STATE_RESOURCE_GOLD)+SlotIndex[this][index].object.gold*charge)
										call ShopUI[pid].addItem(ShopUI[pid].clist.sellItem(SlotIndex[this][index].object))
										call dropItemFromSlot(index, false)
										call enableItemMove(false)
										call closeContextMenu()
										//set SavingPlayerID = pid
										//call ExecuteFunc("CreateNewSaveThreadEx")
									else
										call DisplayTimedTextToPlayer(play, 0, 0, 1., "Still on cooldown.")
									endif
								elseif verifyRequirements(index, true) then
									call TimerStart(dClick, DOUBLE_CLICK_WAIT_TIME, false, null)
									call useItemAtSlot(index)
								endif
							else
								call closeContextMenu()
							endif
						endif
					endif
				endif
				if Locale == play then
					call SelectUnit(u, false)
					call SelectUnit(Controller[pid], true)
				endif
			elseif ContextButtonBag[data] != 0 then
				set this = ContextButtonBag[data]
				if UnitAlive(MainUnit[pid]) then
					if ContextButtonIndex[data] == 1 then // Use
						if verifyRequirements(index, true) then
							call enableItemMove(false)
							call useItemAtSlot(index)
						endif
					elseif ContextButtonIndex[data] == 2 then // move
						call enableItemMove(not moving)
					elseif ContextButtonIndex[data] == 3 then // drop
						if not SlotIndex[this][index].object.id.onCooldown() then
							call dropItemFromSlot(index, true)
							call enableItemMove(false)
							call enableItemSocket(false)
							call closeContextMenu()
							if Locale == play then
								call InventoryDropSound.play(0, 0, 0, 100)
							else
								call InventoryDropSound.play(0, 0, 0, 0)
							endif
							//set SavingPlayerID = pid
							//call ExecuteFunc("CreateNewSaveThreadEx")
						else
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Still on cooldown.")
						endif
					elseif ContextButtonIndex[data] == 4 then // sell
						if ShopUI[pid].visible and ShopMerchants_CurrentMerchant[pid] != null then
							if not SlotIndex[this][index].object.id.onCooldown() then
								if Locale == play then
									call InventorySellSound.play(0, 0, 0, 100)
								else
									call InventorySellSound.play(0, 0, 0, 0)
								endif
								set charge = SlotIndex[this][index].object.charge
								if charge == 0 then
									set charge = 1
								endif
								call SetPlayerState(play, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(play, PLAYER_STATE_RESOURCE_GOLD)+SlotIndex[this][index].object.gold*charge)
								//call SetPlayerState(play, PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(play, PLAYER_STATE_RESOURCE_LUMBER)+SlotIndex[this][index].object.lumber*charge)
								call ShopUI[pid].addItem(ShopUI[pid].clist.sellItem(SlotIndex[this][index].object))
								call dropItemFromSlot(index, false)
								call enableItemMove(false)
								call enableItemSocket(false)
								call closeContextMenu()
								//set SavingPlayerID = pid
								//call ExecuteFunc("CreateNewSaveThreadEx")
							else
								call DisplayTimedTextToPlayer(play, 0, 0, 1., "Still on cooldown.")
							endif
						else
							call DisplayTimedTextToPlayer(play, 0, 0, 1., "Must select a merchant first.")
						endif
					elseif ContextButtonIndex[data] == 5 then
						call enableItemMove(false)
						call closeContextMenu()
					endif
				else
					call DisplayTimedTextToPlayer(play, 0, 0, 1., "You are dead.")
				endif
				if Locale == play then
					call SelectUnit(u, false)
					call SelectUnit(Controller[pid], true)
				endif
			endif
			set u = null
			
			return false
		endmethod
		
		private static method onDeindex takes nothing returns boolean
			
			local unit u = GetIndexedUnit()
			local integer data = GetUnitUserData(u)
			
			if SlotBag[data] != 0 then
				set SlotBag[data]  = 0
				set ButtonSlot[data] = 0
			endif
			set u = null
			
			return false
		endmethod
  
        private static method checkPickItem takes nothing returns nothing
			
			local timer t = GetExpiredTimer()
			local integer id = GetTimerData(t)
			local integer vol
			local ItemObject obj
			
			if GetUnitCurrentOrder(MainUnit[id]) == PickItemOrder[id] then
				if IsUnitInRange(MainUnit[id], PickItemTarget[id], ITEM_PICKUP_RANGE) then
					set obj = ItemObject[PickItemTarget[id]]
					if obj.id.autoUse then
						call ApplyBonus(Fighter[id], obj)
						call obj.destroy()
					else
						if InventoryIndex[id].addItemEx(PickItemTarget[id]) then
							if Locale == Player(id) then
								set vol = 150
							else
								set vol = 0
							endif
							call PickUpItemSfx.play(0, 0, 0, vol)
						endif
					endif
					call ReleaseTimer(PickItemTimer[id])
					set PickItemTimer[id] = null
					call IssueImmediateOrder(MainUnit[id], "stop")
				endif
			else
				call ReleaseTimer(PickItemTimer[id])
				set PickItemTimer[id] = null
			endif
			set t = null
			
		endmethod
		
		method orderPickItem takes unit u returns nothing
			if not Fighter[pid].isStunned and not Fighter[pid].isAttacking and not Fighter[pid].isImmobilized and not Fighter[pid].isChanneling then
				if GetUnitTypeId(u) == 'e02F' then
					if PickItemTimer[pid] == null then
						set PickItemTimer[pid] = NewTimerEx(pid)
						call TimerStart(PickItemTimer[pid], 0.1, true, function thistype.checkPickItem)
					endif
					set PickItemOrder[pid] = GetIssuedOrderId()
					set PickItemTarget[pid] = u
					set skipDetect = true
					call IssueTargetOrderById(MainUnit[pid], PickItemOrder[pid], u)
					set skipDetect = false
				endif
			endif
		endmethod
  
        private static method onOrder takes nothing returns boolean
      
			local unit u = GetOrderTargetUnit()
			local integer data = GetUnitUserData(u)
			local integer id
			local thistype this
      
			if skipDetect then
				return false
			endif
			if u != null and GetIssuedOrderId() == ORDER_smart then
				if (SlotBag[data] != 0 or ContextButtonBag[data] != 0 or ExitBag[data] != 0) then
					set this = SlotBag[data]
					set u = GetTriggerUnit()
					call IssueImmediateOrderById(u, ORDER_stop)
					call IssueImmediateOrderById(u, ORDER_stunned)
					if SlotBag[data] != 0 then
						if ButtonSlot[data].object != Tooltips1[pid].itmObject or not Tooltips1[pid].control.visible then
							call Tooltips1[pid].show(true)
							//call Tooltips1.control.move(540.0-ButtonSlot[data].plat.xOffset, 0, 0)
							call Tooltips1[pid].setItem(ButtonSlot[data].object)
							if ButtonSlot[data].object.id.category < Items.CONSUMABLE and CharacterWindow_SlotObject[pid][ButtonSlot[data].object.id.category] != 0 then
								call Tooltips2[pid].show(true)
								call Tooltips1[pid].control.move(150, 0, Tooltips1[pid].control.zDepth)
								call Tooltips2[pid].control.move(-150, 0, Tooltips2[pid].control.zDepth)
								call Tooltips1[pid].control.refresh()
								call Tooltips2[pid].control.refresh()
								call Tooltips2[pid].setItem(CharacterWindow_SlotObject[pid][ButtonSlot[data].object.id.category])
							else
								call Tooltips1[pid].control.move(0, 0, Tooltips1[pid].control.zDepth)
								call Tooltips1[pid].control.refresh()
								call Tooltips2[pid].show(false)
								set Tooltips2[pid].itmObject = -1
							endif
						else
							call Tooltips1[pid].show(false)
							call Tooltips2[pid].show(false)
							set Tooltips1[pid].itmObject = -1
							set Tooltips2[pid].itmObject = -1
						endif
					endif
				else
					set id = GetPlayerId(GetTriggerPlayer())
					if GetTriggerUnit() == Controller[id] then
						if GetUnitTypeId(u) == 'e02F' then
							call InventoryIndex[id].orderPickItem(u)
						elseif PickItemTimer[id] != null then
							call ReleaseTimer(PickItemTimer[id])
							set PickItemTimer[id] = null
						endif
					endif
				endif
            endif
			set u = null
      
            return false
        endmethod
		
		private static method checkSelection takes nothing returns nothing

			local unit u
			local integer data
			local thistype this

			if CharacterManager_GameModeCode == 22 then
				set u = BlzGetMouseFocusUnit()
				if u == null then
					if LastSelection != null then
						set data = GetUnitUserData(u)
						set this = SlotBag[data]
						if Tooltips1[PNumb].itmObject != -1 then
							call Tooltips1[PNumb].show(false)
							call Tooltips2[PNumb].show(false)
							set Tooltips1[PNumb].itmObject = -1
							set Tooltips2[PNumb].itmObject = -1
							set LastSelection = u
						endif
					endif
				else
					if LastSelection != u then
						set data = GetUnitUserData(u)
						if SlotBag[data] != 0 then
							set this = SlotBag[data]
							call Tooltips1[PNumb].show(true)
							call Tooltips1[PNumb].setItem(ButtonSlot[data].object)
							if ButtonSlot[data].object.id.category < Items.CONSUMABLE and CharacterWindow_SlotObject[PNumb][ButtonSlot[data].object.id.category] != 0 then
								call Tooltips2[PNumb].show(true)
								call Tooltips1[PNumb].control.move(150, 0, Tooltips1[PNumb].control.zDepth)
								call Tooltips2[PNumb].control.move(-150, 0, Tooltips2[PNumb].control.zDepth)
								call Tooltips1[PNumb].control.refresh()
								call Tooltips2[PNumb].control.refresh()
								call Tooltips2[PNumb].setItem(CharacterWindow_SlotObject[PNumb][ButtonSlot[data].object.id.category])
							else
								call Tooltips1[PNumb].control.move(0, 0, Tooltips1[PNumb].control.zDepth)
								call Tooltips1[PNumb].control.refresh()
								call Tooltips2[PNumb].show(false)
								set Tooltips2[PNumb].itmObject = -1
							endif
							set LastSelection = u
						endif
					endif
				endif
				set u = null
			endif

		endmethod
		
		private static method onInit takes nothing returns nothing
			
			local trigger t = CreateTrigger()
			
			call RegisterUnitIndexEvent(Condition(function thistype.onDeindex), UnitIndexer.DEINDEX)
			call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_SELECTED)
			call TriggerAddCondition(t, Condition(function thistype.onSelect))
			
			set t = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
            call TriggerAddCondition(t, Condition(function thistype.onOrder))

			call TimerStart(CreateTimer(), 0.1, true, function thistype.checkSelection)
			
		endmethod
		
	endstruct
	
	private function UpdateGold takes player p, playerstate state, integer amount returns nothing
		
		local integer id
		
		if state == PLAYER_STATE_RESOURCE_GOLD then
			set id = GetPlayerId(p)
			call InventoryIndex[id].gold.setText(I2S(amount), FONTSTYLE_FrizQTShaded)
			call InventoryIndex[id].gold.refresh()
		endif
		
	endfunction

	hook SetPlayerState UpdateGold

endlibrary