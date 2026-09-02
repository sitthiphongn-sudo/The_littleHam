extends Control

## Controls / Settings screen script
## Handles the Exit button on the Controls menu.

# ชื่อ path ของ MainMenu scene ที่จะกลับไปตอนกด Exit
# ถ้า path จริงในโปรเจกต์ไม่ตรง ให้แก้ตรงนี้
@export var main_menu_scene_path: String = "res://scenes/MainMenu.tscn"

@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		push_warning("ไม่พบ scene ที่ path: %s กรุณาแก้ main_menu_scene_path ให้ตรงกับโปรเจกต์" % main_menu_scene_path)
