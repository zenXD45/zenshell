-- Every value here is theme-driven. See modules/general.lua for the rationale.
-- `or` fallbacks mean a theme file missing a key degrades gracefully instead of
-- erroring out and taking the whole Hyprland config down with it.
hl.config({
    decoration = {
        rounding = rounding or 12,
        active_opacity = 1.0,
        inactive_opacity = inactive_opacity or 0.90,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = shadow_color or "rgba(00000066)",
        },
        blur = {
            enabled = true,
            size = blur_size or 4,
            passes = blur_passes or 2,
            ignore_opacity = true,
            noise = 0.08,
            contrast = 1.5,
            xray = false,
            new_optimizations = true,
        },
    },
})
