local M = {}
local OFFSET_MIN = -200
local OFFSET_MAX = 200
local DISPLAY_MODE_LAST = "last"
local DISPLAY_MODE_FINAL = "final"
local DISPLAY_MODE_BOTH = "both"
local DISPLAY_MODE_MIN_INDEX = 0
local DISPLAY_MODE_MAX_INDEX = 2
local DISPLAY_MODE_BY_INDEX = {
    [0] = DISPLAY_MODE_LAST,
    [1] = DISPLAY_MODE_FINAL,
    [2] = DISPLAY_MODE_BOTH
}
local DISPLAY_MODE_INDEX_BY_MODE = {
    [DISPLAY_MODE_LAST] = 0,
    [DISPLAY_MODE_FINAL] = 1,
    [DISPLAY_MODE_BOTH] = 2
}
local DISPLAY_MODE_LABELS = {
    [DISPLAY_MODE_LAST] = "Last Multiplier",
    [DISPLAY_MODE_FINAL] = "Final Multiplier",
    [DISPLAY_MODE_BOTH] = "Both"
}
local DISPLAY_MODE_SCROLL_VALUE_BY_MODE = {
    [DISPLAY_MODE_LAST] = 0,
    [DISPLAY_MODE_FINAL] = 5,
    [DISPLAY_MODE_BOTH] = 10
}
local TAB_HOLD_SECONDS_MIN = 0
local TAB_HOLD_SECONDS_MAX = 10
local DISPLAY_DURATION_SECONDS_MIN = 0
local DISPLAY_DURATION_SECONDS_MAX = 30
local FADE_IN_SECONDS_MIN = 0
local FADE_IN_SECONDS_MAX = 10
local FADE_OUT_SECONDS_MIN = 0
local FADE_OUT_SECONDS_MAX = 10
local DEFAULT_TAB_HOLD_SECONDS = 0
local DEFAULT_DISPLAY_DURATION_SECONDS = 5
local DEFAULT_FADE_IN_SECONDS = 0.2
local DEFAULT_FADE_OUT_SECONDS = 0.6

local function getDefaultSettings()
    if StatsAPI and type(StatsAPI.DEFAULT_SETTINGS) == "table" then
        return StatsAPI.DEFAULT_SETTINGS
    end
    return {
        displayEnabled = true,
        displayOffsetX = 0,
        displayOffsetY = 0,
        trackVanillaDisplay = true,
        debugEnabled = false,
        displayMode = DISPLAY_MODE_BOTH,
        tabHoldSeconds = DEFAULT_TAB_HOLD_SECONDS,
        displayDurationSeconds = DEFAULT_DISPLAY_DURATION_SECONDS,
        fadeInSeconds = DEFAULT_FADE_IN_SECONDS,
        fadeOutSeconds = DEFAULT_FADE_OUT_SECONDS
    }
end

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

local function clampSeconds(value, minValue, maxValue, defaultValue)
    local num = tonumber(value)
    if type(num) ~= "number" then
        num = defaultValue
    end
    if num < minValue then
        num = minValue
    elseif num > maxValue then
        num = maxValue
    end
    return math.floor((num * 10) + 0.5) / 10
end

local function normalizeDisplayMode(value)
    if type(value) == "number" then
        local rounded = nil
        if value >= 0 then
            rounded = math.floor(value + 0.5)
        else
            rounded = math.ceil(value - 0.5)
        end
        if rounded < 0 then
            rounded = 0
        elseif rounded > 10 then
            rounded = 10
        end

        -- NUMBER mode: exact 0/1/2
        if rounded >= DISPLAY_MODE_MIN_INDEX and rounded <= DISPLAY_MODE_MAX_INDEX then
            return DISPLAY_MODE_BY_INDEX[rounded] or DISPLAY_MODE_BOTH
        end

        -- SCROLL mode fallback (0~10): bucket into 3 states.
        if rounded <= 3 then
            return DISPLAY_MODE_LAST
        elseif rounded <= 7 then
            return DISPLAY_MODE_FINAL
        end
        return DISPLAY_MODE_BOTH
    end

    if type(value) == "string" then
        local mode = string.lower(value)
        if mode == DISPLAY_MODE_LAST
            or mode == "current"
            or mode == "last_multiplier"
            or mode == "recent" then
            return DISPLAY_MODE_LAST
        elseif mode == DISPLAY_MODE_FINAL
            or mode == "total"
            or mode == "final_multiplier"
            or mode == "total_multiplier" then
            return DISPLAY_MODE_FINAL
        elseif mode == DISPLAY_MODE_BOTH
            or mode == "all" then
            return DISPLAY_MODE_BOTH
        end
    end

    return DISPLAY_MODE_BOTH
