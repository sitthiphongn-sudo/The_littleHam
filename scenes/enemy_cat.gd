extends CharacterBody2D

const GRAVITY = 980.0
const CHASE_SPEED = 120.0
const ATTACK_RANGE = 60.0
const ATTACK_COOLDOWN = 1.2
const ATTACK_DAMAGE = 10
const RETURN_SPEED = 100.0

@onready var anim_player: AnimatedSprite2D = $Animation  # หากใช้ Sprite2D + AnimationPlayer ให้เปลี่ยนชนิดให้ตรง
@onready var walk_sound = $Walksound
@onready var attack_sound: AudioStreamPlayer2D = $Attak_sound
@onready var detection_area = $detection_area

enum State { IDLE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE
var target: Node2D = null
var _attack_timer := 0.0
var _is_attacking := false
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	# เชื่อมสัญญาณเมื่อเล่นแอนิเมชันจบ
	if anim_player is AnimatedSprite2D:
		anim_player.animation_finished.connect(_on_animation_finished)

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		if state == State.IDLE or state == State.RETURN:
			state = State.CHASE

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		reset_target_and_return()

func reset_target_and_return() -> void:
	target = null
	_is_attacking = false
	state = State.RETURN

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if _attack_timer > 0.0:
		_attack_timer -= delta

	match state:
		State.IDLE:
			velocity.x = 0
			if anim_player.animation != "idle":
				anim_player.play("idle")

		State.CHASE:
			if target == null or not is_instance_valid(target):
				reset_target_and_return()
			else:
				var distance_x = abs(global_position.x - target.global_position.x)
				var direction = signf(target.global_position.x - global_position.x)

				if distance_x <= ATTACK_RANGE:
					state = State.ATTACK
					velocity.x = 0
				else:
					velocity.x = direction * CHASE_SPEED
					_flip_to(direction)
					if anim_player.animation != "run":
						anim_player.play("run")
					if not walk_sound.playing:
						walk_sound.play()

		State.ATTACK:
			velocity.x = 0
			if not _is_attacking:
				if target == null or not is_instance_valid(target):
					reset_target_and_return()
				else:
					var distance_x = abs(global_position.x - target.global_position.x)
					_flip_to(signf(target.global_position.x - global_position.x))

					if distance_x > ATTACK_RANGE * 1.5:
						state = State.CHASE
					elif _attack_timer <= 0.0:
						_do_attack()

		State.RETURN:
			var distance_to_spawn = abs(global_position.x - spawn_position.x)
			if distance_to_spawn <= 5.0:
				global_position.x = spawn_position.x
				state = State.IDLE
			else:
				var direction = signf(spawn_position.x - global_position.x)
				velocity.x = direction * RETURN_SPEED
				_flip_to(direction)
				if anim_player.animation != "run":
					anim_player.play("run")

	move_and_slide()

# --- ส่วนที่แก้ไข ---
# เปลี่ยนมากลับด้าน Sprite แทนการปรับ scale ของ Node หลักเพื่อป้องกัน bug Physics
func _flip_to(direction: float) -> void:
	if direction != 0:
		# สมมติว่าสไปรท์ต้นฉบับหันหน้าไปทางซ้าย (Left)
		# ถ้าเดินไปทางขวา (direction > 0) ต้องกลับด้าน (flip_h = true)
		anim_player.flip_h = (direction > 0)

# --- ส่วนที่แก้ไข ---
func _do_attack() -> void:
	_is_attacking = true
	_attack_timer = ATTACK_COOLDOWN
	anim_player.play("attack") # สั่งเล่นแอนิเมชันก่อน
	
	if not attack_sound.playing:
		attack_sound.play()

	# !!! สำคัญ !!! 
	# หน่วงเวลาสักนิด (เช่น 0.3 วินาที หรือตามระยะเวลาเฟรมที่ง้างจนสุดก่อนข่วนจริง)
	# เพื่อให้แอนิเมชันเล่นไปก่อน ค่อยทำความเสียหาย
	# คุณต้องปรับตัวเลข 0.3 นี้ให้ตรงกับแอนิเมชันของคุณ
	await get_tree().create_timer(0.3).timeout

	# ทำความเสียหายเมื่อถึงจังหวะเวลา (และต้องเช็คว่าเพลเยอร์ยังอยู่และยังอยู่ในระยะหรือไม่)
	if state == State.ATTACK and target != null and is_instance_valid(target):
		var distance_x = abs(global_position.x - target.global_position.x)
		if distance_x <= ATTACK_RANGE * 1.5:
			if target.has_method("take_damage"):
				target.take_damage(ATTACK_DAMAGE)

func _on_animation_finished() -> void:
	if anim_player.animation == "attack":
		_is_attacking = false
		if target == null or not is_instance_valid(target):
			reset_target_and_return()
