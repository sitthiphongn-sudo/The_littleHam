extends CanvasLayer

@onready var death_label: Label = $DeathLabel
@onready var button_box: Control = $ButtonBox
@onready var color_rect: ColorRect = $ColorRect
@onready var restart_button: Button = $ButtonBox/RestartButton
@onready var exit_button: Button = $ButtonBox/ExitButton

@export var text_fade_duration: float = 0.8
@export var button_fade_duration: float = 0.5
@export var delay_before_button: float = 0.4


func _ready() -> void:
	layer = 105
	visible = false
	
	# 1. ป้องกัน ColorRect บังการคลิกเมาส์ (สำคัญมาก!)
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 2. เชื่อมต่อสัญญาณปุ่มกดอัตโนมัติ
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	if exit_button and not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)
		
	if death_label:
		death_label.modulate.a = 0.0
	if button_box:
		button_box.modulate.a = 0.0


func show_death_screen() -> void:
	visible = true
	layer = 105
	
	var tween := create_tween().set_parallel(true)
	if death_label:
		tween.tween_property(death_label, "modulate:a", 1.0, text_fade_duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
			
	if button_box:
		tween.tween_property(button_box, "modulate:a", 1.0, button_fade_duration)\
			.set_delay(delay_before_button)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)


# กดปุ่ม Restart -> เริ่มเล่นฉากนี้ใหม่
func _on_restart_button_pressed() -> void:
	# 1. ปิดหน้าจอ DeathScreen และรีเซ็ตความโปร่งใสก่อน Reload
	visible = false
	if death_label:
		death_label.modulate.a = 0.0
	if button_box:
		button_box.modulate.a = 0.0

	# 2. รีโหลดฉากปัจจุบัน
	get_tree().reload_current_scene()


# กดปุ่ม Exit -> กลับหน้าเมนูหลัก
func _on_exit_button_pressed() -> void:
	# 1. ซ่อนหน้าจอ DeathScreen และรีเซ็ตค่า Modulate
	visible = false
	if death_label:
		death_label.modulate.a = 0.0
	if button_box:
		button_box.modulate.a = 0.0
		
	# 2. ยกเลิก Tween ที่อาจจะยังทำงานค้างอยู่
	var tween = create_tween()
	if tween and tween.is_running():
		tween.kill()

	# 3. เปลี่ยนไปยังฉาก MainMenu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	
