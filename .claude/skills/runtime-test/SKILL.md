---
name: runtime-test
description: Run Godot scenes with runtime testing via command-line flags. Set properties, call methods, emit signals, capture signals, and assert expectations—all without editing source files.
---

# Runtime Test - CLI Testing Framework for Godot

Test Godot scenes at runtime without modifying source files. Perfect for:
- AI agents running automated tests
- CI pipeline integration
- Quick debugging and state injection
- Signal capture and assertion

## Grep-First Design

All output uses `[RT:*]` prefix for easy filtering:

```bash
# Get ONLY RuntimeTest output
godot ... 2>&1 | grep "\[RT:"

# Filter by type
grep "\[RT:PASS\]"     # Passed assertions
grep "\[RT:FAIL\]"     # Failed assertions
grep "\[RT:OK\]"       # Successful operations
grep "\[RT:ERR\]"      # Failed operations
grep "\[RT:SIGNAL\]"   # Captured signals
grep "\[RT:RESULTS\]"  # Summary line
```

## Quick Reference

### Injection Commands
```bash
--set:Path:prop=value        # Set property
--call:Path:method:arg1      # Call method
--emit:Path:signal:arg1      # Emit signal
```

### Observation Commands
```bash
--print:Path:prop            # Print property once
--listen:Path:signal         # Capture signal emissions (up to 5 args)
--watchprop:Path:prop        # Print on property change
```

### Assertion Commands
```bash
--expect:Path:prop=value     # Assert property equals value
--expect-signal:Path:sig     # Assert signal was emitted
--expect-signal:Path:sig:a:b # Assert signal with specific args
--expect-no-signal:Path:sig  # Assert signal NOT emitted
```

### Control Commands
```bash
--wait:500                   # Wait 500ms
--wait-frames:10             # Wait 10 frames
--watch                      # Keep running, Q to quit
```

### Path Conventions
- `.` = scene root
- `Player` = direct child
- `Player/Health` = nested path

## Basic Usage

```bash
# Headless test (CI-friendly)
godot --path . --headless scene.tscn -- --set:.:health=50 --expect:.:health=50

# With window (debugging)
godot --path . scene.tscn -- --watch --watchprop:.:state
```

**Key:** `--` separates Godot flags from RuntimeTest flags.

## Examples

### Property Testing
```bash
# Set and verify
godot --path . --headless scene.tscn -- \
  --set:.:health=50 \
  --expect:.:health=50

# Output:
# [RT:OK] set .:health = 50
# [RT:PASS] .:health = 50
# [RT:RESULTS] Done: 1 OK, 0 ERR, 1 PASS, 0 FAIL
```

### Signal Testing
```bash
# Listen FIRST, then trigger, then assert
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --call:.:take_damage:30 \
  --expect-signal:.:health_changed

# Output:
# [RT:OK] listen .:health_changed
# [RT:SIGNAL] .:health_changed([100, 70])
# [RT:OK] call .:take_damage([30])
# [RT:PASS] signal .:health_changed was emitted (1 times)
```

### Assert Signal NOT Emitted
```bash
godot --path . --headless scene.tscn -- \
  --listen:.:died \
  --set:.:health=100 \
  --call:.:take_damage:10 \
  --expect-no-signal:.:died

# [RT:PASS] signal .:died was not emitted
```

### Async Testing with Wait
```bash
godot --path . --headless scene.tscn -- \
  --listen:.:animation_finished \
  --call:.:play_death \
  --wait:500 \
  --expect-signal:.:animation_finished
```

### Watch Mode (Interactive)
```bash
godot --path . scene.tscn -- \
  --watch \
  --watchprop:.:state \
  --set:.:debug=true
# Press Q to quit
```

## Output Markers

| Marker | Meaning |
|--------|---------|
| `[RT:OK]` | Operation succeeded |
| `[RT:ERR]` | Operation failed |
| `[RT:PASS]` | Assertion passed |
| `[RT:FAIL]` | Assertion failed |
| `[RT:PRINT]` | Property printed |
| `[RT:CHANGE]` | Watched property changed |
| `[RT:SIGNAL]` | Signal captured |
| `[RT:WAIT]` | Waiting |
| `[RT:WATCH]` | Watch mode info |
| `[RT:RESULTS]` | Summary/system message |

### Exit Codes
- `0` = All assertions passed
- `1` = One or more assertions failed

## Type Parsing

| Input | Parsed As |
|-------|-----------|
| `true`/`false` | bool |
| `123` | int |
| `1.5` | float |
| `IDLE` | enum (looked up in script) |
| anything else | String |

## CI Pipeline Integration

```bash
# Run test
godot --path . --headless scene.tscn -- \
  --set:.:health=50 \
  --expect:.:health=50

# Check exit code
if [ $? -ne 0 ]; then
  echo "Tests failed!"
  exit 1
fi

# Or grep for failures
godot ... 2>&1 | grep -q "\[RT:FAIL\]" && exit 1
```

## Common Patterns

### State Machine Testing
```bash
godot --path . --headless scene.tscn -- \
  --listen:.:state_changed \
  --call:.:transition_to:ATTACKING \
  --expect-signal:.:state_changed
```

### Damage System Testing
```bash
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --listen:.:died \
  --set:.:health=100 \
  --call:.:take_damage:150 \
  --expect:.:health=0 \
  --expect-signal:.:died
```

### XR Scene Testing
```bash
godot --path . --xr-mode on scene.tscn -- \
  --watch \
  --set:.:debug_mode=true
```

## Troubleshooting

### `[RT:ERR] property not found`
- Check spelling
- Verify property exists in script
- Check node path

### `[RT:ERR] wrong arg count`
- Method expects different number of arguments
- Check method signature

### `[RT:FAIL] signal not listening`
- Add `--listen:Path:signal` BEFORE the action that emits
- Order matters: listen → trigger → assert

### `[RT:OK] set ... (coerced from X)`
- Type was converted (e.g., float→int truncation)
- Value was accepted but modified

## Instructions for Claude

When user asks to test a scene:

1. **Use `--headless`** for automated tests
2. **Listen before triggering**: `--listen` must come before actions that emit
3. **Assert after actions**: `--expect` comes after `--set`/`--call`
4. **Use exit codes** for CI: non-zero = failure
5. **Grep output** for filtering: `grep "\[RT:FAIL\]"`

Example:
```bash
godot --path . --headless Scenes/Player.tscn -- \
  --listen:.:health_changed \
  --set:.:health=50 \
  --expect:.:health=50 \
  --expect-signal:.:health_changed
```
