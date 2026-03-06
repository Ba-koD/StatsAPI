local M = {}
local OFFSET_MIN = -200
local OFFSET_MAX = 200

local function clampOffset(value)
    local num = tonumber(value) or 0
    if num >= 0 then
        num = math.floor(num + 0.5)
    else
        num = math.ceil(num - 0.5)
    end
    if num < OFFSET_MIN then
        num = OFFSET_MIN
    elseif num > OFFSET_MAX then
        num = OFFSET_MAX
    end
    return num
end

local function ensureSettingsTable()
    if not StatsAPI then
        return nil
    end
    if type(StatsAPI.settings) ~= "table" then
        StatsAPI.settings = {
            displayEnabled = true,
            displayOffsetX = 0,
            displayOffsetY = 0,
            trackVanillaDisplay = true,
            debugEnabled = false
        }
    elseif StatsAPI.settings.trackVanillaDisplay == nil then
        StatsAPI.settings.trackVanillaDisplay = true
    end
    if StatsAPI.settings.debugEnabled == nil then
        StatsAPI.settings.debugEnabled = false
    end
    return StatsAPI.settings
end

local function setDisplayOffset(axis, value)
    local settings = ensureSettingsTable()
    if not settings then
        return
    end

    local key = (axis == "y") and "displayOffsetY" or "displayOffsetX"
    local normalized = clampOffset(value)
    if settings[key] == normalized then
        return
    end

    settings[key] = normalized
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function resetDisplayDefaults()
    local settings = ensureSettingsTable()
    if not settings then
        return
    end

    local previousTrackVanilla = settings.trackVanillaDisplay
    local previousDebugEnabled = settings.debugEnabled == true
    settings.displayEnabled = true
    settings.displayOffsetX = 0
    settings.displayOffsetY = 0
    settings.trackVanillaDisplay = true
    settings.debugEnabled = false

    if previousTrackVanilla ~= true
        and StatsAPI
        and type(StatsAPI.SetVanillaDisplayTrackingEnabled) == "function" then
        StatsAPI:SetVanillaDisplayTrackingEnabled(true)
    end

    if previousDebugEnabled
        and StatsAPI
        and type(StatsAPI.SetDebugModeEnabled) == "function" then
        StatsAPI:SetDebugModeEnabled(false)
    elseif StatsAPI then
        StatsAPI.DEBUG = false
    end

    if StatsAPI and StatsAPI.stats and StatsAPI.stats.multiplierDisplay
        and type(StatsAPI.stats.multiplierDisplay.RefreshAllFromUnified) == "function" then
        StatsAPI.stats.multiplierDisplay:RefreshAllFromUnified()
    end

    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function hasMCM()
    return type(ModConfigMenu) == "table"
        and type(ModConfigMenu.AddSetting) == "function"
        and type(ModConfigMenu.OptionType) == "table"
        and ModConfigMenu.OptionType.BOOLEAN ~= nil
end

local function getDisplayEnabled()
    if StatsAPI and type(StatsAPI.IsDisplayEnabled) == "function" then
        return StatsAPI:IsDisplayEnabled()
    end
    return true
end

local function getTrackVanillaDisplay()
    if StatsAPI and type(StatsAPI.IsVanillaDisplayTrackingEnabled) == "function" then
        return StatsAPI:IsVanillaDisplayTrackingEnabled()
    end
    local settings = ensureSettingsTable()
    if settings then
        return settings.trackVanillaDisplay ~= false
    end
    return true
end

local function getDebugEnabled()
    if StatsAPI and type(StatsAPI.IsDebugModeEnabled) == "function" then
        return StatsAPI:IsDebugModeEnabled()
    end
    local settings = ensureSettingsTable()
    if settings then
        return settings.debugEnabled == true
    end
    return StatsAPI and StatsAPI.DEBUG == true or false
end

local function getDisplayOffsetX()
    local settings = ensureSettingsTable()
    if settings then
        return clampOffset(settings.displayOffsetX)
    end
    if StatsAPI and type(StatsAPI.GetDisplayOffsetX) == "function" then
        return clampOffset(StatsAPI:GetDisplayOffsetX())
    end
    return 0
end

local function getDisplayOffsetY()
    local settings = ensureSettingsTable()
    if settings then
        return clampOffset(settings.displayOffsetY)
    end
    if StatsAPI and type(StatsAPI.GetDisplayOffsetY) == "function" then
        return clampOffset(StatsAPI:GetDisplayOffsetY())
    end
    return 0
end

