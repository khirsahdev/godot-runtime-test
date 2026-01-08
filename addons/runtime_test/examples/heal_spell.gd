extends Node
class_name HealSpell
## Spell component that heals when parent requests healing
##
## Connects to parent's heal_requested signal and applies healing

@export var heal_amount: int = 30

var _parent: Node


func _ready() -> void:
	_parent = get_parent()
	if _parent and _parent.has_signal("heal_requested"):
		_parent.heal_requested.connect(_on_heal_requested)
		print("[HealSpell] Ready - connected to %s (heal amount: %d)" % [_parent.name, heal_amount])
	else:
		push_warning("[HealSpell] Parent doesn't have heal_requested signal!")


func _on_heal_requested(target: Node) -> void:
	print("[HealSpell] Heal requested! Casting heal on %s..." % target.name)
	if target.has_method("receive_heal"):
		target.receive_heal(heal_amount)
		print("[HealSpell] Heal complete!")
