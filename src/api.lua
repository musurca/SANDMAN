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

-- For scenario authors to set a unit's sleep deficit manually
function Sandman_SetRandomSleepDeficit(guid, min_hrs, max_hrs)
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
                local circadian = CustomCircadianTerm(
                    GetLocalTime(unit.longitude)
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
function Sandman_GetEffectiveness(guid)
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
function Sandman_GetCrashRisk(guid)
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
function Sandman_GetMicroNapRisk(guid)
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
                return MicroNapRisk(
                    3600,
                    unit_state.effects[k],
                    CustomCircadianTerm(
                        GetLocalTime(
                            u.longitude
                        )
                    )
                )
            else
                break
            end
        end
    end
    return 0
end