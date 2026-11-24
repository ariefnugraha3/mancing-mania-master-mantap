class_name Money
extends RefCounted
## Rupiah and number formatting used by every player-visible amount, in the
## player's language: English writes "Rp 2,000,000" and "2.92 kg",
## Indonesian writes "Rp 2.000.000" and "2,92 kg".


static func format_rp(amount: int) -> String:
	return "Rp %s" % group_thousands(amount)


static func group_thousands(amount: int) -> String:
	var separator := "." if TextDb.get_language() == TextDb.INDONESIAN else ","
	var digits := str(absi(amount))
	var grouped := ""
	while digits.length() > 3:
		grouped = separator + digits.substr(digits.length() - 3) + grouped
		digits = digits.substr(0, digits.length() - 3)
	grouped = digits + grouped
	return ("-" + grouped) if amount < 0 else grouped


## A number with `digits` decimals and the language's decimal mark.
static func decimal(value: float, digits: int = 2) -> String:
	var text := ("%." + str(digits) + "f") % value
	return text.replace(".", ",") if TextDb.get_language() == TextDb.INDONESIAN else text
