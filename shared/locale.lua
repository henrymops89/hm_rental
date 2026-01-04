-- ██╗      ██████╗  ██████╗ █████╗ ██╗     ███████╗
-- ██║     ██╔═══██╗██╔════╝██╔══██╗██║     ██╔════╝
-- ██║     ██║   ██║██║     ███████║██║     █████╗  
-- ██║     ██║   ██║██║     ██╔══██║██║     ██╔══╝  
-- ███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗
-- ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝
--
-- LOCALE SYSTEM
-- Translation management and language loader
-- ════════════════════════════════════════════════════════════════════════════

Locales = {}
Lang = {}

--- Load locale file
--- @param locale string Locale code (en, de, etc.)
function Locales.Load(locale)
    local resourceName = GetCurrentResourceName()
    local localeFile = ('locales/%s.lua'):format(locale)
    
    if Config.Debug then
        print(('^3[HM-Rental Locale]^7 Attempting to load: %s'):format(localeFile))
    end
    
    -- Try to load locale file
    local success, result = pcall(function()
        return LoadResourceFile(resourceName, localeFile)
    end)
    
    if not success or not result then
        print(('^1[HM-Rental]^7 Failed to load locale: %s'):format(locale))
        print('^3[HM-Rental]^7 Falling back to English (en)')
        
        -- Fallback to English
        result = LoadResourceFile(resourceName, 'locales/en.lua')
    end
    
    if result then
        local localeData = load(result)()
        Lang = localeData
        
        if Config.Debug then
            print(('^2[HM-Rental]^7 Successfully loaded locale: %s'):format(locale))
            print(('^2[HM-Rental]^7 Lang table type: %s'):format(type(Lang)))
            if Lang then
                print(('^2[HM-Rental]^7 Lang.blips exists: %s'):format(tostring(Lang.blips ~= nil)))
            end
        end
    else
        print('^1[HM-Rental]^7 Critical: Could not load any locale file!')
        Lang = {}  -- Set empty table as fallback
    end
end

--- Get translation string
--- @param category string Category name (e.g., 'notify', 'menu')
--- @param key string Translation key
--- @param ... any Format arguments
--- @return string Translated string
function Locales.Get(category, key, ...)
    -- Guard: Lang not loaded yet
    if not Lang or type(Lang) ~= 'table' then
        return 'LOCALE_NOT_LOADED'
    end
    
    if not Lang[category] then
        return 'MISSING_CATEGORY: ' .. category
    end
    
    if not Lang[category][key] then
        return 'MISSING_KEY: ' .. category .. '.' .. key
    end
    
    local str = Lang[category][key]
    
    -- If arguments provided, format string
    if ... then
        return string.format(str, ...)
    end
    
    return str
end

--- Shorthand function for getting translations
--- @param path string Dot-notation path (e.g., 'notify.item_found')
--- @param ... any Format arguments
--- @return string Translated string
function _(path, ...)
    local parts = {}
    for part in path:gmatch('[^.]+') do
        table.insert(parts, part)
    end
    
    if #parts < 2 then
        return 'INVALID_PATH: ' .. path
    end
    
    local category = parts[1]
    local key = parts[2]
    
    return Locales.Get(category, key, ...)
end

--- Get nested value (for complex structures like vehicles)
--- @param path string Dot-notation path (e.g., 'vehicles.bicycle.name')
--- @return any Value at path
function Locales.GetNested(path)
    local parts = {}
    for part in path:gmatch('[^.]+') do
        table.insert(parts, part)
    end
    
    local current = Lang
    for _, part in ipairs(parts) do
        if current[part] then
            current = current[part]
        else
            return 'MISSING_PATH: ' .. path
        end
    end
    
    return current
end

--- Check if locale exists
--- @param locale string Locale code
--- @return boolean Exists
function Locales.Exists(locale)
    local resourceName = GetCurrentResourceName()
    local localeFile = ('locales/%s.lua'):format(locale)
    local content = LoadResourceFile(resourceName, localeFile)
    return content ~= nil
end

--- Get all available locales
--- @return table List of locale codes
function Locales.GetAvailable()
    return {'en', 'de'}
end

--- Reload current locale (useful for development)
function Locales.Reload()
    Locales.Load(Config.Locale)
end

-- ══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════

-- Load locale immediately (don't wait for Config in a thread)
-- Config is already loaded since locale.lua is after config.lua in fxmanifest
if Config and Config.Locale then
    Locales.Load(Config.Locale)
else
    -- Fallback to English if Config not available yet
    Locales.Load('en')
    print('^3[HM-Rental]^7 Warning: Config not loaded yet, using English locale')
end

-- ══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ══════════════════════════════════════════════════════════════════════════

exports('GetLocale', function()
    return Config.Locale
end)

exports('GetTranslation', function(path, ...)
    return _(path, ...)
end)

exports('ReloadLocale', function()
    Locales.Reload()
end)
