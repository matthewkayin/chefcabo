extends Sprite

signal finished(item, adding)

var item
var adding
var target_sprite

func begin(with_item: int, add_ingredient: bool, from: Sprite, to: Sprite):
    item = with_item
    adding = add_ingredient

    position = from.position
    texture = from.texture

    var _ret = $tween.connect("tween_all_completed", self, "_on_interpolate_finished")
    $tween.interpolate_property(self, "position", position, to.position, 0.1)
    $tween.start()
    visible = true

func _on_interpolate_finished():
    emit_signal("finished", item, adding)
    queue_free()
