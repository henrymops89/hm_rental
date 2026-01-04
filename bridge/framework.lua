-- ██████╗ ██████╗ ██╗██████╗  ██████╗ ███████╗
-- ██╔══██╗██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝
-- ██████╔╝██████╔╝██║██║  ██║██║  ███╗█████╗  
-- ██╔══██╗██╔══██╗██║██║  ██║██║   ██║██╔══╝  
-- ██████╔╝██║  ██║██║██████╔╝╚██████╔╝███████╗
-- ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚══════╝
--
-- FRAMEWORK BRIDGE (WITH AUTO-DETECTION!)
-- Handles player data, money, jobs, and identifiers
-- Supports: QBox, QBCore, ESX
-- ════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════
-- AUTO-DETECTION (if Config.Framework = 'auto')
-- ══════════════════════════════════════════════════════════════════════════

if Config.Framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
        Config.Framework = 'qbox'
        if Config.Debug then
            print('^2[Framework]^7 Auto-detected: ^3QBox^7 (qbx_core)')
        end
    elseif GetResourceState('qb-core') == 'started' or GetResourceState('qb-core') == 'starting' then
        Config.Framework = 'qbcore'
        if Config.Debug then
            print('^2[Framework]^7 Auto-detected: ^3QBCore^7 (qb-core)')
        end
    elseif GetResourceState('es_extended') == 'started' or GetResourceState('es_extended') == 'starting' then
        Config.Framework = 'esx'
        if Config.Debug then
            print('^2[Framework]^7 Auto-detected: ^3ESX^7 (es_extended)')
        end
    elseif GetResourceState('esx_core') == 'started' or GetResourceState('esx_core') == 'starting' then
        Config.Framework = 'esx'
        if Config.Debug then
            print('^2[Framework]^7 Auto-detected: ^3ESX^7 (esx_core)')
        end
    else
        Config.Framework = 'qbcore'  -- Default fallback
        print('^3[Framework]^7 No framework detected, defaulting to ^3QBCore^7')
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CORE INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════

Framework = {}
Framework.Type = Config.Framework

if Framework.Type == 'qbox' then
    -- QBox doesn't have GetCoreObject, use exports directly
    Framework.Core = exports.qbx_core
elseif Framework.Type == 'qbcore' then
    Framework.Core = exports['qb-core']:GetCoreObject()
elseif Framework.Type == 'esx' then
    Framework.Core = exports['es_extended']:getSharedObject()
end

-- ══════════════════════════════════════════════════════════════════════════
-- PLAYER FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Get player object from source
--- @param source number Player server ID
--- @return table|nil Player object
function Framework.GetPlayer(source)
    if Framework.Type == 'qbox' then
        -- QBox uses exports directly
        return exports.qbx_core:GetPlayer(source)
    elseif Framework.Type == 'qbcore' then
        return Framework.Core.Functions.GetPlayer(source)
    elseif Framework.Type == 'esx' then
        return Framework.Core.GetPlayerFromId(source)
    end
end

--- Get player identifier
--- @param source number Player server ID
--- @return string Identifier (license:xxx, steam:xxx, etc.)
function Framework.GetIdentifier(source)
    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        local Player = Framework.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework.Type == 'esx' then
        local Player = Framework.GetPlayer(source)
        return Player and Player.identifier or nil
    end
end

--- Get player name
--- @param source number Player server ID
--- @return string Player name
function Framework.GetPlayerName(source)
    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        local Player = Framework.GetPlayer(source)
        if not Player then return 'Unknown' end
        local charinfo = Player.PlayerData.charinfo
        return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
    elseif Framework.Type == 'esx' then
        local Player = Framework.GetPlayer(source)
        return Player and Player.getName() or 'Unknown'
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- MONEY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Add money to player
--- @param source number Player server ID
--- @param amount number Amount to add
--- @param account string Account type ('cash', 'bank')
--- @return boolean Success
function Framework.AddMoney(source, amount, account)
    account = account or 'cash'
    local Player = Framework.GetPlayer(source)
    if not Player then return false end

    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        Player.Functions.AddMoney(account, amount)
        return true
    elseif Framework.Type == 'esx' then
        local accountType = account == 'cash' and 'money' or account
        Player.addAccountMoney(accountType, amount)
        return true
    end
end

--- Remove money from player
--- @param source number Player server ID
--- @param amount number Amount to remove
--- @param account string Account type ('cash', 'bank')
--- @return boolean Success
function Framework.RemoveMoney(source, amount, account)
    account = account or 'cash'
    local Player = Framework.GetPlayer(source)
    if not Player then return false end

    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        return Player.Functions.RemoveMoney(account, amount)
    elseif Framework.Type == 'esx' then
        local accountType = account == 'cash' and 'money' or account
        Player.removeAccountMoney(accountType, amount)
        return true
    end
