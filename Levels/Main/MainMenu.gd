extends CanvasLayer



func _on_PlayButton_pressed():
	get_tree().change_scene("res://CutsceneBase.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit() # Quits the game


func _on_PlayButton2_pressed():
	get_tree().change_scene("res://Levels/Main/ForestLevel.tscn")
