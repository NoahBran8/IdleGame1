extends RefCounted

# Deterministic rotation: no clocks, random rewards or expiry dates.
static func make_offer(config: GardenConfig, uid: int, player_level: int, excluded: Array) -> Dictionary:
	var eligible: Array[String] = []
	for id: String in config.requests:
		if int(config.requests[id].level_required) <= player_level and not id in excluded:
			eligible.append(id)
	if eligible.is_empty():
		return {}
	return {"uid": uid, "template_id": eligible[(uid - 1) % eligible.size()]}

static func reward(template: Dictionary, sell_values: Dictionary) -> int:
	var coins: int = int(template.bonus_coins)
	for species: String in template.items:
		coins += int(template.items[species]) * int(sell_values[species])
	return coins
