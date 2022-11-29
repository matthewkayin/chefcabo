extends Node2D

onready var sprite = $sprite
onready var timer = $timer

var item: int
var coordinate: Vector2

func _ready():
    timer.connect("timeout", self, "_on_timeout")

func spawn(at_coordinate: Vector2, with_item: int):
    coordinate = at_coordinate
    position = coordinate * 32
    item = with_item
    sprite.texture = Items.DATA[item].texture
    sprite.frame = 0 
    timer.start(0.2)

    add_to_group("items")

func _on_timeout():
    sprite.frame = (sprite.frame + 1) % sprite.hframes