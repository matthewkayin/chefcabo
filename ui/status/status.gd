extends Control

onready var health_label = $health_label

var player = null

func _ready():
    pass 

func _process(_delta):
    if player == null:
        player = get_node_or_null("../../player")
    if player == null:
        return
    
    health_label.text = "HP: " + String(player.health) + " / " + String(player.max_health)