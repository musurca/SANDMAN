-- Returns difference from UTC using CMO's timezone approximation
function GetLocalTimeDifference(longitude)
    return math.floor( ( longitude+7.5 ) / 15 )
end

-- returns local hour as real number
function GetLocalTime(longitude)
    local ct = EpochToUTC_Time(
        ScenEdit_CurrentTime()
    )
    local ct_hr = tonumber(
        string.sub(ct, 1, 2)
    )
    local hr = (
        ct_hr + GetLocalTimeDifference(longitude)
    ) % 24
    local min = tonumber(
        string.sub(ct, 4, 5)
    )
    local sec = tonumber(
        string.sub(ct, 7, 8)
    )
    return hr + min/60 + sec/3600
end