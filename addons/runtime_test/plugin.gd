@tool
extends EditorPlugin
## Runtime Test plugin - registers RuntimeTest autoload for runtime testing

const AUTOLOAD_NAME = "RuntimeTest"
const AUTOLOAD_PATH = "res://addons/runtime_test/runtime_test.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("[RuntimeTest] Plugin enabled - autoload registered")


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("[RuntimeTest] Plugin disabled - autoload removed")
