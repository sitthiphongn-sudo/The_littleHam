extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $AnimatedSprite2D/Area2D

@export var move_speed := 100.0
@export var move_distance := 200.0

var start_x: float
var direction := 1.0
var laser_on := true


func _ready():
	start_x = position.x

	laser_on = true
	sprite.play("default")

	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.monitoring = true
	hitbox.monitorable = true

	laser_cycle()


func _process(delta):
	if not laser_on:
		return

	position.x += direction * move_speed * delta

	if position.x >= start_x + move_distance:
		position.x = start_x + move_distance
		direction = -1.0

	elif position.x <= start_x - move_distance:
		position.x = start_x - move_distance
		direction = 1.0



func laser_cycle():
	while true:

		# =========================
		# ยิงปกติ 2 วินาที
		# =========================
		laser_on = true
		sprite.visible = true
		sprite.play("default")
		hitbox.set_deferred("monitoring", true)

		await get_tree().create_timer(2.0).timeout


		# =========================
		# Fade
		# =========================
		laser_on = false
		hitbox.set_deferred("monitoring", false)

		sprite.play("fade")

		await get_tree().create_timer(0.8).timeout


		# =========================
		# ดับสนิท 2 วินาที
		# =========================
		sprite.visible = false

		await get_tree().create_timer(2.0).timeout


		# =========================
		# กลับมายิงปกติ
		# =========================
		sprite.visible = true
		sprite.play("default")
		hitbox.set_deferred("monitoring", true)
		laser_on = true




func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		print("Laser2 โดน Player: ", body.name)
		body.take_damage()
