extends Node
class_name Character
## Multi-node example: Character with HealSpell child component
##
## Test flow - damage then heal via signal:
##   godot --path . --headless addons/runtime_test/examples/multi_node.tscn -- \
##     --print:.:health \
##     --call:.:take_damage:50 \
##     --print:.:health \
##     --call:.:request_heal \
##     --print:.:health

signal heal_requested(target: Node)

@export var health: int = 100:
	set(value):
		var old = health
		health = clampi(value, 0, max_health)
		if old != health:
			print("[Character] Health: %d -> %d" % [old, health])

@export var max_health: int = 100


func _ready() -> void:
	print("[Character] Ready - health: %d/%d" % [health, max_health])


func take_damage(amount: int) -> void:
	print("[Character] Taking %d damage" % amount)
	health -= amount
	if health <= 0:
		print("[Character] Defeated!")


func request_heal() -> void:
	print("[Character] Requesting heal...")
	heal_requested.emit(self)


func receive_heal(amount: int) -> void:
	var old = health
	health = mini(health + amount, max_health)
	print("[Character] Healed for %d (now %d/%d)" % [amount, health, max_health])
