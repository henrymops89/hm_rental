-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - SERVER MAIN
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════════════════════════════════════

local ActiveRentals = {}      -- [source] = {vehicle, vehicleData, startTime, deposit, stationName}
local RentalStats = {
    totalRentals = 0,
    totalRevenue = 0
}
local PlayerCooldowns = {}    -- [source] = timestamp
local RateLimits = {}         -- [source] = {count, timestamp}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

--- Check if player has permission
--- @param source number Player source
--- @return boolean Has permission
local function hasAdminPermission(source)
    if not Config.Permissions.AdminCommand.enabled then return false end
    
    -- Check ACE permission
    if IsPlayerAceAllowed(source, Config.Permissions.AdminCommand.acePermission) then
        return true
    end
    
    -- Check job-based permission
    if Config.Permissions.AdminCommand.jobs then
        local playerJob = Framework.GetJob(source)
        for idx, job in ipairs(Config.Permissions.AdminCommand.jobs) do
            if playerJob == job then
                return true
            end
        end
    end
    
    return false
end

--- Check if player can rent for free
--- @param source number Player source
--- @return boolean Can rent free
local function canRentFree(source)
    if not Config.Permissions.FreeRental.enabled then return false end
    
    local playerJob = Framework.GetJob(source)
    for idx, job in ipairs(Config.Permissions.FreeRental.jobs) do
        if playerJob == job then
            return true
        end
    end
    
    return false
end

--- Check rate limit
--- @param source number Player source
--- @return boolean Within limit
local function checkRateLimit(source)
    if not Config.Security.RateLimit.enabled then return true end
    
    local currentTime = os.time()
    local limit = RateLimits[source]
    
    if not limit then
        RateLimits[source] = {count = 1, timestamp = currentTime}
        return true
    end
    
    -- Reset if minute passed
    if currentTime - limit.timestamp > 60 then
        RateLimits[source] = {count = 1, timestamp = currentTime}
        return true
    end
    
    -- Check if exceeded
    if limit.count >= Config.Security.RateLimit.maxRequests then
        return false
    end
    
    -- Increment
    limit.count = limit.count + 1
    return true
end

--- Check cooldown
--- @param source number Player source
--- @return boolean Can rent
local function checkCooldown(source)
    if not Config.Security.Cooldown.enabled then return true end
    
    local lastRental = PlayerCooldowns[source]
    if not lastRental then return true end
    
    local elapsed = os.time() - lastRental
    if elapsed < Config.Security.Cooldown.seconds then
        return false, Config.Security.Cooldown.seconds - elapsed
    end
    
    return true
end

--- Validate distance to station
--- @param source number Player source
--- @param stationName string Station name
--- @return boolean Valid distance
local function validateDistance(source, stationName)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    
    for idx, station in ipairs(Config.Stations) do
        if station.name == stationName then
            local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
            local distance = #(playerCoords - stationCoords)
            
            return distance <= Config.Security.MaxDistance
        end
    end
    
    return false
end

--- Get vehicle config by model
--- @param model string Vehicle model
--- @return table|nil Vehicle config
local function getVehicleConfig(model)
    for idx, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == model then
            return vehicle
        end
    end
    return nil
end

--- Calculate rental fee
--- @param startTime number Start timestamp
--- @param pricePerMinute number Price per minute
--- @return number Total fee
local function calculateRentalFee(startTime, pricePerMinute)
    local currentTime = os.time()
    local minutes = math.ceil((currentTime - startTime) / 60)
    return minutes * pricePerMinute
end

--- Find nearest station
--- @param coords vector3 Player coords
--- @return table|nil Station data
local function findNearestStation(coords)
    local nearest = nil
    local nearestDist = math.huge
    
    for idx, station in ipairs(Config.Stations) do
        local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
        local dist = #(coords - stationCoords)
        
        if dist < nearestDist then
            nearestDist = dist
            nearest = station
        end
    end
    
    return nearest, nearestDist
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

