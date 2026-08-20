extends CharacterBody2D

const WALK_SPEED = 40.0
const RUN_SPEED = 100.0
const GRAVITY = 980.0
const JUMP_VELOCITY = -300.0

# --- ตั้งค่าจุดเกิดใหม่ (Respawn) ---
@export var spawn_position: Vector2 = Vector2(100, 300)

# --- ตั้งค่าโหมด Perspective (เดินลึก) ---
@export var perspective_move_speed: float = 40.0
@export var perspective_top_y: float = 0.0        # ตำแหน่ง y จุดไกลสุด
@export var perspective_bottom_y: float = 100.0   # ตำแหน่ง y จุดใกล้สุด
@export var perspective_min_scale: float = 0.4
@export var perspective_max_scale: float = 1.0
@export var perspective_jump_force: float = -300.0
@export var perspective_jump_gravity: float = 980.0

var in_perspective_mode := false
var _perspective_jump_velocity := 0.0
var _perspective_jump_offset := 0.0
var _perspective_is_jumping := false

@onready var idle_sprite: Sprite2D = $P_idle
@onready var walk_sprite: Sprite2D = $P_walk
@onready var run_sprite: Sprite2D = $P_run
@onready var jump_sprite: Sprite2D = $P_jump
@onready var shadow: Sprite2D = $ShadowSprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer

@export var walk_footstep_sounds: Array[AudioStream] = []
@export var run_footstep_sounds: Array[AudioStream] = []

var _footstep_timer := 0.0
const WALK_STEP_INTERVAL := 0.4
const RUN_STEP_INTERVAL := 0.22


func _ready() -> void:
	# เพิ่ม Player เข้าไปในกลุ่ม "player" เพื่อให้แมงมุมอ้างอิงได้ถูกต้อง
	add_to_group("player")


# =========================================================
# ระบบเกิดใหม่เมื่อโดนโจมตี
# =========================================================
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	# รีเซ็ตสถานะการกระโดดของโหมด perspective กันสไปรท์ลอยค้าง
	_perspective_jump_offset = 0.0
	_perspective_jump_velocity = 0.0
	_perspective_is_jumping = false
	idle_sprite.position.y = 0
	walk_sprite.position.y = 0
	run_sprite.position.y = 0
	jump_sprite.position.y = 0


func _physics_process(delta: float) -> void:
	if in_perspective_mode:
		_process_perspective_movement(delta)
	else:
		_process_normal_movement(delta)

	move_and_slide()


# =========================================================
# โหมดปกติ (พื้นราบ ซ้าย-ขวา + กระโดดจริงด้วยแรงโน้มถ่วง)
# =========================================================
func _process_normal_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	var is_running := Input.is_action_pressed("move_run")

	if direction != 0:
		var speed := RUN_SPEED if is_running else WALK_SPEED
		velocity.x = direction * speed
		_set_flip(direction < 0)
	else:
		velocity.x = 0

	if not is_on_floor():
		_play_state(jump_sprite)
		footstep_player.stop()
		if anim_player.current_animation != "jump":
			anim_player.play("jump")
	elif direction != 0:
		if is_running:
			_play_state(run_sprite)
			if anim_player.current_animation != "run":
				anim_player.play("run")
			_play_footsteps(delta, run_footstep_sounds, RUN_STEP_INTERVAL)
		else:
			_play_state(walk_sprite)
			if anim_player.current_animation != "walk":
				anim_player.play("walk")
			_play_footsteps(delta, walk_footstep_sounds, WALK_STEP_INTERVAL)
	else:
		_play_state(idle_sprite)
		_footstep_timer = 0.0
		footstep_player.stop()
		if anim_player.current_animation != "idle":
			anim_player.play("idle")


