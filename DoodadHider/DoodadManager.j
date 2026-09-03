/**
    DoodadManager

    Author: Valdemar
    Version: 1.0.0

    Description:
        Provides the map-specific doodad rawcodes and render distances consumed
        by DoodadRender. The initial list contains frequent small decorative
        types selected from the current war3map.doo placement snapshot: 33
        rawcodes covering 12,354 of its 50,118 placement records.

    Credits:
        Placement counts were read from DoodadHider/_reference/war3map.doo.

    How to install:
        Import this library before DoodadRender.j through the normal JassHelper
        workflow. Update this list when the map's doodad placement data changes.

    API:
        DoodadManager_GetTypeCount() -> integer
        DoodadManager_GetTypeId(integer index) -> integer
        DoodadManager_GetDrawDistance(integer index) -> real

**/
library DoodadManager initializer Init
    globals
        // Configuration shared by groups of similarly sized decorative types.
        private constant real SHORT_DISTANCE = 3072.00
        private constant real MEDIUM_DISTANCE = 4096.00

        private integer typeCount = 0
        private integer array typeId
        private real array typeDrawDistance
    endglobals

    private function AddType takes integer doodadId, real drawDistance returns nothing
        set typeCount = typeCount + 1
        set typeId[typeCount] = doodadId
        set typeDrawDistance[typeCount] = drawDistance
    endfunction

    public function GetTypeCount takes nothing returns integer
        return typeCount
    endfunction

    public function GetTypeId takes integer index returns integer
        if index < 1 or index > typeCount then
            return 0
        endif
        return typeId[index]
    endfunction

    public function GetDrawDistance takes integer index returns real
        if index < 1 or index > typeCount then
            return 0.00
        endif
        return typeDrawDistance[index]
    endfunction

    private function Init takes nothing returns nothing
        // Bushes, grass, flowers, ferns, and other small foliage.
        call AddType('D63R', SHORT_DISTANCE)  // HFMBush GladeA: 3616
        call AddType('D63S', SHORT_DISTANCE)  // HFMBush GladeA DEAD: 947
        call AddType('D66E', SHORT_DISTANCE)  // lumpygrass01: 807
        call AddType('D661', SHORT_DISTANCE)  // bramble_01: 543
        call AddType('D63T', SHORT_DISTANCE)  // HFMGrass Glade A: 542
        call AddType('D6DD', SHORT_DISTANCE)  // Tree_crystalsongaspenbush02: 291
        call AddType('D63U', SHORT_DISTANCE)  // HFMGrass Glade B: 236
        call AddType('D619', SHORT_DISTANCE)  // Grass: Animated 2: 219
        call AddType('D696', SHORT_DISTANCE)  // STV Plant08: 204
        call AddType('D611', SHORT_DISTANCE)  // Bushes: 195
        call AddType('D63V', SHORT_DISTANCE)  // HFMFlowers Glade A: 166
        call AddType('D664', SHORT_DISTANCE)  // bush_05: 152
        call AddType('D6DV', SHORT_DISTANCE)  // Tree_8swa_watergrass_b01: 137
        call AddType('D62L', SHORT_DISTANCE)  // Shrub: Fern (2): 126
        call AddType('D6DC', SHORT_DISTANCE)  // Tree_crystalsongaspenbush01: 119
        call AddType('D66F', SHORT_DISTANCE)  // lumpygrass01_dark: 107
        call AddType('D667', SHORT_DISTANCE)  // bush_bush_dark_02: 88
        call AddType('D665', SHORT_DISTANCE)  // bush_05_green: 83
        call AddType('D6FY', SHORT_DISTANCE)  // RUBY_db_flowers01: 81
        call AddType('D6DW', SHORT_DISTANCE)  // Tree_8swa_watergrass_b03: 66
        call AddType('D62R', SHORT_DISTANCE)  // Shrub: Fern (7): 63
        call AddType('D022', SHORT_DISTANCE)  // lumpygrass01_light: 61
        call AddType('D6FZ', SHORT_DISTANCE)  // RUBY_db_flowers02: 52

        // Rocks and compact conifers use a longer range to reduce visible pop-in.
        call AddType('D62D', MEDIUM_DISTANCE) // Rock: Boulder 1: 934
        call AddType('D63G', MEDIUM_DISTANCE) // HFMFir A: 845
        call AddType('D62E', MEDIUM_DISTANCE) // Rock: Boulder 1b: 561
        call AddType('D00Z', MEDIUM_DISTANCE) // Rock: od_small_6: 378
        call AddType('D63L', MEDIUM_DISTANCE) // HFMRock Crag 2x2: 282
        call AddType('D63Q', MEDIUM_DISTANCE) // HFMRock Crag Mound: 128
        call AddType('D63K', MEDIUM_DISTANCE) // HFMRock Crag 1x1: 103
        call AddType('D63H', MEDIUM_DISTANCE) // HFMFir B: 81
        call AddType('D010', MEDIUM_DISTANCE) // Rock: od_small_7: 78
        call AddType('D6AN', MEDIUM_DISTANCE) // Rock09: 63
    endfunction
endlibrary
