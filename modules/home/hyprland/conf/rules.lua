-- Window rules.

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Allow tearing for Steam games (needs general.allow_tearing in looks.lua).
hl.window_rule({
    name      = "games-immediate",
    match     = { class = "^steam_app_.*$" },
    immediate = true,
})