end

local function ensureSettingsTable()
    if not StatsAPI then
        return nil
    end
    local defaults = getDefaultSettings()
    if type(StatsAPI.settings) ~= "table" then
        StatsAPI.settings = {}
    end
    for key, defaultValue in pairs(defaults) do
        if StatsAPI.settings[key] == nil then
            StatsAPI.settings[key] = defaultValue
        end
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

    local defaults = getDefaultSettings()
    local previousTrackVanilla = settings.trackVanillaDisplay
    local previousDebugEnabled = settings.debugEnabled == true
    local previousDisplayMode = normalizeDisplayMode(settings.displayMode)
    settings.displayEnabled = defaults.displayEnabled
    settings.displayOffsetX = defaults.displayOffsetX
    settings.displayOffsetY = defaults.displayOffsetY
    settings.trackVanillaDisplay = defaults.trackVanillaDisplay
    settings.debugEnabled = defaults.debugEnabled
    settings.displayMode = defaults.displayMode
    settings.tabHoldSeconds = defaults.tabHoldSeconds
    settings.displayDurationSeconds = defaults.displayDurationSeconds
    settings.fadeInSeconds = defaults.fadeInSeconds
    settings.fadeOutSeconds = defaults.fadeOutSeconds

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

    if previousDisplayMode ~= DISPLAY_MODE_BOTH
        and StatsAPI
        and type(StatsAPI.SetDisplayMode) == "function" then
        StatsAPI:SetDisplayMode(DISPLAY_MODE_BOTH)
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

local function getDisplayMode()
    if StatsAPI and type(StatsAPI.GetDisplayMode) == "function" then
        return normalizeDisplayMode(StatsAPI:GetDisplayMode())
    end
    local settings = ensureSettingsTable()
    if settings then
        return normalizeDisplayMode(settings.displayMode)
    end
    return DISPLAY_MODE_BOTH
end

local function getDisplayModeIndex()
    local mode = getDisplayMode()
    return DISPLAY_MODE_INDEX_BY_MODE[mode] or DISPLAY_MODE_INDEX_BY_MODE[DISPLAY_MODE_BOTH]
end

local function getDisplayModeScrollValue()
    local mode = getDisplayMode()
    return DISPLAY_MODE_SCROLL_VALUE_BY_MODE[mode] or DISPLAY_MODE_SCROLL_VALUE_BY_MODE[DISPLAY_MODE_BOTH]
end

local function getTabHoldSeconds()
    if StatsAPI and type(StatsAPI.GetTabHoldSeconds) == "function" then
        return clampSeconds(
            StatsAPI:GetTabHoldSeconds(),
            TAB_HOLD_SECONDS_MIN,
            TAB_HOLD_SECONDS_MAX,
            DEFAULT_TAB_HOLD_SECONDS
        )
    end
    local settings = ensureSettingsTable()
    if settings then
        return clampSeconds(
            settings.tabHoldSeconds,
            TAB_HOLD_SECONDS_MIN,
            TAB_HOLD_SECONDS_MAX,
            DEFAULT_TAB_HOLD_SECONDS
        )
    end
    return DEFAULT_TAB_HOLD_SECONDS
end

