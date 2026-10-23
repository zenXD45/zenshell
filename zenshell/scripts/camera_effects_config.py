#!/usr/bin/env python3
"""Write the camera-effects daemon config (output size, fps) atomically.

The daemon reads its sizes from ~/.config/camera-effects/config.json when it
starts, and there is no socket command for them — so the only way to change
the output resolution is to edit the file and restart the daemon. The panel
does exactly that, in the right order: stop the daemon, write the file, start
it again (the daemon saves its own config from memory, so writing while it
runs would be overwritten).

  camera_effects_config.py --output 1920x1080 --fps 30
  camera_effects_config.py --output 2560x1440     # keeps the current fps

Prints the new output block as JSON.
"""
import json
import os
import sys
import tempfile

CONFIG = os.path.join(
    os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
    "camera-effects",
    "config.json",
)

# The daemon clamps to these; keep the helper in the same range so what the
# panel shows is what the daemon ends up using.
MIN_W, MAX_W = 160, 4096
MIN_H, MAX_H = 120, 4096
MIN_FPS, MAX_FPS = 1, 120


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    return 2


def parse_args(argv):
    width = height = fps = None
    i = 0
    while i < len(argv):
        key = argv[i]
        if key == "--output" and i + 1 < len(argv):
            raw = argv[i + 1].lower().replace("×", "x")
            if "x" not in raw:
                return None, fail(f"bad --output value: {argv[i + 1]} (want WIDTHxHEIGHT)")
            w, _, h = raw.partition("x")
            try:
                width, height = int(w), int(h)
            except ValueError:
                return None, fail(f"bad --output value: {argv[i + 1]}")
            i += 2
        elif key == "--fps" and i + 1 < len(argv):
            try:
                fps = int(argv[i + 1])
            except ValueError:
                return None, fail(f"bad --fps value: {argv[i + 1]}")
            i += 2
        else:
            return None, fail(f"unknown argument: {key}")
    if width is None and fps is None:
        return None, fail("nothing to change (use --output WIDTHxHEIGHT and/or --fps N)")
    return (width, height, fps), None


def main():
    wanted, error = parse_args(sys.argv[1:])
    if error:
        return error

    config = {}
    try:
        with open(CONFIG, "r", encoding="utf-8") as handle:
            loaded = json.load(handle)
            if isinstance(loaded, dict):
                config = loaded
    except FileNotFoundError:
        pass
    except (OSError, ValueError):
        pass  # a broken config is rewritten from scratch below

    output = config.get("output")
    if not isinstance(output, dict):
        output = {"width": 1280, "height": 720, "fps": 30}

    if wanted[0] is not None:
        output["width"] = max(MIN_W, min(MAX_W, wanted[0]))
        output["height"] = max(MIN_H, min(MAX_H, wanted[1]))
    if wanted[2] is not None:
        output["fps"] = max(MIN_FPS, min(MAX_FPS, wanted[2]))

    config["output"] = output

    directory = os.path.dirname(CONFIG)
    os.makedirs(directory, exist_ok=True)
    handle = tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=directory, delete=False)
    try:
        json.dump(config, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    finally:
        handle.close()
    os.replace(handle.name, CONFIG)

    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
