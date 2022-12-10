extends TileMap

onready var player_scene = preload("res://player/player.tscn")
onready var tomato_scene = preload("res://enemies/tomato/tomato.tscn")
onready var kitchen_scene = preload("res://kitchen.tscn")

onready var global = get_node("/root/Global")

const MAP_WIDTH = 50
const MAP_HEIGHT = 50
var tile_open = []

enum Tile {
    FLOOR_1,
    FLOOR_COBBLE,
    FLOOR_MOSS_LIGHT,
    FLOOR_MOSS_MED,
    FLOOR_MOSS_HEAVY,
    DARKNESS,
    WALL_TOP,
    WALL_TOP_MOSS_LIGHT,
    WALL_TOP_MOSS_MED,
    WALL_TOP_MOSS_HEAVY,
    WALL_TOP_RIGHT,
    WALL_RIGHT,
    WALL_BOT_RIGHT,
    WALL_BOT,
    WALL_BOT_LEFT,
    WALL_LEFT,
    WALL_TOP_LEFT,
    WALL_INNER_TOP_RIGHT,
    WALL_INNER_TOP_LEFT,
    WALL_INNER_BOT_RIGHT,
    WALL_INNER_BOT_LEFT,
    STAIRS
}
var blocked_tiles = []

var safe_room_rect

func _ready():
    init_floor()

func init_floor():
    blocked_tiles = []
    for key in Tile.keys():
        Tile[key] = tile_set.find_tile_by_name(key.to_lower())
        if key.begins_with("WALL"):
            blocked_tiles.append(Tile[key])

    var generator = Generator.new()
    generator.generate_grid(global.rng, MAP_WIDTH, MAP_HEIGHT)

    safe_room_rect = Rect2(generator.safe_room_pos, generator.SAFE_ROOM_SIZE)

    for x in range(0, MAP_WIDTH):
        tile_open.append([])
        for y in range(0, MAP_HEIGHT):
            tile_open[x].append(true)
            if generator.grid[y][x] == Generator.GeneratorTile.FLOOR:
                set_cell(x, y, Tile.FLOOR_COBBLE)

    for y in range(0, MAP_HEIGHT):
        for x in range(0, MAP_WIDTH):
            if generator.grid[y][x] == Generator.GeneratorTile.WALL:
                var adjacent_floors = []
                for direction in Direction.VECTORS.values():
                    var point = Vector2(x, y) + direction
                    if generator.grid_at(point.x, point.y) == Generator.GeneratorTile.FLOOR:
                        adjacent_floors.append(direction)
                if adjacent_floors.size() >= 3 or (adjacent_floors.size() == 2 and adjacent_floors[0] + adjacent_floors[1] == Vector2.ZERO): 
                    generator.grid[y][x] = Generator.GeneratorTile.FLOOR
                    set_cell(x, y, Tile.FLOOR_COBBLE)

    for y in range(0, MAP_HEIGHT):
        for x in range(0, MAP_WIDTH):
            if generator.grid[y][x] == Generator.GeneratorTile.WALL:
                if generator.grid_at(x, y + 1) == Generator.GeneratorTile.FLOOR and generator.grid_at(x + 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_TOP_LEFT)
                    continue
                if generator.grid_at(x, y + 1) == Generator.GeneratorTile.FLOOR and generator.grid_at(x - 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_TOP_RIGHT)
                    continue
                if generator.grid_at(x, y - 1) == Generator.GeneratorTile.FLOOR and generator.grid_at(x + 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_BOT_LEFT)
                    continue
                if generator.grid_at(x, y - 1) == Generator.GeneratorTile.FLOOR and generator.grid_at(x - 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_BOT_RIGHT)
                    continue
                if generator.grid_at(x, y + 1) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_TOP)
                    continue
                if generator.grid_at(x, y - 1) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_BOT)
                    continue
                if generator.grid_at(x + 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_LEFT)
                    continue
                if generator.grid_at(x - 1, y) == Generator.GeneratorTile.FLOOR:
                    set_cell(x, y, Tile.WALL_RIGHT)
                    continue
                if generator.grid_at(x, y + 1) == Generator.GeneratorTile.WALL and generator.grid_at(x + 1, y) == Generator.GeneratorTile.WALL and generator.grid_at(x + 1, y + 1) == Generator.GeneratorTile.FLOOR:
                        set_cell(x, y, Tile.WALL_INNER_TOP_LEFT)
                        continue
                if generator.grid_at(x, y - 1) == Generator.GeneratorTile.WALL and generator.grid_at(x + 1, y) == Generator.GeneratorTile.WALL and generator.grid_at(x + 1, y - 1) == Generator.GeneratorTile.FLOOR:
                        set_cell(x, y, Tile.WALL_INNER_BOT_LEFT)
                        continue
                if generator.grid_at(x, y + 1) == Generator.GeneratorTile.WALL and generator.grid_at(x - 1, y) == Generator.GeneratorTile.WALL and generator.grid_at(x - 1, y + 1) == Generator.GeneratorTile.FLOOR:
                        set_cell(x, y, Tile.WALL_INNER_TOP_RIGHT)
                        continue
                if generator.grid_at(x, y - 1) == Generator.GeneratorTile.WALL and generator.grid_at(x - 1, y) == Generator.GeneratorTile.WALL and generator.grid_at(x - 1, y - 1) == Generator.GeneratorTile.FLOOR:
                        set_cell(x, y, Tile.WALL_INNER_BOT_RIGHT)
                        continue

    for x in range(0, MAP_WIDTH):
        for y in range(0, MAP_HEIGHT):
            if get_cell(x, y) == -1:
                set_cell(x, y, Tile.DARKNESS)

    for y in range(generator.safe_room_pos.y, generator.safe_room_pos.y + generator.SAFE_ROOM_SIZE.y):
        for x in range(generator.safe_room_pos.x, generator.safe_room_pos.x + generator.SAFE_ROOM_SIZE.x):
            set_cell(x, y, Tile.FLOOR_1)

    var moss_points = 0
    var moss_tiles = [Tile.FLOOR_MOSS_LIGHT, Tile.FLOOR_MOSS_MED, Tile.FLOOR_MOSS_HEAVY]
    var moss_wall_tiles = [Tile.WALL_TOP_MOSS_LIGHT, Tile.WALL_TOP_MOSS_MED, Tile.WALL_TOP_MOSS_HEAVY]
    var desired_moss_points = int((MAP_WIDTH * MAP_HEIGHT) / 167.0)
    while moss_points < desired_moss_points:
        var moss_pos = Vector2(global.rng.randi_range(0, MAP_WIDTH - 1), global.rng.randi_range(0, MAP_HEIGHT - 1))
        if get_cellv(moss_pos) != Tile.FLOOR_COBBLE:
            continue
        var moss_frontier = [{ "age": 0, "pos": moss_pos, "str": global.rng.randi_range(0, 2) }]
        while not moss_frontier.empty():
            var next = moss_frontier.pop_front()
            if get_cellv(next.pos) == Tile.FLOOR_COBBLE:
                if global.rng.randi_range(0, 20) == 0:
                    set_cellv(next.pos, moss_tiles[next.str])
            if get_cellv(next.pos) == Tile.WALL_TOP:
                set_cellv(next.pos, moss_wall_tiles[next.str])
                continue
            for direction in Direction.EIGHT_DIRECTION_VECTORS:
                var child_pos = next.pos + direction
                if get_cellv(child_pos) == Tile.WALL_TOP:
                    moss_frontier.append({ "age": next.age + 1, "pos": child_pos, "str": next.str })
                    continue
                if get_cellv(child_pos) != Tile.FLOOR_COBBLE:
                    continue
                var fade_score = global.rng.randi_range(0, next.age)
                var child_str = next.str
                if fade_score < next.age:
                    child_str -= 1
                if child_str == -1:
                    continue
                moss_frontier.append({ "age": next.age + 1, "pos": child_pos, "str": child_str })
        moss_points += 1

    set_cellv(generator.stairs_coordinate, Tile.STAIRS)

    var kitchen = kitchen_scene.instance()
    kitchen.coordinate = generator.kitchen_coordinate
    get_parent().call_deferred("add_child", kitchen)
    var player = player_scene.instance()
    player.coordinate = generator.player_coordinate
    get_parent().call_deferred("add_child", player)
    for spawn in generator.enemy_spawns:
        if spawn.type == generator.Enemy.TOMATO:
            var tomato_instance = tomato_scene.instance()
            tomato_instance.coordinate = spawn.coordinate
            get_parent().call_deferred("add_child", tomato_instance)

