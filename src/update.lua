__UPDATE_INTERVALS__ = {61, 47, 73, 53, 59, 67, 71}
__CUR_UPDATE_INTERVAL__ = 0
function Sandman_CreateNextUpdate()
    __CUR_UPDATE_INTERVAL__ = (__CUR_UPDATE_INTERVAL__ + 1) % #__UPDATE_INTERVALS__
    local next_update_index = 1 + __CUR_UPDATE_INTERVAL__
    local next_interval = __UPDATE_INTERVALS__[next_update_index]-1

    local next_update_evt = ExecuteAt(
        ScenEdit_CurrentTime() + next_interval,
        "Sandman_Update("..tostring(next_interval)..")"
    )
    StoreString("SANDMAN_NEXT_UPDATE_EVT", next_update_evt)
end

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
    local crew_state = sandman.crew_state
    local reserve_state = sandman.reserve_state
    local unit_micronapping = unit_state.is_micronapping
    local unit_boltered = unit_state.has_boltered

    local zulutime = GetZuluTime()

    -- update reserve crews
    for k=1, #sandman.reserve_state.base_guids do
        Sandman_UpdateReserveCrew(
            crew_state,
            reserve_state,
            k,
            interval
        )
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
            if unit.loadoutdbid ~= 4 and unit.loadoutdbid ~= 3 then
                if unit_state.is_active[k] == 0 then
                    -- just reactivated, move in reserve crews
                    Sandman_Unit_TrySwapReserve(sandman, unit, k)
                    if unit_state.crewindices[k] == -1 then
                        -- if no reserves available,
                        -- add new crew at lowest skill
                        unit_state.baseprofs[k] = 1
                        local ucrew = math.max(1, unit.crew)
                        local crewargs = {
                            longitude = unit.longitude
                        }
                        local cindex = Sandman_AddCrew(
                            unit.side,
                            crew_state,
                            ucrew,
                            crewargs
                        )
                        unit_state.crewindices[k] = cindex
                        unit_state.is_active[k] = 1
                    end
                end

                Sandman_UpdateUnit(
                    sandman,
                    k,
                    unit,
                    interval
                )

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
                local crewindex = unit_state.crewindices[k]
                local circadian_hr = crew_state.circadian_hr[crewindex]
                local circadian = CustomCircadianTerm(
                    zulutime - circadian_hr
                )

                if unit.airbornetime_v > 0 then
                    -- AIRBORNE
                    -- if unit previously boltered, turn it around
                    if unit_boltered[k] == 1 then
                        unit:RTB(true)
                        unit_boltered[k] = 0
                    end

                    
                    local dice_roll
                    if unit.crew > 0 then
                        -- if not a UAV, check if we've been caught nappin'
                        dice_roll = Random()
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
                    end

                    -- Small risk of aircraft crashing on landing
                    if unit.condition == "On final approach" or unit.condition == "In landing queue" then
                        if unit.base then
                            local crash_risk = CrashRisk(
                                unit.side, 
                                interval, 
                                cur_effect, 
                                unit.base
                            )
                            dice_roll = Random()
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

                    -- check for replacement
                    local sidenum = SideNumberByName(unit.side)
                    local rthresh = RESERVE_REPLACE_THRESHOLD[sidenum]
                    if cur_effect < rthresh then
                        Sandman_Unit_TrySwapReserve(sandman, unit, k)
                    end
                end
            else
                if unit_state.is_active[k] == 1 then
                    -- move crew to reserve
                    Sandman_MoveToReserve(sandman, unit, k)
                end
            end
        end
    end

    Sandman_StoreState(sandman)

    -- set up next update
    Sandman_CreateNextUpdate()
end