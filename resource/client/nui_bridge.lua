--- NUI bridge for pizza_libs. SendNUIMessage only targets this resource's ui_page.

local pizza_libs = 'pizza_libs'

if GetCurrentResourceName() ~= pizza_libs then
    return
end

local actionHandlers = {}

--- Register a handler invoked from the NUI page (generic nui_callback).
--- @param action string
--- @param handler fun(data: table): any?
local function registerNuiActionHandler(action, handler)
    actionHandlers[action] = handler
end

--- @param action string
local function clearNuiActionHandler(action)
    actionHandlers[action] = nil
end

--- @param payload table
local function sendNui(payload)
    SendNUIMessage(payload)
end

exports('hasLoaded', function()
    return true
end)

exports('sendNui', sendNui)
exports('registerNuiActionHandler', registerNuiActionHandler)
exports('clearNuiActionHandler', clearNuiActionHandler)

RegisterNUICallback('nui_callback', function(body, cb)
    local action = body and body.action
    local handler = action and actionHandlers[action]
    if handler then
        local ok, err = pcall(handler, body)
        if not ok then
            print(('[pizza_libs] NUI handler error (%s): %s'):format(tostring(action), tostring(err)))
        end
    end
    cb({ ok = true })
end)
