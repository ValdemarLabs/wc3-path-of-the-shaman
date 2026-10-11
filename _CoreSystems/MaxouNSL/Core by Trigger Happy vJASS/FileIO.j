library FileIO
/***************************************************************
*
*   v1.1.0, by TriggerHappy
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*
*   Provides functionality to read and write files.
*   _________________________________________________________________________
*   1. Requirements
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       - Patch 1.29 or higher.
*       - JassHelper (vJASS)
*   _________________________________________________________________________
*   2. Installation
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   Copy the script to your map and save it.
*   _________________________________________________________________________
*   3. API
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       struct File extends array
*
*           static constant integer AbilityCount
*           static constant integer PreloadLimit
*
*           readonly static boolean ReadEnabled
*           readonly static integer Counter
*           readonly static integer array List
*
*           static method open takes string filename returns File
*           static method create takes string filename returns File
*
*           ---------
*
*           method write takes string value returns File
*           method read takes nothing returns string
*
*           method readEx takes boolean close returns string
*           method readAndClose takes nothing returns string
*           method readBuffer takes nothing returns string
*           method writeBuffer takes string contents returns nothing
*           method appendBuffer takes string contents returns nothing
*
*           method close takes nothing returns nothing
*
*           public function Write takes string filename, string contents returns nothing
*           public function Read takes string filename returns string
*
***************************************************************/
    private keyword FileInit

    struct File extends array
        static constant integer BufferAbility = 'Z000'
        static constant integer BufferLevelLength = 50
        static constant integer PreloadLimit = 200
        
        readonly static integer Counter = 0
        readonly static integer array List
        
        readonly static boolean ReadEnabled = false
  
        readonly string filename

        private string buffer
        
        static method open takes string filename returns thistype
            local thistype this = .List[0]
        
            if (this == 0) then
                set this = Counter + 1
                set Counter = this
            else
                set .List[0] = .List[this]
            endif
            
            set this.filename = filename
            set this.buffer = null
            
            return this
        endmethod

        method write takes string contents returns thistype
            local integer i = 0
            local integer c = 0
            local integer len = StringLength(contents)
            local string prefix = "-" // this is used to signify an empty string vs a null one
            local string chunk
            
            set this.buffer = null
            
            // Check if the string is empty. If null, the contents will be cleared.
            if (contents == "") then
                set len = len + 1
            endif
            
            // Begin to generate the file
            call PreloadGenClear()
            call PreloadGenStart()
            loop
                exitwhen i >= len
                
                set chunk = SubString(contents, i, i + .PreloadLimit)
                call Preload("\" )\ncall BlzSetAbilityTooltip(" + I2S(.BufferAbility) + ", \"" + prefix + chunk + "\", " + I2S(c) + ")\n//")
                set i = i + .PreloadLimit
                set c = c + 1
            endloop
            call Preload("\" )\nendfunction\nfunction a takes nothing returns nothing\n //")
            call PreloadGenEnd(this.filename)
        
            return this
        endmethod
        
        method clear takes nothing returns thistype
            return this.write(null)
        endmethod
        
        private method readPreload takes nothing returns string
            local integer i = 0
            local string array original
            local string chunk = ""
            local string output = ""
            
            loop
                exitwhen i == .BufferLevelLength
                set original[i] = BlzGetAbilityTooltip(.BufferAbility, i)
                set i = i + 1
            endloop
            
            // Execute the preload file
            call Preloader(this.filename)
            
            // Read the output
            set i = 0
            loop
                exitwhen i == .BufferLevelLength
                
                // Make sure the tooltip has changed
                set chunk = BlzGetAbilityTooltip(.BufferAbility, i)
                
                if (chunk == original[i]) then
                    if (i == 0 and output == "") then
                        return null // empty file
                    endif
                    return output
                endif
                
                if (i == 0) then
                    if (SubString(chunk, 0, 1) != "-") then
                        return null // empty file
                    endif
                    set chunk = SubString(chunk, 1, StringLength(chunk))
                endif
                
                // Remove the prefix
                if (i > 0) then
                    set chunk = SubString(chunk, 1, StringLength(chunk))
                endif
                
                // Restore the tooltip and append the chunk
                call BlzSetAbilityTooltip(.BufferAbility, original[i], i)
                
                set output = output + chunk
                
                set i = i + 1
            endloop
            
            return output
        endmethod
        
        method close takes nothing returns nothing
            if (this.buffer != null) then
                call .write(.readPreload() + this.buffer)
                set this.buffer = null
            endif
            set .List[this] = .List[0]
            set .List[0] = this
        endmethod
        
        method readEx takes boolean close returns string
            local string output = .readPreload()
            local string buf = this.buffer
        
            if (close) then
                call this.close()
            endif
            
            if (output == null) then
                return buf
            endif
            
            if (buf != null) then
                set output = output + buf
            endif
            
            return output
        endmethod
        
        method read takes nothing returns string
            return .readEx(false)
        endmethod
        
        method readAndClose takes nothing returns string
            return .readEx(true)
        endmethod
        
        method appendBuffer takes string contents returns thistype
            set .buffer = .buffer + contents
            return this
        endmethod
  
        method readBuffer takes nothing returns string
            return .buffer
        endmethod
        
        method writeBuffer takes string contents returns nothing
            set .buffer = contents
        endmethod
        
        static method create takes string filename returns thistype
            return .open(filename).write("")
        endmethod
    
        implement FileInit
    endstruct
 
    private module FileInit
        private static method onInit takes nothing returns nothing            
            // Read check
            set File.ReadEnabled = File.open("FileTester.pld").write(SCOPE_PREFIX).readAndClose() == SCOPE_PREFIX
        endmethod
    endmodule
 
    public function Write takes string filename, string contents returns nothing
        call File.open(filename).write(contents).close()
    endfunction
 
    public function Read takes string filename returns string
        return File.open(filename).readEx(true)
    endfunction
 
endlibrary