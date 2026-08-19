extends Control

const COLOR_NORMAL := Color(0.75, 0.78, 0.85, 0.75) # เทาอมฟ้า (ปุ่มที่ไม่ได้เลือก)
const COLOR_SELECTED := Color(1, 1, 1, 1)            # ขาว (ปุ่มที่เลือกอยู่)
func _ready() -> void:
	# (Optional) ตั้งให้ปุ่ม Exit ได้รับ Focus อัตโนมัติ รองรับการใช้ Joypad / Keyboard Navigation
	$ExitButton.grab_focus()


func _on_exit_button_pressed() -> void:
	# เมื่อกดปุ่ม Exit ให้สลับกลับไปหน้า MainMenu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
