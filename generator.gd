extends Node2D
class_name Generator

var rooms = []

func _ready():
    pass

func generate(rng, width, height, desired_room_count):
    while rooms.size() != desired_room_count:
        var room_candidate = Rect2(
            Vector2(
                rng.randi_range(1, width - 32),
                rng.randi_range(1, height - 32)
            ), 
            Vector2(
                rng.randi_range(5, 15),
                rng.randi_range(5, 15)
            ))
        
        var is_room_valid = true
        for existing_room in rooms:
            if existing_room.intersects(room_candidate, true):
                is_room_valid = false
        
        if is_room_valid:
            rooms.append(room_candidate)

    for i in range(0, desired_room_count): 
        var num_hallways = 0
        for j in range(0, desired_room_count):
            if i == j:
                continue

            var has_horizontal_distance = rooms[i].position.x + rooms[i].size.x < rooms[j].position.x or rooms[j].position.x + rooms[j].size.x < rooms[i].position.x
            var has_vertical_distance = rooms[i].position.y + rooms[i].size.y < rooms[j].position.y or rooms[j].position.y + rooms[j].size.y < rooms[i].position.y
            var make_hallway_horizontal
            if has_horizontal_distance and has_vertical_distance:
                make_hallway_horizontal = bool(rng.randi_range(0, 1))
            elif has_horizontal_distance:
                make_hallway_horizontal = true
            elif has_vertical_distance:
                make_hallway_horizontal = false
            else:
                continue

            if make_hallway_horizontal:
                var start
                var end
                if rooms[i].position.x + rooms[i].size.x < rooms[j].position.x:
                    start = Vector2(rooms[i].position.x + rooms[i].size.x, rng.randi_range(rooms[i].position.y + 1, rooms[i].position.y + rooms[i].size.y - 2))
                    end = Vector2(rooms[j].position.x, rng.randi_range(rooms[j].position.y + 1, rooms[j].position.y + rooms[j].size.y - 2))
                else:
                    start = Vector2(rooms[j].position.x + rooms[j].size.x, rng.randi_range(rooms[j].position.y + 1, rooms[j].position.y + rooms[j].size.y - 2))
                    end = Vector2(rooms[i].position.x, rng.randi_range(rooms[i].position.y + 1, rooms[i].position.y + rooms[i].size.y - 2))
                var midpoint_x
                if start.y == end.y:
                    midpoint_x = null
                else:
                    midpoint_x = rng.randi_range(start.x, end.x)

                if midpoint_x == null:
                    rooms.append(Rect2(start, end - start))
                else:
                    var hall_part_1_end = Vector2(midpoint_x, start.y)
                    var hall_part_3_start = Vector2(midpoint_x, end.y)
                    rooms.append(create_hall(start, hall_part_1_end, true))
                    rooms.append(create_hall(hall_part_1_end, hall_part_3_start, false))
                    rooms.append(create_hall(hall_part_3_start, end, true))
            else:
                var start
                var end
                if rooms[i].position.y + rooms[i].size.y < rooms[j].position.y:
                    start = Vector2(rng.randi_range(rooms[i].position.x + 1, rooms[i].position.x + rooms[i].size.x - 2), rooms[i].position.y + rooms[i].size.y)
                    end = Vector2(rng.randi_range(rooms[j].position.x + 1, rooms[j].position.x + rooms[j].size.x - 2), rooms[j].position.y)
                else:
                    start = Vector2(rng.randi_range(rooms[j].position.x + 1, rooms[j].position.x + rooms[j].size.x - 2), rooms[j].position.y + rooms[j].size.y)
                    end = Vector2(rng.randi_range(rooms[i].position.x + 1, rooms[i].position.x + rooms[i].size.x - 2), rooms[i].position.y)
                var midpoint_y
                if start.x == end.x:
                    midpoint_y = null
                else:
                    midpoint_y = rng.randi_range(start.y, end.y)

                if midpoint_y == null:
                    rooms.append(Rect2(start, end - start))
                else:
                    var hall_part_1_end = Vector2(start.x, midpoint_y)
                    var hall_part_3_start = Vector2(end.x, midpoint_y)
                    rooms.append(create_hall(start, hall_part_1_end, false))
                    rooms.append(create_hall(hall_part_1_end, hall_part_3_start, true))
                    rooms.append(create_hall(hall_part_3_start, end, false))
            num_hallways += 1
            if num_hallways == 2:
                break

func create_hall(start, end, horizontal):
    var top_left = Vector2(min(start.x, end.x), min(start.y, end.y))
    var bottom_right = Vector2(max(start.x, end.x), max(start.y, end.y))
    var space_padding = Vector2.ZERO
    if horizontal:
        space_padding.y = 1
    else:
        space_padding.x = 1
        space_padding.y = 1
    return Rect2(top_left, bottom_right - top_left + space_padding)

func _draw():
    for room in rooms:
        draw_rect(room, Color(1, 0, 0, 1))
