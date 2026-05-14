local pizza_libs = 'pizza_libs'

local function sendNui(payload)
    exports[pizza_libs]:sendNui(payload)
end

local visible = false

--- Show a screen TextUI hint.
--- @param text string
--- @param opts? { position?: string }
local function showTextUI(text, opts)
    opts = opts or {}
    visible = true
    sendNui({
        type = 'pizza:textui:show',
        data = {
            text = text,
            position = opts.position or 'left-center',
        },
    })
end

--- Hide the TextUI hint if it is open.
local function hideTextUI()
    if not visible then
        return
    end
    visible = false
    sendNui({ type = 'pizza:textui:hide' })
end

--- Returns whether the TextUI is currently visible.
--- @return boolean
local function isTextUIOpen()
    return visible
end

return {
    showTextUI = showTextUI,
    hideTextUI = hideTextUI,
    isTextUIOpen = isTextUIOpen,
}
