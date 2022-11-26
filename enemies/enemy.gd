extends Node2D

onready var item_drop_scene = preload("res://items/item.tscn")

onready var player = get_parent().get_node("player")
onready var tilemap = get_parent().get_node("tilemap")

onready var tween = $tween
onready var sprite = $sprite

var turn = null
var coordinate: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN

var max_health = 10
var health = max_health
var power = 3

func _ready():
    add_to_group("enemies")
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)

    tween.connect("tween_all_completed", player, "_on_interpolate_finished")

func _process(_delta):
    update_sprite()

func is_done_interpolating():
    return not tween.is_active()

func plan_turn():
    turn = {
        "action": "move",
        "coordinate": tilemap.get_astar_path(coordinate, player.coordinate)[1]
    }

func execute_turn():
    if turn.action == "move":
        facing_direction = coordinate.direction_to(turn.coordinate)
        if turn.coordinate == player.coordinate:
            player.take_damage(3)
        else:
            if tilemap.is_tile_free(turn.coordinate):
                tilemap.free_tile(coordinate)
                tilemap.reserve_tile(turn.coordinate)
                coordinate = turn.coordinate

func interpolate_turn():
    tween.interpolate_property(self, "position", position, coordinate * 32, 0.2)
    tween.start()

func update_sprite():
    for name in Direction.NAMES:
        if facing_direction == Direction.VECTORS[name]:
            sprite.play(name)

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        var item_drop = item_drop_scene.instance()
        get_parent().add_child(item_drop)
        item_drop.spawn(coordinate, Items.Item.TOMATO)

        tilemap.free_tile(coordinate)
        queue_free()
