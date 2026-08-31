extends Control

# =========================================================
# Settings Scene
# ปรับเสียง Master / Music, มีวิดีโอพื้นหลัง, มีเสียงตัวอย่าง
# ให้ได้ยินจริงตอนลาก slider, และบันทึกค่าอัตโนมัติ
# =========================================================

const SETTINGS_PATH := "user://settings.cfg"

# ชื่อ path ของ MainMenu scene ที่จะกลับไปตอนกด Back
# ถ้า path จริงในโปรเจกต์ไม่ตรง ให้แก้ตรงนี้
@export var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"

@onready var video_bg: VideoStreamPlayer = $VideoBackground
@onready var master_slider: HSlider = $VBoxContainer/MasterRow/MasterSlider
@onready var music_slider: HSlider = $VBoxContainer/MusicRow/MusicSlider
@onready var music_preview_player: AudioStreamPlayer = $MusicPreviewPlayer
@onready var back_button: Button = $BackButton

var _config := ConfigFile.new()


func _ready() -> void:
	_load_settings()
	_connect_signals()
	_start_video_background()
	_start_music_preview()


func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	back_button.pressed.connect(_on_back_pressed)
	music_preview_player.finished.connect(_on_music_preview_finished)


# =========================================================
# วิดีโอพื้นหลัง (เล่นวนไปเรื่อยๆ, ใช้ Bus "Master")
# =========================================================
func _start_video_background() -> void:
	if not video_bg.stream:
		return
	video_bg.bus = "Master"
	video_bg.play()
	if not video_bg.finished.is_connected(_on_video_finished):
		video_bg.finished.connect(_on_video_finished)


func _on_video_finished() -> void:
	video_bg.play()  # วนซ้ำเอง เพราะ VideoStreamPlayer ไม่มี loop สำเร็จรูป


# =========================================================
# เสียงตัวอย่าง Music (เล่นวนเบาๆ ให้ได้ยินตอนปรับ slider จริง)
# =========================================================
func _start_music_preview() -> void:
	if not music_preview_player.stream:
		return
	music_preview_player.bus = "Music"
	music_preview_player.play()


func _on_music_preview_finished() -> void:
	music_preview_player.play()  # วนซ้ำเอง


# =========================================================
# โหลดค่าที่เคยตั้งไว้ (ถ้ามีไฟล์) แล้วเอามาใส่ใน UI + Apply จริง
# =========================================================
func _load_settings() -> void:
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


func _save_settings() -> void:
	_config.set_value("audio", "master", master_slider.value)
	_config.set_value("audio", "music", music_slider.value)
	_config.save(SETTINGS_PATH)


# =========================================================
# ปรับเสียงแต่ละ Bus
# หมายเหตุ: ต้องมี Audio Bus ชื่อ "Master", "Music" ใน
# Audio > Bus Layout ของโปรเจกต์ก่อน ไม่งั้นจะหา bus ไม่เจอ (idx = -1)
# =========================================================
func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_value, 0.0001, 1.0)))
	AudioServer.set_bus_mute(idx, linear_value <= 0.0001)


func _on_master_changed(value: float) -> void:
	_apply_bus_volume("Master", value)
	_save_settings()


func _on_music_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	_save_settings()


# =========================================================
# ปุ่ม Back กลับไปหน้า MainMenu
# =========================================================
func _on_back_pressed() -> void:
	_save_settings()
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		push_warning("ไม่พบ scene ที่ path: %s กรุณาแก้ main_menu_scene_path ให้ตรงกับโปรเจกต์" % main_menu_scene_path)
