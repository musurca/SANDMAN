function Sandman_Init()
    local tracked_guids = {}
    -- find all aircraft to track
    for k, side in ipairs(VP_GetSides()) do
        for n, unit in ipairs(side.units) do
            local u = ScenEdit_GetUnit({guid=unit.guid})
            if u.type=="Aircraft" then
                table.insert(tracked_guids, unit.guid)
            end
        end
    end

    local sandman = Sandman_NewState()

    for k, v in ipairs(tracked_guids) do
        local ac = ScenEdit_GetUnit({guid=v})
        local uindex = Sandman_AddUnit(sandman, ac)

        -- set initial proficiency
        local prof_name = Sandman_GetUnitProficiency(sandman, uindex)
        if ac.proficiency ~= prof_name then
            ScenEdit_SetUnit({
                guid=v,
                proficiency=prof_name
            })
        end
    end

    Sandman_StoreState(sandman)

    StoreBoolean("UNIT_TRACKER_INITIALIZED", true)
end

function Sandman_CheckInit()
    if GetBoolean("UNIT_TRACKER_INITIALIZED") == false then
        Sandman_Init()
    end
end

--true if IKE is installed in this scenario
function Sandman_HasIKE()
    return ScenEdit_GetKeyValue("__SCEN_SETUPPHASE") ~= ""
end

-- add the fatigue management special actions
function Sandman_AddSpecialActions()
    ForEachDo(VP_GetSides(), function(side)
        local sname = side.name
        SpecialAction_Create(
            "Fatigue Avoidance Scheduling Tool (All Pilots)",
            "Shows the current effectiveness state for all of your pilots.",
            sname,
            "Sandman_Display()"
        )

        SpecialAction_Create(
            "Fatigue Avoidance Scheduling Tool (Selected Pilots)",
            "Shows the current effectiveness state for the currently selected aircraft.",
            sname,
            "Sandman_DisplaySelected()"
        )
    end)
end

-- remove the fatigue management special actions
function Sandman_RemoveSpecialActions()
    ForEachDo(VP_GetSides(), function(side)
        local sname = side.name
        SpecialAction_Delete(
            "Fatigue Avoidance Scheduling Tool (All Pilots)", 
            sname
        )

        SpecialAction_Delete(
            "Fatigue Avoidance Scheduling Tool (Selected Pilots)",
            sname
        )
    end)
end

--reset tracked aircraft to their base proficiency
function Sandman_Clear()
    if GetBoolean("UNIT_TRACKER_INITIALIZED") == true then
        local unit_state = Sandman_GetUnitState()

        for k, id in ipairs(unit_state.guids) do
            local baseprof = unit_state.baseprofs[k]
            local _, unit = pcall(
                ScenEdit_GetUnit,
                {
                    guid=id
                }
            )

            -- reset original unit proficiency
            if unit then
                pcall(
                    ScenEdit_SetUnit,
                    {
                        guid=id,
                        proficiency=ProfNameByNumber(baseprof)
                    }
                )
            end
        end
    end
end

--restore tracked aircraft to their fatigue-related proficiency
function Sandman_Restore()
    if GetBoolean("UNIT_TRACKER_INITIALIZED") == true then
        local sandman = Sandman_GetState()
        local unit_state = sandman.unit_state
        
        for k, id in ipairs(unit_state.guids) do
            local _, unit = pcall(
                ScenEdit_GetUnit,
                {
                    guid=id
                }
            )
    
            if unit then
                -- set initial proficiency
                local prof_name = Sandman_GetUnitProficiency(sandman, k)
                if unit.proficiency ~= prof_name then
                    pcall(
                        ScenEdit_SetUnit,
                        {
                            guid=id,
                            proficiency=prof_name
                        }
                    )
                end
            end
        end
    end
end