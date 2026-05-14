--- Send a notification to a player's client.
--- @param playerId integer
--- @param data { title?: string, description?: string, type?: 'success'|'error'|'warning'|'info', duration?: integer, position?: string }
local function notify(playerId, data)
    TriggerClientEvent('pizza_libs:notify', playerId, data)
end

return setmetatable({}, {
    __call = function(_, playerId, data)
        return notify(playerId, data)
    end,
})
