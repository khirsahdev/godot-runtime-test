extends Node
## Runtime Test v2 - CLI Testing Framework for Godot
## Inject state, observe behavior, assert expectations - all from command line.
##
## INJECTION:
##   --set:Path:prop=value       Set a property
##   --call:Path:method:args     Call a method
##   --emit:Path:signal:args     Emit a signal (outbound)
##
## OBSERVATION:
##   --print:Path:prop           Print property value once
##   --watchprop:Path:prop       Watch property and print on change
##   --listen:Path:signal        Capture signal emissions (inbound)
##
## ASSERTION:
##   --expect:Path:prop=value    Assert property equals value
##   --expect-signal:Path:sig    Assert signal was emitted
##   --expect-signal:Path:sig:args  Assert signal with specific params
##   --expect-no-signal:Path:sig Assert signal was NOT emitted
##
## CONTROL:
##   --wait:ms                   Wait milliseconds before next command
##   --wait-frames:N             Wait N frames before next command
##   --watch                     Keep running until 'Q' pressed
##
## Example:
##   godot --path . scene.tscn -- --listen:.:died --set:.:health=0 --wait:100 --expect-signal:.:died

# Counters
var ok_count: int = 0
var err_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

# Signal capture storage: {"path:signal_name": [emission1_args, emission2_args, ...]}
var captured_signals: Dictionary = {}

# Listeners to setup before commands run
var queued_listens: Array[Dictionary] = []

# Sequential command queue - preserves CLI order
var command_queue: Array[Dictionary] = []

# Watch mode and property watchers
var watch_mode: bool = false
var watch_properties: Array[Dictionary] = []

var scene_root: Node = null


func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	if args.is_empty():
		set_process(false)
		return

	print("[RT:RESULTS] Parsing %d args" % args.size())

	for arg in args:
		if arg.begins_with("--set:"):
			_parse_set(arg.substr(6))
		elif arg.begins_with("--call:"):
			_parse_call(arg.substr(7))
		elif arg.begins_with("--print:"):
			_parse_print(arg.substr(8))
		elif arg.begins_with("--emit:"):
			_parse_emit(arg.substr(7))
		elif arg.begins_with("--watchprop:"):
			_parse_watchprop(arg.substr(12))
		elif arg.begins_with("--listen:"):
			_parse_listen(arg.substr(9))
		elif arg.begins_with("--expect-signal:"):
			_parse_expect_signal(arg.substr(16))
		elif arg.begins_with("--expect-no-signal:"):
			_parse_expect_no_signal(arg.substr(19))
		elif arg.begins_with("--expect:"):
			_parse_expect(arg.substr(9))
		elif arg.begins_with("--wait-frames:"):
			_parse_wait_frames(arg.substr(14))
		elif arg.begins_with("--wait:"):
			_parse_wait(arg.substr(7))
		elif arg == "--watch":
			watch_mode = true

	if command_queue.is_empty() and queued_listens.is_empty() and watch_properties.is_empty() and not watch_mode:
		set_process(false)
		return

	call_deferred("_execute")


#region PARSING

func _parse_set(spec: String) -> void:
	var eq_pos = spec.rfind("=")
	if eq_pos < 0:
		print("[RT:ERR] Invalid set syntax: %s (missing =)" % spec)
		err_count += 1
		return

	var path_prop = spec.substr(0, eq_pos)
	var value_str = spec.substr(eq_pos + 1)
	var colon_pos = path_prop.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid set syntax: %s (missing node:prop)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "set",
		"path": path_prop.substr(0, colon_pos),
		"prop": path_prop.substr(colon_pos + 1),
		"value": value_str
	})


func _parse_call(spec: String) -> void:
	var parts = spec.split(":")
	if parts.size() < 2:
		print("[RT:ERR] Invalid call syntax: %s (need path:method)" % spec)
		err_count += 1
		return

	var call_args: Array[String] = []
	for i in range(2, parts.size()):
		call_args.append(parts[i])

	command_queue.append({
		"type": "call",
		"path": parts[0],
		"method": parts[1],
		"args": call_args
	})


