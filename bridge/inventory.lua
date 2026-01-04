-- ██╗███╗   ██╗██╗   ██╗███████╗███╗   ██╗████████╗ ██████╗ ██████╗ ██╗   ██╗
-- ██║████╗  ██║██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
-- ██║██╔██╗ ██║██║   ██║█████╗  ██╔██╗ ██║   ██║   ██║   ██║██████╔╝ ╚████╔╝ 
-- ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██╔══██╗  ╚██╔╝  
-- ██║██║ ╚████║ ╚████╔╝ ███████╗██║ ╚████║   ██║   ╚██████╔╝██║  ██║   ██║   
-- ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
--
-- INVENTORY BRIDGE (WITH AUTO-DETECTION!)
-- Handles item operations across different inventory systems
-- Supports: ox_inventory, qb-inventory, ps-inventory, qs-inventory, tgiann-inventory, core_inventory
-- ════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════
-- AUTO-DETECTION (if Config.Inventory = 'auto')
-- ══════════════════════════════════════════════════════════════════════════

if Config.Inventory == 'auto' then
    if GetResourceState('ox_inventory') == 'started' or GetResourceState('ox_inventory') == 'starting' then
        Config.Inventory = 'ox_inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3ox_inventory^7')
        end
    elseif GetResourceState('qb-inventory') == 'started' or GetResourceState('qb-inventory') == 'starting' then
        Config.Inventory = 'qb-inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3qb-inventory^7')
        end
    elseif GetResourceState('ps-inventory') == 'started' or GetResourceState('ps-inventory') == 'starting' then
        Config.Inventory = 'ps-inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3ps-inventory^7')
        end
    elseif GetResourceState('qs-inventory') == 'started' or GetResourceState('qs-inventory') == 'starting' then
        Config.Inventory = 'qs-inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3qs-inventory^7')
        end
    elseif GetResourceState('core_inventory') == 'started' or GetResourceState('core_inventory') == 'starting' then
        Config.Inventory = 'core_inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3core_inventory^7')
        end
    elseif GetResourceState('tgiann-inventory') == 'started' or GetResourceState('tgiann-inventory') == 'starting' then
        Config.Inventory = 'tgiann-inventory'
        if Config.Debug then
            print('^2[Inventory]^7 Auto-detected: ^3tgiann-inventory^7')
        end
    else
        -- Fallback based on framework
        if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
            Config.Inventory = 'qb-inventory'
            if Config.Debug then
                print('^3[Inventory]^7 No inventory detected, defaulting to ^3qb-inventory^7 (based on framework)')
            end
        else
            Config.Inventory = 'ox_inventory'
            if Config.Debug then
                print('^3[Inventory]^7 No inventory detected, defaulting to ^3ox_inventory^7')
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CORE INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════

Inventory = {}
Inventory.Type = Config.Inventory

-- ══════════════════════════════════════════════════════════════════════════
-- ITEM MANAGEMENT
-- ══════════════════════════════════════════════════════════════════════════

--- Add item to player inventory
--- @param source number Player server ID
--- @param item string Item name
--- @param count number Amount to add
--- @param metadata table Optional item metadata
--- @return boolean Success
function Inventory.AddItem(source, item, count, metadata)
    count = count or 1
    metadata = metadata or {}

    if Inventory.Type == 'ox_inventory' then
        local success = exports.ox_inventory:AddItem(source, item, count, metadata)
        return success ~= false
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(item, count, nil, metadata)
    elseif Inventory.Type == 'core_inventory' then
        -- ESX/core_inventory
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        Player.addInventoryItem(item, count)
        return true
    end
end

--- Remove item from player inventory
--- @param source number Player server ID
--- @param item string Item name
--- @param count number Amount to remove
--- @param metadata table Optional metadata for specific item removal
--- @return boolean Success
function Inventory.RemoveItem(source, item, count, metadata)
    count = count or 1

    if Inventory.Type == 'ox_inventory' then
        local success = exports.ox_inventory:RemoveItem(source, item, count, metadata)
        return success ~= false
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, count)
    elseif Inventory.Type == 'core_inventory' then
        -- ESX/core_inventory
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        Player.removeInventoryItem(item, count)
        return true
    end
