-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - CLIENT MAIN
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════════════════════════════════════

local currentRentalVehicle = nil
local rentalBlips = {}
local rentalPeds = {}
local isNearStation = false
local currentStation = nil
local initialUnlockDone = false  -- Track if initial unlock after rental was done

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

--- Safely set blip name
--- @param blip number Blip handle
--- @param name string Blip name
--- @return boolean Success
local function setBlipName(blip, name)
    if not blip or not DoesBlipExist(blip) then
        return false
    end
    
    if not name or name == '' then
        name = 'Blip'
    end
    
    -- Ensure string is not too long (GTA limit is around 99)
    if #name > 99 then
        name = string.sub(name, 1, 99)
    end
    
    -- Use pcall for safety
    local success, err = pcall(function()
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(name)  -- Use this instead of AddTextComponentString!
        EndTextCommandSetBlipName(blip)
    end)
    
    if not success and Config.Debug then
        print('^1[HM-Rental]^7 Failed to set blip name:', err)
    end
    
    return success
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

--- Get spawn point at station
--- @param stationName string Station name
--- @return vector4|nil Spawn coords
local function getSpawnPoint(stationName)
    for idx, station in ipairs(Config.Stations) do
        if station.name == stationName then
            -- Find free spawn point
            for idx, spawnPoint in ipairs(station.spawnPoints) do
                local coords = vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)
                if not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 2.0) then
                    return spawnPoint
                end
            end
            -- If all occupied, use first one
            return station.spawnPoints[1]
        end
    end
    return nil
end

--- Check if near any station
--- @return boolean Near station
--- @return table|nil Station data
local function checkNearStation()
    local playerCoords = GetEntityCoords(cache.ped)
    
    for idx, station in ipairs(Config.Stations) do
        local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
        local distance = #(playerCoords - stationCoords)
        
        if distance <= Config.Security.MaxDistance then
            return true, station
        end
    end
    
    return false, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL MENU
-- ═══════════════════════════════════════════════════════════════════════════

--- Open rental menu
--- @param stationName string Station name
local function openRentalMenu(stationName)
    if Config.Debug then
        print('^2[HM-Rental]^7 Opening rental menu for station:', stationName)
    end
    
    -- Get available vehicles
    Framework.TriggerCallback('hm-rental:getVehicles', function(vehicles)
        if not vehicles or #vehicles == 0 then
            Utils.NotifyError(nil, _('notify.no_vehicles_available'))
            return
        end
        
        -- Build menu options
        local options = {}
        
        for idx, vehicle in ipairs(vehicles) do
            local deposit = Config.Rental.UseDeposit and vehicle.deposit or 0
            local totalCost = vehicle.price + deposit
            
            local description = _('menu.rental_fee') .. ': $' .. vehicle.price
            if Config.Rental.RentalFeePerMinute > 0 then
                description = description .. ' ' .. _('menu.per_minute')
            end
            if deposit > 0 then
                description = description .. '\n' .. _('menu.deposit') .. ': $' .. deposit
            end
            description = description .. '\n' .. _('menu.total_cost') .. ': $' .. totalCost
            
            table.insert(options, {
                title = vehicle.label,
                description = description,
                icon = vehicle.icon,
                iconColor = vehicle.color,
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('hm-rental:server:rentVehicle', vehicle.model, stationName)
                end
            })
        end
        
        -- Show rental info option if has active rental
        Framework.TriggerCallback('hm-rental:getRentalInfo', function(rentalInfo)
            if rentalInfo then
                table.insert(options, 1, {
                    title = _('menu.rental_info_title'),
                    description = _('menu.rental_info_vehicle', rentalInfo.vehicle) .. '\n' ..
                                _('menu.rental_info_time', rentalInfo.time) .. '\n' ..
                                _('menu.rental_info_cost', rentalInfo.cost) .. '\n' ..
                                _('menu.rental_info_deposit', rentalInfo.deposit),
                    icon = 'fas fa-info-circle',
                    iconColor = 'blue',
                    disabled = true
                })
            end
            
            -- Show menu
            lib.registerContext({
                id = 'hm_rental_menu',
                title = _('menu.title'),
                options = options
            })
            
            lib.showContext('hm_rental_menu')
        end)
    end, stationName)
