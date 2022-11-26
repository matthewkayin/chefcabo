extends TileMap

var rng = RandomNumberGenerator.new()

const MAP_WIDTH = 100
const MAP_HEIGHT = 100
var tile_open = []

func _ready():
    for x in range(0, MAP_WIDTH):
        tile_open.append([])
        for _y in range(0, MAP_HEIGHT):
            tile_open[x].append(true)

func get_point_on_rect_wall(rect: Rect2):
    var which_wall = rng.randi_range(0, 3)
    if which_wall == 0:
        return Vector2(rng.randi_range(rect.position.x + 1, rect.position.x + rect.size.x - 2), rect.position.y)
    elif which_wall == 1:
        return Vector2(rect.position.x + rect.size.x - 1, rng.randi_range(rect.position.y + 1, rect.position.y + rect.size.y - 2))
    elif which_wall == 2:
        return Vector2(rng.randi_range(rect.position.x + 1, rect.position.x + rect.size.x - 2), rect.position.y + rect.size.y - 1)
    else:
        return Vector2(rect.position.x, rng.randi_range(rect.position.y + 1, rect.position.y + rect.size.y - 2))

func astar_point_index(point_position: Vector2):
    return (point_position.x * MAP_HEIGHT) + point_position.y

func get_width():
    return tile_open.size()

func get_height():
    return tile_open[0].size()

func is_tile_free(coordinate: Vector2):
    return tile_open[coordinate.x][coordinate.y] and get_cellv(coordinate) != 2

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
