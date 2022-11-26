extends Node2D

onready var tilemap = get_parent().get_node("tilemap")
onready var inventory = get_node("../ui/inventory")

onready var camera = $camera
onready var tween = $tween

var turn = null
var is_turn_ready = true
var coordinate: Vector2 = Vector2.ZERO

var max_health = 100
var health = max_health
var power = 3

func _ready():
    coordinate = position / 16
    tilemap.reserve_tile(coordinate)

    camera.limit_left = tilemap.position.x
    camera.limit_top = tilemap.position.y
    camera.limit_right = tilemap.position.x + (tilemap.get_width() * 16)
    camera.limit_bottom = tilemap.position.y + (tilemap.get_height() * 16)

    tween.connect("tween_all_completed", self, "_on_interpolate_finished")

func is_everyone_done_interpolating():
    if tween.is_active():
        return false
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not enemy.is_done_interpolating():
            return false
    return true

func _on_interpolate_finished():
    if is_everyone_done_interpolating():
        is_turn_ready = true

func _process(_delta):
    if not is_turn_ready:
        return
    if inventory.is_open():
        return
    if Input.is_action_just_pressed("menu"):
        inventory.open(true)
        return
    for name in Direction.NAMES:
        if Input.is_action_just_pressed(name):
            turn = {
                "action": "move",
                "direction": Direction.VECTORS[name]
            }
    if turn != null:
        begin_turn()

func begin_turn():
    is_turn_ready = false

    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.plan_turn()

    execute_turn()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.execute_turn()

    interpolate_turn()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.interpolate_turn()

func execute_turn():
    if turn.action == "move":
        var future_coord = coordinate + turn.direction
        if tilemap.is_tile_free(future_coord):
            tilemap.free_tile(coordinate)
            tilemap.reserve_tile(future_coord)
            coordinate = future_coord

            for item in get_tree().get_nodes_in_group("items"):
                if coordinate == item.coordinate:
                    inventory.add_item(item.item)
                    item.queue_free()
        else:
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if future_coord == enemy.coordinate:
                    enemy.take_damage(power)
                    break
    turn = null

func interpolate_turn():
    tween.interpolate_property(self, "position", position, coordinate * 16, 0.2)
    tween.start()

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        queue_free()
