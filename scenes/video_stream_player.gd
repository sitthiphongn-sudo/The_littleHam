extends VideoStreamPlayer

func _ready():
	play()
	await get_tree().process_frame
	await get_tree().process_frame
	print("Video texture size: ", get_video_texture().get_size())
