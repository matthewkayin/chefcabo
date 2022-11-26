extends Node2D

onready var sprite = $sprite

var item: int
var coordinate: Vector2

func _ready():
    pass 

func spawn(at_coordinate: Vector2, with_item: int):
    coordinate = at_coordinate
    position = coordinate * 32
    item = with_item
    sprite.texture = Items.DATA[item].texture

    add_to_group("items")