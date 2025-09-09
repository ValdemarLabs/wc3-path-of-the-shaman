////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  Wietlol's Relative Unit Attaching System 0.1 14/06/2015
//  Valdemar note: https://www.hiveworkshop.com/threads/how-do-i-attach-units-to-units.267095/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Description:
//      This system is made to move a dummy unit relative to it's target like a special effect.
//      It will update the location of the dummy to the location of it's target with either
//          - a raw offset (x, y) or
//          - a dynamic offset (offset, angle)
//      
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  How to install:
//      (make sure you have JNGP)
//      Copy and paste the "Relative Unit Attaching System" folder into your map.
//      
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  How to use:
//      1. Create a unit.
//      2. Create a dummy that you want to attach to the unit.
//      3. Call the RUA_CreateUnitAttachment.
//      4. Store the dummy unit in a variable so you can remove it again later.
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Function list:
//      function RUA_CreateUnitAttachment takes unit target, unit attachment, real offset, real angle, real zOffset, boolean offsetRotation, boolean isRotating returns integer
//      This funcion makes unit "attachment" be an attachment on unit "target".
//      
//      function RUA_DestroyUnitAttachmentBJ takes unit attachment returns nothing
//      This funcion removes the unit "attachment" from the arrays.
//      It doesnt remove the unit itself. 
//
//      Example Destroy:
//          Custom script: call RUA_DestroyUnitAttachmentBJ(udg_TempUnit)
//
//      Example Create:
//          Custom script: call RUA_CreateUnitAttachment(udg_TempUnit[0], udg_TempUnit[1], 100, 205, 200, true, true)
//
//          target	        unit	    the unit on which you want the other unit be attached to
//          attachment	    unit	    the unit which will be attached on the first unit
//          offset	        real	    the offset in XY between target and attachment
//          angle	        real	    the angle in XY from target to attachment
//          zOffset	        real	    the zOffset from the target to attachment
//          offsetRotation	boolean	    if the angle must rotate according to the facing of target
//          isRotating	    boolean	    if the attachment must copy the rotation of the target

