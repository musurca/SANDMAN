-- interval in seconds
function Sandman_Update(interval)
    -- quit if disabled
    if Sandman_IsEnabled() == false then
        return
    end

    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local sandman = Sandman_GetState()
    local unit_state = sandman.unit_state
    local unit_micronapping = unit_state.is_micronapping
    local unit_boltered = unit_state.has_boltered

    -- update reserve crews
    for k=1, #sandman.reserve_state.base_guids do
        Sandman_UpdateReserveCrew(sandman, k, interval)
    end

    -- update active units
    for k, id in ipairs(unit_state.guids) do
        local _, unit = pcall(
            ScenEdit_GetUnit,
            {
                guid=id
            }
        )

        if unit then
            -- only update units not under maintenance
            if unit.loadoutdbid ~= 4 then
                local interval_resting = 0
                if unit.condition_v == "Parked" then
                    -- most effective rest
                    interval_resting = interval*PARKED_PERCENTAGE
                elseif string.find(unit.condition_v, "Readying") ~= nil then
                    -- less effective rest
                    interval_resting = interval*READYING_PERCENTAGE
                end
                -- otherwise we're totally awake
                local interval_active = interval - interval_resting

                local new_prof_name = Sandman_UpdateUnit(
                    sandman,
                    k,
                    unit,
                    interval_active,
                    interval_resting
                )
                
                if unit.proficiency ~= new_prof_name then
                    pcall(
                        ScenEdit_SetUnit,
                        {
                            guid=unit.guid,
                            proficiency=new_prof_name
                        }
                    )
                end

                local function unit_set_nap(u, isnap)
                    local uguid = u.guid
                    local ucourse = u.course
                    local inv_isnap = not isnap
                    
                    if isnap then
                        local pt = World_GetPointFromBearing(
                            {
                                latitude = u.latitude,
                                longitude = u.longitude,
                                distance = 500,
                                bearing = u.heading
                            }
                        )
                        table.insert(
                            ucourse,
                            1,
                            {
                                latitude = pt.latitude,
                                longitude = pt.longitude
                            }
                        )
                    else
                        table.remove(ucourse, 1)
                    end

                    pcall(
                        ScenEdit_SetUnit,
                        {
                            guid=uguid,
                            course=ucourse,
                            outofcomms=isnap,
                            AI_EvaluateTargets_enabled=inv_isnap,
                            AI_DeterminePrimaryTarget_enabled=inv_isnap
                        }
                    )
                end

                local cur_effect = unit_state.effects[k]
                local circadian = CustomCircadianTerm(
                    GetLocalTime(unit.longitude)
                )

                if unit.airbornetime_v > 0 then
                    -- AIRBORNE
                    -- if unit previously boltered, turn it around
                    if unit_boltered[k] == 1 then
                        unit:RTB(true)
                        unit_boltered[k] = 0
                    end

                     -- check if we've been caught nappin'
                    local dice_roll = Random()
                    local nap_risk = MicroNapRisk(interval, cur_effect, circadian)
                    -- divide nap risk by number of crew members
                    nap_risk = nap_risk / unit_state.crewsizes[k]
                    
                    if unit_micronapping[k] == 1 then
                        -- if already napping, twice as likely to continue
                        if dice_roll*2 > nap_risk then
                            unit_set_nap(unit, false)
                            unit_micronapping[k] = 0
                        end
                    else
                        if dice_roll <= nap_risk then
                            -- pilot falls asleep
                            unit_set_nap(unit, true)
                            unit_micronapping[k] = 1
                        end
                    end

                    -- Small risk of aircraft crashing on landing
                    if unit.condition == "On final approach" or unit.condition == "In landing queue" then
                        if unit.base then
                            local crash_risk = CrashRisk(interval, cur_effect, unit.base)
                            local dice_roll = Random()
                            if dice_roll <= crash_risk then
                                local preposition = "at"
                                if unit.base.type == "Ship" then
                                    preposition = "on"
                                end
                                local msg = unit.name.." crashed while attempting to land "..preposition.." "..unit.base.name.."."
                                ScenEdit_SpecialMessage(
                                    unit.side,
                                    msg,
                                    {
                                        latitude=unit.latitude,
                                        longitude=unit.longitude
                                    }
                                )
                                ScenEdit_KillUnit({
                                    guid=unit.guid
                                })
                            else
                                -- a go-around/bolter is 100x more likely
                                if Clamp(dice_roll*100, 0, 0.95) <= crash_risk then
                                    unit:RTB(false)
                                    unit_boltered[k] = 1
                                end
                            end
                        end
                    end
                else
                    -- ON THE GROUND
                    -- reset micronapping/bolter states
                    if unit_micronapping[k] == 1 then
                        --nap stops
                        unit_set_nap(unit, false)
                        unit_micronapping[k] = 0
                    end
                    if unit_boltered[k] == 1 then
                        unit_boltered[k] = 0
                    end

                    -- TODO: if plane has been set to maintenance mode,
                    -- move pilots into the available reserves
                        
                    -- check for replacement
                    local sidenum = SideNumberByName(unit.side)
                    local rthresh = RESERVE_REPLACE_THRESHOLD[sidenum]
                    if cur_effect < rthresh then
                        Sandman_Unit_TrySwapReserve(sandman, unit, k)
                    end
                end
            end
        end
    end

    Sandman_StoreState(sandman)
end