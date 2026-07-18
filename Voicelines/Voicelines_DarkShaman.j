/**
    VoicelinesDarkShaman

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
    Global `VL_DARKSHAMAN_*` constants.

**/
library VoicelinesDarkShaman requires Voicelines

globals
    constant string VL_DARKSHAMAN_FOLDER = "DarkShaman"

    // Legacy Excel draft/reference rows.

    // Excel draft: DarkShaman | Event: BossScorchion: Engage Darkshamans | Done: x
    constant string VL_DARKSHAMAN_0001_KEY = "DarkShaman_0001"
    constant string VL_DARKSHAMAN_0001_TEXT = "How dare you interfere with our plans! The flames obey us, they kneel to us... but now, they shall consume you instead!"
    constant string VL_DARKSHAMAN_0002_KEY = "DarkShaman_0002"
    constant string VL_DARKSHAMAN_0002_TEXT = "The spirits of fire are bound to our will-your flesh shall be their feast!"
    constant string VL_DARKSHAMAN_0003_KEY = "DarkShaman_0003"
    constant string VL_DARKSHAMAN_0003_TEXT = "Witness the true power of shackled flame!"
    constant string VL_DARKSHAMAN_0004_KEY = "DarkShaman_0004"
    constant string VL_DARKSHAMAN_0004_TEXT = "Aaargh! Why can't you just.. die?!"

    // Excel draft: DarkShaman | Event: BossScorchion: Engage Darkshamans
    constant string VL_DARKSHAMAN_0005_KEY = "DarkShaman_0005"
    constant string VL_DARKSHAMAN_0005_TEXT = "Haha! Your actions are amusing!"

    // Excel draft: DarkShaman | Event: BossScorchion: Last dark shaman dies | Done: x
    constant string VL_DARKSHAMAN_0007_KEY = "DarkShaman_0007"
    constant string VL_DARKSHAMAN_0007_TEXT = "The spirits... never to be... controlled..."
    constant string VL_DARKSHAMAN_0008_KEY = "DarkShaman_0008"
    constant string VL_DARKSHAMAN_0008_TEXT = "The fire... is unbound... It devours... us all..."
    constant string VL_DARKSHAMAN_0009_KEY = "DarkShaman_0009"
    constant string VL_DARKSHAMAN_0009_TEXT = "...Scorchion will destroy you!"

    // Excel draft: DarkShaman | Event: BossScorchion: Engage reset | Done: x
    constant string VL_DARKSHAMAN_0012_KEY = "DarkShaman_0012"
    constant string VL_DARKSHAMAN_0012_TEXT = "Run, little coward! The spirits have abandoned you!"
    constant string VL_DARKSHAMAN_0013_KEY = "DarkShaman_0013"
    constant string VL_DARKSHAMAN_0013_TEXT = "Flee! You are no match for us!"
    constant string VL_DARKSHAMAN_0014_KEY = "DarkShaman_0014"
    constant string VL_DARKSHAMAN_0014_TEXT = "There is nowhere to hide under the burning sky!"

    // Excel draft: DarkShaman | Event: Distant / "Filmed from far away" | Done: x
    constant string VL_DARKSHAMAN_0019_KEY = "DarkShaman_0019"
    constant string VL_DARKSHAMAN_0019_TEXT = "With this elemental enslaved, none shall stand against us!"
    constant string VL_DARKSHAMAN_0020_KEY = "DarkShaman_0020"
    constant string VL_DARKSHAMAN_0020_TEXT = "What if it breaks free? Its rage would turn us all to cinders..."
    constant string VL_DARKSHAMAN_0021_KEY = "DarkShaman_0021"
    constant string VL_DARKSHAMAN_0021_TEXT = "Silence, you fool!"
    constant string VL_DARKSHAMAN_0022_KEY = "DarkShaman_0022"
    constant string VL_DARKSHAMAN_0022_TEXT = "Our master has a vision, and that vision will not be achieved with cowardice!"

    // Excel draft: DarkShaman | Event: Distant / "Filmed from far away"
    constant string VL_DARKSHAMAN_0023_KEY = "DarkShaman_0023"
    constant string VL_DARKSHAMAN_0023_TEXT = "Still... I can sense fire straining against the chains, it speaks to me violently."

    // Excel draft: DarkShaman | Event: Distant / "Filmed from far away" | Done: x
    constant string VL_DARKSHAMAN_0024_KEY = "DarkShaman_0024"
    constant string VL_DARKSHAMAN_0024_TEXT = "Bah! Then bind it tighter, feed it more pain. Now-concentrate your energies on this fire lord!"
endglobals

endlibrary
