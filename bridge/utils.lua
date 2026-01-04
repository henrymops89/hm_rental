-- ██╗   ██╗████████╗██╗██╗     ███████╗
-- ██║   ██║╚══██╔══╝██║██║     ██╔════╝
-- ██║   ██║   ██║   ██║██║     ███████╗
-- ██║   ██║   ██║   ██║██║     ╚════██║
-- ╚██████╔╝   ██║   ██║███████╗███████║
--  ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝
--
-- UTILITIES BRIDGE
-- Handles notifications, progress bars, input dialogs, and other UI elements
-- Supports: ox_lib, qbcore, esx, custom
-- ════════════════════════════════════════════════════════════════════════════

Utils = {}
Utils.NotifyType = Config.Notify

-- ══════════════════════════════════════════════════════════════════════════
-- NOTIFICATION FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Send notification to player
--- @param source number Player server ID (server-side) or nil (client-side)
--- @param message string Notification message
--- @param type string Notification type ('success', 'error', 'info')
--- @param duration number Duration in milliseconds
function Utils.Notify(source, message, type, duration)
    type = type or 'info'
    duration = duration or 5000

    -- Server-side notification
    if IsDuplicityVersion() == 1 then
        if not source then return end
        
        if Utils.NotifyType == 'ox_lib' then
            TriggerClientEvent('ox_lib:notify', source, {
                description = message,
                type = type,
                duration = duration
            })
        elseif Utils.NotifyType == 'qbcore' then
            TriggerClientEvent('QBCore:Notify', source, message, type, duration)
        elseif Utils.NotifyType == 'esx' then
            TriggerClientEvent('esx:showNotification', source, message)
        elseif Utils.NotifyType == 'custom' then
            TriggerClientEvent('hm-metaldetecting:client:notify', source, message, type, duration)
        end
    
    -- Client-side notification
    else
        if Utils.NotifyType == 'ox_lib' then
            lib.notify({
                description = message,
                type = type,
                duration = duration
            })
        elseif Utils.NotifyType == 'qbcore' then
            Framework.Core.Functions.Notify(message, type, duration)
        elseif Utils.NotifyType == 'esx' then
            Framework.Core.ShowNotification(message)
        elseif Utils.NotifyType == 'custom' then
            -- Implement your custom notification here
            SetNotificationTextEntry('STRING')
            AddTextComponentString(message)
            DrawNotification(false, false)
        end
    end
end

--- Shorthand for success notification
--- @param source number Player server ID (server-side) or nil (client-side)
--- @param message string Notification message
function Utils.NotifySuccess(source, message)
    Utils.Notify(source, message, 'success', 5000)
end

--- Shorthand for error notification
--- @param source number Player server ID (server-side) or nil (client-side)
--- @param message string Notification message
function Utils.NotifyError(source, message)
    Utils.Notify(source, message, 'error', 5000)
end

--- Shorthand for info notification
--- @param source number Player server ID (server-side) or nil (client-side)
--- @param message string Notification message
function Utils.NotifyInfo(source, message)
    Utils.Notify(source, message, 'info', 5000)
end

--- Special notification for item found (longer duration + styling)
--- @param source number Player server ID
--- @param itemLabel string Item label
--- @param quantity number Item quantity
--- @param rarity string Item rarity (common, uncommon, rare, epic, legendary)
function Utils.NotifyItemFound(source, itemLabel, quantity, rarity)
    -- Get duration from config (default 8000ms)
    local duration = 8000
    if Config and Config.Notifications and Config.Notifications.ItemFoundDuration then
        duration = Config.Notifications.ItemFoundDuration
    end
    
    -- Build message
    local message = string.format('Found %dx %s', quantity, itemLabel)
    
    -- Add rarity if enabled in config
    local showRarity = true
    if Config and Config.Notifications and Config.Notifications.ShowRarity ~= nil then
        showRarity = Config.Notifications.ShowRarity
    end
    
    if showRarity and rarity then
        local rarityText = rarity:sub(1,1):upper() .. rarity:sub(2) -- Capitalize
        message = message .. ' (' .. rarityText .. ')'
    end
    
    message = message .. '!'
    
    -- Send notification with custom duration
    Utils.Notify(source, message, 'success', duration)
end

-- ══════════════════════════════════════════════════════════════════════════
-- PROGRESS BAR FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show progress bar
--- @param duration number Duration in milliseconds
--- @param label string Progress bar label
--- @param useWhileDead boolean Allow while dead
--- @param canCancel boolean Allow cancellation
--- @param disable table Disable controls
--- @param anim table Animation data
--- @param prop table Prop data
--- @return boolean Success (false if cancelled)
function Utils.ProgressBar(duration, label, useWhileDead, canCancel, disable, anim, prop)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: ProgressBar called on server!')
        return false 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        local success = lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = useWhileDead or false,
            canCancel = canCancel or false,
            disable = disable or {
                car = true,
                move = true,
                combat = true
            },
            anim = anim,
            prop = prop
        })
        return success
    elseif Utils.NotifyType == 'qbcore' then
        -- QB Progress Bar
        local finished = false
        local cancelled = false
        
        exports['progressbar']:Progress({
            name = label:lower():gsub(' ', '_'),
            duration = duration,
            label = label,
            useWhileDead = useWhileDead or false,
            canCancel = canCancel or false,
            controlDisables = disable or {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            },
            animation = anim,
            prop = prop
        }, function(status)
            finished = true
            cancelled = status
        end)
        
        while not finished do
            Wait(10)
        end
        
        return not cancelled
    else
        -- Fallback: Simple wait with notification
        Utils.NotifyInfo(nil, label)
        Wait(duration)
        return true
    end
