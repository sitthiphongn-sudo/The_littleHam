extends CanvasLayer

## =========================================================
## TutorialHintUI
## ผูกกับ Node โครงสร้าง: CanvasLayer > Control(HintBox) > Label(HintLabel)
## ทำ fade in/out ข้อความ hint ตามสัญญาณจาก TutorialManager
## =========================================================

@onready var hint_box: Control = $HintBox
@onready var hint_label: Label = $HintBox/HintLabel

const FADE_DURATION := 0.3

var _current_shown_id: String = ""  # hint id ที่กำลังโชว์อยู่จริงตอนนี้ (กันปัญหา fade-out เก่ามาทับ hint ใหม่)

func _ready() -> void:
	# ล็อกกล่องข้อความไว้กลางบนของจอเสมอ ไม่ว่าขนาดหน้าจอจะเท่าไหร่
	hint_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# ตั้ง offset ตรงๆ แทนการใช้ .position (position คือพิกัดสัมบูรณ์ ไม่ใช่ระยะห่างจาก anchor
	# ถ้าใช้ .position กล้องจะเลื่อนกล่องหลุดจอไปทางซ้ายแทนที่จะอยู่กึ่งกลาง)
	var box_width: float = hint_box.size.x
	var box_height: float = hint_box.size.y
	hint_box.offset_left = -box_width / 2.0
	hint_box.offset_right = box_width / 2.0
	hint_box.offset_top = 40.0  # ระยะห่างจากขอบบน (px) ปรับได้ตามชอบ
	hint_box.offset_bottom = 40.0 + box_height

	hint_box.modulate.a = 0.0
	hint_box.visible = false

	TutorialManager.hint_requested.connect(_on_hint_requested)
	TutorialManager.hint_dismissed.connect(_on_hint_dismissed)


func _on_hint_requested(hint_id: String, text: String) -> void:
	_current_shown_id = hint_id
	hint_label.text = text
	hint_box.visible = true
	var tween := create_tween()
	tween.tween_property(hint_box, "modulate:a", 1.0, FADE_DURATION)


func _on_hint_dismissed(hint_id: String) -> void:
	# ถ้า hint ใหม่โผล่มาแทนที่ไปแล้วระหว่างที่ hint นี้กำลังจะ fade-out
	# (เช่น dismiss "move" แล้ว "jump" ถูก request ต่อทันที) ห้ามให้ callback เก่ามาซ่อนกล่องทับ hint ใหม่
	if hint_id != _current_shown_id:
		return
	_current_shown_id = ""

	var tween := create_tween()
	tween.tween_property(hint_box, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func():
		# เช็คซ้ำอีกทีตอน callback ทำงานจริง เผื่อมี hint ใหม่โผล่มาระหว่างรอ fade
		if _current_shown_id == "":
			hint_box.visible = false
	)
