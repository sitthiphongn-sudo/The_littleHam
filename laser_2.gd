
extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $AnimatedSprite2D/Area2D

var player_hit := false


func _ready():
	sprite.visible = true
	sprite.modulate.a = 1.0
	sprite.scale = Vector2(1, 1)

	sprite.play("default")

	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.monitoring = true

	hitbox.body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if player_hit:
		return

	if body.has_method("take_damage"):
		player_hit = true

		print("LASER2 โดน Player: ", body.name)

		body.take_damage()