local function getDisplayDurationSeconds()
    if StatsAPI and type(StatsAPI.GetDisplayDurationSeconds) == "function" then
        return clampSeconds(
            StatsAPI:GetDisplayDurationSeconds(),
            DISPLAY_DURATION_SECONDS_MIN,
            DISPLAY_DURATION_SECONDS_MAX,
            DEFAULT_DISPLAY_DURATION_SECONDS
        )
    end
    local settings = ensureSettingsTable()
    if settings then
        return clampSeconds(
            settings.displayDurationSeconds,
            DISPLAY_DURATION_SECONDS_MIN,
            DISPLAY_DURATION_SECONDS_MAX,
            DEFAULT_DISPLAY_DURATION_SECONDS
        )
    end
    return DEFAULT_DISPLAY_DURATION_SECONDS
end

local function getFadeInSeconds()
    if StatsAPI and type(StatsAPI.GetFadeInSeconds) == "function" then
        return clampSeconds(
            StatsAPI:GetFadeInSeconds(),
            FADE_IN_SECONDS_MIN,
            FADE_IN_SECONDS_MAX,
            DEFAULT_FADE_IN_SECONDS
        )
    end
    local settings = ensureSettingsTable()
    if settings then
        return clampSeconds(
            settings.fadeInSeconds,
            FADE_IN_SECONDS_MIN,
            FADE_IN_SECONDS_MAX,
            DEFAULT_FADE_IN_SECONDS
        )
    end
    return DEFAULT_FADE_IN_SECONDS
end

local function getFadeOutSeconds()
    if StatsAPI and type(StatsAPI.GetFadeOutSeconds) == "function" then
        return clampSeconds(
            StatsAPI:GetFadeOutSeconds(),
            FADE_OUT_SECONDS_MIN,
            FADE_OUT_SECONDS_MAX,
            DEFAULT_FADE_OUT_SECONDS
        )
    end
    local settings = ensureSettingsTable()
    if settings then
        return clampSeconds(
            settings.fadeOutSeconds,
            FADE_OUT_SECONDS_MIN,
            FADE_OUT_SECONDS_MAX,
            DEFAULT_FADE_OUT_SECONDS
        )
    end
    return DEFAULT_FADE_OUT_SECONDS
end

local function setDisplayMode(value)
    local mode = normalizeDisplayMode(value)
    if StatsAPI and type(StatsAPI.SetDisplayMode) == "function" then
        StatsAPI:SetDisplayMode(mode)
        return
    end

    local settings = ensureSettingsTable()
    if not settings then
        return
    end

    if settings.displayMode == mode then
        return
    end
    settings.displayMode = mode

    if StatsAPI and StatsAPI.stats and StatsAPI.stats.multiplierDisplay
        and type(StatsAPI.stats.multiplierDisplay.RefreshAllFromUnified) == "function" then
        StatsAPI.stats.multiplierDisplay:RefreshAllFromUnified()
    end
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function setTabHoldSeconds(value)
    local seconds = clampSeconds(
        value,
        TAB_HOLD_SECONDS_MIN,
        TAB_HOLD_SECONDS_MAX,
        DEFAULT_TAB_HOLD_SECONDS
    )
    if StatsAPI and type(StatsAPI.SetTabHoldSeconds) == "function" then
        StatsAPI:SetTabHoldSeconds(seconds)
        return
    end

    local settings = ensureSettingsTable()
    if not settings then
        return
    end
    if settings.tabHoldSeconds == seconds then
        return
    end
    settings.tabHoldSeconds = seconds
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function setDisplayDurationSeconds(value)
    local seconds = clampSeconds(
        value,
        DISPLAY_DURATION_SECONDS_MIN,
        DISPLAY_DURATION_SECONDS_MAX,
        DEFAULT_DISPLAY_DURATION_SECONDS
    )
    if StatsAPI and type(StatsAPI.SetDisplayDurationSeconds) == "function" then
        StatsAPI:SetDisplayDurationSeconds(seconds)
        return
    end

    local settings = ensureSettingsTable()
    if not settings then
        return
    end
    if settings.displayDurationSeconds == seconds then
        return
    end
    settings.displayDurationSeconds = seconds
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function setFadeInSeconds(value)
    local seconds = clampSeconds(
        value,
        FADE_IN_SECONDS_MIN,
        FADE_IN_SECONDS_MAX,
        DEFAULT_FADE_IN_SECONDS
    )
    if StatsAPI and type(StatsAPI.SetFadeInSeconds) == "function" then
        StatsAPI:SetFadeInSeconds(seconds)
        return
    end

    local settings = ensureSettingsTable()
    if not settings then
        return
    end
    if settings.fadeInSeconds == seconds then
        return
    end
    settings.fadeInSeconds = seconds
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function setFadeOutSeconds(value)
    local seconds = clampSeconds(
        value,
        FADE_OUT_SECONDS_MIN,
        FADE_OUT_SECONDS_MAX,
        DEFAULT_FADE_OUT_SECONDS
    )
    if StatsAPI and type(StatsAPI.SetFadeOutSeconds) == "function" then
        StatsAPI:SetFadeOutSeconds(seconds)
        return
    end

    local settings = ensureSettingsTable()
    if not settings then
        return
    end
    if settings.fadeOutSeconds == seconds then
        return
    end
    settings.fadeOutSeconds = seconds
    if StatsAPI and type(StatsAPI.SaveRunData) == "function" then
        StatsAPI:SaveRunData()
    end
