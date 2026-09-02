
extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $AnimatedSprite2D/Area2D

@export var fire_time := 2.0
@export var fade_time := 0.8
@export var off_time := 2.0

var laser_on := false


func _ready():
	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.monitoring = false
	hitbox.monitorable = true

	sprite.visible = false

	laser_cycle()


func laser_cycle():
	while true:

		# 🔥 FIRE
		laser_on = true
		sprite.visible = true
		sprite.play("fire")
		hitbox.set_deferred("monitoring", true)

		await get_tree().create_timer(fire_time).timeout


		# 🌫 FADE
		laser_on = false
		hitbox.set_deferred("monitoring", false)
		sprite.play("fade")

		await get_tree().create_timer(fade_time).timeout


		# ❌ ดับ
		sprite.visible = false

		await get_tree().create_timer(off_time).timeout


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		print("Laser Jump 2 โดน Player: ", body.name)
		body.take_damage()
