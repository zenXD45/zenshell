-- VM / VirtualBox compatibility (safe to keep on bare metal — they are ignored)
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Keep terminal apps (btop, etc.) in a UTF-8 locale. The system locale is
-- en_IN, which has no UTF-8 codeset and makes btop refuse to start.
hl.env("LANG", "en_IN.UTF-8")

hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

