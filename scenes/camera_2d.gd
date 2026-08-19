extends Camera2D

## ระยะเลื่อนเบา ๆ ของกล้อง (px) — ยิ่งมากยิ่งสั่นชัด
@export var sway_amount: float = 3.0
## ความเร็วในการแกว่ง — ยิ่งมากยิ่งไว
@export var sway_speed: float = 0.7
## มุมเอียงเล็กน้อย (เรเดียน) — ค่าน้อย ๆ พอ เช่น 0.005-0.02
@export var rotation_sway_amount: float = 0.02

var _time_offset := randf() * 100.0   # สุ่มจุดเริ่มต้น กันไม่ให้ซิงค์กับตัวอื่นเป๊ะเกินไป

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + _time_offset

	# เลื่อนตำแหน่งเบา ๆ แบบไม่ประสานจังหวะกัน (ใช้ความถี่ x/y ต่างกัน)
	offset.x = sin(t * sway_speed) * sway_amount
	offset.y = cos(t * sway_speed * 0.7) * sway_amount * 0.5

	# มุมเอียงเล็กน้อย
	rotation = sin(t * sway_speed * 0.4) * rotation_sway_amount
