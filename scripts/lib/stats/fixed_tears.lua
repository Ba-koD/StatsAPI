StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.fixedTears = StatsAPI.stats.fixedTears or {}

local shared = StatsAPI.stats.shared or {}
local _clampFireDelay = shared.ClampFireDelay or function(maxFireDelay)
    if type(maxFireDelay) ~= "number" then
        return maxFireDelay
    end
    if (maxFireDelay + 1) < 0.001 then
        return 0.001 - 1
    end
    return maxFireDelay
end

function StatsAPI.stats.fixedTears.applyMultiplier(player, multiplier, minFireDelay, showDisplay)
    if not player then return end

    local baseFireDelay = player.MaxFireDelay
    local newFireDelay = _clampFireDelay(baseFireDelay * multiplier)

    if minFireDelay then
        newFireDelay = math.max(minFireDelay, newFireDelay)
    end

    StatsAPI.printDebug(string.format("[FixedTears] Multiplier apply: baseFD=%.4f mult=%.4f -> newFD=%.4f",
        baseFireDelay, multiplier, newFireDelay))

    player.MaxFireDelay = newFireDelay

    return newFireDelay
end

function StatsAPI.stats.fixedTears.applyAddition(player, addition, minFireDelay)
    if not player then return end

    local baseFireDelay = player.MaxFireDelay
    local newFireDelay = _clampFireDelay(baseFireDelay + addition)

    if minFireDelay then
        newFireDelay = math.max(minFireDelay, newFireDelay)
    end

    StatsAPI.printDebug(string.format("[FixedTears] Addition apply: baseFD=%.4f addFD=%+.4f -> newFD=%.4f",
        baseFireDelay, addition, newFireDelay))

    player.MaxFireDelay = newFireDelay

    return newFireDelay
end

return StatsAPI.stats.fixedTears
