Locale = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- GENERAL
-- ═══════════════════════════════════════════════════════════════════════════

Locale.general = {
    press_to_interact = '[E] Interact',
    loading = 'Loading...',
    processing = 'Processing...',
    cancel = 'Cancel',
    confirm = 'Confirm',
    close = 'Close',
    back = 'Back',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════

Locale.notify = {
    -- Success
    rental_success = 'You rented a %s for $%s!',
    rental_success_deposit = 'You rented a %s! Deposit: $%s',
    return_success = 'Vehicle returned! Deposit refunded: $%s',
    return_success_no_deposit = 'Vehicle returned successfully!',
    return_with_fee = 'Vehicle returned! Rental fee: $%s',
    
    -- Errors
    not_enough_money = 'Not enough money! Required: $%s',
    already_renting = 'You already have a rented vehicle!',
    no_vehicle_rented = 'You don\'t have a rented vehicle!',
    not_rental_vehicle = 'This is not a rental vehicle!',
    too_far_from_station = 'You are too far from a station!',
    vehicle_not_found = 'Vehicle not found!',
    spawn_failed = 'Failed to spawn vehicle!',
    invalid_vehicle_type = 'Invalid vehicle type!',
    cooldown_active = 'Please wait %s seconds before renting again!',
    rate_limit = 'Too many requests! Please wait a moment.',
    deposit_lost = 'Deposit forfeited: $%s (Vehicle not returned at station)',
    
    -- Info
    no_vehicles_available = 'No vehicles available',
    
    -- Vehicle Lock/Unlock
    vehicle_locked = 'Vehicle locked',
    vehicle_unlocked = 'Vehicle unlocked',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MENU
-- ═══════════════════════════════════════════════════════════════════════════

Locale.menu = {
    -- Main menu
    title = 'Vehicle Rental',
    subtitle = 'Choose a vehicle to rent',
    
    -- Vehicle selection
    select_vehicle = 'Select Vehicle',
    rent_now = 'Rent Now',
    rental_fee = 'Rental Fee',
    deposit = 'Deposit',
    total_cost = 'Total Cost',
    per_minute = 'per minute',
    one_time = 'One-time',
    available = 'Available',
    rented = 'Rented',
    
    -- Return
    return_title = 'Return Vehicle?',
    return_text = 'Do you want to return the vehicle?',
    return_deposit_info = 'You will receive your deposit of $%s back.',
    return_fee_info = 'Rental fee: $%s',
    
    -- Current rental info
    rental_info_title = 'Currently Rented',
    rental_info_vehicle = 'Vehicle: %s',
    rental_info_time = 'Rental Time: %s minutes',
    rental_info_cost = 'Cost so far: $%s',
    rental_info_deposit = 'Deposit: $%s',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL / STATION
-- ═══════════════════════════════════════════════════════════════════════════

Locale.rental = {
    open_station = 'Rent Vehicle',
    return_vehicle = 'Return Vehicle',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- VEHICLES
-- ═══════════════════════════════════════════════════════════════════════════

Locale.vehicles = {
    -- Bicycles
    bicycle = {
        name = 'Bicycle',
        desc = 'Standard bicycle',
    },
    mountainbike = {
        name = 'Mountain Bike',
        desc = 'Rugged mountain bike',
    },
    racer = {
        name = 'Racing Bike',
        desc = 'Fast racing bike',
    },
    
    -- Scooters
    scooter = {
        name = 'E-Scooter',
        desc = 'Electric scooter',
    },
    sport_scooter = {
        name = 'Sport Scooter',
        desc = 'Fast sport scooter',
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

Locale.commands = {
    -- Statistics
    stats = 'Rental Statistics',
    total_rentals = 'Total Rentals: %s',
    active_rentals = 'Active Rentals: %s',
    total_revenue = 'Total Revenue: $%s',
    
    -- Station management
    spawned_station = 'Rental station created: %s',
    removed_station = 'Rental station removed: %s',
    no_station = 'No station found nearby!',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BLIPS
-- ═══════════════════════════════════════════════════════════════════════════

Locale.blips = {
    rental = 'Vehicle Rental',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- TIME FORMATTING
-- ═══════════════════════════════════════════════════════════════════════════

Locale.time = {
    minutes_short = 'min',
    seconds_short = 'sec',
}

return Locale
