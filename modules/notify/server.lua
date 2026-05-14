local resourceName = GetCurrentResourceName()
local notifyEvent = ('__pizza_notify_%s'):format(resourceName)

--- Send a notification to a player's client (scoped to this resource, like st_libs).
--- @param playerId integer
--- @param data { title?: string, description?: string, type?: 'success'|'error'|'warning'|'info', duration?: integer, position?: string }
local function notify(playerId, data)
    TriggerClientEvent(notifyEvent, playerId, data)
end

return setmetatable({}, {
    __call = function(_, playerId, data)
        return notify(playerId, data)
    end,
})
