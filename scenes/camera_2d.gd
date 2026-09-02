extends Camera2D


# =========================================================
# 🌊 การแกว่งกล้องปกติ
# =========================================================

@export var sway_amount: float = 3.0
@export var sway_speed: float = 0.7
@export var rotation_sway_amount: float = 0.02


# =========================================================
# 🔄 ค่า Zoom หลัง Restart
#
# ปรับตรงนี้ได้เลย
# เช่น Vector2(2.5, 2.5)
# =========================================================

@export var restart_zoom: Vector2 = Vector2(3.0, 3.0)


# =========================================================
# ☠️ ค่า Zoom ตอนตาย
# =========================================================

@export var death_zoom: Vector2 = Vector2(4.0, 4.0)
@export var death_zoom_duration: float = 5.0


# =========================================================
# 📚 Tutorial Zoom
# =========================================================

@export var tutorial_zoom_level: Vector2 = Vector2(5.0, 5.0)
@export var tutorial_zoom_duration: float = 0.8
@export var tutorial_zoom_out_duration: float = 2.2


# =========================================================
# ตัวแปรระบบ
# =========================================================

var _time_offset := randf() * 100.0

var is_swaying := true
var is_dead_mode := false

var target_node: Node2D = null

var _tutorial_zoomed_in := false

var _active_tween: Tween = null


# =========================================================
# 🎯 Zoom ตอนเปิดเกมครั้งแรก
#
# จะจำค่าจาก Inspector
# =========================================================

var _initial_zoom: Vector2


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# จำค่า Zoom เดิมที่ตั้งใน Inspector
	# ใช้สำหรับตอนเปิดเกมครั้งแรก
	_initial_zoom = zoom


	# เชื่อม Tutorial
	if not TutorialManager.hint_requested.is_connected(
		_on_tutorial_hint_requested
	):
		TutorialManager.hint_requested.connect(
			_on_tutorial_hint_requested
		)


	if not TutorialManager.tutorial_finished.is_connected(
		_on_tutorial_finished
	):
		TutorialManager.tutorial_finished.connect(
			_on_tutorial_finished
		)


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	var t := (
		Time.get_ticks_msec() / 1000.0
		+ _time_offset
	)


	# =====================================================
	# ☠️ โหมดตอนตาย
	# =====================================================

	if is_dead_mode:

		if is_instance_valid(target_node):

			global_position = global_position.lerp(
				target_node.global_position,
				delta * 3.0
			)


		# เอียงกล้องเบา ๆ ตอนตาย
		var target_rotation := sin(t * 0.7) * 0.06


		rotation = lerp_angle(
			rotation,
			target_rotation,
			delta * 2.5
		)

		return


	# =====================================================
	# 🌊 กล้องแกว่งปกติ
	# =====================================================

	if not is_swaying:
		return


	offset.x = (
		sin(t * sway_speed)
		* sway_amount
	)


	offset.y = (
		cos(t * sway_speed * 0.7)
		* sway_amount
		* 0.5
	)


	rotation = (
		sin(t * sway_speed * 0.4)
		* rotation_sway_amount
	)


# =========================================================
# 🛑 หยุด Tween เก่า
# =========================================================

func _kill_active_tween() -> void:

	if _active_tween:

		if _active_tween.is_running():

			_active_tween.kill()


# =========================================================
# ☠️ ซูมตอนตาย
#
# เรียกจาก Player
# =========================================================

func play_death_zoom(
	player_ref: Node2D = null
) -> void:

	_kill_active_tween()


	make_current()

	enabled = true


	# หยุดกล้องแกว่ง
	is_swaying = false


	# เปิดโหมดตาย
	is_dead_mode = true


	# ให้กล้องหมุนตอนตาย
	ignore_rotation = false


	# จำ Player ที่ตาย
	target_node = player_ref


	# รีเซ็ต Offset ก่อน
	offset = Vector2.ZERO


	# Tween ซูม
	_active_tween = (
		create_tween()
		.set_parallel(true)
	)


	_active_tween.tween_property(

		self,

		"zoom",

		death_zoom,

		death_zoom_duration

	).set_trans(

		Tween.TRANS_SINE

	).set_ease(

		Tween.EASE_OUT
	)


# =========================================================
# 📚 Tutorial Zoom เข้า
# =========================================================

func play_tutorial_zoom() -> void:

	# ถ้าตายอยู่ ไม่ให้ Tutorial เปลี่ยน Zoom
	if is_dead_mode:
		return


	_kill_active_tween()


	_active_tween = create_tween()


	_active_tween.tween_property(

		self,

		"zoom",

		tutorial_zoom_level,

		tutorial_zoom_duration

	).set_trans(

		Tween.TRANS_SINE

	).set_ease(

		Tween.EASE_OUT
	)


# =========================================================
# 📚 Tutorial Zoom ออก
# =========================================================

func end_tutorial_zoom() -> void:

	# ถ้าตายอยู่ ไม่ทำงาน
	if is_dead_mode:
		return


	_kill_active_tween()


	_active_tween = create_tween()


	# ถ้าเคย Restart แล้ว
	# จะกลับไป restart_zoom
	#
	# ถ้ายังไม่ Restart
	# จะกลับไป Zoom ตอนเปิดเกม


	var target_zoom: Vector2


	if _has_restarted:

		target_zoom = restart_zoom

	else:

		target_zoom = _initial_zoom


	_active_tween.tween_property(

		self,

		"zoom",

		target_zoom,

		tutorial_zoom_out_duration

	).set_trans(

		Tween.TRANS_SINE

	).set_ease(

		Tween.EASE_OUT
	)


# =========================================================
# 📚 Tutorial เริ่ม
# =========================================================

func _on_tutorial_hint_requested(
	_hint_id: String,
	_text: String
) -> void:

	if _tutorial_zoomed_in:
		return


	_tutorial_zoomed_in = true


	play_tutorial_zoom()


# =========================================================
# 📚 Tutorial จบ
# =========================================================

func _on_tutorial_finished() -> void:

	_tutorial_zoomed_in = false


	end_tutorial_zoom()


# =========================================================
# 🔄 ตรวจสอบว่าเคย Restart หรือยัง
# =========================================================

var _has_restarted := false


# =========================================================
# 🔥 RESET CAMERA
#
# ฟังก์ชันนี้ต้องถูกเรียกตอนกด Restart
# =========================================================

func reset_camera() -> void:

	_kill_active_tween()


	# บอกว่าตอนนี้เกมผ่านการ Restart แล้ว
	_has_restarted = true


	# ปิดโหมดตาย
	is_dead_mode = false


	# ล้าง Player เป้าหมาย
	target_node = null


	# เปิดการแกว่ง
	is_swaying = true


	# =====================================================
	# 🔥 ใช้ Zoom หลัง Restart
	#
	# ปรับค่าจาก:
	#
	# @export var restart_zoom
	# =====================================================

	zoom = restart_zoom


	# รีเซ็ต Offset
	offset = Vector2.ZERO


	# รีเซ็ตการหมุน
	rotation = 0.0


	# กลับเป็นการหมุนปกติ
	ignore_rotation = true
