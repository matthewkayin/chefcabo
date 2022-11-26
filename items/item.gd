class_name Items

enum Item {
    TOMATO,
    TOMATO_SOUP
}

const DATA = {
    Item.TOMATO: {
        "name": "Tomato",
        "texture": preload("res://items/deadmato.png")
    },
    Item.TOMATO_SOUP: {
        "name": "Tomato Soup",
        "texture": preload("res://items/tomato_soup.png")
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