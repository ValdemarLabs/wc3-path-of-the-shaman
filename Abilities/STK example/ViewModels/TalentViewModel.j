library STKTalentViewModel requires STKITalentSlot, STKITalentView

    public struct TalentViewModel extends ITalentSlot

        public static constant string ActiveLinkTexture = STKConstants_ACTIVE_LINK_TEXTURE
        public static constant string InactiveLinkTexture = STKConstants_INACTIVE_LINK_TEXTURE

        private ITalentView view
        private player watcher

        private integer state = 0
        private integer rank = 0
        private STKTalent_Talent talent = 0

        private string errorText
        private boolean visible = false
        private boolean isAvailable = false

        private boolean linkLeftVisible = false
        private boolean linkUpVisible = false
        private boolean linkRightVisible = false
        private boolean linkDownVisible = false

        static method create takes ITalentView view returns TalentViewModel
            local TalentViewModel this = TalentViewModel.allocate()
            set this.view = view

            return this
        endmethod

        method RenderView takes nothing returns nothing

            // call BJDebugMsg("Rendering talent " + I2S(this.state))

            if (this.state == 0) then
                // Empty
                call this.SetVisible(false)

            elseif (this.state == 1) then
                // RequireDisabled
                call this.SetTooltip(this.errorText, this.talent.cost)
                call this.SetRank(this.rank)
                call this.SetAvailable(false)

            elseif (this.state == 2) then
                // DependDisabled
                call this.SetTooltip(this.errorText, this.talent.cost)
                call this.SetRank(this.rank)
                call this.SetAvailable(false)

            elseif (this.state == 3) then
                // Available
                call this.SetTooltip(this.errorText, this.talent.cost)
                call this.SetRank(this.rank)
                call this.SetAvailable(true)

            elseif (this.state == 4) then
                // Maxed
                call this.SetTooltip(this.errorText, 0)
                call this.SetRank(this.rank)
                call this.SetMaxed()

            elseif (this.state == 5) then
                // Link
                call this.SetAsLink()

            endif
        endmethod

        // Internal ===========================================================
        method SetTooltip takes string requirements, integer cost returns nothing
            local string description = ""
            local string text = ""
            
            if (this.talent == 0 or GetLocalPlayer() != this.watcher) then
                return
            endif

            set description = this.talent.description
            if (this.talent.nextRank != 0 and this.talent.previousRank != 0) then
                set description = this.talent.previousRank.description + "\n\nNext rank:\n" + description
            endif

            set text = this.talent.name
            if (cost > 0) then
                set text = text + "\n\n|cffffc04d[Cost " + I2S(cost) + "]|r "
            endif
            if (cost > 0 and requirements != null and requirements != "") then
                set text = text + "|cffff6450Requires: " + requirements + "|r\n\n" + description
            elseif (requirements != null and requirements != "") then
                set text = text + "\n\n|cffff6450Requires: " + requirements + "|r\n\n" + description
            else
                set text = text + "\n\n" + description
            endif

            call BlzFrameSetText(this.view.tooltipText, text)
        endmethod

        method SetAvailable takes boolean isAvailable returns nothing
            local string texture
            set this.isAvailable = isAvailable

            if (this.talent == 0) then
                return
            endif

            // icon to disabled/enabled, button enable, highlight, tooltip
            set texture = this.talent.iconDisabled
            if (this.GetRank() > 0) then
                set texture = this.talent.iconEnabled
            endif

            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetTexture(this.view.buttonImage, texture, 0, true)
            call BlzFrameSetEnable(this.view.buttonMain, isAvailable)
            call BlzFrameSetVisible(this.view.highlight, isAvailable)

        endmethod

        method SetMaxed takes nothing returns nothing

            if (this.talent == 0) then
                return
            endif

            set this.isAvailable = false
            call this.SetTooltip(null, 0)
    
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetTexture(this.view.buttonImage, this.talent.iconEnabled, 0, true)
            call BlzFrameSetEnable(this.view.buttonMain, false)
            call BlzFrameSetVisible(this.view.highlight, false)
        endmethod

        method SetAsLink takes nothing returns nothing

            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetVisible(this.view.highlight, false)

            if (this.talent != 0 and this.talent.iconEnabled != null) then
                call BlzFrameSetVisible(this.view.buttonMain, true)
                call BlzFrameSetEnable(this.view.buttonMain, false)
                if (this.rank > 0) then
                    call BlzFrameSetTexture(this.view.buttonImage, this.talent.iconEnabled, 0, true)
                endif
            else
                call BlzFrameSetVisible(this.view.buttonMain, false)
                call BlzFrameSetVisible(this.view.linkIntersection, true)
                if (this.rank > 0) then
                    call BlzFrameSetTexture(this.view.linkIntersection, ActiveLinkTexture, 0, true)
                else
                    call BlzFrameSetTexture(this.view.linkIntersection, InactiveLinkTexture, 0, true)
                endif
            endif

            call this.UpdateLinkVisibility()
        endmethod

        // End Internal ===========================================================

        method GetButtonFrame takes nothing returns framehandle
            return this.view.buttonMain
        endmethod

        method SetVisible takes boolean isVisible returns nothing

            set this.visible = isVisible

            if (isVisible == false) then
                // call BJDebugMsg("Setting invisible ")
            endif

            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            if (this.talent != 0 and this.talent.isLink) then
                call BlzFrameSetVisible(this.view.linkIntersection, isVisible and this.talent.isLink)
                return
            endif

            call BlzFrameSetVisible(this.view.linkIntersection, false)
            call BlzFrameSetVisible(this.view.buttonMain, isVisible)
            call BlzFrameSetVisible(this.view.highlight, isVisible and this.isAvailable)

            call BlzFrameSetVisible(this.view.linkLeft, isVisible and this.linkLeftVisible)
            call BlzFrameSetVisible(this.view.linkUp, isVisible and this.linkUpVisible)
            call BlzFrameSetVisible(this.view.linkRight, isVisible and this.linkRightVisible)
            call BlzFrameSetVisible(this.view.linkDown, isVisible and this.linkDownVisible)
        endmethod

        method GetTalent takes nothing returns STKTalent_Talent
            return this.talent
        endmethod

        method SetTalent takes STKTalent_Talent talent returns nothing
            set this.talent = talent
            call this.RenderView()
        endmethod
    
        method GetRank takes nothing returns integer
            return this.rank
        endmethod

        method SetRank takes integer rank returns nothing
            local string tooltipText
            local string rankText
            
            set this.rank = rank

            if (this.talent == 0) then
                return
            endif

            set rankText = I2S(rank) + "/" + I2S(this.talent.maxRank)
            set tooltipText = "Rank " + rankText

            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            if (this.talent.maxRank == 1) then
                call BlzFrameSetVisible(this.view.rankImage, false)
                call BlzFrameSetVisible(this.view.rankText, false)
            else
                call BlzFrameSetVisible(this.view.rankImage, true)
                call BlzFrameSetVisible(this.view.rankText, true)
                call BlzFrameSetText(this.view.rankText, rankText)
            endif
            call BlzFrameSetText(this.view.tooltipRank, tooltipText)
        endmethod
    
        method GetIndex takes nothing returns integer
            return 1
        endmethod
    
        method GetWatcher takes nothing returns player
            return GetTriggerPlayer()
        endmethod

        method SetWatcher takes player watcher returns nothing
            set this.watcher = watcher
        endmethod
    
        method GetState takes nothing returns integer
            return this.state
        endmethod

        method SetState takes integer state returns nothing
            set this.state = state
            // call BJDebugMsg("Set Talent state " + I2S(state))
            call this.RenderView()
        endmethod
    
        method GetErrorText takes nothing returns string
            return this.errorText
        endmethod

        method SetErrorText takes string text returns nothing
            set this.errorText = text
        endmethod
    
        method MoveTo takes framepointtype point, framehandle relative, framepointtype relativePoint, real x, real y, real linkWidth, real linkHeight returns nothing
            
            local real width = 0.
            local real height = 0.
            
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetPoint(this.view.buttonMain, point, relative, relativePoint, x, y)

            // Links
            set height = BlzFrameGetHeight(this.view.linkLeft)
            set width = BlzFrameGetWidth(this.view.linkUp)

            call BlzFrameClearAllPoints(this.view.linkLeft)
            call BlzFrameSetPoint(this.view.linkLeft, FRAMEPOINT_RIGHT, this.view.buttonMain, FRAMEPOINT_CENTER, 0, 0)
            call BlzFrameSetSize(this.view.linkLeft, linkWidth, height)
            
            call BlzFrameClearAllPoints(this.view.linkUp)
            call BlzFrameSetPoint(this.view.linkUp, FRAMEPOINT_BOTTOM, this.view.buttonMain, FRAMEPOINT_CENTER, 0, 0)
            call BlzFrameSetSize(this.view.linkUp, width, linkHeight)

            call BlzFrameClearAllPoints(this.view.linkRight)
            call BlzFrameSetPoint(this.view.linkRight, FRAMEPOINT_LEFT, this.view.buttonMain, FRAMEPOINT_CENTER, 0, 0)
            call BlzFrameSetSize(this.view.linkRight, linkWidth, height)

            call BlzFrameClearAllPoints(this.view.linkDown)
            call BlzFrameSetPoint(this.view.linkDown, FRAMEPOINT_TOP, this.view.buttonMain, FRAMEPOINT_CENTER, 0, 0)
            call BlzFrameSetSize(this.view.linkDown, width, linkHeight)
        endmethod

        method UpdateLinkVisibility takes nothing returns nothing
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call BlzFrameSetVisible(this.view.linkLeft, this.linkLeftVisible)
            call BlzFrameSetVisible(this.view.linkUp, this.linkUpVisible)
            call BlzFrameSetVisible(this.view.linkRight, this.linkRightVisible)
            call BlzFrameSetVisible(this.view.linkDown, this.linkDownVisible)
        endmethod
    
        method RenderLinks takes string dependencyLeft, string dependencyUp, string dependencyRight, string dependencyDown returns nothing

            set this.linkLeftVisible = this.talent.dependencyLeft != 0 // dependencyLeft != null and dependencyLeft != ""
            set this.linkUpVisible = this.talent.dependencyUp != 0 // dependencyLeft != null and dependencyUp != ""
            set this.linkRightVisible = this.talent.dependencyRight != 0 // dependencyLeft != null and dependencyRight != ""
            set this.linkDownVisible = this.talent.dependencyDown != 0 // dependencyLeft != null and dependencyDown != ""
            
            if (GetLocalPlayer() != this.watcher) then
                return
            endif

            call this.UpdateLinkVisibility()
            
            if (dependencyLeft == null and this.linkLeftVisible) then
                call BlzFrameSetTexture(this.view.linkLeft, thistype.ActiveLinkTexture, 0, true)
            else
                call BlzFrameSetTexture(this.view.linkLeft, thistype.InactiveLinkTexture, 0, true)
            endif
            if (dependencyUp == null and this.linkUpVisible) then
                call BlzFrameSetTexture(this.view.linkUp, thistype.ActiveLinkTexture, 0, true)
            else
                call BlzFrameSetTexture(this.view.linkUp, thistype.InactiveLinkTexture, 0, true)
            endif
            if (dependencyRight == null and this.linkRightVisible) then
                call BlzFrameSetTexture(this.view.linkRight, thistype.ActiveLinkTexture, 0, true)
            else
                call BlzFrameSetTexture(this.view.linkRight, thistype.InactiveLinkTexture, 0, true)
            endif
            if (dependencyDown == null and this.linkDownVisible) then
                call BlzFrameSetTexture(this.view.linkDown, thistype.ActiveLinkTexture, 0, true)
            else
                call BlzFrameSetTexture(this.view.linkDown, thistype.InactiveLinkTexture, 0, true)
            endif
        endmethod

    endstruct

endlibrary