extends Node2D

onready var item_drop_scene = preload("res://items/item.tscn")

onready var player = get_parent().get_node("player")
onready var tilemap = get_parent().get_node("tilemap")

onready var tween = $tween

var turn = null
var coordinate: Vector2 = Vector2.ZERO

var max_health = 10
var health = max_health
var power = 3

func _ready():
    add_to_group("enemies")
    coordinate = position / 16
    tilemap.reserve_tile(coordinate)

    tween.connect("tween_all_completed", player, "_on_interpolate_finished")

func is_done_interpolating():
    return not tween.is_active()

func plan_turn():
    turn = {
        "action": "move",
        "coordinate": tilemap.get_astar_path(coordinate, player.coordinate)[1]
    }

func execute_turn():
    if turn.action == "move":
        if turn.coordinate == player.coordinate:
            player.take_damage(3)
        else:
            if tilemap.is_tile_free(turn.coordinate):
                tilemap.free_tile(coordinate)
                tilemap.reserve_tile(turn.coordinate)
                coordinate = turn.coordinate

func interpolate_turn():
    tween.interpolate_property(self, "position", position, coordinate * 16, 0.2)
    tween.start()

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        var item_drop = item_drop_scene.instance()
        get_parent().add_child(item_drop)
        item_drop.spawn(coordinate, Items.Item.TOMATO)

        tilemap.free_tile(coordinate)
        queue_free()
