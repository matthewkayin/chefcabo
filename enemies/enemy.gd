extends Node2D

signal turn_finished

onready var item_drop_scene = preload("res://items/item.tscn")

onready var player = get_parent().get_node("player")
onready var tilemap = get_parent().get_node("tilemap")

onready var tween = $tween
onready var sprite = $sprite
onready var timer = $timer

var turn = null
var coordinate: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var should_interpolate_movement = false

var max_health = 10
var health = max_health
var power = 3

func _ready():
    add_to_group("enemies")
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)

    tween.connect("tween_all_completed", self, "_on_tween_finished")

func _process(_delta):
    if should_interpolate_movement:
        interpolate_movement()

func is_done_interpolating():
    return not tween.is_active()

func plan_turn():
    turn = {
        "action": "move",
        "coordinate": tilemap.get_astar_path(coordinate, player.coordinate)[1]
    }

func get_turn_target():
    if turn.coordinate == player.coordinate:
        return player
    return null

func execute_turn():
    if health == 0:
        return
    if turn.action == "move":
        facing_direction = coordinate.direction_to(turn.coordinate)
        sprite.play(Direction.get_name(facing_direction))
        if turn.coordinate == player.coordinate:
            player.take_damage(3)
            turn = null
            emit_signal("turn_finished")
        else:
            if tilemap.is_tile_free(turn.coordinate):
                tilemap.free_tile(coordinate)
                tilemap.reserve_tile(turn.coordinate)
                coordinate = turn.coordinate
                should_interpolate_movement = true
            else:
                turn = null
                emit_signal("turn_finished")

func interpolate_movement():
    var future_pos = coordinate * 32
    if position != future_pos:
        if position.distance_to(future_pos) <= 2:
            position = future_pos
        else:
            position += position.direction_to(future_pos) * 2
    if position == future_pos:
        turn = null
        emit_signal("turn_finished")
        should_interpolate_movement = false

func _on_tween_finished():
    turn = null
    emit_signal("turn_finished")

func take_damage(amount: int):
    health -= amount
    for _i in range(0, 3):
        sprite.visible = false
        timer.start(0.1)
        yield(timer, "timeout")
        sprite.visible = true
        timer.start(0.1)
        yield(timer, "timeout")
    if health <= 0:
        var item_drop = item_drop_scene.instance()
        get_parent().add_child(item_drop)
        item_drop.spawn(coordinate, Items.Item.TOMATO)

        tilemap.free_tile(coordinate)
        queue_free()
