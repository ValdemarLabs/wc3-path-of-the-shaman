/**
    PotSSaveConfigNSLImplCompile

    Author: Valdemar
    Version: 1.0.0

    Description:
    Compile-only compatibility harness for maps that retain the immutable
    original Maxou NSLImpl configuration beside PotSSaveConfig.

    Credits:
    - Maxou, New Save Load (NSL)

    How to install:
    Never import this file into a production map. Feed it to JassHelper with
    the repository's active common.j and blizzard.j only for validation.

    API:
    - None; config/main exist only as compiler entry points.
**/
library NSLImpl
    globals
        constant integer NSL_CodeVersion = 1
        constant string NSL_FolderName = "MaxouNSL"
        constant integer NSL_Key = 19
        constant boolean NSL_UseSimpleSaveLoad = true
    endglobals
endlibrary

//! import "../PotSSaveConfig.j"

function config takes nothing returns nothing
endfunction

function main takes nothing returns nothing
endfunction
