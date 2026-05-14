local nextId = 0

--- Create a synced map blip for all players and return its id.
--- @param data { coords: vector3|table, sprite?: integer, color?: integer, scale?: number, label?: string, shortRange?: boolean }
--- @return integer
local function addBlip(data)
    nextId = nextId + 1
    local id = nextId
    TriggerClientEvent('pizza_libs:blips:upsert', -1, id, data)
    return id
end

--- Remove a blip previously created with addBlip.
--- @param blipId integer
local function removeBlip(blipId)
    TriggerClientEvent('pizza_libs:blips:remove', -1, blipId)
end

return {
    addBlip = addBlip,
    removeBlip = removeBlip,
}
