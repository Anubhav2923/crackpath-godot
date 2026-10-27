extends Control


func _ready() -> void:
	# Pause gameplay while the win screen is visible.
	get_tree().paused = true
