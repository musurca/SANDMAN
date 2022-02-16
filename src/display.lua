function Sandman_Display(selected_guids)
    -- initialize the unit tracker if it hasn't already been
    Sandman_CheckInit()

    -- formatting for our old-skool HTML tables
    local table_names = { "UNIT DESIGNATION", "SKILL", "EFFECTIVENESS" }
    local table_header = "<table cellSpacing=1 cols="..#table_names.." cellPadding=1 width=\"95%\" border=2><tbody>"
    table_header = table_header.."<tr>"
    for k, tname in ipairs(table_names) do
        table_header = table_header.."<td><b>"..tname.."</b></td>"
    end
    table_header = table_header.."</tr>"
    local table_footer = "</tbody></table>"
    local msg_body = ""

    local unit_state = Sandman_GetUnitState()

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
            if unit.side == pside and unit.loadoutdbid ~= 4 then
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
                        add_column(
                            unit.name
                        )
                        add_column(
                            ProfNameByNumber(unit_state.baseprofs[k])
                        )
                        local rest_arrow = UNIT_RESTSTATES[
                            unit_state.reststates[k]
                        ]
                        local unit_effect = unit_state.effects[k]
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
            table.insert(guids, unit.guid)
        end
    end
    if #guids > 0 then
        Sandman_Display(guids)
    else
        Input_OK("No units selected!")
    end
end