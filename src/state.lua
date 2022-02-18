function Sandman_NewState()
    return {
        unit_state = Sandman_NewUnitState(),
        crew_state = Sandman_NewCrewState(),
        reserve_state = Sandman_NewReserveState()
    }
end

function Sandman_GetState()
    return {
        unit_state = Sandman_GetUnitState(),
        crew_state = Sandman_GetCrewState(),
        reserve_state = Sandman_GetReserveState()
    }
end

function Sandman_StoreState(state)
    Sandman_StoreCrewState(state.crew_state)
    Sandman_StoreReserveState(state.reserve_state)
    Sandman_StoreUnitState(state.unit_state)
end

function Sandman_NewUnitState()
    return {
        guids = {},
        crewindices = {},
        crewsizes = {},
        effects = {},
        baseprofs = {},
        reststates = {},
        has_boltered = {},
        is_micronapping = {}
    }
end

function Sandman_GetUnitState()
    return {
        guids = GetArrayString("SANDMAN_UNIT_GUIDS"),
        crewindices = GetArrayNumber("SANDMAN_UNIT_CREWINDICES"),
        crewsizes = GetArrayNumber("SANDMAN_UNIT_CREWSIZES"),
        effects = GetArrayNumber("SANDMAN_UNIT_EFFECTS"),
        baseprofs = GetArrayNumber("SANDMAN_UNIT_BASEPROFS"),
        reststates = GetArrayNumber("SANDMAN_UNIT_RESTSTATES"),
        has_boltered = GetArrayNumber("SANDMAN_UNIT_BOLTER"),
        is_micronapping = GetArrayNumber("SANDMAN_UNIT_MICRONAP")
    }
end

function Sandman_StoreUnitState(unit_state)
    StoreArrayString("SANDMAN_UNIT_GUIDS", unit_state.guids)
    StoreArrayNumber("SANDMAN_UNIT_CREWINDICES", unit_state.crewindices)
    StoreArrayNumber("SANDMAN_UNIT_CREWSIZES", unit_state.crewsizes)
    StoreArrayNumber("SANDMAN_UNIT_EFFECTS", unit_state.effects)
    StoreArrayNumber("SANDMAN_UNIT_BASEPROFS", unit_state.baseprofs)
    StoreArrayNumber("SANDMAN_UNIT_RESTSTATES", unit_state.reststates)
    StoreArrayNumber("SANDMAN_UNIT_BOLTER", unit_state.has_boltered)
    StoreArrayNumber("SANDMAN_UNIT_MICRONAP", unit_state.is_micronapping)
end

function Sandman_AddUnit(state, unit)
    local unit_state = state.unit_state
    local crew_state = state.crew_state

    local unitindex = #unit_state.guids + 1

    --unit guid
    table.insert(
        unit_state.guids,
        unit.guid
    )

    --crew
    local crewnum = math.max(1, unit.crew)
    local crew_args = {
        min_hoursawake = MIN_HOURS_AWAKE,
        max_hoursawake = MAX_HOURS_AWAKE,
        longitude = unit.longitude
    }
    local crewindex = Sandman_AddCrew(crew_state, crewnum, crew_args)
    table.insert(
        unit_state.crewindices,
        crewindex
    )
    table.insert(
        unit_state.crewsizes,
        crewnum
    )
    table.insert(
        unit_state.effects,
        Sandman_GetCrewEffectiveness(crew_state, crewindex, crewnum)
    )

    --proficiency
    table.insert(
        unit_state.baseprofs,
        ProfNumberByName(unit.proficiency)
    )

    -- rest state
    local circadian = CustomCircadianTerm(
        GetLocalTime(unit.longitude)
    )
    table.insert(
        unit_state.reststates,
        RestStateByCondition(unit.condition_v, circadian)
    )

    -- starting states
    table.insert(
        unit_state.has_boltered,
        0
    )
    table.insert(
        unit_state.is_micronapping,
        0
    )

    return unitindex
end

function Sandman_GetUnitProficiency(state, index)
    local effect = state.unit_state.effects[index]
    local baseprof = state.unit_state.baseprofs[index]

    return ProfNameByNumber(
        ProfByEffectiveness(baseprof, effect)
    )
end

