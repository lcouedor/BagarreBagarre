extends Node3D

var isPlaying = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_simulation_play_state_changed(state):
	var all_fighters = get_children()
	for i in range(0, all_fighters.size()):
		#Si le fighter existe, qu'il n'a pas été détruit
		if all_fighters[i].is_in_group("fighter"):
			all_fighters[i].isPlaying = state
