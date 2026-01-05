-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - SHARED CONFIG
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAMEWORK & SYSTEM SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Framework = 'auto'    -- 'auto', 'qbox', 'qbcore', 'esx'
Config.Inventory = 'auto'    -- 'auto', 'ox_inventory', 'qb-inventory', 'tgiann-inventory'
Config.Target = 'auto'       -- 'auto', 'ox_target', 'qb-target', 'qtarget'
Config.Notify = 'ox_lib'     -- 'ox_lib', 'qbcore', 'esx', 'custom'
Config.VehicleKeys = 'qbx_vehiclekeys'  -- Oder 'none' wenn du es nicht nutzen willst
Config.VehicleKeyType = 'owned'         -- 'temporary' = nur fahren | 'owned' = volle Kontrolle (empfohlen!)

-- Debug Mode
Config.Debug = true  -- Enable for troubleshooting, disable in production

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

Config.Locale = 'de'  -- 'en', 'de'

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Rental = {
    -- Deposit system
    UseDeposit = true,           -- Require deposit when renting?
    DepositAmount = 50,          -- Deposit amount (returned on return)
    
    -- Rental fees
    RentalFeePerMinute = 2,      -- Fee per minute
    MaxRentalTime = 60,          -- Max rental time in minutes (0 = unlimited)
    
    -- Return settings
    ReturnAnywhere = true,       -- Can return at any station?
    ReturnPenalty = 25,          -- Penalty if not returned (lost deposit)
    
    -- Fuel/Battery
    SpawnFuel = 100,             -- Vehicle spawn fuel/battery level
    
    -- Lock status
    SpawnLockStatus = 1,         -- Lock status on spawn: 1 = Unlocked (recommended), 2 = Locked
    ForceUnlockAfterKeys = true, -- Force unlock after giving keys (recommended for better UX)
    
    -- Vehicle despawn
    DespawnOnReturn = true,      -- Delete vehicle on return?
    DespawnTimer = 5,            -- Minutes before auto-despawn if abandoned (0 = never)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- VEHICLE TYPES
-- ═══════════════════════════════════════════════════════════════════════════

Config.Vehicles = {
    -- Bicycles
    {
        type = 'bicycle',
        label = 'Fahrrad',
        model = 'bmx',
        price = 5,              -- Rental fee (one-time or per minute based on system)
        deposit = 25,
        icon = 'fas fa-bicycle',
        color = 'primary'
    },
    {
        type = 'bicycle',
        label = 'Mountainbike',
        model = 'tribike3',
        price = 8,
        deposit = 30,
        icon = 'fas fa-bicycle',
        color = 'success'
    },
    {
        type = 'bicycle',
        label = 'Rennrad',
        model = 'tribike',
        price = 10,
        deposit = 35,
        icon = 'fas fa-bicycle',
        color = 'warning'
    },
    
    -- Scooters
    {
        type = 'scooter',
        label = 'E-Scooter',
        model = 'faggio',
        price = 15,
        deposit = 50,
        icon = 'fas fa-motorcycle',
        color = 'info'
    },
    {
        type = 'automobile',
        label = 'Panto',
        model = 'panto',
        price = 20,
        deposit = 60,
        icon = 'fas fa-car',
        color = 'danger'
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL STATIONS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Stations = {
    -- Legion Square
    {
        name = 'Legion Square',
        coords = vector4(-957.25, -2704.92, 13.83, 87.96),
        blip = {
            enabled = true,
            sprite = 226,
            color = 3,
            scale = 0.7
        },
        ped = {
            enabled = true,
            model = 'a_m_y_hipster_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },
        vehicles = {'bicycle', 'scooter','automobile' },  -- Available types
        spawnPoints = {
            vector4(-960.29, -2709.98, 13.83, 8.93),
            vector4(-963.55, -2710.27, 13.83, 1.74),
            vector4(-961.62, -2699.33, 13.83, 146.61),
        }
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- PERMISSIONS (ACE or Job-based)
-- ═══════════════════════════════════════════════════════════════════════════

Config.Permissions = {
    -- Admin commands
    AdminCommand = {
        enabled = true,
        acePermission = 'hm-rental.admin',  -- ACE permission
        jobs = {'admin', 'god'},             -- Or job-based
    },
    
    -- Free rental for specific jobs
    FreeRental = {
        enabled = false,
        jobs = {'police', 'ambulance'}
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- UI SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.UI = {
    -- Blip settings (override per station)
    DefaultBlip = {
        sprite = 226,
        color = 3,
        scale = 0.7
    },
    
    -- Target settings
    Target = {
        icon = 'fas fa-bicycle',
        distance = 3.0
    },
    
    -- Ped settings
    DefaultPed = {
        model = 'a_m_y_hipster_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    
    -- Vehicle Lock/Unlock Settings
    VehicleLock = {
        showNotification = true,      -- Show OUR notification (set to false to use qbx_vehiclekeys notification instead)
        playLightAnimation = true,    -- Play indicator lights animation (Lichthupe)
        playHorn = true,              -- Play short horn sound
        lockRange = 5.0,              -- Distance to vehicle in meters
        
        -- Animation Settings
        animDict = 'anim@mp_player_intmenu@key_fob@',  -- Animation dictionary
        animName = 'fob_click_fp',                      -- Animation name (fob_click_fp = first person)
        keyProp = 'p_car_keys_01',                      -- Key prop model
        showKeyProp = true                               -- Show key prop in hand
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SECURITY SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Security = {
    -- Rate limiting
    RateLimit = {
        enabled = true,
        maxRequests = 10,      -- Max requests per minute
        banTime = 300          -- Ban time in seconds
    },
    
    -- Cooldown between rentals
    Cooldown = {
        enabled = true,
        seconds = 30           -- Cooldown in seconds
    },
    
    -- Distance validation
    MaxDistance = 10.0,        -- Max distance from station to rent
    
    -- Anti-exploit
    PreventDuplicateRental = true,  -- Prevent renting while already having vehicle
    PreventVehicleModding = true,   -- Prevent modding rental vehicles
}
