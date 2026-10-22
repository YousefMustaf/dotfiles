-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "-1280x28", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })

for workspace = 1, 10 do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "eDP-1" })
end

for workspace = 1, 10 do
  hl.workspace_rule({ workspace = "name:HP-" .. workspace, monitor = "HDMI-A-1" })
end

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
