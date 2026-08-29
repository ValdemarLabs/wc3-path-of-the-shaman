/**
    AmbientEvents

    Author: Valdemar
    Version: 1.0.0

    Description:
    Provides reusable one-shot region-entry events and lightweight ambient
    unit-type transmissions for world scenarios.

    Credits:
    - World/_oldGUI/Horde Units Random Chat

    How to install:
    Import after `ExSound.j` and before ambient-event sublibraries.

    API:
    - AmbientEvents_CreateOneShotRegionEnter(whichRect, enteringOwner, callback, enabled)
    - AmbientEvents_SetRegionEnterEnabled(whichTrigger, enabled)
    - AmbientEvents_DestroyRegionEnter(whichTrigger)
    - AmbientEvents_PlayUnitTypeLine(audience, sourceOwner, sourceUnitTypeId, speakerName, sourceRect, text, soundKey, duration)

**/
library AmbientEvents initializer Init requires ExSound
    globals
        private constant integer OWNER_ID_KEY = 0

        private hashtable RegionEnterConfig = null
    endglobals

    private function IsConfiguredOwner takes nothing returns boolean
        local trigger sourceTrigger = GetTriggeringTrigger()
        local unit enteringUnit = GetTriggerUnit()
        local boolean matches = enteringUnit != null and GetPlayerId(GetOwningPlayer(enteringUnit)) == LoadInteger(RegionEnterConfig, GetHandleId(sourceTrigger), OWNER_ID_KEY)

        set enteringUnit = null
        set sourceTrigger = null
        return matches
    endfunction

    private function OnOneShotRegionEnter takes nothing returns nothing
        call DisableTrigger(GetTriggeringTrigger())
    endfunction

    public function CreateOneShotRegionEnter takes rect whichRect, player enteringOwner, code callback, boolean enabled returns trigger
        local trigger enterTrigger = null

        if whichRect == null or enteringOwner == null then
            return null
        endif
        set enterTrigger = CreateTrigger()
        call SaveInteger(RegionEnterConfig, GetHandleId(enterTrigger), OWNER_ID_KEY, GetPlayerId(enteringOwner))
        call TriggerRegisterEnterRectSimple(enterTrigger, whichRect)
        call TriggerAddCondition(enterTrigger, Condition(function IsConfiguredOwner))
        call TriggerAddAction(enterTrigger, function OnOneShotRegionEnter)
        call TriggerAddAction(enterTrigger, callback)
        if not enabled then
            call DisableTrigger(enterTrigger)
        endif
        return enterTrigger
    endfunction

    public function SetRegionEnterEnabled takes trigger whichTrigger, boolean enabled returns nothing
        if whichTrigger == null then
            return
        endif
        if enabled then
            call EnableTrigger(whichTrigger)
        else
            call DisableTrigger(whichTrigger)
        endif
    endfunction

    public function DestroyRegionEnter takes trigger whichTrigger returns nothing
        if whichTrigger == null then
            return
        endif
        call FlushChildHashtable(RegionEnterConfig, GetHandleId(whichTrigger))
        call DestroyTrigger(whichTrigger)
    endfunction

    public function PlayUnitTypeLine takes force audience, player sourceOwner, integer sourceUnitTypeId, string speakerName, rect sourceRect, string text, string soundKey, real duration returns nothing
        local location sourcePoint = null

        if audience == null or sourceOwner == null or sourceRect == null then
            return
        endif
        set sourcePoint = Location(GetRectCenterX(sourceRect), GetRectCenterY(sourceRect))
        if soundKey != "" then
            call ExSound_Play(soundKey, text)
        endif
        call TransmissionFromUnitTypeWithNameBJ(audience, sourceOwner, sourceUnitTypeId, speakerName, sourcePoint, null, text, bj_TIMETYPE_SET, duration, false)
        call RemoveLocation(sourcePoint)
        set sourcePoint = null
    endfunction

    private function Init takes nothing returns nothing
        set RegionEnterConfig = InitHashtable()
    endfunction
endlibrary
