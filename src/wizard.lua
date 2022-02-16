SANDMAN_VERSION = "0.2.0"

function Sandman_Wizard()
    -- remove previous versions of SANDMAN
    if Event_Exists("SANDMAN: Scenario Loaded") then
        Event_Delete("SANDMAN: Scenario Loaded", true)

        Sandman_RemoveSpecialActions()
    end
    if Event_Exists("SANDMAN: Update Tick") then
        Event_Delete("SANDMAN: Update Tick", true)
    end
    Sandman_Clear()

    -- initialize SANDMAN on load by injecting its own code into the VM
    local loadEvent = Event_Create(
        "SANDMAN: Scenario Loaded",
        {
            IsRepeatable=true,
            IsShown=false
        }
    )
    Event_AddTrigger(
        loadEvent,
        Trigger_Create(
            "PBEM_Scenario_Loaded",
            {
                type="ScenLoaded"
            }
        )
    )
    Event_AddAction(
        loadEvent,
        Action_Create(
            "SANDMAN: Load Library",
            {
                type="LuaScript",
                ScriptText=SANDMAN_LOADER
            }
        )
    )

    -- update tick every minute
    local updateEvent = Event_Create(
        "SANDMAN: Update Tick",
        {
            IsRepeatable=true,
            IsShown=false
        }
    )
    Event_AddTrigger(
        updateEvent,
        Trigger_Create(
            "SANDMAN_Update_Tick",
            {
                type="RegularTime",
                interval=4 --Every Minute
            }
        )
    )
    Event_AddAction(
        updateEvent,
        Action_Create(
            "SANDMAN: Next Update",
            {
                type="LuaScript",
                ScriptText="Sandman_Update(60)"
               }
        )
    )

    -- add special actions for the scheduling tool
    Sandman_AddSpecialActions()

    -- set values for model
    local result = Input_YesNo("Thanks for using SANDMAN v"..SANDMAN_VERSION..", the fatigue modeling system for CMO.\n\nDo you want to use the suggested values for the fatigue model?")
    if result == true then
        Sandman_UseDefaults()
    else
        Sandman_InputDefaults()
    end

    -- reset unit tracker
    StoreBoolean("UNIT_TRACKER_INITIALIZED", false)

    -- enable SANDMAN
    Sandman_Enable()
    
    Input_OK("SANDMAN v"..SANDMAN_VERSION.." has been installed into this scenario!")
end