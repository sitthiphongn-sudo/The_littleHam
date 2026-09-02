extends Area2D

@export var pipe_index: int = 1
@export var hide_duration: float = 2.5
@export var complete_on_enter: bool = false

var _player_nearby: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_nearby = body
	if body.has_method("set_nearby_safe_zone"):
		body.set_nearby_safe_zone(self)

func _on_body_exited(body: Node2D) -> void:
	if body != _player_nearby:
		return
	if body.has_method("set_nearby_safe_zone"):
		body.set_nearby_safe_zone(null)
	_player_nearby = null


## เรียกจากผู้เล่นตอนกดปุ่ม "interact" (E) ขณะยืนอยู่ในโซนนี้ -> ผู้เล่นจะซ่อนตัว
## คืนค่า true ถ้าซ่อนสำเร็จ (เรียงลำดับท่อถูกต้อง 1 -> 2 -> 3)
func try_hide(body: Node2D) -> bool:
	var current := int(body.get_meta("safe_pipe_index", 0))
	# เล่นตามลำดับ 1 -> 2 -> 3 เท่านั้น
	if pipe_index != current + 1 and not (pipe_index == 3 and current >= 3):
		return false

	body.set_meta("owl_hidden", true)
	body.set_meta("safe_pipe_index", pipe_index)

	var finished := pipe_index >= 3 or complete_on_enter
	body.set_meta("owl_chase_complete", finished)

	for node in get_tree().get_nodes_in_group("owl"):
		if is_instance_valid(node) and node.has_method("on_player_enter_safe_zone"):
			node.on_player_enter_safe_zone(global_position, hide_duration, finished)

	return true


## เรียกจากผู้เล่นตอนกดปุ่ม "interact" (E) อีกครั้งเพื่อออกจากที่ซ่อน
func try_unhide(body: Node2D) -> void:
	body.set_meta("owl_hidden", false)

	if body.get_meta("owl_chase_complete", false):
		return

	for node in get_tree().get_nodes_in_group("owl"):
		if is_instance_valid(node) and node.has_method("on_player_exit_safe_zone"):
			node.on_player_exit_safe_zone()
