extends TileMap

signal finished(selected_coordinate)

onready var tilemap = get_node("../tilemap")

enum RangeType {
    CIRCLE
}

const RANGES = {
    RangeType.CIRCLE: [
        [0, 1, 1, 1, 0],
        [1, 1, 2, 1, 1],
        [1, 1, 0, 1, 1],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0]
    ]
}

var aim_range
var range_start
var cursor_position

func _ready():
    visible = false

func is_open():
    return visible

func open(at_coordinate: Vector2, range_type: int):
    aim_range = RANGES[range_type]
    range_start = at_coordinate - Vector2((aim_range.size() - 1) / 2, (aim_range[0].size() - 1) / 2)
    for y in range(0, aim_range.size()):
        for x in range(0, aim_range[0].size()):
            if aim_range[y][x] == 0:
                continue
            if tilemap.is_tile_blocked(range_start + Vector2(x, y)):
                continue
            if aim_range[y][x] == 2:
                set_cellv(range_start + Vector2(x, y), 1)
                cursor_position = Vector2(x, y)
            else:
                set_cellv(range_start + Vector2(x, y), 0)
    visible = true

func close():
    for y in range(0, aim_range.size()):
        for x in range(0, aim_range[0].size()):
            set_cellv(range_start + Vector2(x, y), -1)
    visible = false

func move_cursor(direction: Vector2):
    var new_pos = cursor_position + direction
    if get_cellv(range_start + new_pos) == -1:
        return
    set_cellv(range_start + cursor_position, 0)
    cursor_position = new_pos
    set_cellv(range_start + cursor_position, 1)

func _process(_delta):
    if not is_open():
        return
    if Input.is_action_just_pressed("back"):
        emit_signal("finished", null)
        close()
        return
    if Input.is_action_just_pressed("action"):
        emit_signal("finished", range_start + cursor_position)
        close()
        return
    for name in Direction.NAMES:
        if Input.is_action_just_pressed(name):
            move_cursor(Direction.VECTORS[name])