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

        SpecialAction_Create(
            "View Available Reserve Pilots (All Bases)",
            "Shows available reserve crews in all friendly bases.",
            sname,
            "Sandman_ShowReservesAll()"
        )

        SpecialAction_Create(
            "View Available Reserve Pilots (Selected Bases)",
            "Shows available reserve crews in selected friendly bases.",
            sname,
            "Sandman_ShowReservesSelected()"
        )

        SpecialAction_Create(
            "Set Pilot Replacement Threshold",
            "Sets the effectiveness threshold below which returning crews will be replaced by available reserves.",
            sname,
            "Sandman_InputReserveThreshold()"
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

        SpecialAction_Delete(
            "View Available Reserve Pilots (All Bases)",
            sname
        )

        SpecialAction_Delete(
            "View Available Reserve Pilots (Selected Bases)",
            sname
        )

        SpecialAction_Delete(
            "Set Pilot Replacement Threshold",
            sname
        )
    end)
end

function Sandman_InputReserveThreshold()
    local sidenum = SideNumberByName(ScenEdit_PlayerSide())
    local def_thresh = Round(RESERVE_REPLACE_THRESHOLD[sidenum]*100)

    local thresh = -1
    repeat
        thresh = Input_Number_Default("Enter the effectiveness threshold below which pilots will be replaced by fresh reserves, if possible (0-99):\n\nDEFAULT: "..def_thresh, def_thresh)
    until (thresh >= 0 and thresh <= 99)

    RESERVE_REPLACE_THRESHOLD[sidenum] = thresh/100
    StoreArrayNumber("SANDMAN_DEF_RESERVE_THRESH", RESERVE_REPLACE_THRESHOLD)
    
    Input_OK("Pilots will now be replaced when they fall below "..thresh.."% effectiveness.")
end

