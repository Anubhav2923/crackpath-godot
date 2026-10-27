
extends Area2D

@export var value: int = 1

var _collected: bool = false


func _ready() -> void:
	add_to_group("coins")


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return

	if not body.is_in_group("player"):
		return

	_collected = true
	set_deferred("monitoring", false)
	visible = false

	if body.has_method("collect_coin"):
		body.call("collect_coin", value, self)


func restore_coin() -> void:
	_collected = false
	visible = true
	set_deferred("monitoring", true)
