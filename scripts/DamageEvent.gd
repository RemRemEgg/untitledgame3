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
