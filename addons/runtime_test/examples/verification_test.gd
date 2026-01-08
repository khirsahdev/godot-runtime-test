extends Node3D
class_name VerificationTest
## Test script for verifying RuntimeTest catches false positives
## Tests: type mismatches, invalid enums, wrong signal arg counts

enum Status { OK, WARNING, ERROR, CRITICAL }

signal status_changed(new_status: Status)
signal health_updated(old_val: int, new_val: int) # 2 args required
signal simple_ping() # 0 args required

@export var status: Status = Status.OK
@export var health: int = 100:
	set(v):
		var old = health
		health = clampi(v, 0, 200)
		if old != health:
			health_updated.emit(old, health)
			print("[VerificationTest] health: %d -> %d" % [old, health])

@export var name_tag: String = "default"
@export var is_active: bool = true

var internal_counter: int = 0


func _ready() -> void:
	status_changed.connect(_on_status_changed)
	health_updated.connect(_on_health_updated)
	simple_ping.connect(_on_simple_ping)
	print("[VerificationTest] Ready - status: %s, health: %d" % [Status.keys()[status], health])


func increment_counter() -> void: ## Simple method with no args
	internal_counter += 1
	print("[VerificationTest] Counter: %d" % internal_counter)


func set_status_checked(new_status: Status) -> void: ## Method with enum arg
	if new_status == status:
		return
	var old = status
	status = new_status
	status_changed.emit(new_status)
	print("[VerificationTest] status: %s -> %s" % [Status.keys()[old], Status.keys()[new_status]])


func method_with_args(a: int, b: String) -> void: ## Method requiring 2 args
	print("[VerificationTest] method_with_args(%d, '%s')" % [a, b])


func get_health() -> int: ## Method with return value
	return health


func _on_status_changed(new_status: Status) -> void:
	print("[VerificationTest] Signal: status_changed(%s)" % Status.keys()[new_status])


func _on_health_updated(old_val: int, new_val: int) -> void:
	print("[VerificationTest] Signal: health_updated(%d, %d)" % [old_val, new_val])


func _on_simple_ping() -> void:
	print("[VerificationTest] Signal: simple_ping()")
