class_name MarketDebtPanel
extends MarketPanel
## DEBT LEDGER page (GDD 79): original, paid and remaining, a progress bar and
## the payment buttons. There is no interest, no fee and no deadline, and the
## page says so.
##
## A button is disabled when the cash on hand cannot cover it. Whatever is
## asked for, MarketController never pays more than the cash or the debt left.

signal payment_requested(amount: int)

const PRESET_AMOUNTS: Array[int] = [25000, 50000, 100000]
## The first payment taught by the Market tutorial (GDD 183.5).
const TUTORIAL_AMOUNT := 10000
const CUSTOM_STEPS: Dictionary[StringName, int] = {
	&"market.debt.step_minus_10k": -10000,
	&"market.debt.step_minus_1k": -1000,
	&"market.debt.step_plus_1k": 1000,
	&"market.debt.step_plus_10k": 10000,
}
const ACTION_FONT_SIZE := 18
const STEP_BUTTON_WIDTH := 62.0

var _original_label: Label
var _paid_label: Label
var _remaining_label: Label
var _progress: ProgressBar
var _note_label: Label
var _available_label: Label
var _tutorial_button: GameButton
var _preset_buttons: Dictionary[int, GameButton] = {}
var _custom_button: GameButton
var _all_button: GameButton
var _custom_box: HBoxContainer
var _custom_confirm: GameButton
var _step_buttons: Dictionary[int, GameButton] = {}
var _custom_amount: int = 0
var _tutorial_offer: bool = false


func build() -> void:
	set_heading(TextDb.t(&"market.debt.title"))

	_original_label = add_value_row(body, TextDb.t(&"market.debt.original"))
	_paid_label = add_value_row(body, TextDb.t(&"market.debt.paid"))
	body.add_child(make_rule())
	_remaining_label = add_value_row(body, TextDb.t(&"market.debt.remaining"), UiTokens.TYPE_HEADER)

	_progress = ProgressBar.new()
	_progress.name = "DebtProgress"
	_progress.custom_minimum_size.y = 24.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_progress)
	_note_label = make_label("", UiTokens.TYPE_SMALL)
	body.add_child(_note_label)

	_available_label = make_label("", UiTokens.TYPE_SMALL)
	actions.add_child(_available_label)

	_tutorial_button = _action_button(TextDb.tf(&"market.debt.pay_amount", {"amount": Money.format_rp(TUTORIAL_AMOUNT)}), UiTokens.TYPE_CTA_BUTTON)
	_tutorial_button.name = "TutorialPayButton"
	_tutorial_button.pressed.connect(func() -> void: payment_requested.emit(TUTORIAL_AMOUNT))
	actions.add_child(_tutorial_button)

	var presets := HBoxContainer.new()
	presets.name = "Presets"
	presets.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	actions.add_child(presets)
	for amount: int in PRESET_AMOUNTS:
		var button := _action_button(TextDb.tf(&"market.debt.pay_amount", {"amount": Money.group_thousands(amount)}))
		button.name = "Pay%d" % amount
		button.pressed.connect(func() -> void: payment_requested.emit(amount))
		presets.add_child(button)
		_preset_buttons[amount] = button

	var extras := HBoxContainer.new()
	extras.name = "Extras"
	extras.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	actions.add_child(extras)
	_custom_button = _action_button(TextDb.t(&"market.debt.pay_custom"))
	_custom_button.name = "PayCustomButton"
	_custom_button.pressed.connect(_toggle_custom)
	extras.add_child(_custom_button)
	_all_button = _action_button(TextDb.t(&"market.debt.pay_all"), UiTokens.TYPE_CTA_BUTTON)
	_all_button.name = "PayAllButton"
	_all_button.size_flags_stretch_ratio = 1.5
	_all_button.pressed.connect(func() -> void: payment_requested.emit(_max_payment()))
	extras.add_child(_all_button)

	# PAY CUSTOM: step the amount down or up around the button that pays it.
	_custom_box = HBoxContainer.new()
	_custom_box.name = "Custom"
	_custom_box.visible = false
	_custom_box.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	actions.add_child(_custom_box)
	_custom_confirm = _action_button("", UiTokens.TYPE_CTA_BUTTON)
	_custom_confirm.name = "PayCustomConfirm"
	_custom_confirm.pressed.connect(func() -> void: payment_requested.emit(_custom_amount))
	for text_key: StringName in CUSTOM_STEPS:
		var step: int = CUSTOM_STEPS[text_key]
		if step > 0 and _custom_confirm.get_parent() == null:
			_custom_box.add_child(_custom_confirm)
		var button := _action_button(TextDb.t(text_key))
		button.name = "Step%d" % step
		button.size_flags_horizontal = Control.SIZE_FILL
		button.custom_minimum_size.x = STEP_BUTTON_WIDTH
		make_compact(button)
		button.pressed.connect(_step_custom.bind(step))
		_custom_box.add_child(button)
		_step_buttons[step] = button
	make_compact(_custom_confirm)


