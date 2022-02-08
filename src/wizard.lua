SANDMAN_VERSION = "0.1.0"

function Sandman_Wizard()
	-- remove previous versions of SANDMAN
	if Event_Exists("SANDMAN: Scenario Loaded") then
        Event_Delete("SANDMAN: Scenario Loaded", true)

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
	if Event_Exists("SANDMAN: Update Tick") then
		Event_Delete("SANDMAN: Update Tick", true)
	end

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

	if Input_YesNo("Thanks for using SANDMAN, the fatigue modeling system for CMO. Do you want to use the suggested values?") then
		Sandman_UseDefaults()
	else
		Sandman_InputDefaults()
	end

	Input_OK("SANDMAN v"..SANDMAN_VERSION.." has been installed into this scenario!")
end