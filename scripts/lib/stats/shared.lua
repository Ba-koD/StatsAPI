StatsAPI.stats = StatsAPI.stats or {}

local shared = StatsAPI.stats.shared or {}

local STAT_TYPE_ALIASES = {
    FireDelay = "FixedTears",
    TearDelay = "FixedTears",
    FixedFireDelay = "FixedTears",
    FixedTears = "FixedTears"
}

function shared.NormalizeStatType(statType)
    if type(statType) ~= "string" then
        return statType
    end
    return STAT_TYPE_ALIASES[statType] or statType
end

local DEFAULT_MOVE_SPEED_MAX = 2.0
shared.DEFAULT_MOVE_SPEED_MAX = DEFAULT_MOVE_SPEED_MAX
StatsAPI.stats.DEFAULT_SPEED_CAP = DEFAULT_MOVE_SPEED_MAX

if type(StatsAPI.stats._moveSpeedMax) ~= "number" then
    StatsAPI.stats._moveSpeedMax = DEFAULT_MOVE_SPEED_MAX
end

function shared.SetMoveSpeedMax(maxSpeed)
    if maxSpeed == nil then
        StatsAPI.stats._moveSpeedMax = DEFAULT_MOVE_SPEED_MAX
        return StatsAPI.stats._moveSpeedMax
    end

    if type(maxSpeed) ~= "number" or maxSpeed ~= maxSpeed or maxSpeed <= 0 then
        if StatsAPI and type(StatsAPI.printError) == "function" then
            StatsAPI.printError("SetMoveSpeedMax: maxSpeed must be a positive number")
        end
        return shared.GetMoveSpeedMax()
    end

    StatsAPI.stats._moveSpeedMax = maxSpeed
    return maxSpeed
end

function shared.GetMoveSpeedMax()
    local maxSpeed = StatsAPI.stats._moveSpeedMax
    if type(maxSpeed) ~= "number" or maxSpeed ~= maxSpeed or maxSpeed <= 0 then
        return DEFAULT_MOVE_SPEED_MAX
    end
    return maxSpeed
end

function shared.ResetMoveSpeedMax()
    StatsAPI.stats._moveSpeedMax = DEFAULT_MOVE_SPEED_MAX
    return StatsAPI.stats._moveSpeedMax
end

function shared.ClampMoveSpeed(value)
    if type(value) ~= "number" then
        return value
    end
    local maxSpeed = shared.GetMoveSpeedMax()
    if value > maxSpeed then
        return maxSpeed
    end
    return value
end

StatsAPI.stats.setSpeedCap = function(maxSpeed)
    return shared.SetMoveSpeedMax(maxSpeed)
end

StatsAPI.stats.getSpeedCap = function()
    return shared.GetMoveSpeedMax()
end

StatsAPI.stats.resetSpeedCap = function()
    return shared.ResetMoveSpeedMax()
end

local MIN_TEAR_RATE_SPS = 0.01
local MIN_FIRE_DELAY_DENOM = 0.001

function shared.SafeSPSFromFireDelay(maxFireDelay)
    local denom = (type(maxFireDelay) == "number" and maxFireDelay or 0) + 1
    if denom < MIN_FIRE_DELAY_DENOM then
        denom = MIN_FIRE_DELAY_DENOM
    end
    return 30 / denom
end

function shared.SafeFireDelayFromSPS(sps)
    local safeSPS = type(sps) == "number" and sps or MIN_TEAR_RATE_SPS
    if safeSPS < MIN_TEAR_RATE_SPS then
        safeSPS = MIN_TEAR_RATE_SPS
    end

    local maxFireDelay = (30 / safeSPS) - 1
    if (maxFireDelay + 1) < MIN_FIRE_DELAY_DENOM then
        maxFireDelay = MIN_FIRE_DELAY_DENOM - 1
    end

    return maxFireDelay, safeSPS
end

function shared.ClampFireDelay(maxFireDelay)
    if type(maxFireDelay) ~= "number" then
        return maxFireDelay
    end
    if (maxFireDelay + 1) < MIN_FIRE_DELAY_DENOM then
        return MIN_FIRE_DELAY_DENOM - 1
    end
    return maxFireDelay
end

StatsAPI.stats.shared = shared

return shared
