/*



            Don't edit this
            


*/
library NSLCodexStore
    globals
        private CodexFormat array CodexArray
        private integer array CodexVersion
        private integer CodexSize = 0
    endglobals
    
    function interface CodexFormat takes integer playerId, NSL_Code loader returns nothing

    public function Add takes integer codex_version, CodexFormat codex returns nothing
        set CodexArray[CodexSize] = codex
        set CodexVersion[CodexSize] = codex_version
        set CodexSize = CodexSize + 1
    endfunction
    
    public function GetCodexForVersion takes integer codex_version returns CodexFormat
        local integer i = 0
        loop
            exitwhen i == CodexSize
            if(CodexVersion[i] == codex_version) then
                return CodexArray[i]
            endif
            set i = i + 1
        endloop
        return -1
    endfunction
endlibrary