end

--- Get player money
--- @param source number Player server ID
--- @param account string Account type ('cash', 'bank')
--- @return number Amount
function Framework.GetMoney(source, account)
    account = account or 'cash'
    local Player = Framework.GetPlayer(source)
    if not Player then return 0 end

    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        return Player.PlayerData.money[account] or 0
    elseif Framework.Type == 'esx' then
        local accountType = account == 'cash' and 'money' or account
        return Player.getAccount(accountType).money or 0
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- JOB FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Get player job
--- @param source number Player server ID
--- @return string Job name
function Framework.GetJob(source)
    local Player = Framework.GetPlayer(source)
    if not Player then return nil end

    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        return Player.PlayerData.job.name
    elseif Framework.Type == 'esx' then
        return Player.getJob().name
    end
end

--- Check if player has job
--- @param source number Player server ID
--- @param jobName string Job name to check
--- @return boolean Has job
function Framework.HasJob(source, jobName)
    local playerJob = Framework.GetJob(source)
    return playerJob == jobName
end

--- Check if player has any of the jobs
--- @param source number Player server ID
--- @param jobs table List of job names
--- @return boolean Has any job
function Framework.HasAnyJob(source, jobs)
    local playerJob = Framework.GetJob(source)
    for _, job in ipairs(jobs) do
        if playerJob == job then
            return true
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════════════
-- PERMISSION FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Check if player has permission
--- @param source number Player server ID
--- @param permission string Permission name
--- @return boolean Has permission
function Framework.HasPermission(source, permission)
    if Framework.Type == 'qbox' then
        -- QBox uses HasPermission export
        return exports.qbx_core:HasPermission(source, permission)
    elseif Framework.Type == 'qbcore' then
        return Framework.Core.Functions.HasPermission(source, permission)
    elseif Framework.Type == 'esx' then
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        -- ESX group-based permissions
        local group = Player.getGroup()
        if permission == 'admin' then
            return group == 'admin' or group == 'superadmin'
        elseif permission == 'god' then
            return group == 'superadmin'
        end
        
        return group == permission
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Check if player is online
--- @param source number Player server ID
--- @return boolean Is online
function Framework.IsPlayerOnline(source)
    return Framework.GetPlayer(source) ~= nil
end

--- Get all online players
--- @return table List of player sources
function Framework.GetPlayers()
    if Framework.Type == 'qbox' then
        -- QBox uses GetQBPlayers export
        return exports.qbx_core:GetQBPlayers()
    elseif Framework.Type == 'qbcore' then
        return Framework.Core.Functions.GetPlayers()
    elseif Framework.Type == 'esx' then
        local players = {}
        for _, playerId in ipairs(GetPlayers()) do
            table.insert(players, tonumber(playerId))
        end
        return players
    end
end

--- Get player's coordinates
--- @param source number Player server ID
--- @return vector3 Coordinates
function Framework.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    return GetEntityCoords(ped)
end

--- Kick player from server
--- @param source number Player server ID
--- @param reason string Kick reason
function Framework.KickPlayer(source, reason)
    if Framework.Type == 'qbox' or Framework.Type == 'qbcore' then
        DropPlayer(source, reason)
    elseif Framework.Type == 'esx' then
        DropPlayer(source, reason)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- ITEM USAGE REGISTRATION (For useable items)
-- ══════════════════════════════════════════════════════════════════════════

--- Register useable item
--- @param itemName string Item name
--- @param callback function Callback function
function Framework.RegisterUsableItem(itemName, callback)
    if Framework.Type == 'qbox' then
        -- QBox uses CreateUseableItem export
        exports.qbx_core:CreateUseableItem(itemName, callback)
    elseif Framework.Type == 'qbcore' then
        Framework.Core.Functions.CreateUseableItem(itemName, callback)
    elseif Framework.Type == 'esx' then
        Framework.Core.RegisterUsableItem(itemName, callback)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CLIENT-SIDE FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Get local player data
--- @return table Player data
function Framework.GetPlayerData()
    if IsDuplicityVersion() == 1 then 
        print('^1[Framework]^7 ERROR: GetPlayerData called on server!')
        return nil 
    end
    
    if Framework.Type == 'qbox' then
        return exports.qbx_core:GetPlayerData()
    elseif Framework.Type == 'qbcore' then
        return Framework.Core.Functions.GetPlayerData()
    elseif Framework.Type == 'esx' then
        return Framework.Core.GetPlayerData()
    end
end

