extends Node2D

signal turn_finished

onready var attack_effect_scene = preload("res://effects/effect_player_slash.tscn")
onready var effect_damage_number_scene = preload("res://effects/effect_damage_number.tscn")

onready var global = get_node("/root/Global")

onready var tilemap = get_node("../tilemap")
onready var fog_of_war = get_node("../fog_of_war_map")
onready var highlight_map = get_node("../highlight_map")
onready var inventory = get_node("../ui/inventory")

onready var camera = $camera
onready var tween = $tween
onready var sprite = $sprite
onready var timer = $timer

var turn = null
var is_executing_turn = false
var pending_thrown_item = null
var is_turn_ready = true
var coordinate: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.ZERO
var should_interpolate_movement = false

var max_health = 100
var health = max_health
var attack = 3

func _ready():
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)
    fog_of_war.update_map(coordinate)

    camera.limit_left = int(tilemap.position.x)
    camera.limit_top = int(tilemap.position.y)
    camera.limit_right = int(tilemap.position.x + (tilemap.get_width() * 32))
    camera.limit_bottom = int(tilemap.position.y + (tilemap.get_height() * 32))

    tween.connect("tween_all_completed", self, "_on_tween_finished")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    sprite.connect("frame_changed", self, "_on_animation_frame_changed")
    inventory.connect("used_item", self, "_on_inventory_used_item")
    highlight_map.connect("finished", self, "_on_highlight_map_finished")

    inventory.add_item(Items.Item.TOMATO_SOUP)
    inventory.add_item(Items.Item.TOMATO)
    inventory.add_item(Items.Item.TOMATO)
    inventory.add_item(Items.Item.TOMATO)

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
        if should_interpolate_movement:
            interpolate_movement()
    if inventory.is_open():
        return
    if highlight_map.is_open():
        return
    if is_turn_ready:
        check_for_inputs()

func check_for_inputs():
    if Input.is_action_just_pressed("back"):
        inventory.open(true)
        return
    if Input.is_action_just_pressed("action"):
        turn = {
            "action": "wait"
        }
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

func get_turn_target():
    if turn.action == "item" and turn.effect == "heal":
        return self
    if turn.action == "item" and turn.effect == "throw":
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if turn.at == enemy.coordinate:
                return enemy
        return null
    if turn.action == "move":
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if coordinate + turn.direction == enemy.coordinate:
                return enemy
        return null

func execute_turn():
    if health == 0:
        return
    is_executing_turn = true
    if turn.action == "wait":
        end_turn()
    elif turn.action == "move":
        var future_coord = coordinate + turn.direction
        facing_direction = coordinate.direction_to(future_coord)
        if tilemap.is_tile_free(future_coord):
            tilemap.free_tile(coordinate)
            tilemap.reserve_tile(future_coord)
            coordinate = future_coord

            sprite.play(Direction.get_name(facing_direction))
            position += position.direction_to(coordinate * 32)
            should_interpolate_movement = true
        else:
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if future_coord == enemy.coordinate:
                    sprite.play("attack_" + Direction.get_name(facing_direction))
                    return

            # If tile is blocked but no enemy exists
            end_turn()
    elif turn.action == "item":
        if turn.effect == "heal":
            health = min(max_health, health + 20)
        elif turn.effect == "throw":
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if enemy.coordinate == turn.at:
                    enemy.take_damage(enemy.health)
                    break
        end_turn()

func end_turn():
    fog_of_war.update_map(coordinate)
    is_executing_turn = false
    turn = null
    emit_signal("turn_finished")

func _on_tween_finished():
    end_turn()

func interpolate_movement():
    var future_pos = coordinate * 32
    if position != future_pos:
        if position.distance_to(future_pos) <= 2:
            position = future_pos
        else:
            position += position.direction_to(future_pos) * 2
    if position == future_pos:
        # Check for item pickups
        for item in get_tree().get_nodes_in_group("items"):
            if coordinate == item.coordinate:
                inventory.add_item(item.item)
                item.queue_free()

        # End turn
        end_turn()
        should_interpolate_movement = false

func _on_animation_finished():
    if sprite.animation.begins_with("attack"):
        sprite.play(Direction.get_name(facing_direction))

func _on_animation_frame_changed():
    if sprite.animation.begins_with("attack") and sprite.frame == 2:
        var attack_coordinate = coordinate + facing_direction
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if attack_coordinate == enemy.coordinate:
                var effect = attack_effect_scene.instance()
                get_parent().add_child(effect)
                effect.spawn(attack_coordinate)
                yield(effect, "finished")

                yield(enemy.take_damage(global.calculate_damage(self, enemy)), "completed")
                break
        end_turn()

func take_damage(result):
    var damage_number = effect_damage_number_scene.instance()
    get_parent().add_child(damage_number)
    damage_number.spawn(coordinate, result)

    if result.value != -1:
        health -= result.value
        for _i in range(0, 3):
            sprite.visible = false
            timer.start(0.1)
            yield(timer, "timeout")
            sprite.visible = true
            timer.start(0.1)
            yield(timer, "timeout")

    if not damage_number.is_finished:
        yield(damage_number, "finished")
    damage_number.queue_free()

    if health <= 0:
        queue_free()
