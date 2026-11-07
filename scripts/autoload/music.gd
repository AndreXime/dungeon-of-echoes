extends Node

const HUB := "res://assets/audio/music/hub_campfire.ogg"
const DUNGEON := "res://assets/audio/music/dungeon_echoes.ogg"

var _player: AudioStreamPlayer
var _current_path := ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BgmPlayer"
	_player.volume_db = -11.0
	add_child(_player)


func play_hub() -> void:
	_play(HUB, -12.0)


func play_dungeon() -> void:
	_play(DUNGEON, -10.0)


func stop() -> void:
	if _player:
		_player.stop()
	_current_path = ""


func _play(path: String, volume_db: float) -> void:
	if _current_path == path and _player.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var stream := load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_player.stream = stream
	_player.volume_db = volume_db
	_current_path = path
	_player.play()
