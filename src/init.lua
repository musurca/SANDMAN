function Sandman_Init()
    local dbid_to_name={}
    local dbid_to_crew={}
    local tracked_guids = {}
    -- find all aircraft to track
    for k, side in ipairs(VP_GetSides()) do
        for n, unit in ipairs(side.units) do
            local u = ScenEdit_GetUnit({guid=unit.guid})
            if u.type=="Aircraft" then
                table.insert(tracked_guids, unit.guid)
                local dbid = tostring(u.dbid)
                dbid_to_name[dbid] = u.classname
                dbid_to_crew[dbid] = u.crew
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

    SANDMAN_DBID_TO_CLASS = dbid_to_name
    SANDMAN_DBID_TO_CREW = dbid_to_crew
    StoreDictionary("SANDMAN_DBID_CLASSNAME", dbid_to_name)
    StoreDictionary("SANDMAN_DBID_CREWSIZE", dbid_to_crew)

    StoreBoolean("SANDMAN_INITIALIZED", true)
end

function Sandman_CheckInit()
    if GetBoolean("SANDMAN_INITIALIZED") == false then
        Sandman_Init()
    end
end

--true if IKE is installed in this scenario
function Sandman_HasIKE()
    return ScenEdit_GetKeyValue("__SCEN_SETUPPHASE") ~= ""
end

--reset tracked aircraft to their base proficiency
function Sandman_Clear()
    if GetBoolean("SANDMAN_INITIALIZED") == true then
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

    local update_evt = GetString("SANDMAN_NEXT_UPDATE_EVT")
    if update_evt ~= "" then
        Event_Delete(update_evt, true)
        StoreString("SANDMAN_NEXT_UPDATE_EVT", "")
    end
end

--restore tracked aircraft to their fatigue-related proficiency
function Sandman_Restore()
    if GetBoolean("SANDMAN_INITIALIZED") == true then
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

    local update_evt = GetString("SANDMAN_NEXT_UPDATE_EVT")
    if update_evt == "" then
        Sandman_CreateNextUpdate()
    end
end