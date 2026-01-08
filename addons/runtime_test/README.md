# godot-runtime-test

**CLI-based Runtime testing framework for Godot 4.x**

Run any Godot scene from the command line and inject test behavior at runtime. Set properties, call methods, emit signals, capture signal emissions, and assert expectations—all without touching your source files. Get structured output (`[RT:OK]`, `[RT:ERR]`, `[RT:PASS]`, `[RT:FAIL]`) that's easy to parse and act on.

Originally built for AI coding agents (Claude Code, Cursor) to run tests automatically via CLI—but works great for manual debugging too. No AI required.

**YouTube Guide:** Coming soon

---

## Quick Start

```bash
# Basic property test
godot --path . --headless scene.tscn -- --set:.:health=50 --expect:.:health=50

# Signal capture test
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --call:.:take_damage:30 \
  --expect-signal:.:health_changed

# Full async test with wait
godot --path . --headless scene.tscn -- \
  --listen:.:died \
  --set:.:health=1 \
  --call:.:take_damage:100 \
  --wait:200 \
  --expect:.:health=0 \
  --expect-signal:.:died
```

---

## Command Reference

### Injection Commands
| Command | Syntax | Purpose |
|---------|--------|---------|
| `--set` | `--set:Path:prop=value` | Set a property |
| `--call` | `--call:Path:method:arg1:arg2` | Call a method |
| `--emit` | `--emit:Path:signal:arg1:arg2` | Emit a signal (outbound) |

### Observation Commands
| Command | Syntax | Purpose |
|---------|--------|---------|
| `--print` | `--print:Path:prop` | Print property value once |
| `--watchprop` | `--watchprop:Path:prop` | Print when property changes |
| `--listen` | `--listen:Path:signal` | Capture signal emissions (inbound, up to 5 args) |

### Assertion Commands
| Command | Syntax | Purpose |
|---------|--------|---------|
| `--expect` | `--expect:Path:prop=value` | Assert property equals value |
| `--expect-signal` | `--expect-signal:Path:signal` | Assert signal was emitted |
| `--expect-signal` | `--expect-signal:Path:signal:arg1:arg2` | Assert signal with specific params |
| `--expect-no-signal` | `--expect-no-signal:Path:signal` | Assert signal was NOT emitted |

### Control Commands
| Command | Syntax | Purpose |
|---------|--------|---------|
| `--wait` | `--wait:milliseconds` | Wait before next command |
| `--wait-frames` | `--wait-frames:N` | Wait N frames |
| `--watch` | `--watch` | Keep running, Q to quit |

**Path conventions:**
- `.` = scene root
- `Player` = direct child named "Player"
- `Player/Health` = nested path

---

## Output Markers

| Marker | Meaning |
|--------|---------|
| `[RT:OK]` | Injection operation succeeded |
| `[RT:ERR]` | Injection operation failed |
| `[RT:PRINT]` | Property value printed |
| `[RT:CHANGE]` | Watched property changed |
| `[RT:SIGNAL]` | Signal was captured |
| `[RT:PASS]` | Assertion passed |
| `[RT:FAIL]` | Assertion failed |
| `[RT:WAIT]` | Waiting (ms or frames) |
| `[RT:WATCH]` | Watch mode property info |
| `[RT:RESULTS]` | Summary/system message |

### Summary Format
```
[RT:RESULTS] Done: 3 OK, 0 ERR, 2 PASS, 1 FAIL
```

### Exit Codes
- `0` = All assertions passed (or no assertions)
- `1` = One or more assertions failed

---

## Installation

### Option 1: As Addon (Recommended)
1. Copy `addons/runtime_test/` to your project
2. Enable in **Project → Project Settings → Plugins**
3. The `RuntimeTest` autoload is registered automatically

### Option 2: Manual Autoload
1. Copy `runtime_test.gd` anywhere in your project
2. Add as autoload: **Project → Project Settings → Autoload**
3. Name it `RuntimeTest`

---

## Examples

### Property Testing
```bash
# Set and verify
godot --path . --headless scene.tscn -- \
  --set:.:health=50 \
  --expect:.:health=50

# Print current value
godot --path . --headless scene.tscn -- \
  --print:.:health
```

### Signal Testing
```bash
# Verify signal is emitted (any params)
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --set:.:health=50 \
  --expect-signal:.:health_changed

# Verify signal with exact params
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --set:.:health=50 \
  --expect-signal:.:health_changed:100:50

# Verify signal is NOT emitted
godot --path . --headless scene.tscn -- \
  --listen:.:died \
  --set:.:health=100 \
  --call:.:take_damage:10 \
  --expect-no-signal:.:died
```

### Async Testing with Wait
```bash
# Wait for async operations
godot --path . --headless scene.tscn -- \
  --listen:.:animation_finished \
  --call:.:play_death_animation \
  --wait:500 \
  --expect-signal:.:animation_finished

# Wait for frame-based logic
godot --path . --headless scene.tscn -- \
  --call:.:start_process \
  --wait-frames:10 \
  --expect:.:process_complete=true
```

### Watch Mode (Interactive)
```bash
# Keep running and observe changes
godot --path . scene.tscn -- \
  --watch \
  --watchprop:.:state \
  --set:.:is_active=true
# Press Q to quit
```

---

## Type Parsing

Values are auto-parsed:

| Input | Parsed As |
|-------|-----------|
| `true` / `false` | bool |
| `123` | int |
| `1.5` | float |
| `FLOATING` | enum (looked up in script) |
| anything else | String |

---

## AI Agent Integration

This framework is designed for AI-assisted workflows. Claude Code can construct and run tests with natural language:

> "Test the player taking 50 damage and verify health drops to 50"

```bash
godot --path . --headless player.tscn -- \
  --listen:.:health_changed \
  --set:.:health=100 \
  --call:.:take_damage:50 \
  --expect:.:health=50 \
  --expect-signal:.:health_changed
```

Output is grep-able for CI pipelines:
```bash
godot ... 2>&1 | grep "\[FAIL\]" && echo "Tests failed!"
```

---

## Project Structure

```
your-project/
├── addons/
│   └── runtime_test/
│       ├── plugin.cfg
│       ├── plugin.gd
│       ├── runtime_test.gd
│       ├── README.md
│       └── examples/
│           ├── verification_test.gd
│           ├── verification_test.tscn
│           └── EXAMPLES.md
└── ...
```

---

## License

MIT
