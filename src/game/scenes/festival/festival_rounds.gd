class_name FestivalRounds
extends RefCounted

## Pure round builder for the zone festival («Прочитай и найди»).
## One round per animal of the zone (shuffled). Distractors come from this zone and all earlier zones
## (all already collected). With 4+ cards, animals sharing the target's first letter are preferred,
## so the child has to read the whole word, not guess by the first letter.


## Returns [{ "target": LevelData, "cards": Array[LevelData] }, ...].
static func build(zone: ZoneData, catalog: LevelsCatalog, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := _pool(zone, catalog)
	var order := zone.levels.duplicate()
	_shuffle(order, rng)
	var rounds: Array[Dictionary] = []
	for target in order:
		rounds.append({"target": target, "cards": _cards_for(target, pool, zone.festival_cards, rng)})
	return rounds


## 3 if at most 1 mistake, 2 if at most 3, otherwise 1 (stars never block progress).
static func stars_for(mistakes: int) -> int:
	if mistakes <= 1:
		return 3
	return 2 if mistakes <= 3 else 1


static func _pool(zone: ZoneData, catalog: LevelsCatalog) -> Array[LevelData]:
	var pool: Array[LevelData] = []
	for z in catalog.get_zones():
		pool.append_array(z.levels)
		if z == zone:
			break
	return pool


static func _cards_for(target: LevelData, pool: Array[LevelData], count: int, rng: RandomNumberGenerator) -> Array[LevelData]:
	var same_letter: Array[LevelData] = []
	var others: Array[LevelData] = []
	for level in pool:
		if level == target or _looks_same(level, target):
			continue
		if level.word.left(1) == target.word.left(1):
			same_letter.append(level)
		else:
			others.append(level)
	_shuffle(same_letter, rng)
	_shuffle(others, rng)
	var picks: Array[LevelData] = []
	if count >= 4:
		picks.append_array(same_letter)
	picks.append_array(others)
	if count < 4:
		picks.append_array(same_letter)
	var cards: Array[LevelData] = [target]
	for level in picks:
		if cards.size() >= count:
			break
		if not cards.any(func(c: LevelData): return _looks_same(c, level)):
			cards.append(level)
	_shuffle(cards, rng)
	return cards


## Two cards are indistinguishable when neither has a photo and they share the placeholder emoji.
static func _looks_same(a: LevelData, b: LevelData) -> bool:
	if a.animal_texture or b.animal_texture:
		return a.animal_texture == b.animal_texture
	return a.emoji == b.emoji


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
