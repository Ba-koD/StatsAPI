StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.tears = StatsAPI.stats.tears or {}

local shared = StatsAPI.stats.shared or {}
local _safeSPSFromFireDelay = shared.SafeSPSFromFireDelay or function(maxFireDelay)
    local denom = (type(maxFireDelay) == "number" and maxFireDelay or 0) + 1
    if denom < 0.001 then denom = 0.001 end
    return 30 / denom
end
local _safeFireDelayFromSPS = shared.SafeFireDelayFromSPS or function(sps)
    local safeSPS = type(sps) == "number" and sps or 0.01
    if safeSPS < 0.01 then safeSPS = 0.01 end
    return (30 / safeSPS) - 1, safeSPS
end

function StatsAPI.stats.tears.calculateMaxFireDelay(baseFireDelay, multiplier, minFireDelay)
    if not baseFireDelay or not multiplier then return baseFireDelay end
    local baseSPS = _safeSPSFromFireDelay(baseFireDelay)
    local targetSPS = baseSPS * multiplier
    local newMaxFireDelay = _safeFireDelayFromSPS(targetSPS)
    return newMaxFireDelay
end

function StatsAPI.stats.tears.applyMultiplier(player, multiplier, minFireDelay, showDisplay)
    if not player then return end
    local baseFireDelay = player.MaxFireDelay
    local baseSPS = _safeSPSFromFireDelay(baseFireDelay)
    local newFireDelay = StatsAPI.stats.tears.calculateMaxFireDelay(baseFireDelay, multiplier, nil)
    local newSPS = _safeSPSFromFireDelay(newFireDelay)
    StatsAPI.printDebug(string.format("[Tears] Multiplier apply: baseFD=%.4f baseSPS=%.4f mult=%.4f -> newFD=%.4f newSPS=%.4f",
        baseFireDelay, baseSPS, multiplier, newFireDelay, newSPS))
    player.MaxFireDelay = newFireDelay
    return newFireDelay
end

function StatsAPI.stats.tears.applyMultiplierScaled(player, multiplier, minFireDelay, showDisplay)
    if not player then return end
    local vanillaMultiplier = 1.0
    if StatsAPI.VanillaMultipliers and StatsAPI.VanillaMultipliers.GetPlayerFireRateMultiplier then
        vanillaMultiplier = StatsAPI.VanillaMultipliers:GetPlayerFireRateMultiplier(player)
    end
    local scaledMultiplier = multiplier * vanillaMultiplier
    local baseFireDelay = player.MaxFireDelay
    local baseSPS = _safeSPSFromFireDelay(baseFireDelay)
    local newFireDelay = StatsAPI.stats.tears.calculateMaxFireDelay(baseFireDelay, scaledMultiplier, nil)
    local newSPS = _safeSPSFromFireDelay(newFireDelay)
    StatsAPI.printDebug(string.format("[Tears] MultiplierScaled: baseFD=%.4f baseSPS=%.4f mult=%.4f * %.2fx = %.4f -> newFD=%.4f newSPS=%.4f",
        baseFireDelay, baseSPS, multiplier, vanillaMultiplier, scaledMultiplier, newFireDelay, newSPS))
    player.MaxFireDelay = newFireDelay
    return newFireDelay, scaledMultiplier
end

function StatsAPI.stats.tears.applyAddition(player, addition, minFireDelay)
    if not player then return end
    local baseFireDelay = player.MaxFireDelay
    local baseSPS = _safeSPSFromFireDelay(baseFireDelay)
    local targetSPS = baseSPS + addition
    local newMaxFireDelay = _safeFireDelayFromSPS(targetSPS)
    local newSPS = _safeSPSFromFireDelay(newMaxFireDelay)
    StatsAPI.printDebug(string.format("[Tears] Addition apply: baseFD=%.4f baseSPS=%.4f addSPS=%+.4f -> newFD=%.4f newSPS=%.4f",
        baseFireDelay, baseSPS, addition, newMaxFireDelay, newSPS))
    player.MaxFireDelay = newMaxFireDelay
    return newMaxFireDelay
end

function StatsAPI.stats.tears.applyAdditionScaled(player, addition, minFireDelay)
    if not player then return end
    local vanillaMultiplier = 1.0
    if StatsAPI.VanillaMultipliers and StatsAPI.VanillaMultipliers.GetPlayerFireRateMultiplier then
        vanillaMultiplier = StatsAPI.VanillaMultipliers:GetPlayerFireRateMultiplier(player)
    end
    local scaledAddition = addition * vanillaMultiplier
    local baseFireDelay = player.MaxFireDelay
    local baseSPS = _safeSPSFromFireDelay(baseFireDelay)
    local targetSPS = baseSPS + scaledAddition
    local newMaxFireDelay = _safeFireDelayFromSPS(targetSPS)
    local newSPS = _safeSPSFromFireDelay(newMaxFireDelay)
    StatsAPI.printDebug(string.format("[Tears] AdditionScaled: baseFD=%.4f baseSPS=%.4f addSPS=%+.4f * %.2fx = %+.4f -> newFD=%.4f newSPS=%.4f",
        baseFireDelay, baseSPS, addition, vanillaMultiplier, scaledAddition, newMaxFireDelay, newSPS))
    player.MaxFireDelay = newMaxFireDelay
    return newMaxFireDelay, scaledAddition
end

return StatsAPI.stats.tears
