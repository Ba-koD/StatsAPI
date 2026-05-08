StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.luck = StatsAPI.stats.luck or {}

function StatsAPI.stats.luck.applyMultiplier(player, multiplier, minLuck, showDisplay)
    if not player then return end
    local newLuck = player.Luck
    if player.Luck ~= 0 then
        newLuck = player.Luck * multiplier
        if minLuck then newLuck = math.max(minLuck, newLuck) end
    end
    player.Luck = newLuck
    return newLuck
end

function StatsAPI.stats.luck.applyMultiplierScaled(player, multiplier, minLuck, showDisplay)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledMultiplier = multiplier * vanillaMultiplier
    local newLuck = player.Luck
    if player.Luck ~= 0 then
        newLuck = player.Luck * scaledMultiplier
        if minLuck then newLuck = math.max(minLuck, newLuck) end
    end
    player.Luck = newLuck
    StatsAPI.printDebug(string.format("[Luck] MultiplierScaled: %.2fx * %.2fx = %.2fx -> Total: %.2f",
        multiplier, vanillaMultiplier, scaledMultiplier, newLuck))
    return newLuck, scaledMultiplier
end

function StatsAPI.stats.luck.applyAddition(player, addition, minLuck)
    if not player then return end
    local newLuck = player.Luck + addition
    if minLuck then newLuck = math.max(minLuck, newLuck) end
    player.Luck = newLuck
    return newLuck
end

function StatsAPI.stats.luck.applyAdditionScaled(player, addition, minLuck)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledAddition = addition * vanillaMultiplier
    local newLuck = player.Luck + scaledAddition
    if minLuck then newLuck = math.max(minLuck, newLuck) end
    player.Luck = newLuck
    StatsAPI.printDebug(string.format("[Luck] AdditionScaled: %.2f * %.2fx = %.2f -> Total: %.2f",
        addition, vanillaMultiplier, scaledAddition, newLuck))
    return newLuck, scaledAddition
end

return StatsAPI.stats.luck
