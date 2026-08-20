extends Camera2D

## ระยะเลื่อนเบา ๆ ของกล้องช่วงเล่นปกติ (px)
@export var sway_amount: float = 3.0
@export var sway_speed: float = 0.7
@export var rotation_sway_amount: float = 0.02

var _time_offset := randf() * 100.0
var is_swaying := true
var is_dead_mode := false
var target_node: Node2D = null

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + _time_offset

	# --- โหมดตอนหนูตาย (ซูมเข้าใกล้ + ขยับกล้องไปหาหนู + เอียงซ้ายขวานุ่มๆ) ---
	if is_dead_mode:
		# 1. ขยับกล้องเข้าหาตำแหน่งตัวหนูโดยตรง (Lerp นุ่มๆ)
		if is_instance_valid(target_node):
			global_position = global_position.lerp(target_node.global_position, delta * 3.0)

		# 2. เอียงกล้องสลับซ้าย-ขวา ไปมานุ่มๆ (ใช้ Sine Wave)
		# sin(t * 1.2) กำหนดความเร็วในการเอียง / 0.08 คือมุมเอียง (ประมาณ 4.5 องศา)
		var target_rotation = sin(t * 0.7) * 0.06
		rotation = lerp_angle(rotation, target_rotation, delta * 2.5)
		return

	# --- โหมดสั่น/แกว่งปกติขณะเล่น ---
	if not is_swaying:
		return

	offset.x = sin(t * sway_speed) * sway_amount
	offset.y = cos(t * sway_speed * 0.7) * sway_amount * 0.5
	rotation = sin(t * sway_speed * 0.4) * rotation_sway_amount


# =========================================================
# ฟังก์ชันสั่งซูมเข้าใกล้ตัวหนู (เรียกจาก player.gd)
# =========================================================
func play_death_zoom(player_ref: Node2D = null) -> void:
	make_current()
	enabled = true
	is_swaying = false
	is_dead_mode = true
	ignore_rotation = false  # ปลดล็อกให้กล้องหมุนเอียงได้ใน Godot 4
	target_node = player_ref

	var tween := create_tween().set_parallel(true)
	
	# ค่อยๆ ดึง offset กลับตรงกลาง
	tween.tween_property(self, "offset", Vector2.ZERO, 0.5)
	
	# ซูมขยายภาพเข้าใกล้ตัวหนู (ปรับระดับความใกล้ตรงนี้ เช่น Vector2(2.5, 2.5))
	tween.tween_property(self, "zoom", Vector2(4, 4), 5.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# =========================================================
# รีเซ็ตกล้องกลับเป็นปกติเมื่อกด Restart
# =========================================================
func reset_camera() -> void:
	is_swaying = true
	is_dead_mode = false
	target_node = null
	ignore_rotation = true
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "zoom", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(self, "rotation", 0.0, 0.5)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.5)
