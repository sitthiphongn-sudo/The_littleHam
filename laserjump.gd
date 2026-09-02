extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $AnimatedSprite2D/Area2D

func _ready():
	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.monitoring = true
	hitbox.monitorable = true

	laser_cycle()


func laser_cycle():
	while true:

		# 🔥 FIRE
		sprite.visible = true
		sprite.play("fire")
		hitbox.set_deferred("monitoring", true)

		await get_tree().create_timer(2.0).timeout


		# 🌫 FADE
		hitbox.set_deferred("monitoring", false)
		sprite.play("fade")

		await get_tree().create_timer(0.8).timeout


		# ดับ
		sprite.visible = false

		await get_tree().create_timer(2.0).timeout


		# ยิงใหม่
		sprite.visible = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		print("Laser Gun โดน Player: ", body.name)
		body.take_damage()
