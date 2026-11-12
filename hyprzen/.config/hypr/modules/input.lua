hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "ven_06cb:00-06cb:ce81-touchpad",
    enabled = true,
    sensitivity = 0.0,
    accel_profile = "adaptive",
})

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:escape",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        follow_mouse = 1,
        mouse_refocus = true,
        sensitivity = 0.0,
        accel_profile = "flat",
        numlock_by_default = true,
        left_handed = false,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            drag_lock = false,
            scroll_factor = 0.8,
            clickfinger_behavior = false,
            middle_button_emulation = false,
        },
    },
    -- gestures block variables are deprecated in Hyprland 0.55+
    -- Use the new 'gesture' directive instead.
    -- example: gesture = 3, horizontal, workspace
    -- Gestures (New Syntax for Hyprland 0.55+)
})
