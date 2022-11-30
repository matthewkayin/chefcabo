extends Control

signal used_item(item)

onready var cursor = $cursor
onready var pot = $pot
onready var timer = $timer

onready var sprites = []
onready var sprite_labels = []
onready var ingredient_sprites = []

const ITEM_STACK_SIZE = 16

var cursor_index = Vector2.ZERO
var inventory = []
var ingredients = []
var just_opened_or_closed = false
var in_cook_mode = false

func _ready():
    var rows = [$row_1, $row_2, $row_3]
    for i in range(0, 3):
        sprites.append([])
        sprite_labels.append([])
        inventory.append([])
        for child in rows[i].get_children():
            sprites[i].append(child)
            sprite_labels[i].append(child.get_child(0))
            inventory[i].append(null)
    for sprite in $ingredients.get_children():
        ingredient_sprites.append(sprite)

    timer.connect("timeout", self, "_on_timer_timeout")

func _on_timer_timeout():
    var sprite = sprites[cursor_index.y][cursor_index.x]
    if sprite.texture == null:
        return
    sprite.frame = (sprite.frame + 1) % sprite.hframes

func is_full():
    var inventory_size = 0
    for row in inventory:
        for item in inventory:
            if item != null:
                inventory_size += 1
    return inventory_size == 12

func is_open():
    return visible

func add_item(item: int):
    # We do two for loops because we want to search the whole inventory for the item before adding an entirely new entry
    for row in inventory:
        for existing_item in row:
            if existing_item != null and existing_item.item == item and existing_item.quantity < ITEM_STACK_SIZE:
                existing_item.quantity += 1
                return
    for row in inventory:
        for existing_item_index in range(0, row.size()):
            if row[existing_item_index] == null:
                row[existing_item_index] = { "item": item, "quantity": 1 }
                return

func remove_item(item: int, remove_all: bool = false):
    for row in inventory:
        for existing_item_index in range(0, row.size()):
            if row[existing_item_index] == null:
                continue
            if row[existing_item_index].item == item:
                if remove_all or row[existing_item_index].quantity == 1:
                    row[existing_item_index] = null
                else:
                    row[existing_item_index].quantity -= 1

func navigate_cursor(direction: Vector2):
    if sprites[cursor_index.y][cursor_index.x].texture != null:
        sprites[cursor_index.y][cursor_index.x].frame = 0

    cursor_index += direction
    if cursor_index.x >= 4:
        cursor_index.x = 0
    elif cursor_index.x < 0:
        cursor_index.x = 3
    if cursor_index.y >= 3:
        cursor_index.y = 0
    elif cursor_index.y < 0:
        cursor_index.y = 2
    
    refresh_cursor()

func refresh_cursor():
    cursor.visible = true
    cursor.position = sprites[cursor_index.y][cursor_index.x].position
    cursor.play("default")

func refresh_sprites():
    for y in range(0, 3):
        for x in range(0, 4):
            if inventory[y][x] == null:
                sprites[y][x].texture = null
                sprite_labels[y][x].visible = false
            else:
                sprites[y][x].texture = Items.DATA[inventory[y][x].item].texture
                if inventory[y][x].quantity > 1:
                    sprite_labels[y][x].visible = true
                    sprite_labels[y][x].text = str(inventory[y][x].quantity)
                else:
                    sprite_labels[y][x].visible = false
    for index in range(0, 3):
        if index >= ingredients.size():
            ingredient_sprites[index].texture = null
        else:
            ingredient_sprites[index].texture = Items.DATA[ingredients[index]].texture

func open(cook_mode: bool = false):
    if just_opened_or_closed:
        just_opened_or_closed = false 
        return

    cursor_index = Vector2.ZERO
    refresh_cursor()
    refresh_sprites()
    in_cook_mode = cook_mode
    pot.visible = in_cook_mode
    timer.start(0.2)
    visible = true
    just_opened_or_closed = true

func close():
    visible = false
    timer.stop()
    just_opened_or_closed = true

func _process(_delta):
    if just_opened_or_closed: 
        just_opened_or_closed = false
        return
    if not visible:
        return
    if inventory.size() == 0:
        cursor.visible = false
    if Input.is_action_just_pressed("back") and ingredients.empty():
        close()
        return
    if in_cook_mode:
        if Input.is_action_just_pressed("action") and ingredients.size() == 3:
            cook_ingredients()
            return
        if Input.is_action_just_pressed("action"):
            add_ingredient()
            return
        if Input.is_action_just_pressed("back"):
            remove_ingredient()
            return
    else:
        if Input.is_action_just_pressed("action"):
            use_item()
            return
    for direction in Direction.NAMES:
        if Input.is_action_just_pressed(direction):
            navigate_cursor(Direction.VECTORS[direction])

func add_ingredient():
    var selection = inventory[cursor_index.y][cursor_index.x]
    if selection == null:
        return
    if Items.DATA[selection.item].type != Items.Type.INGREDIENT and ingredients.size() > 0:
        return
    if Items.DATA[selection.item].type == Items.Type.INGREDIENT and ingredients.size() == 3:
        return
    if Items.DATA[selection.item].type != Items.Type.INGREDIENT:
        return

    if Items.DATA[selection.item].type == Items.Type.INGREDIENT:
        remove_item(selection.item)
        ingredients.append(selection.item)
        refresh_sprites()

func use_item():
    var selection = inventory[cursor_index.y][cursor_index.x]
    if selection == null:
        return
    if Items.DATA[selection.item].type == Items.Type.INGREDIENT:
        return
    remove_item(selection.item)
    close()
    emit_signal("used_item", selection.item)

func remove_ingredient():
    if ingredients.size() == 0:
        return
    add_item(ingredients[ingredients.size() - 1])
    ingredients.remove(ingredients.size() - 1)
    refresh_sprites()

func dictionaries_are_equal(a, b):
    for key in a.keys():
        if not b.has(key) or a[key] != b[key]:
            return false
    return true

func cook_ingredients():
    if ingredients.size() != 3:
        return
    var ingredients_formatted = {}
    for ingredient in ingredients:
        if ingredients_formatted.has(ingredient):
            ingredients_formatted[ingredient] += 1
        else: 
            ingredients_formatted[ingredient] = 1

    for recipe in Items.RECIPES:
        if dictionaries_are_equal(recipe.ingredients, ingredients_formatted):
            add_item(recipe.result)
            break
    ingredients = []
    refresh_sprites()
