extends Node
## Placeholder audio (M13): two buses (Music, SFX), a generated click sound and a soft looping pad, volumes saved in
## the settings file. Everything is synthesised in code, so there are no external audio assets.

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const DEFAULTS := {"music": 40, "sfx": 70}
const RATE := 11025
const MusicRules = preload("res://scripts/domain/music_rules.gd")
const FADE := 1.2

var volumes: Dictionary = DEFAULTS.duplicate()
var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _click: AudioStreamWAV
var enabled_playback: bool = true  # tests switch it off to avoid generating samples
var catalog: Dictionary = {}
var current_track: String = ""
var _current_file: String = ""
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _poll: float = 0.0
var _fallback_pad: AudioStreamWAV
var _last_sting_battle: Object = null


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	var saved: Dictionary = Saves.load_settings()
	for k in DEFAULTS:
		volumes[k] = clampi(int(saved.get(k + "_volume", DEFAULTS[k])), 0, 100)
	_apply_all()
	get_tree().node_added.connect(_on_node_added)
	if enabled_playback and DisplayServer.get_name() != "headless":
		_start_playback()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")


## kind: "music" or "sfx"; value 0..100. Saves into the settings file (other settings are kept).
func set_volume(kind: String, value: int, persist: bool = true) -> void:
	if not DEFAULTS.has(kind):
		return
	volumes[kind] = clampi(value, 0, 100)
	_apply(kind)
	if persist:
		Saves.update_settings({kind + "_volume": volumes[kind]})


func get_volume(kind: String) -> int:
	return int(volumes.get(kind, 0))


func bus_db(kind: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS if kind == "music" else SFX_BUS))


func _apply_all() -> void:
	for k in DEFAULTS:
		_apply(k)


func _apply(kind: String) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS if kind == "music" else SFX_BUS)
	var v: int = volumes[kind]
	AudioServer.set_bus_mute(idx, v == 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 1) / 100.0))


func _start_playback() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = SFX_BUS
	_sfx.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_sfx)
	_click = _tone([660.0, 990.0], 0.07, 0.5, false)
	catalog = MusicRules.load_catalog()
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	_music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_music)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = MUSIC_BUS
	_music_b.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_music_b)
	_active = _music
	_fallback_pad = _tone([220.0, 277.18, 329.63], 6.0, 0.18, true)
	set_process(true)


## What the game is doing right now, as the music rules expect it.
func music_context() -> Dictionary:
	var ctx := {"scene": Router.current_key}
	var st: RefCounted = Game.state
	if st != null:
		var last: String = str(st.world.last_area)
		if last != "" and not Content.area(last).is_empty():
			ctx["region"] = str(Content.area(last).region)
		else:
			ctx["region"] = "jade_valley"
		var dlg: Dictionary = st.story.dialogue
		if not dlg.is_empty():
			ctx["bg"] = str(dlg.get("stage", {}).get("bg", ""))
			var hook := str(dlg.get("hook", ""))
			if hook.begins_with("event:"):
				ctx["event_id"] = hook.substr(6)
	if Game.battle != null:
		ctx["scenario_id"] = str(Game.battle.scenario_id)
	return ctx


## The track the rules pick for the moment (no playback; tests call this).
func track_now() -> String:
	if catalog.is_empty():
		catalog = MusicRules.load_catalog()
	return MusicRules.track_for(music_context(), catalog)


func _process(delta: float) -> void:
	if _music == null:
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.4
	var want := track_now()
	if want != current_track:
		play_track(want)
	var b: RefCounted = Game.battle
	if b != null and b != _last_sting_battle and str(b.outcome) != "":
		_last_sting_battle = b
		play_sting("victory" if str(b.outcome) == "victory" else "defeat")


## Crossfades to a catalog track; a missing file falls back to the soft pad so music never goes silent.
func play_track(track_id: String) -> void:
	current_track = track_id
	var file := MusicRules.track_file(track_id, catalog)
	if file != "" and file == _current_file and _active != null and _active.playing:
		return   # several slots share one recording: keep it playing instead of restarting
	_current_file = file
	var stream: AudioStream = null
	if file != "" and ResourceLoader.exists(file):
		stream = load(file)
		if stream is AudioStreamOggVorbis:
			stream = stream.duplicate()
			stream.loop = true
	if stream == null:
		stream = _fallback_pad
	var old: AudioStreamPlayer = _active
	var fresh: AudioStreamPlayer = _music_b if old == _music else _music
	fresh.stream = stream
	fresh.volume_db = -40.0
	fresh.play()
	_active = fresh
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fresh, "volume_db", 0.0, FADE)
	tw.tween_property(old, "volume_db", -40.0, FADE)
	tw.chain().tween_callback(old.stop)


## A short stinger over the music (battle result).
func play_sting(kind: String) -> void:
	var file := MusicRules.track_file(MusicRules.sting_for(kind, catalog), catalog)
	if _sfx == null or file == "" or not ResourceLoader.exists(file):
		return
	var s: AudioStream = load(file)
	_sfx.stream = s
	_sfx.play()


func play_click() -> void:
	if _sfx != null and _click != null:
		_sfx.stream = _click
		_sfx.play()


func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		n.pressed.connect(play_click)


## A short synthesised tone: a mix of sine partials; looped pads fade in and out at the seam.
func _tone(freqs: Array, seconds: float, gain: float, loop: bool) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
		s /= freqs.size()
		var env := 1.0
		if loop:
			env = 0.6 + 0.4 * sin(PI * float(i) / count)  # swell
			s *= 0.7 + 0.3 * sin(TAU * 0.25 * t)
		else:
			env = pow(1.0 - float(i) / count, 2.0)
		data.encode_s16(i * 2, int(clampf(s * env * gain, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = count
	return w
