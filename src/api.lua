function Sandman_Disable()
    -- disable SANDMAN
    StoreBoolean("SANDMAN_ENABLED", false)
    Sandman_Clear()
    Sandman_RemoveSpecialActions()
end

function Sandman_Enable()
    -- enable SANDMAN
    Sandman_Restore()
    StoreBoolean("SANDMAN_ENABLED", true)
    Sandman_AddSpecialActions()
end

function Sandman_IsEnabled()
    return GetBoolean("SANDMAN_ENABLED")
end

function Sandman_ClassByDBID(dbid)
    local classname = SANDMAN_DBID_TO_CLASS[tostring(dbid)]
    if classname ~= nil then
        return classname
    end
    return "Unknown"
end

function Sandman_CrewByDBID(dbid)
    local crewnum = tonumber(
        SANDMAN_DBID_TO_CREW[tostring(dbid)]
    )
    if crewnum ~= nil then
        return crewnum
    end
    return 1
end

-- For scenario authors to manually add reserves
function Sandman_AddReserves(args)
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local sandman = Sandman_GetState()

    local base_guid = args.guid
    local _, base = pcall(
        ScenEdit_GetUnit,
        {
            guid=base_guid
        }
    )

    if base == nil then
        return
    end

    local dbid = args.dbid
    local proficiency = args.proficiency
    local num_reserves = args.num

    local crew_args = {}
    if args.min_hoursawake then
        crew_args.min_hoursawake = args.min_hoursawake
    end
    if args.max_hoursawake then
        crew_args.min_hoursawake = args.max_hoursawake
    end
    crew_args.longitude = base.longitude

    for i=1,num_reserves do
        Sandman_AddReserveCrew(
            sandman.reserve_state,
            dbid,
            base,
            proficiency,
            sandman.crew_state,
            crew_args
        )
    end

    Sandman_StoreState(sandman)
end

-- For scenario authors to set a unit's sleep deficit manually
function Sandman_SetRandomSleepDeficit(args)
    local guid = args.guid
    local min_hrs = args.min_hoursawake
    local max_hrs = args.max_hoursawake
    local longitude = args.longitude

    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local sandman = Sandman_GetState()
    local unit_state = sandman.unit_state
    local crew_state = sandman.crew_state

    for k, id in ipairs(unit_state.guids) do
        if id == guid then
            local _, unit = pcall(
                ScenEdit_GetUnit,
                {
                    guid=id
                }
            )
            if unit then
                local cindex = unit_state.crewindices[k]
                local circadian_hr
                if longitude then
                    circadian_hr = GetLocalTimeDifference(longitude)
                else
                    circadian_hr = crew_state.circadian_hr[cindex]
                end
                local circadian = CustomCircadianTerm(
                    GetZuluTime() - circadian_hr
                )

                local crewnum = unit_state.crewsizes[k]
                local crewindex = unit_state.crewindices[k]
                local effect_avg = 0
                for i=1, crewnum do
                    local ci = crewindex + i - 1
                    local sleep_units = SLEEP_RESERVOIR_CAPACITY - RandomSleepDeficit(min_hrs, max_hrs)
                    local effect = EffectivenessScore(sleep_units, circadian)
                    crew_state.sleep_units[ci] = sleep_units
                    crew_state.effects[ci] = effect
                    effect_avg = effect_avg + effect
                end
                effect_avg = effect_avg / crewnum
                unit_state.effects[k] = effect_avg
                local baseprof = unit_state.baseprofs[k]

                local prof_name = ProfNameByNumber(
                    ProfByEffectiveness(baseprof, effect_avg)
                )
                if unit.proficiency ~= prof_name then
                    ScenEdit_SetUnit({
                        guid=id,
                        proficiency=prof_name
                    })
                end
                
                Sandman_StoreState(sandman)
                
                return true
            end
            break
        end
    end

    return false
end

-- For scenario authors to query unit effectiveness.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetEffectiveness(args)
    local guid = args.guid
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local unit_states = Sandman_GetUnitState()

    for k, id in ipairs(unit_states.guids) do
        if id == guid then
            return unit_states.effects[k]
        end
    end
    return 1
end

-- For scenario authors to query unit crash risk per hour.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetCrashRisk(args)
    local guid = args.guid
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local unit_state = Sandman_GetUnitState()

    for k, id in ipairs(unit_state.guids) do
        if id == guid then
            local _, u = pcall(
                ScenEdit_GetUnit,
                {
                    guid=guid
                }
            )
            if u then
                if u.base then
                    return CrashRisk(
                        3600,
                        unit_state.effects[k],
                        u.base
                    )
                else
                    break
                end
            else
                break
            end
        end
    end
    return 0
end

-- For scenario authors to query unit micronap risk per hour.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetMicroNapRisk(args)
    local guid = args.guid
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local unit_state = Sandman_GetUnitState()
    local crew_state = Sandman_GetCrewState()

    for k, id in ipairs(unit_state.guids) do
        if id == guid then
            local _, u = pcall(
                ScenEdit_GetUnit,
                {
                    guid=guid
                }
            )
            if u then
                local cindex = unit_state.crewindices[k]
                local circadian_hr = crew_state.circadian_hr[cindex]
                local circadian = CustomCircadianTerm(
                    GetZuluTime() - circadian_hr
                )
                return MicroNapRisk(
                    3600,
                    unit_state.effects[k],
                    circadian
                )
            else
                break
            end
        end
    end
    return 0
end