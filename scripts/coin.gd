extends Area2D


@export var value : int = 1

var _collected : bool = false

func _ready() -> void :
	# The scene file already connects body_entered to _on_body_entered,
	# so we only join the "coins" group here (used for dynamic counting).
	add_to_group("coins")

func _on_body_entered(body: Node2D) -> void:
	# Guard: the handler can fire more than once in a single physics frame.
	if _collected:
		return
	if not body.is_in_group("player") :
		return 

	_collected = true
	set_deferred("monitoring", false)
	
	if body.has_method("collect_coin"):
		body.call("collect_coin",value)
		
	queue_free()
