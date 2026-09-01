extends CharacterBody2D

# --- จุดโค้งการเคลื่อนที่ (ซ้าย -> กลาง(สูงสุด) -> ขวา) ---
@export var arc_side_offset: float = 150.0   # ระยะห่างซ้าย/ขวาจากจุดกึ่งกลาง
@export var arc_peak_height: float = 80.0   # ความสูงจุดยอดโค้ง (ค่ายิ่งมาก ยิ่งขึ้นสูง)
@export var hidden_offset: float = 150.0     # ความลึกที่ซ่อนอยู่ใต้พื้น/น้ำ ตอนเริ่ม-จบ

# --- ความเร็ว/จังหวะ ---
@export var arc_duration: float = 6.0        # เวลาทั้งหมดที่ใช้เคลื่อนที่โค้ง (ยิ่งมาก ยิ่งช้า)
@export var rotation_speed_degrees: float = 90.0   # หมุนกี่องศาต่อวินาที (ช้าๆ)

# --- เวลาสุ่มก่อนโผล่ขึ้นมาแต่ละรอบ ---
@export var min_wait_time: float = 2.0
@export var max_wait_time: float = 6.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $jakk
@onready var spawn_timer: Timer = $SpawnTimer
@onready var sfx_player: AudioStreamPlayer2D = $SoundPlayer  # เพิ่มโหนดเล่นเสียง 2D

var start_position: Vector2
var is_active := false
var _rotation_tween: Tween


func _ready() -> void:
	start_position = position
	position = start_position + Vector2(-arc_side_offset, hidden_offset)
	rotation_degrees = 0.0
	z_index = -10

	if hitbox:
		hitbox.body_entered.connect(_on_jakk_body_entered)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_start_random_timer()


func _start_random_timer() -> void:
	spawn_timer.wait_time = randf_range(min_wait_time, max_wait_time)
	spawn_timer.one_shot = true
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	activate()


func activate() -> void:
	if is_active:
		return
	is_active = true
	z_index = 5

	if anim_player.has_animation("swing"):
		anim_player.play("swing")

	# --- เล่นเสียงพร้อม Animation ---
	if sfx_player and sfx_player.stream:
		sfx_player.play()

	# --- เริ่มหมุนช้าๆ ต่อเนื่องตลอดการเคลื่อนที่ ---
	_start_slow_rotation()

	await _move_arc()

	# --- หยุดหมุนและหยุดเสียงตอนจบ ---
	if _rotation_tween:
		_rotation_tween.kill()
	rotation_degrees = 0.0

	if anim_player.has_animation("swing"):
		anim_player.stop()

	if sfx_player:
		sfx_player.stop()

	z_index = -10
	is_active = false
	_start_random_timer()


func _start_slow_rotation() -> void:
	if _rotation_tween:
		_rotation_tween.kill()
	_rotation_tween = create_tween()
	_rotation_tween.set_loops()
	var spin_time := 360.0 / rotation_speed_degrees
	_rotation_tween.tween_property(self, "rotation_degrees", 360.0, spin_time)\
		.as_relative().set_trans(Tween.TRANS_LINEAR)


# เคลื่อนที่เป็นเส้นโค้ง (Quadratic Bezier): ซ่อนซ้าย -> จุดยอดกลาง -> ซ่อนขวา
func _move_arc() -> void:
	var p0 := start_position + Vector2(-arc_side_offset, hidden_offset)   # จุดเริ่ม (ซ่อนซ้าย)
	var p2 := start_position + Vector2(arc_side_offset, hidden_offset)    # จุดจบ (ซ่อนขวา)
	var p1 := start_position + Vector2(0.0, -arc_peak_height)             # จุดควบคุมโค้ง (ยอดกลาง)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_arc_point.bind(p0, p1, p2), 0.0, 1.0, arc_duration)
	await tween.finished


func _apply_arc_point(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> void:
	# สูตร Quadratic Bezier: B(t) = (1-t)^2 * p0 + 2(1-t)t * p1 + t^2 * p2
	var one_minus_t := 1.0 - t
	position = one_minus_t * one_minus_t * p0 \
		+ 2.0 * one_minus_t * t * p1 \
		+ t * t * p2


func _on_jakk_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
