extends Node2D
class_name Generator

enum GeneratorTile {
    FLOOR = 1,
    STAIRS = 2,
    KITCHEN = 3,
    PLAYER = 4,
    WALL = 5
}

enum Enemy {
    TOMATO,
    ONION
}

const RENDER_SCALE = 2
const SAFE_ROOM_SIZE = Vector2(3, 4)

var width
var height
var grid
var room_points 
var safe_room_pos
var render_safe_room = true
var kitchen_coordinate
var player_coordinate
var stairs_coordinate
var enemy_spawns

func _ready():
    generate_grid(RandomNumberGenerator.new(), 50, 50)

func grid_at(x, y):
    if x < 0 or y < 0 or x >= width or y >= height:
        return 0
    else:
        return grid[y][x]

func generate_enemy_test_grid():
    width = 50
    height = 50
    var actual_grid = [
        [1, 1, 1, 1, 1],
        [1, 0, 0, 0, 1],
        [1, 1, 0, 1, 1],
        [1, 0, 0, 0, 1],
        [1, 1, 1, 1, 1],
    ]
    grid = []
    for y in range(0, height):
        grid.append([])
        for x in range(0, width):
            if x < 10 or y < 10 or x > 14 or y > 14:
                grid[y].append(0)
            else:
                var relative_coord = Vector2(x, y) - Vector2(10, 10)
                if actual_grid[relative_coord.y][relative_coord.x] == 1:
                    grid[y].append(GeneratorTile.WALL)
                else:
                    grid[y].append(GeneratorTile.FLOOR)
    player_coordinate = Vector2(11, 11)
    kitchen_coordinate = Vector2(0, 0)
    safe_room_pos = Vector2(0, 0)
    enemy_spawns = [
        {
            "type": Enemy.TOMATO,
            "coordinate": Vector2(11, 13)
        },
        {
            "type": Enemy.TOMATO,
            "coordinate": Vector2(13, 13)
        }
    ]

func generate_grid(rng, with_width, with_height):
    width = with_width
    height = with_height

    var success = false
    while not success:
        grid = grid_generate_random(rng)
        for _i in range(0, 5):
            grid = grid_life_step(grid)
        grid_connect_rooms(rng)
        if not grid_generate_safe_room(rng):
            success = false
            continue
        grid_fill_floor()
        kitchen_coordinate = safe_room_pos
        stairs_coordinate = safe_room_pos + Vector2(1, 2)
        grid_choose_player_spawn(rng)
        grid_choose_enemy_spawns(rng)
        grid_mark_walls()
        room_points.pop_front()
        room_points.pop_front()
        success = true
    return grid

func grid_generate_random(rng):
    var cells = []
    for y in range(0, height):
        cells.append([])
        for x in range(0, width):
            if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                cells[y].append(0)
            elif rng.randi_range(0, 100) < 50:
                cells[y].append(1)
            else:
                cells[y].append(0)
    return cells

func grid_life_step(old):
    var cells = []
    for y in range(0, old.size()):
        cells.append([])
        for x in range(0, old[0].size()):
            if x == 0 or y == 0 or x == old[0].size() - 1 or y == old.size() - 1:
                cells[y].append(0)
                continue
            var neighbours = 0
            for dy in [y - 1, y, y + 1]:
                for dx in [x - 1, x, x + 1]:
                    if dx == x and dy == y:
                        continue
                    if dx < 0 or dx >= old[0].size() or dy < 0 or dy >= old.size():
                        continue
                    if old[dy][dx]:
                        neighbours += 1
            var value = old[y][x]
            if value == 1 and neighbours < 4:
                value = 0
            elif value == 0 and neighbours >= 5:
                value = 1
            cells[y].append(value)
    return cells

func grid_connect_rooms(rng):
    room_points = [[], []]
    var room_id = 2
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] == 1:
                var frontier = [Vector2(x, y)]
                room_points.append([])
                while not frontier.empty():
                    var next_point = frontier.pop_front()
                    if next_point.x < 0 or next_point.x >= grid[0].size() or next_point.y < 0 or next_point.y >= grid.size():
                        continue
                    if grid[next_point.y][next_point.x] != 1:
                        continue
                    grid[next_point.y][next_point.x] = room_id
                    room_points[room_id].append(next_point)
                    for direction in Direction.VECTORS.values():
                        frontier.append(next_point + direction)
                room_id += 1

    for first_room in range(2, room_points.size() - 1):
        var first_room_points = room_points[first_room]
        var first_point = first_room_points[rng.randi_range(0, first_room_points.size() - 1)]

        var second_room = first_room + 1
        var second_room_points = room_points[second_room]
        var second_point = second_room_points[rng.randi_range(0, second_room_points.size() - 1)]

        if grid[first_point.y][first_point.x] == grid[second_point.y][second_point.x]:
            continue

        var path = get_astar_path(first_point, second_point)
        for point in path:
            grid[point.y][point.x] = room_id

func grid_fill_floor():
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] > 0:
                grid[y][x] = GeneratorTile.FLOOR

func grid_mark_walls():
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] == 1:
                for direction in Direction.EIGHT_DIRECTION_VECTORS:
                    var point = Vector2(x, y) + direction
                    if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
                        continue
                    if grid[point.y][point.x] == 0:
                        grid[point.y][point.x] = GeneratorTile.WALL

