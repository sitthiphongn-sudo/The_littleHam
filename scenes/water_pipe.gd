extends Node2D

## =========================================================
## ท่อน้ำ: จุดซ่อนตัวของผู้เล่น
## - ผู้เล่นเดินเข้าใกล้แล้วกด "interact" (ปุ่ม E) เพื่อซ่อน/ออกจากท่อ
## - pipe_id ใช้กำหนดลำดับที่นกฮูกจะเดินไปตรวจค้นหาผู้เล่น (1 -> 2 -> 3)
##   ท่อสุดท้ายที่นกฮูกจะไปตรวจคือท่อที่มี pipe_id สูงสุด (ค่าเริ่มต้น = ท่อน้ำ 3)
## =========================================================

@export var pipe_id: int = 1

## ตำแหน่งที่นกฮูกจะบินไปหยุดตรวจค้นหน้าท่อนี้ ถ้าไม่ตั้งค่าไว้จะใช้ตำแหน่งของท่อเอง
@onready var check_point: Marker2D = $OwlCheckPoint if has_node("OwlCheckPoint") else null
@onready var interact_zone: Area2D = $InteractZone if has_node("InteractZone") else null

var _player_inside: Node = null


func _ready() -> void:
	add_to_group("hiding_spot")
	if interact_zone:
		interact_zone.body_entered.connect(_on_body_entered)
		interact_zone.body_exited.connect(_on_body_exited)
	else:
		push_warning("water_pipe.gd (%s): ไม่พบ Area2D ชื่อ 'InteractZone' ใต้โหนดนี้ ผู้เล่นจะไม่สามารถกดซ่อนตัวได้" % name)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		if body.has_method("set_nearby_hiding_spot"):
			body.set_nearby_hiding_spot(self)


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		if body.has_method("set_nearby_hiding_spot"):
			body.set_nearby_hiding_spot(null)
		_player_inside = null


## ตำแหน่งที่นกฮูกใช้บินไปหยุด "เช็ก" ท่อนี้ระหว่างโหมดค้นหา
func get_check_position() -> Vector2:
	if check_point:
		return check_point.global_position
	return global_position
