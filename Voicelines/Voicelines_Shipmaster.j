/**
    VoicelinesShipmaster

    Author: Valdemar
    Version:

    Description:
    Speaker-owned voiceline key/text constants migrated from legacy
    Excel draft/reference rows. Runtime consumers require this
    library directly when they need these constants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after `Voicelines.j`. Add runtime registration when a
    consumer starts using these constants.

    API:
    Global `VL_SHIPMASTER_*` constants.

**/
library VoicelinesShipmaster requires Voicelines

globals
    constant string VL_SHIPMASTER_FOLDER = "Shipmaster"

    // Legacy Excel draft/reference rows.

    // Excel draft: Shipmaster | Event: Normal Greet | Done: x
    constant string VL_SHIPMASTER_0001_KEY = "Shipmaster_0001"
    constant string VL_SHIPMASTER_0001_TEXT = "You lookin' to travel?"
    constant string VL_SHIPMASTER_0002_KEY = "Shipmaster_0002"
    constant string VL_SHIPMASTER_0002_TEXT = "Ahoy there, traveler!"

    // Excel draft: Shipmaster | Event: ShipNOTdeck | Done: x
    constant string VL_SHIPMASTER_0005_KEY = "Shipmaster_0005"
    constant string VL_SHIPMASTER_0005_TEXT = "Hold yer sea legs! The ship ain't here yet."
    constant string VL_SHIPMASTER_0006_KEY = "Shipmaster_0006"
    constant string VL_SHIPMASTER_0006_TEXT = "Easy there, friend - ship's not docked here yet."

    // Excel draft: Shipmaster | Event: InsufficientGold | Done: x
    constant string VL_SHIPMASTER_0009_KEY = "Shipmaster_0009"
    constant string VL_SHIPMASTER_0009_TEXT = "No pay, no way!"
    constant string VL_SHIPMASTER_0010_KEY = "Shipmaster_0010"
    constant string VL_SHIPMASTER_0010_TEXT = "I'm afraid you don't have enough gold."

    // Excel draft: Shipmaster | Event: EnterShip | Done: x
    constant string VL_SHIPMASTER_0013_KEY = "Shipmaster_0013"
    constant string VL_SHIPMASTER_0013_TEXT = "Welcome aboard!"
    constant string VL_SHIPMASTER_0014_KEY = "Shipmaster_0014"
    constant string VL_SHIPMASTER_0014_TEXT = "The waves are callin'!"

    // Excel draft: Shipmaster | Event: Farewell | Done: x
    constant string VL_SHIPMASTER_0017_KEY = "Shipmaster_0017"
    constant string VL_SHIPMASTER_0017_TEXT = "Safe travels!"
    constant string VL_SHIPMASTER_0018_KEY = "Shipmaster_0018"
    constant string VL_SHIPMASTER_0018_TEXT = "Till next time!"
endglobals

endlibrary
