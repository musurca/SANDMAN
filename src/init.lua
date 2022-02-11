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

	local circadian = CircadianTerm()

	local unit_profs = {}
	local unit_sleepres = {}
	local unit_effect = {}
	local unit_reststate = {}
	local unit_boltered = {}
	local unit_micronapping = {}

	for k, v in ipairs(tracked_guids) do
		local ac = ScenEdit_GetUnit({guid=v})
		unit_sleepres[k] = SLEEP_RESERVOIR_CAPACITY - RandomSleepDeficit(MIN_HOURS_AWAKE, MAX_HOURS_AWAKE) - SLEEP_UNITS_LOST_MIN*ac.airbornetime_v/60
		unit_profs[k] = ProfNumberByName(ac.proficiency)
		unit_effect[k] = EffectivenessScore(unit_sleepres[k], circadian)
		unit_reststate[k] = RestStateByCondition(ac.condition_v, circadian)
		unit_boltered[k] = 0
		unit_micronapping[k] = 0

		-- set initial proficiency
		local prof_name = ProfNameByNumber(
			ProfByEffectiveness(unit_profs[k], unit_effect[k])
		)
		if ac.proficiency ~= prof_name then
			ScenEdit_SetUnit({
				guid=v,
				proficiency=prof_name
			})
		end
	end

	StoreArrayString("UNIT_TRACKER_GUIDS", tracked_guids)
	StoreArrayNumber("UNIT_TRACKER_BASE_PROFS", unit_profs)
	StoreArrayNumber("UNIT_TRACKER_SLEEPRES", unit_sleepres)
	StoreArrayNumber("UNIT_TRACKER_EFFECT", unit_effect)
	StoreArrayNumber("UNIT_TRACKER_RESTSTATE", unit_reststate)
	StoreArrayNumber("UNIT_TRACKER_BOLTER", unit_boltered)
	StoreArrayNumber("UNIT_TRACKER_MICRONAP", unit_micronapping)

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