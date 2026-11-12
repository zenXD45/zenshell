#!/usr/bin/env python3
"""Generate Obsidian CSS snippet from quickshell theme palette — targeting Minimal theme tokens."""
import json
import sys
import colorsys
from pathlib import Path

THEMES_JSON = Path.home() / ".config" / "quickshell" / "dynamic-island" / "scripts" / "themes.json"
SNIPPETS_DIR = Path.home() / "Documents" / "obsidian-vault" / ".obsidian" / "snippets"
SNIPPET_PATH = SNIPPETS_DIR / "hyprzen-theme.css"

def load_themes():
    with open(THEMES_JSON) as f:
        return json.load(f)

def hex_to_hsl(hex_color):
    """Convert hex color to HSL (hue 0-360, saturation 0-100, lightness 0-100)."""
    hex_color = hex_color.lstrip('#')
    r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return round(h * 360), round(s * 100), round(l * 100)

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)

def generate_css(theme):
    """Generate CSS snippet targeting Minimal theme's HSL token system."""
    accent = theme["accent"]
    bg = theme["bg"]
    surface = theme["surface"]
    fg = theme["fg"]
    extra = theme["extra"]
    dark = theme["dark"]

    # Convert to HSL for Minimal's token system
    base_h, base_s, base_l = hex_to_hsl(bg)
    accent_h, accent_s, accent_l = hex_to_hsl(accent)
    extra_h, extra_s, extra_l = hex_to_hsl(extra)
    fg_h, fg_s, fg_l = hex_to_hsl(fg)

    # Build dark mode block
    dark_block = f"""
/* === DARK MODE (Minimal's .theme-dark) === */
.theme-dark,
.theme-dark.minimal-default-dark {{
  /* Base hue/saturation/lightness — drives bg1, bg2, bg3, ui1-3, tx1-3 */
  --base-h: {base_h};
  --base-s: {base_s}%;
  --base-l: {base_l}%;

  /* Accent hue/saturation/lightness — drives ax1, ax2, ax3 */
  --accent-h: {accent_h};
  --accent-s: {accent_s}%;
  --accent-l: {accent_l}%;

  /* Extra/secondary accent for links, etc. */
  --hyprzen-extra-h: {extra_h};
  --hyprzen-extra-s: {extra_s}%;
  --hyprzen-extra-l: {extra_l}%;

  /* Explicit overrides for computed tokens (more precise than auto-calc) */
  --bg1: hsl({base_h}, {base_s}%, {base_l}%);
  --bg2: hsl({base_h}, {base_s}%, {max(base_l - 2, 0)}%);
  --bg3: hsla({base_h}, {base_s}%, {min(base_l + 40, 95)}%, 0.12);

  /* UI/Border tokens */
  --ui1: hsla({base_h}, {base_s}%, {min(base_l + 15, 90)}%, 0.5);
  --ui2: hsla({base_h}, {base_s}%, {min(base_l + 20, 90)}%, 0.5);
  --ui3: hsl({accent_h}, {accent_s}%, {accent_l}%);

  /* Text tokens */
  --tx1: hsl({fg_h}, {fg_s}%, {min(fg_l + 5, 95)}%);
  --tx2: hsl({fg_h}, {fg_s}%, {max(fg_l - 20, 30)}%);
  --tx3: hsl({fg_h}, {fg_s}%, {max(fg_l - 35, 20)}%);
  --tx4: hsl({fg_h}, {fg_s}%, {max(fg_l - 10, 50)}%);

  /* Accent tokens */
  --ax1: hsl({accent_h}, {accent_s}%, {accent_l}%);
  --ax2: hsl({accent_h}, {accent_s}%, {min(accent_l + 10, 90)}%);
  --ax3: hsla({accent_h}, {accent_s}%, {accent_l}%, 0.15);

  /* Highlight tokens */
  --hl1: hsla({accent_h}, {accent_s}%, {accent_l}%, 0.25);
  --hl2: hsla({extra_h}, {extra_s}%, {extra_l}%, 0.35);

  /* Text on accent */
  --sp1: hsl({base_h}, {base_s}%, {min(base_l + 90, 100)}%);
}}"""

    # Build light mode block
    light_block = f"""
/* === LIGHT MODE (Minimal's .theme-light) === */
.theme-light,
.theme-light.minimal-default-light {{
  /* Base hue/saturation/lightness */
  --base-h: {base_h};
  --base-s: {base_s}%;
  --base-l: {base_l}%;

  /* Accent */
  --accent-h: {accent_h};
  --accent-s: {accent_s}%;
  --accent-l: {accent_l}%;

  --hyprzen-extra-h: {extra_h};
  --hyprzen-extra-s: {extra_s}%;
  --hyprzen-extra-l: {extra_l}%;

  /* Explicit overrides */
  --bg1: hsl({base_h}, {base_s}%, {base_l}%);
  --bg2: hsl({base_h}, {base_s}%, {min(base_l + 2, 98)}%);
  --bg3: hsla({base_h}, {base_s}%, {max(base_l - 40, 10)}%, 0.12);

  --ui1: hsla({base_h}, {base_s}%, {max(base_l - 15, 10)}%, 0.5);
  --ui2: hsla({base_h}, {base_s}%, {max(base_l - 20, 10)}%, 0.5);
  --ui3: hsl({accent_h}, {accent_s}%, {accent_l}%);

  --tx1: hsl({fg_h}, {fg_s}%, {max(fg_l - 5, 10)}%);
  --tx2: hsl({fg_h}, {fg_s}%, {min(fg_l + 20, 60)}%);
  --tx3: hsl({fg_h}, {fg_s}%, {min(fg_l + 35, 70)}%);
  --tx4: hsl({fg_h}, {fg_s}%, {min(fg_l + 10, 50)}%);

  --ax1: hsl({accent_h}, {accent_s}%, {accent_l}%);
  --ax2: hsl({accent_h}, {accent_s}%, {max(accent_l - 10, 30)}%);
  --ax3: hsla({accent_h}, {accent_s}%, {accent_l}%, 0.15);

  --hl1: hsla({accent_h}, {accent_s}%, {accent_l}%, 0.25);
  --hl2: hsla({extra_h}, {extra_s}%, {extra_l}%, 0.35);

  --sp1: hsl({base_h}, {base_s}%, {max(base_l - 90, 0)}%);
}}"""

    # Standard variables block
    standard_block = f"""
/* === Standard Obsidian variables (fallback for non-Minimal themes/plugins) === */
:root {{
  --background-primary: {bg};
  --background-primary-alt: {surface};
  --background-secondary: {surface};
  --background-modifier-border: {fg}33;
  --background-modifier-border-focus: {accent};
  --text-normal: {fg};
  --text-muted: {fg}99;
  --text-faint: {fg}66;
  --interactive-accent: {accent};
  --interactive-accent-rgb: {", ".join(map(str, hex_to_rgb(accent)))};
  --background-modifier-success: #a6e3a1;
  --background-modifier-warning: #f9e2af;
  --background-modifier-error: #f38ba8;
  --background-modifier-info: #89dceb;
}}

/* Force color scheme */
body {{
  color-scheme: { "dark" if dark else "light" };
}}"""

    # Combine all blocks
    css = f"""/*
 * HyprZen Theme: {theme['name']} ({theme['id']})
 * Targeting Minimal theme's HSL token system
 * Auto-generated by generate-obsidian-theme.py
 * DO NOT EDIT DIRECTLY — changes will be overwritten on theme switch
 */
{dark_block}
{light_block}
{standard_block}
"""
    return css

