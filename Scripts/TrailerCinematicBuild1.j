globals
    camerasetup array camA
    camerasetup array camB
    timer msgClearTimer = null
    timer cinematicTimer = null
    integer cinematicIndex = 1
endglobals

function InitCamerasTrailer1 takes nothing returns nothing
    // Assign all camera pairs
    set camA[1]  = gg_cam_cam001a
    set camB[1]  = gg_cam_cam001b
    set camA[2]  = gg_cam_cam002a
    set camB[2]  = gg_cam_cam002b
    set camA[3]  = gg_cam_cam003a
    set camB[3]  = gg_cam_cam003b
    set camA[4]  = gg_cam_cam004a
    set camB[4]  = gg_cam_cam004b
    set camA[5]  = gg_cam_cam005a
    set camB[5]  = gg_cam_cam005b
    set camA[6]  = gg_cam_cam006a
    set camB[6]  = gg_cam_cam006b
    set camA[7]  = gg_cam_cam007a
    set camB[7]  = gg_cam_cam007b
    set camA[8]  = gg_cam_cam008a
    set camB[8]  = gg_cam_cam008b
    set camA[9]  = gg_cam_cam009a
    set camB[9]  = gg_cam_cam009b
    set camA[10] = gg_cam_cam010a
    set camB[10] = gg_cam_cam010b
    set camA[11] = gg_cam_cam011a
    set camB[11] = gg_cam_cam011b
    set camA[12] = gg_cam_cam012a
    set camB[12] = gg_cam_cam012b
    set camA[13] = gg_cam_cam013a
    set camB[13] = gg_cam_cam013b
    set camA[14] = gg_cam_cam014a
    set camB[14] = gg_cam_cam014b
    set camA[15] = gg_cam_cam015a
    set camB[15] = gg_cam_cam015b
    set camA[16] = gg_cam_cam016a
    set camB[16] = gg_cam_cam016b
    set camA[17] = gg_cam_cam017a
    set camB[17] = gg_cam_cam017b
    set camA[18] = gg_cam_cam018a
    set camB[18] = gg_cam_cam018b
    set camA[19] = gg_cam_cam019a
    set camB[19] = gg_cam_cam019b
    set camA[20] = gg_cam_cam020a
    set camB[20] = gg_cam_cam020b
    set camA[21] = gg_cam_cam021a
    set camB[21] = gg_cam_cam021b
    set camA[22] = gg_cam_cam022a
    set camB[22] = gg_cam_cam022b
    set camA[23] = gg_cam_cam023a
    set camB[23] = gg_cam_cam023b
    set camA[24] = gg_cam_cam024a
    set camB[24] = gg_cam_cam024b
    set camA[25] = gg_cam_cam025a
    set camB[25] = gg_cam_cam025b
    set camA[26] = gg_cam_cam026a
    set camB[26] = gg_cam_cam026b
    set camA[27] = gg_cam_cam027a
    set camB[27] = gg_cam_cam027b
    set camA[28] = gg_cam_cam028a
    set camB[28] = gg_cam_cam028b
    set camA[29] = gg_cam_cam029a
    set camB[29] = gg_cam_cam029b
    set camA[30] = gg_cam_cam030a
    set camB[30] = gg_cam_cam030b
    set camA[31] = gg_cam_cam031a
    set camB[31] = gg_cam_cam031b
    set camA[32] = gg_cam_cam032a
    set camB[32] = gg_cam_cam032b
    set camA[33] = gg_cam_cam033a
    set camB[33] = gg_cam_cam033b
    set camA[34] = gg_cam_cam034a
    set camB[34] = gg_cam_cam034b
    set camA[35] = gg_cam_cam035a
    set camB[35] = gg_cam_cam035b
    set camA[36] = gg_cam_cam036a
    set camB[36] = gg_cam_cam036b
    set camA[37] = gg_cam_cam037a
    set camB[37] = gg_cam_cam037b
    set camA[38] = gg_cam_cam038a
    set camB[38] = gg_cam_cam038b
    set camA[39] = gg_cam_cam039a
    set camB[39] = gg_cam_cam039b
    set camA[40] = gg_cam_cam040a
    set camB[40] = gg_cam_cam040b
    set camA[41] = gg_cam_cam041a
    set camB[41] = gg_cam_cam041b
    set camA[42] = gg_cam_cam042a
    set camB[42] = gg_cam_cam042b
    set camA[43] = gg_cam_cam043a
    set camB[43] = gg_cam_cam043b
    set camA[44] = gg_cam_cam044a
    set camB[44] = gg_cam_cam044b
    set camA[45] = gg_cam_cam045a
    set camB[45] = gg_cam_cam045b
    set camA[46] = gg_cam_cam046a
    set camB[46] = gg_cam_cam046b
    set camA[47] = gg_cam_cam047a
    set camB[47] = gg_cam_cam047b
    set camA[48] = gg_cam_cam048a
    set camB[48] = gg_cam_cam048b
    set camA[49] = gg_cam_cam049a
    set camB[49] = gg_cam_cam049b
    set camA[50] = gg_cam_cam050a
    set camB[50] = gg_cam_cam050b
    set camA[51] = gg_cam_cam051a
    set camB[51] = gg_cam_cam051b
    set camA[52] = gg_cam_cam052a
    set camB[52] = gg_cam_cam052b
    set camA[53] = gg_cam_cam053a
    set camB[53] = gg_cam_cam053b
    set camA[54] = gg_cam_cam054a
    set camB[54] = gg_cam_cam054b
    set camA[55] = gg_cam_cam055a
    set camB[55] = gg_cam_cam055b
    set camA[56] = gg_cam_cam056a
    set camB[56] = gg_cam_cam056b
    set camA[57] = gg_cam_cam057a
    set camB[57] = gg_cam_cam057b
    set camA[58] = gg_cam_cam058a
    set camB[58] = gg_cam_cam058b
    set camA[59] = gg_cam_cam059a
    set camB[59] = gg_cam_cam059b
    set camA[60] = gg_cam_cam060a
    set camB[60] = gg_cam_cam060b
    set camA[61] = gg_cam_cam061a
    set camB[61] = gg_cam_cam061b
    set camA[62] = gg_cam_cam062a
    set camB[62] = gg_cam_cam062b
    set camA[63] = gg_cam_cam063a
    set camB[63] = gg_cam_cam063b