func _parse_print(spec: String) -> void:
	var colon_pos = spec.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid print syntax: %s (need path:property)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "print",
		"path": spec.substr(0, colon_pos),
		"prop": spec.substr(colon_pos + 1)
	})


func _parse_emit(spec: String) -> void:
	var parts = spec.split(":")
	if parts.size() < 2:
		print("[RT:ERR] Invalid emit syntax: %s (need path:signal)" % spec)
		err_count += 1
		return

	var emit_args: Array[String] = []
	for i in range(2, parts.size()):
		emit_args.append(parts[i])

	command_queue.append({
		"type": "emit",
		"path": parts[0],
		"signal_name": parts[1],
		"args": emit_args
	})


func _parse_watchprop(spec: String) -> void:
	var colon_pos = spec.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid watchprop syntax: %s (need path:property)" % spec)
		err_count += 1
		return

	watch_properties.append({
		"path": spec.substr(0, colon_pos),
		"prop": spec.substr(colon_pos + 1),
		"last_value": null
	})


func _parse_listen(spec: String) -> void:
	var colon_pos = spec.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid listen syntax: %s (need path:signal)" % spec)
		err_count += 1
		return

	queued_listens.append({
		"path": spec.substr(0, colon_pos),
		"signal_name": spec.substr(colon_pos + 1)
	})


func _parse_expect(spec: String) -> void:
	var eq_pos = spec.rfind("=")
	if eq_pos < 0:
		print("[RT:ERR] Invalid expect syntax: %s (missing =)" % spec)
		err_count += 1
		return

	var path_prop = spec.substr(0, eq_pos)
	var value_str = spec.substr(eq_pos + 1)
	var colon_pos = path_prop.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid expect syntax: %s (missing path:prop)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "expect",
		"path": path_prop.substr(0, colon_pos),
		"prop": path_prop.substr(colon_pos + 1),
		"expected": value_str
	})


func _parse_expect_signal(spec: String) -> void:
	var parts = spec.split(":")
	if parts.size() < 2:
		print("[RT:ERR] Invalid expect-signal syntax: %s (need path:signal)" % spec)
		err_count += 1
		return

	var expected_args: Array[String] = []
	for i in range(2, parts.size()):
		expected_args.append(parts[i])

	command_queue.append({
		"type": "expect_signal",
		"path": parts[0],
		"signal_name": parts[1],
		"expected_args": expected_args
	})


func _parse_expect_no_signal(spec: String) -> void:
	var colon_pos = spec.rfind(":")
	if colon_pos < 0:
		print("[RT:ERR] Invalid expect-no-signal syntax: %s (need path:signal)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "expect_no_signal",
		"path": spec.substr(0, colon_pos),
		"signal_name": spec.substr(colon_pos + 1)
	})


func _parse_wait(spec: String) -> void:
	if not spec.is_valid_int():
		print("[RT:ERR] Invalid wait syntax: %s (need integer ms)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "wait",
		"ms": int(spec)
	})


func _parse_wait_frames(spec: String) -> void:
	if not spec.is_valid_int():
		print("[RT:ERR] Invalid wait-frames syntax: %s (need integer)" % spec)
		err_count += 1
		return

	command_queue.append({
		"type": "wait_frames",
		"frames": int(spec)
	})

#endregion


#region EXECUTION

func _execute() -> void:
	await get_tree().process_frame
	scene_root = get_tree().current_scene

	# Setup signal listeners FIRST (before any commands that might emit)
	_setup_listeners()

	# Execute commands sequentially
	for cmd in command_queue:
		match cmd.type:
			"set":
				_do_set(cmd.path, cmd.prop, cmd.value)
			"call":
				_do_call(cmd.path, cmd.method, cmd.args)
			"print":
				_do_print(cmd.path, cmd.prop)
			"emit":
				_do_emit(cmd.path, cmd.signal_name, cmd.args)
			"expect":
				_do_expect(cmd.path, cmd.prop, cmd.expected)
			"expect_signal":
				_do_expect_signal(cmd.path, cmd.signal_name, cmd.expected_args)
			"expect_no_signal":
				_do_expect_no_signal(cmd.path, cmd.signal_name)
			"wait":
				await _do_wait(cmd.ms)
			"wait_frames":
				await _do_wait_frames(cmd.frames)

	# Initialize watch properties
	_setup_watch_properties()

	# Print summary
	_print_summary()

	# Handle watch mode or exit
	if watch_mode:
		_enter_watch_mode()
	elif watch_properties.is_empty():
		_exit_with_code()


