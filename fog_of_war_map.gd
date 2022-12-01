extends TileMap

onready var tilemap = get_parent().get_node("tilemap")

func _ready():
    for y in range(0, tilemap.MAP_HEIGHT):
        for x in range(0, tilemap.MAP_WIDTH):
            set_cell(x, y, 0)

func update_map(player_position: Vector2):
    for y in range(0, tilemap.MAP_HEIGHT):
        for x in range(0, tilemap.MAP_WIDTH):
            if get_cell(x, y) == -1:
                set_cell(x, y, 1)
    var sight_range = 4
    var light_rays = [player_position]
    while not light_rays.empty():
        var next_ray = light_rays[0]
        light_rays.pop_front()
        if tilemap.get_manhatten_distance(next_ray, player_position) > sight_range:
            continue
        if tilemap.get_cellv(next_ray) == -1:
            continue
        if get_cellv(next_ray) == -1:
            continue
        set_cellv(next_ray, -1)
        for direction in Direction.VECTORS.values():
            light_rays.append(next_ray + direction)