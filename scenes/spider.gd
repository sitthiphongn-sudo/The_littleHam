extends Node2D

@export var attack_limit: int = 3
@export var move_left_distance: float = 60.0  # ระยะขยับไปทางซ้าย
@export var move_up_distance: float = 400.0   # ระยะไต่ขึ้นบนเพื่อออกจากฉาก

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detect_area: Area2D = $DetectArea
@onready var web_hitbox: Area2D = $WebHitbox

@onready var s_idle: Sprite2D = $S_idle
@onready var s_attack: Sprite2D = $S_attack
@onready var walk_audio: AudioStreamPlayer2D = $WalkAudioPlayer # เพิ่มเสียงเดิน

var start_position: Vector2
var attack_count: int = 0
var is_player_in_detect_zone: bool = false
var is_busy: bool = false

func _ready() -> void:
	start_position = global_position
	
	# เชื่อมต่อ Signals
	detect_area.body_entered.connect(_on_detect_body_entered)
	detect_area.body_exited.connect(_on_detect_body_exited)
	web_hitbox.body_entered.connect(_on_web_hitbox_body_entered)
	
	# ยืนนิ่งรอ
	_show_idle_and_pause()

func _show_idle_and_pause() -> void:
	s_idle.visible = true
	s_attack.visible = false
	anim_player.play("idle")
	anim_player.pause() # หยุดนิ่งไม่เล่นเฟรมเดิน
	if walk_audio.playing:
		walk_audio.stop() # หยุดเสียงเดินเมื่อนิ่ง

func _show_attack() -> void:
	if walk_audio.playing:
		walk_audio.stop() # หยุดเสียงเดินขณะยิงใย
	s_idle.visible = false
	s_attack.visible = true
	anim_player.play("attack") # เล่นยิงใย 1 รอบ

# --- Detect Area ---
func _on_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_detect_zone = true
		if not is_busy:
			_start_loop_process()

func _on_detect_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_detect_zone = false

# --- Web Hitbox (ผู้เล่นโดนยิง) ---
func _on_web_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and s_attack.visible:
		if body.has_method("respawn"):
			body.respawn()
			_on_player_died()

# เมื่อผู้เล่นตาย ให้รีเซ็ต Loop นับใหม่
func _on_player_died() -> void:
	attack_count = 0 # รีเซ็ตนับรอบใหม่ให้ครบ 3
	is_busy = false
	is_player_in_detect_zone = false
	global_position = start_position
	_show_idle_and_pause()

# --- ลูปการทำงานหลัก ---
func _start_loop_process() -> void:
	is_busy = true
	
	while attack_count < attack_limit and is_player_in_detect_zone:
		attack_count += 1
		
		# 1. เดินขยับมาทางซ้าย + เล่นเสียงเดิน
		s_idle.visible = true
		s_attack.visible = false
		anim_player.play("idle")
		if not walk_audio.playing:
			walk_audio.play()
		
		var tween_left = create_tween()
		tween_left.tween_property(self, "global_position", start_position + Vector2(-move_left_distance, 0), 0.5)
		await tween_left.finished
		
		# 2. หยุดแป๊บนึง แล้วยิงใย 1 ครั้ง (หยุดเสียงเดินชั่วคราว)
		_show_attack()
		await anim_player.animation_finished # รอจนยิงเสร็จ 1 รอบ
		
		# 3. สลับกลับเป็น idle แล้วเดินกลับไปทางขวา (จุดเริ่มต้น) + เล่นเสียงเดิน
		s_idle.visible = true
		s_attack.visible = false
		anim_player.play("idle")
		if not walk_audio.playing:
			walk_audio.play()
		
		var tween_right = create_tween()
		tween_right.tween_property(self, "global_position", start_position, 0.5)
		await tween_right.finished
		
		# 4. หยุดนิ่งพัก 1 วินาที (หยุดเสียงเดิน) ก่อนเช็กเงื่อนไขทำซ้ำรอบต่อไป
		_show_idle_and_pause()
		await get_tree().create_timer(1.0).timeout
	
	# --- เมื่อหลุดออกจากลูป ---
	if attack_count >= attack_limit:
		# ถ้ายิงไม่โดนครบ 3 รอบ -> เดิน/ไต่ขึ้นด้านบนออกนอกฉาก
		_exit_to_top()
	else:
		is_busy = false

# การไต่ขึ้นด้านบนออกนอกฉาก
func _exit_to_top() -> void:
	s_idle.visible = true
	s_attack.visible = false
	anim_player.play("idle")
	if not walk_audio.playing:
		walk_audio.play()
	
	var tween_up = create_tween()
	tween_up.tween_property(self, "global_position", global_position + Vector2(0, -move_up_distance), 1.2)
	await tween_up.finished
	
	if walk_audio.playing:
		walk_audio.stop()
	queue_free() # ลบออกจากฉากเมื่อพ้นขอบบน