func _setup_listeners() -> void:
	for listen in queued_listens:
		var node = _resolve_node(listen.path)
		if not node:
			print("[RT:ERR] listen %s:%s - node not found" % [listen.path, listen.signal_name])
			err_count += 1
			continue

		if not node.has_signal(listen.signal_name):
			print("[RT:ERR] listen %s:%s - signal not found" % [listen.path, listen.signal_name])
			err_count += 1
			continue

		var key = "%s:%s" % [listen.path, listen.signal_name]
		captured_signals[key] = []

		# Create handler - capture self and key in closure
		# Note: Supports signals with up to 5 arguments
		var runtime_test = self
		var capture_key = key
		var handler = func(a1="__NONE__", a2="__NONE__", a3="__NONE__", a4="__NONE__", a5="__NONE__"):
			var args: Array = []
			for arg in [a1, a2, a3, a4, a5]:
				if str(arg) != "__NONE__":
					args.append(arg)
			runtime_test.captured_signals[capture_key].append(args)
			print("[RT:SIGNAL] %s(%s)" % [capture_key, args])

		var err = node.connect(listen.signal_name, handler)
		if err != OK:
			print("[RT:ERR] listen %s:%s - connect failed: %d" % [listen.path, listen.signal_name, err])
			err_count += 1
			continue
		print("[RT:OK] listen %s:%s" % [listen.path, listen.signal_name])
		ok_count += 1


func _setup_watch_properties() -> void:
	if watch_properties.is_empty():
		return

	print("[RT:RESULTS] Watching %d properties for changes:" % watch_properties.size())
	for wp in watch_properties:
		var node = _resolve_node(wp.path)
		if node and wp.prop in node:
			wp.last_value = node.get(wp.prop)
			print("  [RT:WATCH] %s:%s = %s (initial)" % [wp.path, wp.prop, wp.last_value])
		else:
			print("  [RT:ERR] %s:%s - not found" % [wp.path, wp.prop])
			err_count += 1
	set_process(true)


func _print_summary() -> void:
	var parts: Array[String] = []
	if ok_count > 0 or err_count > 0:
		parts.append("%d OK" % ok_count)
		parts.append("%d ERR" % err_count)
	if pass_count > 0 or fail_count > 0:
		parts.append("%d PASS" % pass_count)
		parts.append("%d FAIL" % fail_count)

	if parts.is_empty():
		print("[RT:RESULTS] Done")
	else:
		print("[RT:RESULTS] Done: %s" % ", ".join(parts))


func _enter_watch_mode() -> void:
	print("")
	print("=".repeat(50))
	print("[RT:RESULTS] WATCH MODE ACTIVE")
	print("=".repeat(50))
	print("Press 'Q' to quit when done observing.")
	print("=".repeat(50))
	set_process(true)


func _exit_with_code() -> void:
	if fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

#endregion


#region COMMAND IMPLEMENTATIONS

func _do_set(path: String, prop: String, value_str: String) -> void:
	var node = _resolve_node(path)
	if not node:
		print("[RT:ERR] set %s:%s - node not found" % [path, prop])
		err_count += 1
		return

	if not prop in node:
		print("[RT:ERR] set %s:%s - property not found" % [path, prop])
		err_count += 1
		return

	var parsed = _parse_value(value_str, node, prop)
	var old_value = node.get(prop)
	node.set(prop, parsed)
	var new_value = node.get(prop)

	# Check if value was completely rejected
	if str(parsed) != str(old_value) and str(new_value) == str(old_value):
		print("[RT:ERR] set %s:%s - value rejected (type mismatch: tried %s on %s)" % [path, prop, typeof(parsed), typeof(old_value)])
		err_count += 1
		return

	# Warn if type coercion occurred (e.g., float→int truncation)
	if typeof(parsed) != typeof(new_value) and str(parsed) != str(new_value):
		print("[RT:OK] set %s:%s = %s (coerced from %s)" % [path, prop, new_value, parsed])
		ok_count += 1
		return

	print("[RT:OK] set %s:%s = %s" % [path, prop, new_value])
	ok_count += 1


