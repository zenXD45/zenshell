hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("easeOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint",
    style = "popin 91%",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 6,
    bezier = "easeOutQuint",
    style = "popin 91%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "easeOut",
    style = "popin 95%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 8,
    bezier = "linear",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 80,
    bezier = "linear",
    style = "loop",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "md3_decel",
    style = "slidefade 15%",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 6,
    bezier = "md3_decel",
    style = "slidefadevert 15%",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint",
    style = "fade",
})
hl.config({
    animations = {
        enabled = true,
        -- Premium Bezier Curves
    },
})
