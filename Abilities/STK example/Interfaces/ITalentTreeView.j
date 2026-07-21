library STKITalentTreeView
    
    interface ITalentTreeView

        framehandle box                 // Window frame that is shown and hidden when player opens and closes their Talent Tree/s.
        framehandle container           // Window frame that envelops talent tree itself, acts as a boundary for Talent views. Same size as TalentTree background image.
        framehandle containerImage      // Image frame that shows TalentTree background image. The system will attempt to change background image according to the loaded TalentTree object.
        framehandle title               // Text frame that shows Title of loaded TalentTree.
        framehandle confirmButtonMain   // Button frame whose click will apply temporary talents and activate them.
        framehandle cancelButtonMain    // Button frame whose click will reset temporary talents.
        framehandle closeButton         // Button frame whose click will hide Talent Tree window.

    endinterface

endlibrary