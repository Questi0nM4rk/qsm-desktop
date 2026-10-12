-- Hyprland has no public per-device enabled getter. Keep the state beside the
-- one setter used by initial configuration, shortcuts and the CLI.
local keyboard = { name = "at-translated-set-2-keyboard" }
local enabled = nil

function keyboard.status()
  if enabled == nil then return "UNKNOWN" end
  return enabled and "ENABLED" or "DISABLED"
end

function keyboard.set_enabled(value)
  assert(type(value) == "boolean", "keyboard enabled must be boolean")
  hl.device({ name = keyboard.name, enabled = value })
  enabled = value
  return keyboard.status()
end

local commands = {
  status = keyboard.status,
  enable = function() return keyboard.set_enabled(true) end,
  disable = function() return keyboard.set_enabled(false) end,
  toggle = function()
    if enabled == nil then return "UNKNOWN" end
    return keyboard.set_enabled(not enabled)
  end,
}

function keyboard.command(name)
  local command = commands[name]
  assert(command, "unknown main-keyboard command")
  return command()
end

return keyboard
