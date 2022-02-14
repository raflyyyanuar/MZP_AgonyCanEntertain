extends KinematicBody

var health = 200

func _ready():
	pass

func takeDamage(damage):
	$AnimationPlayer.play("hit")
	health -= damage
	if health <= 0:
		queue_free()
