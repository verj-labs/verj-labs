extends TestCase


func test_small_numbers_read_plainly() -> void:
	eq(Num.fmt(0), "0")
	eq(Num.fmt(950), "950")
	eq(Num.fmt(6.5), "6.5", "a fraction under 100 keeps one decimal")
	eq(Num.fmt(12.0), "12")


func test_suffixes() -> void:
	eq(Num.fmt(1250), "1.25K")
	eq(Num.fmt(12_500), "12.5K")
	eq(Num.fmt(125_000), "125K")
	eq(Num.fmt(1_250_000), "1.25M")
	eq(Num.fmt(2.5e15), "2.50Q")
	eq(Num.fmt(2.5e18), "2.50aa", "after Q come letter pairs")
	eq(Num.fmt(2.5e21), "2.50ab")


func test_digits_are_cut_not_rounded_up() -> void:
	eq(Num.fmt(999_999), "999K")
	eq(Num.fmt(1_000_000), "1.00M")
	eq(Num.fmt(1999), "1.99K")


func test_cash_and_prices_are_whole_dollars() -> void:
	eq(Num.cash(19.7), "$19")
	eq(Num.price(19.2), "$20", "prices round up so the button never undersells")
	eq(Num.cash(1500), "$1.50K")


func test_durations() -> void:
	eq(Num.duration(9), "9S")
	eq(Num.duration(250), "4M 10S")
	eq(Num.duration(3900), "1H 05M")
	eq(Num.duration(90000), "1D 01H")
	eq(Num.duration(-5), "0S")
