extends Node

## =========================================================
## TutorialManager (ตั้งเป็น Autoload/Singleton)
## โชว์ hint ทีละอันตามลำดับ โดยรอให้ผู้เล่นทำ action นั้นสำเร็จก่อน
## ถึงจะขึ้น hint ถัดไป
## =========================================================

signal hint_requested(hint_id: String, text: String)
signal hint_dismissed(hint_id: String)
signal tutorial_finished

## ข้อความ hint ทั้งหมด แก้ไข/เพิ่มลดได้ตรงนี้ที่เดียว
var hints: Dictionary = {
	"move": "กด A และ D ทั้งสองปุ่ม เพื่อเดิน",
	"jump": "กด Space เพื่อกระโดด",
	"run":  "กด Shift ค้างไว้ขณะเดินเพื่อวิ่ง",
	"perspective": "โซนนี้เปลี่ยนมุมมอง กด W และ S ทั้งสองปุ่ม เพื่อเดินขึ้น-เดินลง",
}

## hint บางอันต้องทำให้ "ครบทุกด้าน" ก่อนถึงจะถือว่าผ่าน
## เช่น "move" ต้องกดทั้ง A และ D ไม่ใช่กดด้านใดด้านหนึ่งแล้วผ่านเลย
## key = hint id, value = รายชื่อ part ที่ต้องเจอครบก่อนจะนับว่าเรียนจบ
var _required_parts: Dictionary = {
	"move": ["left", "right"],
	"perspective": ["up", "down"],
}

var _shown: Dictionary = {}             # hint ที่โชว์จบไปแล้ว (จะไม่โชว์ซ้ำอีก)
var _queue: Array[String] = []          # คิว hint ที่รอโชว์
var _current_hint: String = ""          # hint id ที่กำลังโชว์อยู่ตอนนี้ ("" = ไม่มี)
var _current_progress: Dictionary = {}  # part ที่ทำไปแล้วของ hint ที่กำลังโชว์อยู่
var _started: bool = false


## เรียกตอนเข้าฉากเกมจริง (เรียกจาก main_game.gd ตอน _ready) -> คิว hint พื้นฐานตอนเริ่มเกม
func start_tutorial() -> void:
	if _started:
		return
	_started = true
	queue_sequence(["move", "jump", "run"])


## เพิ่ม hint หลายอันเข้าคิวรวดเดียว ตามลำดับ
func queue_sequence(ids: Array) -> void:
	for id in ids:
		_enqueue(id)
	_try_show_next()


## เรียกตอนเกิดเหตุการณ์ที่ควรสอนเพิ่ม เช่น เข้าโซน perspective ครั้งแรก
## (เรียกได้ตลอด ไม่ต้องรอ start_tutorial เสร็จก่อน และจะไม่โชว์ซ้ำถ้าเคยผ่านแล้ว)
func trigger(hint_id: String) -> void:
	_enqueue(hint_id)
	_try_show_next()


func _enqueue(hint_id: String) -> void:
	if not hints.has(hint_id):
		push_warning("TutorialManager: ไม่พบ hint id '%s'" % hint_id)
		return
	if _shown.has(hint_id) or _current_hint == hint_id or _queue.has(hint_id):
		return
	_queue.append(hint_id)


func _try_show_next() -> void:
	if _current_hint != "" or _queue.is_empty():
		return
	_current_hint = _queue.pop_front()
	hint_requested.emit(_current_hint, hints[_current_hint])


## เรียกจาก player.gd ทุกครั้งที่ผู้เล่น "ทำ" action นั้นจริงๆ (เดิน/กระโดด/วิ่ง/เดินขึ้น-ลง ฯลฯ)
## part: ใช้กับ hint ที่ต้องทำครบหลายด้าน เช่น move -> "left"/"right", perspective -> "up"/"down"
## hint ที่ไม่ได้อยู่ใน _required_parts ไม่ต้องส่ง part มาก็ได้ จะผ่านทันทีเหมือนเดิม
func report_action(action_id: String, part: String = "") -> void:
	if action_id != _current_hint:
		return  # ยังไม่ถึงคิวของ hint นี้ หรือ hint นี้จบไปแล้ว -> ไม่ต้องทำอะไร

	if _required_parts.has(action_id):
		if part != "":
			if not _current_progress.has(action_id):
				_current_progress[action_id] = {}
			_current_progress[action_id][part] = true

		var done: Dictionary = _current_progress.get(action_id, {})
		for required_part in _required_parts[action_id]:
			if not done.has(required_part):
				return  # ยังทำไม่ครบทุกด้าน -> ยังไม่ถือว่าผ่าน hint นี้

	var finished_id := _current_hint
	_shown[finished_id] = true
	_current_progress.erase(finished_id)
	_current_hint = ""
	hint_dismissed.emit(finished_id)

	_try_show_next()
	if _current_hint == "" and _queue.is_empty():
		tutorial_finished.emit()
