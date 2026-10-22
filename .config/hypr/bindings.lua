-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
hl.unbind("SUPER + J")
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + SHIFT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
hl.unbind("SUPER + K")
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Input methods: English, Arabic, and Mandarin (Pinyin).
o.bind("SUPER + E", "English input", "fcitx5-remote -c")
o.bind("SUPER + A", "Arabic input", "fcitx5-remote -o; fcitx5-remote -s keyboard-ara")
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + M", "Mandarin input", "fcitx5-remote -o; fcitx5-remote -s pinyin")

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  local hp_workspace = "name:HP-" .. workspace

  hl.unbind("SUPER + CTRL + " .. key)
  o.bind("SUPER + CTRL + " .. key, "Switch to HP workspace " .. workspace, hl.dsp.focus({ workspace = hp_workspace }))
  o.bind("SUPER + SHIFT + CTRL + " .. key, "Move window to HP workspace " .. workspace, hl.dsp.window.move({ workspace = hp_workspace }))
  o.bind("SUPER + SHIFT + ALT + CTRL + " .. key, "Move window silently to HP workspace " .. workspace, hl.dsp.window.move({ workspace = hp_workspace, follow = false }))
end
