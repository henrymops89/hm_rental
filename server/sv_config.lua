-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - SERVER SECRETS
-- ═══════════════════════════════════════════════════════════════════════════
-- ⚠️ CRITICAL: NEVER share this file or commit to public repositories!
-- ═══════════════════════════════════════════════════════════════════════════

local ServerSecrets = {
    -- Discord Webhook (optional for logging)
    DiscordWebhook = '',  -- Leave empty if not using
    
    -- Enable Discord logging
    EnableDiscordLogs = false,
    
    -- Log rental actions to Discord
    LogRentals = true,
    LogReturns = true,
    LogAdminCommands = true,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- DISCORD LOGGING FUNCTION
-- ═══════════════════════════════════════════════════════════════════════════

--- Send log to Discord
--- @param title string Log title
--- @param description string Log description
--- @param color number Embed color
local function sendDiscordLog(title, description, color)
    if not ServerSecrets.EnableDiscordLogs or ServerSecrets.DiscordWebhook == '' then
        return
    end
    
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color or 3447003,
            ['footer'] = {
                ['text'] = 'HM Rental System',
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S'),
        }
    }
    
    PerformHttpRequest(ServerSecrets.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = 'HM Rental',
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOGGING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

if ServerSecrets.EnableDiscordLogs then
    -- Log rental
    RegisterNetEvent('hm-rental:server:logRental', function(playerName, vehicleLabel, stationName, cost)
        if not ServerSecrets.LogRentals then return end
        
        sendDiscordLog(
            '🛴 Vehicle Rented',
            string.format('**Player:** %s\n**Vehicle:** %s\n**Station:** %s\n**Cost:** $%s',
                playerName, vehicleLabel, stationName, cost),
            3066993  -- Green
        )
    end)
    
    -- Log return
    RegisterNetEvent('hm-rental:server:logReturn', function(playerName, vehicleLabel, fee, deposit)
        if not ServerSecrets.LogReturns then return end
        
        sendDiscordLog(
            '↩️ Vehicle Returned',
            string.format('**Player:** %s\n**Vehicle:** %s\n**Fee:** $%s\n**Deposit Refund:** $%s',
                playerName, vehicleLabel, fee, deposit),
            10181046  -- Blue
        )
    end)
    
    -- Log admin command
    RegisterNetEvent('hm-rental:server:logAdmin', function(playerName, command, details)
        if not ServerSecrets.LogAdminCommands then return end
        
        sendDiscordLog(
            '⚙️ Admin Command',
            string.format('**Admin:** %s\n**Command:** %s\n**Details:** %s',
                playerName, command, details),
            15158332  -- Red
        )
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ALTERNATIVE: CONVARS (Recommended for production)
-- ═══════════════════════════════════════════════════════════════════════════

-- You can also use server.cfg convars instead:
-- setr hm_rental_webhook "your-webhook-url-here"
-- setr hm_rental_enable_logs "true"

-- Then access with:
-- local webhook = GetConvar('hm_rental_webhook', '')
-- local enableLogs = GetConvar('hm_rental_enable_logs', 'false') == 'true'

return ServerSecrets
