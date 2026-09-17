/**
    Warcraft300P2TestHarness

    Author: Valdemar
    Version: 0.2.0

    Description:
    Provides explicit, resettable Warcraft III 3.0 P2 probes inside the full
    PotS map. No effect is created at startup; DynamicMinimap keeps its configured
    default source until an explicit minimap command changes it locally.

    Credits:

    How to install:
    Import SpeciFX and DynamicMinimap before this library, then import this
    library before DebugCommands.

    API:
    - Warcraft300P2TestHarness_Execute(player, command, x, y, hasPoint) -> boolean
    - /debug wc3 effects help
    - /debug wc3 minimap help

**/
library Warcraft300P2TestHarness requires SpeciFX, DynamicMinimap
    globals
        private constant string W3P_PREFIX = "|cffffcc80[WC3 3.0 P2]|r "
        private constant string W3P_EFFECT_MODEL = "units\\orc\\grunt\\grunt.mdl"

        // One explicit probe effect is owned per triggering player.
        private effect array W3P_Effect
        private string array W3P_Animation
        private string array W3P_QueuedAnimation
        private real array W3P_BlendTime
    endglobals

    private function W3P_StartsWith takes string source, string prefix returns boolean
        local integer prefixLength = StringLength(prefix)
        return StringLength(source) >= prefixLength and SubString(source, 0, prefixLength) == prefix
    endfunction

    private function W3P_BooleanText takes boolean value returns string
        if value then
            return "true"
        endif
        return "false"
    endfunction

    private function W3P_Message takes player whichPlayer, string message returns nothing
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, W3P_PREFIX + message)
    endfunction

    private function W3P_HasEffect takes integer playerId returns boolean
        return W3P_Effect[playerId] != null
    endfunction

    private function W3P_ShowHelp takes player whichPlayer returns nothing
        call W3P_Message(whichPlayer, "Effects: effects create | status | animation <name> | queue <name>")
        call W3P_Message(whichPlayer, "Effects: effects blend <seconds> | legacy | destroy")
        call W3P_Message(whichPlayer, "Minimap: minimap status | source imported|native | view chunked|full | force")
    endfunction

    private function W3P_DestroyEffect takes player whichPlayer returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        if W3P_HasEffect(playerId) then
            call DestroyEffect(W3P_Effect[playerId])
            set W3P_Effect[playerId] = null
        endif
        set W3P_Animation[playerId] = ""
        set W3P_QueuedAnimation[playerId] = ""
        set W3P_BlendTime[playerId] = 0.00
        call W3P_Message(whichPlayer, "Effect probe destroyed and state reset.")
    endfunction

    private function W3P_CreateEffect takes player whichPlayer, real x, real y, boolean hasPoint returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        if not hasPoint then
            call W3P_Message(whichPlayer, "Effect creation requires a synchronized camera-target point.")
            return
        endif
        if W3P_HasEffect(playerId) then
            call DestroyEffect(W3P_Effect[playerId])
            set W3P_Effect[playerId] = null
        endif
        set W3P_Effect[playerId] = AddSpecialEffect(W3P_EFFECT_MODEL, x, y)
        set W3P_Animation[playerId] = "stand"
        set W3P_QueuedAnimation[playerId] = ""
        set W3P_BlendTime[playerId] = 0.15
        call SpeciFX_SetAnimationBlendTime(W3P_Effect[playerId], W3P_BlendTime[playerId])
        call SpeciFX_SetAnimation(W3P_Effect[playerId], W3P_Animation[playerId])
        call W3P_Message(whichPlayer, "Created synchronized Grunt effect at " + R2S(x) + ", " + R2S(y) + ".")
    endfunction

    private function W3P_ShowStatus takes player whichPlayer returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        call W3P_Message(whichPlayer, "Effect active=" + I2S(GetHandleId(W3P_Effect[playerId])) + ", animation='" + W3P_Animation[playerId] + "', queued='" + W3P_QueuedAnimation[playerId] + "', blend=" + R2S(W3P_BlendTime[playerId]) + ".")
    endfunction

    private function W3P_SetAnimation takes player whichPlayer, string animationName returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        if not W3P_HasEffect(playerId) then
            call W3P_Message(whichPlayer, "Create the effect probe first.")
            return
        endif
        if animationName == null or animationName == "" then
            call W3P_Message(whichPlayer, "Animation name cannot be empty.")
            return
        endif
        call SpeciFX_SetAnimation(W3P_Effect[playerId], animationName)
        set W3P_Animation[playerId] = animationName
        set W3P_QueuedAnimation[playerId] = ""
        call W3P_Message(whichPlayer, "Requested named animation '" + animationName + "'.")
    endfunction

    private function W3P_QueueAnimation takes player whichPlayer, string animationName returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        if not W3P_HasEffect(playerId) then
            call W3P_Message(whichPlayer, "Create the effect probe first.")
            return
        endif
        if animationName == null or animationName == "" then
            call W3P_Message(whichPlayer, "Queued animation name cannot be empty.")
            return
        endif
        call SpeciFX_QueueAnimation(W3P_Effect[playerId], animationName)
        set W3P_QueuedAnimation[playerId] = animationName
        call W3P_Message(whichPlayer, "Queued named animation '" + animationName + "'.")
    endfunction

    private function W3P_SetBlendTime takes player whichPlayer, string value returns nothing
        local integer playerId = GetPlayerId(whichPlayer)
        local real blendTime

        if not W3P_HasEffect(playerId) then
            call W3P_Message(whichPlayer, "Create the effect probe first.")
            return
        endif
        if value == null or value == "" then
            call W3P_Message(whichPlayer, "Blend time requires a number in seconds.")
            return
        endif
        set blendTime = S2R(value)
        if blendTime < 0.00 then
            set blendTime = 0.00
        endif
        call SpeciFX_SetAnimationBlendTime(W3P_Effect[playerId], blendTime)
        set W3P_BlendTime[playerId] = blendTime
        call W3P_Message(whichPlayer, "Animation blend time set to " + R2S(blendTime) + " seconds.")
    endfunction

    private function W3P_PlayLegacyAnimation takes player whichPlayer returns nothing
        local integer playerId = GetPlayerId(whichPlayer)

        if not W3P_HasEffect(playerId) then
            call W3P_Message(whichPlayer, "Create the effect probe first.")
            return
        endif
        call BlzPlaySpecialEffect(W3P_Effect[playerId], ANIM_TYPE_ATTACK)
        set W3P_Animation[playerId] = "ANIM_TYPE_ATTACK"
        set W3P_QueuedAnimation[playerId] = ""
        call W3P_Message(whichPlayer, "Requested the legacy animtype attack path.")
    endfunction

    private function W3P_ShowMinimapStatus takes player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
            call W3P_Message(whichPlayer, "Minimap source=" + DynamicMinimap_GetRenderSourceName() + ", fullMap=" + W3P_BooleanText(DynamicMinimap_GetFullMapMode()) + ", enabled=" + W3P_BooleanText(DynamicMinimap_IsEnabled()) + ".")
        endif
    endfunction

    private function W3P_SetMinimapSource takes player whichPlayer, integer source returns nothing
        local boolean accepted

        if GetLocalPlayer() == whichPlayer then
            set accepted = DynamicMinimap_SetRenderSource(source)
            call W3P_Message(whichPlayer, "Minimap source request accepted=" + W3P_BooleanText(accepted) + ", active=" + DynamicMinimap_GetRenderSourceName() + ".")
        endif
    endfunction

    private function W3P_SetMinimapView takes player whichPlayer, boolean fullMap returns nothing
        if GetLocalPlayer() == whichPlayer then
            call DynamicMinimap_SetFullMapMode(fullMap)
            call W3P_Message(whichPlayer, "Minimap view fullMap=" + W3P_BooleanText(DynamicMinimap_GetFullMapMode()) + ".")
        endif
    endfunction

    private function W3P_ForceMinimapUpdate takes player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
            call DynamicMinimap_ForceUpdate()
            call W3P_Message(whichPlayer, "Forced a local minimap refresh using " + DynamicMinimap_GetRenderSourceName() + " terrain.")
        endif
    endfunction

    public function Execute takes player whichPlayer, string command, real x, real y, boolean hasPoint returns boolean
        local string lowerCommand = StringCase(command, false)
        local string argument

        if lowerCommand == "wc3 effects" or lowerCommand == "wc3 effects help" then
            call W3P_ShowHelp(whichPlayer)
        elseif lowerCommand == "wc3 effects create" then
            call W3P_CreateEffect(whichPlayer, x, y, hasPoint)
        elseif lowerCommand == "wc3 effects status" then
            call W3P_ShowStatus(whichPlayer)
        elseif W3P_StartsWith(lowerCommand, "wc3 effects animation ") then
            set argument = SubString(lowerCommand, StringLength("wc3 effects animation "), StringLength(lowerCommand))
            call W3P_SetAnimation(whichPlayer, argument)
        elseif W3P_StartsWith(lowerCommand, "wc3 effects queue ") then
            set argument = SubString(lowerCommand, StringLength("wc3 effects queue "), StringLength(lowerCommand))
            call W3P_QueueAnimation(whichPlayer, argument)
        elseif W3P_StartsWith(lowerCommand, "wc3 effects blend ") then
            set argument = SubString(lowerCommand, StringLength("wc3 effects blend "), StringLength(lowerCommand))
            call W3P_SetBlendTime(whichPlayer, argument)
        elseif lowerCommand == "wc3 effects legacy" then
            call W3P_PlayLegacyAnimation(whichPlayer)
        elseif lowerCommand == "wc3 effects destroy" or lowerCommand == "wc3 effects reset" then
            call W3P_DestroyEffect(whichPlayer)
        elseif lowerCommand == "wc3 minimap" or lowerCommand == "wc3 minimap help" then
            call W3P_ShowHelp(whichPlayer)
        elseif lowerCommand == "wc3 minimap status" then
            call W3P_ShowMinimapStatus(whichPlayer)
        elseif lowerCommand == "wc3 minimap source imported" then
            call W3P_SetMinimapSource(whichPlayer, DYNAMIC_MINIMAP_SOURCE_IMPORTED)
        elseif lowerCommand == "wc3 minimap source native" then
            call W3P_SetMinimapSource(whichPlayer, DYNAMIC_MINIMAP_SOURCE_NATIVE)
        elseif lowerCommand == "wc3 minimap view chunked" or lowerCommand == "wc3 minimap chunked" then
            call W3P_SetMinimapView(whichPlayer, false)
        elseif lowerCommand == "wc3 minimap view full" or lowerCommand == "wc3 minimap full" then
            call W3P_SetMinimapView(whichPlayer, true)
        elseif lowerCommand == "wc3 minimap force" then
            call W3P_ForceMinimapUpdate(whichPlayer)
        else
            return false
        endif

        return true
    endfunction
endlibrary
