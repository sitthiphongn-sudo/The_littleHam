extends Node2D

## ===== ตั้งค่าตรงนี้ =====
# เวลา (วินาที) ที่จะให้วิดีโอเล่นก่อน แล้วปุ่มถึงจะโผล่มา
@export var seconds_before_buttons: float = 5.0

# path ของฉากเมนูหลัก (แก้ path ให้ตรงกับโปรเจกต์จริงถ้าจำเป็น)
@export var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"

# path ของฉากด่านแรก เอาไว้กด "เริ่มเกมใหม่"
@export var new_game_scene_path: String = "res://scenes/main_game.tscn"

@onready var video_player: VideoStreamPlayer = $VideoEnd/VideoStreamPlayer
@onready var button_container: Control = $CanvasLayer/ButtonContainer
@onready var btn_menu: Button = $CanvasLayer/ButtonContainer/VBoxContainer/BtnMenu
@onready var btn_restart: Button = $CanvasLayer/ButtonContainer/VBoxContainer/BtnRestart


func _ready() -> void:
	# ซ่อนปุ่มไว้ก่อน
	button_container.visible = false
	button_container.modulate.a = 0.0

	# เริ่มเล่นวิดีโอจบ
	video_player.play()

	# ต่อสัญญาณปุ่ม
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)

	# พอวิดีโอเล่นจบ ให้ค้างเฟรมสุดท้ายไว้ แล้วค่อยโชว์ปุ่ม
	video_player.finished.connect(_on_video_finished)


func _on_video_finished() -> void:
	# ค้างภาพเฟรมสุดท้ายไว้ ไม่ให้มันรีเซ็ตกลับไปเฟรมแรก/จอดำ
	video_player.paused = true

	# ถ้าอยากให้หน่วงอีกนิดก่อนปุ่มขึ้น (ปรับ/ลบได้ที่ seconds_before_buttons)
	if seconds_before_buttons > 0.0:
		await get_tree().create_timer(seconds_before_buttons).timeout

	_show_buttons()


func _show_buttons() -> void:
	button_container.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(button_container, "modulate:a", 1.0, 1.0)


func _on_menu_pressed() -> void:
	Transition.change_scene(main_menu_scene_path, 1.5)


func _on_restart_pressed() -> void:
	Transition.change_scene(new_game_scene_path, 1.5)