--- Rent vehicle
RegisterNetEvent('hm-rental:server:rentVehicle', function(vehicleModel, stationName)
    local source = source
    
    -- Guard: Rate limit check
    if not checkRateLimit(source) then
        Utils.NotifyError(source, _('notify.rate_limit'))
        return
    end
    
    -- Guard: Cooldown check
    local canRent, remainingTime = checkCooldown(source)
    if not canRent then
        Utils.NotifyError(source, _('notify.cooldown_active', remainingTime))
        return
    end
    
    -- Guard: Distance validation
    if not validateDistance(source, stationName) then
        Utils.NotifyError(source, _('notify.too_far_from_station'))
        return
    end
    
    -- Guard: Check if already renting
    if Config.Security.PreventDuplicateRental and ActiveRentals[source] then
        Utils.NotifyError(source, _('notify.already_renting'))
        return
    end
    
    -- Get vehicle config
    local vehicleConfig = getVehicleConfig(vehicleModel)
    if not vehicleConfig then
        Utils.NotifyError(source, _('notify.invalid_vehicle_type'))
        return
    end
    
    -- Check if free rental
    local isFree = canRentFree(source)
    local rentalCost = isFree and 0 or vehicleConfig.price
    local depositCost = (Config.Rental.UseDeposit and not isFree) and vehicleConfig.deposit or 0
    local totalCost = rentalCost + depositCost
    
    -- Guard: Money check
    if totalCost > 0 then
        local hasMoney = Framework.GetMoney(source, 'cash') >= totalCost
        if not hasMoney then
            Utils.NotifyError(source, _('notify.not_enough_money', totalCost))
            return
        end
        
        -- Remove money
        Framework.RemoveMoney(source, totalCost, 'cash')
    end
    
    -- Store rental data
    ActiveRentals[source] = {
        model = vehicleModel,
        vehicleData = vehicleConfig,
        startTime = os.time(),
        deposit = depositCost,
        stationName = stationName,
        rentalCost = rentalCost
    }
    
    -- Update cooldown
    PlayerCooldowns[source] = os.time()
    
    -- Update stats
    RentalStats.totalRentals = RentalStats.totalRentals + 1
    RentalStats.totalRevenue = RentalStats.totalRevenue + rentalCost
    
    -- Notify client to spawn vehicle
    TriggerClientEvent('hm-rental:client:spawnVehicle', source, vehicleModel, stationName)
    
    -- Notify success
    if depositCost > 0 then
        Utils.NotifySuccess(source, _('notify.rental_success_deposit', vehicleConfig.label, depositCost))
    else
        Utils.NotifySuccess(source, _('notify.rental_success', vehicleConfig.label, rentalCost))
    end
    
    if Config.Debug then
        print(string.format('^2[HM-Rental]^7 Player %s rented %s at %s (Cost: $%s, Deposit: $%s)', 
            source, vehicleModel, stationName, rentalCost, depositCost))
    end
end)

--- Return vehicle
RegisterNetEvent('hm-rental:server:returnVehicle', function(atStation)
    local source = source
    
    -- Guard: Check if has rental
    local rental = ActiveRentals[source]
    if not rental then
        Utils.NotifyError(source, _('notify.no_vehicle_rented'))
        return
    end
    
    -- Calculate total fee if time-based
    local totalFee = 0
    if Config.Rental.RentalFeePerMinute > 0 then
        totalFee = calculateRentalFee(rental.startTime, Config.Rental.RentalFeePerMinute)
        
        -- Deduct from deposit or charge player
        if rental.deposit >= totalFee then
            rental.deposit = rental.deposit - totalFee
        else
            local remaining = totalFee - rental.deposit
            rental.deposit = 0
            Framework.RemoveMoney(source, remaining, 'cash')
        end
    end
    
    -- Refund deposit
    local refundAmount = 0
    if atStation or Config.Rental.ReturnAnywhere then
        refundAmount = rental.deposit
        if refundAmount > 0 then
            Framework.AddMoney(source, refundAmount, 'cash')
            Utils.NotifySuccess(source, _('notify.return_success', refundAmount))
        else
            if totalFee > 0 then
                Utils.NotifySuccess(source, _('notify.return_with_fee', totalFee))
            else
                Utils.NotifySuccess(source, _('notify.return_success_no_deposit'))
            end
        end
    else
        -- Not at station and return anywhere is disabled
        Utils.NotifyError(source, _('notify.deposit_lost', rental.deposit))
        refundAmount = 0
    end
    
    -- Update revenue
    RentalStats.totalRevenue = RentalStats.totalRevenue + totalFee
    
    -- Clear rental
    ActiveRentals[source] = nil
    
    -- Notify client to delete vehicle
    TriggerClientEvent('hm-rental:client:deleteVehicle', source)
    
    if Config.Debug then
        print(string.format('^2[HM-Rental]^7 Player %s returned vehicle (Fee: $%s, Refund: $%s)', 
            source, totalFee, refundAmount))
    end
end)

