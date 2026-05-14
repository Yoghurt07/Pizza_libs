--- Colored console helpers for pizza_libs consumers.

--- Print an informational message to the console.
--- @param msg string
local function info(msg)
    print(('^5[pizza_libs]^0 %s'):format(msg))
end

--- Print a warning message to the console.
--- @param msg string
local function warn(msg)
    print(('^3[pizza_libs]^0 %s'):format(msg))
end

--- Print an error message to the console.
--- @param msg string
local function err(msg)
    print(('^1[pizza_libs]^0 %s'):format(msg))
end

--- Print a debug message when `pizza_libs:debug` convar is enabled.
--- @param msg string
local function debug(msg)
    if GetConvarInt('pizza_libs:debug', 0) == 1 then
        print(('^4[pizza_libs]^0 %s'):format(msg))
    end
end

return {
    info = info,
    warn = warn,
    error = err,
    debug = debug,
}
