library RuidTalentTreeView requires STKTalentViewModel
    
    public struct TalentTreeView extends ITalentTreeView

        framehandle box
        framehandle container
        framehandle containerImage
        framehandle title
        framehandle closeButton
        framehandle confirmButtonMain
        // framehandle confirmButtonImage
        framehandle cancelButtonMain
        // framehandle cancelButtonImage

    endstruct

    public function GenerateTalentTreeViewLeft takes framehandle parent returns ITalentTreeView

        local ITalentTreeView view = TalentTreeView.create()
        
        // CloseText
        // ConfirmText
        // CancelText

        set view.box = TalentMainFrame
        set view.container = TreeLeft
        set view.containerImage = TreeBackgroundLeft
        set view.title = TitleLeft
        set view.closeButton = CloseTalentViewButton
        set view.confirmButtonMain = ConfirmTalentsButton
        set view.cancelButtonMain = CancelTalentsButton

        return view
    endfunction

    public function GenerateTalentTreeViewMiddle takes framehandle parent returns ITalentTreeView

        local ITalentTreeView view = TalentTreeView.create()
        
        // CloseText
        // ConfirmText
        // CancelText

        set view.box = TalentMainFrame
        set view.container = TreeMiddle
        set view.containerImage = TreeBackgroundMiddle
        set view.title = TitleMiddle
        set view.closeButton = CloseTalentViewButton
        set view.confirmButtonMain = ConfirmTalentsButton
        set view.cancelButtonMain = CancelTalentsButton

        return view
    endfunction

    public function GenerateTalentTreeViewRight takes framehandle parent returns ITalentTreeView

        local ITalentTreeView view = TalentTreeView.create()
        
        // CloseText
        // ConfirmText
        // CancelText

        set view.box = TalentMainFrame
        set view.container = TreeRight
        set view.containerImage = TreeBackgroundRight
        set view.title = TitleRight
        set view.closeButton = CloseTalentViewButton
        set view.confirmButtonMain = ConfirmTalentsButton
        set view.cancelButtonMain = CancelTalentsButton

        return view
    endfunction

endlibrary