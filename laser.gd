extends Node2D

@onready var laser_line = $Line2D
@onready var laser_line2 = $Line2D2
@onready var laser_line3 = $Line2D3
@onready var hitbox = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

@export var sweep_speed := 0.8
@export var min_angle := -45.0
@export var max_angle := 45.0

var direction := 1.0
var player_hit := false


func _ready():
	var laser_length := 500.0

	# =========================
	# ความยาวของลำแสง
	# =========================

	laser_line.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, laser_length)
	])

	laser_line2.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, laser_length)
	])

	laser_line3.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, laser_length)
	])


	# =========================
	# หน้าตาลำแสง
	# =========================

	# แสงรอบนอก
	laser_line.width = 20.0
	laser_line.default_color = Color(1, 0, 0, 0.25)
	laser_line.antialiased = true

	# ลำแสงหลัก
	laser_line2.width = 9.0
	laser_line2.default_color = Color(1, 0, 0, 0.8)
	laser_line2.antialiased = true

	# แกนกลางสีขาว
	laser_line3.width = 3.0
	laser_line3.default_color = Color(1, 0.8, 0.8, 1.0)
	laser_line3.antialiased = true


	# =========================
	# Collision
	# =========================

	var shape := collision_shape.shape as RectangleShape2D

	if shape:
		shape.size = Vector2(20, laser_length)

	collision_shape.position = Vector2(0, laser_length / 2.0)

	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.monitoring = true
	hitbox.monitorable = true

	hitbox.body_entered.connect(_on_body_entered)


	print("Laser Hitbox พร้อมทำงาน")
	print("Layer =", hitbox.collision_layer)
	print("Mask =", hitbox.collision_mask)


func _process(delta):
	# =========================
	# Laser กวาดซ้าย-ขวา
	# =========================

	rotation += direction * sweep_speed * delta

	if rotation >= deg_to_rad(max_angle):
		rotation = deg_to_rad(max_angle)
		direction = -1.0

	elif rotation <= deg_to_rad(min_angle):
		rotation = deg_to_rad(min_angle)
		direction = 1.0


func _on_body_entered(body):
	# ป้องกันการเรียกซ้ำ
	if player_hit:
		return

	if body.has_method("take_damage"):
		player_hit = true

		print("LASER ฆ่า Player: ", body.name)

		body.take_damage()
		
