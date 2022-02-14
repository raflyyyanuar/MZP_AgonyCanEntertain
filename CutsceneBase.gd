extends Node2D

onready var tween = $Tween
onready var animPlayer = $AnimationPlayer


func _on_StartTimer_timeout():
	animPlayer.play("Cutscene1")



func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Cutscene1":
		$EndTimer.start()


func _on_EndTimer_timeout():
	get_tree().change_scene("res://Levels/Main/ForestLevel.tscn")
