extends Node2D

@onready var drone_sprite = $AnimatedSprite2D2

func _ready():
	drone_sprite.play("fly")
