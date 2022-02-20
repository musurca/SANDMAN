-- normal # of crashes per 100,000 hours of flight
DEFAULT_CRASH_INCIDENCE = 3.5

-- percentage of time spent resting while parked and idle
DEFAULT_PARKED_PERCENTAGE = 1/2

-- percentage of time spent resting while readying
DEFAULT_READYING_PERCENTAGE = 1/6

-- min/max hours awake for pilots at the start of the scenario
DEFAULT_MIN_HOURS_AWAKE = 6
DEFAULT_MAX_HOURS_AWAKE = 14

-- Effectiveness replacement threshold
DEFAULT_RESERVE_REPLACE_THRESHOLD = 80

function Sandman_Side_Enabled(sidename)
    return SANDMAN_SIDES_ENABLED[SideNumberByName(sidename)] == 1
end

function Sandman_Side_CrashIncidence(sidename)
    return SANDMAN_CRASH_INCIDENCE[SideNumberByName(sidename)]
end

function Sandman_Side_MinHoursAwake(sidename)
    return SANDMAN_MIN_HOURS_AWAKE[SideNumberByName(sidename)]
end

function Sandman_Side_MaxHoursAwake(sidename)
    return SANDMAN_MAX_HOURS_AWAKE[SideNumberByName(sidename)]
end

function Sandman_RefreshSettings()
    SANDMAN_SIDES_ENABLED = GetArrayNumber("SANDMAN_SIDE_ENABLED")
    SANDMAN_CRASH_INCIDENCE = GetArrayNumber("SANDMAN_SIDE_CRASHINCID")
    SANDMAN_MIN_HOURS_AWAKE = GetArrayNumber("SANDMAN_SIDE_MINHRS")
    SANDMAN_MAX_HOURS_AWAKE = GetArrayNumber("SANDMAN_SIDE_MAXHRS")
    PARKED_PERCENTAGE = GetNumber("SANDMAN_DEF_PARKED_PERC")
    READYING_PERCENTAGE = GetNumber("SANDMAN_DEF_READYING_PERC")

    RESERVE_REPLACE_THRESHOLD = GetArrayNumber("SANDMAN_DEF_RESERVE_THRESH")

    SANDMAN_DBID_TO_CLASS = GetDictionary("SANDMAN_DBID_CLASSNAME")
    SANDMAN_DBID_TO_CREW = GetDictionary("SANDMAN_DBID_CREWSIZE")

    -- build the cache of circadian values
    BuildCircadianCache()
end

function Sandman_SetDefaults()
    PARKED_PERCENTAGE = DEFAULT_PARKED_PERCENTAGE
    READYING_PERCENTAGE = DEFAULT_READYING_PERCENTAGE
    RESERVE_REPLACE_THRESHOLD = {}
    for i=1,#VP_GetSides() do
        RESERVE_REPLACE_THRESHOLD[i] = DEFAULT_RESERVE_REPLACE_THRESHOLD/100
    end

    StoreNumber("SANDMAN_DEF_PARKED_PERC", DEFAULT_PARKED_PERCENTAGE)
    StoreNumber("SANDMAN_DEF_READYING_PERC", DEFAULT_READYING_PERCENTAGE)
    StoreArrayNumber("SANDMAN_DEF_RESERVE_THRESH", RESERVE_REPLACE_THRESHOLD)
end

function Sandman_InputSides()
    Sandman_SetDefaults()

    local sides_enabled = {}
    local min_hrs = {}
    local max_hrs = {}
    local crash_incid = {}
    for k, side in ipairs(VP_GetSides()) do
        local use_side = Input_YesNo("Enable fatigue tracking for "..side.name.." side?")
        if use_side == true then
            sides_enabled[k] = 1

            local use_defaults = Input_YesNo("Use default model values for "..side.name.."?")
            if use_defaults == true then
                min_hrs[k] = DEFAULT_MIN_HOURS_AWAKE
                max_hrs[k] = DEFAULT_MAX_HOURS_AWAKE
                crash_incid[k] = DEFAULT_CRASH_INCIDENCE
            else
                local min_hrs_awake, max_hrs_awake, crash_rate
                repeat
                    min_hrs_awake = Input_Number_Default(
                        "Enter the MINIMUM number of hours a "..side.name.." pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MIN_HOURS_AWAKE,
                        DEFAULT_MIN_HOURS_AWAKE
                    )
                until min_hrs_awake >= 0
            
                repeat
                    max_hrs_awake = Input_Number_Default(
                        "Enter the MAXIMUM number of hours a "..side.name.." pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MAX_HOURS_AWAKE, 
                        DEFAULT_MAX_HOURS_AWAKE
                    )
                until max_hrs_awake >= 0
            
                repeat
                    crash_rate = Input_Number_Default(
                        "Enter the NORMAL number of crashes the "..side.name.." side may experience in 100,000 flight hours.\n\nDEFAULT: "..DEFAULT_CRASH_INCIDENCE, 
                        DEFAULT_CRASH_INCIDENCE
                    )
                until crash_rate >= 0
                crash_rate = crash_rate/100000

                min_hrs[k] = min_hrs_awake
                max_hrs[k] = max_hrs_awake
                crash_incid[k] = crash_rate
            end
        else
            sides_enabled[k] = 0
            min_hrs[k] = DEFAULT_MIN_HOURS_AWAKE
            max_hrs[k] = DEFAULT_MAX_HOURS_AWAKE
            crash_incid[k] = DEFAULT_CRASH_INCIDENCE
        end
    end

    StoreArrayNumber("SANDMAN_SIDE_ENABLED", sides_enabled)
    StoreArrayNumber("SANDMAN_SIDE_MINHRS", min_hrs)
    StoreArrayNumber("SANDMAN_SIDE_MAXHRS", max_hrs)
    StoreArrayNumber("SANDMAN_SIDE_CRASHINCID", crash_incid)

    Sandman_RefreshSettings()
end