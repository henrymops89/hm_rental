-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - VEHICLE KEYS BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════
-- Supports multiple vehicle key systems with auto-detection
-- Primary support: jaksam vehicles_keys
-- Secondary support: qb-vehiclekeys, cd_garage, wasabi_carlock, etc.
-- ═══════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════
-- AUTO-DETECTION (if Config.VehicleKeys = 'auto')
-- ══════════════════════════════════════════════════════════════════════════

if Config.VehicleKeys == 'auto' then
    if GetResourceState('vehicles_keys') == 'started' or GetResourceState('vehicles_keys') == 'starting' then
        Config.VehicleKeys = 'jaksam'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3jaksam vehicles_keys^7')
        end
    elseif GetResourceState('qs-vehiclekeys') == 'started' or GetResourceState('qs-vehiclekeys') == 'starting' then
        Config.VehicleKeys = 'qs-vehiclekeys'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3qs-vehiclekeys^7')
        end
    elseif GetResourceState('qb-vehiclekeys') == 'started' or GetResourceState('qb-vehiclekeys') == 'starting' then
        Config.VehicleKeys = 'qb-vehiclekeys'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3qb-vehiclekeys^7')
        end
    elseif GetResourceState('qbx_vehiclekeys') == 'started' or GetResourceState('qbx_vehiclekeys') == 'starting' then
        Config.VehicleKeys = 'qbx_vehiclekeys'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3qbx_vehiclekeys^7')
        end
    elseif GetResourceState('wasabi_carlock') == 'started' or GetResourceState('wasabi_carlock') == 'starting' then
        Config.VehicleKeys = 'wasabi_carlock'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3wasabi_carlock^7')
        end
    elseif GetResourceState('cd_garage') == 'started' or GetResourceState('cd_garage') == 'starting' then
        Config.VehicleKeys = 'cd_garage'
        if Config.Debug then
            print('^2[Vehicle Keys]^7 Auto-detected: ^3cd_garage^7')
        end
    else
        Config.VehicleKeys = 'none'
        if Config.Debug then
            print('^3[Vehicle Keys]^7 No vehicle key system detected')
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CORE INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════

VehicleKeys = {}
VehicleKeys.Type = Config.VehicleKeys

-- ══════════════════════════════════════════════════════════════════════════
-- CLIENT-SIDE FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

