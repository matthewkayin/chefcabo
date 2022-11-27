class_name Items

enum Item {
    TOMATO,
    TOMATO_SOUP
}

enum Type {
    INGREDIENT,
    POTION,
    BOMB
}

const DATA = {
    Item.TOMATO: {
        "name": "Tomato",
        "texture": preload("res://items/deadmato.png"),
        "type": Type.INGREDIENT
    },
    Item.TOMATO_SOUP: {
        "name": "Tomato Soup",
        "texture": preload("res://items/tomato_soup.png"),
        "type": Type.BOMB
    }
}

const RECIPES = [
    {
        "ingredients": 
            {
                Item.TOMATO: 3
            }
        ,
        "result": Item.TOMATO_SOUP
    }
]