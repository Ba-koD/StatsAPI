StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.range = StatsAPI.stats.range or {}

function StatsAPI.stats.range.applyMultiplier(player, multiplier, minRange, showDisplay)
    if not player then return end
    local newRange = player.TearRange * multiplier
    if minRange then newRange = math.max(minRange, newRange) end
    player.TearRange = newRange
    return newRange
end

function StatsAPI.stats.range.applyMultiplierScaled(player, multiplier, minRange, showDisplay)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledMultiplier = multiplier * vanillaMultiplier
    local newRange = player.TearRange * scaledMultiplier
    if minRange then newRange = math.max(minRange, newRange) end
    player.TearRange = newRange
    StatsAPI.printDebug(string.format("[Range] MultiplierScaled: %.2fx * %.2fx = %.2fx -> Total: %.2f",
        multiplier, vanillaMultiplier, scaledMultiplier, newRange))
    return newRange, scaledMultiplier
end

function StatsAPI.stats.range.applyAddition(player, addition, minRange)
    if not player then return end
    local newRange = player.TearRange + addition
    if minRange then newRange = math.max(minRange, newRange) end
    player.TearRange = newRange
    return newRange
end

function StatsAPI.stats.range.applyAdditionScaled(player, addition, minRange)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledAddition = addition * vanillaMultiplier
    local newRange = player.TearRange + scaledAddition
    if minRange then newRange = math.max(minRange, newRange) end
    player.TearRange = newRange
    StatsAPI.printDebug(string.format("[Range] AdditionScaled: %.2f * %.2fx = %.2f -> Total: %.2f",
        addition, vanillaMultiplier, scaledAddition, newRange))
    return newRange, scaledAddition
end

return StatsAPI.stats.range
