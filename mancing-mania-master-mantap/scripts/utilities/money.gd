class_name Money
extends RefCounted
## Rupiah formatting used by every player-visible amount ("Rp 1,800,000").


static func format_rp(amount: int) -> String:
	return "Rp %s" % group_thousands(amount)


static func group_thousands(amount: int) -> String:
	var digits := str(absi(amount))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.substr(digits.length() - 3) + grouped
		digits = digits.substr(0, digits.length() - 3)
	grouped = digits + grouped
	return ("-" + grouped) if amount < 0 else grouped
