class_name DamageEvent

var damage: float = 0.0
var knockback: float = 0.0

# TODO make better damage event builders
static func create(damage_: float) -> DamageEvent:
	var dmg: DamageEvent = DamageEvent.new()
	dmg.damage = damage_
	return dmg

# TODO knockback systems
func kb(amount: float) -> DamageEvent:
	knockback = amount
	return self

func to_array() -> Array[float]:
	var arr: Array[float] = []
	arr.resize(2)
	arr[0] = damage
	arr[1] = knockback
	return arr

static func from_array(arr: Array[float]) -> DamageEvent:
	var hurt: DamageEvent = DamageEvent.new()
	hurt.damage = arr[0]
	hurt.knockback = arr[1]
	return hurt
