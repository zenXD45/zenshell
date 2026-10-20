#!/usr/bin/env python3
import os
import re
import json

CONFIG_PATH = os.path.expanduser("~/.config/hypr/modules/keybinds.lua")

def human_readable_action(action):
    # Exact mappings
    mappings = {
        '~/.config/quickshell/dynamic-island/island_ctl.sh launcher': 'Open App Launcher',
        '~/.config/quickshell/dynamic-island/modules/spotlight/toggle.sh': 'Toggle Spotlight Search',
        'hyprswitch gui --mod-key alt_l --key tab --close mod-key-release --reverse-key=mod=shift --sort-recent --ignore-workspaces': 'Window Switcher',
        '~/.config/quickshell/dynamic-island/island_ctl.sh cheatsheet': 'Keybinds Cheatsheet',
        '~/.config/quickshell/dynamic-island/island_ctl.sh clipboard': 'Clipboard Manager',
        '~/.config/quickshell/dynamic-island/island_ctl.sh power': 'Power Menu',
        '~/.config/quickshell/dynamic-island/island_ctl.sh control': 'Control Center / Notifications',
        '~/.config/quickshell/dynamic-island/island_ctl.sh profiles': 'Open Profile Switcher',
        'hyprlock': 'Lock Screen',
        '~/.config/quickshell/dynamic-island/island_ctl.sh powerprofile': 'Power Profiles',
        '~/.config/quickshell/dynamic-island/island_ctl.sh themes': 'Theme Switcher',
        '~/.config/quickshell/dynamic-island/island_ctl.sh wallpapers': 'Wallpaper Selector',
        'hyprshade toggle oled': 'Toggle OLED Shader',
        'quickshell ipc -p ~/.config/quickshell/dynamic-island/modules/desktop-widgets call widgets toggle': 'Toggle Desktop Widgets',
        'wlogout -b 5 -T 350 -B 350': 'Logout Menu',
        '~/scripts/caffeine.sh': 'Toggle Caffeine',
    }
    if action in mappings:
        return mappings[action]

    # Pattern matchers
    if "hyprshot" in action:
        if "output" in action: return "Screenshot Full Screen"
        if "region" in action and "wl-copy" in action: return "Screenshot Region (Edit)"
        if "region" in action and "clipboard-only" in action: return "Screenshot Region (Copy)"
        return "Take Screenshot"
    
    if action == "hl.dsp.window.close()": return "Close Window"
    if "window.fullscreen" in action and "maximized" in action: return "Maximize Window"
    if "window.fullscreen" in action: return "Fullscreen Window"
    if "window.float" in action: return "Toggle Floating Window"
    if "window.pseudo" in action: return "Toggle Pseudo Tiling"
    if "window.set_prop" in action and "opaque" in action: return "Toggle Window Opacity"
    
    if "focus({ direction =" in action:
        m = re.search(r'direction = "(.*?)"', action)
        if m: return f"Move Focus {m.group(1).capitalize()}"
    
    if "window.move({ direction =" in action:
        m = re.search(r'direction = "(.*?)"', action)
        if m:
            dir_map = {'l': 'Left', 'r': 'Right', 'u': 'Up', 'd': 'Down'}
            return f"Move Window {dir_map.get(m.group(1), m.group(1))}"
        
    if "window.resize" in action:
        return "Resize Active Window"

    if "focus({ workspace =" in action:
        m = re.search(r'workspace = (\d+|".*?")', action)
        if m:
            ws = m.group(1).replace('"', '')
            if ws == 'e+1': return "Next Workspace"
            if ws == 'e-1': return "Previous Workspace"
            return f"Switch to Workspace {ws}"

    if "window.move({ workspace =" in action:
        m = re.search(r'workspace = (\d+|".*?")', action)
        if m:
            ws = m.group(1).replace('"', '')
            if ws == "special:magic": return "Move to Special Workspace"
            return f"Move Window to Workspace {ws}"

    if action == "Toggle scrolloverview": return "Toggle Overview"
    if "workspace.toggle_special" in action: return "Toggle Special Workspace"
    if "window.drag()" in action: return "Drag Window (Mouse)"
    if "window.resize()" in action: return "Resize Window (Mouse)"

    if "osd_control.sh volume up" in action: return "Volume Up"
    if "osd_control.sh volume down" in action: return "Volume Down"
    if "osd_control.sh volume mute" in action: return "Toggle Audio Mute"
    if "osd_control.sh volume mic-mute" in action: return "Toggle Mic Mute"
    if "playerctl play-pause" in action: return "Play/Pause Media"
    if "playerctl next" in action: return "Next Track"
    if "playerctl previous" in action: return "Previous Track"
    
    if "osd_control.sh brightness up" in action: return "Brightness Up"
    if "osd_control.sh brightness down" in action: return "Brightness Down"

    if "hyprctl reload" in action: return "Reload Hyprland Config"
    if "hl.dsp.exit()" in action: return "Exit Hyprland"

    # Fallbacks for any uncaught hl.dsp.exec_cmd
    act = action.replace("hl.dsp.", "")
    act = re.sub(r'\(\{[^}]*\}\)$', '', act)
    act = re.sub(r'\(".*"\)$', '', act)
    act = re.sub(r'\(\)$', '', act)

    # Last resort: show a readable command name, never a raw shell line.
    # This is what produced entries like
    # "quickshell ipc -p ~/.config/... call widgets toggle".
    first = act.split()[0] if act.split() else act
    label = os.path.basename(first).rsplit(".", 1)[0]
    label = label.replace("_", " ").replace("-", " ").strip()
    return label.title() if label else "Action"

