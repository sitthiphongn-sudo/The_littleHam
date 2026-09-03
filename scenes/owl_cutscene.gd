extends Node2D
## แนบ script นี้ไว้ที่ root node ของ owlcutscene.tscn (โหนดชื่อ "owlcutsecene")
## วางฉากนี้ตรงจุดที่อยากให้นกฮูกยืนอยู่ (หันหลัง) ใน main_game.tscn ได้เลย
##
## พฤติกรรม:
## - นกฮูกโชว์อยู่แล้วตั้งแต่เกมเริ่ม (ไม่ซ่อน) ผู้เล่นเดินมาเห็นได้เลยตามปกติ
## - เมื่อ Player เดินเข้ามาในกรอบ TriggerZone -> (ถ้าเปิดไว้) เริ่มเล่น animation "default" ครั้งเดียว (ไม่วนลูป)
## - เมื่อ Player เดินออกจากกรอบ (หลุดเฟรม/เดินผ่านไปแล้ว) -> นกฮูกถึงหายไป
@export var play_animation_on_enter: bool = true
## true  = ตอน player เดินเข้ากรอบ จะเริ่มเล่น animation "default" (เช่น ขยับตัว/หันมอง)
## false = ให้นกฮูกอยู่นิ่งเฉยๆ จนกว่า player จะเดินหลุดกรอบไป
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger_zone: Area2D = $TriggerZone
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	visible = true # นกฮูกโชว์อยู่แล้วตั้งแต่ต้น ไม่ซ่อน
	sprite.stop()
	sprite.frame = 0 # เริ่มที่เฟรมแรกเสมอ (ไฟล์เดิมค้าง frame=44 ไว้จากตอนแก้ใน editor)
	# ชดเชย scale ของโหนดนี้ (owlcutsecene มักถูกย่อขนาดให้เข้ากับฉาก เช่น 0.14)
	# เพื่อให้ TriggerZone มีขนาด "จริง" ในเกมตรงกับที่ตั้งไว้ใน Shape เสมอ
	# ตำแหน่งยังคงอยู่ตรงกลางนกฮูกเหมือนเดิม (ไม่ขยับ) แค่ขนาดกรอบใหญ่ขึ้น
	if scale.x != 0.0 and scale.y != 0.0:
		trigger_zone.scale = Vector2(1.0 / scale.x, 1.0 / scale.y)

	trigger_zone.body_entered.connect(_on_body_entered)
	trigger_zone.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	visible = true
	if play_animation_on_enter:
		sprite.frame = 0
		sprite.play("default")
		audio_player.play()


func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	# player เดินหลุดออกจากกรอบไปแล้ว (ไม่เห็นในเฟรมแล้ว) ตอนนี้แหละที่นกฮูกหายไป
	visible = false
	sprite.stop()


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.name == "Player"
