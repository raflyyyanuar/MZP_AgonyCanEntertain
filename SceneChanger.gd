extends CanvasLayer


onready var animPlayer = $AnimationPlayer
onready var image = $Control/Black

func change_scene(path, delay = 0.5):
	yield(get_tree().create_timer(delay), "timeout")
	animPlayer.play("FadeToBlack")
	yield(animPlayer, "animation_finished")
	assert(get_tree().change_scene(path) == OK)
	animPlayer.play_backwards("FadeToBlack")
