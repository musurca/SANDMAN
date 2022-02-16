--[[
----------------------------------------------
SANDMAN
prng.lua
----------------------------------------------

Reimplementation of math.random() to control the seed.

----------------------------------------------
]]--

function XORSHIFT_32(state)
    local x = state
    x = bit_xor(x, bit_lshift(x, 13))
    x = bit_xor(x, bit_rshift(x, 17))
    x = bit_xor(x, bit_lshift(x, 5))
    return x
end

function Random(lower, upper)
    local seed = GetNumber("SANDMAN_RANDOM_SEED")
    if seed == 0 then
        seed = os.time() % 4294967296
    end
    local raw_state = XORSHIFT_32(seed)
    StoreNumber("SANDMAN_RANDOM_SEED", raw_state)
    local raw_rnd = raw_state / 4294967296

    local rval = 0
    if lower then
        if upper then
            rval = math.floor(1+lower+raw_rnd*(upper-lower))
        else
            rval = math.floor(1+raw_rnd*lower)
        end
    else
        rval = raw_rnd
    end

    return rval
end