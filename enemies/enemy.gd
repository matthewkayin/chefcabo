extends Node2D
class_name Enemy

signal turn_finished

onready var item_drop_scene = preload("res://items/item.tscn")
onready var bullet_scene = preload("res://enemies/tomato/tomato_bullet.tscn")
onready var effect_damage_number_scene = preload("res://effects/effect_damage_number.tscn")

onready var global = get_node("//root/Global")

onready var player = get_parent().get_node("player")
onready var tilemap = get_parent().get_node("tilemap")

onready var tween = $tween
onready var sprite = $sprite
onready var timer = $timer

export var max_health = 10
export var attack = 2
export var is_melee_attacker = true
export var attack_impact_frame = 2
export(Items.Item) var dropped_item

var health = max_health

var turn = null
var is_executing_turn = false
var is_charging = false
var coordinate: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var should_interpolate_movement = false

func _ready():
    add_to_group("enemies")
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)

    tween.connect("tween_all_completed", self, "_on_tween_finished")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    sprite.connect("frame_changed", self, "_on_animation_frame_changed")

func puppet_process():
    if should_interpolate_movement:
        interpolate_movement()

func is_done_interpolating():
    return not tween.is_active()

func plan_turn():
    var path = tilemap.get_astar_path(coordinate, player.coordinate, true)
    var turn_coordinate = coordinate
    if not path.empty():
        turn_coordinate = path[1]
    turn = {
        "action": "move",
        "coordinate": turn_coordinate
    }

func get_turn_target():
    if turn.action == "attack":
        return player
    return null

func face_toward_player():
    if abs(player.coordinate.x - coordinate.x) >= abs(player.coordinate.y - coordinate.y):
        if player.coordinate.x > coordinate.x:
            facing_direction = Vector2.RIGHT
        else:
            facing_direction = Vector2.LEFT
    else:
        if player.coordinate.y > coordinate.y:
            facing_direction = Vector2.DOWN
        else:
            facing_direction = Vector2.UP

func execute_turn():
    if health == 0:
        return
    is_executing_turn = true
    if turn.action == "charge":
        face_toward_player()
        sprite.play("charge_" + Direction.get_name(facing_direction))
        is_charging = true
        end_turn()
    elif turn.action == "move":
        facing_direction = coordinate.direction_to(turn.coordinate)
        sprite.play(Direction.get_name(facing_direction))
        if tilemap.is_tile_free(turn.coordinate):
            tilemap.free_tile(coordinate)
            tilemap.reserve_tile(turn.coordinate)
            coordinate = turn.coordinate
            should_interpolate_movement = true
        elif is_melee_attacker and turn.coordinate == player.coordinate:
            sprite.play("attack_" + Direction.get_name(facing_direction))
        else:
            end_turn()
    elif turn.action == "attack":
        sprite.play("attack_" + Direction.get_name(facing_direction))

func end_turn():
    is_executing_turn = false
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
        end_turn()
        should_interpolate_movement = false

func _on_tween_finished():
    end_turn()

func _on_animation_finished():
    if sprite.animation.begins_with("attack"):
        sprite.play(Direction.get_name(facing_direction))

func _on_animation_frame_changed():
    if sprite.animation.begins_with("attack") and sprite.frame == attack_impact_frame:
        attack_impact()

func attack_impact():
    pass

func take_damage(result):
    var damage_number = effect_damage_number_scene.instance()
    get_parent().add_child(damage_number)
    damage_number.spawn(coordinate, result)

    if result.value != -1:
        sprite.play("hurt_" + Direction.get_name(facing_direction))
        is_charging = false
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
        sprite.play("death_" + Direction.get_name(facing_direction))
        yield(sprite, "animation_finished")

        var item_drop = item_drop_scene.instance()
        get_parent().add_child(item_drop)
        item_drop.spawn(coordinate, dropped_item)

        tilemap.free_tile(coordinate)
        turn = null
        queue_free()
    else:
        if result.value != -1:
            sprite.play(Direction.get_name(facing_direction))
