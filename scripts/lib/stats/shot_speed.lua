StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.shotSpeed = StatsAPI.stats.shotSpeed or {}

function StatsAPI.stats.shotSpeed.applyMultiplier(player, multiplier, minShotSpeed, showDisplay)
    if not player then return end
    local newShotSpeed = player.ShotSpeed * multiplier
    if minShotSpeed then newShotSpeed = math.max(minShotSpeed, newShotSpeed) end
    player.ShotSpeed = newShotSpeed
    return newShotSpeed
end

function StatsAPI.stats.shotSpeed.applyMultiplierScaled(player, multiplier, minShotSpeed, showDisplay)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledMultiplier = multiplier * vanillaMultiplier
    local newShotSpeed = player.ShotSpeed * scaledMultiplier
    if minShotSpeed then newShotSpeed = math.max(minShotSpeed, newShotSpeed) end
    player.ShotSpeed = newShotSpeed
    StatsAPI.printDebug(string.format("[ShotSpeed] MultiplierScaled: %.2fx * %.2fx = %.2fx -> Total: %.2f",
        multiplier, vanillaMultiplier, scaledMultiplier, newShotSpeed))
    return newShotSpeed, scaledMultiplier
end

function StatsAPI.stats.shotSpeed.applyAddition(player, addition, minShotSpeed)
    if not player then return end
    local newShotSpeed = player.ShotSpeed + addition
    if minShotSpeed then newShotSpeed = math.max(minShotSpeed, newShotSpeed) end
    player.ShotSpeed = newShotSpeed
    return newShotSpeed
end

function StatsAPI.stats.shotSpeed.applyAdditionScaled(player, addition, minShotSpeed)
    if not player then return end
    local vanillaMultiplier = 1.0
    local scaledAddition = addition * vanillaMultiplier
    local newShotSpeed = player.ShotSpeed + scaledAddition
    if minShotSpeed then newShotSpeed = math.max(minShotSpeed, newShotSpeed) end
    player.ShotSpeed = newShotSpeed
    StatsAPI.printDebug(string.format("[ShotSpeed] AdditionScaled: %.2f * %.2fx = %.2f -> Total: %.2f",
        addition, vanillaMultiplier, scaledAddition, newShotSpeed))
    return newShotSpeed, scaledAddition
end

return StatsAPI.stats.shotSpeed
