
extends Area2D

@export var value: int = 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pickup_sound: Node = get_node_or_null("PickupSound")

var _collected: bool = false


func _ready() -> void:
	add_to_group("coins")

	# Connect collision detection only once.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Connect animation finished callback.
	if not animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		animation_player.animation_finished.connect(_on_animation_player_animation_finished)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return

	if not body.is_in_group("player"):
		return

	_collected = true
	set_deferred("monitoring", false)

	# Play the pickup animation.
	if animation_player.has_animation(&"pickup_animation"):
		animation_player.play(&"pickup_animation")
	elif animation_player.has_animation(&"pickup_annimation"):
		animation_player.play(&"pickup_annimation")
	else:
		visible = false

	# Update the player's coin counter and record this coin for Undo.
	if body.has_method("collect_coin"):
		body.call("collect_coin", value, self)


func _on_animation_player_animation_finished(animation_name: StringName) -> void:
	if _collected:
		visible = false


func _on_animation_finished(animation_name: StringName) -> void:
	if _collected:
		visible = false


func restore_coin() -> void:
	_collected = false
	animation_player.stop()

	if animation_player.has_animation(&"RESET"):
		animation_player.play(&"RESET")

	visible = true
	$AnimatedSprite2D.visible = true
	set_deferred("monitoring", true)
