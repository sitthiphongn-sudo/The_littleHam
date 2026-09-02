extends CanvasLayer


@onready var death_label: Label = $DeathLabel
@onready var button_box: Control = $ButtonBox
@onready var color_rect: ColorRect = $ColorRect
@onready var restart_button: Button = $ButtonBox/RestartButton
@onready var exit_button: Button = $ButtonBox/ExitButton


@export var text_fade_duration: float = 0.8
@export var button_fade_duration: float = 0.5
@export var delay_before_button: float = 0.4


func _ready() -> void:

	layer = 105
	visible = false


	# ป้องกัน ColorRect บังการคลิกเมาส์
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# เชื่อมต่อปุ่ม Restart
	if restart_button:

		if not restart_button.pressed.is_connected(
			_on_restart_button_pressed
		):

			restart_button.pressed.connect(
				_on_restart_button_pressed
			)


	# เชื่อมต่อปุ่ม Exit
	if exit_button:

		if not exit_button.pressed.is_connected(
			_on_exit_button_pressed
		):

			exit_button.pressed.connect(
				_on_exit_button_pressed
			)


	# ซ่อนข้อความตอนเริ่ม
	if death_label:
		death_label.modulate.a = 0.0


	# ซ่อนปุ่มตอนเริ่ม
	if button_box:
		button_box.modulate.a = 0.0


# =========================================================
# แสดงหน้า Death Screen
# =========================================================

func show_death_screen() -> void:

	visible = true
	layer = 105


	var tween := create_tween().set_parallel(true)


	if death_label:

		tween.tween_property(

			death_label,

			"modulate:a",

			1.0,

			text_fade_duration

		).set_trans(

			Tween.TRANS_SINE

		).set_ease(

			Tween.EASE_OUT

		)


	if button_box:

		tween.tween_property(

			button_box,

			"modulate:a",

			1.0,

			button_fade_duration

		).set_delay(

			delay_before_button

		).set_trans(

			Tween.TRANS_SINE

		).set_ease(

			Tween.EASE_OUT

		)


# =========================================================
# 🔄 กดปุ่ม Restart
# =========================================================

func _on_restart_button_pressed() -> void:


	# -----------------------------------------------------
	# 1. ปิด Death Screen
	# -----------------------------------------------------

	visible = false


	if death_label:
		death_label.modulate.a = 0.0


	if button_box:
		button_box.modulate.a = 0.0


	# -----------------------------------------------------
	# 2. ให้ Player เกิดใหม่ที่ Checkpoint
	# -----------------------------------------------------

	var player = get_tree().get_first_node_in_group("player")


	if player and player.has_method("respawn"):

		player.respawn()


	# -----------------------------------------------------
	# 3. รอ 1 Frame
	#
	# เพื่อให้ Player วาร์ปไป Checkpoint ก่อน
	# -----------------------------------------------------

	await get_tree().process_frame


	# -----------------------------------------------------
	# 4. 🔥 หา Camera ที่กำลังใช้งาน
	# -----------------------------------------------------

	var camera = get_viewport().get_camera_2d()


	# -----------------------------------------------------
	# 5. 🔥 สั่ง Reset Camera
	#
	# ตรงนี้จะทำให้ restart_zoom ทำงาน
	# -----------------------------------------------------

	if camera and camera.has_method("reset_camera"):

		camera.reset_camera()


# =========================================================
# 🚪 กดปุ่ม Exit
# =========================================================

func _on_exit_button_pressed() -> void:


	# ซ่อน Death Screen
	visible = false


	if death_label:
		death_label.modulate.a = 0.0


	if button_box:
		button_box.modulate.a = 0.0


	# กลับ Main Menu
	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)
