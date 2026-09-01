extends Camera2D

## ระยะเลื่อนเบา ๆ ของกล้องช่วงเล่นปกติ (px)
@export var sway_amount: float = 3.0
@export var sway_speed: float = 0.7
@export var rotation_sway_amount: float = 0.02

var _time_offset := randf() * 100.0
var is_swaying := true
var is_dead_mode := false
var target_node: Node2D = null

var _tutorial_zoomed_in := false  # กันไม่ให้สั่งซูมเข้าซ้ำทุก hint

func _ready() -> void:
	# ซูมเข้าครั้งเดียวตอน hint แรกโผล่ แล้วค้างไว้จนกว่า tutorial จะจบทั้งหมด
	TutorialManager.hint_requested.connect(_on_tutorial_hint_requested)
	TutorialManager.tutorial_finished.connect(_on_tutorial_finished)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + _time_offset

	# --- โหมดตอนหนูตาย (ซูมเข้าใกล้ + ขยับกล้องไปหาหนู + เอียงซ้ายขวานุ่มๆ) ---
	if is_dead_mode:
		if is_instance_valid(target_node):
			global_position = global_position.lerp(target_node.global_position, delta * 3.0)

		var target_rotation = sin(t * 0.7) * 0.06
		rotation = lerp_angle(rotation, target_rotation, delta * 2.5)
		return

	# --- โหมดสั่น/แกว่งปกติขณะเล่น ---
	if not is_swaying:
		return

	offset.x = sin(t * sway_speed) * sway_amount
	offset.y = cos(t * sway_speed * 0.7) * sway_amount * 0.5
	rotation = sin(t * sway_speed * 0.4) * rotation_sway_amount


# =========================================================
# ฟังก์ชันสั่งซูมเข้าใกล้ตัวหนู (เรียกจาก player.gd ตอนตาย)
# =========================================================
func play_death_zoom(player_ref: Node2D = null) -> void:
	make_current()
	enabled = true
	is_swaying = false
	is_dead_mode = true
	ignore_rotation = false
	target_node = player_ref

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.5)
	tween.tween_property(self, "zoom", Vector2(4, 4), 5.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# =========================================================
# ซูมเข้าใกล้ตัวละครตอนกำลังสอน tutorial แล้วแพนออกเท่าเดิมตอนสอนจบ
# =========================================================
@export var tutorial_zoom_level: Vector2 = Vector2(5.0, 5.0)
@export var tutorial_zoom_duration: float = 0.8       ## ความเร็วตอนซูม "เข้า" (โชว์ hint แรก)
@export var tutorial_zoom_out_duration: float = 2.2    ## ความเร็วตอนซูม "ออก" (สอนจบแล้วแพนกล้องกลับ) - ช้ากว่าตอนซูมเข้า

## ค่าซูมปกติของกล้องตอนเล่นเกมจริง (ให้ตรงกับค่า zoom เริ่มต้นใน player.tscn)
@export var normal_zoom_level: Vector2 = Vector2(2.8, 2.8)

func play_tutorial_zoom() -> void:
	if is_dead_mode:
		return
	var tween := create_tween()
	tween.tween_property(self, "zoom", tutorial_zoom_level, tutorial_zoom_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func end_tutorial_zoom() -> void:
	if is_dead_mode:
		return
	var tween := create_tween()
	tween.tween_property(self, "zoom", normal_zoom_level, tutorial_zoom_out_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func _on_tutorial_hint_requested(_hint_id: String, _text: String) -> void:
	# ซูมเข้าแค่ครั้งแรกที่มี hint โผล่ขึ้นมา ส่วน hint ถัดๆ ไปกล้องค้างซูมอยู่แล้วไม่ต้องสั่งซ้ำ
	if _tutorial_zoomed_in:
		return
	_tutorial_zoomed_in = true
	play_tutorial_zoom()


func _on_tutorial_finished() -> void:
	# สอนครบทุก hint แล้ว -> ค่อยซูมออกทีเดียว
	_tutorial_zoomed_in = false
	end_tutorial_zoom()


# =========================================================
# รีเซ็ตกล้องกลับเป็นปกติเมื่อกด Restart
# =========================================================
func reset_camera() -> void:
	is_swaying = true
	is_dead_mode = false
	target_node = null
	ignore_rotation = true

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "zoom", normal_zoom_level, 0.5)
	tween.tween_property(self, "rotation", 0.0, 0.5)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.5)
