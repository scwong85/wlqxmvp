# Engine spike (M0), Web target only

Date: 2026-10-14. Scope: can this cloud environment develop and build the Godot version of Jade Valley Chronicles for Web? Windows and Android were deliberately skipped.

## Verdict

**Yes for Web.** Godot 4.5.1 installs from GitHub releases, exports headless to a single-threaded Web build, and that build boots in Chromium, renders Mandarin, accepts mouse, keyboard and touch events, and reacts to viewport changes.

## Environment found

| Item | State |
|---|---|
| Godot | Not installed; installed this session from GitHub releases (4.5.1-stable) |
| Flutter / Dart | Not installed in this environment |
| Java | Present (needed later for Android) |
| Node, Python 3, git, gh | Present |
| GitHub release downloads | Reachable through the egress proxy |
| `gh` CLI token | **Invalid**, so GitHub API and `gh repo create` do not work from the shell |
| Headless Chromium | Present at `/opt/pw-browsers` (Playwright), used for the smoke test |
| Disk / RAM | 31 GB free, 7.8 GB RAM, 2 cores |

## Results

| Check | Result | Evidence |
|---|---|---|
| Godot runs headless | Pass | `4.5.1.stable.official.f62fdbde1` |
| Web export | Pass | `build/web/`: `index.wasm` 38 MB, `index.pck` 1.6 MB |
| Single-threaded build | Pass | Console: "single-threaded, no GDExtension support" (works on GitHub Pages, which cannot send COOP/COEP headers) |
| WebGL 2 (Compatibility renderer) | Pass | Console shows WebGL 2.0 |
| Mandarin rendering | Pass | `screens/landscape_start.png` |
| English toggle and fallback to Mandarin | Pass | `screens/landscape_english.png` (untranslated line stays Mandarin) |
| Mouse, keyboard input | Pass | Input log lines in screenshots |
| Touch input | Pass in emulation only | `screens/phone_landscape_after_tap.png`; **needs a real phone** |
| Landscape / portrait readout | Pass | 1280x720, 844x390, 390x844 viewports all booted |
| Self-test in engine | Pass | `SPIKE_OK` in headless and in browser |

## Findings that affect the plan

1. **Web has no system font fallback.** A character missing from the bundled font renders as an empty box. The first build showed this for "渲", which is not in the common 3,755-character set. Fix applied: `scripts/make_font_subset.py` now adds every character found in the locale JSON files to the font subset, so content can never miss a glyph. Add this as a lint gate (M13-05 already covers fallback; make the subset step part of the build).
2. **Font cost is low.** Noto Sans CJK SC subset (3,871 characters) is 1.8 MB.
3. **The `.wasm` is 38 MB uncompressed.** GitHub Pages serves it gzip-compressed, so first load is much smaller, but expect a visible load on slow mobile networks.
4. **Single-threaded export is required for Pages.** The threaded export needs cross-origin isolation headers that Pages cannot set.
5. **`gh` is not usable here.** Publishing has to go through `git push` to a repository attached to the session.

## Not tested (deferred)

Windows export, Android export, real-device touch, iOS Safari, audio, save persistence in browser storage (M2/M14).

## Reproduce

```bash
bash scripts/setup_env.sh   # installs Godot, web templates, Python deps
bash scripts/build_web.sh   # imports, exports, runs the browser smoke test
```
