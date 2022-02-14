extends CanvasLayer

func _ready():
	$AnimationPlayer.play("ready")

func _process(delta):
	if Input.is_action_just_pressed("enter_cutscene"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("crouch"):
		get_tree().change_scene("res://Levels/Main/MainMenu.tscn")


func _on_RestartButton_pressed():
	get_tree().reload_current_scene()


func _on_QuitButton_pressed():
	get_tree().change_scene("res://Levels/Main/MainMenu.tscn")