function Sandman_UpdateUnit(state, index, unit, active_interval, resting_interval)
    local unit_state = state.unit_state
    local crewnum = unit_state.crewsizes[index]
    local crewindex = unit_state.crewindices[index]

    local crew_state = state.crew_state
    local circadian_hr = crew_state.circadian_hr[crewindex]

    -- circadian phase shift
    local total_time = active_interval + resting_interval
    local time_diff = GetLocalTimeDifference(unit.longitude)
    local tz_dff = (time_diff - circadian_hr + 12) % 24 - 12
    local phase_shift = 0
    -- TODO: determine speed of phase transition by amt of light
    if tz_dff > 0 then
        -- east bound phase transition
        -- 1.5d / hour
        phase_shift = math.min(total_time/129600, tz_dff)
    elseif tz_dff < 0 then
        -- west bound phase transition
        -- 1d / hour
        phase_shift = math.max(-total_time/86400, tz_dff)
    end
    circadian_hr = circadian_hr + phase_shift
    local circadian = CustomCircadianTerm(
        (GetZuluTime() - circadian_hr) % 24
    )

    -- update crew first
    local sleep_units_lost = SLEEP_UNITS_LOST_MIN*active_interval/60
    local effect_avg = 0
    for i=1, crewnum do
        local ci = crewindex + i - 1
        local sleepres = crew_state.sleep_units[ci]
        local sleep_units_gained = 0
        if resting_interval > 0 then
           sleep_units_gained = RestorativeSleep(
               resting_interval,
               sleepres,
               circadian
            )
        end
        sleepres = Clamp(
            sleepres - sleep_units_lost + sleep_units_gained,
            0,
            SLEEP_RESERVOIR_CAPACITY
        )
        crew_state.sleep_units[ci] = sleepres
        local effect = EffectivenessScore(sleepres, circadian)
        crew_state.effects[ci] = effect
        effect_avg = effect_avg + effect
        crew_state.circadian_hr[ci] = circadian_hr
    end

    unit_state.reststates[index] = RestStateByCondition(
        unit.condition_v,
        circadian
    )

    effect_avg = effect_avg / crewnum
    unit_state.effects[index] = effect_avg

    local baseprof = state.unit_state.baseprofs[index]

    return ProfNameByNumber(
        ProfByEffectiveness(baseprof, effect_avg)
    )
end

function Sandman_NewCrewState()
    return {
        sleep_units = {},
        circadian_hr = {},
        effects = {}
    }
end

function Sandman_GetCrewState()
    return {
        sleep_units = GetArrayNumber("SANDMAN_CREW_SLEEPUNITS"),
        circadian_hr = GetArrayNumber("SANDMAN_CREW_CIRCADIANHR"),
        effects = GetArrayNumber("SANDMAN_CREW_EFFECTS")
    }
end

function Sandman_StoreCrewState(crew_state)
    StoreArrayNumber("SANDMAN_CREW_SLEEPUNITS", crew_state.sleep_units)
    StoreArrayNumber("SANDMAN_CREW_CIRCADIANHR", crew_state.circadian_hr)
    StoreArrayNumber("SANDMAN_CREW_EFFECTS", crew_state.effects)
end

function Sandman_AddCrew(crew_state, num, args)
    local min_hoursawake = args.min_hoursawake
    local max_hoursawake = args.max_hoursawake
    local start_hoursawake = 0
    if args.start_hoursawake then
        start_hoursawake = args.start_hoursawake
    end

    local return_index = #crew_state.sleep_units + 1

    local localhr = GetLocalTime(args.longitude)
    local circadian = CustomCircadianTerm(localhr)
    for i=1, num do
        local sleep_units = SLEEP_RESERVOIR_CAPACITY - RandomSleepDeficit(min_hoursawake, max_hoursawake) - SLEEP_UNITS_LOST_MIN*start_hoursawake*60
        local effect = EffectivenessScore(sleep_units, circadian)

        table.insert(
            crew_state.sleep_units,
            sleep_units
        )
        table.insert(
            crew_state.circadian_hr,
            GetLocalTimeDifference(args.longitude)
        )
        table.insert(
            crew_state.effects,
            effect
        )
    end

    return return_index
end

function Sandman_GetCrewEffectiveness(crew_state, index, num)
    local effect_avg = 0
    for i = 1, num do
        effect_avg = effect_avg + crew_state.effects[index + i - 1]
    end
    return effect_avg / num
end

function Sandman_NewReserveState()
    return {
        unit_types = {},
        base_guids = {},
        baseprofs = {},
        crewsizes = {},
        crewindices = {},
        effects = {}
    }
end

function Sandman_GetReserveState()
    return {
        unit_types = GetArrayNumber("SANDMAN_RESERVE_TYPES"),
        base_guids = GetArrayNumber("SANDMAN_RESERVE_BASEGUIDS"),
        baseprofs = GetArrayNumber("SANDMAN_RESERVE_BASEPROFS"),
        crewsizes = GetArrayNumber("SANDMAN_RESERVE_CREWSIZES"),
        crewindices = GetArrayNumber("SANDMAN_RESERVE_CREWINDICES"),
        effects = GetArrayNumber("SANDMAN_RESERVE_EFFECTS")
    }
end

function Sandman_StoreReserveState(reserve_state)
    StoreArrayNumber("SANDMAN_RESERVE_TYPES", reserve_state.unit_types)
    StoreArrayNumber("SANDMAN_RESERVE_BASEGUIDS", reserve_state.base_guids)
    StoreArrayNumber("SANDMAN_RESERVE_BASEPROFS", reserve_state.baseprofs)
    StoreArrayNumber("SANDMAN_RESERVE_CREWSIZES", reserve_state.crewsizes)
    StoreArrayNumber("SANDMAN_RESERVE_CREWINDICES", reserve_state.crewindices)
    StoreArrayNumber("SANDMAN_RESERVE_EFFECTS", reserve_state.effects)
