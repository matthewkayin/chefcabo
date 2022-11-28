extends TileMap

signal finished(selected_coordinate)

onready var tilemap = get_node("../tilemap")

onready var cursor = $cursor

enum RangeType {
    CIRCLE
}

const RANGES = {
    RangeType.CIRCLE: [
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
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
    cursor.visible = false

func is_open():
    return visible

func open(at_coordinate: Vector2, range_type: int):
    aim_range = RANGES[range_type]
    var range_center = Vector2(int(aim_range[0].size() / 2), int(aim_range.size() / 2))
    range_start = at_coordinate - Vector2((aim_range[0].size() - 1) / 2, (aim_range.size() - 1) / 2)
    for y in [-1, 0, 1]:
        for x in [0, 1, -1]:
            if y == 0 and x == 0:
                continue
            var direction = Vector2(x, y)
            var current = range_center + direction
            while not (current.x < 0 or current.y < 0 or 
                       current.x >= aim_range[0].size() or current.y >= aim_range.size() or 
                       aim_range[current.y][current.x] == 0 or tilemap.is_tile_blocked((current - range_center) + at_coordinate)):
                set_cellv((current - range_center) + at_coordinate, 0)
                current += direction

    cursor_position = at_coordinate
    cursor.position = cursor_position * 32
    cursor.frame = 2
    cursor.visible = true

    visible = true

func close():
    for y in range(0, aim_range.size()):
        for x in range(0, aim_range[0].size()):
            set_cellv(range_start + Vector2(x, y), -1)
    cursor_position = null
    cursor.visible = false
    visible = false

func move_cursor(direction: Vector2):
    cursor_position += direction
    cursor.position = cursor_position * 32
    if get_cellv(cursor_position) == 0:
        cursor.frame = 1
    else:
        cursor.frame = 2

func _process(_delta):
    if not is_open():
        return
    if Input.is_action_just_pressed("back"):
        emit_signal("finished", null)
        close()
        return
    if Input.is_action_just_pressed("action"):
        if cursor.frame == 2:
            return
        emit_signal("finished", range_start + cursor_position)
        close()
        return
    for name in Direction.NAMES:
        if Input.is_action_just_pressed(name):
            move_cursor(Direction.VECTORS[name])
