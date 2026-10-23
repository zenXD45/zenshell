#!/usr/bin/env python3
"""Measure the camera-effects daemon: CPU, memory, frame time, per-stage profile.

  measure_camera_effects.py [seconds-per-scenario]
"""
import json
import os
import socket
import subprocess
import sys
import time

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
SOCK = os.path.join(RUNTIME, "camera-effects", "ctl.sock")
CONFIG = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
                      "camera-effects", "config.json")


def send(obj, expect_reply=True):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(SOCK)
    s.sendall((json.dumps(obj) + "\n").encode())
    if not expect_reply:
        s.close()
        return None
    s.settimeout(3)
    buf = b""
    while b"\n" not in buf:
        chunk = s.recv(400000)
        if not chunk:
            break
        buf += chunk
    s.close()
    try:
        return json.loads(buf.decode().strip().split("\n")[0])
    except Exception:
        return None


def daemon_pid():
    """The daemon the shell runs: the biggest one, and not a test copy."""
    out = subprocess.run(["pgrep", "-f", "camera-effects-server run"], capture_output=True, text=True).stdout
    best = None
    for pid in (int(p) for p in out.split()):
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as handle:
                cmdline = handle.read().decode(errors="replace")
        except OSError:
            continue
        if "--config" in cmdline:
            continue  # a manually started copy, not the shell's
        rss = os.path.getsize(f"/proc/{pid}/statm")  # rough, only for ranking
        if best is None or rss > best[1]:
            best = (pid, rss)
    return best[0] if best else None


def cpu_sample(pid):
    """utime+stime of the process, in seconds, plus its RSS."""
    with open(f"/proc/{pid}/stat") as handle:
        fields = handle.read().rsplit(")", 1)[1].split()
    utime, stime = int(fields[11]), int(fields[12])
    ticks = os.sysconf("SC_CLK_TCK")
    with open(f"/proc/{pid}/statm") as handle:
        rss_pages = int(handle.read().split()[1])
    return (utime + stime) / ticks, rss_pages * os.sysconf("SC_PAGE_SIZE") / (1024 * 1024)


def scenario(name, seconds, setup=None, consumer=False):
    if setup:
        setup()
    time.sleep(1.0)  # let the pipeline settle (the camera reopen costs a second)
    pid = daemon_pid()
    t0, rss0 = cpu_sample(pid)
    start = time.time()
    proc = None
    if consumer:
        proc = subprocess.Popen(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "v4l2", "-i", "/dev/video20",
             "-f", "null", "-"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(seconds)
    if proc:
        proc.terminate()
        proc.wait()
    t1, rss1 = cpu_sample(pid)
    elapsed = time.time() - start
    state = send({"cmd": "get"}) or {}
    cpu = (t1 - t0) / elapsed * 100.0
    print(f"{name:<34} CPU {cpu:5.1f}%   RSS {rss1:6.1f} MB   "
          f"proc {state.get('procMs', 0):>3} ms   fps {state.get('fps', 0):>2}   "
          f"out {state.get('output', {}).get('width')}x{state.get('output', {}).get('height')}")
    return state


def main():
    seconds = float(sys.argv[1]) if len(sys.argv) > 1 else 6.0
    print(f"daemon pid {daemon_pid()}\n")

    print("── scenarios " + "─" * 60)
    scenario("idle (no consumer, no preview)", seconds)
    scenario("panel open (preview only)", seconds, setup=open_panel)
    scenario("streaming 720p, all effects off", seconds, consumer=True,
             setup=lambda: (set_output(1280, 720, 30), effects(False)))
    scenario("streaming 720p, portrait + centre", seconds, consumer=True,
             setup=lambda: (set_output(1280, 720, 30), effects(True)))
    scenario("streaming 1080p, portrait + centre", seconds, consumer=True,
             setup=lambda: (set_output(1920, 1080, 30), effects(True)))
    scenario("streaming 1440p (upscale), portrait", seconds, consumer=True,
             setup=lambda: (set_output(2560, 1440, 30), effects(True)))
    scenario("streaming 1440p, all effects off", seconds, consumer=True,
             setup=lambda: (set_output(2560, 1440, 30), effects(False)))
    scenario("streaming 4K (3x upscale), effects off", seconds, consumer=True,
             setup=lambda: (set_output(3840, 2160, 30), effects(False)))
    close_panel()


def open_panel():
    subprocess.run(["quickshell", "ipc", "-p",
                    os.path.expanduser("~/.config/quickshell/dynamic-island"),
                    "call", "island", "showCamera"], capture_output=True)
    time.sleep(1.5)


def close_panel():
    subprocess.run(["quickshell", "ipc", "-p",
                    os.path.expanduser("~/.config/quickshell/dynamic-island"),
                    "call", "island", "showCamera"], capture_output=True)
    time.sleep(0.5)


def effects(on):
    send({"cmd": "set", "settings": {
        "portrait": on, "centerStage": on, "studioLight": False,
        "filter": "none", "fun": "none", "ambience": "none"}})


def set_output(w, h, fps):
    subprocess.run(["python3", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            "camera_effects_config.py"),
                    "--output", f"{w}x{h}", "--fps", str(fps)], capture_output=True)
    # The daemon must be restarted to read it; ask the shell to do that.
    subprocess.run(["quickshell", "ipc", "-p",
                    os.path.expanduser("~/.config/quickshell/dynamic-island"),
                    "call", "island", "setCameraOutput", str(w), str(h), str(fps)],
                   capture_output=True)
    time.sleep(2.5)


if __name__ == "__main__":
    main()
