library TerrainTextureColors initializer Init
//===========================================================================
/*
    Terrain Texture Colors for RPG Minimap
    
    Provides color values (RGB) for all Warcraft 3 terrain types.
    Used by minimap systems to colorize terrain tiles.
    
    Usage:
        local integer color = GetTerrainColorForType(GetTerrainType(x, y))
        // color is a BlzConvertColor integer
*/
//===========================================================================

globals
    private hashtable TerrainColors = InitHashtable()
endglobals

//===========================================================================
// Get terrain color by fourCC integer
//===========================================================================
function GetTerrainColorForType takes integer terrainType returns integer
    return LoadInteger(TerrainColors, 0, terrainType)
endfunction

//===========================================================================
// Get RGB components (for custom blending)
//===========================================================================
function GetTerrainRGB takes integer terrainType, integer component returns integer
    // component: 0=red, 1=green, 2=blue
    return LoadInteger(TerrainColors, 1 + component, terrainType)
endfunction

//===========================================================================
// Initialize terrain color table
//===========================================================================
private function InitTerrainColors takes nothing returns nothing
    local integer fourCC
    local integer r
    local integer g
    local integer b
    
    // Ashenvale terrain types
    set fourCC = 'Adrt' // Ashen_Dirt
    set r = 66
    set g = 64
    set b = 23
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Adrg' // Ashen_DirtGrass
    set r = 48
    set g = 70
    set b = 12
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Adrd' // Ashen_DirtRough
    set r = 49
    set g = 58
    set b = 20
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Agrs' // Ashen_Grass
    set r = 42
    set g = 84
    set b = 15
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Agrd' // Ashen_GrassLumpy
    set r = 40
    set g = 66
    set b = 20
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Alvd' // Ashen_Leaves
    set r = 32
    set g = 51
    set b = 23
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Arck' // Ashen_Rock
    set r = 114
    set g = 119
    set b = 74
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Avin' // Ashen_Vines
    set r = 29
    set g = 68
    set b = 24
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Barrens terrain types
    set fourCC = 'Bdsr' // Barrens_Desert
    set r = 133
    set g = 87
    set b = 50
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bdsd' // Barrens_DesertDark
    set r = 102
    set g = 61
    set b = 28
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bdrt' // Barrens_Dirt
    set r = 83
    set g = 53
    set b = 32
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bdrg' // Barrens_DirtGrass
    set r = 75
    set g = 43
    set b = 15
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bdrh' // Barrens_DirtRough
    set r = 56
    set g = 34
    set b = 18
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bgrr' // Barrens_Grass
    set r = 119
    set g = 70
    set b = 10
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bdrr' // Barrens_Pebbles
    set r = 88
    set g = 47
    set b = 32
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Bflr' // Barrens_Rock
    set r = 80
    set g = 39
    set b = 27
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Cityscape terrain types
    set fourCC = 'Yblm' // City_BlackMarble
    set r = 40
    set g = 32
    set b = 20
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ybtl' // City_BrickTiles
    set r = 149
    set g = 136
    set b = 117
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ydrt' // City_Dirt
    set r = 77
    set g = 73
    set b = 38
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ydtr' // City_DirtRough
    set r = 61
    set g = 61
    set b = 29
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ygsb' // City_Grass
    set r = 20
    set g = 71
    set b = 18
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Yhdg' // City_GrassTrim
    set r = 7
    set g = 44
    set b = 5
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Yrtl' // City_RoundTiles
    set r = 91
    set g = 83
    set b = 72
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ysqd' // City_SquareTiles
    set r = 132
    set g = 112
    set b = 82
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ywmb' // City_WhiteMarble
    set r = 173
    set g = 165
    set b = 157
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Dalaran terrain types
    set fourCC = 'Xblm' // Dalaran_BlackMarble
    set r = 49
    set g = 26
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xbtl' // Dalaran_BrickTiles
    set r = 154
    set g = 138
    set b = 138
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xdrt' // Dalaran_Dirt
    set r = 71
    set g = 67
    set b = 45
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xdtr' // Dalaran_DirtRough
    set r = 56
    set g = 55
    set b = 34
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xgsb' // Dalaran_Grass
    set r = 28
    set g = 70
    set b = 16
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xhdg' // Dalaran_GrassTrim
    set r = 8
    set g = 44
    set b = 5
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xrtl' // Dalaran_RoundTiles
    set r = 126
    set g = 114
    set b = 108
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xsqd' // Dalaran_SquareTiles
    set r = 92
    set g = 62
    set b = 85
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Xwmb' // Dalaran_WhiteMarble
    set r = 167
    set g = 167
    set b = 167
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Dungeon terrain types
    set fourCC = 'Dbrk' // Cave_Brick
    set r = 54
    set g = 18
    set b = 19
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ddkr' // Cave_DarkRocks
    set r = 62
    set g = 20
    set b = 16
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ddrt' // Cave_Dirt
    set r = 56
    set g = 25
    set b = 21
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Dgrs' // Cave_GreyStones
    set r = 42
    set g = 14
    set b = 12
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Dlav' // Cave_Lava
    set r = 200
    set g = 40
    set b = 4
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Dlvc' // Cave_LavaCracks
    set r = 133
    set g = 14
    set b = 2
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Drds' // Cave_RedStones
    set r = 91
    set g = 23
    set b = 16
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Dsqd' // Cave_SquareTiles
    set r = 75
    set g = 49
    set b = 46
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Dungeon2 (Underground) terrain types
    set fourCC = 'Gbrk'
    set r = 27
    set g = 42
    set b = 39
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Gdkr'
    set r = 14
    set g = 30
    set b = 16
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Gdrt'
    set r = 18
    set g = 34
    set b = 31
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ggrs'
    set r = 20
    set g = 21
    set b = 19
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Glav'
    set r = 52
    set g = 155
    set b = 166
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Glvc'
    set r = 26
    set g = 97
    set b = 100
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Grds'
    set r = 28
    set g = 40
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Gsqd'
    set r = 47
    set g = 53
    set b = 41
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Felwood terrain types
    set fourCC = 'Cdrt'
    set r = 39
    set g = 54
    set b = 49
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Cdrd'
    set r = 27
    set g = 42
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Cgrs'
    set r = 19
    set g = 56
    set b = 27
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Clvg'
    set r = 20
    set g = 48
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Cpos'
    set r = 20
    set g = 87
    set b = 5
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Crck'
    set r = 5
    set g = 46
    set b = 28
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Cvin'
    set r = 24
    set g = 58
    set b = 37
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // LordaeronFall terrain types
    set fourCC = 'Fdrt'
    set r = 111
    set g = 86
    set b = 49
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Fdrg'
    set r = 102
    set g = 76
    set b = 25
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Fdro'
    set r = 108
    set g = 80
    set b = 45
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Fgrs'
    set r = 114
    set g = 79
    set b = 19
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Fgrd'
    set r = 92
    set g = 61
    set b = 11
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Frok'
    set r = 139
    set g = 108
    set b = 96
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // LordaeronSummer terrain types
    set fourCC = 'Ldrt'
    set r = 145
    set g = 101
    set b = 54
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ldrg'
    set r = 107
    set g = 98
    set b = 36
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ldro'
    set r = 141
    set g = 98
    set b = 51
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Lgrs'
    set r = 36
    set g = 117
    set b = 25
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Lgrd'
    set r = 11
    set g = 87
    set b = 12
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Lrok'
    set r = 139
    set g = 108
    set b = 96
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ltdt' // Lordaeron_DarkTile
    set r = 45
    set g = 70
    set b = 35
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Lsks' // Lordaeron_SnowyRocks
    set r = 115
    set g = 115
    set b = 115
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // LordaeronWinter terrain types
    set fourCC = 'Wdrt'
    set r = 76
    set g = 77
    set b = 60
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Wdro'
    set r = 72
    set g = 76
    set b = 61
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Wgrs'
    set r = 35
    set g = 68
    set b = 61
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Wrok'
    set r = 92
    set g = 77
    set b = 63
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Wsnw'
    set r = 189
    set g = 208
    set b = 228
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Wsng'
    set r = 66
    set g = 75
    set b = 59
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Northrend terrain types
    set fourCC = 'Ndrt'
    set r = 34
    set g = 61
    set b = 53
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ndrd'
    set r = 20
    set g = 42
    set b = 37
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ngrs'
    set r = 17
    set g = 80
    set b = 74
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Nice'
    set r = 89
    set g = 160
    set b = 184
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Nrck'
    set r = 18
    set g = 53
    set b = 58
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Nsnw'
    set r = 189
    set g = 208
    set b = 228
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Nsnr'
    set r = 124
    set g = 159
    set b = 176
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Village terrain types
    set fourCC = 'Vcbp'
    set r = 62
    set g = 53
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vcrp'
    set r = 54
    set g = 66
    set b = 30
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vdrt'
    set r = 77
    set g = 73
    set b = 38
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vdrr'
    set r = 61
    set g = 61
    set b = 29
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vgrs'
    set r = 68
    set g = 79
    set b = 28
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vgrt'
    set r = 20
    set g = 71
    set b = 18
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vrck'
    set r = 100
    set g = 101
    set b = 69
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Vstp'
    set r = 106
    set g = 92
    set b = 60
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // VillageFall terrain types
    set fourCC = 'Qcbp'
    set r = 59
    set g = 48
    set b = 29
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qcrp'
    set r = 64
    set g = 64
    set b = 22
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qdrt'
    set r = 74
    set g = 70
    set b = 41
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qdrr'
    set r = 58
    set g = 58
    set b = 32
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qgrs'
    set r = 73
    set g = 55
    set b = 19
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qgrt'
    set r = 94
    set g = 58
    set b = 9
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qrck'
    set r = 106
    set g = 90
    set b = 72
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Qstp'
    set r = 97
    set g = 87
    set b = 67
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // BlackCitadel terrain types
    set fourCC = 'Kdkt'
    set r = 40
    set g = 14
    set b = 14
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Kdrt'
    set r = 101
    set g = 26
    set b = 9
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Kfsl'
    set r = 105
    set g = 46
    set b = 18
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Kfst'
    set r = 45
    set g = 8
    set b = 1
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Klgb'
    set r = 51
    set g = 9
    set b = 9
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Kdtr'
    set r = 54
    set g = 18
    set b = 3
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ksmb'
    set r = 75
    set g = 23
    set b = 11
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ksqt'
    set r = 18
    set g = 3
    set b = 2
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // DalaranRuins terrain types
    set fourCC = 'Jblm'
    set r = 29
    set g = 16
    set b = 19
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jbtl'
    set r = 59
    set g = 50
    set b = 48
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jdrt'
    set r = 55
    set g = 52
    set b = 38
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jdtr'
    set r = 36
    set g = 36
    set b = 21
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jgsb'
    set r = 34
    set g = 42
    set b = 22
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jhdg'
    set r = 17
    set g = 26
    set b = 13
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jrtl'
    set r = 35
    set g = 30
    set b = 28
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jsgd'
    set r = 45
    set g = 27
    set b = 40
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Jwmb'
    set r = 73
    set g = 73
    set b = 73
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Icecrown terrain types
    set fourCC = 'Ibkb'
    set r = 3
    set g = 21
    set b = 26
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ibsq'
    set r = 2
    set g = 24
    set b = 26
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Idki'
    set r = 16
    set g = 115
    set b = 122
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Idrt'
    set r = 30
    set g = 49
    set b = 53
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Idtr'
    set r = 15
    set g = 25
    set b = 27
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Iice'
    set r = 95
    set g = 189
    set b = 207
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Irbk'
    set r = 15
    set g = 43
    set b = 49
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Isnw'
    set r = 152
    set g = 209
    set b = 230
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Itbk'
    set r = 6
    set g = 60
    set b = 67
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Outland terrain types
    set fourCC = 'Oaby'
    set r = 0
    set g = 0
    set b = 0
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Odrt'
    set r = 101
    set g = 26
    set b = 9
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ofst'
    set r = 99
    set g = 30
    set b = 11
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Odtr'
    set r = 105
    set g = 46
    set b = 18
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Olgb'
    set r = 45
    set g = 8
    set b = 1
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ofsl'
    set r = 118
    set g = 55
    set b = 25
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Orok'
    set r = 36
    set g = 3
    set b = 1
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Osmb'
    set r = 54
    set g = 18
    set b = 3
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    // Ruins terrain types
    set fourCC = 'Zdrt'
    set r = 107
    set g = 106
    set b = 55
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zdrg'
    set r = 73
    set g = 98
    set b = 32
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zdtr'
    set r = 82
    set g = 81
    set b = 33
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zgrs'
    set r = 11
    set g = 87
    set b = 12
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zvin'
    set r = 0
    set g = 46
    set b = 0
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zbkl'
    set r = 142
    set g = 133
    set b = 75
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Ztil'
    set r = 39
    set g = 83
    set b = 34
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zsan'
    set r = 121
    set g = 120
    set b = 69
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    set fourCC = 'Zbks'
    set r = 58
    set g = 69
    set b = 27
    call SaveInteger(TerrainColors, 0, fourCC, BlzConvertColor(255, r, g, b))
    call SaveInteger(TerrainColors, 1, fourCC, r)
    call SaveInteger(TerrainColors, 2, fourCC, g)
    call SaveInteger(TerrainColors, 3, fourCC, b)
    
    call BJDebugMsg("|cff00ff00TerrainTextureColors initialized|r")
endfunction

//===========================================================================
// Auto-initialization
//===========================================================================
private function Init takes nothing returns nothing
    call InitTerrainColors()
endfunction

endlibrary