--- Trigger server callback
--- @param name string Callback name
--- @param callback function Callback function
--- @param ... any Arguments
function Framework.TriggerCallback(name, callback, ...)
    if IsDuplicityVersion() == 1 then 
        print('^1[Framework]^7 ERROR: TriggerCallback called on server!')
        return 
    end
    
    if Framework.Type == 'qbox' then
        -- QBox uses lib.callback from ox_lib (async)
        if not lib or not lib.callback or not lib.callback.await then
            print('^1[Framework Bridge]^7 Error: ox_lib not loaded! Cannot use callbacks.')
            print('^3[Framework Bridge]^7 Make sure ox_lib is loaded before hm-metaldetecting')
            if callback then callback(nil) end
            return
        end
        
        local args = {...}
        Citizen.CreateThread(function()
            local success, result = pcall(function()
                return lib.callback.await(name, false, table.unpack(args))
            end)
            
            if success then
                if callback then callback(result) end
            else
                print('^1[Framework Bridge]^7 Callback error:', result)
                if callback then callback(nil) end
            end
        end)
    elseif Framework.Type == 'qbcore' then
        Framework.Core.Functions.TriggerCallback(name, callback, ...)
    elseif Framework.Type == 'esx' then
        Framework.Core.TriggerServerCallback(name, callback, ...)
    end
end

--- Get closest player
--- @return number Player ID
--- @return number Distance
function Framework.GetClosestPlayer()
    if IsDuplicityVersion() == 1 then 
        print('^1[Framework]^7 ERROR: GetClosestPlayer called on server!')
        return nil, nil 
    end
    
    if Framework.Type == 'qbox' then
        local player, distance = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 5, false)
        return player, distance
    elseif Framework.Type == 'qbcore' then
        return Framework.Core.Functions.GetClosestPlayer()
    elseif Framework.Type == 'esx' then
        return Framework.Core.Game.GetClosestPlayer()
    end
end

-- Debug print for client functions
if IsDuplicityVersion() == 0 then
    print('^2[Framework Bridge]^7 Client functions initialized for: ^3' .. Framework.Type .. '^7')
    print('^2[Framework Bridge]^7 Client functions loaded:')
    print('  - GetPlayerData:', Framework.GetPlayerData ~= nil)
    print('  - TriggerCallback:', Framework.TriggerCallback ~= nil)
    print('  - GetClosestPlayer:', Framework.GetClosestPlayer ~= nil)
    print('^2[Framework Bridge]^7 ✅ CLIENT BRIDGE READY')
end

-- ══════════════════════════════════════════════════════════════════════════
-- SERVER-SIDE FUNCTIONS (Only available on server)
-- ══════════════════════════════════════════════════════════════════════════

if IsDuplicityVersion() == 1 then -- Server-side only
    
    --- Register server callback
    --- @param name string Callback name
    --- @param callback function Callback function (QBCore-style: function(source, cb, ...))
    function Framework.RegisterCallback(name, callback)
        if Framework.Type == 'qbox' then
            -- QBox uses lib.callback.register from ox_lib
            -- QBox callbacks use return instead of cb()
            -- Wrap the callback to convert QBCore-style (with cb) to QBox-style (return)
            lib.callback.register(name, function(source, ...)
                local result = nil
                local cbCalled = false
                
                -- Create a fake cb function that captures the result
                local function fakeCb(data)
                    result = data
                    cbCalled = true
                end
                
                -- Call the original callback with the fake cb
                callback(source, fakeCb, ...)
                
                -- Return the captured result
                return result
            end)
        elseif Framework.Type == 'qbcore' then
            Framework.Core.Functions.CreateCallback(name, callback)
        elseif Framework.Type == 'esx' then
            Framework.Core.RegisterServerCallback(name, callback)
        end
    end

    --- Get player from identifier
    --- @param identifier string Player identifier
    --- @return table|nil Player object
    function Framework.GetPlayerByIdentifier(identifier)
        if Framework.Type == 'qbox' then
            return exports.qbx_core:GetPlayerByCitizenId(identifier)
        elseif Framework.Type == 'qbcore' then
            return Framework.Core.Functions.GetPlayerByCitizenId(identifier)
        elseif Framework.Type == 'esx' then
            -- ESX doesn't have built-in function, iterate through players
            for _, playerId in ipairs(GetPlayers()) do
                local Player = Framework.GetPlayer(tonumber(playerId))
                if Player and Player.identifier == identifier then
                    return Player
                end
            end
            return nil
        end
    end

end

-- ══════════════════════════════════════════════════════════════════════════
-- DEBUG LOGGING
-- ══════════════════════════════════════════════════════════════════════════

if IsDuplicityVersion() == 1 then
    print('^2[Framework Bridge]^7 Server functions initialized for: ^3' .. Framework.Type .. '^7')
    if Framework.Type == 'qbox' then
        print('^2[Framework Bridge]^7 Using callback wrapper for QBox compatibility')
    end
end

if Config.Debug then
    print('^2[HM-MetalDetecting]^7 Framework Bridge initialized: ^3' .. Framework.Type .. '^7')
end

return Framework