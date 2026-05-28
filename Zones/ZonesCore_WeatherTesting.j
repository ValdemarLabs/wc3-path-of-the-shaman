function ShowCurrentZoneWeatherTypes takes nothing returns nothing
    local integer zoneId = ZonesCore_GetCurrentZone()
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    local string msg = "Allowed weather types: "
    local integer i = 0
    local integer count
    if z == 0 or not z.weatherAllowed then
        call BJDebugMsg("Weather is not allowed in this zone.")
        return
    endif
    set count = z.weatherTypeCount
    if count == 0 then
        set count = 8 // Number of default types
    endif
    call BJDebugMsg("zoneId: " + I2S(zoneId))
    call BJDebugMsg("weatherTypeCount: " + I2S(z.weatherTypeCount))
    loop
        exitwhen i >= count
        if z.weatherTypeCount > 0 then
            set msg = msg + z.getWeatherType(i)
        endif
        if i < count - 1 then
            set msg = msg + ", "
        endif
        set i = i + 1
    endloop
    call BJDebugMsg(msg)
endfunction