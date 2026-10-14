"""Web smoke test for the Godot build (M1).

Usage: python3 web_smoke.py <build_dir> <out_dir>
Serves <build_dir>, opens it in headless Chromium at several viewport sizes, waits for the
engine's TITLE_READY / CULT_READY / SETTINGS_READY console markers, drives the UI by keyboard
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


def wait_for(console, marker, timeout_s=60, start=0):
    for _ in range(timeout_s * 4):
        if any(marker in c for c in console[start:]):
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
        ok_hub = wait_for(console, "CULT_READY")
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m1_{name}_cultivation.png"))

        results["checks"][name] = {"title_ready": ok_title, "cultivation_ready_via_keyboard": ok_hub}

        if name == "1280x720":
            # Persistence: advance a slot (autosaves), save manually, reload the page, then load.
            page.keyboard.press("Enter")      # confirm button is focused: performs the default activity
            saved = wait_for(console, "SAVE auto ok=true", 10)
            page.wait_for_timeout(1500)       # let the browser flush IndexedDB
            page.screenshot(path=os.path.join(out_dir, "m2_cultivation_saved.png"))
            mark = len(console)
            page.reload(wait_until="load")
            ok_reload = wait_for(console, "TITLE_READY load_enabled=true", 60, mark)
            page.wait_for_timeout(600)
            page.screenshot(path=os.path.join(out_dir, "m2_title_after_reload.png"))
            page.locator("canvas").click(position={"x": 5, "y": 5})
            page.keyboard.press("Tab")        # start -> load (enabled now)
            page.keyboard.press("Enter")
            mark2 = len(console)
            ok_load = wait_for(console, "CULT_READY day=1 slot=2", 20, mark)
            page.wait_for_timeout(500)
            page.screenshot(path=os.path.join(out_dir, "m2_cultivation_after_load.png"))
            results["checks"][name].update({"autosave_ok": saved, "load_enabled_after_reload": ok_reload,
                                            "loaded_slot2_after_reload": ok_load})

        if not name.startswith("portrait"):  # landscape sizes must pass the layout audit
            audits = [c for c in console if "LAYOUT_AUDIT" in c]
            results["checks"][name]["audit_lines"] = [c for c in console if "LAYOUT_AUDIT" in c or "audit:" in c][:6]
            results["checks"][name]["layout_audit_clean"] = bool(audits) and all("problems=0" in c for c in audits)
        errs = [c for c in console if c.startswith("error") or "SCRIPT ERROR" in c]
        results["checks"][name]["console_errors"] = len(errs)
        results["errors"].extend(f"[{name}] {e}" for e in errs[:5])
        ctx.close()
    browser.close()

httpd.shutdown()
results["passed"] = (not results["errors"]) and all(
    all(v for k, v in c.items() if k != "console_errors") for c in results["checks"].values())
with open(os.path.join(out_dir, "web_smoke_result.json"), "w") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)
print(json.dumps(results, ensure_ascii=False, indent=2))
sys.exit(0 if results["passed"] else 1)
