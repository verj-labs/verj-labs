class_name MediumBot
extends Bot
## Sensible but beatable:
## - goes out whenever it can;
## - leads with its lowest set (the whole group) to shed cards early;
## - follows with the cheapest legal play, avoiding breaking up pairs/triples;
## - keeps 2s for when they matter: a high pile, a short hand, or an opponent about to go out;
## - does not waste Kings and Aces on low piles unless an opponent is close to going out.

const BREAKS_A_SET_PENALTY := 3.5
const WORTH_RESETTING_FROM := Card.QUEEN
const SHORT_HAND := 3
const SAVE_HIGH_CARDS_FROM := Card.KING


func choose(view: PlayerView) -> Play:
	if view.legal_plays.is_empty():
		return null
	for candidate in view.legal_plays:
		if candidate.size == view.hand.size():
			return candidate
	if view.pile == null:
		return _lead(view)
	return _follow(view)


func _lead(view: PlayerView) -> Play:
	var ordinary := view.legal_plays.filter(func(p: Play) -> bool: return not p.is_two())
	var pool: Array = ordinary if not ordinary.is_empty() else view.legal_plays
	var best: Play = null
	for candidate: Play in pool:
		if best == null or _lead_is_better(candidate, best):
			best = candidate
	return best


## Lower rank first; within a rank, the bigger set (sheds more cards).
func _lead_is_better(a: Play, b: Play) -> bool:
	if a.strength() != b.strength():
		return a.strength() < b.strength()
	return a.size > b.size


func _follow(view: PlayerView) -> Play:
	var danger := view.opponent_close_to_out()
	var best: Play = null
	var best_cost := INF
	for candidate in view.legal_plays:
		if candidate.is_two():
			continue
		var cost := _cost(view, candidate)
		if cost < best_cost:
			best = candidate
			best_cost = cost
	if best != null:
		var wasteful := best.strength() >= SAVE_HIGH_CARDS_FROM and view.pile.strength() < Card.JACK
		if wasteful and not danger and view.can_pass:
			return null
		return best
	return _maybe_reset(view, danger)


func _cost(view: PlayerView, candidate: Play) -> float:
	var in_hand := 0
	for card in view.hand:
		if card.rank == candidate.rank:
			in_hand += 1
	var cost := float(candidate.strength())
	if in_hand > candidate.size:
		cost += BREAKS_A_SET_PENALTY
	return cost


func _maybe_reset(view: PlayerView, danger: bool) -> Play:
	var worth_it := (
		danger or view.hand.size() <= SHORT_HAND or view.pile.strength() >= WORTH_RESETTING_FROM
	)
	if not worth_it:
		return null
	for candidate in view.legal_plays:
		if candidate.is_two():
			return candidate
	return null
