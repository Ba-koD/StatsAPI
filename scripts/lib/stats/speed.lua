StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.speed = StatsAPI.stats.speed or {}

local shared = StatsAPI.stats.shared or {}

local function _speedCapArg(first, second)
    if type(first) == "table" and second ~= nil then
        return second
    end
    return first
end

StatsAPI.stats.speed.setCap = function(first, second)
    local setter = shared.SetMoveSpeedMax or StatsAPI.stats.setSpeedCap
    if type(setter) ~= "function" then return nil end
    return setter(_speedCapArg(first, second))
end

StatsAPI.stats.speed.getCap = function()
    local getter = shared.GetMoveSpeedMax or StatsAPI.stats.getSpeedCap
    if type(getter) ~= "function" then return 2.0 end
    return getter()
end

StatsAPI.stats.speed.resetCap = function()
    local resetter = shared.ResetMoveSpeedMax or StatsAPI.stats.resetSpeedCap
    if type(resetter) ~= "function" then return 2.0 end
    return resetter()
end

local ClampMoveSpeed = shared.ClampMoveSpeed or function(value)
    if type(value) == "number" and value > 2.0 then return 2.0 end
    return value
end

function StatsAPI.stats.speed.applyMultiplier(player, multiplier, minSpeed, showDisplay)
    if not player then return end
    local newSpeed = ClampMoveSpeed(player.MoveSpeed * multiplier)
    player.MoveSpeed = newSpeed
    return newSpeed
end

function StatsAPI.stats.speed.applyMultiplierScaled(player, multiplier, minSpeed, showDisplay)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledMultiplier = multiplier * vanillaMultiplier
    local newSpeed = ClampMoveSpeed(player.MoveSpeed * scaledMultiplier)
    player.MoveSpeed = newSpeed
    StatsAPI.printDebug(string.format("[Speed] MultiplierScaled: %.2fx * %.2fx = %.2fx -> Total: %.2f",
        multiplier, vanillaMultiplier, scaledMultiplier, newSpeed))
    return newSpeed, scaledMultiplier
end

function StatsAPI.stats.speed.applyAddition(player, addition, minSpeed)
    if not player then return end
    local newSpeed = ClampMoveSpeed(player.MoveSpeed + addition)
    player.MoveSpeed = newSpeed
    return newSpeed
end

function StatsAPI.stats.speed.applyAdditionScaled(player, addition, minSpeed)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledAddition = addition * vanillaMultiplier
    local newSpeed = ClampMoveSpeed(player.MoveSpeed + scaledAddition)
    player.MoveSpeed = newSpeed
    StatsAPI.printDebug(string.format("[Speed] AdditionScaled: %.2f * %.2fx = %.2f -> Total: %.2f",
        addition, vanillaMultiplier, scaledAddition, newSpeed))
    return newSpeed, scaledAddition
end

return StatsAPI.stats.speed
