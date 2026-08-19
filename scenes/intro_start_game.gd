extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

var _transitioning := false   # กันไม่ให้เรียกซ้ำ แทนการเช็ค is_playing()

func _ready() -> void:
	video_player.play()
	video_player.finished.connect(_go_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_go_to_menu()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_menu()

func _go_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	video_player.stop()
	Transition.change_scene("res://scenes/main_game.tscn", 1.7, "THE LITTLE HAM\nESCAPE")
