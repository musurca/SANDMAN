function Sandman_Disable()
	-- disable SANDMAN
	StoreBoolean("SANDMAN_ENABLED", false)
	Sandman_Clear()
end

function Sandman_Enable()
	-- enable SANDMAN
	Sandman_Restore()
	StoreBoolean("SANDMAN_ENABLED", true)
end

function Sandman_IsEnabled()
	return GetBoolean("SANDMAN_ENABLED")
end

-- For scenario authors to set a unit's sleep deficit manually
function Sandman_SetRandomSleepDeficit(guid, min_hrs, max_hrs)
	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_sleepres = GetArrayNumber("UNIT_TRACKER_SLEEPRES")
	local unit_profs = GetArrayNumber("UNIT_TRACKER_BASE_PROFS")
	local unit_effect = GetArrayNumber("UNIT_TRACKER_EFFECT")

	for k, id in ipairs(tracked_guids) do
		if id == guid then
			local _, unit = pcall(
				ScenEdit_GetUnit,
				{
					guid=id
				}
			)
			if unit then
				local circadian = CircadianTerm()

				unit_sleepres[k] = SLEEP_RESERVOIR_CAPACITY - RandomSleepDeficit(min_hrs, max_hrs)
				unit_effect[k] = EffectivenessScore(unit_sleepres[k], circadian)
				local prof_name = ProfNameByNumber(
					ProfByEffectiveness(unit_profs[k], unit_effect[k])
				)
				if unit.proficiency ~= prof_name then
					ScenEdit_SetUnit({
						guid=id,
						proficiency=prof_name
					})
				end
				
				StoreArrayNumber("UNIT_TRACKER_SLEEPRES", unit_sleepres)
				StoreArrayNumber("UNIT_TRACKER_EFFECT", unit_effect)
				
				return true
			end
			break
		end
	end

	return false
end

-- For scenario authors to query unit effectiveness.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetEffectiveness(guid)
	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_effect = GetArrayNumber("UNIT_TRACKER_EFFECT")
	for k, id in ipairs(tracked_guids) do
		if id == guid then
			return unit_effect[k]
		end
	end
	return 1
end

-- For scenario authors to query unit crash risk per hour.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetCrashRisk(guid)
	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_effect = GetArrayNumber("UNIT_TRACKER_EFFECT")
	for k, id in ipairs(tracked_guids) do
		if id == guid then
			local _, u = pcall(
				ScenEdit_GetUnit,
				{
					guid=guid
				}
			)
			if u then
				if u.base then
					return CrashRisk(3600, unit_effect[k], u.base)
				else
					break
				end
			else
				break
			end
		end
	end
	return 0
end

-- For scenario authors to query unit micronap risk per hour.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetMicroNapRisk(guid)
	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_effect = GetArrayNumber("UNIT_TRACKER_EFFECT")
	for k, id in ipairs(tracked_guids) do
		if id == guid then
			local _, u = pcall(
				ScenEdit_GetUnit,
				{
					guid=guid
				}
			)
			if u then
				return MicroNapRisk(
					3600,
					unit_effect[k],
					CircadianTerm()
				)
			else
				break
			end
		end
	end
	return 0
end