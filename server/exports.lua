-- ═══════════════════════════════════════════════════════════════════════════
-- HM BIKE & SCOOTER RENTAL - SERVER EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

--- Get all active rentals
--- @return table Active rentals {[source] = rentalData}
function GetActiveRentals()
    return ActiveRentals
end

--- Get rental statistics
--- @return table Stats {totalRentals, totalRevenue, activeRentals}
function GetRentalStats()
    local activeCount = 0
    for _ in pairs(ActiveRentals) do
        activeCount = activeCount + 1
    end
    
    return {
        totalRentals = RentalStats.totalRentals,
        totalRevenue = RentalStats.totalRevenue,
        activeRentals = activeCount
    }
end

--- Check if player has active rental
--- @param source number Player source
--- @return boolean Has rental
function HasActiveRental(source)
    return ActiveRentals[source] ~= nil
end

--- Get player's rental data
--- @param source number Player source
--- @return table|nil Rental data
function GetPlayerRental(source)
    return ActiveRentals[source]
end

--- Force end player's rental
--- @param source number Player source
--- @param refundDeposit boolean Refund deposit?
--- @return boolean Success
function ForceEndRental(source, refundDeposit)
    local rental = ActiveRentals[source]
    if not rental then return false end
    
    -- Refund deposit if requested
    if refundDeposit and rental.deposit > 0 then
        Framework.AddMoney(source, rental.deposit, 'cash')
    end
    
    -- Clear rental
    ActiveRentals[source] = nil
    
    -- Notify client to delete vehicle
    TriggerClientEvent('hm-rental:client:deleteVehicle', source)
    
    return true
end

--- Set rental fee per minute (override config)
--- @param feePerMinute number Fee per minute
function SetRentalFee(feePerMinute)
    Config.Rental.RentalFeePerMinute = feePerMinute
end

-- Register exports
exports('GetActiveRentals', GetActiveRentals)
exports('GetRentalStats', GetRentalStats)
exports('HasActiveRental', HasActiveRental)
exports('GetPlayerRental', GetPlayerRental)
exports('ForceEndRental', ForceEndRental)
exports('SetRentalFee', SetRentalFee)
