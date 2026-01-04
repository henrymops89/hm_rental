-- ████████╗ █████╗ ██████╗  ██████╗ ███████╗████████╗
-- ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝ ██╔════╝╚══██╔══╝
--    ██║   ███████║██████╔╝██║  ███╗█████╗     ██║   
--    ██║   ██╔══██║██╔══██╗██║   ██║██╔══╝     ██║   
--    ██║   ██║  ██║██║  ██║╚██████╔╝███████╗   ██║   
--    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   
--
-- TARGET BRIDGE (WITH AUTO-DETECTION!)
-- Handles targeting system for peds and objects
-- Supports: ox_target, qb-target, qtarget
-- ════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════
-- AUTO-DETECTION (if Config.Target = 'auto')
-- ══════════════════════════════════════════════════════════════════════════

if Config.Target == 'auto' then
    if GetResourceState('ox_target') == 'started' or GetResourceState('ox_target') == 'starting' then
        Config.Target = 'ox_target'
        if Config.Debug then
            print('^2[Target]^7 Auto-detected: ^3ox_target^7')
        end
    elseif GetResourceState('qb-target') == 'started' or GetResourceState('qb-target') == 'starting' then
        Config.Target = 'qb-target'
        if Config.Debug then
            print('^2[Target]^7 Auto-detected: ^3qb-target^7')
        end
    elseif GetResourceState('qtarget') == 'started' or GetResourceState('qtarget') == 'starting' then
        Config.Target = 'qtarget'
        if Config.Debug then
            print('^2[Target]^7 Auto-detected: ^3qtarget^7')
        end
    else
        -- Fallback based on framework
        if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
            Config.Target = 'qb-target'
            if Config.Debug then
                print('^3[Target]^7 No target system detected, defaulting to ^3qb-target^7 (based on framework)')
            end
        else
            Config.Target = 'ox_target'
            if Config.Debug then
                print('^3[Target]^7 No target system detected, defaulting to ^3ox_target^7')
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CORE INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════

Target = {}
Target.Type = Config.Target


-- ══════════════════════════════════════════════════════════════════════════
-- PED TARGETING
-- ══════════════════════════════════════════════════════════════════════════

--- Add target to ped/entity
--- @param entity number Entity handle
--- @param options table Target options
--- @return boolean Success
function Target.AddEntityTarget(entity, options)
    if Target.Type == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, options)
        return true
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = options,
            distance = options.distance or 2.5
        })
        return true
    end
    return false
end

--- Remove target from ped/entity
--- @param entity number Entity handle
function Target.RemoveEntityTarget(entity)
    if Target.Type == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity)
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- MODEL TARGETING
-- ══════════════════════════════════════════════════════════════════════════

--- Add target to specific model
--- @param models table or string Model hash(es)
--- @param options table Target options
--- @return boolean Success
function Target.AddModelTarget(models, options)
    if type(models) ~= 'table' then
        models = {models}
    end

    if Target.Type == 'ox_target' then
        exports.ox_target:addModel(models, options)
        return true
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:AddTargetModel(models, {
            options = options,
            distance = options.distance or 2.5
        })
        return true
    end
    return false
end

--- Remove target from model
--- @param models table or string Model hash(es)
function Target.RemoveModelTarget(models)
    if type(models) ~= 'table' then
        models = {models}
    end

    if Target.Type == 'ox_target' then
        exports.ox_target:removeModel(models)
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:RemoveTargetModel(models)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- ZONE TARGETING (Sphere/Box/Poly)
-- ══════════════════════════════════════════════════════════════════════════

--- Add sphere zone target
--- @param name string Zone name
--- @param coords vector3 Zone center
--- @param radius number Zone radius
--- @param options table Target options
--- @return boolean Success
function Target.AddSphereZone(name, coords, radius, options)
    if Target.Type == 'ox_target' then
        exports.ox_target:addSphereZone({
            name = name,
            coords = coords,
            radius = radius,
            debug = Config.Debug,
            options = options
        })
        return true
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:AddCircleZone(name, coords, radius, {
            name = name,
            debugPoly = Config.Debug,
            useZ = true
        }, {
            options = options,
            distance = radius
        })
        return true
    end
    return false
end

