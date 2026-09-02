extends Area2D

@export var is_activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_activated:
		is_activated = true
		
		# อัปเดตจุดเกิดในตัวละครเป็นตำแหน่งของ Checkpoint นี้
		body.spawn_position = global_position
		
		# เปลี่ยนสี/เปลี่ยนสไปรท์เพื่อบอกว่า Checkpoint ทำงานแล้ว
		modulate = Color(0.4, 1.0, 0.4) # เปลี่ยนเป็นโทนสีเขียว
