extends AnimatedSprite

signal finished

func spawn(coordinate: Vector2):
    var _ret = self.connect("animation_finished", self, "_on_animation_finished")
    add_to_group("effects")
    position = coordinate * 32
    play("default")

func _on_animation_finished():
    emit_signal("finished")
    queue_free()