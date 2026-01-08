extends Node3D
class_name TestTarget
## Example script demonstrating Runtime Test capabilities
##
## Run these commands to test:
##   godot --path . --headless addons/runtime_test/examples/test_target.tscn -- --print:.:state --print:.:health
##   godot --path . --headless addons/runtime_test/examples/test_target.tscn -- --set:.:health=50 --call:.:transition_to:ATTACKING
##   godot --path . addons/runtime_test/examples/test_target.tscn -- --watch --watchprop:.:state --emit:.:state_changed:DEAD

enum State { IDLE, MOVING, ATTACKING, DEAD }

signal state_changed(new_state: State)
signal health_changed(old_value: int, new_value: int)

@export var health: int = 100:
	set(value):
		var old = health
		health = clampi(value, 0, max_health)
		if old != health:
			health_changed.emit(old, health)
			print("[TestTarget] Health: %d -> %d" % [old, health])

@export var max_health: int = 100
@export var speed: float = 5.0
@export var is_invulnerable: bool = false

var state: State = State.IDLE


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	health_changed.connect(_on_health_changed)
	print("[TestTarget] Ready - state: %s, health: %d" % [State.keys()[state], health])


func transition_to(new_state: State) -> void: ## Change state (testable via --call:.:transition_to:ATTACKING)
	if state == new_state:
		return
	var old_state = state
	state = new_state
	state_changed.emit(new_state)
	print("[TestTarget] State: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])


func take_damage(amount: int) -> void: ## Apply damage (testable via --call:.:take_damage:25)
	if is_invulnerable:
		print("[TestTarget] Damage blocked - invulnerable")
		return
	health -= amount
	if health <= 0:
		transition_to(State.DEAD)


func heal(amount: int) -> void: ## Heal (testable via --call:.:heal:50)
	health = mini(health + amount, max_health)


func reset() -> void: ## Reset to initial state
	health = max_health
	is_invulnerable = false
	transition_to(State.IDLE)


func _on_state_changed(new_state: State) -> void:
	print("[TestTarget] Signal received: state_changed(%s)" % State.keys()[new_state])


func _on_health_changed(old_value: int, new_value: int) -> void:
	print("[TestTarget] Signal received: health_changed(%d, %d)" % [old_value, new_value])
