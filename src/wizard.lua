SANDMAN_VERSION = "0.2.2"

function Sandman_Wizard()
    local result = Input_YesNo("Thanks for using SANDMAN v"..SANDMAN_VERSION..", the fatigue modeling system for CMO.\n\nHave you saved a backup of this scenario?")
    if result == false then
        Input_OK("Please save a backup first, then run this script again.")
        return
    end

    -- remove previous versions of SANDMAN
    if Event_Exists("SANDMAN: Scenario Loaded") then
        Event_Delete("SANDMAN: Scenario Loaded", true)

        Sandman_RemoveSpecialActions()
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
            "SANDMAN_Scenario_Loaded",
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

    -- set values for model
    Sandman_InputSides()

    -- reset unit tracker
    StoreBoolean("SANDMAN_INITIALIZED", false)

    -- enable SANDMAN
    Sandman_Enable()
    
    Input_OK("SANDMAN v"..SANDMAN_VERSION.." has been installed into this scenario!")
end

-- Refresh globals anew every time the scenario loads
Sandman_RefreshSettings()