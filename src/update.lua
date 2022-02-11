-- interval in seconds
function Sandman_Update(interval)
	-- quit if disabled
	if Sandman_IsEnabled() == false then
		return
	end

	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_profs = GetArrayNumber("UNIT_TRACKER_BASE_PROFS")
	local unit_sleepres = GetArrayNumber("UNIT_TRACKER_SLEEPRES")
	local unit_effect = GetArrayNumber("UNIT_TRACKER_EFFECT")
	local unit_reststate = GetArrayNumber("UNIT_TRACKER_RESTSTATE")
	local unit_boltered = GetArrayNumber("UNIT_TRACKER_BOLTER")
	local unit_micronapping = GetArrayNumber("UNIT_TRACKER_MICRONAP")

	local circadian = CircadianTerm()

	for k, id in ipairs(tracked_guids) do
		local _, unit = pcall(
			ScenEdit_GetUnit,
			{
				guid=id
			}
		)

		if unit then
			-- only update units not under maintenance
			if unit.loadoutdbid ~= 4 then
				local interval_resting = 0
				local sleep_units = unit_sleepres[k]
				if unit.condition_v == "Parked" then
					-- most effective rest
					interval_resting = interval*PARKED_PERCENTAGE
				elseif string.find(unit.condition_v, "Readying") ~= nil then
					-- less effective rest
					interval_resting = interval*READYING_PERCENTAGE
				end
				-- otherwise we're totally awake
				local interval_active = interval - interval_resting
				local units_gained = 0
				if interval_resting > 0 then
					units_gained = RestorativeSleep(
						interval_resting,
						sleep_units,
						circadian
					)
				end
				local units_lost = SLEEP_UNITS_LOST_MIN*interval_active/60
				sleep_units = sleep_units + units_gained - units_lost
				sleep_units = math.min(
					SLEEP_RESERVOIR_CAPACITY,
					math.max(
						0,
						sleep_units
					)
				)
				unit_sleepres[k] = sleep_units
				unit_reststate[k] = RestStateByCondition(unit.condition_v, circadian)

				-- set effectiveness by hours awake
				local base_prof = unit_profs[k]
				local cur_effect = EffectivenessScore(sleep_units, circadian)
				unit_effect[k] = cur_effect

				-- set proficiency by effectiveness
				local new_prof = ProfByEffectiveness(base_prof, cur_effect)
				local new_prof_name = ProfNameByNumber(new_prof)
				if unit.proficiency ~= new_prof_name then
					pcall(
						ScenEdit_SetUnit,
						{
							guid=unit.guid,
							proficiency=new_prof_name
						}
					)
				end

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

				-- check if we've been caught nappin'
				if unit.airbornetime_v > 0 then
					local dice_roll = math.random()
					local nap_risk = MicroNapRisk(interval, cur_effect, circadian)
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
				else
					if unit_micronapping[k] == 1 then
						--nap stops
						unit_set_nap(unit, false)
						unit_micronapping[k] = 0
					end
				end

				-- if unit previously boltered, turn it around
				if unit_boltered[k] == 1 then
					unit:RTB(true)
					unit_boltered[k] = 0
				end

				-- Small risk of aircraft crashing on landing
				if unit.condition == "On final approach" or unit.condition == "In landing queue" then
					if unit.base then
						local crash_risk = CrashRisk(interval, cur_effect, unit.base)
						local dice_roll = math.random()
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
							if dice_roll*100 <= crash_risk then
								unit:RTB(false)
								unit_boltered[k] = 1
							end
						end
					end
				end
			end
		end
	end

	StoreArrayNumber("UNIT_TRACKER_SLEEPRES", unit_sleepres)
	StoreArrayNumber("UNIT_TRACKER_EFFECT", unit_effect)
	StoreArrayNumber("UNIT_TRACKER_RESTSTATE", unit_reststate)
	StoreArrayNumber("UNIT_TRACKER_BOLTER", unit_boltered)
	StoreArrayNumber("UNIT_TRACKER_MICRONAP", unit_micronapping)
end