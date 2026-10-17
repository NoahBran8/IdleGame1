extends RefCounted

# Property milestones share one persistent set of beds; visiting never resets crops.
const ORDER: Array[String] = ["cottage","market","lakeside"]
const DATA: Dictionary = {
	"cottage":{"name":"Cottage Garden","short":"Cottage","plots":4,"description":"A sheltered kitchen garden beside your cottage."},
	"market":{"name":"Market Courtyard","short":"Market","plots":9,"description":"A stone courtyard and market frontage for a growing business."},
	"lakeside":{"name":"Lakeside Garden","short":"Lakeside","plots":16,"description":"A waterside retreat with a new bed arrangement and stone walks."}
}

static func unlocked(id: String, count: int) -> bool:
	return DATA.has(id) and count >= int(DATA[id].plots)

static func milestone(count: int) -> String:
	for id: String in ORDER:
		if id != "cottage" and count == int(DATA[id].plots):
			return id
	return ""

static func next_area(count: int) -> String:
	for id: String in ORDER:
		if count < int(DATA[id].plots):
			return id
	return ""
