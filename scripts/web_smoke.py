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
         ("2400x1080", 2400, 1080, True), ("portrait_390x844", 390, 844, True),
         ("portrait_360x640", 360, 640, True), ("portrait_768x1024", 768, 1024, True)]

results = {"url": url, "checks": {}, "errors": []}


def wait_for(console, marker, timeout_s=60, start=0):
    for _ in range(timeout_s * 4):
        if any(marker in c for c in console[start:]):
            return True
        page_wait(250)
    return False


page_ref = {}


def ui_pos(console, name, start=0):
    """Pixel position of a control, from the engine's latest UI_POS line after `start` (logical -> CSS px)."""
    for line in reversed(console[start:]):
        if "UI_POS" in line and f" {name}=" in line:
            vp = line.split("vp=")[1].split(" ")[0].split(",")
            x, y = line.split(f" {name}=")[1].split(" ")[0].split(",")
            return float(x) * page_ref["w"] / float(vp[0]), float(y) * page_ref["h"] / float(vp[1])
    return None


def click_ui(console, name, start=0):
    pos = ui_pos(console, name, start)
    if pos is None:
        return False
    page_ref["p"].mouse.click(pos[0], pos[1])
    return True


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
        page_ref["w"], page_ref["h"] = w, h
        page.on("console", lambda m, c=console: c.append(f"{m.type}: {m.text}"))
        page.on("pageerror", lambda e, c=console: c.append(f"error: pageerror {e}"))
        page.goto(url, wait_until="load")

        ok_title = wait_for(console, "TITLE_READY")
        page.wait_for_timeout(600)
        page.screenshot(path=os.path.join(out_dir, f"m1_{name}_title.png"))

        page.locator("canvas").click(position={"x": 5, "y": 5})  # give the canvas keyboard focus
        d0 = len(console)
        page.keyboard.press("Enter")  # start button is focused by the title screen
        ok_dlg = wait_for(console, "DIALOGUE_READY id=day1_intro", 30, d0)
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m12_{name}_dialogue.png"))
        if name.startswith("portrait"):
            wait_for(console, "dlg_continue=", 10, d0)
            click_ui(console, "dlg_continue", d0)   # tap the Continue button
        else:
            page.keyboard.press("Enter")
        page.wait_for_timeout(500)
        page.keyboard.press("Enter")
        page.wait_for_timeout(500)
        page.keyboard.press("Enter")
        ok_path = wait_for(console, "DIALOGUE_READY id=day2_path", 30, d0)   # week 1 also holds the path choice
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m12_{name}_path_choice.png"))
        if name.startswith("portrait"):
            wait_for(console, "dlg_choice1=", 10, d0)
            click_ui(console, "dlg_choice1", d0)    # tap the first path
        else:
            page.keyboard.press("Enter")            # first choice is focused
        page.wait_for_timeout(600)
        page.keyboard.press("Enter")                # continue after the choice
        ok_hub = wait_for(console, "CULT_READY", 30, d0)
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m1_{name}_cultivation.png"))

        results["checks"][name] = {"title_ready": ok_title, "intro_dialogue_shown": ok_dlg, "path_choice_dialogue": ok_path, "cultivation_ready_via_keyboard": ok_hub}

        if name == "1280x720":
            # Persistence: advance a slot (autosaves), save manually, reload the page, then load.
            page.locator("canvas").click(position={"x": 845, "y": 70})   # top-bar companions button (touch/mouse path)
            party = wait_for(console, "PARTY_SHOWN", 10)
            page.wait_for_timeout(400)
            page.screenshot(path=os.path.join(out_dir, "m7_party.png"))
            page.keyboard.press("Enter")      # focused Close button
            page.wait_for_timeout(300)
            page.locator("canvas").click(position={"x": 420, "y": 635})   # confirm button
            chooser = wait_for(console, "CHOICE_SHOWN training", 10)
            page.wait_for_timeout(400)
            page.screenshot(path=os.path.join(out_dir, "m6_chooser.png"))
            page.keyboard.press("Enter")      # first approach is focused: perform it
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
            ok_load = wait_for(console, "CULT_READY week=1 slot=2", 20, mark)
            page.wait_for_timeout(500)
            page.screenshot(path=os.path.join(out_dir, "m2_cultivation_after_load.png"))
            # Exploration in the browser: rest into day 2, open Bamboo Pass, take two steps.
            mark3 = len(console)
            page.locator("canvas").click(position={"x": 697, "y": 467})   # rest card
            page.locator("canvas").click(position={"x": 420, "y": 635})   # confirm
            ok_day2 = wait_for(console, "EVENT_SHOWN day3_recruit", 15, mark3)   # week 2 opens with the invitation pop-up
            page.wait_for_timeout(500)
            page.screenshot(path=os.path.join(out_dir, "m12_week2_invitation.png"))
            page.keyboard.press("Enter")      # continue
            wait_for(console, "RECRUIT_PROMPT shen_qinghe", 10, mark3)
            page.wait_for_timeout(400)
            page.keyboard.press("Enter")      # focused button of the prompt (maybe later)
            page.wait_for_timeout(800)
            click_ui(console, "explore", mark3)   # explore button
            ok_explore = wait_for(console, "EXPLORE_READY route=bamboo_pass node=start", 15, mark3)
            page.wait_for_timeout(500)
            page.screenshot(path=os.path.join(out_dir, "m8_explore_start.png"))
            page.keyboard.press("Enter")      # first open choice (old road)
            wait_for(console, "EXPLORE start/old_road", 10, mark3)
            page.keyboard.press("Enter")      # first open choice (greet the courier)
            ok_prompt = wait_for(console, "RECRUIT_PROMPT lu_chenzhou", 10, mark3)
            page.wait_for_timeout(400)
            page.screenshot(path=os.path.join(out_dir, "m8_explore_recruit.png"))
            results["checks"][name].update({"week2_invitation_popup": ok_day2, "explore_opens": ok_explore, "explore_recruit_prompt": ok_prompt})
            results["checks"][name].update({"party_panel_opens": party, "chooser_opens": chooser, "autosave_ok": saved, "load_enabled_after_reload": ok_reload,
                                            "loaded_slot2_after_reload": ok_load})

        if name.startswith("portrait"):
            checks = results["checks"][name]
            m0 = len(console)
            page.wait_for_timeout(400)
            page.screenshot(path=os.path.join(out_dir, f"{name}_hero_tab.png"))
            m1 = len(console)
            checks["tab_click"] = click_ui(console, "tab_activities")
            checks["tab_switched"] = wait_for(console, "UI_POS", 8, m1) and ui_pos(console, "confirm", m1) is not None
            page.wait_for_timeout(300)
            page.screenshot(path=os.path.join(out_dir, f"{name}_activities_tab.png"))
            m2 = len(console)
            if name == "portrait_390x844":
                click_ui(console, "confirm", m1)
                checks["chooser_opens"] = wait_for(console, "CHOICE_SHOWN training", 8, m2)
                page.wait_for_timeout(300)
                page.screenshot(path=os.path.join(out_dir, f"{name}_chooser.png"))
                page.keyboard.press("Enter")   # first approach is focused: perform it
                checks["autosave_ok"] = wait_for(console, "SAVE auto ok=true", 8, m2)
                m3 = len(console)
                click_ui(console, "party", m1)
                checks["party_opens"] = wait_for(console, "PARTY_SHOWN", 8, m3)
                page.wait_for_timeout(300)
                page.screenshot(path=os.path.join(out_dir, f"{name}_party.png"))
                page.keyboard.press("Enter")   # focused Close
                page.wait_for_timeout(300)
                click_ui(console, "tab_stats", m1)
                page.wait_for_timeout(500)
                page.screenshot(path=os.path.join(out_dir, f"{name}_stats_tab.png"))
                click_ui(console, "tab_activities", m1)
                m4 = len(console)
                wait_for(console, "UI_POS", 8, m4)
                click_ui(console, "card_rest", m4)         # rest -> day 2
                page.wait_for_timeout(300)
                click_ui(console, "confirm", m4)
                checks["week2_invitation_popup"] = wait_for(console, "EVENT_SHOWN day3_recruit", 15, m4)
                page.wait_for_timeout(500)
                page.screenshot(path=os.path.join(out_dir, f"{name}_week2_invitation.png"))
                page.keyboard.press("Enter")
                wait_for(console, "RECRUIT_PROMPT shen_qinghe", 10, m4)
                page.wait_for_timeout(400)
                page.screenshot(path=os.path.join(out_dir, f"{name}_week2_prompt.png"))
                page.keyboard.press("Enter")
                page.wait_for_timeout(800)
                m5 = len(console)
                click_ui(console, "map", m1)
                checks["map_opens"] = wait_for(console, "MAP_READY", 15, m5)
                page.wait_for_timeout(600)
                page.screenshot(path=os.path.join(out_dir, f"{name}_map.png"))
                m6 = len(console)
                click_ui(console, "back", m5)
                checks["map_back_to_training"] = wait_for(console, "CULT_READY", 15, m6)
                page.wait_for_timeout(500)
                m5 = len(console)
                click_ui(console, "explore", m1)
                checks["explore_opens"] = wait_for(console, "EXPLORE_READY route=bamboo_pass", 15, m5)
                page.wait_for_timeout(500)
                page.screenshot(path=os.path.join(out_dir, f"{name}_explore.png"))
                page.keyboard.press("Enter")
                wait_for(console, "EXPLORE start/old_road", 8, m5)
                page.keyboard.press("Enter")
                checks["recruit_prompt"] = wait_for(console, "RECRUIT_PROMPT lu_chenzhou", 8, m5)
                page.wait_for_timeout(400)
                page.screenshot(path=os.path.join(out_dir, f"{name}_recruit.png"))

        # Combat (M10): fresh page, practice battle, fast-forward, move, guard, end turn, enemies act.
        b0 = len(console)
        page.goto(url, wait_until="load")
        wait_for(console, "TITLE_READY", 60, b0)
        wait_for(console, "UI_POS", 10, b0)
        page.wait_for_timeout(400)
        bc = results["checks"][name]
        bc["practice_click"] = click_ui(console, "practice", b0)
        bc["battle_opens"] = wait_for(console, "BATTLE_READY scenario=training_match", 20, b0)
        wait_for(console, "act_move=", 10, b0)
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m10_{name}_battle.png"))
        page.wait_for_timeout(800)
        b1 = len(console)
        bc["move_click"] = click_ui(console, "act_move", b0)
        bc["move_mode"] = wait_for(console, "move_to=", 10, b1)
        page.wait_for_timeout(600)
        page.screenshot(path=os.path.join(out_dir, f"m10_{name}_move.png"))
        bc["move_target_click"] = click_ui(console, "move_to", b1)
        b2 = len(console)
        wait_for(console, "act_guard=", 10, b2)
        page.wait_for_timeout(600)
        b3 = len(console)
        bc["guard_click"] = click_ui(console, "act_guard", b2)
        wait_for(console, "act_end=", 10, b3)
        page.wait_for_timeout(600)
        bc["fast_click"] = click_ui(console, "ff", b0)
        page.wait_for_timeout(200)
        b4 = len(console)
        bc["end_click"] = click_ui(console, "act_end", b3)
        bc["enemies_act_then_player_again"] = wait_for(console, "act_end=", 40, b4)
        page.wait_for_timeout(500)
        page.screenshot(path=os.path.join(out_dir, f"m10_{name}_after_turn.png"))

        # Performance (M13): frame times on the battle screen, sampled for 3 s. Software rendering (SwiftShader) in a
        # container is far slower than a phone GPU, so these are an upper bound, recorded to catch regressions.
        frames = page.evaluate("""() => new Promise(res => { const t = []; let last = performance.now(); const end = last + 3000;
            function f(n) { t.push(n - last); last = n; if (n < end) requestAnimationFrame(f); else res(t); }
            requestAnimationFrame(f); })""")
        frames = sorted(frames[2:]) or [0]
        results.setdefault("perf", {})[name] = {"frames": len(frames), "avg_ms": round(sum(frames) / len(frames), 1),
                                                 "p95_ms": round(frames[int(len(frames) * 0.95) - 1], 1), "max_ms": round(frames[-1], 1)}

        if True:  # every size, portrait included, must pass the layout audit
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