end

--- Get item count in player inventory
--- @param source number Player server ID
--- @param item string Item name
--- @return number Item count
function Inventory.GetItemCount(source, item)
    if Inventory.Type == 'ox_inventory' then
        local count = exports.ox_inventory:GetItemCount(source, item)
        return count or 0
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return 0 end
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount or 0
    elseif Inventory.Type == 'core_inventory' then
        -- ESX/core_inventory
        local Player = Framework.GetPlayer(source)
        if not Player then return 0 end
        local itemData = Player.getInventoryItem(item)
        return itemData and itemData.count or 0
    end
end

--- Check if player has item
--- @param source number Player server ID
--- @param item string Item name
--- @param count number Minimum amount
--- @return boolean Has item
function Inventory.HasItem(source, item, count)
    count = count or 1
    return Inventory.GetItemCount(source, item) >= count
end

--- Get specific item data
--- @param source number Player server ID
--- @param item string Item name
--- @return table|nil Item data
function Inventory.GetItem(source, item)
    if Inventory.Type == 'ox_inventory' then
        return exports.ox_inventory:GetItem(source, item)
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return nil end
        return Player.Functions.GetItemByName(item)
    elseif Inventory.Type == 'core_inventory' then
        -- ESX/core_inventory
        local Player = Framework.GetPlayer(source)
        if not Player then return nil end
        return Player.getInventoryItem(item)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- INVENTORY CHECKS
-- ══════════════════════════════════════════════════════════════════════════

--- Check if player can carry item
--- @param source number Player server ID
--- @param item string Item name
--- @param count number Amount to check
--- @return boolean Can carry
function Inventory.CanCarryItem(source, item, count)
    count = count or 1

    if Inventory.Type == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(source, item, count)
    elseif Inventory.Type == 'qb-inventory' then
        -- QB doesn't have native CanCarryItem, check weight
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        -- Get item data from shared items
        local itemData = QBCore.Shared.Items[item:lower()]
        if not itemData then return false end
        
        -- Calculate total weight
        local totalWeight = Player.Functions.GetTotalWeight()
        local itemWeight = itemData.weight * count
        local maxWeight = 120000 -- QB default max weight
        
        return (totalWeight + itemWeight) <= maxWeight
    elseif Inventory.Type == 'core_inventory' then
        -- ESX/core_inventory basic check
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        -- ESX uses weight system too
        local itemData = Player.getInventoryItem(item)
        if not itemData then return false end
        
        return Player.canCarryItem(item, count)
    end
end

--- Get player inventory weight
--- @param source number Player server ID
--- @return number current weight
--- @return number max weight
function Inventory.GetWeight(source)
    if Inventory.Type == 'ox_inventory' then
        local weight = exports.ox_inventory:GetCurrentWeight(source)
        local maxWeight = exports.ox_inventory:GetMaxWeight(source)
        return weight or 0, maxWeight or 0
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return 0, 0 end
        return Player.Functions.GetTotalWeight(), 120000
    elseif Inventory.Type == 'core_inventory' then
        -- ESX weight system
        local Player = Framework.GetPlayer(source)
        if not Player then return 0, 0 end
        return Player.getWeight(), Player.getMaxWeight()
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- METADATA FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Set item metadata
--- @param source number Player server ID
--- @param item string Item name
--- @param metadata table Metadata to set
--- @param slot number Optional slot number
--- @return boolean Success
function Inventory.SetMetadata(source, item, metadata, slot)
    if Inventory.Type == 'ox_inventory' then
        if slot then
            return exports.ox_inventory:SetMetadata(source, slot, metadata)
        else
            -- Find item slot first
            local inventory = exports.ox_inventory:GetInventory(source)
            if not inventory then return false end
            
            for k, v in pairs(inventory.items) do
                if v.name == item then
                    return exports.ox_inventory:SetMetadata(source, k, metadata)
                end
            end
        end
    elseif Inventory.Type == 'qb-inventory' then
        -- QB-Inventory metadata handling
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        if slot then
            Player.PlayerData.items[slot].info = metadata
            Player.Functions.SetInventory(Player.PlayerData.items)
            return true
        else
            -- Find item by name
            for k, v in pairs(Player.PlayerData.items) do
                if v.name == item then
                    Player.PlayerData.items[k].info = metadata
                    Player.Functions.SetInventory(Player.PlayerData.items)
                    return true
                end
            end
        end
    end
    
    return false
