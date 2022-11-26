extends Control

onready var cursor = $cursor
onready var pot = $pot
onready var sprites = []
onready var sprite_labels = []
onready var ingredient_sprites = []

const ITEM_STACK_SIZE = 16

var cursor_index = Vector2.ZERO
var inventory = []
var ingredients = []
var just_opened = false
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
    cursor_index = Vector2.ZERO
    refresh_cursor()
    refresh_sprites()
    in_cook_mode = cook_mode
    pot.visible = in_cook_mode
    visible = true
    just_opened = true

func close():
    visible = false

func _process(_delta):
    if not visible:
        return
    if just_opened: 
        just_opened = false
        return
    if inventory.size() == 0:
        cursor.visible = false
    if Input.is_action_just_pressed("menu"):
        close()
        return
    if in_cook_mode:
        if Input.is_action_just_pressed("action"):
            add_ingredient()
            return
        if Input.is_action_just_pressed("back"):
            remove_ingredient()
            return
        if Input.is_action_just_pressed("cook"):
            cook_ingredients()
            return
    for direction in Direction.NAMES:
        if Input.is_action_just_pressed(direction):
            navigate_cursor(Direction.VECTORS[direction])

func add_ingredient():
    if ingredients.size() == 3:
        return
    var selection = inventory[cursor_index.y][cursor_index.x]
    if selection == null:
        return
    remove_item(selection.item)
    ingredients.append(selection.item)
    refresh_sprites()

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
