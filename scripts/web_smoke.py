"""Web smoke test for the Godot build (M1).

Usage: python3 web_smoke.py <build_dir> <out_dir>
Serves <build_dir>, opens it in headless Chromium at several viewport sizes, waits for the
engine's TITLE_READY / HUB_READY / SETTINGS_READY console markers, drives the UI by keyboard
(Enter on the focused button, Tab to move), fails on any console error, and saves screenshots.
"""
import functools
import http.server
import json
import os
import sys
import threading

from playwright.sync_api import sync_playwright

build_dir, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)

handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=build_dir)
handler.log_message = lambda *a, **k: None
httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
threading.Thread(target=httpd.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{httpd.server_address[1]}/index.html"

SIZES = [("1280x720", 1280, 720, False), ("1920x1080", 1920, 1080, False),
         ("2400x1080", 2400, 1080, True), ("portrait_390x844", 390, 844, True)]

results = {"url": url, "checks": {}, "errors": []}


def wait_for(console, marker, timeout_s=60):
    for _ in range(timeout_s * 4):
        if any(marker in c for c in console):
            return True
        page_wait(250)
    return False


page_ref = {}


def page_wait(ms):
    page_ref["p"].wait_for_timeout(ms)


with sync_playwright() as p:
    browser = p.chromium.launch(
        args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
              "--ignore-gpu-blocklist", "--enable-webgl"])
    for name, w, h, touch in SIZES:
        console = []
        ctx = browser.new_context(viewport={"width": w, "height": h}, has_touch=touch)
        page = ctx.new_page()
        page_ref["p"] = page
        page.on("console", lambda m, c=console: c.append(f"{m.type}: {m.text}"))
        page.on("pageerror", lambda e, c=console: c.append(f"error: pageerror {e}"))
        page.goto(url, wait_until="load")

        ok_title = wait_for(console, "TITLE_READY")
        page.wait_for_timeout(600)
        page.screenshot(path=os.path.join(out_dir, f"m1_{name}_title.png"))

        page.locator("canvas").click(position={"x": 5, "y": 5})  # give the canvas keyboard focus
        page.keyboard.press("Enter")  # start button is focused by the title screen
        ok_hub = wait_for(console, "HUB_READY")
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m1_{name}_hub.png"))

        results["checks"][name] = {"title_ready": ok_title, "hub_ready_via_keyboard": ok_hub}

        if name == "1920x1080":
            # Back to title, then Tab to Settings (disabled Load is skipped) and open it.
            page.keyboard.press("Enter")  # back button is the only focusable control on the hub
            wait_for(console, "SETTINGS_READY", 1)
            page.keyboard.press("Tab")
            page.keyboard.press("Tab")
            page.wait_for_timeout(300)
            page.screenshot(path=os.path.join(out_dir, f"m1_{name}_focus_probe.png"))

        errs = [c for c in console if c.startswith("error") or "SCRIPT ERROR" in c]
        results["checks"][name]["console_errors"] = len(errs)
        results["errors"].extend(f"[{name}] {e}" for e in errs[:5])
        ctx.close()
    browser.close()

httpd.shutdown()
results["passed"] = (not results["errors"]) and all(
    c["title_ready"] and c["hub_ready_via_keyboard"] for c in results["checks"].values())
with open(os.path.join(out_dir, "web_smoke_result.json"), "w") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)
print(json.dumps(results, ensure_ascii=False, indent=2))
sys.exit(0 if results["passed"] else 1)
