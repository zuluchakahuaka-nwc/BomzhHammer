extends SceneTree
func _init():
    var f = FileAccess.open("res://data/cards/situations.json", FileAccess.READ)
    var json = JSON.new()
    json.parse(f.get_as_text())
    f.close()
    var effects = {}
    for c in json.get_data():
        var et = c.get("effect_type", "NONE")
        if not effects.has(et):
            effects[et] = []
        effects[et].append(c.get("id", ""))
    for et in effects:
        print("%s (%d): %s" % [et, effects[et].size(), str(effects[et])])
    quit()