func _do_call(path: String, method: String, args: Array[String]) -> void:
	var node = _resolve_node(path)
	if not node:
		print("[RT:ERR] call %s:%s - node not found" % [path, method])
		err_count += 1
		return

	if not node.has_method(method):
		print("[RT:ERR] call %s:%s - method not found" % [path, method])
		err_count += 1
		return

	# Validate argument count
	var expected_arg_count := -1
	for m in node.get_method_list():
		if m.name == method:
			expected_arg_count = m.args.size()
			break

	if expected_arg_count >= 0 and args.size() != expected_arg_count:
		print("[RT:ERR] call %s:%s - wrong arg count (got %d, expected %d)" % [path, method, args.size(), expected_arg_count])
		err_count += 1
		return

	var parsed_args: Array = []
	for arg_str in args:
		parsed_args.append(_parse_value_simple(arg_str, node, method))

	node.callv(method, parsed_args)
	print("[RT:OK] call %s:%s(%s)" % [path, method, parsed_args])
	ok_count += 1


func _do_print(path: String, prop: String) -> void:
	var node = _resolve_node(path)
	if not node:
		print("[RT:ERR] print %s:%s - node not found" % [path, prop])
		err_count += 1
		return

	if not prop in node:
		print("[RT:ERR] print %s:%s - property not found" % [path, prop])
		err_count += 1
		return

	var value = node.get(prop)
	print("[RT:PRINT] %s:%s = %s" % [path, prop, value])
	ok_count += 1


func _do_emit(path: String, signal_name: String, args: Array[String]) -> void:
	var node = _resolve_node(path)
	if not node:
		print("[RT:ERR] emit %s:%s - node not found" % [path, signal_name])
		err_count += 1
		return

	if not node.has_signal(signal_name):
		print("[RT:ERR] emit %s:%s - signal not found" % [path, signal_name])
		err_count += 1
		return

	var expected_arg_count := -1
	for sig in node.get_signal_list():
		if sig.name == signal_name:
			expected_arg_count = sig.args.size()
			break

	if expected_arg_count >= 0 and args.size() != expected_arg_count:
		print("[RT:ERR] emit %s:%s - wrong arg count (got %d, expected %d)" % [path, signal_name, args.size(), expected_arg_count])
		err_count += 1
		return

	var parsed_args: Array = []
	for arg_str in args:
		parsed_args.append(_parse_value_simple(arg_str, node, signal_name))

	if parsed_args.is_empty():
		node.emit_signal(signal_name)
	else:
		node.emit_signal.callv([signal_name] + parsed_args)

	print("[RT:OK] emit %s:%s(%s)" % [path, signal_name, parsed_args])
	ok_count += 1


func _do_expect(path: String, prop: String, expected_str: String) -> void:
	var node = _resolve_node(path)
	if not node:
		print("[RT:FAIL] expect %s:%s - node not found" % [path, prop])
		fail_count += 1
		return

	if not prop in node:
		print("[RT:FAIL] expect %s:%s - property not found" % [path, prop])
		fail_count += 1
		return

	var actual = node.get(prop)
	var expected = _parse_value(expected_str, node, prop)

	if str(actual) == str(expected):
		print("[RT:PASS] %s:%s = %s" % [path, prop, actual])
		pass_count += 1
	else:
		print("[RT:FAIL] %s:%s = %s (expected %s)" % [path, prop, actual, expected])
		fail_count += 1


