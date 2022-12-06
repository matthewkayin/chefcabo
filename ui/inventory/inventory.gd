extends Control

signal used_item(item)
signal claim_item

onready var inventory_transition_scene = preload("res://ui/inventory/inventory_transition.tscn")

onready var rows = [$row_1, $row_2, $row_3, $row_4, $row_5, $row_6]
onready var cursor = $cursor
onready var pot = $pot
onready var timer = $timer
onready var fade = $fade
onready var tween = $tween
onready var bg = $bg
onready var ingredients_bar = $ingredients_bar
onready var cook_button = $cook_button

onready var sprites = []
onready var sprite_labels = []
onready var ingredient_sprites = []

const ITEM_STACK_SIZE = 16

var cursor_index = Vector2.ZERO
var inventory = []
var ingredients = []
var ingredient_count = 0
var just_opened_or_closed = false
var in_cook_mode = false

func _ready():
    for i in range(0, rows.size()):
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

func get_add_item_index(item: int):
    for y in range(0, inventory.size()):
        for x in range(0, inventory[0].size()):
            if inventory[y][x] == null:
                continue
            if inventory[y][x].item == item:
                return Vector2(x, y)
    for y in range(0, inventory.size()):
        for x in range(0, inventory[0].size()):
            if inventory[y][x] == null:
                return Vector2(x, y)

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
    if ingredients.size() == 3:
        return

    if sprites[cursor_index.y][cursor_index.x].texture != null:
        sprites[cursor_index.y][cursor_index.x].frame = 0

    cursor_index += direction
    if cursor_index.x >= inventory[0].size():
        cursor_index.x = 0
    elif cursor_index.x < 0:
        cursor_index.x = inventory[0].size() - 1
    if cursor_index.y >= inventory.size():
        cursor_index.y = 0
    elif cursor_index.y < 0:
        cursor_index.y = inventory.size() - 1
    
    refresh_cursor()

func refresh_cursor():
    cursor.visible = true
    cursor.position = sprites[cursor_index.y][cursor_index.x].position + Vector2(0, rows[cursor_index.y].rect_position.y) - Vector2(1, 1)

func refresh_sprites():
    for y in range(0, inventory.size()):
        for x in range(0, inventory[0].size()):
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
    cook_button.visible = ingredients.size() == 3
    cursor.visible = ingredients.size() != 3

func open(cook_mode: bool = false):
    if just_opened_or_closed:
        just_opened_or_closed = false 
        return

    in_cook_mode = cook_mode

    bg.visible = true
    ingredients_bar.visible = in_cook_mode
    pot.visible = in_cook_mode
    cursor.visible = true
    for row in rows:
        row.visible = true
    $ingredients.visible = in_cook_mode
    $cook_result.visible = false
    fade.color = Color(0, 0, 0, 0.5)
    fade.visible = in_cook_mode
    cook_button.visible = false

    cursor_index = Vector2.ZERO
    refresh_cursor()
    refresh_sprites()

    if in_cook_mode:
        modulate = Color(1, 1, 1, 0)
        visible = true
        tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.2)
        tween.start()
        yield(tween, "tween_all_completed")
    else:
        modulate = Color(1, 1, 1, 1)
        visible = true

    timer.start(0.2)
    just_opened_or_closed = true

func close():
    if in_cook_mode:
        tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.2)
        tween.start()
        yield(tween, "tween_all_completed")

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
    if ingredients.size() == 3 and not $cook_button.visible:
        if $cook_result/highlight.visible and Input.is_action_just_pressed("action"):
            emit_signal("claim_item")
        return
    if Input.is_action_just_pressed("back") and ingredient_count == 0:
        close()
        return
    if in_cook_mode:
        if Input.is_action_just_pressed("action") and ingredients.size() == 3:
            cook_ingredients()
            return
        if Input.is_action_just_pressed("action") and ingredient_count < 3:
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
        ingredient_count += 1
        var transition_instance = inventory_transition_scene.instance()
        transition_instance.connect("finished", self, "_on_inventory_transition_finished")
        add_child(transition_instance)
        transition_instance.begin(selection.item, true, sprites[cursor_index.y][cursor_index.x], ingredient_sprites[ingredients.size()])
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
    var add_item_index = get_add_item_index(ingredients[ingredients.size() - 1])
    var transition_instance = inventory_transition_scene.instance()
    transition_instance.connect("finished", self, "_on_inventory_transition_finished")
    add_child(transition_instance)
    transition_instance.begin(ingredients[ingredients.size() - 1], false, ingredient_sprites[ingredients.size() - 1], sprites[add_item_index.y][add_item_index.x])
    ingredients.remove(ingredients.size() - 1)
    ingredient_count -= 1
    refresh_sprites()

func _on_inventory_transition_finished(item: int, adding: bool):
    if adding:
        ingredients.append(item)
    else:
        add_item(item)
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

    var result = null
    for recipe in Items.RECIPES:
        if dictionaries_are_equal(recipe.ingredients, ingredients_formatted):
            result = recipe.result
            break

    cook_button.visible = false
    timer.stop()
    for i in [1, 0, 2]:
        if i != 1:
            timer.start(0.2)
            yield(timer, "timeout")
            timer.stop()
        ingredient_sprites[i].begin_animation()

    for i in range(0, 3):
        if not ingredient_sprites[i].is_finished():
            yield(ingredient_sprites[i], "finished")

    if result != null:
        $cook_result.visible = true
        $cook_result/highlight.visible = false

        var transition_instance = inventory_transition_scene.instance()
        transition_instance.connect("finished", self, "_on_inventory_transition_finished")
        add_child(transition_instance)

        timer.start(0.2)
        yield(timer, "timeout")
        timer.stop()

        yield(transition_instance.rise_from_pot(result), "completed")

        $cook_result/highlight.visible = true
        transition_instance.animate_item()
        yield(self, "claim_item")

        var add_item_index = get_add_item_index(result)
        transition_instance.claim_item(sprites[add_item_index.y][add_item_index.x])
        yield(transition_instance, "finished")

        $cook_result.visible = false
        add_item(result)

    timer.start(0.2)

    for i in range(0, 3):
        ingredient_sprites[i].reset()

    # add_item()
    ingredients = []
    ingredient_count = 0
    refresh_sprites()