func grid_generate_safe_room(rng):
    var attempts = 0
    while attempts != 15:
        safe_room_pos = Vector2(
            rng.randi_range(2, width - 2 - SAFE_ROOM_SIZE.x), 
            rng.randi_range(2, height - 2 - SAFE_ROOM_SIZE.y)
        )

        var is_valid = true
        # The minus and plus 1 are added to make sure we're not directly touching another room
        for y in range(safe_room_pos.y - 2, safe_room_pos.y + SAFE_ROOM_SIZE.y + 2):
            for x in range(safe_room_pos.x - 2, safe_room_pos.x + SAFE_ROOM_SIZE.x + 2):
                if grid[y][x] != 0:
                    is_valid = false
                    break
            if not is_valid:
                break

        if not is_valid:
            attempts += 1
            continue

        for y in range(0, SAFE_ROOM_SIZE.y):
            for x in range(0, SAFE_ROOM_SIZE.x):
                var point = safe_room_pos + Vector2(x, y)
                grid[point.y][point.x] = 1

        var nearest = null
        var nearest_dist = 0
        var safe_room_center = safe_room_pos + Vector2(1, 2)
        for y in range(0, grid.size()):
            for x in range(0, grid[0].size()):
                if grid[y][x] > 1:
                    if nearest == null:
                        nearest = Vector2(x, y)
                        nearest_dist = abs(safe_room_center.x - nearest.x) + abs(safe_room_center.y - nearest.y)
                    else:
                        var dist = abs(safe_room_center.x - x) + abs(safe_room_center.y - y)
                        if dist < nearest_dist:
                            nearest = Vector2(x, y)
                            nearest_dist = dist

        var safe_room_point = safe_room_pos + Vector2(rng.randi_range(0, SAFE_ROOM_SIZE.x - 1), rng.randi_range(0, SAFE_ROOM_SIZE.y - 1))
        var path = get_astar_path(safe_room_point, nearest)
        for point in path:
            grid[point.y][point.x] = 1

        return true
    return false

func grid_choose_player_spawn(rng):
    while true:
        player_coordinate = Vector2(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
        if grid[player_coordinate.y][player_coordinate.x] == 0:
            continue
        if (player_coordinate.x >= safe_room_pos.x and player_coordinate.x <= safe_room_pos.x + SAFE_ROOM_SIZE.x - 1 and player_coordinate.y >= safe_room_pos.y and player_coordinate.y <= safe_room_pos.y + SAFE_ROOM_SIZE.y - 1):
            continue
        return

func grid_choose_enemy_spawns(rng):
    var desired_number_of_enemies = 5
    enemy_spawns = []
    while enemy_spawns.size() != desired_number_of_enemies:
        var enemy_coord = Vector2(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
        if grid[enemy_coord.y][enemy_coord.x] == 0:
            continue
        if (enemy_coord.x >= safe_room_pos.x and enemy_coord.x <= safe_room_pos.x + SAFE_ROOM_SIZE.x - 1 and enemy_coord.y >= safe_room_pos.y and enemy_coord.y <= safe_room_pos.y + SAFE_ROOM_SIZE.y - 1):
            continue
        if abs(player_coordinate.x - enemy_coord.x) + abs(player_coordinate.y - enemy_coord.y) < 10:
            continue
        enemy_spawns.append({
            "type": Enemy.TOMATO,
            "coordinate": enemy_coord
        })

func get_astar_path(from: Vector2, to: Vector2):
    var frontier = [{ "path": [from], "score": 0 }]
    var explored = []

    while frontier.size() != 0:
        var smallest_index = 0
        for i in range(1, frontier.size()):
            if frontier[i].score < frontier[smallest_index].score:
                smallest_index = i
        var smallest = frontier[smallest_index]
        frontier.remove(smallest_index)

        # If solution, return the first step
        if smallest.path[smallest.path.size() - 1] == to:
            return smallest.path

        # Otherwise, add to explored
        explored.append(smallest.path[smallest.path.size() - 1])

        for direction in Direction.VECTORS.values():
            var new_pos = smallest.path[smallest.path.size() - 1] + direction
            var new_path = smallest.path + [new_pos]
            var new_score = abs(new_pos.x - to.x) + abs(new_pos.y - to.y)

            if new_pos.x <= 0 or new_pos.y <= 0 or new_pos.x >= grid[0].size() - 1 or new_pos.y >= grid.size() - 1:
                continue

            if explored.has(new_pos):
                continue
            
            for path in frontier:
                if path.path[path.path.size() - 1] == new_pos:
                    if new_score < path.score:
                        path.score = new_score
                        path.path = new_path
                    continue

            frontier.append({ "path": new_path, "score": new_score })
        
    # Pathfinding failed
    return []

func _process(_delta):
    if Input.is_action_just_pressed("action"):
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        generate_grid(rng, 50, 50)
        update()
    elif Input.is_action_just_pressed("back"):
        render_safe_room = not render_safe_room
        update()

func _draw():
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] != 0:
                var color = Color(1, 1, 1, 1)
                draw_rect(Rect2(Vector2(x, y) * RENDER_SCALE, Vector2(1, 1) * RENDER_SCALE), color)