//      
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Changelog:
//      0.1 14/06/2015
//          Initial creation of the system.
//      
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Known bugs:
//      - none
//      
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  RUA System
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
library ruaSystem
    
    globals
        
        //The timer and its interval:
        timer           udg_RUA_TIMER                   = CreateTimer()
        real            udg_RUA_INTERVAL                = 0.03          //User preference... in some way.
        
        //The data storage:
        integer         udg_RUA_Amount                  = -1
        unit array      udg_RUA_Param_Target
        unit array      udg_RUA_Param_Attachment
        real array      udg_RUA_Param_Angle
        real array      udg_RUA_Param_Offset
        real array      udg_RUA_Param_OffsetX
        real array      udg_RUA_Param_OffsetY
        real array      udg_RUA_Param_OffsetZ
        boolean array   udg_RUA_Param_OffsetRotation
        boolean array   udg_RUA_Param_IsRotating
        
    endglobals
    
    //This function is called to update all attachments.
    function RUA_Interval takes nothing returns nothing
        local integer i = 0
        local real targetFacing
        
        loop
            exitwhen i > udg_RUA_Amount
            
            //Store the target's facing angle in a variable.
            set targetFacing = GetUnitFacing(udg_RUA_Param_Target[i])
            if udg_RUA_Param_IsRotating[i] then
                //If the unit must rotate together with the target, then rotate it.
                call SetUnitFacing(udg_RUA_Param_Attachment[i], targetFacing)
            endif
            
            if udg_RUA_Param_OffsetRotation[i] then
                
                //Move the dummy relative to the target's angle with it's given offset and angle.
                set targetFacing = targetFacing * bj_DEGTORAD
                call SetUnitX(udg_RUA_Param_Attachment[i], GetUnitX(udg_RUA_Param_Target[i]) + udg_RUA_Param_Offset[i]*Cos(targetFacing + udg_RUA_Param_Angle[i]))
                call SetUnitY(udg_RUA_Param_Attachment[i], GetUnitY(udg_RUA_Param_Target[i]) + udg_RUA_Param_Offset[i]*Sin(targetFacing + udg_RUA_Param_Angle[i]))
                
            else
                
                //Move the dummy with the raw offset.
                call SetUnitX(udg_RUA_Param_Attachment[i], GetUnitX(udg_RUA_Param_Target[i]) + udg_RUA_Param_OffsetX[i]) 
                call SetUnitY(udg_RUA_Param_Attachment[i], GetUnitY(udg_RUA_Param_Target[i]) + udg_RUA_Param_OffsetY[i])
                
            endif
            
            //Update flying heght.
            call SetUnitFlyHeight(udg_RUA_Param_Attachment[i] , GetUnitFlyHeight(udg_RUA_Param_Target[i]) + udg_RUA_Param_OffsetZ[i], 0)
            
            set i = i +1
        endloop
        
    endfunction
    
    function RUA_CreateUnitAttachment takes unit target, unit attachment, real offset, real angle, real zOffset, boolean offsetRotation, boolean isRotating returns integer
        set angle = angle * bj_DEGTORAD
        
        set udg_RUA_Amount = udg_RUA_Amount +1
        set udg_RUA_Param_Target[udg_RUA_Amount] = target
        set udg_RUA_Param_Attachment[udg_RUA_Amount] = attachment
        set udg_RUA_Param_Angle[udg_RUA_Amount] = angle
        set udg_RUA_Param_Offset[udg_RUA_Amount] = offset
        set udg_RUA_Param_OffsetX[udg_RUA_Amount] = offset*Cos(angle)
        set udg_RUA_Param_OffsetY[udg_RUA_Amount] = offset*Sin(angle)
        set udg_RUA_Param_OffsetZ[udg_RUA_Amount] = zOffset
        set udg_RUA_Param_OffsetRotation[udg_RUA_Amount] = offsetRotation
        set udg_RUA_Param_IsRotating[udg_RUA_Amount] = isRotating
        
        if udg_RUA_Amount == 0 then
            call TimerStart(udg_RUA_TIMER, udg_RUA_INTERVAL, true, function RUA_Interval)
        endif
        
        return udg_RUA_Amount
    endfunction
    
    function RUA_DestroyUnitAttachment takes integer index returns nothing
        
        set udg_RUA_Param_Target[index]         = udg_RUA_Param_Target[udg_RUA_Amount]
        set udg_RUA_Param_Attachment[index]     = udg_RUA_Param_Attachment[udg_RUA_Amount]
        set udg_RUA_Param_Offset[index]         = udg_RUA_Param_Offset[udg_RUA_Amount]
        set udg_RUA_Param_OffsetX[index]        = udg_RUA_Param_OffsetX[udg_RUA_Amount]
        set udg_RUA_Param_OffsetY[index]        = udg_RUA_Param_OffsetY[udg_RUA_Amount]
        set udg_RUA_Param_OffsetZ[index]        = udg_RUA_Param_OffsetZ[udg_RUA_Amount]
        set udg_RUA_Param_OffsetRotation[index] = udg_RUA_Param_OffsetRotation[udg_RUA_Amount]
        set udg_RUA_Param_IsRotating[index]     = udg_RUA_Param_IsRotating[udg_RUA_Amount]
        set udg_RUA_Param_Target[udg_RUA_Amount]            = null
        set udg_RUA_Param_Attachment[udg_RUA_Amount]        = null
        set udg_RUA_Param_Offset[udg_RUA_Amount]            = 0.
        set udg_RUA_Param_OffsetX[udg_RUA_Amount]           = 0.
        set udg_RUA_Param_OffsetY[udg_RUA_Amount]           = 0.
        set udg_RUA_Param_OffsetZ[udg_RUA_Amount]           = 0.
        set udg_RUA_Param_OffsetRotation[udg_RUA_Amount]    = false
        set udg_RUA_Param_IsRotating[udg_RUA_Amount]        = false
        set udg_RUA_Amount = udg_RUA_Amount -1
        
        if udg_RUA_Amount == 0 then
            call PauseTimer(udg_RUA_TIMER)
        endif
        
    endfunction
    
    function RUA_DestroyUnitAttachmentBJ takes unit attachment returns nothing
        local integer i = 0
        
        loop
            exitwhen i > udg_RUA_Amount
            if attachment == udg_RUA_Param_Attachment[i] then
                call RUA_DestroyUnitAttachment(i)
            endif
        endloop
        
    endfunction
    
endlibrary
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  End RUA System
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////