func astar_point_index(point_position: Vector2):
    return (point_position.x * MAP_HEIGHT) + point_position.y

func get_width():
    return tile_open.size()

func get_height():
    return tile_open[0].size()

func is_tile_free(coordinate: Vector2):
    return tile_open[coordinate.x][coordinate.y] and not blocked_tiles.has(get_cellv(coordinate))

func reserve_tile(coordinate: Vector2):
    tile_open[coordinate.x][coordinate.y] = false

func free_tile(coordinate: Vector2):
    tile_open[coordinate.x][coordinate.y] = true

func get_manhatten_distance(from: Vector2, to: Vector2) -> int:
    return int(abs(from.x - to.x) + abs(from.y - to.y))

func is_in_bounds(point: Vector2) -> bool:
    return not (point.x < 0 or point.y < 0 or point.x >= MAP_WIDTH or point.y >= MAP_HEIGHT)

func get_astar_path(from: Vector2, to: Vector2, limit_iterations = false):
    var iterations = 0

    var frontier = [{ "path": [from], "score": 0 }]
    var explored = []

    while frontier.size() != 0:
        iterations += 1
        if limit_iterations and iterations == 15:
            return []

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
            var new_score = get_manhatten_distance(new_pos, to)

            if not is_in_bounds(new_pos):
                continue
            if new_pos != to and not is_tile_free(new_pos):
                continue

            if explored.has(new_pos):
                continue
            
            var found_in_frontier = false
            for path in frontier:
                if path.path[path.path.size() - 1] == new_pos:
                    if new_score < path.score:
                        path.score = new_score
                        path.path = new_path
                    found_in_frontier = true
                    continue
            if found_in_frontier:
                continue

            frontier.append({ "path": new_path, "score": new_score })
        
    # Pathfinding failed
    return []
