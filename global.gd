extends Node

var rng

func _ready():
    rng = RandomNumberGenerator.new()
    # rng.seed = 809320074667773066
    # rng.state = 2257944420018308052

    rng.randomize()
    print("seed: ", rng.seed)
    print("state: ", rng.state)

func calculate_damage(attacker, _defender):
    var hit_value = rng.randf_range(0, 1)
    if hit_value <= 0.05:
        return {
            "value": -1,
            "is_crit": false
        }
    else:
        var crit_bonus = 0
        var is_crit = hit_value >= 0.95
        if is_crit:
            crit_bonus = rng.randi_range(attacker.attack, 2 * attacker.attack)
        return {
            "value": int(max(1, rng.randi_range(attacker.attack, 2 * attacker.attack)) + crit_bonus),
            "is_crit": is_crit
        }
