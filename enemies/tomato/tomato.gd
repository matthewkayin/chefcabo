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
    elif dist_to_player <= 1:
        var direction = Vector2.ZERO
        var dist = 0
        for possible_direction in Direction.VECTORS.values():
            if not tilemap.is_tile_free(coordinate + possible_direction):
                continue
            var possible_dist = tilemap.get_manhatten_distance(coordinate + possible_direction, player.coordinate)
            if direction == Vector2.ZERO or possible_dist > dist:
                direction = possible_direction
                dist = possible_dist
        turn = {
            "action": "move",
            "coordinate": coordinate + direction
        }
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

    yield(player.take_damage(global.calculate_damage(self, player)), "completed")
    end_turn()