extends CanvasLayer

signal reveal_finished   # ยิงสัญญาณตอนจอสว่างเต็มที่แล้ว (ก่อนตัวหนังสือค้าง/จางหาย)

@onready var color_rect: ColorRect = $ColorRect
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	layer = 100
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.modulate.a = 0.0
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene(
	path: String,
	fade_duration: float = 0.6,
	title_text: String = "",
	linger_duration: float = 1.5
) -> void:
	# 1) จอมืดลง
	var tw_out := create_tween()
	tw_out.tween_property(color_rect, "modulate:a", 1.0, fade_duration)
	await tw_out.finished

	# 2) เปลี่ยนฉากจริงตอนจอมืดสนิท
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	# 3) ตัวหนังสือค่อยๆ โผล่ขึ้นมา
	if title_text != "":
		title_label.text = title_text
		var tw_text_in := create_tween()
		tw_text_in.tween_property(title_label, "modulate:a", 1.0, fade_duration * 0.6)
		await tw_text_in.finished
		await get_tree().create_timer(0.8).timeout

	# 4) จอค่อยๆ สว่าง
	var tw_reveal := create_tween()
	tw_reveal.tween_property(color_rect, "modulate:a", 0.0, fade_duration)
	await tw_reveal.finished

	reveal_finished.emit()   # <-- แจ้งว่าจอสว่างเต็มที่แล้ว ให้ Player เล่น recover ได้

	# 5) ตัวหนังสือค้างไว้อีกสักพักหลังฉากสว่างแล้ว แล้วค่อยจางหายเอง
	if title_text != "":
		await get_tree().create_timer(linger_duration).timeout
		var tw_text_out := create_tween()
		tw_text_out.tween_property(title_label, "modulate:a", 0.0, fade_duration * 0.6)