--- Give vehicle keys to player
RegisterNetEvent('hm-rental:server:giveKeys', function(netId, plate)
    local src = source
    
    if Config.Debug then
        print('^3[HM-Rental DEBUG]^7 ==========================================')
        print('^3[HM-Rental DEBUG]^7 Giving keys to player:', src)
        print('^3[HM-Rental DEBUG]^7 Vehicle NetID:', netId)
        print('^3[HM-Rental DEBUG]^7 Vehicle Plate:', plate)
    end
    
    if Config.VehicleKeys ~= 'none' then
        -- Wait a bit to ensure network sync
        Wait(100)
        
        -- Convert NetID to server-side vehicle entity
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        
        if Config.Debug then
            print('^3[HM-Rental DEBUG]^7 Server Vehicle Entity:', vehicle)
            print('^3[HM-Rental DEBUG]^7 Vehicle Exists:', DoesEntityExist(vehicle))
            print('^3[HM-Rental DEBUG]^7 Entity Type:', GetEntityType(vehicle))
        end
        
        -- Verify it's a valid vehicle entity
        if DoesEntityExist(vehicle) and vehicle ~= 0 and GetEntityType(vehicle) == 2 then
            -- Use VehicleKeys bridge for proper multi-framework support
            -- Pass vehicle entity directly to bridge
            -- Use Config.VehicleKeyType or default to 'owned' for full functionality
            local keyType = Config.VehicleKeyType or 'owned'
            local success = VehicleKeys.GiveKeys(src, plate, keyType, vehicle)
            
            if Config.Debug then
                print('^2[HM-Rental]^7 Keys given via bridge:', success and 'Success' or 'Failed')
                print('^3[HM-Rental DEBUG]^7 ==========================================')
            end
            
            -- Notify client
            Wait(300)
            TriggerClientEvent('hm-rental:client:keysGiven', src)
            TriggerClientEvent('hm-rental:client:verifyKeys', src, vehicle, plate)
        else
            if Config.Debug then
                print('^1[HM-Rental]^7 Vehicle not found from NetID or invalid entity!')
                print('^1[HM-Rental DEBUG]^7 NetID was:', netId)
                print('^1[HM-Rental DEBUG]^7 Entity result was:', vehicle)
                print('^3[HM-Rental DEBUG]^7 ==========================================')
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

--- Get available vehicles at station
Framework.RegisterCallback('hm-rental:getVehicles', function(source, cb, stationName)
    local availableVehicles = {}
    
    -- Find station
    local station = nil
    for idx, s in ipairs(Config.Stations) do
        if s.name == stationName then
            station = s
            break
        end
    end
    
    if not station then
        cb({})
        return
    end
    
    -- Get vehicles for this station
    for idx, vehicle in ipairs(Config.Vehicles) do
        -- Check if vehicle type is available at station
        local isAvailable = false
        for idx, vtype in ipairs(station.vehicles) do
            if vtype == vehicle.type then
                isAvailable = true
                break
            end
        end
        
        if isAvailable then
            table.insert(availableVehicles, vehicle)
        end
    end
    
    cb(availableVehicles)
end)

--- Get current rental info
Framework.RegisterCallback('hm-rental:getRentalInfo', function(source, cb)
    local rental = ActiveRentals[source]
    if not rental then
        cb(nil)
        return
    end
    
    local currentFee = 0
    if Config.Rental.RentalFeePerMinute > 0 then
        currentFee = calculateRentalFee(rental.startTime, Config.Rental.RentalFeePerMinute)
    end
    
    local rentalTime = math.floor((os.time() - rental.startTime) / 60)
    
    cb({
        vehicle = rental.vehicleData.label,
        model = rental.model,
        time = rentalTime,
        cost = currentFee,
        deposit = rental.deposit
    })
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

--- Get rental statistics
RegisterCommand('rentalstats', function(source, args, rawCommand)
    if source == 0 or hasAdminPermission(source) then
        local activeCount = 0
        for _ in pairs(ActiveRentals) do
            activeCount = activeCount + 1
        end
        
        print('^2[HM-Rental]^7 ' .. _('commands.stats'))
        print('^2[HM-Rental]^7 ' .. _('commands.total_rentals', RentalStats.totalRentals))
        print('^2[HM-Rental]^7 ' .. _('commands.active_rentals', activeCount))
        print('^2[HM-Rental]^7 ' .. _('commands.total_revenue', RentalStats.totalRevenue))
        
        if source > 0 then
            Utils.NotifyInfo(source, _('commands.stats'))
        end
    end
end, false)

--- Force return all rentals (admin)
RegisterCommand('rentalreturnall', function(source, args, rawCommand)
    if source == 0 or hasAdminPermission(source) then
        local count = 0
        for playerId, rental in pairs(ActiveRentals) do
            TriggerClientEvent('hm-rental:client:deleteVehicle', playerId)
            ActiveRentals[playerId] = nil
            count = count + 1
        end
        
        print('^2[HM-Rental]^7 Returned ' .. count .. ' active rentals')
        if source > 0 then
            Utils.NotifySuccess(source, 'Returned ' .. count .. ' active rentals')
        end
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYER DISCONNECT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Clean up rental data
    if ActiveRentals[source] then
        if Config.Debug then
            print(string.format('^3[HM-Rental]^7 Player %s disconnected with active rental', source))
        end
        ActiveRentals[source] = nil
    end
    
    -- Clean up cooldowns
    PlayerCooldowns[source] = nil
    RateLimits[source] = nil
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    print('^2[HM-Rental]^7 Server initialized successfully')
    print('^2[HM-Rental]^7 Loaded ' .. #Config.Stations .. ' rental stations')
    print('^2[HM-Rental]^7 Loaded ' .. #Config.Vehicles .. ' vehicle types')
end)