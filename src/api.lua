function Sandman_Disable()
	-- disable SANDMAN
	StoreBoolean("SANDMAN_ENABLED", false)
end

function Sandman_Enable()
	-- enable SANDMAN
	StoreBoolean("SANDMAN_ENABLED", true)
end

function Sandman_IsEnabled()
	return GetBoolean("SANDMAN_ENABLED")
end

-- For scenario authors to set unit's sleep deficit manually
function Sandman_SetRandomSleepDeficit(guid, min_hrs, max_hrs)
	-- initialize the unit tracker if it hasn't already been
	Sandman_CheckInit()

	local tracked_guids = GetArrayString("UNIT_TRACKER_GUIDS")
	local unit_sleepres = GetArrayNumber("UNIT_TRACKER_SLEEPRES")
	for k, id in ipairs(tracked_guids) do
		if id == guid then
			unit_sleepres[k] = SLEEP_RESERVOIR_CAPACITY - RandomSleepDeficit(min_hrs, max_hrs)
			break
		end
	end

	StoreArrayNumber("UNIT_TRACKER_SLEEPRES", unit_sleepres)
end

-- For scenario authors to query unit effectiveness.
-- Returns as fraction [0-1] representing percentage
function Sandman_GetEffectiveness(guid)
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