end

--- Get item metadata
--- @param source number Player server ID
--- @param item string Item name
--- @param slot number Optional slot number
--- @return table|nil Metadata
function Inventory.GetMetadata(source, item, slot)
    if Inventory.Type == 'ox_inventory' then
        if slot then
            local itemData = exports.ox_inventory:GetSlot(source, slot)
            return itemData and itemData.metadata or nil
        else
            local itemData = exports.ox_inventory:GetItem(source, item, nil, true)
            return itemData and itemData.metadata or nil
        end
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return nil end
        
        if slot then
            local itemData = Player.PlayerData.items[slot]
            return itemData and itemData.info or nil
        else
            local itemData = Player.Functions.GetItemByName(item)
            return itemData and itemData.info or nil
        end
    elseif Inventory.Type == 'core_inventory' then
        -- ESX doesn't support metadata natively
        return nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- INVENTORY ACCESS
-- ══════════════════════════════════════════════════════════════════════════

--- Get full player inventory
--- @param source number Player server ID
--- @return table Inventory items
function Inventory.GetInventory(source)
    if Inventory.Type == 'ox_inventory' then
        local inventory = exports.ox_inventory:GetInventory(source)
        return inventory and inventory.items or {}
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return {} end
        return Player.PlayerData.items or {}
    elseif Inventory.Type == 'core_inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return {} end
        return Player.getInventory() or {}
    end
end

--- Clear player inventory
--- @param source number Player server ID
--- @return boolean Success
function Inventory.ClearInventory(source)
    if Inventory.Type == 'ox_inventory' then
        return exports.ox_inventory:ClearInventory(source)
    elseif Inventory.Type == 'qb-inventory' then
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        Player.Functions.ClearInventory()
        return true
    elseif Inventory.Type == 'core_inventory' then
        -- ESX manual clearing
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        local inventory = Player.getInventory()
        for _, item in pairs(inventory) do
            if item.count > 0 then
                Player.removeInventoryItem(item.name, item.count)
            end
        end
        return true
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- SPECIAL FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════

--- Check if player has specific detector equipped
--- @param source number Player server ID
--- @return string|nil Detector item name
function Inventory.GetEquippedDetector(source)
    local detectors = {
        'detector_beginner',
        'detector_lustrous',
        'detector_trove',
        'detector_goldseeker',
        'detector_archaeo'
    }
    
    for _, detector in ipairs(detectors) do
        if Inventory.HasItem(source, detector, 1) then
            return detector
        end
    end
    
    return nil
end

--- Get all loot items in player inventory
--- @param source number Player server ID
--- @return table List of loot items with counts
function Inventory.GetAllLootItems(source)
    local lootItems = {}
    
    -- Iterate through all loot tables
    for _, lootTable in pairs(Config.LootTables) do
        for _, itemData in ipairs(lootTable.Items) do
            local count = Inventory.GetItemCount(source, itemData.item)
            if count > 0 then
                table.insert(lootItems, {
                    item = itemData.item,
                    count = count,
                    sellPrice = itemData.sellPrice,
                    totalValue = count * itemData.sellPrice,
                    rarity = lootTable.Rarity
                })
            end
        end
    end
    
    return lootItems
end

-- ══════════════════════════════════════════════════════════════════════════
-- DEBUG LOGGING
-- ══════════════════════════════════════════════════════════════════════════

if Config.Debug then
    print('^2[HM-MetalDetecting]^7 Inventory Bridge initialized: ^3' .. Inventory.Type .. '^7')
end

return Inventory