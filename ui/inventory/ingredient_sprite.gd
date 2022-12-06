extends Sprite

signal finished

enum State {
    VIBING,
    RISING,
    FALLING,
    FINISHED
}

export var RISING_POS = Vector2(241, -12)
const RISING_DURATION = 0.5

export var FALLING_POS = Vector2(241, 114)
const FALLING_DURATION = 0.7

export var rotation_speed = 1

var initial_position
var state = State.VIBING
var timer

func _ready():
    initial_position = position

func reset():
    position = initial_position
    texture = null
    visible = true
    rotation_degrees = 0
    state = State.VIBING

func is_finished():
    return state == State.FINISHED

func begin_animation():
    state = State.RISING
    timer = RISING_DURATION

func _process(delta):
    if state == State.RISING:
        rotation_degrees += rotation_speed * delta
        timer -= delta
        if timer <= 0:
            position = RISING_POS
            timer = FALLING_DURATION
            state = State.FALLING
        else:
            var percent = 1 - (timer / RISING_DURATION)
            var dist = RISING_POS - initial_position
            position = initial_position + Vector2(dist.x * percent, 1.0 * dist.y * sin(1.57 * percent))
    elif state == State.FALLING:
        rotation_degrees += rotation_speed * delta
        timer -= delta
        if timer <= 0:
            position = FALLING_POS
            state = State.FINISHED
            visible = false
            emit_signal("finished")
        else:
            var percent = 1 - (timer / FALLING_DURATION)
            var dist = FALLING_POS - RISING_POS
            position = RISING_POS + (dist * percent)