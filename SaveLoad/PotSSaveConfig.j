/**
    PotSSaveConfig

    Author: Valdemar
    Version: 2.1.0

    Description:
    Owns PotS application-schema limits and the immutable Maxou NSL core
    configuration used by the separate PotS integration.

    Credits:
    - Maxou, New Save Load (NSL)

    How to install:
    Import before the reusable NSL core and every PotS SaveLoad library. Do
    not also import the vendor NSLImpl/command example.

    API:
    - Configuration constants are exposed with the PotSSaveConfig_ prefix.

**/
library PotSSaveConfig
    globals
        // Required by the immutable NSL codec and SaveFile core.
        constant integer NSL_CodeVersion = 1
        constant integer NSL_Key = 19
        constant string NSL_FolderName = "Pots"

        // PotS application schema. Schema 1 remains readable; schema 2.0 adds
        // ability provenance and schema 2.1 adds custom inventory/equipment.
        public constant integer SCHEMA_MAJOR = 2
        public constant integer SCHEMA_MINOR = 1
        public constant integer OLDEST_SCHEMA_MAJOR = 1
        public constant integer MAGIC = 'PSSL'

        // Bounded runtime and payload limits.
        public constant integer MAX_STREAM_VALUES = 1000
        public constant integer MAX_RECORDS = 16
        public constant integer MAX_ABILITIES = 128
        public constant integer MAX_ENUMERATED_ABILITIES = 256
        public constant integer MAX_INVENTORY_SLOTS = 24
        public constant integer MAX_DINVENTORY_SLOTS = 80
        public constant integer MAX_EQUIPMENT_SLOTS = 20
        public constant integer MAX_WORLD_FLAGS = 128
        public constant integer MAX_RAWCODE_MIGRATIONS = 64
        public constant integer MAX_WORLD_MIGRATIONS = 64
        // Reserve two characters for the physical _n/_z party-file suffix.
        public constant integer MAX_SLOT_LENGTH = 30
        public constant integer VITAL_SCALE = 100000
        public constant real LOAD_WINDOW_SECONDS = 120.00

        // Stable record tags. Existing meanings must never be reused.
        public constant integer TAG_HERO_IDENTITY = 1
        public constant integer TAG_HERO_PROGRESS = 2
        public constant integer TAG_HERO_ATTRIBUTES = 3
        public constant integer TAG_ABILITIES = 4
        public constant integer TAG_INVENTORY = 5
        public constant integer TAG_RESOURCES = 6
        public constant integer TAG_VITALS = 7
        public constant integer TAG_CHECKPOINT = 8
        public constant integer TAG_ABILITY_PROVENANCE = 9
        public constant integer TAG_DINVENTORY = 10
        public constant integer TAG_EQUIPMENT = 11
        public constant integer TAG_QUESTS = 1000

        public constant integer ABILITY_SOURCE_UNKNOWN = 0
        public constant integer ABILITY_SOURCE_CATALOG = 1
        public constant integer ABILITY_SOURCE_TRACKED = 2
        public constant integer WORLD_FLAG_COMPLETED = 1

        // Public operation error codes.
        public constant integer ERROR_NONE = 0
        public constant integer ERROR_BUSY = 1
        public constant integer ERROR_INVALID_SLOT = 2
        public constant integer ERROR_NO_HERO = 3
        public constant integer ERROR_AMBIGUOUS_HERO = 4
        public constant integer ERROR_SCAN_FAILED = 5
        public constant integer ERROR_CAPACITY = 6
        public constant integer ERROR_FILE_NOT_FOUND = 7
        public constant integer ERROR_INVALID_CODE = 8
        public constant integer ERROR_UNSUPPORTED_SCHEMA = 9
        public constant integer ERROR_INVALID_DATA = 10
        public constant integer ERROR_LOAD_LOCKED = 11
        public constant integer ERROR_ALREADY_LOADED = 12
        public constant integer ERROR_PREFLIGHT = 13
        public constant integer ERROR_APPLY_FAILED = 14
        public constant integer ERROR_SINGLE_PLAYER_ONLY = 15
    endglobals
endlibrary
