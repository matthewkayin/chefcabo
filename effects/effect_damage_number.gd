extends Node2D

signal finished

onready var digits = $digits.get_children()
onready var tween = $tween
onready var timer = $timer

const digit_state_heights = [8, 16]
const digit_state_durations = [0.15, 0.2]

var digit_states = []
var is_finished = false

func _ready():
    tween.connect("tween_completed", self, "_on_tween_finished")

func spawn(at_coordinate: Vector2, damage_result):
    position = at_coordinate * 32

    if damage_result.is_crit:
        for digit in digits:
            digit.modulate = Color(1, 1, 0, 1)

    var digit_string = ""
    if damage_result.value == -1:
        digit_string = "Miss"
    else:
        digit_string = String(damage_result.value)

    var digit_width = (8 * digit_string.length()) + (3 * (digit_string.length() - 1))
    var digit_start_x = 16 - (digit_width / 2)

    for index in range(0, digit_string.length()):
        digits[index].text = " "

    for index in range(0, digit_string.length()):
        if index != 0:
            timer.start(0.05)
            yield(timer, "timeout")
        digits[index].text = digit_string[index]
        digits[index].rect_position = Vector2(digit_start_x + (11 * index), 16)
        digit_states.append(0)
        tween.interpolate_property(digits[index], "rect_position", digits[index].rect_position, Vector2(digits[index].rect_position.x, digit_state_heights[0]), digit_state_durations[0])
        tween.start()
        digits[index].visible = true

func _on_tween_finished(obj, _key):
    for index in range(0, digit_states.size()):
        if obj == digits[index]:
            digit_states[index] += 1
            if digit_states[index] < digit_state_heights.size():
                tween.interpolate_property(digits[index], "rect_position", digits[index].rect_position, Vector2(digits[index].rect_position.x, digit_state_heights[digit_states[index]]), digit_state_durations[digit_states[index]])
                tween.start()
            elif index == digit_states.size() - 1:
                visible = false
                is_finished = true
                emit_signal("finished")
