extends CharacterBody2D

@onready var hitbox: Area2D = $web_spider
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var attack_animation: String = "attack_s"

var _anim_timer: float = 0.0
var _next_anim_time: float = 0.0
var _is_playing_attack := false


func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	anim_player.animation_finished.connect(_on_anim_finished)

	_hold_first_frame()
	_reset_anim_timer()


func _process(delta: float) -> void:
	if _is_playing_attack:
		return  # กำลังเล่น animation อยู่ ไม่ต้องนับเวลา

	_anim_timer += delta
	if _anim_timer >= _next_anim_time:
		_play_attack()


func _hold_first_frame() -> void:
	if not anim_player.has_animation(attack_animation):
		return
	anim_player.stop()
	anim_player.play(attack_animation)
	anim_player.seek(0.0, true)   # ไปเฟรมแรกและอัปเดตภาพทันที
	anim_player.pause()           # ค้างนิ่งไว้


func _play_attack() -> void:
	if not anim_player.has_animation(attack_animation):
		return
	_is_playing_attack = true
	anim_player.play(attack_animation)  # เล่นเต็ม ๆ จากเฟรมแรก


func _on_anim_finished(anim_name: String) -> void:
	if anim_name == attack_animation:
		_is_playing_attack = false
		_hold_first_frame()   # เล่นจบแล้วกลับไปค้างเฟรมแรก
		_reset_anim_timer()   # สุ่มเวลาใหม่รอบต่อไป


func _reset_anim_timer() -> void:
	_anim_timer = 0.0
	_next_anim_time = randf_range(3.0, 6.0)  # สุ่มช่วง 1-3 วินาที


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
