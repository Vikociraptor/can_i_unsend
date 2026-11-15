extends Node

#Number of minigames per round
const MODES := {
	"easy": 1,
	"medium": 2,
	"hard": 3,
}

var minigame_count := 2 #default for isolated scene testing
