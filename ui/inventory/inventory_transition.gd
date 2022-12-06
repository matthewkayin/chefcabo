extends Sprite

signal finished(item, adding)

var item
var adding
var target_sprite

func begin(with_item: int, add_ingredient: bool, from: Sprite, to: Sprite):
    item = with_item
    adding = add_ingredient

    texture = from.texture

    var _ret = $tween.connect("tween_all_completed", self, "_on_interpolate_finished")
    var from_position = from.position
    var to_position = to.position
    if add_ingredient:
        to_position -= Vector2(16, 16)
    else:
        from_position -= Vector2(16, 16)
    position = from_position
    $tween.interpolate_property(self, "position", position, to_position, 0.1)
    $tween.start()
    visible = true

func animate_item():
    var _ret = $timer.connect("timeout", self, "_on_timer_timeout")
    $timer.start(0.2)

func _on_timer_timeout():
    frame = (frame + 1) % hframes

func rise_from_pot(with_item: int):
    item = with_item
    adding = true

    texture = Items.DATA[item].texture
    position = Vector2(225, 121) 

    $tween.interpolate_property(self, "position", position, Vector2(225, 52), 0.3)
    $tween.start()
    visible = true
    yield($tween, "tween_all_completed")

func claim_item(to: Sprite):
    frame = 0
    $timer.stop()
    var _ret = $tween.connect("tween_all_completed", self, "_on_interpolate_finished")
    $tween.interpolate_property(self, "position", position, to.position, 0.1)
    $tween.start()

func _on_interpolate_finished():
    emit_signal("finished", item, adding)
    queue_free()
