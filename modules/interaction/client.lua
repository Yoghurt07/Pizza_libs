local pizza_libs = 'pizza_libs'

local function sendNui(payload)
    exports[pizza_libs]:sendNui(payload)
end

---@class InteractionOption
---@field id string|integer
---@field text string
---@field displayDist number
---@field interactDist number
---@field key string
---@field keyNum integer
---@field coords vector3|nil
---@field entity integer|nil
---@field playerId integer|nil
---@field model integer|string|nil
---@field searchRadius number|nil
---@field onSelect function|nil
---@field canInteract fun(): boolean|nil

---@class InteractionGroup
---@field mode 'coords'|'entity'|'player'|'model'
---@field options table<string, InteractionOption>

local groups = {} ---@type table<string, InteractionGroup>
local threadRunning = false

local function normalizeOptions(options)
    local map = {}
    if type(options) ~= 'table' then
        return map
    end
    for i = 1, #options do
        local opt = options[i]
        if type(opt) == 'table' and opt.id ~= nil then
            local key = tostring(opt.id)
            map[key] = opt
        end
    end
    return map
end

local function ensureThread()
    if threadRunning then
        return
    end
    threadRunning = true
    local last = { hint = '', pin = '' }
    Citizen.CreateThread(function()
        while next(groups) do
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)

            for _, group in pairs(groups) do
                if group.mode == 'model' then
                    for _, opt in pairs(group.options) do
                        local hash = opt.model
                        if type(hash) == 'string' then
                            hash = joaat(hash)
                        end
                        local search = opt.coords or pcoords
                        local radius = opt.searchRadius or 50.0
                        local best, bestDist
                        for _, ent in ipairs(GetGamePool('CObject')) do
                            if DoesEntityExist(ent) and GetEntityModel(ent) == hash then
                                local ec = GetEntityCoords(ent)
                                local d = #(search - ec)
                                if d <= radius and (not bestDist or d < bestDist) then
                                    best, bestDist = ec, d
                                end
                            end
                        end
                        for _, ent in ipairs(GetGamePool('CPed')) do
                            if DoesEntityExist(ent) and GetEntityModel(ent) == hash then
                                local ec = GetEntityCoords(ent)
                                local d = #(search - ec)
                                if d <= radius and (not bestDist or d < bestDist) then
                                    best, bestDist = ec, d
                                end
                            end
                        end
                        opt._resolved = best
                    end
                end
            end

            local bestPin = nil ---@type { dist: number, world: vector3 }|nil
            local bestInteract = nil ---@type { dist: number, opt: InteractionOption, world: vector3 }|nil

            for _, group in pairs(groups) do
                for _, opt in pairs(group.options) do
                    local world = nil
                    if group.mode == 'coords' then
                        world = opt.coords
                    elseif group.mode == 'entity' then
                        local ent = opt.entity
                        if ent and DoesEntityExist(ent) then
                            world = GetEntityCoords(ent)
                        end
                    elseif group.mode == 'player' then
                        local sid = opt.playerId
                        if sid then
                            local player = GetPlayerFromServerId(sid)
                            if player ~= -1 then
                                local ent = GetPlayerPed(player)
                                if ent ~= 0 and DoesEntityExist(ent) then
                                    world = GetEntityCoords(ent)
                                end
                            end
                        end
                    elseif group.mode == 'model' then
                        world = opt._resolved
                    end

                    if world then
                        local dist = #(pcoords - world)
                        local displayDist = opt.displayDist or 10.0
                        local interactDist = opt.interactDist or 2.0

                        if dist <= displayDist then
                            if not bestPin or dist < bestPin.dist then
                                bestPin = { dist = dist, world = world }
                            end
                        end

                        if dist <= interactDist then
                            local ok = true
                            if opt.canInteract then
                                ok = opt.canInteract() == true
                            end
                            if ok and (not bestInteract or dist < bestInteract.dist) then
                                bestInteract = { dist = dist, opt = opt, world = world }
                            end
                        end
                    end
                end
            end

            if bestPin then
                local ok, sx, sy
                if GetScreenCoordFromWorldCoord then
                    ok, sx, sy = GetScreenCoordFromWorldCoord(bestPin.world.x, bestPin.world.y, bestPin.world.z)
                else
                    ok, sx, sy = World3dToScreen2d(bestPin.world.x, bestPin.world.y, bestPin.world.z)
                end
                if ok then
                    local sig = ('1:%.4f:%.4f'):format(sx, sy)
                    if sig ~= last.pin then
                        last.pin = sig
                        sendNui({
                            type = 'pizza:interaction:pin',
                            data = { x = sx, y = sy, visible = true },
                        })
                    end
                else
                    if last.pin ~= '0' then
                        last.pin = '0'
                        sendNui({ type = 'pizza:interaction:pin', data = { visible = false } })
                    end
                end
            else
                if last.pin ~= '' then
                    last.pin = ''
                    sendNui({ type = 'pizza:interaction:pin', data = { visible = false } })
                end
            end

            if bestInteract then
                local o = bestInteract.opt
                local sig = ('%s|%s|%s'):format(o.text or '', o.key or 'E', tostring(o.keyNum or 38))
                if sig ~= last.hint then
                    last.hint = sig
                    sendNui({
                        type = 'pizza:interaction:show',
                        data = {
                            text = o.text or '',
                            key = o.key or 'E',
                            keyNum = o.keyNum or 38,
                        },
                    })
                end

                if IsControlJustReleased(0, o.keyNum or 38) then
                    local allow = true
                    if o.canInteract then
                        allow = o.canInteract() == true
                    end
                    if allow and o.onSelect then
                        o.onSelect()
                    end
                end
            else
                if last.hint ~= '' then
                    last.hint = ''
                    sendNui({ type = 'pizza:interaction:hide' })
                end
            end

            Wait(0)
        end
        last.hint = ''
        last.pin = ''
        sendNui({ type = 'pizza:interaction:hide' })
        sendNui({ type = 'pizza:interaction:pin', data = { visible = false } })
        threadRunning = false
    end)
