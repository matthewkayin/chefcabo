extends Node2D

onready var tilemap = $tilemap
onready var fade = $fade
onready var tween = $tween

var player = null
var player_health = null

var is_turn_ready = true

func _process(_delta):
    if player == null:
        player = get_node_or_null("player")
        if player == null:
            return
        if player_health != null:
            player.health = player_health
    
    player.puppet_process()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.puppet_process()
    
    if is_turn_ready:
        player.check_for_inputs()
        if player.turn != null:
            is_turn_ready = false
            play_turn()

func play_turn():
    var actors = [weakref(player)]
    for enemy in get_tree().get_nodes_in_group("enemies"):
        actors.append(weakref(enemy))

    var special_actors = []
    var turn_targets = []

    for actor in actors:
        if actor.get_ref().is_in_group("enemies"):
            actor.get_ref().plan_turn()
        if turn_targets.has(actor.get_ref()):
            special_actors.append(actor)
            continue
        var turn_target = actor.get_ref().get_turn_target()
        if turn_target != null:
            special_actors.append(actor)
            turn_targets.append(turn_target)
        else:
            actor.get_ref().execute_turn()

    while special_actors.size() != 0:
        if special_actors[0].get_ref() == null or special_actors[0].get_ref().health <= 0:
            special_actors.pop_front()
            continue
        var turn_target = special_actors[0].get_ref().get_turn_target()
        if turn_target != null and turn_target.is_executing_turn:
            yield(turn_target, "turn_finished")
        special_actors[0].get_ref().execute_turn()
        if special_actors[0].get_ref().turn != null:
            yield(special_actors[0].get_ref(), "turn_finished")
        special_actors.pop_front()

    for actor in actors:
        if actor.get_ref() == null:
            continue
        if actor.get_ref().turn != null:
            yield(actor.get_ref(), "turn_finished")

    if tilemap.get_cellv(player.coordinate) == tilemap.Tile.STAIRS:
        start_new_floor()
        return

    is_turn_ready = true

func start_new_floor():
    player_health = player.health
    player = null

    tween.interpolate_property(fade, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5)
    tween.start()

    for child in get_children():
        if ["tilemap", "highlight_map", "ui", "fade", "tween"].has(child.name):
            continue
        remove_child(child)
        child.queue_free()

    if tween.is_active():
        yield(tween, "tween_all_completed")

    tilemap.init_floor()

    tween.interpolate_property(fade, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5)
    tween.start()
    yield(tween, "tween_all_completed")
