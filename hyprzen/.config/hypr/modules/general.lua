-- Geometry comes from the active theme (themes/current_theme.lua) so that
-- switching themes actually changes the shape of the desktop, not just colours.
-- Fallbacks keep a malformed/partial theme file from breaking the whole config.
hl.config({
    general = {
        gaps_in = gaps_in or 4,
        gaps_out = gaps_out or 8,
        border_size = border_size or 2,
        col = {
            active_border = border_active,
            inactive_border = border_inactive,
        },
        layout = "dwindle",
        resize_on_border = true,
        allow_tearing = false,
    },
    dwindle = {
        preserve_split = true,
        smart_resizing = true,
    },
    master = {
        new_status = "slave",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})
