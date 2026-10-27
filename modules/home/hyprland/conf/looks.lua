-- General layout, decoration and animations.

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
            inactive_border = "rgba(585b70aa)",
        },
        layout = "dwindle",
        -- Lets games opt into tearing through the "immediate" rule in rules.lua.
        allow_tearing = true,
    },

    decoration = {
        rounding = 8,
        shadow = { enabled = false },
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        vrr                     = 2, -- adaptive sync for fullscreen apps only
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear",       { type = "bezier", points = { { 0, 0 },    { 1, 1 } } })

hl.animation({ leaf = "global",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 4,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,  bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,  bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2,  bezier = "easeOutQuint", style = "fade" })