function M.Setup()
    if not hasMCM() then
        return false
    end

    local category = "StatsAPI"
    local subcategory = "Display"

    if type(ModConfigMenu.RemoveCategory) == "function" then
        pcall(ModConfigMenu.RemoveCategory, category)
    end

    if type(ModConfigMenu.AddSpace) == "function" then
        ModConfigMenu.AddSpace(category, subcategory)
    end
    if type(ModConfigMenu.AddText) == "function" then
        ModConfigMenu.AddText(category, subcategory, "--- HUD Display ---")
    end

    ModConfigMenu.AddSetting(category, subcategory, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return getDisplayEnabled()
        end,
        Display = function()
            local enabled = getDisplayEnabled()
            return "Multiplier HUD: " .. (enabled and "ON" or "OFF")
        end,
        Info = { "Toggle StatsAPI multiplier HUD rendering." },
        OnChange = function(value)
            if StatsAPI and StatsAPI.SetDisplayEnabled then
                StatsAPI:SetDisplayEnabled(value)
            end
        end
    })

    ModConfigMenu.AddSetting(category, subcategory, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return getTrackVanillaDisplay()
        end,
        Display = function()
            local enabled = getTrackVanillaDisplay()
            return "Track Vanilla Multiplier: " .. (enabled and "ON" or "OFF")
        end,
        Info = {
            "Include vanilla character/item multipliers in total display.",
            "Applies per-player (item holder character context)."
        },
        OnChange = function(value)
            local enabled = value ~= false
            if StatsAPI and type(StatsAPI.SetVanillaDisplayTrackingEnabled) == "function" then
                StatsAPI:SetVanillaDisplayTrackingEnabled(enabled)
                return
            end

            local settings = ensureSettingsTable()
            if not settings then
                return
            end
            settings.trackVanillaDisplay = enabled

            if StatsAPI and StatsAPI.stats and StatsAPI.stats.multiplierDisplay
                and type(StatsAPI.stats.multiplierDisplay.RefreshAllFromUnified) == "function" then
                StatsAPI.stats.multiplierDisplay:RefreshAllFromUnified()
            end

            if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
                StatsAPI:SaveRunData()
            end
        end
    })

    ModConfigMenu.AddSetting(category, subcategory, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return getDebugEnabled()
        end,
        Display = function()
            local enabled = getDebugEnabled()
            return "Debug Mode (Watcher Log): " .. (enabled and "ON" or "OFF")
        end,
        Info = {
            "Enable debug mode and show watcher runtime logs at bottom-left.",
            "Used by watch.sh runtime queue MSG/CMD notifications."
        },
        OnChange = function(value)
            local enabled = value == true
            if StatsAPI and type(StatsAPI.SetDebugModeEnabled) == "function" then
                StatsAPI:SetDebugModeEnabled(enabled)
                return
            end

            local settings = ensureSettingsTable()
            if not settings then
                return
            end
            settings.debugEnabled = enabled
            if StatsAPI then
                StatsAPI.DEBUG = enabled
            end
            if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
                StatsAPI:SaveRunData()
            end
        end
    })

    if ModConfigMenu.OptionType.NUMBER ~= nil then
        ModConfigMenu.AddSetting(category, subcategory, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return getDisplayOffsetX()
            end,
            Minimum = OFFSET_MIN,
            Maximum = OFFSET_MAX,
            Display = function()
                return string.format("HUD Offset X: %+d", getDisplayOffsetX())
            end,
            Info = {
                "Horizontal offset for StatsAPI HUD display.",
                "Positive moves right, negative moves left."
            },
            OnChange = function(value)
                setDisplayOffset("x", value)
            end
        })

        ModConfigMenu.AddSetting(category, subcategory, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return getDisplayOffsetY()
            end,
            Minimum = OFFSET_MIN,
            Maximum = OFFSET_MAX,
            Display = function()
                return string.format("HUD Offset Y: %+d", getDisplayOffsetY())
            end,
            Info = {
                "Vertical offset for StatsAPI HUD display.",
                "Positive moves down, negative moves up."
            },
            OnChange = function(value)
                setDisplayOffset("y", value)
            end
        })
    end

    if type(ModConfigMenu.AddSpace) == "function" then
        ModConfigMenu.AddSpace(category, subcategory)
    end
    ModConfigMenu.AddSetting(category, subcategory, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return false
        end,
        Display = function()
            return "Reset Display To Default"
        end,
        Info = {
            "Reset Multiplier HUD to defaults:",
            "Display ON, Track Vanilla ON, Debug OFF, Offset X 0, Offset Y 0."
        },
        OnChange = function(value)
            if value then
                resetDisplayDefaults()
            end
            return false
        end
    })

    return true
end

return M
