library STKStore requires STKConstants, STKTalentTree

    globals
        // Configurable globals
        private constant integer MAX_TALENT_SLOTS = STKConstants_MAX_TALENT_SLOTS
        private constant integer MAX_PLAYER_COUNT = STKConstants_MAX_PLAYER_COUNT
        private constant integer MAX_PANELS_VISIBLE = 3
        
        // Internal globals
        private constant integer MAX_TALENT_VIEWS = MAX_TALENT_SLOTS * MAX_PANELS_VISIBLE
        private constant integer MAX_TALENT_VIEW_MODELS = MAX_PLAYER_COUNT * MAX_PANELS_VISIBLE

        private constant integer HASH_UNIT_TREE_KEY = 100
    endglobals

    struct STKStore
        private hashtable hash
        private ITalentView array talentViews[MAX_TALENT_VIEWS]
        private STKTalentTreeViewModel_TalentTreeViewModel array talentTreeViewModels[MAX_TALENT_VIEW_MODELS]

        static method create takes nothing returns STKStore
            local thistype this = thistype.allocate()
            set this.hash = InitHashtable()
            return this
        endmethod

        // Talent Trees
        public method SetUnitTalentTree takes integer panelId, unit whichUnit, STKTalentTree_TalentTree talentTree returns STKTalentTree_TalentTree
            local integer playerId = GetPlayerId(GetOwningPlayer(whichUnit))
            call SaveInteger(this.hash, HASH_UNIT_TREE_KEY + panelId, GetHandleId(whichUnit), talentTree)
            return talentTree
        endmethod
        public method GetUnitTalentTree takes integer panelId, unit whichUnit returns STKTalentTree_TalentTree
            local integer playerId = GetPlayerId(GetOwningPlayer(whichUnit))
            return LoadInteger(this.hash, HASH_UNIT_TREE_KEY + panelId, GetHandleId(whichUnit))
        endmethod

        // Talent Views
        public method SetTalentView takes integer panelId, integer talentViewIndex, ITalentView talentView returns ITalentView
            local integer index = MAX_TALENT_SLOTS * panelId + talentViewIndex
            set this.talentViews[index] = talentView
            return talentView
        endmethod
        public method GetTalentView takes integer panelId, integer talentViewIndex returns ITalentView
            local integer index = MAX_TALENT_SLOTS * panelId + talentViewIndex
            return this.talentViews[index]
        endmethod

        // Talent Tree View Models
        public method SetPlayerTalentTreeViewModel takes integer panelId, integer playerId, STKTalentTreeViewModel_TalentTreeViewModel talentTreeViewModel returns STKTalentTreeViewModel_TalentTreeViewModel
            local integer index = MAX_PANELS_VISIBLE * playerId + panelId
            set this.talentTreeViewModels[index] = talentTreeViewModel
            return talentTreeViewModel
        endmethod
        public method GetPlayerTalentTreeViewModel takes integer panelId, integer playerId returns STKTalentTreeViewModel_TalentTreeViewModel
            local integer index = MAX_PANELS_VISIBLE * playerId + panelId
            return this.talentTreeViewModels[index]
        endmethod
    endstruct
endlibrary