def parse_keybinds():
    if not os.path.exists(CONFIG_PATH):
        return []

    keybinds = []
    current_category = "General"

    with open(CONFIG_PATH, "r") as f:
        for line in f:
            line = line.strip()
            
            if line.startswith("-- ──"):
                cat = line.replace("-- ──", "").strip()
                cat = re.sub(r'─+$', '', cat).strip()
                # Drop parenthetical implementation notes: "Clipboard (ZenShell
                # island)" is a heading, not a sentence.
                cat = re.sub(r'\s*\([^)]*\)\s*', ' ', cat).strip()
                if cat:
                    current_category = cat
                continue

            if line.startswith("hl.bind(") and not line.startswith("--"):
                match = re.match(r'hl\.bind\((.*?),\s*(.*)\)', line)
                if not match:
                    continue
                
                key_raw = match.group(1)
                action_raw = match.group(2)
                
                # Format Key (order matters: super+shift/ctrl/alt BEFORE super)
                key = key_raw
                key = key.replace('SS .. " + ', 'SUPER+SHIFT + ')
                key = key.replace('SC .. " + ', 'SUPER+CTRL + ')
                key = key.replace('SA .. " + ', 'SUPER+ALT + ')
                key = key.replace('S .. " + ', 'SUPER + ')
                key = key.replace('"', '').strip()

                if action_raw.startswith("function"):
                    action_raw = "Toggle scrolloverview"
                
                # Strip ending parenthesis and commas if any
                if action_raw.endswith("})"):
                    action_raw = action_raw[:-1]
                if action_raw.endswith("), { locked = true }"):
                    action_raw = action_raw.replace("), { locked = true }", ")")
                if action_raw.endswith("), { locked = true, repeating = true }"):
                    action_raw = action_raw.replace("), { locked = true, repeating = true }", ")")
                if action_raw.endswith("), { repeating = true }"):
                    action_raw = action_raw.replace("), { repeating = true }", ")")

                if action_raw.startswith("hl.dsp.exec_cmd("):
                    action_raw = action_raw.replace('hl.dsp.exec_cmd("', '')
                    action_raw = action_raw.replace('")', '')
                    action_raw = action_raw.replace('")', '')
                    if action_raw.endswith('"'): action_raw = action_raw[:-1]
                    
                action = human_readable_action(action_raw)

                keybinds.append({
                    "category": current_category,
                    "key": key,
                    "action": action
                })

    # Drop exact duplicates (the Lua file lists a few binds twice for clarity).
    seen = set()
    unique = []
    for bind in keybinds:
        ident = (bind["category"], bind["key"], bind["action"])
        if ident in seen:
            continue
        seen.add(ident)
        unique.append(bind)
    return unique

if __name__ == "__main__":
    print(json.dumps(parse_keybinds()))
