--- Bootstrap for the pizza_libs resource (runs inside @pizza_libs only).
--- Registers globals used by internal scripts and marks the resource as ready.

local pizza_libs = 'pizza_libs'

if GetCurrentResourceName() ~= pizza_libs then
    return
end

_ENV.pizza_libs_ready = true
