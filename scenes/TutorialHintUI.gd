extends CanvasLayer

## =========================================================
## TutorialHintUI
## ผูกกับ Node โครงสร้าง:
## CanvasLayer > Control(HintBox) > Label(HintLabel)
## ทำ fade in/out ข้อความ hint ตามสัญญาณจาก TutorialManager
## =========================================================

@onready var hint_box: Control = $HintBox
@onready var hint_label: Label = $HintBox/HintLabel

const FADE_DURATION := 0.3

var _current_shown_id: String = ""


func _ready() -> void:
	# สีข้อความ Tutorial
	hint_label.add_theme_color_override(
		"font_color",
		Color("#00ffcc")
	)

	# ล็อกกล่องข้อความไว้กลางบนของจอเสมอ
	hint_box.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# ตั้ง offset ตรงๆ
	var box_width: float = hint_box.size.x
	var box_height: float = hint_box.size.y

	hint_box.offset_left = -box_width / 2.0
	hint_box.offset_right = box_width / 2.0
	hint_box.offset_top = 40.0
	hint_box.offset_bottom = 40.0 + box_height

	# เริ่มต้นให้กล่องโปร่งใส
	hint_box.modulate.a = 0.0
	hint_box.visible = false

	# เชื่อมสัญญาณจาก TutorialManager
	TutorialManager.hint_requested.connect(_on_hint_requested)
	TutorialManager.hint_dismissed.connect(_on_hint_dismissed)


func _on_hint_requested(hint_id: String, text: String) -> void:
	_current_shown_id = hint_id

	hint_label.text = text
	hint_box.visible = true

	var tween := create_tween()

	tween.tween_property(
		hint_box,
		"modulate:a",
		1.0,
		FADE_DURATION
	)


func _on_hint_dismissed(hint_id: String) -> void:
	# ถ้า hint ใหม่โผล่มาแล้ว
	# ห้าม fade-out เก่ามาซ่อน hint ใหม่
	if hint_id != _current_shown_id:
		return

	_current_shown_id = ""

	var tween := create_tween()

	tween.tween_property(
		hint_box,
		"modulate:a",
		0.0,
		FADE_DURATION
	)

	await tween.finished

	# เช็คอีกครั้งก่อนซ่อน
	if _current_shown_id == "":
		hint_box.visible = false
