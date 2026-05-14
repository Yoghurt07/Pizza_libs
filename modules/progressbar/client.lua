local pizza_libs = 'pizza_libs'

local function sendNui(payload)
    exports[pizza_libs]:sendNui(payload)
end

local function registerHandler(action, handler)
    exports[pizza_libs]:registerNuiActionHandler(action, handler)
end

local function clearHandler(action)
    exports[pizza_libs]:clearNuiActionHandler(action)
end

local function loadAnim(dict, clip, flags)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not HasAnimDictLoaded(dict) then
        return false
    end
    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, flags or 49, 0.0, false, false, false)
    return true
end

local function stopAnim()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

local function applyDisables(disable)
    if not disable then
        return
    end
    if disable.move then
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 32, true)
        DisableControlAction(0, 33, true)
        DisableControlAction(0, 34, true)
        DisableControlAction(0, 35, true)
        DisableControlAction(0, 21, true)
    end
    if disable.car then
        DisableControlAction(0, 63, true)
        DisableControlAction(0, 64, true)
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
        DisableControlAction(0, 75, true)
    end
    if disable.combat then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 47, true)
        DisableControlAction(0, 58, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
    end
end

--- Show a blocking progress bar with optional animation and control disables.
--- @param opts { label: string, duration: integer, useWhileDead?: boolean, canCancel?: boolean, disable?: table, anim?: { dict: string, clip: string }, onFinish?: function, onCancel?: function }
--- @return boolean success False when cancelled or interrupted.
local function progressbar(opts)
    local ped = PlayerPedId()
    if not opts.useWhileDead and IsEntityDead(ped) then
        return false
    end

    local duration = math.max(0, math.floor(opts.duration or 0))
    local cancelled = false

    registerHandler('progressbar:cancel', function()
        if opts.canCancel then
            cancelled = true
        end
    end)

    sendNui({
        type = 'pizza:progressbar',
        data = {
            action = 'start',
            label = opts.label or '',
            duration = duration,
            canCancel = opts.canCancel == true,
        },
    })

    local animStarted = false
    if opts.anim and opts.anim.dict and opts.anim.clip then
        animStarted = loadAnim(opts.anim.dict, opts.anim.clip, 49)
    end

    local start = GetGameTimer()
    while GetGameTimer() - start < duration do
        if cancelled then
            break
        end
        if not opts.useWhileDead and IsEntityDead(PlayerPedId()) then
            cancelled = true
            break
        end
        applyDisables(opts.disable)
        if opts.canCancel then
            for _, ctrl in ipairs({ 177, 199, 202, 194 }) do
                DisableControlAction(0, ctrl, true)
                if IsDisabledControlJustPressed(0, ctrl) then
                    cancelled = true
                end
            end
        end
        Wait(0)
    end

    if animStarted then
        stopAnim()
    end

    clearHandler('progressbar:cancel')
    sendNui({ type = 'pizza:progressbar', data = { action = 'stop' } })

    if cancelled then
        if opts.onCancel then
            opts.onCancel()
        end
        return false
    end
    if opts.onFinish then
        opts.onFinish()
    end
    return true
end

return progressbar
