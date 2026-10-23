class_name BotFactory
extends RefCounted


static func create(difficulty: int, rng: RandomNumberGenerator) -> Bot:
	match difficulty:
		Bot.Difficulty.EASY:
			return EasyBot.new(rng)
		_:
			return MediumBot.new()


static func difficulty_name(difficulty: int) -> String:
	return "Easy" if difficulty == Bot.Difficulty.EASY else "Medium"
