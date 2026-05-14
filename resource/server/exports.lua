--- Server-side exports for pizza_libs (hasLoaded parity with client).

local pizza_libs = 'pizza_libs'

if GetCurrentResourceName() ~= pizza_libs then
    return
end

exports('hasLoaded', function()
    return true
end)