function Sandman_Display(selected_guids)
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    -- formatting for our old-skool HTML tables
    local table_names = { "UNIT DESIGNATION", "SKILL", "P.A.T.", "EFFECTIVENESS" }
    local table_header = "<table cellSpacing=1 cols="..#table_names.." cellPadding=1 width=\"95%\" border=2><tbody>"
    table_header = table_header.."<tr>"
    for k, tname in ipairs(table_names) do
        table_header = table_header.."<td><b>"..tname.."</b></td>"
    end
    table_header = table_header.."</tr>"
    local table_footer = "</tbody></table>"
    local msg_body = ""

    local unit_state = Sandman_GetUnitState()
    local crew_state = Sandman_GetCrewState()

    local function start_table()
        msg_body = msg_body..table_header
    end

    local function end_table()
        msg_body = msg_body..table_footer
    end

    local function start_row()
        msg_body = msg_body.."<tr>"
    end

    local function end_row()
        msg_body = msg_body.."</tr>"
    end
    
    local function add_column(data)
        msg_body = msg_body.."<td>"..data.."</td>"
    end

    local status_dict = {}
    local pside = ScenEdit_PlayerSide()

    local function was_selected(uguid)
        if selected_guids then
            for k, g in ipairs(selected_guids) do
                if uguid == g then
                    return true
                end
            end
            return false
        end
        return true
    end

    local units_selected = 0

    -- collect units and group them by type
    for k, id in ipairs(unit_state.guids) do
        local _, unit = pcall(
            ScenEdit_GetUnit,
            {
                guid=id
            }
        )
        if unit and was_selected(id) then
            -- if on our side and not under maintenance
            if unit.side == pside and unit.loadoutdbid ~= 4 and unit.loadoutdbid ~= 3 and unit_state.is_active[k] == 1 then
                units_selected = units_selected + 1

                -- organize units by their status condition
                local cv = unit.condition_v
                local baselist_dict = status_dict[cv]
                if baselist_dict == nil then
                    baselist_dict = {}
                    status_dict[cv] = baselist_dict
                end
                
                -- then organize by their group name or originating base
                local group_index
                if unit.group ~= nil then
                    group_index = unit.group.name
                elseif unit.base ~= nil then
                    group_index = unit.base.name
                else
                    group_index = "Unassigned"
                end
                local unitlist_dict = baselist_dict[group_index]
                if unitlist_dict == nil then
                    unitlist_dict = {}
                    baselist_dict[group_index] = unitlist_dict
                end

                -- finally organize by their class
                local unitlist = unitlist_dict[unit.classname]
                if unitlist == nil then
                    unitlist = {}
                    unitlist_dict[unit.classname] = unitlist
                end
                -- since we're indexing out of order, we treat the table
                -- as a dictionary instead of array. the indices are
                -- converted to string keys.
                unitlist[tostring(k)] = unit
            end
        end
    end

    if units_selected == 0 then
        Input_OK("No valid units selected!")
        return
    end

    local function show_units_by_status(s, bl_dict)
        msg_body = msg_body.."<hr><center><h2>"..string.upper(s).."</h2></center><hr>"
        for basename, unitlist_dict in pairs(bl_dict) do
            msg_body = msg_body.."<center><p><h2><u>"..basename.."</u></h2></p></center>"
            for uclass, unitlist in pairs(unitlist_dict) do
                if not DictionaryEmpty(unitlist) then
                    msg_body = msg_body.."<b>"..uclass.."</b>"
                    start_table()
                    for n, unit in pairs(unitlist) do
                        -- convert key from string to number for array index
                        local k = tonumber(n)
                        -- display row for unit
                        start_row()

                        -- UNIT DESIGNATION
                        add_column(
                            unit.name
                        )

                        -- SKILL
                        local unit_effect = unit_state.effects[k]
                        local baseprof = unit_state.baseprofs[k]
                        local realprof = ProfByEffectiveness(baseprof, unit_effect)
                        local profname
                        if baseprof == realprof then
                            profname = ProfNameByNumber(baseprof)
                        else
                            profname = "<i>("..ProfNameByNumber(realprof)..")</i>"
                        end
                        add_column(
                            profname
                        )

                        -- P.A.T.
                        local cindex = unit_state.crewindices[k]
                        local circadian_hr = crew_state.circadian_hr[cindex]
                        local pat = (18 - circadian_hr) % 24
                        local pat_hr = math.floor(pat)
                        local pat_min = Round((pat - pat_hr)*60)
                        local pat_hr_str = tostring(pat_hr)
                        local pat_min_str = tostring(pat_min)
                        if string.len(pat_hr_str) == 1 then
                            pat_hr_str = "0"..pat_hr_str
                        end
                        if string.len(pat_min_str) == 1 then
                            pat_min_str = "0"..pat_min_str
                        end
                        add_column(
                            pat_hr_str..":"..pat_min_str.."Z"
                        )

                        -- EFFECTIVENESS
                        local rest_arrow = UNIT_RESTSTATES[
                            unit_state.reststates[k]
                        ]
                        add_column(
                            "<center>"..Round(unit_effect*100).."% "..rest_arrow.."</center>"
                        )
                        end_row()
                    end
                    end_table()
                    msg_body = msg_body.."<br/>"
                end
            end
        end
        msg_body = msg_body.."<hr><br/>"
    end

    for status, baselist_dict in pairs(status_dict) do
        if status ~= "Parked" then
            show_units_by_status(status, baselist_dict)
        end
    end
    if status_dict["Parked"] ~= nil then
        show_units_by_status("Parked", status_dict["Parked"])
    end

    ScenEdit_SpecialMessage("playerside", msg_body)

    -- if we're running IKE as well, we need to flush the msg queue
    if Sandman_HasIKE() == true then
        if PBEM_FlushSpecialMessages then
            PBEM_FlushSpecialMessages()
        end
    end
end

function Sandman_DisplaySelected()
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local guids = {}
    local u = ScenEdit_SelectedUnits()
    if u then
        for k, unit in ipairs(u.units) do
            local _, u = pcall(
                ScenEdit_GetUnit,
                {
                    guid=unit.guid
                }
            )
            if u then
                if u.type == "Aircraft" then
                    table.insert(guids, unit.guid)
                elseif u.embarkedUnits then
                    if u.embarkedUnits.Aircraft then
                        for n, ac_guid in ipairs(u.embarkedUnits.Aircraft) do
                            table.insert(guids, ac_guid)
                        end
                    end
                end
            end
        end
    end
    if #guids > 0 then
        Sandman_Display(guids)
    else
        Input_OK("No units selected!")
    end
end

