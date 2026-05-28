# GatherNodes System Design

## Overview

A comprehensive gathering/node spawning system that manages herbs, ore veins, crystal veins, fish pools, etc. Integrates with Item Manager database and exports to JASS libraries.

## System Architecture

### 1. JASS Libraries

```
GatherNodes.j (Master Library)
├── GatherNodeItems.j (Herb/Item spawning subsystem)
├── GatherNodeUnits.j (Vein/Unit spawning subsystem)
└── GatherNodeDefinitions.j (Generated from database)
```

### 2. Database Tables

#### `gather_item_nodes` - Define items that spawn as gather nodes (Herbs)
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| item_code | VARCHAR(4) | WC3 item rawcode |
| node_name | VARCHAR(100) | Display name |
| node_category | VARCHAR(50) | Category (e.g., "Herbs", "Flowers", "Mushrooms") |
| spawn_weight | INT | Relative spawn probability (higher = more common) |
| respawn_time_min | REAL | Minimum respawn time (seconds) |
| respawn_time_max | REAL | Maximum respawn time (seconds) |
| max_per_zone | INT | Maximum active nodes per zone |
| skill_required | INT | Gathering skill level required (0 = none) |
| enabled | BOOLEAN | Is this node active |
| notes | TEXT | Optional notes |

#### `gather_unit_nodes` - Define units that spawn as gather nodes (Veins)
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| unit_code | VARCHAR(4) | WC3 unit rawcode |
| node_name | VARCHAR(100) | Display name |
| node_category | VARCHAR(50) | Category (e.g., "Ore Veins", "Crystal Veins", "Rich Veins") |
| spawn_weight | INT | Relative spawn probability |
| respawn_time_min | REAL | Minimum respawn time (seconds) |
| respawn_time_max | REAL | Maximum respawn time (seconds) |
| max_per_zone | INT | Maximum active nodes per zone |
| skill_required | INT | Mining/Gathering skill level required |
| owner_player | INT | Player number for unit (default 24 = Peanut) |
| enabled | BOOLEAN | Is this node active |
| notes | TEXT | Optional notes |

#### `gather_node_zones` - Link nodes to zones (many-to-many)
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| node_type | VARCHAR(10) | 'item' or 'unit' |
| node_id | INT | FK to gather_item_nodes or gather_unit_nodes |
| zone_id | INT | Zone ID from Zones.j |
| zone_name | VARCHAR(100) | Zone name (for display) |
| spawn_mode | VARCHAR(20) | 'random', 'fixed', 'both' |
| weight_override | INT | Zone-specific weight (NULL = use default) |
| max_override | INT | Zone-specific max (NULL = use default) |
| enabled | BOOLEAN | Is this zone assignment active |

#### `gather_spawn_points` - Define specific spawn points within zones
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| zone_id | INT | Zone ID |
| point_name | VARCHAR(50) | Spawn point name (e.g., "OreVeins0001") |
| region_variable | VARCHAR(50) | WC3 region variable name (e.g., "gg_rct_OreVeins0001") |
| node_type | VARCHAR(10) | 'item', 'unit', or 'both' |
| enabled | BOOLEAN | Is this spawn point active |
| notes | TEXT | Optional notes |

### 3. Item Manager UI

#### GatherItemNodeForm (for Herbs)
- List of all item nodes with categories
- Filter by category, zone, enabled status
- Details panel:
  - Item selector
  - Category dropdown
  - Spawn weight
  - Respawn time range
  - Max per zone
  - Skill required
- Zone assignment grid:
  - Add/remove zones
  - Per-zone spawn mode (Random/Fixed/Both)
  - Per-zone weight override

#### GatherUnitNodeForm (for Veins)  
- List of all unit nodes with categories
- Filter by category, zone, enabled status
- Details panel:
  - Unit selector (from unit types)
  - Category dropdown
  - Spawn weight
  - Respawn time range
  - Max per zone
  - Owner player
- Zone assignment grid:
  - Add/remove zones
  - Per-zone spawn mode (Random/Fixed/Both)
  - Per-zone weight override

#### GatherSpawnPointsForm
- Manage fixed spawn points per zone
- Bulk import from existing regions
- Map preview (if possible)

### 4. JASS System Flow

```
Map Init
    └─> GatherNodes_Init()
        ├─> GatherNodeItems_Init() 
        │   └─> Register all herb definitions
        └─> GatherNodeUnits_Init()
            └─> Register all vein definitions

During Game
    ├─> Periodic Timer (per zone)
    │   ├─> Check current node count vs max
    │   ├─> Roll for spawn based on weights
    │   └─> Spawn at random position or fixed point
    │
    ├─> Node Pickup/Death Event
    │   ├─> Update zone node count
    │   └─> Start respawn timer
    │
    └─> Zone Transition
        └─> Update active zone for spawn checks
```

