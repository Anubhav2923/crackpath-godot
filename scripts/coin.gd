extends Area2D


@export var value : int = 1

func _ready() -> void :
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") :
		return 
		
	set_deferred("monitoring", false)
	
	if body.has_method("collect_coin"):
		body.call("collect_coin",value)
		
	queue_free()
