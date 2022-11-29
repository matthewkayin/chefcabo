extends Node2D

signal turn_finished

onready var tilemap = get_node("../tilemap")
onready var highlight_map = get_node("../highlight_map")
onready var inventory = get_node("../ui/inventory")

onready var camera = $camera
onready var tween = $tween
onready var sprite = $sprite

var turn = null
var pending_thrown_item = null
var is_turn_ready = true
var coordinate: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.ZERO

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

    tween.connect("tween_all_completed", self, "_on_tween_finished")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    inventory.connect("used_item", self, "_on_inventory_used_item")
    highlight_map.connect("finished", self, "_on_highlight_map_finished")

    inventory.add_item(Items.Item.TOMATO_SOUP)

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

func _on_inventory_used_item(item):
    if Items.DATA[item].type == Items.Type.POTION:
        turn = {
            "action": "item",
            "effect": "heal"
        }
    elif Items.DATA[item].type == Items.Type.BOMB:
        pending_thrown_item = item
        highlight_map.open(coordinate, highlight_map.RangeType.CIRCLE)

func _on_highlight_map_finished(selected_coordinate):
    if selected_coordinate == null:
        inventory.add_item(pending_thrown_item)
        pending_thrown_item = null
        return

    turn = {
        "action": "item",
        "effect": "throw",
        "at": selected_coordinate
    }

func _process(_delta):
    if not is_turn_ready:
        return
    if inventory.is_open():
        return
    if highlight_map.is_open():
        return
    if is_turn_ready:
        check_for_inputs()

func check_for_inputs():
    if Input.is_action_just_pressed("back"):
        inventory.open(false)
        return
    for name in Direction.NAMES:
        if Input.is_action_pressed(name):
            var future_coord = coordinate + Direction.VECTORS[name]
            for kitchen in get_tree().get_nodes_in_group("kitchens"):
                if future_coord == kitchen.coordinate:
                    inventory.open(true)
                    return
            turn = {
                "action": "move",
                "direction": Direction.VECTORS[name]
            }

func is_turn_special():
    if turn.action != "move":
        return true
    elif turn.action == "move":
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if coordinate + turn.direction == enemy.coordinate:
                return true
        return false

func execute_turn():
    if health == 0:
        return
    if turn.action == "move":
        var future_coord = coordinate + turn.direction
        facing_direction = coordinate.direction_to(future_coord)
        if tilemap.is_tile_free(future_coord):
            tilemap.free_tile(coordinate)
            tilemap.reserve_tile(future_coord)
            coordinate = future_coord

            sprite.play(Direction.get_name(facing_direction))
            position += position.direction_to(coordinate * 32)
            tween.interpolate_property(self, "position", position, coordinate * 32, 0.2)
            tween.start()
        else:
            print("attacking at future coord ", future_coord)
            for enemy in get_tree().get_nodes_in_group("enemies"):
                print("enemy coord ", enemy.coordinate)
                if future_coord == enemy.coordinate:
                    print("playing attack animation")
                    sprite.play("attack_" + Direction.get_name(facing_direction))
                    break
    elif turn.action == "item":
        if turn.effect == "heal":
            health = min(max_health, health + 20)
        elif turn.effect == "throw":
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if enemy.coordinate == turn.at:
                    enemy.take_damage(enemy.health)
                    break
        turn = null
        emit_signal("turn_finished")

func _on_tween_finished():
    for item in get_tree().get_nodes_in_group("items"):
        if coordinate == item.coordinate:
            inventory.add_item(item.item)
            item.queue_free()
    turn = null
    emit_signal("turn_finished")

func _on_animation_finished():
    if sprite.animation.begins_with("attack"):
        var attack_coordinate = coordinate + facing_direction
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if attack_coordinate == enemy.coordinate:
                enemy.take_damage(power)
                break
        sprite.play(Direction.get_name(facing_direction))
        turn = null
        emit_signal("turn_finished")

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        queue_free()
