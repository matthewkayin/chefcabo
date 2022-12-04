extends TileMap

onready var player_scene = preload("res://player/player.tscn")
onready var tomato_scene = preload("res://enemies/tomato/tomato.tscn")
onready var kitchen_scene = preload("res://kitchen.tscn")

onready var global = get_node("/root/Global")

const MAP_WIDTH = 50
const MAP_HEIGHT = 50
var tile_open = []

func _ready():
    var generator = Generator.new()
    generator.generate_grid(global.rng, MAP_WIDTH, MAP_HEIGHT)

    for x in range(0, MAP_WIDTH):
        tile_open.append([])
        for y in range(0, MAP_HEIGHT):
            tile_open[x].append(true)
            if generator.grid[y][x] == Generator.GeneratorTile.FLOOR:
                set_cell(x, y, 0)
            elif generator.grid[y][x] == Generator.GeneratorTile.KITCHEN:
                set_cell(x, y, 0)
                var kitchen = kitchen_scene.instance()
                kitchen.coordinate = Vector2(x, y)
                get_parent().call_deferred("add_child", kitchen)
            elif generator.grid[y][x] == Generator.GeneratorTile.PLAYER:
                set_cell(x, y, 0)
                var player = player_scene.instance()
                player.coordinate = Vector2(x, y)
                get_parent().call_deferred("add_child", player)

    var directions = []
    for x in [-1, 0, 1]:
        for y in [-1, 0, 1]:
            if x == 0 and y == 0:
                continue
            directions.append(Vector2(x, y))

    for x in range(0, MAP_WIDTH):
        for y in range(0, MAP_HEIGHT):
            var current = Vector2(x, y)
            if get_cellv(current) == 0:
                for direction in directions:
                    if get_cellv(current + direction) == -1:
                        set_cellv(current + direction, 2)

func astar_point_index(point_position: Vector2):
    return (point_position.x * MAP_HEIGHT) + point_position.y

func get_width():
    return tile_open.size()

func get_height():
    return tile_open[0].size()

func is_tile_blocked(coordinate: Vector2):
    return get_cellv(coordinate) == 2

func is_tile_free(coordinate: Vector2):
    return tile_open[coordinate.x][coordinate.y] and not is_tile_blocked(coordinate)

func reserve_tile(coordinate: Vector2):
    tile_open[coordinate.x][coordinate.y] = false

func free_tile(coordinate: Vector2):
    tile_open[coordinate.x][coordinate.y] = true

func get_manhatten_distance(from: Vector2, to: Vector2) -> int:
    return int(abs(from.x - to.x) + abs(from.y - to.y))

func is_in_bounds(point: Vector2) -> bool:
    return not (point.x < 0 or point.y < 0 or point.x >= MAP_WIDTH or point.y >= MAP_HEIGHT)

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
            var new_score = get_manhatten_distance(new_pos, to)

            if not is_in_bounds(new_pos):
                continue
            if new_pos != to and not is_tile_free(new_pos):
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
