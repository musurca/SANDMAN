function Sandman_SetTimeZone()
    local lt = ScenEdit_CurrentLocalTime()
    local lt_hr = tonumber(
        string.sub(lt, 1, 2)
    )
    local ct = EpochToUTC_Time(
        ScenEdit_CurrentTime()
    )
    local ct_hr = tonumber(
        string.sub(ct, 1, 2)
    )
    StoreNumber("SANDMAN_TIME_DIFFERNCE", (lt_hr - ct_hr) % 24)
end

-- Returns the local hour as a real number
function Sandman_GetLocalHour()
    local ct = EpochToUTC_Time(
        ScenEdit_CurrentTime()
    )
    local ct_hr = tonumber(
        string.sub(ct, 1, 2)
    )
    local hr = (ct_hr + GetNumber("SANDMAN_TIME_DIFFERNCE")) % 24
    local min = tonumber(
        string.sub(ct, 4, 5)
    )
    local sec = tonumber(
        string.sub(ct, 7, 8)
    )
    return hr + min/60 + sec/3600
end