end

--- Open return menu
local function openReturnMenu()
    if not currentRentalVehicle or not DoesEntityExist(currentRentalVehicle) then
        Utils.NotifyError(nil, _('notify.vehicle_not_found'))
        return
    end
    
    -- Check if at station
    local atStation, station = checkNearStation()
    
    -- Get rental info
    Framework.TriggerCallback('hm-rental:getRentalInfo', function(rentalInfo)
        if not rentalInfo then
            Utils.NotifyError(nil, _('notify.no_vehicle_rented'))
            return
        end
        
        local content = _('menu.return_text')
        if rentalInfo.deposit > 0 and atStation then
            content = content .. '\n' .. _('menu.return_deposit_info', rentalInfo.deposit)
        end
        if rentalInfo.cost > 0 then
            content = content .. '\n' .. _('menu.return_fee_info', rentalInfo.cost)
        end
        
        local alert = lib.alertDialog({
            header = _('menu.return_title'),
            content = content,
            centered = true,
            cancel = true,
            labels = {
                confirm = _('general.confirm'),
                cancel = _('general.cancel')
            }
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('hm-rental:server:returnVehicle', atStation)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VEHICLE SPAWNING
-- ═══════════════════════════════════════════════════════════════════════════

--- Spawn rental vehicle
--- @param model string Vehicle model
--- @param stationName string Station name
RegisterNetEvent('hm-rental:client:spawnVehicle', function(model, stationName)
    -- Get spawn point
    local spawnPoint = getSpawnPoint(stationName)
    if not spawnPoint then
        Utils.NotifyError(nil, _('notify.spawn_failed'))
        return
    end
    
    -- Request model
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        Utils.NotifyError(nil, _('notify.spawn_failed'))
        return
    end
    
    -- Create vehicle (networked for server-side key giving)
    local vehicle = CreateVehicle(
        modelHash,
        spawnPoint.x,
        spawnPoint.y,
        spawnPoint.z,
        spawnPoint.w,
        true,   -- Network the vehicle
        true    -- Make it a mission entity
    )
    
    -- Wait for network ID
    local timeout = 0
    while not NetworkGetEntityIsNetworked(vehicle) and timeout < 50 do
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(10)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(vehicle) then
        Utils.NotifyError(nil, _('notify.spawn_failed'))
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- Ensure vehicle is fully networked
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then
        if Config.Debug then
            print('^1[HM-Rental]^7 Failed to get valid NetID!')
        end
        DeleteVehicle(vehicle)
        Utils.NotifyError(nil, _('notify.spawn_failed'))
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    if Config.Debug then
        print('^3[HM-Rental CLIENT DEBUG]^7 Vehicle Entity:', vehicle)
        print('^3[HM-Rental CLIENT DEBUG]^7 Network ID:', netId)
        print('^3[HM-Rental CLIENT DEBUG]^7 Is Networked:', NetworkGetEntityIsNetworked(vehicle))
    end
    
    -- Set vehicle properties
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleFuelLevel(vehicle, Config.Rental.SpawnFuel + 0.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, false, false, false)
    
    -- Set lock status from config (default: 1 = Unlocked)
    local lockStatus = Config.Rental.SpawnLockStatus or 1
    SetVehicleDoorsLocked(vehicle, lockStatus)
    
    -- Set as rental vehicle
    SetEntityAsMissionEntity(vehicle, true, true)
    
    -- Store vehicle
    currentRentalVehicle = vehicle
    initialUnlockDone = false  -- Reset flag for new rental
    
    -- Get vehicle plate
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- Warp player into vehicle FIRST
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    Wait(1500)  -- Wait for player to be fully seated and synced
    
    -- Ensure vehicle keeps spawn lock status after warp
    SetVehicleDoorsLocked(vehicle, lockStatus)
    
    if Config.Debug then
        print('^2[HM-Rental]^7 Player seated in vehicle:', IsPedInVehicle(cache.ped, vehicle, false))
        print('^2[HM-Rental]^7 Vehicle plate:', plate)
        print('^2[HM-Rental]^7 Vehicle lock status:', GetVehicleDoorLockStatus(vehicle), '(1 = Unlocked)')
    end
    
    -- Request keys from server (using the NetID we verified earlier)
    if Config.VehicleKeys ~= 'none' then
        TriggerServerEvent('hm-rental:server:giveKeys', netId, plate)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    
    if Config.Debug then
        print('^2[HM-Rental]^7 Spawned rental vehicle:', model)
    end
end)

--- Delete rental vehicle
RegisterNetEvent('hm-rental:client:deleteVehicle', function()
    if currentRentalVehicle and DoesEntityExist(currentRentalVehicle) then
        -- Remove player from vehicle if inside
        local playerPed = cache.ped
        if IsPedInVehicle(playerPed, currentRentalVehicle, false) then
            TaskLeaveVehicle(playerPed, currentRentalVehicle, 0)
            Wait(1000)
        end
        
        -- Delete vehicle
        if Config.Rental.DespawnOnReturn then
            SetEntityAsMissionEntity(currentRentalVehicle, true, true)
            DeleteVehicle(currentRentalVehicle)
        end
        
        currentRentalVehicle = nil
        initialUnlockDone = false  -- Reset flag for next rental
        
        if Config.Debug then
            print('^2[HM-Rental]^7 Deleted rental vehicle')
        end
    end
end)

--- Verify keys received (debug)
RegisterNetEvent('hm-rental:client:verifyKeys', function(serverVehicle, plate)
    if Config.Debug then
        Wait(500)
        print('^3[HM-Rental CLIENT DEBUG]^7 ==========================================')
        print('^3[HM-Rental CLIENT DEBUG]^7 Verifying keys for plate:', plate)
        print('^3[HM-Rental CLIENT DEBUG]^7 Server sent vehicle entity:', serverVehicle)
        print('^3[HM-Rental CLIENT DEBUG]^7 Client rental vehicle entity:', currentRentalVehicle)
        
        -- IMPORTANT: Use currentRentalVehicle (client entity), NOT serverVehicle!
        local vehicleToCheck = currentRentalVehicle or GetVehiclePedIsIn(cache.ped, false)
        
        if not DoesEntityExist(vehicleToCheck) or vehicleToCheck == 0 then
            print('^1[HM-Rental CLIENT DEBUG]^7 No valid vehicle to check!')
            print('^3[HM-Rental CLIENT DEBUG]^7 ==========================================')
            return
        end
        
        print('^3[HM-Rental CLIENT DEBUG]^7 Checking vehicle entity:', vehicleToCheck)
        
        -- Try to check if we have keys
        local hasKeys = false
        local checkSuccess, result = pcall(function()
            return exports.qbx_vehiclekeys:HasKeys(vehicleToCheck)
        end)
        
        if checkSuccess then
            hasKeys = result
            print('^3[HM-Rental CLIENT DEBUG]^7 HasKeys result:', hasKeys)
        else
            print('^1[HM-Rental CLIENT DEBUG]^7 HasKeys check failed:', result)
        end
        
        print('^3[HM-Rental CLIENT DEBUG]^7 Vehicle locked:', GetVehicleDoorLockStatus(vehicle))
        print('^3[HM-Rental CLIENT DEBUG]^7 ==========================================')
    end
end)

--- Keys successfully given by server
RegisterNetEvent('hm-rental:client:keysGiven', function()
    -- Force unlock vehicle after keys are given (ONLY ONCE per rental!)
    -- Some key systems automatically LOCK the vehicle when giving keys
    if Config.Rental.ForceUnlockAfterKeys and not initialUnlockDone and currentRentalVehicle and DoesEntityExist(currentRentalVehicle) then
        Wait(200) -- Wait for key system to finish
        SetVehicleDoorsLocked(currentRentalVehicle, 1) -- Force UNLOCK
        initialUnlockDone = true  -- Mark as done, don't unlock again!
        
        if Config.Debug then
            print('^2[HM-Rental]^7 Initial unlock after rental (ForceUnlockAfterKeys = true)')
            print('^2[HM-Rental]^7 Lock status:', GetVehicleDoorLockStatus(currentRentalVehicle), '(1 = Unlocked)')
            print('^2[HM-Rental]^7 This will only happen ONCE - normal lock/unlock works now!')
        end
    end
    
    if Config.Debug then
        Wait(500)
        
        local vehicleToCheck = currentRentalVehicle or GetVehiclePedIsIn(cache.ped, false)
        
        if DoesEntityExist(vehicleToCheck) and vehicleToCheck ~= 0 then
            -- Check if keys were properly given
            local hasKeys = false
            local checkSuccess, result = pcall(function()
                if Config.VehicleKeys == 'qs-vehiclekeys' then
                    local plate = GetVehicleNumberPlateText(vehicleToCheck):gsub("^%s*(.-)%s*$", "%1")
                    return exports['qs-vehiclekeys']:GetKey(plate)
                elseif Config.VehicleKeys == 'qbx_vehiclekeys' then
                    return exports.qbx_vehiclekeys:HasKeys(vehicleToCheck)
                else
                    return true
                end
            end)
            
            if checkSuccess then
                hasKeys = result
            end
            
            print('^2[HM-Rental]^7 Keys confirmation - HasKeys:', hasKeys)
            
            if not hasKeys then
                print('^1[HM-Rental]^7 WARNING: Keys not confirmed!')
                print('^1[HM-Rental]^7 Try /checkkeys to verify')
            end
        end
    end
end)

--- Give keys for qs-vehiclekeys (client-side)
RegisterNetEvent('hm-rental:client:giveKeysQS', function(plate, model)
    if Config.Debug then
        print('^3[HM-Rental]^7 Giving qs-vehiclekeys keys:', plate, model)
    end
    
    exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    
    -- Force unlock vehicle after giving keys (ONLY ONCE per rental!)
    if Config.Rental.ForceUnlockAfterKeys and not initialUnlockDone then
        local vehicle = currentRentalVehicle or GetVehiclePedIsIn(cache.ped, false)
        if DoesEntityExist(vehicle) and vehicle ~= 0 then
            Wait(200)
            SetVehicleDoorsLocked(vehicle, 1) -- Force UNLOCK
            initialUnlockDone = true  -- Mark as done!
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Initial unlock after qs-vehiclekeys (ForceUnlockAfterKeys = true)')
                print('^2[HM-Rental]^7 This will only happen ONCE - normal lock/unlock works now!')
            end
        end
    end
    
    if Config.Debug then
        Wait(200)
        local checkVehicle = currentRentalVehicle or GetVehiclePedIsIn(cache.ped, false)
        if DoesEntityExist(checkVehicle) and checkVehicle ~= 0 then
            local hasKeys = exports['qs-vehiclekeys']:GetKey(plate)
            print('^2[HM-Rental]^7 qs-vehiclekeys HasKeys:', hasKeys)
            print('^2[HM-Rental]^7 Lock status:', GetVehicleDoorLockStatus(checkVehicle), '(1 = Unlocked)')
        end
    end
end)

--- Remove keys for qs-vehiclekeys (client-side)
RegisterNetEvent('hm-rental:client:removeKeysQS', function(plate)
    if Config.Debug then
        print('^3[HM-Rental]^7 Removing qs-vehiclekeys keys:', plate)
    end
    
    local vehicle = currentRentalVehicle or GetVehiclePedIsIn(cache.ped, false)
    if DoesEntityExist(vehicle) and vehicle ~= 0 then
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
        
        if Config.Debug then
            print('^2[HM-Rental]^7 qs-vehiclekeys keys removed:', plate, model)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET SYSTEM SETUP
-- ═══════════════════════════════════════════════════════════════════════════

--- Setup station targets
local function setupStationTargets()
    if Config.Debug then
        print('^2[HM-Rental]^7 Setting up station targets...')
    end
    
    for idx, station in ipairs(Config.Stations) do
        if Config.Debug then
            print('^2[HM-Rental]^7 Processing station:', station.name)
            print('^2[HM-Rental]^7 Ped enabled:', station.ped and station.ped.enabled or false)
        end
        
        -- Spawn ped if enabled
        if station.ped and station.ped.enabled then
            local pedModel = GetHashKey(station.ped.model)
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Requesting ped model:', station.ped.model, 'Hash:', pedModel)
            end
            
            RequestModel(pedModel)
            local timeout = 0
            while not HasModelLoaded(pedModel) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
            
            if not HasModelLoaded(pedModel) then
                print('^1[HM-Rental]^7 Failed to load ped model:', station.ped.model)
                goto continue
            end
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Model loaded, creating ped at:', station.coords)
            end
            
            -- Create ped using vector4 (xyz for coords, w for heading)
            local ped = CreatePed(4, pedModel, station.coords.xyz, station.coords.w, false, true)
            
            if not DoesEntityExist(ped) then
                print('^1[HM-Rental]^7 Failed to create ped for station:', station.name)
                SetModelAsNoLongerNeeded(pedModel)
                goto continue
            end
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Ped created successfully, entity ID:', ped)
            end
            
            -- Set ped properties
            SetEntityAsMissionEntity(ped, true, true)
            FreezeEntityPosition(ped, false)  -- Allow ped to rotate/move naturally
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskSetBlockingOfNonTemporaryEvents(ped, true)
            
            -- Prevent ped from being removed
            SetPedCanBeTargetted(ped, false)
            SetPedCanRagdoll(ped, false)
            
            -- Set scenario
            if station.ped.scenario then
                if Config.Debug then
                    print('^2[HM-Rental]^7 Starting scenario:', station.ped.scenario)
                end
                TaskStartScenarioInPlace(ped, station.ped.scenario, 0, true)
            end
            
            -- Add target
            Target.AddPed(ped, {
                {
                    name = 'rental_open_' .. station.name,
                    label = (Lang and Lang.rental and Lang.rental.open_station) and _('rental.open_station') or 'Rent Vehicle',
                    icon = 'fas fa-bicycle',
                    distance = Config.UI.Target.distance,
                    onSelect = function()
                        openRentalMenu(station.name)
                    end
                },
                {
                    name = 'rental_return_' .. station.name,
                    label = (Lang and Lang.rental and Lang.rental.return_vehicle) and _('rental.return_vehicle') or 'Return Vehicle',
                    icon = 'fas fa-undo',
                    distance = Config.UI.Target.distance,
                    canInteract = function()
                        return currentRentalVehicle ~= nil and DoesEntityExist(currentRentalVehicle)
                    end,
                    onSelect = function()
                        openReturnMenu()
                    end
                }
            })
            
            rentalPeds[station.name] = ped
            SetModelAsNoLongerNeeded(pedModel)
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Ped setup complete for:', station.name)
            end
        end
        
        ::continue::
    end
    
    if Config.Debug then
        print('^2[HM-Rental]^7 Created', #rentalPeds, 'peds')
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BLIPS
-- ═══════════════════════════════════════════════════════════════════════════

--- Create station blips
local function createBlips()
    if Config.Debug then
        print('^2[HM-Rental]^7 Creating blips...')
    end
    
    for i, station in ipairs(Config.Stations) do
        if station.blip and station.blip.enabled then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            
            SetBlipSprite(blip, station.blip.sprite or Config.UI.DefaultBlip.sprite)
            SetBlipColour(blip, station.blip.color or Config.UI.DefaultBlip.color)
            SetBlipScale(blip, station.blip.scale or Config.UI.DefaultBlip.scale)
            SetBlipAsShortRange(blip, true)
            
            -- Get blip name (with fallback if locale not loaded yet)
            local blipName = 'Vehicle Rental'  -- Fallback
            if Lang and Lang.blips and Lang.blips.rental then
                blipName = Lang.blips.rental  -- Direct access
            end
            
            -- Add station name
            local finalName = blipName
            if station.name and station.name ~= '' then
                finalName = blipName .. ' - ' .. station.name
            end
            
            -- Set name using safe wrapper
            setBlipName(blip, finalName)
            
            rentalBlips[station.name] = blip
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Created blip for:', station.name)
            end
        end
    end
    
    if Config.Debug then
        print('^2[HM-Rental]^7 Finished creating blips')
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════════════════════════════════

--- Return vehicle keybind
RegisterCommand('+returnrental', function()
    if currentRentalVehicle and DoesEntityExist(currentRentalVehicle) then
        openReturnMenu()
    end
end, false)

RegisterKeyMapping('+returnrental', 'Return Rental Vehicle', 'keyboard', 'F7')

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCK/UNLOCK WORKAROUND (falls qbx_vehiclekeys Keybind nicht funktioniert)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand('+togglevehiclelock', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, Config.UI.VehicleLock.lockRange, false)
    
    if not vehicle then
        if Config.Debug then
            print('^3[HM-Rental]^7 No vehicle nearby to lock/unlock')
        end
        return
    end
    
    -- Check if we have keys
    local hasKeys = false
    local success, result = pcall(function()
        if Config.VehicleKeys == 'qs-vehiclekeys' then
            local plate = GetVehicleNumberPlateText(vehicle):gsub("^%s*(.-)%s*$", "%1")
            return exports['qs-vehiclekeys']:GetKey(plate)
        elseif Config.VehicleKeys == 'qbx_vehiclekeys' then
            return exports.qbx_vehiclekeys:HasKeys(vehicle)
        else
            -- For other systems, assume we have keys
            return true
        end
    end)
    
    if success then
        hasKeys = result
    end
    
    if not success or not hasKeys then
        if Config.Debug then
            print('^3[HM-Rental]^7 No keys for this vehicle!')
        end
        Utils.NotifyError(nil, 'You don\'t have keys for this vehicle')
        return
    end
    
    -- Toggle lock
    local currentStatus = GetVehicleDoorLockStatus(vehicle)
    local newStatus = (currentStatus == 1) and 2 or 1
    
    SetVehicleDoorsLocked(vehicle, newStatus)
    
    -- Get vehicle class for appropriate effects
    local vehicleClass = GetVehicleClass(vehicle)
    local isMotorcycle = (vehicleClass == 8 or vehicleClass == 13) -- Motorcycles & Cycles
    
    -- Play animation with key prop
    if not IsPedInAnyVehicle(ped, false) then
        local animDict = Config.UI.VehicleLock.animDict
        local animName = Config.UI.VehicleLock.animName
        
        -- Load animation dictionary
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(10)
        end
        
        -- Spawn and attach key prop (if enabled)
        local keyProp = nil
        if Config.UI.VehicleLock.showKeyProp then
            local propModel = GetHashKey(Config.UI.VehicleLock.keyProp)
            
            RequestModel(propModel)
            while not HasModelLoaded(propModel) do
                Wait(10)
            end
            
            -- Create key prop
            keyProp = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, false)
            
            -- Attach to right hand
            local boneIndex = GetPedBoneIndex(ped, 57005) -- Right hand bone
            AttachEntityToEntity(
                keyProp, ped, boneIndex,
                0.09, 0.03, -0.02,  -- Offset
                -76.0, 13.0, 28.0,  -- Rotation
                true, true, false, true, 1, true
            )
            
            SetModelAsNoLongerNeeded(propModel)
        end
        
        -- Play animation (with proper flags: NO LOOP, stoppable)
        -- Flag 48 = Upper body only, can be interrupted
        -- Duration 1000ms to auto-stop
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 1000, 48, 0, false, false, false)
        
        -- Cleanup animation and prop after duration
        CreateThread(function()
            Wait(1200) -- Slightly longer than animation
            
            -- Force stop animation if still playing
            if IsEntityPlayingAnim(ped, animDict, animName, 3) then
                ClearPedTasks(ped)
            end
            
            -- Delete prop
            if keyProp and DoesEntityExist(keyProp) then
                DeleteObject(keyProp)
                keyProp = nil
            end
        end)
    end
    
    -- Play sound
    local soundName = (newStatus == 2) and 'lock' or 'unlock'
    PlaySoundFromEntity(-1, soundName, vehicle, 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0)
    
    -- Vehicle lights animation - different for motorcycles vs cars
    if Config.UI.VehicleLock.playLightAnimation or Config.UI.VehicleLock.playHorn then
        CreateThread(function()
            -- Kurze Hupe (if enabled)
            if Config.UI.VehicleLock.playHorn then
                StartVehicleHorn(vehicle, 200, `HELDDOWN`, false)
            end
            
            -- Light animation (only for cars, not motorcycles)
            if Config.UI.VehicleLock.playLightAnimation and not isMotorcycle then
                -- Cars: Blinker animation
                for i = 1, 2 do
                    SetVehicleIndicatorLights(vehicle, 0, true)  -- Links
                    SetVehicleIndicatorLights(vehicle, 1, true)  -- Rechts
                    Wait(150)
                    SetVehicleIndicatorLights(vehicle, 0, false)
                    SetVehicleIndicatorLights(vehicle, 1, false)
                    Wait(150)
                end
            elseif Config.UI.VehicleLock.playLightAnimation and isMotorcycle then
                -- Motorcycles: Flash headlights instead
                for i = 1, 3 do
                    SetVehicleLights(vehicle, 2)  -- Lights on
                    Wait(100)
                    SetVehicleLights(vehicle, 0)  -- Lights off/normal
                    Wait(100)
                end
            end
        end)
    end
    
    -- Show notification (only once!)
    if Config.UI.VehicleLock.showNotification then
        -- Smart notification: If qbx_vehiclekeys is active and it's a car,
        -- qbx will show its own notification, so we skip ours to avoid duplicates
        local showOurNotification = true
        
        if Config.VehicleKeys == 'qbx_vehiclekeys' and not isMotorcycle then
            -- It's a car and qbx is active - qbx will show notification
            -- Skip ours to avoid duplicate
            showOurNotification = false
            
            if Config.Debug then
                print('^3[HM-Rental]^7 Skipping our notification (qbx will show for cars)')
            end
        end
        
        if showOurNotification then
            local message = (newStatus == 2) and _('notify.vehicle_locked') or _('notify.vehicle_unlocked')
            lib.notify({
                title = (newStatus == 2) and '🔒 Abgeschlossen' or '🔓 Aufgeschlossen',
                description = message,
                type = 'success',
                duration = 2000,
                position = 'top'
            })
        end
    end
    
    if Config.Debug then
        local message = (newStatus == 2) and 'Vehicle locked' or 'Vehicle unlocked'
        local vehType = isMotorcycle and 'Motorcycle' or 'Car'
        print('^2[HM-Rental]^7 ' .. message .. ' - Status:', newStatus, '- Type:', vehType)
    end
end, false)

RegisterKeyMapping('+togglevehiclelock', 'Lock/Unlock Vehicle', 'keyboard', 'U')

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand('checkstations', function()
    print('^3[HM-Rental DEBUG]^7 ==========================================')
    print('^3[HM-Rental DEBUG]^7 Config.Stations:', Config.Stations ~= nil)
    
    if Config.Stations then
        print('^3[HM-Rental DEBUG]^7 Number of stations:', #Config.Stations)
        
        for i, station in ipairs(Config.Stations) do
            print('^3[HM-Rental DEBUG]^7 Station ' .. i .. ':')
            print('  Name:', station.name)
            print('  Coords:', station.coords)
            print('  Blip enabled:', station.blip and station.blip.enabled or false)
            print('  PED enabled:', station.ped and station.ped.enabled or false)
        end
    else
        print('^1[HM-Rental DEBUG]^7 Config.Stations is NIL!')
    end
    
    print('^3[HM-Rental DEBUG]^7 Blips created:', #rentalBlips)
    print('^3[HM-Rental DEBUG]^7 PEDs created:', #rentalPeds)
    print('^3[HM-Rental DEBUG]^7 ==========================================')
end, false)

RegisterCommand('checkkeys', function()
    if not Config.Debug then return end
    
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if vehicle == 0 then
        print('^1[HM-Rental]^7 You are not in a vehicle!')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    print('^3[HM-Rental DEBUG]^7 ==========================================')
    print('^3[HM-Rental DEBUG]^7 Current Vehicle:', vehicle)
    print('^3[HM-Rental DEBUG]^7 Vehicle Plate:', plate)
    print('^3[HM-Rental DEBUG]^7 Vehicle Lock Status:', GetVehicleDoorLockStatus(vehicle))
    
    -- Check if we have keys
    local hasKeys = false
    local checkSuccess, result = pcall(function()
        if Config.VehicleKeys == 'qs-vehiclekeys' then
            local trimmedPlate = plate:gsub("^%s*(.-)%s*$", "%1")
            return exports['qs-vehiclekeys']:GetKey(trimmedPlate)
        elseif Config.VehicleKeys == 'qbx_vehiclekeys' then
            return exports.qbx_vehiclekeys:HasKeys(vehicle)
        else
            return true  -- For other systems
        end
    end)
    
    if checkSuccess then
        hasKeys = result
        print('^3[HM-Rental DEBUG]^7 HasKeys result:', hasKeys)
        print('^3[HM-Rental DEBUG]^7 Key System:', Config.VehicleKeys)
    else
        print('^1[HM-Rental DEBUG]^7 HasKeys check failed!')
    end
    
    print('^3[HM-Rental DEBUG]^7 Is Rental Vehicle:', currentRentalVehicle == vehicle)
    print('^3[HM-Rental DEBUG]^7 ==========================================')
end, false)

RegisterCommand('testlock', function()
    if not Config.Debug then return end
    
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if vehicle == 0 then
        print('^1[HM-Rental]^7 You are not in a vehicle!')
        return
    end
    
    local currentStatus = GetVehicleDoorLockStatus(vehicle)
    print('^3[HM-Rental DEBUG]^7 Current Lock Status:', currentStatus)
    
    -- Try to toggle
    if currentStatus == 1 then
        SetVehicleDoorsLocked(vehicle, 2)
        print('^2[HM-Rental DEBUG]^7 Set to LOCKED (2)')
    else
        SetVehicleDoorsLocked(vehicle, 1)
        print('^2[HM-Rental DEBUG]^7 Set to UNLOCKED (1)')
    end
    
    Wait(100)
    print('^3[HM-Rental DEBUG]^7 New Lock Status:', GetVehicleDoorLockStatus(vehicle))
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- RESOURCE START/STOP
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- RESOURCE START/STOP HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Initialize when player spawns (works for both server start AND players joining after!)
CreateThread(function()
    -- Wait for player to spawn
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    
    -- Player is now spawned, initialize stations
    if Config.Debug then
        print('^2[HM-Rental]^7 Player spawned, initializing stations...')
    end
    
    Wait(2000) -- Give some time for everything to load
    
    -- Create blips
    createBlips()
    
    -- Setup targets
    setupStationTargets()
    
    if Config.Debug then
        print('^2[HM-Rental]^7 Stations initialized for player')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Delete rental vehicle
    if currentRentalVehicle and DoesEntityExist(currentRentalVehicle) then
        DeleteVehicle(currentRentalVehicle)
    end
    
    -- Remove blips
    for name, blip in pairs(rentalBlips) do
        RemoveBlip(blip)
    end
    
    -- Remove peds
    for name, ped in pairs(rentalPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    print('^2[HM-Rental]^7 Client shutdown')
end)