### 5. API Functions

```jass
// === Master Library ===
function GatherNodes_Enable takes boolean enable returns nothing
function GatherNodes_ForceSpawn takes integer zoneId, string nodeType returns nothing
function GatherNodes_GetActiveCount takes integer zoneId, string nodeType returns integer
function GatherNodes_SetDebug takes boolean enable returns nothing

// === Item Nodes ===
function GatherNodeItems_RegisterItem takes integer itemTypeId, string category, integer weight returns nothing
function GatherNodeItems_AddZone takes integer itemTypeId, integer zoneId, string spawnMode returns nothing
function GatherNodeItems_Spawn takes integer zoneId returns nothing
function GatherNodeItems_OnPickup takes item whichItem returns nothing

// === Unit Nodes ===
function GatherNodeUnits_RegisterUnit takes integer unitTypeId, string category, integer weight returns nothing  
function GatherNodeUnits_AddZone takes integer unitTypeId, integer zoneId, string spawnMode returns nothing
function GatherNodeUnits_Spawn takes integer zoneId returns nothing
function GatherNodeUnits_OnDeath takes unit whichUnit returns nothing
```

### 6. Configuration Constants

```jass
// In GatherNodes.j
globals
    private constant real SPAWN_CHECK_INTERVAL = 30.0 // Check spawn every 30 seconds
    private constant real MIN_SPAWN_DISTANCE = 200.0  // Min distance from other nodes
    private constant integer MAX_SPAWN_ATTEMPTS = 10  // Max attempts to find valid position
    private constant player VEIN_OWNER = Player(23)   // Player 24 (Peanut)
endglobals
```

### 7. Node Categories (Examples)

**Item Nodes:**
- Herbs
- Flowers  
- Mushrooms
- Rare Herbs
- Reagents

**Unit Nodes:**
- Ore Veins (Copper, Tin, Iron, etc.)
- Crystal Veins (Quartz, Amethyst, etc.)
- Rich Veins (bonus drops)
- Special Nodes (quest-related)

### 8. Zone Data Usage

The system leverages existing `Zones.j` to:
- Get current player zone for spawn decisions
- Use zone regions for random spawning
- Track discovered zones for node visibility

### 9. Export Format

Generated `GatherNodeDefinitions.j`:
```jass
library GatherNodeDefinitions initializer Init requires GatherNodeItems, GatherNodeUnits

    private function RegisterAllItemNodes takes nothing returns nothing
        // === HERBS ===
        call GatherNodeItems_RegisterItem('herb', "Herbs", 100)
        call GatherNodeItems_SetRespawnTime('herb', 60.0, 180.0)
        call GatherNodeItems_SetMaxPerZone('herb', 5)
        // Zone assignments
        call GatherNodeItems_AddZone('herb', 1, "random")  // Twilight Grove
        call GatherNodeItems_AddZone('herb', 2, "random")  // Sereneglade
    endfunction

    private function RegisterAllUnitNodes takes nothing returns nothing
        // === ORE VEINS ===
        call GatherNodeUnits_RegisterUnit('h001', "Ore Veins", 60)  // Copper Vein
        call GatherNodeUnits_SetRespawnTime('h001', 120.0, 360.0)
        call GatherNodeUnits_SetMaxPerZone('h001', 3)
        // Zone assignments  
        call GatherNodeUnits_AddZone('h001', 1, "fixed")  // Twilight Grove - use fixed points
        call GatherNodeUnits_AddZone('h001', 2, "both")   // Sereneglade - random + fixed
    endfunction

    private function Init takes nothing returns nothing
        call TimerStart(CreateTimer(), 0.1, false, function RegisterAllItemNodes)
        call TimerStart(CreateTimer(), 0.2, false, function RegisterAllUnitNodes)
    endfunction

endlibrary
```

## Implementation Order

1. ✅ Design (this document)
2. Database schema creation (SQL)
3. GatherNodes.j master library
4. GatherNodeItems.j subsystem
5. GatherNodeUnits.j subsystem
6. GatherNodeDefinitions exporter
7. Item Manager forms

## Questions for User

1. Should fish pools be items (like herbs) or special units?
2. Do you want a "glow" effect system integrated (like VeinGlow from old GUI)?
3. Should nodes be visible to all players or discoverable per-player?
4. Any other node types to consider (treasure chests, rare spawns, etc.)?