end

local function secondsToScroll(seconds, maxSeconds)
    local safeMax = tonumber(maxSeconds) or 10
    if safeMax <= 0 then
        safeMax = 10
    end
    local ratio = (tonumber(seconds) or 0) / safeMax
    if ratio < 0 then
        ratio = 0
    elseif ratio > 1 then
        ratio = 1
    end
    return math.floor((ratio * 10) + 0.5)
end

local function scrollToSeconds(value, maxSeconds, defaultValue)
    local scroll = tonumber(value) or 0
    if scroll < 0 then
        scroll = 0
    elseif scroll > 10 then
        scroll = 10
    end
    local safeMax = tonumber(maxSeconds) or 10
    if safeMax <= 0 then
        safeMax = 10
    end
    local seconds = (scroll / 10) * safeMax
    return clampSeconds(seconds, 0, safeMax, defaultValue)
end

function M.Setup()
    if not hasMCM() then
        return false
    end

    local hasNumberOption = ModConfigMenu.OptionType.NUMBER ~= nil
    local hasScrollOption = ModConfigMenu.OptionType.SCROLL ~= nil
    if not hasNumberOption and not hasScrollOption then
        return false
    end
    local modeOptionType = hasNumberOption and ModConfigMenu.OptionType.NUMBER or ModConfigMenu.OptionType.SCROLL

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

    local modeSetting = {
        Type = modeOptionType,
        CurrentSetting = function()
            if modeOptionType == ModConfigMenu.OptionType.NUMBER then
                return getDisplayModeIndex()
            end
            return getDisplayModeScrollValue()
        end,
        Display = function()
            local mode = getDisplayMode()
            local label = DISPLAY_MODE_LABELS[mode] or DISPLAY_MODE_LABELS[DISPLAY_MODE_BOTH]
            return "HUD Display Mode: " .. label
        end,
        Info = {
            "Choose what to render on stat multiplier HUD text.",
            "Last Multiplier: show only latest changed multiplier.",
            "Final Multiplier: show only final combined multiplier.",
            "Both: show latest/final together (default)."
        },
        OnChange = function(value)
            setDisplayMode(value)
        end
    }
    if modeOptionType == ModConfigMenu.OptionType.NUMBER then
        modeSetting.Minimum = DISPLAY_MODE_MIN_INDEX
        modeSetting.Maximum = DISPLAY_MODE_MAX_INDEX
    end
    ModConfigMenu.AddSetting(category, subcategory, modeSetting)

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

    local timingSubcategory = "Timing"
    if type(ModConfigMenu.AddSpace) == "function" then
        ModConfigMenu.AddSpace(category, timingSubcategory)
    end
    if type(ModConfigMenu.AddText) == "function" then
        ModConfigMenu.AddText(category, timingSubcategory, "--- HUD Timing ---")
    end

    if hasNumberOption then
        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return getTabHoldSeconds()
            end,
            Minimum = TAB_HOLD_SECONDS_MIN,
            Maximum = TAB_HOLD_SECONDS_MAX,
            ModifyBy = 0.1,
            Display = function()
                return string.format("Hold To Show (sec): %.1f", getTabHoldSeconds())
            end,
            Info = {
                "How long to hold TAB before HUD appears."
            },
            OnChange = function(value)
                setTabHoldSeconds(value)
            end
        })

        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return getFadeInSeconds()
            end,
            Minimum = FADE_IN_SECONDS_MIN,
            Maximum = FADE_IN_SECONDS_MAX,
            ModifyBy = 0.1,
            Display = function()
                return string.format("Fade In (sec): %.1f", getFadeInSeconds())
            end,
            Info = {
                "How long HUD takes to appear after hold is satisfied."
            },
            OnChange = function(value)
                setFadeInSeconds(value)
            end
        })

        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return getFadeOutSeconds()
            end,
            Minimum = FADE_OUT_SECONDS_MIN,
            Maximum = FADE_OUT_SECONDS_MAX,
            ModifyBy = 0.1,
            Display = function()
                return string.format("Fade Out (sec): %.1f", getFadeOutSeconds())
            end,
            Info = {
                "How long HUD takes to disappear after TAB release."
            },
            OnChange = function(value)
                setFadeOutSeconds(value)
            end
        })
    elseif hasScrollOption then
        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.SCROLL,
            CurrentSetting = function()
                return secondsToScroll(getTabHoldSeconds(), TAB_HOLD_SECONDS_MAX)
            end,
            Display = function()
                return string.format("Hold To Show (sec): %.1f", getTabHoldSeconds())
            end,
            Info = {
                "How long to hold TAB before HUD appears.",
                "SCROLL mode is coarse (0~10 steps)."
            },
            OnChange = function(value)
                setTabHoldSeconds(scrollToSeconds(value, TAB_HOLD_SECONDS_MAX, DEFAULT_TAB_HOLD_SECONDS))
            end
        })

        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.SCROLL,
            CurrentSetting = function()
                return secondsToScroll(getFadeInSeconds(), FADE_IN_SECONDS_MAX)
            end,
            Display = function()
                return string.format("Fade In (sec): %.1f", getFadeInSeconds())
            end,
            Info = {
                "How long HUD takes to appear after hold is satisfied.",
                "SCROLL mode is coarse (0~10 steps)."
            },
            OnChange = function(value)
                setFadeInSeconds(scrollToSeconds(value, FADE_IN_SECONDS_MAX, DEFAULT_FADE_IN_SECONDS))
            end
        })

        ModConfigMenu.AddSetting(category, timingSubcategory, {
            Type = ModConfigMenu.OptionType.SCROLL,
            CurrentSetting = function()
                return secondsToScroll(getFadeOutSeconds(), FADE_OUT_SECONDS_MAX)
            end,
            Display = function()
                return string.format("Fade Out (sec): %.1f", getFadeOutSeconds())
            end,
            Info = {
                "How long HUD takes to disappear after TAB release.",
                "SCROLL mode is coarse (0~10 steps)."
            },
            OnChange = function(value)
                setFadeOutSeconds(scrollToSeconds(value, FADE_OUT_SECONDS_MAX, DEFAULT_FADE_OUT_SECONDS))
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
            "Display ON, Mode BOTH, Track Vanilla ON, Debug OFF, Hold 0.0s, Fade In 0.2s, Fade Out 0.6s, Offset X 0, Offset Y 0."
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
