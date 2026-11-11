class_name ContentIds
extends RefCounted
## The v1.0 content manifest as stable IDs (GDD Section 165).
## These lists are closed: adding or removing an entry is a GDD revision.

const FISH_IDS: Array[StringName] = [
	&"catfish_bruiser",
	&"tilapia_gym_rat",
	&"gourami_shady",
	&"carp_golden",
	&"snakehead_sergeant",
	&"arowana_don",
]

const TRASH_IDS: Array[StringName] = [
	&"trash_sandal",
	&"trash_can",
	&"trash_tyre",
]

const UPGRADE_IDS: Array[StringName] = [
	&"bait",
	&"rod",
	&"tonic",
	&"coffee",
	&"charm",
]

## Order doubles as the favourite-duel tiebreak order (GDD 171.5).
const DUEL_IDS: Array[StringName] = [
	&"boxing",
	&"arm_wrestle",
	&"dance",
	&"suwit",
]

const STORY_EVENT_IDS: Array[StringName] = [
	&"story_prologue_zero",
	&"story_first_fish",
	&"story_first_market",
	&"story_debt_100k",
	&"story_debt_300k",
	&"story_debt_600k",
	&"story_debt_1000k",
	&"story_debt_1400k",
	&"story_debt_1650k",
	&"story_debt_paid",
	&"story_arowana_first_win",
	&"story_final_family",
	&"story_postgame_unlock",
]

const CHAPTER_IDS: Array[StringName] = [
	&"prologue",
	&"chapter_1",
	&"chapter_2",
	&"chapter_3",
	&"chapter_4",
	&"chapter_5",
	&"chapter_6",
	&"finale",
	&"epilogue",
]

const TUTORIAL_IDS: Array[StringName] = [
	&"fishing_seen",
	&"reeling_seen",
	&"wheel_seen",
	&"boxing_seen",
	&"arm_wrestle_seen",
	&"dance_seen",
	&"suwit_seen",
	&"market_seen",
	&"debt_seen",
]

const DEBT_ORIGINAL: int = 1_800_000
const STARTING_CASH: int = 8_430
const UPGRADE_MAX_LEVEL: int = 3


static func get_bucket_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append_array(FISH_IDS)
	ids.append_array(TRASH_IDS)
	return ids