end

local function upsertGroup(mode, id, options, merge)
    id = tostring(id)
    local group = groups[id]
    if not group then
        group = { mode = mode, options = {} }
        groups[id] = group
    else
        group.mode = mode
    end
    local map = normalizeOptions(options)
    if merge then
        for k, v in pairs(map) do
            group.options[k] = v
        end
    else
        group.options = map
    end
    ensureThread()
end

--- Create 3D text UI interactions bound to world coordinates.
--- @param id string|integer
--- @param options InteractionOption[]
local function create3DTextUIOnCoords(id, options)
    upsertGroup('coords', id, options, false)
end

--- Update a single coordinate-bound interaction option.
--- @param id string|integer
--- @param optionId string|integer
--- @param data table
local function update3DTextUIOnCoords(id, optionId, data)
    id = tostring(id)
    optionId = tostring(optionId)
    local g = groups[id]
    if not g or g.mode ~= 'coords' then
        return
    end
    local cur = g.options[optionId]
    if not cur then
        return
    end
    for dk, dv in pairs(data) do
        cur[dk] = dv
    end
end

--- Remove all coordinate-bound interactions for an id.
--- @param id string|integer
local function remove3DTextUIFromCoords(id)
    groups[tostring(id)] = nil
end

--- Remove one coordinate-bound interaction option.
--- @param id string|integer
--- @param optionId string|integer
local function remove3DTextUIFromCoordsOption(id, optionId)
    local g = groups[tostring(id)]
    if g then
        g.options[tostring(optionId)] = nil
        if next(g.options) == nil then
            groups[tostring(id)] = nil
        end
    end
end

--- Create 3D text UI interactions bound to entities.
--- @param id string|integer
--- @param options InteractionOption[]
local function create3DTextUIOnEntity(id, options)
    upsertGroup('entity', id, options, false)
end