--- Add box zone target
--- @param name string Zone name
--- @param coords vector3 Zone center
--- @param size vector3 Box size (length, width, height)
--- @param heading number Zone rotation
--- @param options table Target options
--- @return boolean Success
function Target.AddBoxZone(name, coords, size, heading, options)
    if Target.Type == 'ox_target' then
        exports.ox_target:addBoxZone({
            name = name,
            coords = coords,
            size = size,
            rotation = heading,
            debug = Config.Debug,
            options = options
        })
        return true
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name = name,
            heading = heading,
            debugPoly = Config.Debug,
            minZ = coords.z - size.z / 2,
            maxZ = coords.z + size.z / 2
        }, {
            options = options,
            distance = 2.5
        })
        return true
    end
    return false
end

--- Add poly zone target
--- @param name string Zone name
--- @param points table List of vector3 points
--- @param options table Target options
--- @return boolean Success
function Target.AddPolyZone(name, points, options)
    if Target.Type == 'ox_target' then
        exports.ox_target:addPolyZone({
            name = name,
            points = points,
            thickness = options.thickness or 2.0,
            debug = Config.Debug,
            options = options
        })
        return true
    elseif Target.Type == 'qb-target' then
        -- Convert vector3 points to vector2 for qb-target
        local qbPoints = {}
        for _, point in ipairs(points) do
            table.insert(qbPoints, vector2(point.x, point.y))
        end
        
        exports['qb-target']:AddPolyZone(name, qbPoints, {
            name = name,
            debugPoly = Config.Debug,
            minZ = options.minZ or 0.0,
            maxZ = options.maxZ or 100.0
        }, {
            options = options,
            distance = 2.5
        })
        return true
    end
    return false
end

--- Remove zone target
--- @param name string Zone name
function Target.RemoveZone(name)
    if Target.Type == 'ox_target' then
        exports.ox_target:removeZone(name)
    elseif Target.Type == 'qb-target' then
        exports['qb-target']:RemoveZone(name)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Format target options for compatibility
--- @param options table Raw options
--- @return table Formatted options
function Target.FormatOptions(options)
    -- Ensure options is array
    if not options[1] then
        options = {options}
    end

    -- Format each option for target system
    local formatted = {}
    for _, option in ipairs(options) do
        local formattedOption = {
            name = option.name or 'option',
            label = option.label or 'Interact',
            icon = option.icon or 'fas fa-hand-paper',
            distance = option.distance or 2.5,
            onSelect = option.onSelect or option.action,
            canInteract = option.canInteract
        }

        -- QB-Target specific
        if Target.Type == 'qb-target' then
            formattedOption.action = formattedOption.onSelect
            formattedOption.onSelect = nil
        end

        table.insert(formatted, formattedOption)
    end

    return formatted
end

--- Add ped target with automatic cleanup
--- @param ped number Ped handle
--- @param options table Target options
--- @return boolean Success
function Target.AddPed(ped, options)
    if not DoesEntityExist(ped) then return false end
    
    local formatted = Target.FormatOptions(options)
    return Target.AddEntityTarget(ped, formatted)
end

--- Add targeting to shop peds
--- @param shopData table Shop configuration
--- @return number Ped handle
function Target.SetupShopPed(shopData)
    local pedModel = GetHashKey(shopData.Ped.model)
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(10)
    end

    local ped = CreatePed(4, pedModel, 
        shopData.Ped.coords.x, 
        shopData.Ped.coords.y, 
        shopData.Ped.coords.z - 1.0, 
        shopData.Ped.coords.w, 
        false, true
    )

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Set scenario if provided
    if shopData.Ped.scenario then
        TaskStartScenarioInPlace(ped, shopData.Ped.scenario, 0, true)
    end

    -- Add target
    local options = {
        {
            name = 'shop_' .. shopData.Type,
            label = shopData.Target.label,
            icon = shopData.Target.icon,
            distance = shopData.Target.distance,
            onSelect = function()
                TriggerEvent('hm-metaldetecting:client:openShop', shopData.Type)
            end
        }
    }

    Target.AddPed(ped, options)
    
    return ped
end

-- ══════════════════════════════════════════════════════════════════════════
-- DEBUG LOGGING
-- ══════════════════════════════════════════════════════════════════════════

if Config.Debug then
    print('^2[HM-MetalDetecting]^7 Target Bridge initialized: ^3' .. Target.Type .. '^7')
end

return Target