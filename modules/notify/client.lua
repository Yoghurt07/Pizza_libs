local pizza_libs = 'pizza_libs'

local function sendNui(payload)
    exports[pizza_libs]:sendNui(payload)
end

RegisterNetEvent('pizza_libs:notify', function(data)
    sendNui({ type = 'pizza:notify', data = data })
end)

--- Show a client notification through pizza_libs NUI.
--- @param data { title?: string, description?: string, type?: 'success'|'error'|'warning'|'info', duration?: integer, position?: string }
local function notify(data)
    sendNui({ type = 'pizza:notify', data = data })
end

return setmetatable({}, {
    __call = function(_, data)
        return notify(data)
    end,
})
