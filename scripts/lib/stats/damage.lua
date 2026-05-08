StatsAPI.stats = StatsAPI.stats or {}
StatsAPI.stats.damage = StatsAPI.stats.damage or {}

function StatsAPI.stats.damage.applyMultiplier(player, multiplier, minDamage, showDisplay)
    if not player then
        StatsAPI.printError("Player not found in StatsAPI.stats.damage.applyMultiplier")
        return
    end

    local baseDamage = player.Damage
    local newDamage = baseDamage * multiplier

    if minDamage then
        newDamage = math.max(minDamage, newDamage)
    end

    player.Damage = newDamage
    StatsAPI.stats.damage.applyPoisonDamageMultiplier(player, multiplier)
    return newDamage
end

function StatsAPI.stats.damage.applyMultiplierScaled(player, multiplier, minDamage, showDisplay)
    if not player then
        StatsAPI.printError("Player not found in StatsAPI.stats.damage.applyMultiplierScaled")
        return
    end

    local vanillaMultiplier = 1.0
    if StatsAPI.VanillaMultipliers and StatsAPI.VanillaMultipliers.GetPlayerDamageMultiplier then
        vanillaMultiplier = StatsAPI.VanillaMultipliers:GetPlayerDamageMultiplier(player)
    end

    local scaledMultiplier = multiplier * vanillaMultiplier
    local baseDamage = player.Damage
    local newDamage = baseDamage * scaledMultiplier

    if minDamage then
        newDamage = math.max(minDamage, newDamage)
    end

    player.Damage = newDamage
    StatsAPI.stats.damage.applyPoisonDamageMultiplier(player, scaledMultiplier)

    StatsAPI.printDebug(string.format("[Damage] MultiplierScaled: %.2fx * %.2fx (vanilla) = %.2fx -> Total: %.2f",
        multiplier, vanillaMultiplier, scaledMultiplier, newDamage))

    return newDamage, scaledMultiplier
end

function StatsAPI.stats.damage.applyAddition(player, addition, minDamage)
    if not player then return end

    local baseDamage = player.Damage
    local newDamage = baseDamage + addition

    if minDamage then
        newDamage = math.max(minDamage, newDamage)
    end

    player.Damage = newDamage
    StatsAPI.stats.damage.applyPoisonDamageAddition(player, addition)
    return newDamage
end

function StatsAPI.stats.damage.applyAdditionScaled(player, addition, minDamage)
    if not player then return end

    local vanillaMultiplier = 1.0
    if StatsAPI.VanillaMultipliers and StatsAPI.VanillaMultipliers.GetPlayerDamageMultiplier then
        vanillaMultiplier = StatsAPI.VanillaMultipliers:GetPlayerDamageMultiplier(player)
    end

    local scaledAddition = addition * vanillaMultiplier
    local baseDamage = player.Damage
    local newDamage = baseDamage + scaledAddition

    if minDamage then
        newDamage = math.max(minDamage, newDamage)
    end

    player.Damage = newDamage
    StatsAPI.stats.damage.applyPoisonDamageAddition(player, scaledAddition)

    StatsAPI.printDebug(string.format("[Damage] AdditionScaled: %.2f * %.2fx (vanilla) = %.2f -> Total: %.2f",
        addition, vanillaMultiplier, scaledAddition, newDamage))

    return newDamage, scaledAddition
end

function StatsAPI.stats.damage.applyPoisonDamageMultiplier(player, multiplier)
    if not player then return end
    if not StatsAPI.stats.damage.supportsTearPoisonAPI(player) then return end

    local pdata = player:GetData()
    if not pdata.statutils_tpd_base then
        pdata.statutils_tpd_base = player:GetTearPoisonDamage()
    end
    if multiplier == 1.0 then
        pdata.statutils_tpd_base = player:GetTearPoisonDamage()
    end

    local basePoisonDamage = pdata.statutils_tpd_base or 0
    local newPoisonDamage = basePoisonDamage * multiplier
    player:SetTearPoisonDamage(newPoisonDamage)
    pdata.statutils_tpd_lastMult = multiplier
    return newPoisonDamage
end

function StatsAPI.stats.damage.applyPoisonDamageAddition(player, addition)
    if not player then return end
    if not StatsAPI.stats.damage.supportsTearPoisonAPI(player) then return end

    local pdata = player:GetData()
    if not pdata.statutils_tpd_base then
        pdata.statutils_tpd_base = player:GetTearPoisonDamage()
    end

    local basePoisonDamage = pdata.statutils_tpd_base or 0
    local newPoisonDamage = basePoisonDamage + addition
    player:SetTearPoisonDamage(newPoisonDamage)
    return newPoisonDamage
end

function StatsAPI.stats.damage.applyPoisonDamageCombined(player, multiplier, addition)
    if not player then return end
    if not StatsAPI.stats.damage.supportsTearPoisonAPI(player) then return end

    local pdata = player:GetData()
    if not pdata.statutils_tpd_base then
        pdata.statutils_tpd_base = player:GetTearPoisonDamage()
    end

    local basePoisonDamage = pdata.statutils_tpd_base or 0
    local add = type(addition) == "number" and addition or 0
    local mult = type(multiplier) == "number" and multiplier or 1.0
    local newPoisonDamage = (basePoisonDamage + add) * mult

    player:SetTearPoisonDamage(newPoisonDamage)
    pdata.statutils_tpd_lastMult = mult
    pdata.statutils_tpd_lastAdd = add
    return newPoisonDamage
end

function StatsAPI.stats.damage.supportsTearPoisonAPI(player)
    return player and type(player.GetTearPoisonDamage) == "function" and type(player.SetTearPoisonDamage) == "function"
end

return StatsAPI.stats.damage