end

--- Show circle progress bar (ox_lib only)
--- @param duration number Duration in milliseconds
--- @param label string Progress label
--- @param position string Position ('bottom', 'middle')
--- @return boolean Success
function Utils.ProgressCircle(duration, label, position)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: ProgressCircle called on server!')
        return false 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        return lib.progressCircle({
            duration = duration,
            label = label,
            position = position or 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
    else
        -- Fallback to regular progress bar
        return Utils.ProgressBar(duration, label, false, true, nil, nil, nil)
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 Progress functions initialized')
    print('  - ProgressBar:', Utils.ProgressBar ~= nil)
    print('  - ProgressCircle:', Utils.ProgressCircle ~= nil)
end

-- ══════════════════════════════════════════════════════════════════════════
-- INPUT DIALOG FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show input dialog
--- @param heading string Dialog heading
--- @param rows table Input rows
--- @return table|nil Input values
function Utils.InputDialog(heading, rows)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: InputDialog called on server!')
        return nil 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        local input = lib.inputDialog(heading, rows)
        return input
    elseif Utils.NotifyType == 'qbcore' then
        -- QB Input Dialog
        local dialog = exports['qb-input']:ShowInput({
            header = heading,
            submitText = 'Submit',
            inputs = rows
        })
        return dialog
    else
        -- Fallback: Return nil (no input dialog available)
        Utils.NotifyError(nil, 'Input dialog not available')
        return nil
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 Input dialog initialized')
    print('  - InputDialog:', Utils.InputDialog ~= nil)
end

-- ══════════════════════════════════════════════════════════════════════════
-- MENU FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show context menu
--- @param id string Menu ID
--- @param title string Menu title
--- @param options table Menu options
function Utils.ShowMenu(id, title, options)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: ShowMenu called on server!')
        return 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        lib.registerContext({
            id = id,
            title = title,
            options = options
        })
        lib.showContext(id)
    elseif Utils.NotifyType == 'qbcore' then
        -- QB Menu
        local menuOptions = {}
        for _, option in ipairs(options) do
            table.insert(menuOptions, {
                header = option.title,
                txt = option.description or '',
                params = {
                    event = option.event,
                    args = option.args,
                    isServer = option.serverEvent or false
                }
            })
        end
        
        exports['qb-menu']:openMenu(menuOptions)
    else
        Utils.NotifyError(nil, 'Menu system not available')
    end
end

--- Close menu
function Utils.CloseMenu()
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: CloseMenu called on server!')
        return 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        lib.hideContext()
    elseif Utils.NotifyType == 'qbcore' then
        exports['qb-menu']:closeMenu()
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 Menu functions initialized')
    print('  - ShowMenu:', Utils.ShowMenu ~= nil)
    print('  - CloseMenu:', Utils.CloseMenu ~= nil)
end

-- ══════════════════════════════════════════════════════════════════════════
-- TEXT UI FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show text UI
--- @param message string Text to display
--- @param position string Position ('right-center', 'left-center', 'top-center')
function Utils.ShowTextUI(message, position)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: ShowTextUI called on server!')
        return 
    end
    
    if not message then return end
    
    if Utils.NotifyType == 'ox_lib' then
        if lib and lib.showTextUI then
            lib.showTextUI(message, {
                position = position or 'right-center'
            })
        else
            print('^3[Utils]^7 Warning: ox_lib not available, using fallback')
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(message)
            EndTextCommandDisplayHelp(0, false, true, -1)
        end
    elseif Utils.NotifyType == 'qbcore' then
        exports['qb-core']:DrawText(message, position or 'left')
    else
        -- Fallback: Use native help text
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end

--- Hide text UI
function Utils.HideTextUI()
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: HideTextUI called on server!')
        return 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
    elseif Utils.NotifyType == 'qbcore' then
        exports['qb-core']:HideText()
    end
end

-- Debug print for TextUI functions
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 TextUI functions initialized')
    print('^2[Utils Bridge]^7 TextUI functions loaded:')
    print('  - ShowTextUI:', Utils.ShowTextUI ~= nil)
    print('  - HideTextUI:', Utils.HideTextUI ~= nil)
    print('^2[Utils Bridge]^7 ✅ UTILS BRIDGE READY')
end

-- ══════════════════════════════════════════════════════════════════════════
-- SKILL CHECK FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show skill check
--- @param difficulty table Difficulty settings
--- @param keys table Keys to use
--- @return boolean Success
function Utils.SkillCheck(difficulty, keys)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: SkillCheck called on server!')
        return false 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        local success = lib.skillCheck(difficulty, keys)
        return success
    else
        -- Fallback: Auto-success or simple chance-based
        return math.random(100) > 30
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 SkillCheck initialized')
end

-- ══════════════════════════════════════════════════════════════════════════
-- ALERT DIALOG FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Show alert dialog
--- @param heading string Alert heading
--- @param content string Alert content
--- @param confirm string Confirm button text
--- @param cancel string Cancel button text
--- @return string|nil Button clicked ('confirm' or 'cancel')
function Utils.AlertDialog(heading, content, confirm, cancel)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: AlertDialog called on server!')
        return nil 
    end
    
    if Utils.NotifyType == 'ox_lib' then
        local alert = lib.alertDialog({
            header = heading,
            content = content,
            centered = true,
            cancel = cancel ~= nil,
            labels = {
                confirm = confirm or 'Confirm',
                cancel = cancel or 'Cancel'
            }
        })
        return alert
    else
        -- Fallback: Simple notification
        Utils.NotifyInfo(nil, content)
        return 'confirm'
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 AlertDialog initialized')
end

-- ══════════════════════════════════════════════════════════════════════════
-- ANIMATION FUNCTIONS (Always defined but only work on client)
-- ══════════════════════════════════════════════════════════════════════════

--- Play animation
--- @param dict string Animation dictionary
--- @param name string Animation name
--- @param duration number Duration in milliseconds
--- @param flag number Animation flag
function Utils.PlayAnimation(dict, name, duration, flag)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: PlayAnimation called on server!')
        return 
    end
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, duration or -1, flag or 49, 0, false, false, false)
end

--- Stop animation
function Utils.StopAnimation()
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: StopAnimation called on server!')
        return 
    end
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

--- Load and attach prop to ped
--- @param propModel string Prop model
--- @param bone number Bone index
--- @param offset table Position offset {x, y, z}
--- @param rotation table Rotation offset {x, y, z}
--- @return number Prop object
function Utils.AttachProp(propModel, bone, offset, rotation)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: AttachProp called on server!')
        return 0 
    end
    
    local model = GetHashKey(propModel)
    
    if Config.Debug then
        print('^2[Utils]^7 Requesting model:', propModel, 'hash:', model)
    end
    
    RequestModel(model)
    
    -- Wait for model to load with timeout
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do -- Max 1 second
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        print('^1[Utils]^7 Failed to load prop model:', propModel)
        return 0
    end
    
    if Config.Debug then
        print('^2[Utils]^7 Model loaded successfully')
    end

    local ped = PlayerPedId()
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    
    if Config.Debug then
        print('^2[Utils]^7 Created prop object:', prop)
    end
    
    if not DoesEntityExist(prop) then
        print('^1[Utils]^7 Failed to create prop object')
        return 0
    end
    
    AttachEntityToEntity(
        prop, ped, 
        GetPedBoneIndex(ped, bone),
        offset.x or 0.0, offset.y or 0.0, offset.z or 0.0,
        rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0,
        true, true, false, true, 1, true
    )
    
    if Config.Debug then
        print('^2[Utils]^7 Prop attached successfully')
    end

    return prop
end

--- Delete attached prop
--- @param prop number Prop object
function Utils.DeleteProp(prop)
    if IsDuplicityVersion() == 1 then 
        print('^1[Utils]^7 ERROR: DeleteProp called on server!')
        return 
    end
    
    if DoesEntityExist(prop) then
        -- CRITICAL: Proper cleanup order to prevent floating props
        
        -- 1. Request network control (important for multiplayer)
        if NetworkGetEntityIsNetworked(prop) then
            NetworkRequestControlOfEntity(prop)
            local timeout = 0
            while not NetworkHasControlOfEntity(prop) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
        end
        
        -- 2. Detach entity first (this removes it from player)
        DetachEntity(prop, true, true)
        
        -- 3. Set as mission entity so we can delete it
        SetEntityAsMissionEntity(prop, true, true)
        
        -- 4. Small delay to ensure detach completes
        Wait(50)
        
        -- 5. Now delete the prop
        DeleteEntity(prop)
        
        -- 6. Double check it's gone
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
        
        if Config.Debug then
            print('^2[Utils]^7 Prop detached and deleted successfully')
        end
    end
end

-- Debug print
if IsDuplicityVersion() == 0 then
    print('^2[Utils Bridge]^7 Animation functions initialized')
end

-- ══════════════════════════════════════════════════════════════════════════
-- NUMBER FORMATTING
-- ══════════════════════════════════════════════════════════════════════════

--- Format number with thousand separators
--- @param number number Number to format
--- @return string Formatted number (e.g., 1,234,567)
function Utils.FormatNumber(number)
    if not number then return '0' end
    
    local formatted = tostring(number)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return formatted
end

-- ══════════════════════════════════════════════════════════════════════════
-- DEBUG LOGGING
-- ══════════════════════════════════════════════════════════════════════════

if Config.Debug then
    print('^2[HM-MetalDetecting]^7 Utils Bridge initialized: ^3' .. Utils.NotifyType .. '^7')
end

return Utils