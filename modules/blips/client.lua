local blips = {}

local function serverOnly()
    error('^1[pizza_libs] addBlip/removeBlip must be called from the server.^0', 2)
end

local function remove(id)
    id = tostring(id)
    local handle = blips[id]
    if handle and DoesBlipExist(handle) then
        RemoveBlip(handle)
    end
    blips[id] = nil
end

local function vec3(coords)
    if not coords then
        return nil
    end
    if type(coords) == 'vector3' then
        return coords
    end
    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3]
    if not x then
        return nil
    end
    return vector3(x + 0.0, y + 0.0, z + 0.0)
end

RegisterNetEvent('pizza_libs:blips:upsert', function(id, data)
    if id == nil or type(data) ~= 'table' then
        return
    end
    id = tostring(id)
    remove(id)
    local c = vec3(data.coords)
    if not c then
        return
    end
    local b = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(b, data.sprite or 1)
    SetBlipColour(b, data.color or 0)
    SetBlipScale(b, data.scale or 0.8)
    if data.shortRange ~= false then
        SetBlipAsShortRange(b, true)
    else
        SetBlipAsShortRange(b, false)
    end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label or 'Blip')
    EndTextCommandSetBlipName(b)
    blips[id] = b
end)

RegisterNetEvent('pizza_libs:blips:remove', function(id)
    if id == nil then
        return
    end
    remove(tostring(id))
end)

return {
    addBlip = serverOnly,
    removeBlip = serverOnly,
}