if IsDuplicityVersion() == 0 then -- Client-side only
    
    --- Give keys to player for vehicle
    --- @param vehicle number Vehicle entity
    --- @param plate string Vehicle plate (optional, auto-detected from vehicle)
    --- @return boolean Success
    function VehicleKeys.GiveKeys(vehicle, plate)
        if not DoesEntityExist(vehicle) then
            print('^1[Vehicle Keys]^7 ERROR: Vehicle does not exist!')
            return false
        end
        
        -- Get plate if not provided
        if not plate then
            plate = GetVehicleNumberPlateText(vehicle)
        end
        
        -- Trim plate
        plate = plate:gsub("^%s*(.-)%s*$", "%1")
        
        if VehicleKeys.Type == 'jaksam' then
            -- jaksam vehicles_keys: Client triggers server event
            TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Gave keys (jaksam):', plate)
            end
            return true
        
        elseif VehicleKeys.Type == 'qs-vehiclekeys' then
            -- Quasar Vehicle Keys: GiveKeysAuto (uses current vehicle)
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Gave keys (qs-vehiclekeys):', plate, model)
            end
            return true
            
        elseif VehicleKeys.Type == 'qb-vehiclekeys' then
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Gave keys (qb-vehiclekeys):', plate)
            end
            return true
            
        elseif VehicleKeys.Type == 'qbx_vehiclekeys' then
            -- QBX has no client-side export to give keys
            -- Keys must be given server-side only
            if Config.Debug then
                print('^3[Vehicle Keys]^7 qbx_vehiclekeys: Client-side key giving not supported, use server-side')
            end
            return false
            
        elseif VehicleKeys.Type == 'wasabi_carlock' then
            exports.wasabi_carlock:GiveKey(plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Gave keys (wasabi_carlock):', plate)
            end
            return true
            
        elseif VehicleKeys.Type == 'cd_garage' then
            TriggerEvent('cd_garage:AddKeys', plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Gave keys (cd_garage):', plate)
            end
            return true
            
        elseif VehicleKeys.Type == 'none' then
            -- No key system, that's fine
            return true
            
        else
            print('^3[Vehicle Keys]^7 Unknown key system:', VehicleKeys.Type)
            return false
        end
    end
    
    --- Remove keys from player for vehicle
    --- @param vehicle number Vehicle entity
    --- @param plate string Vehicle plate (optional, auto-detected from vehicle)
    --- @return boolean Success
    function VehicleKeys.RemoveKeys(vehicle, plate)
        if not plate and DoesEntityExist(vehicle) then
            plate = GetVehicleNumberPlateText(vehicle)
        end
        
        if not plate then
            print('^1[Vehicle Keys]^7 ERROR: No plate provided!')
            return false
        end
        
        -- Trim plate
        plate = plate:gsub("^%s*(.-)%s*$", "%1")
        
        if VehicleKeys.Type == 'jaksam' then
            -- jaksam vehicles_keys: Trigger server to remove
            TriggerServerEvent("vehicles_keys:selfRemoveVehicleKeys", plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Removed keys (jaksam):', plate)
            end
            return true
        
        elseif VehicleKeys.Type == 'qs-vehiclekeys' then
            -- Quasar Vehicle Keys: RemoveKeys
            local model = DoesEntityExist(vehicle) and GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or "unknown"
            exports['qs-vehiclekeys']:RemoveKeys(plate, model)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Removed keys (qs-vehiclekeys):', plate, model)
            end
            return true
            
        elseif VehicleKeys.Type == 'wasabi_carlock' then
            exports.wasabi_carlock:RemoveKey(plate)
            if Config.Debug then
                print('^2[Vehicle Keys]^7 Removed keys (wasabi_carlock):', plate)
            end
            return true
            
        elseif VehicleKeys.Type == 'none' then
            -- No key system
            return true
            
        else
            -- Most key systems don't have remove functionality on client
            if Config.Debug then
                print('^3[Vehicle Keys]^7 Remove keys not supported for:', VehicleKeys.Type)
            end
            return false
        end
    end
    
    if Config.Debug then
        print('^2[Vehicle Keys Bridge]^7 Client initialized for: ^3' .. VehicleKeys.Type .. '^7')
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- SERVER-SIDE FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

if IsDuplicityVersion() == 1 then -- Server-side only
    
    --- Give keys to player (server-side)
    --- @param source number Player server ID
    --- @param plate string Vehicle plate
    --- @param keyType string Key type: "temporary", "owned", "other_player"
    --- @param vehicle number Optional vehicle entity (if not provided, will try to get from player)
    --- @return boolean Success
    function VehicleKeys.GiveKeys(source, plate, keyType, vehicle)
        keyType = keyType or "temporary"
        
        -- Trim plate
        plate = plate:gsub("^%s*(.-)%s*$", "%1")
        
        if VehicleKeys.Type == 'jaksam' then
            -- jaksam vehicles_keys: Server export
            local success = pcall(function()
                exports["vehicles_keys"]:giveVehicleKeysToPlayerId(source, plate, keyType)
            end)
            
            if success then
                if Config.Debug then
                    print(string.format('^2[Vehicle Keys]^7 Gave keys to player %s: %s (%s)', 
                        source, plate, keyType))
                end
                return true
            else
                print('^1[Vehicle Keys]^7 ERROR: Failed to give keys (jaksam)!')
                return false
            end
        
        elseif VehicleKeys.Type == 'qs-vehiclekeys' then
            -- Quasar Vehicle Keys: Trigger client-side export
            -- qs-vehiclekeys doesn't have a server export, use client-side
            if not vehicle or vehicle == 0 then
                local ped = GetPlayerPed(source)
                vehicle = GetVehiclePedIsIn(ped, false)
            end
            
            if DoesEntityExist(vehicle) and vehicle ~= 0 then
                local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                TriggerClientEvent('hm-rental:client:giveKeysQS', source, plate, model)
                if Config.Debug then
                    print(string.format('^2[Vehicle Keys]^7 Gave keys to player %s: %s %s (qs-vehiclekeys)', 
                        source, plate, model))
                end
                return true
            else
                print('^1[Vehicle Keys]^7 ERROR: Player not in vehicle or vehicle not found!')
                return false
            end
            
        elseif VehicleKeys.Type == 'qb-vehiclekeys' or VehicleKeys.Type == 'qbx_vehiclekeys' then
            -- If vehicle not provided, try to get it from player
            if not vehicle or vehicle == 0 then
                local ped = GetPlayerPed(source)
                vehicle = GetVehiclePedIsIn(ped, false)
            end
            
            if DoesEntityExist(vehicle) and vehicle ~= 0 then
                if VehicleKeys.Type == 'qbx_vehiclekeys' then
                    -- QBX requires source FIRST, then vehicle entity
                    local success = pcall(function()
                        exports.qbx_vehiclekeys:GiveKeys(source, vehicle, false)
                    end)
                    if Config.Debug then
                        print(string.format('^2[Vehicle Keys]^7 Gave keys to player %s: %s (qbx_vehiclekeys) - %s | Vehicle: %s', 
                            source, plate, success and 'Success' or 'Failed', vehicle))
                    end
                    return success
                else
                    -- QB uses client event
                    TriggerClientEvent("vehiclekeys:client:SetOwner", source, plate)
                    if Config.Debug then
                        print(string.format('^2[Vehicle Keys]^7 Gave keys to player %s: %s (qb-vehiclekeys)', source, plate))
                    end
                    return true
                end
            else
                print('^1[Vehicle Keys]^7 ERROR: Player not in vehicle!')
                return false
            end
            
        elseif VehicleKeys.Type == 'none' then
            -- No key system
            return true
            
        else
            print('^3[Vehicle Keys]^7 Unknown key system:', VehicleKeys.Type)
            return false
        end
    end
    
    --- Remove keys from player (server-side)
    --- @param source number Player server ID
    --- @param plate string Vehicle plate
    --- @return boolean Success
    function VehicleKeys.RemoveKeys(source, plate)
        -- Trim plate
        plate = plate:gsub("^%s*(.-)%s*$", "%1")
        
        if VehicleKeys.Type == 'jaksam' then
            -- jaksam vehicles_keys: Server export
            local success = pcall(function()
                exports["vehicles_keys"]:removeVehicleKeysFromPlayerId(source, plate)
            end)
            
            if success then
                if Config.Debug then
                    print(string.format('^2[Vehicle Keys]^7 Removed keys from player %s: %s', 
                        source, plate))
                end
                return true
            else
                print('^1[Vehicle Keys]^7 ERROR: Failed to remove keys (jaksam)!')
                return false
            end
        
        elseif VehicleKeys.Type == 'qs-vehiclekeys' then
            -- Quasar Vehicle Keys: Trigger client-side removal
            TriggerClientEvent('hm-rental:client:removeKeysQS', source, plate)
            if Config.Debug then
                print(string.format('^2[Vehicle Keys]^7 Removed keys from player %s: %s (qs-vehiclekeys)', 
                    source, plate))
            end
            return true
            
        elseif VehicleKeys.Type == 'none' then
            -- No key system
            return true
            
        else
            print('^3[Vehicle Keys]^7 Remove not supported for:', VehicleKeys.Type)
            return false
        end
    end
    
    if Config.Debug then
        print('^2[Vehicle Keys Bridge]^7 Server initialized for: ^3' .. VehicleKeys.Type .. '^7')
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- DEBUG LOGGING
-- ══════════════════════════════════════════════════════════════════════════

if Config.Debug then
    print('^2[HM-Rental]^7 Vehicle Keys Bridge initialized: ^3' .. VehicleKeys.Type .. '^7')
end

return VehicleKeys
