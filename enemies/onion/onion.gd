extends Enemy

func plan_turn():
    var dist_to_player = tilemap.get_manhatten_distance(coordinate, player.coordinate)
    if player.is_in_safe_room() or dist_to_player >= 10:
        is_charging = false
        var direction_index = global.rng.randi_range(0, 3)
        turn = {
            "action": "move",
            "coordinate": coordinate + Direction.VECTORS[Direction.NAMES[direction_index]]
        }
    else:
        .plan_turn()