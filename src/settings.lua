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

function Sandman_RefreshSettings()
    CRASH_INCIDENCE = GetNumber("SANDMAN_DEF_CRASH_INCID")
    PARKED_PERCENTAGE = GetNumber("SANDMAN_DEF_PARKED_PERC")
    READYING_PERCENTAGE = GetNumber("SANDMAN_DEF_READYING_PERC")
    MIN_HOURS_AWAKE = GetNumber("SANDMAN_DEF_MIN_HRS")
    MAX_HOURS_AWAKE = GetNumber("SANDMAN_DEF_MAX_HRS")

    RESERVE_REPLACE_THRESHOLD = GetArrayNumber("SANDMAN_DEF_RESERVE_THRESH")

    SANDMAN_DBID_TO_CLASS = GetDictionary("SANDMAN_DBID_CLASSNAME")
    SANDMAN_DBID_TO_CREW = GetDictionary("SANDMAN_DBID_CREWSIZE")

    -- build the cache of circadian values
    BuildCircadianCache()
end

function Sandman_UseDefaults()
    MIN_HOURS_AWAKE = DEFAULT_MIN_HOURS_AWAKE
    MAX_HOURS_AWAKE = DEFAULT_MAX_HOURS_AWAKE
    CRASH_INCIDENCE = DEFAULT_CRASH_INCIDENCE
    PARKED_PERCENTAGE = DEFAULT_PARKED_PERCENTAGE
    READYING_PERCENTAGE = DEFAULT_READYING_PERCENTAGE
    RESERVE_REPLACE_THRESHOLD = {}
    for i=1,#VP_GetSides() do
        RESERVE_REPLACE_THRESHOLD[i] = DEFAULT_RESERVE_REPLACE_THRESHOLD/100
    end

    StoreNumber("SANDMAN_DEF_CRASH_INCID", CRASH_INCIDENCE)
    StoreNumber("SANDMAN_DEF_PARKED_PERC", PARKED_PERCENTAGE)
    StoreNumber("SANDMAN_DEF_READYING_PERC", READYING_PERCENTAGE)
    StoreNumber("SANDMAN_DEF_MIN_HRS", MIN_HOURS_AWAKE)
    StoreNumber("SANDMAN_DEF_MAX_HRS", MAX_HOURS_AWAKE)
    StoreArrayNumber("SANDMAN_DEF_RESERVE_THRESH", RESERVE_REPLACE_THRESHOLD)
end

function Sandman_InputDefaults()
    Sandman_UseDefaults()

    MIN_HOURS_AWAKE = -1
    MAX_HOURS_AWAKE = -1
    CRASH_INCIDENCE = -1

    repeat
        MIN_HOURS_AWAKE = Input_Number_Default(
            "Enter the MINIMUM number of hours a pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MIN_HOURS_AWAKE,
            DEFAULT_MIN_HOURS_AWAKE
        )
    until MIN_HOURS_AWAKE >= 0

    repeat
        MAX_HOURS_AWAKE = Input_Number_Default(
            "Enter the MAXIMUM number of hours a pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MAX_HOURS_AWAKE, 
            DEFAULT_MAX_HOURS_AWAKE
        )
    until MAX_HOURS_AWAKE >= 0

    repeat
        CRASH_INCIDENCE = Input_Number_Default(
            "Enter the NORMAL number of crashes an airforce may experience in 100,000 flight hours.\n\nDEFAULT: "..DEFAULT_CRASH_INCIDENCE, 
            DEFAULT_CRASH_INCIDENCE
        )
    until CRASH_INCIDENCE >= 0
    CRASH_INCIDENCE = CRASH_INCIDENCE/100000

    StoreNumber("SANDMAN_DEF_CRASH_INCID", CRASH_INCIDENCE)
    StoreNumber("SANDMAN_DEF_MIN_HRS", MIN_HOURS_AWAKE)
    StoreNumber("SANDMAN_DEF_MAX_HRS", MAX_HOURS_AWAKE)
end