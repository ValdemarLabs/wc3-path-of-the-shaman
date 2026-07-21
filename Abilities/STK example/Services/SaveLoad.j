library STKSaveLoad requires BSRW

    globals
        public constant integer MAX_TALENT_SLOTS = STKConstants_MAX_TALENT_SLOTS
        public constant integer MAX_SAVED_TALENT_POINTS = STKConstants_MAX_SAVED_TALENT_POINTS
        
        public constant integer TALENTTREE_ID_THRESHOLD_SMALL = STKConstants_TALENTTREE_ID_THRESHOLD_SMALL
        public constant integer TALENTTREE_ID_THRESHOLD_LARGE = STKConstants_TALENTTREE_ID_THRESHOLD_LARGE

        public constant integer TALENT_ID_THRESHOLD_SMALL = STKConstants_TALENT_ID_THRESHOLD_SMALL
        public constant integer TALENT_ID_THRESHOLD_LARGE = STKConstants_TALENT_ID_THRESHOLD_LARGE
        
        public constant integer TALENT_RANK_THRESHOLD_SMALL = STKConstants_TALENT_RANK_THRESHOLD_SMALL
        public constant integer TALENT_RANK_THRESHOLD_MEDIUM = STKConstants_TALENT_RANK_THRESHOLD_MEDIUM
        public constant integer TALENT_RANK_THRESHOLD_LARGE = STKConstants_TALENT_RANK_THRESHOLD_LARGE
        public constant integer TALENT_RANK_THRESHOLD_EXTRA = STKConstants_TALENT_RANK_THRESHOLD_EXTRA
    endglobals

    function interface AssignTalentTreeFunction takes integer panelId, unit u, STKTalentTree_TalentTree createdTalentTree returns nothing
    function interface TalentTreeFactory takes unit u returns STKTalentTree_TalentTree

    // Private globals
    globals
        private constant string array Threshold2SizeName[2]
        private constant string array Threshold4SizeName[4]

        private constant integer array TalentTreeIdThreshold[2]
        private constant integer array TalentIdThreshold[2]
        private constant integer array TalentRankThreshold[4]

        private TalentTreeFactory array TalentTreeFactories[TALENT_ID_THRESHOLD_LARGE]
        private integer MaxTalentTreeId = 0

        private integer array TempArrayChainIndex[TALENT_ID_THRESHOLD_LARGE]
        private string SaveCodeCharset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$#0123456789"
        private integer SaveCodeCharsetBase = 6
        private STKStore Store
        private AssignTalentTreeFunction AssignTalentTree
    endglobals

    private function getCharIndex takes string char returns integer
        local integer i = 0
        local integer length = StringLength(SaveCodeCharset)
        loop
            exitwhen i >= length or char == SubString(SaveCodeCharset, i, i+1)
            set i = i + 1
        endloop
        return i
    endfunction

    private function nextPowerOfTwo takes integer n returns integer
        local integer value = 1
        loop
            exitwhen value >= n
            set value = value * 2
        endloop
        return value
    endfunction

    private function getThresholdValue takes integer size, integer whichThreshold returns integer
        local integer value = -1
        if (whichThreshold == 0) then // talentTreeId
            set value = TalentTreeIdThreshold[size]
        elseif (whichThreshold == 1) then // talentId
            set value = TalentIdThreshold[size]
        elseif (whichThreshold == 2) then // talentRank
            set value = TalentRankThreshold[size]
        elseif (whichThreshold == 3) then // talentPoints
            set value = MAX_SAVED_TALENT_POINTS
        endif
        return value
    endfunction

    private function findSizeBits takes integer value, integer whichThreshold returns integer
        local integer thresholdKey = 0
        local integer i = 0
        local integer threshold = 0
        local integer bits = 0
        loop
            set threshold = getThresholdValue(i, whichThreshold)
            exitwhen value < threshold or threshold == 0
            set thresholdKey = i
            set i = i + 1
        endloop
    
        set threshold = getThresholdValue(thresholdKey, whichThreshold)
        loop
            set bits = bits + 1
            set threshold = threshold / 2
            exitwhen threshold <= 1
        endloop
        return bits
    endfunction

    private function findThresholdSize takes integer value, integer whichThreshold returns integer
        local integer size = 0
        local integer threshold = getThresholdValue(size, whichThreshold)
        loop
            exitwhen value < threshold or threshold == 0
            set size = size + 1
            set threshold = getThresholdValue(size, whichThreshold)
        endloop
        return size
    endfunction

    public function RegisterTalentTree takes integer id, TalentTreeFactory factoryMethod returns boolean
        local TalentTreeFactory f = TalentTreeFactories[id]
        if (id == 0) then
            call BJDebugMsg("|cffdd0808STK-Error: IDs should start from 1, not 0. (SaveLoad.RegisterTalentTree)")
            return false
        endif
        if (f != 0) then
            call BJDebugMsg("|cffdd0808STK-Error: " + I2S(id) + " is already used. (SaveLoad.RegisterTalentTree)")
            return false
        endif
        set TalentTreeFactories[id] = factoryMethod
        if (id > MaxTalentTreeId) then
            set MaxTalentTreeId = id
        endif
        return true
    endfunction
    
    public function InspectTalentTree takes integer panelId, BSRW_BitStreamReader stream, integer talentTreeIdBits, integer talentIdBits, integer talentRankBits, integer talentPointBits returns nothing
        local integer talentTreeId = 0
        local integer talentPoints = 0
        local integer readMode = 0
        local integer talentCount = 0
        local integer talentId = 0
        local integer talentRank = 0
        local integer i = 0

        set talentTreeId = stream.readInt(talentTreeIdBits)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Tree Id: " + I2S(talentTreeId))

        set talentPoints = stream.readInt(talentPointBits)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Points: " + I2S(talentPoints))

        set readMode = stream.readInt(1)

        // Sequential
        if (readMode == 0) then
            call BJDebugMsg(stream.lastReadChunk + " - Read mode: Sequential")

            set talentCount = stream.readInt(talentIdBits)
            call BJDebugMsg(stream.lastReadChunk + " - Talent with Ranks Count: " + I2S(talentCount))

            set i = 0
            loop
                exitwhen i == talentCount

                set talentId = stream.readInt(talentIdBits)
                call BJDebugMsg(stream.lastReadChunk + " - Talent Id: " + I2S(talentId))

                set talentRank = stream.readInt(talentRankBits)
                call BJDebugMsg(stream.lastReadChunk + " - Talent [" + I2S(talentId) + "] Rank: " + I2S(talentRank))
                
                set i = i + 1
            endloop
        endif

        // Positional
        if (readMode == 1) then
            call BJDebugMsg(stream.lastReadChunk + " - Read mode: Positional")
            
            set talentCount = stream.readInt(talentIdBits)
            call BJDebugMsg(stream.lastReadChunk + " - Max Talent Id: " + I2S(talentCount))

            set i = 0
            loop
                exitwhen i == talentCount

                set talentId = i + 1
                set talentRank = stream.readInt(talentRankBits)
                call BJDebugMsg(stream.lastReadChunk + " - Talent [" + I2S(talentId) + "] Rank: " + I2S(talentRank))
                
                set i = i + 1
            endloop
        endif
    endfunction

    public function LoadTalentTree takes integer panelId, BSRW_BitStreamReader stream, integer talentTreeIdBits, integer talentIdBits, integer talentRankBits, integer talentPointBits, unit owner returns STKTalentTree_TalentTree
        local integer talentTreeId = 0
        local integer talentPoints = 0
        local integer readMode = 0
        local integer talentCount = 0
        local integer talentId = 0
        local integer talentRank = 0
        local integer i = 0
        local STKTalentTree_TalentTree tree

        set talentTreeId = stream.readInt(talentTreeIdBits)
        set talentPoints = stream.readInt(talentPointBits)

        set tree = TalentTreeFactories[talentTreeId].evaluate(owner)
        call AssignTalentTree.execute(panelId, owner, tree)
        call tree.UpdateChainIdTalentIndex()
        call tree.SetTalentPoints(talentPoints)

        set readMode = stream.readInt(1)

        // Sequential
        if (readMode == 0) then
            set talentCount = stream.readInt(talentIdBits)

            set i = 0
            loop
                exitwhen i == talentCount
                set talentId = stream.readInt(talentIdBits)
                set talentRank = stream.readInt(talentRankBits)
                call tree.ApplyTalentChainTemporary(talentId, talentRank)
                
                set i = i + 1
            endloop
        endif

        // Positional
        if (readMode == 1) then
            set talentCount = stream.readInt(talentIdBits)

            set i = 0
            loop
                exitwhen i == talentCount

                set talentId = i + 1
                set talentRank = stream.readInt(talentRankBits)

                if (talentRank > 0) then
                    call tree.ApplyTalentChainTemporary(talentId, talentRank)
                endif
                
                set i = i + 1
            endloop
        endif

        call tree.SaveTalentRankState()
        return tree
    endfunction

    public function SaveTalentTree takes BSRW_BitStreamWriter stream, integer talentTreeIdBits, integer talentIdBits, integer talentRankBits, integer talentPointBits, STKTalentTree_TalentTree tree returns nothing
        local integer i = 0
        local integer talentCount = 0
        local integer minChainId = 0
        local integer maxChainId = 0
        local integer chainId = 0
        local string seq = ""
        local string pos = ""
        local BSRW_BitStreamWriter tempWriter = BSRW_BitStreamWriter.create()

        set i = 0
        loop
            exitwhen i == MAX_TALENT_SLOTS
            set TempArrayChainIndex[i] = 0
            set i = i + 1
        endloop

        // Talent Tree Id
        call stream.write(tree.GetId(), talentTreeIdBits)
        // Talent Points
        call stream.write(tree.GetTalentPoints(), talentPointBits)

        // Sequential
        set talentCount = 0
        set i = 0
        loop
            exitwhen i == MAX_TALENT_SLOTS
            if (tree.rankState[i] > 0 and tree.talents[i] > 0) then
                set talentCount = talentCount + 1
                call tempWriter.write(tree.talents[i].GetChainId(), talentIdBits)
                call tempWriter.write(tree.rankState[i], talentRankBits)
            endif
            set i = i + 1
        endloop
        set seq = tempWriter.get()
        call tempWriter.flush().write(talentCount, talentIdBits)
        set seq = tempWriter.get() + seq

        // Positional
        set maxChainId = 0
        set minChainId = MAX_TALENT_SLOTS
        set i = 0
        loop
            exitwhen i == MAX_TALENT_SLOTS
            if (tree.rankState[i] > 0 and tree.talents[i] > 0) then
                set chainId = tree.talents[i].GetChainId()
                if (chainId > maxChainId) then
                    // Highest chain id
                    set maxChainId = chainId
                endif
                if (chainId < minChainId) then
                    set minChainId = chainId
                endif
                if (TempArrayChainIndex[chainId] > 0) then
                    call BJDebugMsg("|cffdd0808STK-Error: Talents on different grid positions should not share Chain ID " + I2S(chainId) + " (" + tree.talents[i].name + "). (SaveLoad.SaveTalentTree)")
                endif
                set TempArrayChainIndex[chainId] = i
            endif
            set i = i + 1
        endloop

        call tempWriter.flush().write(talentCount, talentIdBits)
        set i = minChainId
        loop
            exitwhen i > maxChainId
            call tempWriter.write(tree.rankState[TempArrayChainIndex[i]], talentRankBits)
            set i = i + 1
        endloop
        set pos = tempWriter.get()
        
        if (StringLength(seq) < StringLength(pos)) then
            call stream.write(0, 1)
            call stream.writeStream(seq)
        else
            call stream.write(1, 1)
            call stream.writeStream(pos)
        endif

        call tempWriter.destroy()
        set seq = null
        set pos = null
    endfunction

    public function Inspect takes string bitString returns nothing
        local integer i = 0
        
        local integer talentTreeIdSize = 0
        local integer talentRankSize = 0
        local integer talentIdSize = 0
        
        local integer talentTreeIdBits = 0
        local integer talentIdBits = 0
        local integer talentRankBits = 0        
        local integer talentPointBits = 0
        
        local integer talentTreeId = 0
        local integer talentTreeCount = 0

        local BSRW_BitStreamReader stream = BSRW_BitStreamReader.create(bitString)

        set talentTreeIdSize = stream.readInt(1)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Tree Id size: " + Threshold2SizeName[talentTreeIdSize] + " threshold: " + I2S(TalentTreeIdThreshold[talentTreeIdSize]))

        set talentRankSize = stream.readInt(2)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Rank size: " + Threshold4SizeName[talentRankSize] + " threshold: " + I2S(TalentRankThreshold[talentRankSize]))

        set talentIdSize = stream.readInt(1)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Id size: " + Threshold2SizeName[talentIdSize] + " threshold: " + I2S(TalentIdThreshold[talentIdSize]))

        // Talent Tree Count
        set talentTreeCount = stream.readInt(4)
        call BJDebugMsg(stream.lastReadChunk + " - Talent Tree count: " + I2S(talentTreeCount))

        // Bit sizes
        set talentTreeIdBits = findSizeBits(talentTreeIdSize, 0)
        set talentIdBits = findSizeBits(talentIdSize, 1)
        set talentRankBits = findSizeBits(talentRankSize, 2)
        set talentPointBits = findSizeBits(0, 3)

        // Talent Trees
        set i = 0
        loop
            exitwhen i == talentTreeCount
            call InspectTalentTree(i + 1, stream, talentTreeIdBits, talentIdBits, talentRankBits, talentPointBits)
            set i = i + 1
        endloop

        call stream.destroy()
    endfunction

    public function LoadForUnit takes unit owner, string bitString returns nothing
        local integer i = 0
        local STKTalentTree_TalentTree tt
        
        local integer talentTreeIdSize = 0
        local integer talentRankSize = 0
        local integer talentIdSize = 0
        
        local integer talentTreeIdBits = 0
        local integer talentIdBits = 0
        local integer talentRankBits = 0        
        local integer talentPointBits = 0
        
        local integer talentTreeId = 0
        local integer talentTreeCount = 0

        local BSRW_BitStreamReader stream = BSRW_BitStreamReader.create(bitString)

        set talentTreeIdSize = stream.readInt(1)
        set talentRankSize = stream.readInt(2)
        set talentIdSize = stream.readInt(1)

        // Talent Tree Count
        set talentTreeCount = stream.readInt(4)

        // Bit sizes
        set talentTreeIdBits = findSizeBits(talentTreeIdSize, 0)
        set talentIdBits = findSizeBits(talentIdSize, 1)
        set talentRankBits = findSizeBits(talentRankSize, 2)
        set talentPointBits = findSizeBits(0, 3)

        // Talent Trees
        set i = 0
        loop
            exitwhen i == talentTreeCount
            set tt = LoadTalentTree(i + 1, stream, talentTreeIdBits, talentIdBits, talentRankBits, talentPointBits, owner)
            set i = i + 1
        endloop

        call stream.destroy()
    endfunction

    public function SaveForUnit takes unit owner returns string
        local integer i = 0
        local integer j = 0
        local integer maxTalentRank = 0
        local integer maxTalentId = 0
        local integer talentTreeCount = 0
        
        local integer talentTreeIdSize = 0
        local integer talentIdSize = 0
        local integer talentRankSize = 0
        
        local integer talentTreeIdBits = 0
        local integer talentIdBits = 0
        local integer talentRankBits = 0
        local integer talentPointBits = 0
        
        local STKTalentTree_TalentTree tt
        local integer talentTreeId = 0

        local BSRW_BitStreamWriter stream
        local string bitString

        // Loop over unit's talent trees
        // And find maxTalentRank, maxTalentId
        set j = 1
        loop
            set tt = Store.GetUnitTalentTree(j, owner)
            exitwhen tt <= 0

            set talentTreeCount = talentTreeCount + 1
            set i = 0
            loop
                exitwhen i == MAX_TALENT_SLOTS
                if (tt.rankState[i] > maxTalentRank) then
                    set maxTalentRank = tt.rankState[i]
                endif
                if (tt.talents[i].GetChainId() > maxTalentId) then
                    set maxTalentId = tt.talents[i].GetChainId()
                endif
                set i = i + 1
            endloop

            set j = j + 1
        endloop

        set talentTreeIdSize = findThresholdSize(MaxTalentTreeId, 0)
        set talentIdSize = findThresholdSize(maxTalentId, 1)
        set talentRankSize = findThresholdSize(maxTalentRank, 2)

        set stream = BSRW_BitStreamWriter.create()

        call stream.write(talentTreeIdSize, 1)
        call stream.write(talentRankSize, 2)
        call stream.write(talentIdSize, 1)

        // Talent Tree Count
        call stream.write(talentTreeCount, 4)

        // Bit sizes
        set talentTreeIdBits = findSizeBits(talentTreeIdSize, 0)
        set talentIdBits = findSizeBits(talentIdSize, 1)
        set talentRankBits = findSizeBits(talentRankSize, 2)
        set talentPointBits = findSizeBits(0, 3)

        // Talent Trees
        set i = 1
        loop
            set tt = Store.GetUnitTalentTree(i, owner)
            exitwhen tt <= 0
            call SaveTalentTree(stream, talentTreeIdBits, talentIdBits, talentRankBits, talentPointBits, tt)
            set i = i + 1
        endloop

        set bitString = stream.get()
        call stream.destroy()
        return bitString
    endfunction

    public function InspectEncoded takes string saveCode returns nothing
        local BSRW_BitStreamWriter writer = BSRW_BitStreamWriter.create()
        local integer length = StringLength(saveCode)
        local integer index = 0
        local integer i = 0
        local string char = ""
    
        set i = 0
        loop
            exitwhen i >= length
            set char = SubString(saveCode, i, i+1)
            
            set index = getCharIndex(char)
        
            if (index >= 0) then
                call writer.write(index, SaveCodeCharsetBase)
            endif
            set i = i + 1
        endloop

        call Inspect(writer.get())
        call writer.destroy()
        set char = null
    endfunction

    public function LoadForUnitEncoded takes unit owner, string saveCode returns nothing
        local BSRW_BitStreamWriter writer = BSRW_BitStreamWriter.create()
        local integer length = StringLength(saveCode)
        local integer index = 0
        local integer i = 0
        local string character = ""
    
        set i = 0
        loop
            exitwhen i >= length
            set character = SubString(saveCode, i, i+1)
            
            set index = getCharIndex(character)
        
            if (index >= 0) then
                call writer.write(index, SaveCodeCharsetBase)
            endif
            set i = i + 1
        endloop

        set character = writer.get()

        call LoadForUnit(owner, character)
        call writer.destroy()
        set character = null
    endfunction

    public function SaveForUnitEncoded takes unit owner returns string
        local string encoded = ""
        local string bitString = SaveForUnit(owner)
        local integer bitStringLength = StringLength(bitString)
        local integer remainder = ModuloInteger(bitStringLength, SaveCodeCharsetBase)
        local integer i = 0
        local integer value = 0
        local BSRW_BitStreamReader reader

        // Padding up to the SaveCodeCharset base
        if (remainder != 0) then
            set i = SaveCodeCharsetBase - remainder
            loop
                exitwhen i <= 0
                set bitString = bitString + "0"
                set i = i - 1
            endloop
        endif
        set reader = BSRW_BitStreamReader.create(bitString)

        set i = 0
        loop
            exitwhen i >= bitStringLength
            set value = reader.readInt(SaveCodeCharsetBase)
            set encoded = encoded + SubString(SaveCodeCharset, value, value + 1)
            set i = i + SaveCodeCharsetBase
        endloop

        call reader.destroy()
        return encoded
    endfunction

    public function Initialize takes STKStore store, AssignTalentTreeFunction assignTalentTree returns nothing
        local integer i = 0
        local string char = ""

        set Threshold2SizeName[0] = "SMALL"
        set Threshold2SizeName[1] = "LARGE"

        set Threshold4SizeName[0] = "SMALL"
        set Threshold4SizeName[1] = "MEDIUM"
        set Threshold4SizeName[2] = "LARGE"
        set Threshold4SizeName[3] = "EXTRA"

        set TalentTreeIdThreshold[0] = TALENTTREE_ID_THRESHOLD_SMALL
        set TalentTreeIdThreshold[1] = TALENTTREE_ID_THRESHOLD_LARGE

        set TalentIdThreshold[0] = TALENT_ID_THRESHOLD_SMALL
        set TalentIdThreshold[1] = TALENT_ID_THRESHOLD_LARGE
        
        set TalentRankThreshold[0] = TALENT_RANK_THRESHOLD_SMALL
        set TalentRankThreshold[1] = TALENT_RANK_THRESHOLD_MEDIUM
        set TalentRankThreshold[2] = TALENT_RANK_THRESHOLD_LARGE
        set TalentRankThreshold[3] = TALENT_RANK_THRESHOLD_EXTRA

        set TalentTreeIdThreshold[2] = 0
        set TalentIdThreshold[2] = 0
        set TalentRankThreshold[4] = 0

        set Store = store
        set AssignTalentTree = assignTalentTree
    endfunction
endlibrary