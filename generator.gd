extends Node2D
class_name Generator

enum GeneratorTile {
    FLOOR = 1,
    STAIRS = 2,
    KITCHEN = 3,
    PLAYER = 4
}

const RENDER_SCALE = 2
const SAFE_ROOM = [
    [0, 1, 1, 0],
    [1, 1, 1, 1],
    [1, 1, 1, 1],
    [1, 1, 1, 1],
    [0, 1, 1, 0]
]

var width
var height
var grid
var safe_room = []
var safe_room_walls = []
var render_safe_room = true

func _ready():
    generate_grid(RandomNumberGenerator.new(), 50, 50)

func generate_grid(rng, with_width, with_height):
    width = with_width
    height = with_height

    var success = false
    while not success:
        grid = grid_generate_random(rng)
        for _i in range(0, 5):
            grid = grid_life_step(grid)
        if not grid_generate_safe_room(rng):
            success = false
            continue
        grid_connect_rooms(rng)
        grid_fill_walls()
        grid[safe_room[0].y][safe_room[0].x + 1] = GeneratorTile.KITCHEN
        grid_choose_player_spawn(rng)
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
    var room_points = [[], []]
    var room_id = 2
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] == 1:
                if safe_room.has(Vector2(x, y)):
                    continue
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

    var nearest = null
    var nearest_dist = 0
    var safe_room_center = safe_room[0] + ((Vector2(SAFE_ROOM[0].size(), SAFE_ROOM.size()) * 32) / 2)
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

    var safe_room_point = safe_room[rng.randi_range(0, safe_room.size() - 1)]
    var path = get_astar_path(safe_room_point, nearest, true)
    for point in path:
        grid[point.y][point.x] = 1

func grid_fill_walls():
    for y in range(0, grid.size()):
        for x in range(0, grid[0].size()):
            if grid[y][x] > 0:
                grid[y][x] = GeneratorTile.FLOOR

func grid_generate_safe_room(rng):
    var attempts = 0
    while attempts != 15:
        var top_left = Vector2(
            rng.randi_range(2, width - 2 - SAFE_ROOM[0].size()), 
            rng.randi_range(2, height - 2 - SAFE_ROOM.size())
        )

        var is_valid = true
        # The minus and plus 1 are added to make sure we're not directly touching another room
        for y in range(top_left.y - 2, top_left.y + SAFE_ROOM.size() + 2):
            for x in range(top_left.x - 2, top_left.x + SAFE_ROOM[0].size() + 2):
                if grid[y][x] != 0:
                    is_valid = false
                    break
            if not is_valid:
                break

        if not is_valid:
            attempts += 1
            continue

        safe_room = []
        safe_room_walls = []
        for y in range(0, SAFE_ROOM.size()):
            for x in range(0, SAFE_ROOM[0].size()):
                if SAFE_ROOM[y][x] == 0:
                    safe_room_walls.append(top_left + Vector2(x, y))
                    continue
                if x == 0:
                    safe_room_walls.append(top_left + Vector2(x - 1, y))
                if x == SAFE_ROOM[0].size() - 1:
                    safe_room_walls.append(top_left + Vector2(x + 1, y))
                if y == 0:
                    safe_room_walls.append(top_left + Vector2(x, y - 1))
                if y == SAFE_ROOM.size() - 1:
                    safe_room_walls.append(top_left + Vector2(x, y + 1))
                var point = top_left + Vector2(x, y)
                grid[point.y][point.x] = 1
                safe_room.append(point)

        return true
    return false

func grid_choose_player_spawn(rng):
    while true:
        var player_spawn = Vector2(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
        if grid[player_spawn.y][player_spawn.x] == 0:
            continue
        if safe_room.has(player_spawn):
            continue
        grid[player_spawn.y][player_spawn.x] = GeneratorTile.PLAYER
        return

func get_astar_path(from: Vector2, to: Vector2, allow_safe_room_points = false):
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
            if not allow_safe_room_points and (safe_room.has(new_pos) or safe_room_walls.has(new_pos)):
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
                if safe_room.has(Vector2(x, y)):
                    if not render_safe_room:
                        continue
                    color = Color(0, 1, 0, 1)
                draw_rect(Rect2(Vector2(x, y) * RENDER_SCALE, Vector2(1, 1) * RENDER_SCALE), color)
