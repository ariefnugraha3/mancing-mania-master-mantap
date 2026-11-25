class_name ContentIds
extends RefCounted
## The content manifest as stable IDs (GDD Section 165, revision 6.7).
## These lists are closed: adding or removing an entry is a GDD revision.

## The five fishing spots, from the first to the last (revision 6.7). Each has
## its own fish, its own duel and, after the first, an access item bought at
## Bu Yati's warung.
const LOCATION_IDS: Array[StringName] = [
	&"cempaka",
	&"kenanga",
	&"melati",
	&"anggrek",
	&"mawar",
]
const START_LOCATION: StringName = &"cempaka"

## The fish of each spot, common to rare; the last of each is its legend.
const LOCATION_FISH: Dictionary[StringName, Array] = {
	&"cempaka": [&"catfish_bruiser", &"tilapia_gym_rat", &"gourami_shady", &"carp_golden", &"snakehead_sergeant", &"arowana_don"],
	&"kenanga": [&"baung_satpam", &"tawes_gosip", &"belut_licin", &"hampala_pembalap", &"belida_pendekar"],
	&"melati": [&"red_devil_palak", &"patin_stempel", &"jelawat_influencer", &"betutu_mager", &"toman_jenderal"],
	&"anggrek": [&"bandeng_tanpa_duri", &"buntal_pemarah", &"glodok_pelari", &"kakap_sosialita", &"sembilang_tua"],
	&"mawar": [&"tongkol_ojol", &"layur_penyair", &"barakuda_rentenir", &"kerapu_juragan", &"layaran_kapten"],
}

const FISH_IDS: Array[StringName] = [
	&"catfish_bruiser",
	&"tilapia_gym_rat",
	&"gourami_shady",
	&"carp_golden",
	&"snakehead_sergeant",
	&"arowana_don",
	&"baung_satpam",
	&"tawes_gosip",
	&"belut_licin",
	&"hampala_pembalap",
	&"belida_pendekar",
	&"red_devil_palak",
	&"patin_stempel",
	&"jelawat_influencer",
	&"betutu_mager",
	&"toman_jenderal",
	&"bandeng_tanpa_duri",
	&"buntal_pemarah",
	&"glodok_pelari",
	&"kakap_sosialita",
	&"sembilang_tua",
	&"tongkol_ojol",
	&"layur_penyair",
	&"barakuda_rentenir",
	&"kerapu_juragan",
	&"layaran_kapten",
]

## The legend of each spot: rare, worth a premium, fought at boss strength.
const LEGEND_FISH_IDS: Array[StringName] = [
	&"arowana_don", &"belida_pendekar", &"toman_jenderal", &"sembilang_tua", &"layaran_kapten",
]

const TRASH_IDS: Array[StringName] = [
	&"trash_sandal",
	&"trash_can",
	&"trash_tyre",
]

## Big Bucket comes first on the Market's UPGRADES page: the bucket is the
## first limit a new player meets (revision 6.12).
const UPGRADE_IDS: Array[StringName] = [
	&"bucket",
	&"bait",
	&"rod",
	&"tonic",
	&"coffee",
	&"charm",
]

## Order doubles as the favourite-duel tiebreak order (GDD 171.5). The last
## four are the signature duels of the new spots (revision 6.7).
const DUEL_IDS: Array[StringName] = [
	&"boxing",
	&"arm_wrestle",
	&"dance",
	&"suwit",
	&"silat",
	&"tambang",
	&"gasing",
	&"pinang",
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
	&"story_unlock_kenanga",
	&"story_unlock_melati",
	&"story_unlock_anggrek",
	&"story_unlock_mawar",
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
	&"silat_seen",
	&"tambang_seen",
	&"gasing_seen",
	&"pinang_seen",
	&"travel_seen",
]

const DEBT_ORIGINAL: int = 2_000_000
## The starting debt before revision 6.12. A save that cleared it stays
## cleared; a save still paying keeps what it paid and owes the new total.
const LEGACY_DEBT_ORIGINAL: int = 1_800_000
const STARTING_CASH: int = 10_000
const UPGRADE_MAX_LEVEL: int = 3
## Upgrade levels 2 and 3 require paying debt first, so cash cannot bypass the
## main goal forever.
const UPGRADE_DEBT_GATES: Dictionary[int, int] = {
	2: 100_000,
	3: 350_000,
}
## Consecutive Warung sales without a debt payment trigger CepatCash pressure:
## at 2 sales the collector harasses Darto at the water (slower bites); at 3+
## sales the collector also deducts a reminder fee from each sale until Darto
## pays at least DEBT_MIN_RELIEF_PAYMENT (or clears the debt).
const DEBT_HARASS_AFTER_SALES: int = 2
const DEBT_FEE_AFTER_SALES: int = 3
const DEBT_REMINDER_FEE: int = 10_000
const DEBT_MIN_RELIEF_PAYMENT: int = 10_000
const DEBT_HARASS_WAIT_MULTIPLIER: float = 1.45
## Legends are tier 5. A tier-5 fish attacks on a shorter cooldown and asks
## for a rematch at arm wrestling (GDD Section 49).
const BOSS_TIER: int = 5
## Don Arowana: the legend of the first spot, with his own story beat.
const BOSS_FISH_ID: StringName = &"arowana_don"


static func upgrade_required_debt_paid(target_level: int) -> int:
	return int(UPGRADE_DEBT_GATES.get(target_level, 0))


static func get_bucket_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append_array(FISH_IDS)
	ids.append_array(TRASH_IDS)
	return ids


## The spot a fish lives in, or &"" for an unknown fish.
static func location_of_fish(fish_id: StringName) -> StringName:
	for location_id: StringName in LOCATION_FISH:
		if (LOCATION_FISH[location_id] as Array).has(fish_id):
			return location_id
	return &""


static func fish_of_location(location_id: StringName) -> Array[StringName]:
	var fish: Array[StringName] = []
	for fish_id: Variant in LOCATION_FISH.get(location_id, []):
		fish.append(StringName(fish_id))
	return fish
