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
    elif is_charging: 
        turn = {
            "action": "attack",
            "coordinate": player.coordinate
        }
        is_charging = false
    elif dist_to_player <= 3:
        turn = {
            "action": "charge"
        }
    else:
        .plan_turn()

func attack_impact():
    var bullet = bullet_scene.instance()
    get_parent().add_child(bullet)
    bullet.spawn(position, player.position)
    yield(bullet, "finished")
    bullet.queue_free()

    .attack_impact()