extends CanvasLayer

# =========================================================
# Pause Menu
# - กด ESC หรือปุ่ม Pause มุมขวาบน -> หยุดเกมทั้งหมด
# - ปรับเสียง Master / Music ได้ระหว่าง pause (ค่า sync กับหน้า Settings)
# - ปุ่ม Resume กลับไปเล่นต่อ / ปุ่ม Main Menu ออกไปหน้าเมนู
# =========================================================

const SETTINGS_PATH := "user://settings.cfg"

@export var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"

@onready var pause_button: Button = $PauseButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var master_slider: HSlider = $PauseOverlay/Panel/VBoxContainer/MasterRow/MasterSlider
@onready var music_slider: HSlider = $PauseOverlay/Panel/VBoxContainer/MusicRow/MusicSlider
@onready var resume_button: Button = $PauseOverlay/Panel/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $PauseOverlay/Panel/VBoxContainer/MainMenuButton

var _config := ConfigFile.new()


func _ready() -> void:
	# ทำให้เมนูนี้ยังทำงาน/รับ input ได้อยู่ แม้เกมจะถูก pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_overlay.visible = false
	_load_audio_settings()

	pause_button.pressed.connect(_pause_game)
	resume_button.pressed.connect(_resume_game)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()


# =========================================================
# Pause / Resume
# =========================================================
func _pause_game() -> void:
	get_tree().paused = true
	pause_overlay.visible = true
	pause_button.visible = false


func _resume_game() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	pause_button.visible = true


func _on_main_menu_pressed() -> void:
	get_tree().paused = false  # สำคัญมาก: ต้องปลด pause ก่อนเปลี่ยน scene ไม่งั้น MainMenu จะค้าง
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		push_warning("ไม่พบ scene ที่ path: %s กรุณาแก้ main_menu_scene_path ให้ตรงกับโปรเจกต์" % main_menu_scene_path)


# =========================================================
# เสียง Master / Music (ใช้ config ไฟล์เดียวกับหน้า Settings)
# =========================================================
func _load_audio_settings() -> void:
	var err := _config.load(SETTINGS_PATH)

	var master_vol: float = 1.0
	var music_vol: float = 1.0

	if err == OK:
		master_vol = _config.get_value("audio", "master", 1.0)
		music_vol = _config.get_value("audio", "music", 1.0)

	master_slider.value = master_vol
	music_slider.value = music_vol

	_apply_bus_volume("Master", master_vol)
	_apply_bus_volume("Music", music_vol)


func _save_audio_settings() -> void:
	_config.set_value("audio", "master", master_slider.value)
	_config.set_value("audio", "music", music_slider.value)
	_config.save(SETTINGS_PATH)


func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_value, 0.0001, 1.0)))
	AudioServer.set_bus_mute(idx, linear_value <= 0.0001)


func _on_master_changed(value: float) -> void:
	_apply_bus_volume("Master", value)
	_save_audio_settings()


func _on_music_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	_save_audio_settings()
