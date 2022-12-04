extends Node2D

onready var tilemap = get_node("../tilemap")

var coordinate

func _ready():
    add_to_group("kitchens")
    position = coordinate * 32
    tilemap.reserve_tile(coordinate)
