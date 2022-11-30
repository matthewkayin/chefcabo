extends AnimatedSprite

signal finished

const DURATION = 0.5

var origin
var target
var timer = 0

func spawn(from: Vector2, to: Vector2):
    origin = from + Vector2(16, 16)
    target = to + Vector2(16, 16)
    position = origin
    timer = DURATION

func _process(delta):
    timer -= delta
    if timer <= 0:
        position = target
        emit_signal("finished")
    else:
        var old_pos = position
        var percent = 1 - (timer / DURATION)
        position = origin + ((target - origin) * percent)
        position.y -= 32 * sin(3.14 * percent)
        rotation_degrees = rad2deg((position - old_pos).angle())
        if position.x < old_pos.x:
            flip_h = true
            rotation_degrees -= 180
