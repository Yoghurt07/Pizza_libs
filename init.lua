if not _VERSION:find('5.4') then
    error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local resourceName = GetCurrentResourceName()
local pizza_libs = 'pizza_libs'

if resourceName == pizza_libs then
    return
end

local existingPizza = rawget(_ENV, 'pizza')
if type(existingPizza) == 'table' and existingPizza.name == pizza_libs then
    error(("Cannot load pizza_libs more than once.\n\tRemove duplicate entries from '@%s/fxmanifest.lua'"):format(resourceName))
end

local export = exports[pizza_libs]

if GetResourceState(pizza_libs) ~= 'started' then
    error('^1pizza_libs must be started before this resource.^0', 0)
end

local status = export.hasLoaded()
if status ~= true then
    error(status, 2)
end

msgpack.setoption('ignore_invalid', true)

local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

--- Maps flat API names to their module folder (same idea as st_libs lazy modules + UI exports).
local METHOD_MODULE = {
    create3DTextUIOnCoords = 'interaction',
    update3DTextUIOnCoords = 'interaction',
    remove3DTextUIFromCoords = 'interaction',
    remove3DTextUIFromCoordsOption = 'interaction',
    create3DTextUIOnEntity = 'interaction',
    update3DTextUIOnEntity = 'interaction',
    remove3DTextUIFromEntity = 'interaction',
    remove3DTextUIFromEntityOption = 'interaction',
    create3DTextUIOnPlayer = 'interaction',
    update3DTextUIOnPlayer = 'interaction',
    remove3DTextUIFromPlayer = 'interaction',
    remove3DTextUIFromPlayerOption = 'interaction',
    create3DTextUIOnModel = 'interaction',
    update3DTextUIOnModel = 'interaction',
    remove3DTextUIFromModel = 'interaction',
    remove3DTextUIFromModelOption = 'interaction',
    showTextUI = 'textui',
    hideTextUI = 'textui',
    isTextUIOpen = 'textui',
    addBlip = 'blips',
    removeBlip = 'blips',
}

local notifyEvent = ('__pizza_notify_%s'):format(resourceName)

if not IsDuplicityVersion() then
    RegisterNetEvent(notifyEvent, function(data)
        exports[pizza_libs]:notify(data)
    end)
end

function noop() end

--- Load a module chunk from pizza_libs into the pizza proxy.
--- @param self table
--- @param module string
--- @return function|table|nil
local function loadModule(self, module)
    local dir = ('modules/%s'):format(module)
    local chunk = LoadResourceFile(pizza_libs, ('%s/%s.lua'):format(dir, context))
    local shared = LoadResourceFile(pizza_libs, ('%s/shared.lua'):format(dir))
    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end
    if chunk then
        local chunkname = ('@@pizza_libs/modules/%s/%s.lua'):format(module, context)
        local fn, err = load(chunk, chunkname, 't', _ENV)
        if not fn or err then
            return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
        end
        local result = fn()
        self[module] = result or noop
        if type(result) == 'table' then
            for k, v in pairs(result) do
                if type(v) == 'function' then
                    rawset(self, k, v)
                end
            end
        end
        return self[module]
    end
end

--- Metamethod: lazy-load modules or fall back to pizza_libs exports.
--- @param self table
--- @param index string
--- @return any
local function index(self, index)
    local found = rawget(self, index)
    if found ~= nil then
        return found
    end
    local modName = METHOD_MODULE[index]
    if modName and not rawget(self, modName) then
        loadModule(self, modName)
    end
    found = rawget(self, index)
    if found ~= nil then
        return found
    end
    local loaded = loadModule(self, index)
    if loaded then
        return rawget(self, index)
    end
    local exported = export[index]
    if type(exported) == 'function' then
        local function method(...)
            return exported(nil, ...)
        end
        rawset(self, index, method)
        return method
    end
end

local pizza = setmetatable({
    name = pizza_libs,
    context = context,
}, {
    __index = index,
    __call = index,
})

--- Wait until pizza_libs is running and NUI is ready, then run your setup (st_libs-style).
--- @param cb? fun()
function pizza.ready(cb)
    CreateThread(function()
        local deadline = GetGameTimer() + 30000
        while GetResourceState(pizza_libs) ~= 'started' and GetGameTimer() < deadline do
            Wait(50)
        end
        local status
        repeat
            status = export.hasLoaded()
            if status == true then
                break
            end
            Wait(50)
        until GetGameTimer() > deadline
        if status ~= true then
            error(status or '^1pizza_libs failed to become ready.^0', 2)
        end
        if cb then
            cb()
        end
    end)
end

local intervals = {}
local intervalId = 0

--- Run a callback on a fixed delay until cleared.
--- @param callback function
--- @param interval integer milliseconds
--- @param ... any arguments passed to callback
--- @return integer id
function SetInterval(callback, interval, ...)
    local packed = table.pack(...)
    intervalId = intervalId + 1
    local id = intervalId
    intervals[id] = true
    CreateThread(function()
        while intervals[id] do
            Wait(interval)
            if intervals[id] then
                callback(table.unpack(packed, 1, packed.n))
            end
        end
    end)
    return id
end

--- Stop a previously scheduled interval.
--- @param id integer|nil
function ClearInterval(id)
    if id then
        intervals[id] = nil
    end
end

local cacheValues = {}
local cacheWatchers = {}

if not IsDuplicityVersion() then
    RegisterNetEvent('pizza_libs:cache:update', function(key, value)
        cacheValues[key] = value
        local watchers = cacheWatchers[key]
        if watchers then
            for i = 1, #watchers do
                watchers[i](value, key)
            end
        end
    end)
end

--- Replicated key/value helpers for resources using pizza_libs.
--- Logical event channel per key: `pizza_libs:cache:<key>` payloads are delivered via `pizza_libs:cache:update`.
--- @class cache
local cache = setmetatable({ game = (GetGameName and GetGameName()) or 'gta5', resource = resourceName }, {
    __index = function(self, key)
        if type(key) == 'string' then
            return cacheValues[key]
        end
        return nil
    end,
})

--- Listen for cache updates for a key (client only).
--- @param key string
--- @param cb fun(value: any, key: string)
function pizza.onCache(key, cb)
    if IsDuplicityVersion() then
        return
    end
    cacheWatchers[key] = cacheWatchers[key] or {}
    table.insert(cacheWatchers[key], cb)
end

_ENV.pizza = pizza
_ENV.lib = pizza
_ENV.cache = cache

local seenMeta = {}
for _, metaKey in ipairs({ 'pizza_lib', 'pizza_libs' }) do
    for i = 1, GetNumResourceMetadata(cache.resource, metaKey) do
        local name = GetResourceMetadata(cache.resource, metaKey, i - 1)
        if name and name ~= '' and not seenMeta[name] then
            seenMeta[name] = true
            if not rawget(pizza, name) then
                local mod = loadModule(pizza, name)
                if type(mod) == 'function' then
                    pcall(mod)
                end
            end
        end
    end
end
