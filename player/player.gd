extends Node2D

onready var tilemap = get_node("../tilemap")
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
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)

    camera.limit_left = int(tilemap.position.x)
    camera.limit_top = int(tilemap.position.y)
    camera.limit_right = int(tilemap.position.x + (tilemap.get_width() * 32))
    camera.limit_bottom = int(tilemap.position.y + (tilemap.get_height() * 32))

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
    check_for_inputs()

func check_for_inputs():
    if Input.is_action_just_pressed("back"):
        inventory.open(true)
        return
    for name in Direction.NAMES:
        if Input.is_action_pressed(name):
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
    position += position.direction_to(coordinate * 32)
    tween.interpolate_property(self, "position", position, coordinate * 32, 0.2)
    tween.start()

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        queue_free()
