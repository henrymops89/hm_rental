Locale = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- ALLGEMEIN
-- ═══════════════════════════════════════════════════════════════════════════

Locale.general = {
    press_to_interact = '[E] Interagieren',
    loading = 'Lädt...',
    processing = 'Verarbeite...',
    cancel = 'Abbrechen',
    confirm = 'Bestätigen',
    close = 'Schließen',
    back = 'Zurück',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BENACHRICHTIGUNGEN
-- ═══════════════════════════════════════════════════════════════════════════

Locale.notify = {
    -- Erfolg
    rental_success = 'Du hast ein %s für $%s gemietet!',
    rental_success_deposit = 'Du hast ein %s gemietet! Kaution: $%s',
    return_success = 'Fahrzeug zurückgegeben! Kaution zurückerstattet: $%s',
    return_success_no_deposit = 'Fahrzeug erfolgreich zurückgegeben!',
    return_with_fee = 'Fahrzeug zurückgegeben! Mietgebühr: $%s',
    
    -- Fehler
    not_enough_money = 'Nicht genug Geld! Benötigt: $%s',
    already_renting = 'Du hast bereits ein Fahrzeug gemietet!',
    no_vehicle_rented = 'Du hast kein Fahrzeug gemietet!',
    not_rental_vehicle = 'Dies ist kein Mietfahrzeug!',
    too_far_from_station = 'Du bist zu weit von einer Station entfernt!',
    vehicle_not_found = 'Fahrzeug nicht gefunden!',
    spawn_failed = 'Fahrzeug konnte nicht gespawnt werden!',
    invalid_vehicle_type = 'Ungültiger Fahrzeugtyp!',
    cooldown_active = 'Bitte warte %s Sekunden vor der nächsten Miete!',
    rate_limit = 'Zu viele Anfragen! Bitte warte einen Moment.',
    deposit_lost = 'Kaution verfallen: $%s (Fahrzeug nicht an Station zurückgegeben)',
    
    -- Info
    no_vehicles_available = 'Keine Fahrzeuge verfügbar',
    
    -- Fahrzeug Lock/Unlock
    vehicle_locked = 'Fahrzeug abgeschlossen',
    vehicle_unlocked = 'Fahrzeug aufgeschlossen',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MENÜ
-- ═══════════════════════════════════════════════════════════════════════════

Locale.menu = {
    -- Hauptmenü
    title = 'Fahrzeugverleih',
    subtitle = 'Wähle ein Fahrzeug zum Mieten',
    
    -- Fahrzeugauswahl
    select_vehicle = 'Fahrzeug auswählen',
    rent_now = 'Jetzt mieten',
    rental_fee = 'Mietgebühr',
    deposit = 'Kaution',
    total_cost = 'Gesamtkosten',
    per_minute = 'pro Minute',
    one_time = 'Einmalig',
    available = 'Verfügbar',
    rented = 'Vermietet',
    
    -- Rückgabe
    return_title = 'Fahrzeug zurückgeben?',
    return_text = 'Möchtest du das Fahrzeug zurückgeben?',
    return_deposit_info = 'Du erhältst deine Kaution von $%s zurück.',
    return_fee_info = 'Mietgebühr: $%s',
    
    -- Aktuelle Miete Info
    rental_info_title = 'Aktuell gemietet',
    rental_info_vehicle = 'Fahrzeug: %s',
    rental_info_time = 'Mietdauer: %s Minuten',
    rental_info_cost = 'Kosten bisher: $%s',
    rental_info_deposit = 'Kaution: $%s',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- RENTAL / STATION
-- ═══════════════════════════════════════════════════════════════════════════

Locale.rental = {
    open_station = 'Fahrzeug mieten',
    return_vehicle = 'Fahrzeug zurückgeben',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- FAHRZEUGE
-- ═══════════════════════════════════════════════════════════════════════════

Locale.vehicles = {
    -- Fahrräder
    bicycle = {
        name = 'Fahrrad',
        desc = 'Standard Fahrrad',
    },
    mountainbike = {
        name = 'Mountainbike',
        desc = 'Robustes Mountainbike',
    },
    racer = {
        name = 'Rennrad',
        desc = 'Schnelles Rennrad',
    },
    
    -- Roller
    scooter = {
        name = 'E-Scooter',
        desc = 'Elektrischer Roller',
    },
    sport_scooter = {
        name = 'Sport Scooter',
        desc = 'Schneller Sport-Roller',
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN BEFEHLE
-- ═══════════════════════════════════════════════════════════════════════════

Locale.commands = {
    -- Statistiken
    stats = 'Rental Statistiken',
    total_rentals = 'Gesamt Vermietungen: %s',
    active_rentals = 'Aktive Vermietungen: %s',
    total_revenue = 'Gesamt Einnahmen: $%s',
    
    -- Station Management
    spawned_station = 'Verleihstation erstellt: %s',
    removed_station = 'Verleihstation entfernt: %s',
    no_station = 'Keine Station in der Nähe gefunden!',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BLIPS
-- ═══════════════════════════════════════════════════════════════════════════

Locale.blips = {
    rental = 'Fahrzeugverleih',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ZEIT FORMATIERUNG
-- ═══════════════════════════════════════════════════════════════════════════

Locale.time = {
    minutes_short = 'Min',
    seconds_short = 'Sek',
}

return Locale
