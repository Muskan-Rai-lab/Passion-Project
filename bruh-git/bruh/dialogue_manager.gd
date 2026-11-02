extends Node

signal dialogue_requested(lines: Array)

var dialogues := {
	"door_locked": ["It's locked.", "Maybe there's a key nearby."],
	"piles": ["laaa vatkya raixa"],
	"bowl": ["Found a bowl." ,"Now I need to fill it up with rice"],
	"workshop-key": ["Found workshop key" , "I need to go to the workshop now"],
	"gloves": ["Found rubber gloves!"," Now I can touch the electric box."],
	"toolbox-key": ["Found toolbox key!", "I need to find the tool-box now"],
	"closet-key": ["Found closet key!", "I need to go to my bedroom."],
	"diyo": ["Diyo?", "Maybe I need to fill it up with oil","I need to search for Ajee's Theki."],
	"match": ["Matches?", "I need to return it to the pooja room."],
	"shock": ["Athaa machikney", "I need gloves!"],
	"switch": ["Yes!", "I can fix the electric box now."],
	"screwdriver": ["Hmmm, this might be useful"],
	"tape": ["I can fix the wires with this"],
	"pooja": ["I can scare it away!", "but..","I need more items for pooja"],
	"wall-box": ["Theres something behind this.", "I need a screwdriver!."],
	"closet": ["Theres something behind this.", "I need a closet-key to unlock it."],
	"electric-box": ["If I repair this..", "It might get scared of the light!", "I need materials!"],
	"toolbox": ["Its locked!", "I need a toolbox key!"],
	"full": ["Inventory is full"],
	
}

func say(id: String) -> void:
	if dialogues.has(id):
		dialogue_requested.emit(dialogues[id])
	else:
		push_warning("No dialogue with id: " + id)
