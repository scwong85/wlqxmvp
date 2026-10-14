"""Web smoke test for the Godot spike build.

Usage: python3 web_smoke.py <build_dir> <out_dir>
Serves <build_dir>, opens it in headless Chromium at landscape and portrait sizes,
checks the page loads, clicks/keys/touches, toggles language, and saves screenshots.
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
port = httpd.server_address[1]
threading.Thread(target=httpd.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{port}/index.html"

results = {"url": url, "checks": {}}
console = []

with sync_playwright() as p:
    browser = p.chromium.launch(
        args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
              "--ignore-gpu-blocklist", "--enable-webgl"])

    def run(name, width, height, touch=False):
        ctx = browser.new_context(viewport={"width": width, "height": height}, has_touch=touch)
        page = ctx.new_page()
        page.on("console", lambda m: console.append(f"[{name}] {m.type}: {m.text}"))
        page.on("pageerror", lambda e: console.append(f"[{name}] pageerror: {e}"))
        page.goto(url, wait_until="load")
        # Wait for the engine to boot and print the self-test line.
        ok = False
        for _ in range(120):
            if any("SPIKE_OK" in c and c.startswith(f"[{name}]") for c in console):
                ok = True
                break
            page.wait_for_timeout(500)
        results["checks"][f"{name}_selftest_ok"] = ok
        page.wait_for_timeout(800)
        page.screenshot(path=os.path.join(out_dir, f"{name}_start.png"))
        return ctx, page

    # Landscape desktop: mouse + keyboard + language toggle.
    ctx, page = run("landscape", 1280, 720)
    box = page.locator("canvas").bounding_box()
    results["checks"]["canvas_present"] = box is not None
    if box:
        page.mouse.click(box["x"] + 150, box["y"] + box["height"] - 100)  # start button area
        page.keyboard.press("KeyA")
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, "landscape_after_input.png"))
        page.mouse.click(box["x"] + 430, box["y"] + box["height"] - 100)  # toggle language
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, "landscape_english.png"))
    ctx.close()

    # Wide phone landscape with touch.
    ctx, page = run("phone_landscape", 844, 390, touch=True)
    box = page.locator("canvas").bounding_box()
    if box:
        page.touchscreen.tap(box["x"] + box["width"] * 0.2, box["y"] + box["height"] * 0.8)
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, "phone_landscape_after_tap.png"))
    ctx.close()

    # Portrait to confirm orientation readout reacts.
    ctx, page = run("portrait", 390, 844, touch=True)
    ctx.close()
    browser.close()

httpd.shutdown()
results["console_tail"] = console[-25:]
with open(os.path.join(out_dir, "web_smoke_result.json"), "w") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)
print(json.dumps(results, ensure_ascii=False, indent=2))
