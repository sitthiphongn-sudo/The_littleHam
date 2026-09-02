extends Control

# ลากปุ่มทั้ง 5 มาใส่ใน Inspector หรือปล่อยให้สคริปต์หาผ่าน group ก็ได้
@onready var menu_buttons: Array[Button] = [
	$VBoxRoot/MenuBox/NewGameButton,
	$VBoxRoot/MenuBox/ControlsButton,
	$VBoxRoot/MenuBox/SettingsButton,
	$VBoxRoot/MenuBox/CreditsButton,
	$VBoxRoot/MenuBox/ExitButton, # เพิ่ม ExitButton เข้าใน Array เพื่อให้สคริปต์ต่อสัญญาณ pressed
]

const COLOR_NORMAL := Color(0.75, 0.78, 0.85, 0.75) # เทาอมฟ้า (ปุ่มที่ไม่ได้เลือก)
const COLOR_SELECTED := Color(1, 1, 1, 1)            # ขาว (ปุ่มที่เลือกอยู่)

func _ready() -> void:
	for i in menu_buttons.size():
		var btn := menu_buttons[i]
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.focus_entered.connect(_on_button_hover.bind(btn))
		btn.pressed.connect(_on_button_pressed.bind(btn.name))
		_style_button(btn, false)

	# ตั้งให้ปุ่มบนสุด (New Game) โฟกัสอัตโนมัติตอนเปิดเกม
	menu_buttons[0].grab_focus()

	# ทำ fade-in ทั้งเมนูตอนเข้าฉาก
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)


func _on_button_hover(btn: Button) -> void:
	for b in menu_buttons:
		_style_button(b, b == btn)
	btn.grab_focus()


func _style_button(btn: Button, selected: bool) -> void:
	btn.add_theme_color_override("font_color", COLOR_SELECTED if selected else COLOR_NORMAL)
	btn.add_theme_color_override("font_focus_color", COLOR_SELECTED)
	btn.add_theme_color_override("font_hover_color", COLOR_SELECTED)

	# เอฟเฟกต์ขยับขึ้นนิดหน่อยเมื่อถูกเลือก คล้ายเกมต้นฉบับ
	var target_pos_x := 6.0 if selected else 0.0
	var tw := create_tween()
	tw.tween_property(btn, "position:x", target_pos_x, 0.15).set_trans(Tween.TRANS_SINE)


func _on_button_pressed(button_name: String) -> void:
	match button_name:
		"NewGameButton":
			Transition.change_scene("res://scenes/intro_start_game.tscn", 1.7)
		"ControlsButton":
			Transition.change_scene("res://scenes/Controls.tscn", 1.5)
		"SettingsButton":
			Transition.change_scene("res://scenes/SceneSetting.tscn", 1.5)
		"CreditsButton":
			Transition.change_scene("res://scripts/credits.tscn", 1.5)
		"ExitButton":
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	# รองรับปุ่มลูกศร/จอย เลื่อนเมนูขึ้นลง (ปกติ Godot ทำให้อัตโนมัติผ่าน Focus Neighbors
	# แต่ใส่ไว้ให้ชัวร์เผื่อยังไม่ได้ตั้งค่า Focus Neighbor ใน Inspector)
	pass
