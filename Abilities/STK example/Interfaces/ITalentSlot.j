library STKITalentSlot

    interface ITalentSlot

        method GetButtonFrame takes nothing returns framehandle              // Used for setting up Click triggers
        method SetVisible takes boolean isVisible returns nothing            // Showing or hiding whole talent view. [LOCAL CODE]
        method GetTalent takes nothing returns STKTalent_Talent              // Returns its Talent model
        method SetTalent takes STKTalent_Talent talent returns nothing       // Makes this TalentSlot point to given Talent
        method GetRank takes nothing returns integer                         // Returns rank currently shown in this slot's view
        method SetRank takes integer rank returns nothing                    // Sets rank currently shown in this slot's view
        method GetIndex takes nothing returns integer                        // Not used
        method GetWatcher takes nothing returns player                       // Not used
        method SetWatcher takes player watcher returns nothing               // Sets watcher player of this TalentSlot. Subsequent local code needs this value
        method GetState takes nothing returns integer                        // Returns TalentSlot state (state is internal representation of the TalentSlot)
        method SetState takes integer state returns nothing                  // Sets TalentSlot state (state is internal representation of the TalentSlot)
        method GetErrorText takes nothing returns string                     // Returns currently shown error text
        method SetErrorText takes string text returns nothing                // Sets currently shown error text
        
        // Changes position of this TalentSlot's TalentView frames according to the grid position of its Talent model
        method MoveTo takes framepointtype point, framehandle relative, framepointtype relativePoint, real x, real y, real linkWidth, real linkHeight returns nothing
        // Used to update this slot's view according to dependencies of its Talent model
        method RenderLinks takes string dependencyLeft, string dependencyUp, string dependencyRight, string dependencyDown returns nothing

    endinterface

endlibrary