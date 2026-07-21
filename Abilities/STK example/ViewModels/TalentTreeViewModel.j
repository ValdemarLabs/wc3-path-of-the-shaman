library STKTalentTreeViewModel requires STKITalentSlot

    globals
        private constant integer FRAME_INDEX_KEY = 0
        private constant integer FRAME_PANEL_ID = 0
        private integer array Instances[300]
        private integer InstanceCount = 0
        private hashtable FrameIndex = InitHashtable()
        private trigger ClickTrigger = null
        private trigger ConfirmTrigger = null
        private trigger CancelTrigger = null
        private trigger CloseTrigger = null

        // This block is used to update view without lag =============================================
        private constant integer MAX_PLAYER_ID = 24
        private STKTalentTreeViewModel_TalentTreeViewModel array talentTreeViewModelsToUpdate[2400]
        private hashtable Hash = InitHashtable()
        private constant integer HASH_TIMER_TALENTTREE_KEY = 11
        private constant integer HASH_TALENTTREE_TIMER_KEY  = 12
        // ==========================================================================================
    endglobals

    function interface TalentSlotFactory takes framehandle parent, integer index, integer panelId returns ITalentSlot

    private function ConcatenateErrors takes string err1, string err2 returns string
        if (err1 == null and err2 == null) then
            return null
        elseif (err1 == null) then
            return err2
        elseif (err2 == null) then
            return err1
        endif
        return err1 + ", " + err2
    endfunction

    private function DefaultUpdateTreeViewModelOnViewChanged takes nothing returns nothing
        local integer i = 0
        local timer tim = GetExpiredTimer()
        local integer timerKey = GetHandleId(tim)
        local STKTalentTree_TalentTree tree = LoadInteger(Hash, HASH_TIMER_TALENTTREE_KEY, timerKey)
        local STKTalentTreeViewModel_TalentTreeViewModel ttvm
        call DestroyTimer(tim)

        loop
            exitwhen i == MAX_PLAYER_ID
            set ttvm = talentTreeViewModelsToUpdate[i * MAX_PLAYER_ID + tree]
            if (ttvm != 0 and ttvm != -1) then
                call ttvm.ResetTalentViewModels()
            endif
            set i = i + 1
        endloop

        set tim = null
    endfunction
    
    function DefaultOnTalentViewChanged takes STKTalentTreeViewModel_TalentTreeViewModel ttvm, player watcher, STKTalentTree_TalentTree tree returns nothing
        local integer playerId
        local timer tim

        set playerId = GetPlayerId(watcher)
        set tim = LoadTimerHandle(Hash, HASH_TALENTTREE_TIMER_KEY, tree)

        if (tim == null) then
            set tim = CreateTimer()
            call SaveTimerHandle(Hash, HASH_TALENTTREE_TIMER_KEY, tree, tim)
            call SaveInteger(Hash, HASH_TIMER_TALENTTREE_KEY, GetHandleId(tim), tree)
            call TimerStart(tim, 0, false, function DefaultUpdateTreeViewModelOnViewChanged)
        endif

        set tim = null
    endfunction

    public struct TalentTreeViewModel

        private player watcher
        private boolean watched = false
        private STKTalentTree_TalentTree tree = 0

        private ITalentTreeView view
        private framehandle parent
        private integer panelId
        private ITalentSlot array slots[STKConstants_MAX_TALENT_SLOTS]
        private integer slotCount = STKConstants_MAX_TALENT_SLOTS
        private ViewChanged onViewChanged

        // UI config ===============================================================
        public real boxWidth = 0
        public real boxHeight = 0
        public real sideMargin = 0
        public real verticalMargin = 0
        // End UI config ===============================================================

        static method SetUpTriggersIfNeeded takes nothing returns nothing
            if (ClickTrigger == null) then
                set ClickTrigger = CreateTrigger()
                call TriggerAddAction(ClickTrigger, function thistype.TalentButtonClicked)
            endif

            if (ConfirmTrigger == null) then
                set ConfirmTrigger = CreateTrigger()
                call TriggerAddAction(ConfirmTrigger, function thistype.ConfirmButtonClicked)
            endif

            if (CancelTrigger == null) then
                set CancelTrigger = CreateTrigger()
                call TriggerAddAction(CancelTrigger, function thistype.CancelButtonClicked)
            endif

            if (CloseTrigger == null) then
                set CloseTrigger = CreateTrigger()
                call TriggerAddAction(CloseTrigger, function thistype.CloseButtonClicked)
            endif
        endmethod

        static method SetUpSlotTriggersIfNeeded takes ITalentSlot slot, integer i, integer panelId returns nothing
            local integer fi = LoadInteger(FrameIndex, FRAME_INDEX_KEY + panelId, GetHandleId(slot.GetButtonFrame()))
            if (fi == 0) then
                call BlzTriggerRegisterFrameEvent(ClickTrigger, slot.GetButtonFrame(), FRAMEEVENT_CONTROL_CLICK)
                call SaveInteger(FrameIndex, FRAME_PANEL_ID, GetHandleId(slot.GetButtonFrame()), panelId)
                call SaveInteger(FrameIndex, FRAME_INDEX_KEY + panelId, GetHandleId(slot.GetButtonFrame()), i + 1)
            endif
        endmethod

        static method SetUpActionTriggersIfNeeded takes ITalentTreeView view returns nothing
            if (LoadInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.confirmButtonMain)) == 0) then
                call BlzTriggerRegisterFrameEvent(ConfirmTrigger, view.confirmButtonMain, FRAMEEVENT_CONTROL_CLICK)
                call SaveInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.confirmButtonMain), 1)
            endif
            if (LoadInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.cancelButtonMain)) == 0) then
                call BlzTriggerRegisterFrameEvent(CancelTrigger, view.cancelButtonMain, FRAMEEVENT_CONTROL_CLICK)
                call SaveInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.cancelButtonMain), 1)
            endif
            if (LoadInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.closeButton)) == 0) then
                call BlzTriggerRegisterFrameEvent(CloseTrigger, view.closeButton, FRAMEEVENT_CONTROL_CLICK)
                call SaveInteger(FrameIndex, FRAME_INDEX_KEY, GetHandleId(view.closeButton), 1)
            endif
        endmethod

        private static method create takes player watcher, ITalentTreeView view, TalentSlotFactory talentSlotFactory, integer panelId, ViewChanged onViewChanged returns TalentTreeViewModel
            local TalentTreeViewModel this = TalentTreeViewModel.allocate()
            local ITalentSlot slot
            local integer i = 0

            local framehandle f

            set this.view = view
            set this.watcher = watcher
            set this.parent = view.box
            set this.panelId = panelId
            set this.onViewChanged = onViewChanged
            
            if (onViewChanged == -1 or onViewChanged == 0) then
                set this.onViewChanged = DefaultOnTalentViewChanged
            endif

            call thistype.SetUpTriggersIfNeeded()

            // Set up the talent slots
            loop
                exitwhen i == STKTalentTree_MAX_TALENTS

                // Create a new slot
                set slot = talentSlotFactory.evaluate(view.box, i, panelId)
                set this.slots[i] = slot

                // Set its watcher to this watcher
                call slot.SetWatcher(watcher)
                call thistype.SetUpSlotTriggersIfNeeded(slot, i, panelId)

                set i = i + 1
            endloop

            call thistype.SetUpActionTriggersIfNeeded(view)

            set Instances[InstanceCount] = this
            set InstanceCount = InstanceCount + 1

            call this.Hide()
            return this
        endmethod

        static method createSingleView takes player watcher, ITalentTreeView view, TalentSlotFactory talentSlotFactory returns TalentTreeViewModel
            return TalentTreeViewModel.create(watcher, view, talentSlotFactory, 1, -1)
        endmethod

        static method createPanel takes player watcher, ITalentTreeView view, TalentSlotFactory talentSlotFactory, integer panelId, ViewChanged onViewChanged returns TalentTreeViewModel
            return TalentTreeViewModel.create(watcher, view, talentSlotFactory, panelId, onViewChanged)
        endmethod

        method TalentClicked takes integer index returns nothing
            local ITalentSlot slot = this.slots[index]
            local STKTalent_Talent talent = 0
            local integer tempState

            if (this.watched == false) then
                return
            endif

            if (this.tree == 0) then
                return
            endif

            set talent = this.tree.talents[index]
            if (talent == 0) then
                return
            endif

            set tempState = this.tree.tempRankState[index]
            if (this.tree.GetTalentPoints() >= talent.cost and tempState < talent.maxRank) then

                call this.tree.ApplyTalentTemporary(index)
                set tempState = this.tree.tempRankState[index]

                // Check for link states
                call this.tree.UpdateLinkStates()
                
                if (this.onViewChanged != -1) then
                    call this.onViewChanged.execute(this, this.watcher, this.tree)
                endif
            endif
        endmethod

        method OnConfirm takes nothing returns nothing
            
            if (this.tree != 0) then
                call this.tree.SaveTalentRankState()
                // call this.ResetTalentViewModels()
                if (this.onViewChanged != -1) then
                    call this.onViewChanged.execute(this, this.watcher, this.tree)
                endif
            endif

        endmethod

        method OnCancel takes nothing returns nothing
            
            if (this.tree != 0) then
                call this.tree.ResetTempRankState()
                call this.tree.UpdateLinkStates()
                // call this.ResetTalentViewModels()
                if (this.onViewChanged != -1) then
                    call this.onViewChanged.execute(this, this.watcher, this.tree)
                endif
            endif

        endmethod

        method UpdatePointsAndTitle takes nothing returns nothing
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            if (tree != 0) then
                call BlzFrameSetText(this.view.title, this.tree.GetTitle())
                call BlzFrameSetTexture(this.view.containerImage, this.tree.backgroundImage, 0, true)
            endif
        endmethod

        method ResetTalentViewModels takes nothing returns nothing

            local integer i = 0
            local ITalentSlot slot
            local STKTalent_Talent talent

            if (this.tree == 0 or this.tree == null) then
                return
            endif

            loop
                exitwhen i == this.slotCount

                set slot = this.slots[i]
                set talent = this.tree.talents[i]

                if (talent != 0) then
                    // Update Talent Slot from Talent
                    call slot.SetTalent(talent)
                    call this.UpdateTalentSlot(slot, talent, this.tree, i)
                else
                    call slot.SetState(0)
                endif

                set i = i + 1
            endloop
            // Update points
            call this.UpdatePointsAndTitle()
        endmethod

        method UnregisterFromTreeViewChanges takes STKTalentTree_TalentTree oldWatchedTree returns nothing
            // call BJDebugMsg("Unregister (" + I2S(GetPlayerId(this.watcher) * MAX_PLAYER_ID + oldWatchedTree) + ") TTVM: " + I2S(this))
            set talentTreeViewModelsToUpdate[MAX_PLAYER_ID * GetPlayerId(this.watcher) + oldWatchedTree] = -1
        endmethod

        method RegisterToTreeViewChanges takes STKTalentTree_TalentTree newWatchedTree returns nothing
            // call BJDebugMsg("Register (" + I2S(GetPlayerId(this.watcher) * MAX_PLAYER_ID + newWatchedTree) + ") TTVM: " + I2S(this))
            set talentTreeViewModelsToUpdate[MAX_PLAYER_ID * GetPlayerId(this.watcher) + newWatchedTree] = this
        endmethod

        method ScheduleRedraw takes nothing returns nothing            
            call DefaultOnTalentViewChanged(this, this.watcher, this.tree)
        endmethod

        method SetTree takes STKTalentTree_TalentTree tree returns nothing
            if (this.watched == true) then
                // Unregister from the old tree
                if (this.tree != tree) then
                    call this.UnregisterFromTreeViewChanges(this.tree)
                    call this.RegisterToTreeViewChanges(tree)
                endif
            endif

            set this.tree = tree
            call this.ResetTalentViewModels()
        endmethod

        method GetTree takes nothing returns STKTalentTree_TalentTree
            return this.tree
        endmethod

        method IsWatched takes nothing returns boolean
            return this.watched
        endmethod

        // Show
        method RenderTree takes nothing returns nothing
            local STKTalentTree_TalentTree tree
            local integer cols = 0
            local integer rows = 0
            local real xIncrem = 0
            local real yIncrem = 0
            local integer i = 0
            local ITalentSlot slot
            local real x
            local real y

            set this.watched = true

            if (this.tree == 0) then
                return
            endif

            // Reorganize the talents
            set tree = this.tree
            set cols = tree.columns
            set rows = tree.rows

            set xIncrem = (this.boxWidth * (1 - this.sideMargin)) / (cols + 1)
            set yIncrem = (this.boxHeight * (1 - this.verticalMargin)) / (rows + 1)

            call this.ResetTalentViewModels()

            set i = 0
            loop
                exitwhen i >= this.slotCount
                set slot = this.slots[i]
                
                set x = R2I(ModuloInteger(i, cols)) * xIncrem - ((cols - 1) * 0.5) * xIncrem
                set y = R2I((i) / cols) * yIncrem - ((rows - 1) * 0.5) * yIncrem
                
                call slot.MoveTo(FRAMEPOINT_CENTER, this.view.container, FRAMEPOINT_CENTER, x, y, xIncrem, yIncrem)

                if (tree.talents[i] != 0) then
                    // call slot.SetTalent(tree.talents[i])
                    // call UpdateTalentSlot(slot, tree.talents[i], tree, i)
                    // call BJDebugMsg("Setting visible")
                    call slot.SetVisible(true)
                else
                    call slot.SetVisible(false)
                endif

                set i = i + 1
            endloop

            // Register TalentTreeViewModel to the view changes
            call this.RegisterToTreeViewChanges(tree)
            
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetVisible(this.view.box, true)
            call BlzFrameSetVisible(this.view.container, true)
        endmethod

        method Hide takes nothing returns nothing
            
            local integer i = 0
            set this.watched = false
    
            // for (let i = 0; i < this._slots.length; i++) {
            //     this._slots[i].visible = false;
            // }
    
            // Unreegister TalentTreeViewModel from the view changes
            call this.UnregisterFromTreeViewChanges(this.tree)

            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetVisible(this.view.box, false)
        endmethod

        method UpdateTalentSlot takes ITalentSlot slot, STKTalent_Talent talent, STKTalentTree_TalentTree tree, integer index returns nothing
            
            local integer tempState = tree.tempRankState[index]
            // State Available
            local integer state = 3
            local boolean dep = false
            local boolean req = false
            local boolean depOk = true
            local boolean reqOk = true
            local string depError
            local string reqError

            local string depLeft = tree.CheckDependencyKeyLeft(talent.dependencyLeft, index)
            local string depUp = tree.CheckDependencyKeyUp(talent.dependencyUp, index)
            local string depRight = tree.CheckDependencyKeyRight(talent.dependencyRight, index)
            local string depDown = tree.CheckDependencyKeyDown(talent.dependencyDown, index)

            call slot.SetRank(tempState)
            call slot.RenderLinks(depLeft, depUp, depRight, depDown)

            if (talent.isLink == true) then
                call slot.SetState(5) // Link
                return
            endif

            call slot.SetErrorText("")
            set depOk = true
            set reqOk = true

            set depError = ""
            set reqError = ""

            if (depLeft == null and depUp == null and depRight == null and depDown == null) then
                set depOk = true
            else
                set depOk = false
                set depError = ConcatenateErrors(depLeft, depUp)
                set depError = ConcatenateErrors(depError, depRight)
                set depError = ConcatenateErrors(depError, depDown)
            endif

            set reqError = tree.CalculateTalentRequirements(talent, index)
            set reqOk = false
            if (reqError == null) then
                set reqOk = true
                set reqError = null
            endif

            if (tempState == talent.maxRank) then
                // call BJDebugMsg("STATE 4")
                call slot.SetState(4) // Maxed
            elseif (depOk and reqOk and talent.cost <= tree.GetTalentPoints()) then
                // call BJDebugMsg("STATE 3")
                call slot.SetState(3) // Available
            else
                call slot.SetErrorText(depError + reqError)

                call slot.SetState(1)
                if (reqOk) then
                    // call BJDebugMsg("STATE 1")
                    call slot.SetState(1) // RequireDisabled
                elseif (depOk) then
                    // call BJDebugMsg("STATE 2")
                    call slot.SetState(2) // DependDisabled
                endif
            endif
        endmethod

        static method TalentButtonClicked takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local integer panelId = LoadInteger(FrameIndex, FRAME_PANEL_ID, GetHandleId(frame))
            local integer index = LoadInteger(FrameIndex, FRAME_INDEX_KEY + panelId, GetHandleId(frame)) - 1
            local player clickingPlayer = GetTriggerPlayer()
            local thistype ttvm
            local integer i = 0

            call BlzFrameSetEnable(frame, false)
            call BlzFrameSetEnable(frame, true)

            loop
                exitwhen i == InstanceCount
                set ttvm = Instances[i]
                if (ttvm != 0 and ttvm.watcher == clickingPlayer and ttvm.panelId == panelId) then
                    call ttvm.TalentClicked(index)
                endif
                set i = i + 1
            endloop

            set frame = null
            set clickingPlayer = null
        endmethod

        static method ConfirmButtonClicked takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player clickingPlayer = GetTriggerPlayer()
            local thistype ttvm
            local integer i = 0

            call BlzFrameSetEnable(frame, false)
            call BlzFrameSetEnable(frame, true)

            loop
                exitwhen i == InstanceCount
                set ttvm = Instances[i]
                if (ttvm != 0 and ttvm.watcher == clickingPlayer) then
                    call ttvm.OnConfirm()
                endif
                set i = i + 1
            endloop

            set frame = null
            set clickingPlayer = null
        endmethod

        static method CancelButtonClicked takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player clickingPlayer = GetTriggerPlayer()
            local thistype ttvm
            local integer i = 0

            call BlzFrameSetEnable(frame, false)
            call BlzFrameSetEnable(frame, true)
            
            loop
                exitwhen i == InstanceCount
                set ttvm = Instances[i]
                if (ttvm != 0 and ttvm.watcher == clickingPlayer) then
                    call ttvm.OnCancel()
                endif
                set i = i + 1
            endloop

            set frame = null
            set clickingPlayer = null
        endmethod

        static method CloseButtonClicked takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player clickingPlayer = GetTriggerPlayer()
            local thistype ttvm
            local integer i = 0

            call BlzFrameSetEnable(frame, false)
            call BlzFrameSetEnable(frame, true)

            loop
                exitwhen i == InstanceCount
                set ttvm = Instances[i]
                if (ttvm != 0 and ttvm.watcher == clickingPlayer) then
                    // call ttvm.OnClose()
                    call ttvm.Hide()
                endif
                set i = i + 1
            endloop

            set frame = null
            set clickingPlayer = null
        endmethod        

        method onDestroy takes nothing returns nothing
            set Instances[this] = 0
        endmethod

    endstruct

    function interface ViewChanged takes TalentTreeViewModel ttvm, player watcher, STKTalentTree_TalentTree tree returns nothing
endlibrary