func refresh() -> void:
	var original := GameState.get_debt_original()
	var paid := GameState.get_debt_paid()
	var remaining := GameState.get_debt_remaining()
	var cash := GameState.get_cash()
	var available := _max_payment()
	var cleared := remaining <= 0

	_original_label.text = Money.format_rp(original)
	_paid_label.text = Money.format_rp(paid)
	_remaining_label.text = Money.format_rp(remaining)
	_progress.max_value = float(maxi(original, 1))
	_progress.value = float(paid)
	_note_label.text = TextDb.t(&"market.debt.cleared" if cleared else &"market.debt.terms")

	actions.visible = not cleared
	_available_label.text = TextDb.tf(&"market.debt.available", {"amount": Money.format_rp(available)})
	_tutorial_button.visible = _tutorial_offer and available >= TUTORIAL_AMOUNT
	for amount: int in _preset_buttons:
		# Enough cash for the amount, or enough to finish a smaller remainder.
		_preset_buttons[amount].disabled = cash < mini(amount, remaining) or available <= 0
	_all_button.disabled = available <= 0
	_custom_button.disabled = available <= 0
	if available <= 0:
		_custom_box.visible = false

	_custom_amount = clampi(_custom_amount, 0, available)
	_custom_confirm.text = TextDb.tf(&"market.debt.pay_amount", {"amount": Money.format_rp(_custom_amount)})
	_custom_confirm.disabled = _custom_amount <= 0
	for step: int in _step_buttons:
		var stepped := clampi(_custom_amount + step, 0, available)
		_step_buttons[step].disabled = stepped == _custom_amount


## During the first visit the page offers the small tutorial payment.
func set_tutorial_offer(offered: bool) -> void:
	_tutorial_offer = offered
	if is_node_ready():
		refresh()


func get_custom_amount() -> int:
	return _custom_amount


func get_pay_button(amount: int) -> GameButton:
	if amount == TUTORIAL_AMOUNT:
		return _tutorial_button
	return _preset_buttons.get(amount)


func get_pay_all_button() -> GameButton:
	return _all_button


func _max_payment() -> int:
	return mini(GameState.get_cash(), GameState.get_debt_remaining())


func _toggle_custom() -> void:
	_custom_box.visible = not _custom_box.visible
	if _custom_box.visible and _custom_amount <= 0:
		# Start from a sensible amount instead of zero.
		_custom_amount = mini(TUTORIAL_AMOUNT, _max_payment())
	refresh()


func _step_custom(step: int) -> void:
	_custom_amount = clampi(_custom_amount + step, 0, _max_payment())
	refresh()


func _action_button(text: String, type_variation: StringName = &"") -> GameButton:
	var button := make_button(text, type_variation)
	# This page has many buttons; the smaller touch height keeps the ledger
	# rows above them in view.
	button.min_height = UiTokens.TOUCH_TARGET_MIN
	button.add_theme_font_size_override(&"font_size", ACTION_FONT_SIZE)
	button.clip_text = true
	return button
