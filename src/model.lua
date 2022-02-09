-- SAFTE model: sleep 'reservoir' capacity is 2880 arbitrary units
SLEEP_RESERVOIR_CAPACITY = 2880
-- SAFTE MODEL: reservoir loses 0.5 units/min
SLEEP_UNITS_LOST_MIN = 0.5

UNIT_PROFICIENCIES = {
	"Novice",
	"Cadet",
	"Regular",
	"Veteran",
	"Ace"
}

UNIT_RESTSTATES = {
	"⇓", "", "⇑", "⇑⇑"
}
STATE_AWAKE = 1
STATE_REST_NONE = 2
STATE_REST_LIGHT = 3
STATE_REST_HEAVY = 4

function RestStateByCondition(condition_v, circadian)
	if condition_v == "Parked" then
		if circadian > -0.05 then
			return STATE_REST_LIGHT
		else
			return STATE_REST_HEAVY
		end
	elseif string.find(condition_v, "Readying") then
		if circadian > -0.05 then
			return STATE_REST_NONE
		else
			return STATE_REST_LIGHT
		end
	end
	return STATE_AWAKE
end

function ProfByEffectiveness(baseprof, effect)
	return tonumber(
		math.floor(
			(0.25+baseprof-1) * effect + 1
		)
	)
end

function ProfNumberByName(profname)
	for i, v in ipairs(UNIT_PROFICIENCIES) do
		if profname == v then
			return i
		end
	end
	return 1
end

function ProfNameByNumber(profnum)
	return UNIT_PROFICIENCIES[profnum]
end

function RandomSleepDeficit()
	local std_rnd = math.random()*math.random()
	local hrs = MIN_HOURS_AWAKE+std_rnd*(MAX_HOURS_AWAKE-MIN_HOURS_AWAKE)
	return SLEEP_UNITS_LOST_MIN*60*hrs
end

-- SAFTE model of effect of circadian rhythm
function CircadianTerm()
	local t = Sandman_GetLocalHour()
	return math.cos(2*math.pi*(t-18)/24) + 0.5*math.cos(4*math.pi*(t-21)/24)
end

-- SAFTE model effectiveness score
-- note: we are omitting the transient inertia term after waking
function EffectivenessScore(sleep_units, circadian)
	local ct = circadian * (
		0.07 + 0.05 * (SLEEP_RESERVOIR_CAPACITY - sleep_units) / SLEEP_RESERVOIR_CAPACITY
	)

	return math.max(
		0,
		math.min(
			1,
			sleep_units/SLEEP_RESERVOIR_CAPACITY + ct
		)
	)
end

-- SAFTE model for restorative sleep, based on time of day and sleep debt
function RestorativeSleep(interval, sleep_units, circadian)
	local timestep = interval / 60
	local si = timestep * -0.55*circadian
	return si + timestep * (SLEEP_RESERVOIR_CAPACITY - sleep_units) * 0.0026564
end

--[[
A speculative risk function given the following evidence from the literature...
* there is a direct polynomial relationship between sleep deprivation & crash risk
* effectiveness scores at 50% increase crash risk by 65 times
... and the following assumptions...
* landing at night on a stable platform is twice as risky
* landing at night on a stable ship is five times as risky
* landing at night on an unstable ship is 10-20 times as risky
]]--
function CrashRisk(interval, effect_score, base)
	local timestep = interval/3600
	local effect_perc = (1-effect_score)*100
	local risk_factor = 1 + effect_perc*effect_perc/39.0625
	local time = ScenEdit_GetTimeOfDay(
		{
			lat=base.latitude,
			lon=base.longitude
		}
	)
	if time.tod > 0 then
		if base.type == "Facility" then
			risk_factor = risk_factor * 2
		elseif base.type == "Ship" then
			risk_factor = risk_factor * 5
		end
	end
	if base.type == "Ship" then
		local weather = ScenEdit_GetWeather()
		risk_factor = risk_factor + risk_factor * (
			4 * (weather.seastate-9) / 9
		)
	end
	return math.min(0.95, risk_factor*CRASH_INCIDENCE*timestep)
end

--[[
This function is purely speculative, but based on the literature that indicates
that micronaps are extremely common in sleep-deprived flight crews.
ex: at 3 AM, an 80% effective pilot (up for 20+ hrs) has a 0.29%
chance of taking a micronap every minute
]]--
function MicroNapRisk(interval, effect_score, circadian)
	local base_risk = 1-effect_score
	local tod_risk = 1
	if circadian < 0 then
		tod_risk = tod_risk + -2*circadian
	else
        tod_risk = 1 / (1 + 2*(circadian/1.2999))
    end
	return interval*tod_risk*base_risk*base_risk*base_risk/600
end