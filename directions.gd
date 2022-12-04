class_name Direction

const NAMES = ["up", "right", "down", "left"]
const VECTORS = {
    "up": Vector2.UP,
    "right": Vector2.RIGHT,
    "down": Vector2.DOWN,
    "left": Vector2.LEFT
}
const EIGHT_DIRECTION_VECTORS = [
    Vector2(-1, -1),
    Vector2(0, -1),
    Vector2(1, -1),
    Vector2(-1, 0),
    Vector2(1, 0),
    Vector2(-1, 1),
    Vector2(0, 1),
    Vector2(1, 1),
]

static func get_name(direction: Vector2):
    for name in NAMES:
        if direction == VECTORS[name]:
            return name
    return ""