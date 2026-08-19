extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("PerspectiveZone: ตรวจเจอ ", body.name)
	if body.has_method("_on_perspective_zone_body_entered"):
		body._on_perspective_zone_body_entered(body)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("_on_perspective_zone_body_exited"):
		body._on_perspective_zone_body_exited(body)
