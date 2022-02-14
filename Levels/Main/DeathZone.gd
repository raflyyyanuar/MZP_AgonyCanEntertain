extends Area



func _on_DeathZone_body_entered(body):
	if body.is_in_group("player"):
		body.takeDamage(500)
