extends Area2D

## วาง script นี้บน Area2D ที่มี CollisionShape2D/CollisionPolygon2D
## แล้วไปวางไว้ท้ายสุดของด่านสุดท้ายใน main_game.tscn

@export var end_scene_path: String = "res://scenes/EndScene.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# เช็คว่าเป็น Player (เช็คทั้งชื่อ node และ group เผื่อกรณีไม่ได้ตั้ง group)
	if body.is_in_group("player") or body.name == "Player":
		Transition.change_scene(end_scene_path, 1.5)