# =========================================================
# โหมด Perspective: เดินซ้าย-ขวา-ขึ้น-ลง (ลึก) + ย่อ/ขยายตามระยะ
# + กระโดดจริง (แยกจากตำแหน่งความลึก ใช้ offset ลอยแค่สไปรท์)
# =========================================================
func _process_perspective_movement(delta: float) -> void:
	var dir_x := Input.get_axis("move_left", "move_right")
	var dir_y := Input.get_axis("move_up", "move_down")  # up = ลึกเข้าไป, down = ใกล้กล้อง
	var is_running := Input.is_action_pressed("move_run")
	var speed := RUN_SPEED if is_running else perspective_move_speed

	velocity.x = dir_x * speed
	velocity.y = dir_y * speed

	if dir_x != 0:
		_set_flip(dir_x < 0)

	# จำกัดไม่ให้เดินหลุดขอบเขตความลึก (บน-ล่าง)
	global_position.y = clamp(global_position.y, perspective_top_y, perspective_bottom_y)

	# คำนวณสัดส่วนความลึก 0 = ไกลสุด, 1 = ใกล้สุด แล้วปรับขนาดตัวละคร
	var depth_ratio: float = inverse_lerp(perspective_top_y, perspective_bottom_y, global_position.y)
	depth_ratio = clamp(depth_ratio, 0.0, 1.0)
	var new_scale: float = lerp(perspective_min_scale, perspective_max_scale, depth_ratio)
	scale = Vector2(new_scale, new_scale)

	# --- กระโดดจริง (จำลองแนวดิ่งแยกจากตำแหน่งความลึก) ---
	if Input.is_action_just_pressed("move_jump") and not _perspective_is_jumping:
		_perspective_is_jumping = true
		_perspective_jump_velocity = perspective_jump_force

	if _perspective_is_jumping:
		_perspective_jump_velocity += perspective_jump_gravity * delta
		_perspective_jump_offset += _perspective_jump_velocity * delta
		if _perspective_jump_offset >= 0.0:
			_perspective_jump_offset = 0.0
			_perspective_jump_velocity = 0.0
			_perspective_is_jumping = false

	# ขยับแค่สไปรท์ตัวละครลอยขึ้น-ลงตามระยะกระโดด (เงายังอยู่กับพื้นเสมอ)
	idle_sprite.position.y = _perspective_jump_offset
	walk_sprite.position.y = _perspective_jump_offset
	run_sprite.position.y = _perspective_jump_offset
	jump_sprite.position.y = _perspective_jump_offset

	var is_moving := dir_x != 0 or dir_y != 0

	if _perspective_is_jumping:
		_play_state(jump_sprite)
		footstep_player.stop()
		if anim_player.current_animation != "jump":
			anim_player.play("jump")
	elif is_moving:
		if is_running:
			_play_state(run_sprite)
			if anim_player.current_animation != "run":
				anim_player.play("run")
			_play_footsteps(delta, run_footstep_sounds, RUN_STEP_INTERVAL)
		else:
			_play_state(walk_sprite)
			if anim_player.current_animation != "walk":
				anim_player.play("walk")
			_play_footsteps(delta, walk_footstep_sounds, WALK_STEP_INTERVAL)
	else:
		_play_state(idle_sprite)
		_footstep_timer = 0.0
		footstep_player.stop()
		if anim_player.current_animation != "idle":
			anim_player.play("idle")


func _set_flip(flip: bool) -> void:
	idle_sprite.flip_h = flip
	walk_sprite.flip_h = flip
	run_sprite.flip_h = flip
	jump_sprite.flip_h = flip
	shadow.flip_h = flip


func _play_state(active_sprite: Sprite2D) -> void:
	idle_sprite.visible = active_sprite == idle_sprite
	walk_sprite.visible = active_sprite == walk_sprite
	run_sprite.visible = active_sprite == run_sprite
	jump_sprite.visible = active_sprite == jump_sprite


func _play_footsteps(delta: float, sounds: Array[AudioStream], interval: float) -> void:
	if sounds.is_empty():
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = interval
		footstep_player.stream = sounds[randi() % sounds.size()]
		footstep_player.play()


# =========================================================
# เรียกอัตโนมัติจากสัญญาณของ PerspectiveZone (Area2D)
# =========================================================
func _on_perspective_zone_body_entered(body: Node2D) -> void:
	if body == self:
		in_perspective_mode = true
		velocity = Vector2.ZERO


func _on_perspective_zone_body_exited(body: Node2D) -> void:
	if body == self:
		in_perspective_mode = false
		scale = Vector2(perspective_max_scale, perspective_max_scale)
		velocity = Vector2.ZERO
		# รีเซ็ตค่ากระโดดกันสไปรท์ค้างลอย
		_perspective_jump_offset = 0.0
		_perspective_jump_velocity = 0.0
		_perspective_is_jumping = false
		idle_sprite.position.y = 0
		walk_sprite.position.y = 0
		run_sprite.position.y = 0
		jump_sprite.position.y = 0
		
func take_damage(_amount: int = 0) -> void:
	respawn()
