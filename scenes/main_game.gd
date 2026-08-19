extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $PlayerSpawn

func _ready() -> void:
	player.global_position = spawn_point.global_position


func _on_perspective_zone_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_perspective_zone_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
