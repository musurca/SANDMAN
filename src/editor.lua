--[[
----------------------------------------------
SANDMAN
editor.lua
----------------------------------------------

Wrapper for CMO API functions pertaining to Events,
Triggers, Conditions, and Actions.

----------------------------------------------
]]--

function Side_Exists(side_name)
    for k, side in ipairs(VP_GetSides()) do
        if side.name == side_name then
            return true
        end
    end
    return false
end

function Event_Exists(evt_name)
    local events = ScenEdit_GetEvents()
    for i=1,#events do
        local event = events[i]
        if event.details.description == evt_name then
            return true
        end
    end

    return false
end

function Event_Delete(evt_name, recurse)
    recurse = recurse or false
    if recurse then
        -- delete nested actions, conditions, and triggers
        ForEachDo_Break(ScenEdit_GetEvents(), function(event)
            if event.details.description == evt_name then
                ForEachDo(event.details.triggers, function(e)
                    for key, val in pairs(e) do
                        if val.Description ~= nil then
                            Event_RemoveTrigger(evt_name, val.Description)
                            Trigger_Delete(val.Description)
                        end
                    end
                end)
                ForEachDo(event.details.conditions, function(e)
                    for key, val in pairs(e) do
                        if val.Description ~= nil then
                            Event_RemoveCondition(evt_name, val.Description)
                            Condition_Delete(val.Description)
                        end
                    end
                end)
                ForEachDo(event.details.actions, function(e)
                    for key, val in pairs(e) do
                        if val.Description ~= nil then
                            Event_RemoveAction(evt_name, val.Description)
                            Action_Delete(val.Description)
                        end
                    end
                end)

                return false
            end
            return true
        end)
    end

    -- remove the event
    pcall(ScenEdit_SetEvent, evt_name, {mode="remove"})
end

function Event_Create(evt_name, args)
    -- clear any existing events with that name
    ForEachDo(ScenEdit_GetEvents(), function(event)
        if event.details.description == evt_name then
            pcall(ScenEdit_SetEvent, evt_name, {
                mode="remove"
            })
        end
    end)

    -- add our event
    args.mode="add"
    pcall(
        ScenEdit_SetEvent,
        evt_name,
        args
    )
    return evt_name
end

function Event_AddTrigger(evt, trig)
    pcall(
        ScenEdit_SetEventTrigger,
        evt,
        {
            mode='add',
            name=trig
        }
    )
end

function Event_RemoveTrigger(evt, trig)
    pcall(
        ScenEdit_SetEventTrigger,
        evt,
        {
            mode='remove',
            name=trig
        }
    )
end

function Event_AddCondition(evt, cond)
    pcall(
        ScenEdit_SetEventCondition,
        evt,
        {
            mode='add',
            name=cond
        }
    )
end

function Event_RemoveCondition(evt, cond)
    pcall(
        ScenEdit_SetEventCondition,
        evt,
        {
            mode='remove', name=cond
        }
    )
end

function Event_AddAction(evt, action)
    pcall(
        ScenEdit_SetEventAction,
        evt, 
        {
            mode='add', 
            name=action
        }
    )
end

function Event_RemoveAction(evt, action)
    pcall(
        ScenEdit_SetEventAction,
        evt,
        {
            mode='remove',
            name=action
        }
    )
end

function Trigger_Create(trig_name, args)
    args.name=trig_name
    args.mode="add"
    pcall(ScenEdit_SetTrigger, args)
    return trig_name
end

function Trigger_Delete(trig_name)
    pcall(
        ScenEdit_SetTrigger,
        {
            name=trig_name,
            mode="remove"
        }
    )
end

function Condition_Create(cond_name, args)
    args.name=cond_name
    args.mode="add"
    pcall(ScenEdit_SetCondition, args)
    return cond_name
end

function Condition_Delete(cond_name)
    pcall(
        ScenEdit_SetCondition,
        {
            name=cond_name,
            mode="remove"
        }
    )
end

function Action_Create(action_name, args)
    args.name=action_name
    args.mode="add"
    pcall(ScenEdit_SetAction, args)
    return action_name
end

function Action_Delete(action_name)
    pcall(
        ScenEdit_SetAction,
        {
            name=action_name,
            mode="remove"
        }
    )
end

function SpecialAction_Create(action_name, action_desc, side, script)
    local success = pcall(
        ScenEdit_AddSpecialAction,
        {
            ActionNameOrID=action_name,
            Description=action_desc,
            Side=side,
            IsActive=true,
            IsRepeatable=true,
            ScriptText=script
        }
    )
    if success == true then
        return action_name
    end
    return ""
end

function SpecialAction_Delete(action_name, side)
    pcall(
        ScenEdit_SetSpecialAction,
        {
            ActionNameOrID=action_name,
            Side=side,
            mode="remove"
        }
    )
end