function Sandman_ShowReservesAll(selected_guids)
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    -- formatting for our old-skool HTML tables
    local table_names = { "SKILL", "P.A.T.", "EFFECTIVENESS" }
    local table_header = "<table cellSpacing=1 cols="..#table_names.." cellPadding=1 width=\"95%\" border=2><tbody>"
    table_header = table_header.."<tr>"
    for k, tname in ipairs(table_names) do
        table_header = table_header.."<td><b>"..tname.."</b></td>"
    end
    table_header = table_header.."</tr>"
    local table_footer = "</tbody></table>"
    local msg_body = ""

    local reserve_state = Sandman_GetReserveState()
    if #reserve_state.base_guids == 0 then
        Input_OK("No reserves available!")
    end
    local crew_state = Sandman_GetCrewState()

    local function start_table()
        msg_body = msg_body..table_header
    end

    local function end_table()
        msg_body = msg_body..table_footer
    end

    local function start_row()
        msg_body = msg_body.."<tr>"
    end

    local function end_row()
        msg_body = msg_body.."</tr>"
    end
    
    local function add_column(data)
        msg_body = msg_body.."<td>"..data.."</td>"
    end

    local base_dict = {}
    local pside = ScenEdit_PlayerSide()

    local function was_selected(uguid)
        if selected_guids then
            for k, g in ipairs(selected_guids) do
                if uguid == g then
                    return true
                end
            end
            return false
        end
        return true
    end

    local units_selected = 0

    -- collect units and group them by type
    for k, id in ipairs(reserve_state.base_guids) do
        local _, base = pcall(
            ScenEdit_GetUnit,
            {
                guid=id
            }
        )
        local rtype = reserve_state.unit_types[k]
        local rtypename = Sandman_ClassByDBID(rtype)
        if base and was_selected(id) then
            if base.side == pside and rtypename ~= nil and reserve_state.is_active[k] == 1 then
                units_selected = units_selected + 1

                -- organize reserves by their base
                local bname = base.name
                local typelist_dict = base_dict[bname]
                if typelist_dict == nil then
                    typelist_dict = {}
                    base_dict[bname] = typelist_dict
                end

                -- finally organize by their class
                local unitlist = typelist_dict[rtypename]
                if unitlist == nil then
                    unitlist = {}
                    typelist_dict[rtypename] = unitlist
                end

                table.insert(unitlist, k)
            end
        end
    end

    if units_selected == 0 then
        Input_OK("No available reserves in selected bases!")
        return
    end

    msg_body = msg_body.."<hr><center><h2>".."RESERVES".."</h2></center><hr>"
    for basename, typelist_dict in pairs(base_dict) do
        msg_body = msg_body.."<center><p><h2><u>"..basename.."</u></h2></p></center>"
        for uclass, unitlist in pairs(typelist_dict) do
            if not DictionaryEmpty(unitlist) then
                msg_body = msg_body.."<b>"..uclass.."</b>"
                start_table()
                for n, k in ipairs(unitlist) do
                    -- display row for unit
                    start_row()

                    -- SKILL
                    local unit_effect = reserve_state.effects[k]
                    local baseprof = reserve_state.baseprofs[k]
                    local realprof = ProfByEffectiveness(baseprof, unit_effect)
                    local profname
                    if baseprof == realprof then
                        profname = ProfNameByNumber(baseprof)
                    else
                        profname = "<i>("..ProfNameByNumber(realprof)..")</i>"
                    end
                    add_column(
                        profname
                    )

                    -- P.A.T.
                    local cindex = reserve_state.crewindices[k]
                    local circadian_hr = crew_state.circadian_hr[cindex]
                    local pat = (18 - circadian_hr) % 24
                    local pat_hr = math.floor(pat)
                    local pat_min = Round((pat - pat_hr)*60)
                    local pat_hr_str = tostring(pat_hr)
                    local pat_min_str = tostring(pat_min)
                    if string.len(pat_hr_str) == 1 then
                        pat_hr_str = "0"..pat_hr_str
                    end
                    if string.len(pat_min_str) == 1 then
                        pat_min_str = "0"..pat_min_str
                    end
                    add_column(
                        pat_hr_str..":"..pat_min_str.."Z"
                    )

                    -- EFFECTIVENESS
                    local rest_arrow = UNIT_RESTSTATES[
                        STATE_REST_HEAVY
                    ]
                    local unit_effect = reserve_state.effects[k]
                    add_column(
                        "<center>"..Round(unit_effect*100).."% "..rest_arrow.."</center>"
                    )
                    end_row()
                end
                end_table()
                msg_body = msg_body.."<br/>"
            end
        end
    end
    msg_body = msg_body.."<hr><br/>"

    ScenEdit_SpecialMessage("playerside", msg_body)

    -- if we're running IKE as well, we need to flush the msg queue
    if Sandman_HasIKE() == true then
        if PBEM_FlushSpecialMessages then
            PBEM_FlushSpecialMessages()
        end
    end
end

function Sandman_ShowReservesSelected()
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    local guids = {}
    local u = ScenEdit_SelectedUnits()
    if u then
        for k, unit in ipairs(u.units) do
            table.insert(guids, unit.guid)
        end
    end
    if #guids > 0 then
        Sandman_ShowReservesAll(guids)
    else
        Input_OK("No bases selected!")
    end
end