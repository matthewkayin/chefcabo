extends Node2D

var player = null

func _process(_delta):
    if player == null:
        player = get_node_or_null("player")
        if player == null:
            return
    if player.is_turn_ready and player.turn != null:
        play_turn()

func play_turn():
    player.is_turn_ready = false

    var actors = [weakref(player)]
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.plan_turn()
        actors.append(weakref(enemy))

    var special_actors = []
    var turn_targets = []

    for actor in actors:
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
        if special_actors[0].get_ref() == null:
            special_actors.pop_front()
            continue
        special_actors[0].get_ref().execute_turn()
        if special_actors[0].get_ref().turn != null:
            yield(special_actors[0].get_ref(), "turn_finished")
        special_actors.pop_front()

    for actor in actors:
        if actor.get_ref() == null:
            continue
        if actor.get_ref().turn != null:
            yield(actor.get_ref(), "turn_finished")

    player.is_turn_ready = true
