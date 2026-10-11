library SaveFile requires FileIO
    struct SaveFile extends array
        private File file

        static method getPath takes string charId returns string
            return NSL_FolderName + "\\SaveChar_" + charId + ".pld"
        endmethod
        
        static method create takes player p, string title, string charId, string data returns thistype
            if (GetLocalPlayer() == p) then
                call FileIO_Write(.getPath(charId), title + "\n" + data)
            endif
            return GetPlayerId(p)
        endmethod
        
        static method clear takes player p, string charId returns thistype
            if (GetLocalPlayer() == p) then
                call FileIO_Write(.getPath(charId), "")
            endif
            return GetPlayerId(p)
        endmethod
        
        static method exists takes string charId returns boolean // async
            return StringLength(FileIO_Read(.getPath(charId))) > 1
        endmethod
        
        static method getLines takes string charId, integer line, boolean includePrevious returns string // async
            local string contents   = FileIO_Read(.getPath(charId))
            local integer len       = StringLength(contents)
            local string char       = null
            local string buffer     = ""
            local integer curLine   = 0
            local integer i         = 0
            
            loop
                exitwhen i > len
                set char = SubString(contents, i, i + 1)
                if (char == "\n") then
                    set curLine = curLine + 1
                    if (curLine > line) then
                        return buffer
                    endif
                    if (not includePrevious) then
                        set buffer = ""
                    endif
                else
                    set buffer = buffer + char
                endif
                set i = i + 1
            endloop
            if (curLine == line) then
                return buffer
            endif
            return null
        endmethod
        
        static method getLine takes string charId, integer line returns string // async
            return .getLines(charId, line, false)
        endmethod
        
        static method getTitle takes string charId returns string // async
            return .getLines(charId, 0, false)
        endmethod
        
        static method getData takes string charId returns string // async
            return .getLines(charId, 1, false)
        endmethod
    endstruct
    
endlibrary