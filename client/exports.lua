-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - CLIENT EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

--- Get current rental vehicle
--- @return number|nil Vehicle entity
function getCurrentRentalVehicle()
    if currentRentalVehicle and DoesEntityExist(currentRentalVehicle) then
        return currentRentalVehicle
    end
    return nil
end

--- Check if player has active rental
--- @return boolean Has rental
function hasActiveRental()
    return currentRentalVehicle ~= nil and DoesEntityExist(currentRentalVehicle)
end

--- Open rental menu programmatically
--- @param stationName string Station name
function openRentalMenuExport(stationName)
    openRentalMenu(stationName)
end

--- Open return menu programmatically
function openReturnMenuExport()
    openReturnMenu()
end

-- Register exports
exports('getCurrentRentalVehicle', getCurrentRentalVehicle)
exports('hasActiveRental', hasActiveRental)
exports('openRentalMenu', openRentalMenuExport)
exports('openReturnMenu', openReturnMenuExport)