def main():
    if len(sys.argv) != 2:
        print("Usage: generate-obsidian-theme.py <theme-id>", file=sys.stderr)
        sys.exit(1)

    theme_id = sys.argv[1]
    themes = load_themes()

    theme = next((t for t in themes if t["id"] == theme_id), None)
    if not theme:
        print(f"Theme '{theme_id}' not found", file=sys.stderr)
        sys.exit(1)

    SNIPPETS_DIR.mkdir(parents=True, exist_ok=True)
    css = generate_css(theme)
    SNIPPET_PATH.write_text(css)

    # Enable the snippet in appearance.json
    appearance_path = Path.home() / "Documents" / "obsidian-vault" / ".obsidian" / "appearance.json"
    if appearance_path.exists():
        with open(appearance_path) as f:
            appearance = json.load(f)
        appearance.setdefault("enabledCssSnippets", [])
        if "hyprzen-theme" not in appearance["enabledCssSnippets"]:
            appearance["enabledCssSnippets"].append("hyprzen-theme")
        # Ensure base theme is Minimal
        appearance["cssTheme"] = "Minimal"
        with open(appearance_path, "w") as f:
            json.dump(appearance, f, indent=2)

    print(f"Generated Obsidian theme snippet for {theme['name']} (targeting Minimal tokens)")

if __name__ == "__main__":
    main()