library STKITalentView
    
    interface ITalentView

        framehandle buttonMain             // Button frame for allocating points into a Talent
        framehandle buttonImage            // Image frame that shows Talent icon
        framehandle tooltipBox             // Window frame that shows/hides talent hover tooltip
        framehandle tooltipText            // Text frame that shows Talent title and description
        framehandle tooltipRank            // Text frame that shows current Talent rank within tooltip
        framehandle rankImage              // Image background of current rank on the Talent icon
        framehandle rankText               // Text frame showing current rank on the Talent icon
        framehandle highlight              // Image frame shown when button can be clicked

        framehandle linkLeft               // Image frame left dependency
        framehandle linkUp                 // Image frame up dependency
        framehandle linkRight              // Image frame right dependency
        framehandle linkDown               // Image frame down dependency
        framehandle linkIntersection       // Image frame shown when Talent itself acts as a dependency link

    endinterface

endlibrary