extends Node2D

@export var owl_group: String = "owl"          
@export var owl_lock_duration: float = 1.0       # ระยะเวลาห้ามกด E (1 วินาที)
@export var owl_detection_distance: float = 180.0 # ระยะที่ตรวจจับว่านกฮูกใกล้ปากท่อ

@onready var entrance_zone: Area2D = $EntranceZone
@onready var exit_zone: Area2D = $ExitZone
@onready var entrance_prompt: Label = $EntranceZone/PromptLabel
@onready var exit_prompt: Label = $ExitZone/PromptLabel

enum PipeState { EMPTY, HIDDEN }
var state: PipeState = PipeState.EMPTY

var _player_at_entrance: Node = null
var _hidden_player: Node = null
var _prev_e_pressed := false
var _owl_lock_timer: float = 0.0


func _ready() -> void:
	entrance_zone.body_entered.connect(_on_entrance_entered)
	entrance_zone.body_exited.connect(_on_entrance_exited)

	entrance_prompt.visible = false
	exit_prompt.visible = false


func _physics_process(delta: float) -> void:
	var interact_just_pressed := _consume_interact_pressed()

	# นับถอยหลังตัวล็อก E
	if _owl_lock_timer > 0.0:
		_owl_lock_timer -= delta

	if state == PipeState.HIDDEN:
		# แสดงข้อความ E ค้างไว้ยาวๆ ตลอดช่วงที่ซ่อนตัวอยู่
		exit_prompt.visible = true

		# ถ้านกฮูกบินมาใกล้ปากท่อ ให้รีเซ็ตเวลาล็อกการกด E ไว้ 1 วินาที
		if _is_owl_near_exit():
			_owl_lock_timer = owl_lock_duration

		# สามารถกด E ออกได้ก็ต่อเมื่อพ้นช่วงล็อก 1 วินาทีแล้ว
		if _owl_lock_timer <= 0.0 and interact_just_pressed:
			_do_exit()

	elif _player_at_entrance != null:
		entrance_prompt.visible = true
		if interact_just_pressed:
			_do_hide()
	else:
		entrance_prompt.visible = false


func _consume_interact_pressed() -> bool:
	var pressed := Input.is_physical_key_pressed(KEY_E)
	var just_pressed := pressed and not _prev_e_pressed
	_prev_e_pressed = pressed
	return just_pressed


func _on_entrance_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state == PipeState.EMPTY:
		_player_at_entrance = body


func _on_entrance_exited(body: Node2D) -> void:
	if body == _player_at_entrance:
		_player_at_entrance = null


func _do_hide() -> void:
	if _player_at_entrance == null or not _player_at_entrance.has_method("hide_in_pipe"):
		return

	_hidden_player = _player_at_entrance
	_hidden_player.hide_in_pipe(global_position)

	state = PipeState.HIDDEN
	entrance_prompt.visible = false
	_player_at_entrance = null


func _do_exit() -> void:
	if _hidden_player == null or not _hidden_player.has_method("exit_pipe"):
		return

	_hidden_player.exit_pipe(exit_zone.global_position)

	state = PipeState.EMPTY
	exit_prompt.visible = false
	_hidden_player = null


# เช็คว่านกฮูกบินอยู่ใกล้ปากท่อฝั่งออกหรือไม่
func _is_owl_near_exit() -> bool:
	var owls := get_tree().get_nodes_in_group(owl_group)
	var exit_pos := exit_zone.global_position

	for owl in owls:
		if owl is Node2D:
			if owl.global_position.distance_to(exit_pos) <= owl_detection_distance:
				return true
	return false