func _do_expect_signal(path: String, signal_name: String, expected_args: Array[String]) -> void:
	var key = "%s:%s" % [path, signal_name]

	if key not in captured_signals:
		print("[RT:FAIL] expect-signal %s - not listening (add --listen:%s first)" % [key, key])
		fail_count += 1
		return

	var emissions: Array = captured_signals[key]
	if emissions.is_empty():
		print("[RT:FAIL] signal %s was not emitted" % key)
		fail_count += 1
		return

	# If no expected args specified, just check it was emitted
	if expected_args.is_empty():
		print("[RT:PASS] signal %s was emitted (%d times)" % [key, emissions.size()])
		pass_count += 1
		return

	# Parse expected args and find a matching emission
	var node = _resolve_node(path)
	var parsed_expected: Array = []
	for arg_str in expected_args:
		parsed_expected.append(_parse_value_simple(arg_str, node, signal_name) if node else arg_str)

	for emission in emissions:
		if _arrays_match(emission, parsed_expected):
			print("[RT:PASS] signal %s(%s)" % [key, parsed_expected])
			pass_count += 1
			return

	print("[RT:FAIL] signal %s - no emission matched %s (got: %s)" % [key, parsed_expected, emissions])
	fail_count += 1


func _do_expect_no_signal(path: String, signal_name: String) -> void:
	var key = "%s:%s" % [path, signal_name]

	if key not in captured_signals:
		print("[RT:FAIL] expect-no-signal %s - not listening (add --listen:%s first)" % [key, key])
		fail_count += 1
		return

	var emissions: Array = captured_signals[key]
	if emissions.is_empty():
		print("[RT:PASS] signal %s was not emitted" % key)
		pass_count += 1
	else:
		print("[RT:FAIL] signal %s was emitted %d times (expected none)" % [key, emissions.size()])
		fail_count += 1


func _do_wait(ms: int) -> void:
	print("[RT:WAIT] %d ms" % ms)
	await get_tree().create_timer(ms / 1000.0).timeout


func _do_wait_frames(frames: int) -> void:
	print("[RT:WAIT] %d frames" % frames)
	for i in frames:
		await get_tree().process_frame

#endregion


#region UTILITIES

func _resolve_node(path: String) -> Node:
	if path == "." or path == "":
		return scene_root
	return scene_root.get_node_or_null(path) if scene_root else null


func _arrays_match(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if str(a[i]) != str(b[i]):
			return false
	return true


func _parse_value(value_str: String, node: Node, prop: String) -> Variant:
	if value_str == "true": return true
	if value_str == "false": return false
	if value_str.is_valid_int(): return int(value_str)
	if value_str.is_valid_float(): return float(value_str)

	for p in node.get_property_list():
		if p.name == prop and p.hint == PROPERTY_HINT_ENUM:
			var enum_names = p.hint_string.split(",")
			for i in enum_names.size():
				var name = enum_names[i].split(":")[-1].strip_edges()
				if name == value_str:
					return i
			break

	return value_str


func _parse_value_simple(value_str: String, node: Node, context: String) -> Variant:
	if value_str == "true": return true
	if value_str == "false": return false
	if value_str.is_valid_int(): return int(value_str)
	if value_str.is_valid_float(): return float(value_str)

	var script = node.get_script() if node else null
	if script:
		var constants = script.get_script_constant_map()
		for enum_name in constants:
			if constants[enum_name] is Dictionary:
				var enum_dict = constants[enum_name] as Dictionary
				if value_str in enum_dict:
					return enum_dict[value_str]

	return value_str

#endregion


#region PROCESS & INPUT

func _process(_delta: float) -> void:
	if watch_properties.is_empty():
		return

	for wp in watch_properties:
		var node = _resolve_node(wp.path)
		if not node or not wp.prop in node:
			continue

		var current_value = node.get(wp.prop)
		if current_value != wp.last_value:
			print("[RT:CHANGE] %s:%s = %s → %s" % [wp.path, wp.prop, wp.last_value, current_value])
			wp.last_value = current_value


func _input(event: InputEvent) -> void:
	if not watch_mode:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		print("[RT:RESULTS] Quit requested")
		get_tree().quit()

#endregion
