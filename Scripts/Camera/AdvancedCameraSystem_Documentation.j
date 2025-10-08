// General information about the systems
RPG Systems by The_Witcher

In this map are 3 systems which are very useful for RPGs but mabe for other maps like mini games or shooters, too!!

the systems are all leak free, MPI and done in vJASS!
They all have their own "how to import" and if you want to know how to use them read the beginning of their codes!!

if you use them in your map credit me!!!!!!

the test map triggers are only for examples of what this systems can do. they are not meant as examples for leakfree triggers^^, so they may leak


For more Systems and Spells from me visit www.hiveworkshop.com


/// Movement System Plugins  
// =========================================================================================================      
The Plugins for the movement system give you nearly total
control over the movement system without having to modify its code!

You can easily add extra functions like dashing, quick turning and so on...

BUT even if you don't want any plugins you need the trigger only filled with the

BASE STRUCTURE:

library ArrowKeyMovementPlugins

//! textmacro Init_ArrowKeyMovement_Plugins_Locals

//! endtextmacro
    

//! textmacro Init_ArrowKeyMovement_Plugins

//! endtextmacro


//! textmacro ArrowKeyMovement_Plugins_Functions

//! endtextmacro

endlibrary

if the trigger is only filled with this text you aren't using any plugins!

to create your own plugin follow these steps:
1. set up locals:
    as you will create something like an event that fires your plugin it may happen that you need some locals for that...
    only the declaration locals is allowed!!!
    do this between these two lines in the code
      //! textmacro Init_ArrowKeyMovement_Plugins_Locals
               << your locals here>>
      //! endtextmacro

2. creating the events:
    now as you have everything ready create everything that has to be initialized like triggers, timers and so on
    do this between these two lines (you can use your locals from the 1st step here)
      //! textmacro Init_ArrowKeyMovement_Plugins
               <<your code here>>
      //! endtextmacro

3. creating the actions:
    okay we have our event now(for example a trigger firing when you double press left arrow)...
    we create the actions for this event now!
    do this between these two lines:
      //! textmacro ArrowKeyMovement_Plugins_Functions
               << your actions here>>
      //! endtextmacro
    if you created triggers you maybe have to go back and add these actions

now you are done! please look at my example here in the test map!

To see wich variables you can use in the plugins to affect the system read "Variables for Movement System Plugins"
// =========================================================================================================      


// Variables for Movement System Plugins
// =========================================================================================================        
Here is a List of all the variables you can use in plugins to affect the Movement system
IMPORTANT: for all array variables the index is the player number of the contolling player! 
                             var[0] is the var of player 1 / var[1] is the var of player 2 and so on...
______________________________________________________________________

unit array Walker               <-- this is the unit controlled by the player
                                              example: Walker[0] is the unit controlled by player 1

integer array animation      <-- this is the animation played during moving for the unit with that array
                                              example: animation[1] = 3 means that  Walker[1] will play animation 3 during moving

real array SpeedFactor      <-- this is a speed factor you can modify to change the movement speed and the animation speed
                                              example: 1 = normal speed   0.5 = half speed   2 = double speed

boolean array SpecialDirectionActive  <-- if this is true all key pressing actions are annulated and the unit will constantly move in the angle
                                                               specified in the SpecialDirection variable

real array SpecialDirection <-- this is only important if SpecialDirectionActive is true for that player! 
                                             the unit will move constantly in the given angle without changing its facing
                                                example: SpecialDirection [1] = 90 and SpecialDirectionActive [1] = true will cause Walker[1] to move to 90 degrees constantly with his given speed

 // ========================================================================================================= 
 
 // How to use the Movement System Plugins
// IMPORTANT: if you want to use the plugins you have to include the library ArrowKeyMovementPlugins in your map!
 Make sure that you importet my Keyboard System correctly!

1. Copy the "Movement System" Trigger into your map and edit the setup part.

2. Copy the "Movement System Plugins" Trigger into your map and edit the plugins
       even if you don't want to use plugins the trigger must exist with the base structure in it!
       for more information about the plugins read the "How to use the Movement System Plugins"


Thats all!! You're done :D

How to use the system can be read at the beginning of its code.
// =========================================================================================================

// How to use the Keybaord System Plugins
// =========================================================================================================
Simply copy the "Keyboard System" Trigger into your map and edit the setup part.

Thats all!! You're done :D

How to use the system can be read at the beginning of its code.

// How to use the Cam System
// =========================================================================================================
Simply copy the "Cam System" Trigger into your map and edit the setup part.

Thats all!! You're done :D

How to use the system can be read at the beginning of its code.


