-- StatsAPI - Standalone Stat Multiplier Library
-- Provides unified multiplier management, HUD display, and stat application functions
-- Can be used by any Isaac mod via the global 'StatsAPI' table
local function loadCoreWithInclude()
    if type(include) ~= "function" then
        return false, "include() unavailable"
    end

    local ok = pcall(include, "scripts.statsapi_core")
    if ok then
        return true, nil
    end

    ok = pcall(include, "scripts/statsapi_core")
    if ok then
        return true, nil
    end

    return false, "include() failed for scripts.statsapi_core and scripts/statsapi_core"
end

local function loadCoreWithRequire()
    local loadedTable = package and package.loaded
    if type(loadedTable) == "table" then
        loadedTable["scripts/statsapi_core"] = nil
        loadedTable["scripts.statsapi_core"] = nil
    end

    local ok, err = pcall(require, "scripts/statsapi_core")
    if ok then
        return true, nil
    end

    ok, err = pcall(require, "scripts.statsapi_core")
    if ok then
        return true, nil
    end

    return false, err
end

local loaded, err = loadCoreWithInclude()
if not loaded then
    loaded, err = loadCoreWithRequire()
end

if not loaded then
    Isaac.DebugString("[StatsAPI][ERROR] Failed to load core module: " .. tostring(err))
end
