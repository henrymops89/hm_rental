-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - MANIFEST
-- ═══════════════════════════════════════════════════════════════════════════

fx_version 'cerulean'
game 'gta5'

lua54 'yes'  -- ⚠️ REQUIRED for CFX Asset Escrow!

author 'MopsScripts <henry.mops89@gmail.com>'
description 'Professional bike and scooter rental system with multi-framework support'
version '1.0.0'

-- ═══════════════════════════════════════════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════════════════════════════════════════

dependencies {
    'ox_lib',
    -- Framework dependencies (uncomment your framework!)
    '/server:7290',  -- Require at least server build 7290
    '/onesync',      -- Require OneSync (recommended)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- OX_LIB MODULES
-- ═══════════════════════════════════════════════════════════════════════════

ox_libs {
    'callback'
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locale.lua',    -- ✅ Locale system
    'locales/*.lua',         -- ✅ Locale files
    'bridge/framework.lua',
    'bridge/inventory.lua',
    'bridge/target.lua',
    'bridge/utils.lua',
    'bridge/vehicle_keys.lua'
}

-- ═══════════════════════════════════════════════════════════════════════════
-- CLIENT SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════

client_scripts {
    'client/main.lua',
    'client/exports.lua'
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVER SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════════

server_scripts {
    'server/sv_config.lua',  -- ⚠️ Load first for secrets
    'server/main.lua',
    'server/exports.lua'
}

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Client exports
exports {
    'getCurrentRentalVehicle',
    'hasActiveRental'
}

-- Server exports
server_exports {
    'GetActiveRentals',
    'GetRentalStats'
}