end

function Sandman_AddReserveCrew(reserve_state, unit_type, base, proficiency, crew_state, num, args)
    table.insert(
        reserve_state.unit_types,
        unit_type
    )
    table.insert(
        reserve_state.base_guids,
        base.guid
    )
    table.insert(
        reserve_state.baseprofs,
        ProfNumberByName(proficiency)
    )
    table.insert(
        reserve_state.crewsizes,
        num
    )
    local crewindex = Sandman_AddCrew(crew_state, num, args)
    table.insert(
        reserve_state.crewindices,
        crewindex
    )
    table.insert(
        reserve_state.effects,
        Sandman_GetCrewEffectiveness(crew_state, crewindex, num)
    )
end

function Sandman_UpdateReserveCrew(state, index, resting_interval)
    local crew_state = state.crew_state
    local reserve_state = state.reserve_state

    local crewnum = reserve_state.crewsizes[index]
    local crewindex = reserve_state.crewindices[index]

    local circadian_hr = crew_state.circadian_hr[crewindex]
    local base_guid = reserve_state.base_guids[index]
    local _, base = pcall(
        ScenEdit_GetUnit,
        {
            guid=base_guid
        }
    )
    if base == nil then
        return
    end

    -- circadian phase shift
    local total_time = resting_interval
    local time_diff = GetLocalTimeDifference(base.longitude)
    local tz_dff = (time_diff - circadian_hr + 12) % 24 - 12
    local phase_shift = 0
    -- TODO: determine speed of phase transition by amt of light
    if tz_dff > 0 then
        -- east bound phase transition
        -- 1.5d / hour
        phase_shift = math.min(total_time/129600, tz_dff)
    elseif tz_dff < 0 then
        -- west bound phase transition
        -- 1d / hour
        phase_shift = math.max(-total_time/86400, tz_dff)
    end
    circadian_hr = circadian_hr + phase_shift
    local circadian = CustomCircadianTerm(
        (GetZuluTime() - circadian_hr) % 24
    )

    -- update crew first
    local effect_avg = 0
    for i=1, crewnum do
        local ci = crewindex + i - 1
        local sleepres = crew_state.sleep_units[ci]
        local sleep_units_gained = 0
        if resting_interval > 0 then
           sleep_units_gained = RestorativeSleep(
               resting_interval,
               sleepres,
               circadian
            )
        end
        sleepres = Clamp(
            sleepres + sleep_units_gained,
            0,
            SLEEP_RESERVOIR_CAPACITY
        )
        crew_state.sleep_units[ci] = sleepres
        local effect = EffectivenessScore(sleepres, circadian)
        crew_state.effects[ci] = effect
        effect_avg = effect_avg + effect
        crew_state.circadian_hr[ci] = circadian_hr
    end

    effect_avg = effect_avg / crewnum
    reserve_state.effects[index] = effect_avg
end

function Sandman_Unit_TrySwapReserve(state, unit, index)
    local unit_state = state.unit_state
    local crew_state = state.crew_state
    local reserve_state = state.reserve_state

    if unit.base then
        local max_effect = unit_state.effects[index]
        local reserve_index = -1
        for k, id in ipairs(reserve_state.base_guids) do
            if id == unit.base.guid then
                if tonumber(unit.dbid) == reserve_state.unit_types[k] then
                    if reserve_state.effects[k] > max_effect then
                        reserve_index = k
                        max_effect = reserve_state.effects[k]
                    end
                end
            end
        end

        -- Found a valid reserve crew for swap
        if reserve_index ~= -1 then
            -- swap crew indices
            local oldcrewindex = unit_state.crewindices[index]
            unit_state.crewindices[index] = reserve_state.crewindices[reserve_index]
            reserve_state.crewindices[reserve_index] = oldcrewindex

            -- set new effectiveness level
            unit_state.effects[index] = Sandman_GetCrewEffectiveness(
                crew_state,
                unit_state.crewindices[index],
                unit_state.crewsizes[index]
            )

            local oldprof = unit_state.baseprofs[index]
            unit_state.baseprofs[index] = reserve_state.baseprofs[reserve_index]
            reserve_state.baseprofs[reserve_index] = oldprof
            local effectiveprof = ProfByEffectiveness(
                unit_state.baseprofs[index],
                unit_state.effects[index]
            )
            local newprof = ProfNameByNumber(effectiveprof)
            if unit.proficiency ~= newprof then
                pcall(
                    ScenEdit_SetUnit,
                    {
                        guid=unit.guid,
                        proficiency=newprof
                    }
                )
            end
        end
    end
end