endfunction

//=== Play next camera in cinematic ===
function PlayNextCameraPan takes nothing returns nothing
    local real camX
    local real camY

    // Exit condition
    if cinematicIndex > 63 then
        // Show udg_Nazgrek again
        call ShowUnitShow(udg_Nazgrek)

        // Turn cinematic mode off
        call CinematicModeBJ(false, GetPlayersAll())
        set udg_CinematicTrailer = false

        // Stop timers
        if cinematicTimer != null then
            call DestroyTimer(cinematicTimer)
            set cinematicTimer = null
        endif
        if msgClearTimer != null then
            call PauseTimer(msgClearTimer)
        endif
        return
    endif

    // Get A-camera position
    set camX = CameraSetupGetDestPositionX(camA[cinematicIndex])
    set camY = CameraSetupGetDestPositionY(camA[cinematicIndex])

    // Move udg_Nazgrek to camera A location
    call SetUnitPosition(udg_Nazgrek, camX, camY)

    // Set farz to max to avoid clipping
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_FARZ, 20000.0, 0.0)

    // Apply camera pan: camA -> camB over 15 seconds
    call CameraSetupApplyForPlayer(true, camA[cinematicIndex], Player(0), 0.0)
    call CameraSetupApplyForPlayer(true, camB[cinematicIndex], Player(0), 15.0)

    // Increment index for next pan
    set cinematicIndex = cinematicIndex + 1
endfunction


//=== Clears text messages during cinematic ===
function ClearMessagesPeriodic takes nothing returns nothing
    call ClearTextMessagesBJ( GetPlayersAll() )
endfunction

function PlayCinematicTrailer1 takes nothing returns nothing
    // Enable cinematic mode
    call CinematicModeBJ(true, GetPlayersAll())
    set udg_CinematicTrailer = true

    // Hide udg_Nazgrek during cinematic
    call ShowUnitHide(udg_Nazgrek)

    // Start periodic message clearing
    if msgClearTimer == null then
        set msgClearTimer = CreateTimer()
    endif
    call TimerStart(msgClearTimer, 0.1, true, function ClearMessagesPeriodic)

    // Stop any existing music
    call ClearMapMusicBJ()
    call StopMusicBJ(false)

    // Initialize cinematic index
    set cinematicIndex = 1

    // Create main cinematic timer (fires every 15 seconds)
    if cinematicTimer == null then
        set cinematicTimer = CreateTimer()
    endif
    call TimerStart(cinematicTimer, 15.0, true, function PlayNextCameraPan)

    // Play first camera immediately
    call PlayNextCameraPan()
endfunction