--- @param id string|integer
--- @param optionId string|integer
--- @param data table
local function update3DTextUIOnEntity(id, optionId, data)
    id = tostring(id)
    optionId = tostring(optionId)
    local g = groups[id]
    if not g or g.mode ~= 'entity' then
        return
    end
    local cur = g.options[optionId]
    if not cur then
        return
    end
    for dk, dv in pairs(data) do
        cur[dk] = dv
    end
end

--- @param id string|integer
local function remove3DTextUIFromEntity(id)
    groups[tostring(id)] = nil
end

--- @param id string|integer
--- @param optionId string|integer
local function remove3DTextUIFromEntityOption(id, optionId)
    local g = groups[tostring(id)]
    if g then
        g.options[tostring(optionId)] = nil
        if next(g.options) == nil then
            groups[tostring(id)] = nil
        end
    end
end

--- Create 3D text UI interactions bound to players by server id.
--- @param id string|integer
--- @param options InteractionOption[]
local function create3DTextUIOnPlayer(id, options)
    upsertGroup('player', id, options, false)
end

--- @param id string|integer
--- @param optionId string|integer
--- @param data table
local function update3DTextUIOnPlayer(id, optionId, data)
    id = tostring(id)
    optionId = tostring(optionId)
    local g = groups[id]
    if not g or g.mode ~= 'player' then
        return
    end
    local cur = g.options[optionId]
    if not cur then
        return
    end
    for dk, dv in pairs(data) do
        cur[dk] = dv
    end
end

--- @param id string|integer
local function remove3DTextUIFromPlayer(id)
    groups[tostring(id)] = nil
end

--- @param id string|integer
--- @param optionId string|integer
local function remove3DTextUIFromPlayerOption(id, optionId)
    local g = groups[tostring(id)]
    if g then
        g.options[tostring(optionId)] = nil
        if next(g.options) == nil then
            groups[tostring(id)] = nil
        end
    end
end

--- Create 3D text UI interactions bound to entity models.
--- @param id string|integer
--- @param options InteractionOption[]
local function create3DTextUIOnModel(id, options)
    upsertGroup('model', id, options, false)
end

--- @param id string|integer
--- @param optionId string|integer
--- @param data table
local function update3DTextUIOnModel(id, optionId, data)
    id = tostring(id)
    optionId = tostring(optionId)
    local g = groups[id]
    if not g or g.mode ~= 'model' then
        return
    end
    local cur = g.options[optionId]
    if not cur then
        return
    end
    for dk, dv in pairs(data) do
        cur[dk] = dv
    end
end

--- @param id string|integer
local function remove3DTextUIFromModel(id)
    groups[tostring(id)] = nil
end

--- @param id string|integer
--- @param optionId string|integer
local function remove3DTextUIFromModelOption(id, optionId)
    local g = groups[tostring(id)]
    if g then
        g.options[tostring(optionId)] = nil
        if next(g.options) == nil then
            groups[tostring(id)] = nil
        end
    end
end

return {
    create3DTextUIOnCoords = create3DTextUIOnCoords,
    update3DTextUIOnCoords = update3DTextUIOnCoords,
    remove3DTextUIFromCoords = remove3DTextUIFromCoords,
    remove3DTextUIFromCoordsOption = remove3DTextUIFromCoordsOption,

    create3DTextUIOnEntity = create3DTextUIOnEntity,
    update3DTextUIOnEntity = update3DTextUIOnEntity,
    remove3DTextUIFromEntity = remove3DTextUIFromEntity,
    remove3DTextUIFromEntityOption = remove3DTextUIFromEntityOption,

    create3DTextUIOnPlayer = create3DTextUIOnPlayer,
    update3DTextUIOnPlayer = update3DTextUIOnPlayer,
    remove3DTextUIFromPlayer = remove3DTextUIFromPlayer,
    remove3DTextUIFromPlayerOption = remove3DTextUIFromPlayerOption,

    create3DTextUIOnModel = create3DTextUIOnModel,
    update3DTextUIOnModel = update3DTextUIOnModel,
    remove3DTextUIFromModel = remove3DTextUIFromModel,
    remove3DTextUIFromModelOption = remove3DTextUIFromModelOption,
}
