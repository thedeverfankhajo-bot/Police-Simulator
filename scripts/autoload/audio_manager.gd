extends Node

var _player: AudioStreamPlayer
var _phase: float = 0.0
var _engine_level: float = 0.0
var _siren_enabled: bool = false
var _horn_until_msec: int = 0
var master_volume: float = 0.18

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.35
	_player = AudioStreamPlayer.new()
	_player.stream = generator
	_player.volume_db = -8.0
	add_child(_player)
	_player.play()

func set_engine_intensity(value: float) -> void:
	_engine_level = clampf(value, 0.0, 1.0)

func set_siren(enabled: bool) -> void:
	_siren_enabled = enabled

func play_horn() -> void:
	_horn_until_msec = Time.get_ticks_msec() + 280

func play_ui_tick() -> void:
	_horn_until_msec = Time.get_ticks_msec() + 55

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var playback := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := mini(playback.get_frames_available(), 1024)
	for index in range(frames):
		var time_now := Time.get_ticks_msec()
		var frequency := 48.0 + _engine_level * 115.0
		var amplitude := (0.004 + _engine_level * 0.018) * master_volume
		if _siren_enabled:
			frequency = 690.0 if int(time_now / 330) % 2 == 0 else 880.0
			amplitude = 0.035 * master_volume
		elif time_now < _horn_until_msec:
			frequency = 420.0
			amplitude = 0.045 * master_volume
		_phase += TAU * frequency / 22050.0
		if _phase > TAU:
			_phase -= TAU
		var sample := sin(_phase) * amplitude
		playback.push_frame(Vector2(sample, sample))
func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
		remove_child(_player)
		_player.free()
	_player = null
