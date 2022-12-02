extends Node2D

signal finished

onready var label = $label
onready var tween = $tween

var is_finished = false

func _ready():
    pass

func spawn(at_coordinate: Vector2, with_value: int):
    position = at_coordinate * 32
    label.text = String(with_value)
    tween.interpolate_property(label, "rect_position", label.rect_position, label.rect_position - Vector2(0, 8), 0.15)
    tween.start()
    yield(tween, "tween_all_completed")

    tween.interpolate_property(label, "rect_position", label.rect_position, label.rect_position + Vector2(0, 12), 0.25)
    tween.start()
    yield(tween, "tween_all_completed")
    visible = false

    is_finished = true
    emit_signal("finished")
