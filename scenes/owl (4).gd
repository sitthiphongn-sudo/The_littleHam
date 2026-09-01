extends CharacterBody2D

@export var fly_speed: float = 230.0
@export var detection_range: float = 250.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var attack_hit_frame: int = 5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D


enum State {
	IDLE,
	FLY,
	ATTACK
}

var state: State = State.IDLE
var target: Node2D = null
var _attack_timer: float = 0.0
var _player_in_detection_area: bool = false


func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)

	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)

	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# หา Player ถ้ายังไม่มี Target
	if target == null or not is_instance_valid(target):
		_find_player()

	# ตรวจสอบ Target
	if target != null:
		if _is_player_dead(target):
			_reset_target()
		elif global_position.distance_to(target.global_position) > detection_range:
			_reset_target()

	match state:

		State.IDLE:
			velocity = Vector2.ZERO

			if sprite.animation != "idle":
				sprite.play("idle")

			if target != null and not _is_player_dead(target):
				state = State.FLY


		State.FLY:
			if target == null:
				velocity = Vector2.ZERO
				state = State.IDLE

			else:
				var to_target := target.global_position - global_position
				var distance := to_target.length()

				# หันหน้าไปทาง Player
				_flip_to(to_target.x)

				# อยู่ในระยะโจมตี
				if distance <= attack_range:
					velocity = Vector2.ZERO

					if _attack_timer <= 0.0:
						_start_attack()

				# ยังไม่ถึง → บินตาม
				else:
					velocity = to_target.normalized() * fly_speed

					if sprite.animation != "fly":
						sprite.play("fly")


		State.ATTACK:
			velocity = Vector2.ZERO


	move_and_slide()


# =========================================================
# หา Player
# =========================================================

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")

	for player in players:
		if player is Node2D:
			if not _is_player_dead(player):
				var distance := global_position.distance_to(
					player.global_position
				)

				if distance <= detection_range:
					target = player
					_player_in_detection_area = true
					state = State.FLY
					return


# =========================================================
# กลับด้าน Sprite
# =========================================================

func _flip_to(dir_x: float) -> void:
	if dir_x != 0:
		sprite.flip_h = dir_x > 0


# =========================================================
# เริ่มโจมตี
# =========================================================

func _start_attack() -> void:
	if target == null:
		return

	if _is_player_dead(target):
		return

	state = State.ATTACK
	_attack_timer = attack_cooldown

	velocity = Vector2.ZERO

	sprite.play("attack")
	sprite.frame = 0


# =========================================================
# Animation Frame เปลี่ยน
# =========================================================

func _on_sprite_frame_changed() -> void:
	if sprite.animation == "attack":
		if sprite.frame == attack_hit_frame:
			_try_hit_player()


# =========================================================
# โจมตี Player
# =========================================================

func _try_hit_player() -> void:
	if target == null:
		return

	if not is_instance_valid(target):
		return

	if _is_player_dead(target):
		return

	var distance := global_position.distance_to(
		target.global_position
	)

	# เช็คระยะก่อนโจมตี
	if distance <= attack_range * 1.5:
		if target.has_method("take_damage"):
			target.take_damage(1)


# =========================================================
# Animation จบ
# =========================================================

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "attack":

		if target != null and is_instance_valid(target):
			if not _is_player_dead(target):
				state = State.FLY
				return

		_reset_target()


# =========================================================
# Player เข้า Area
# =========================================================

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not _is_player_dead(body):
			target = body
			_player_in_detection_area = true

			if state == State.IDLE:
				state = State.FLY


# =========================================================
# Player ออกจาก Area
# =========================================================

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == target:
		var distance := global_position.distance_to(
			body.global_position
		)

		if distance > detection_range:
			_reset_target()


# =========================================================
# ตรวจสอบว่า Player ตายหรือไม่
# =========================================================

func _is_player_dead(player_node: Node2D) -> bool:
	if "_is_dead" in player_node:
		if bool(player_node.get("_is_dead")):
			return true

	if "is_dead" in player_node:
		if bool(player_node.get("is_dead")):
			return true

	if "hp" in player_node:
		if player_node.get("hp") <= 0:
			return true

	if "health" in player_node:
		if player_node.get("health") <= 0:
			return true

	return false


# =========================================================
# Reset Owl
# =========================================================

func _reset_target() -> void:
	target = null
	_player_in_detection_area = false
	state = State.IDLE
	velocity = Vector2.ZERO

	if sprite.animation != "idle":
		sprite.play("idle")
