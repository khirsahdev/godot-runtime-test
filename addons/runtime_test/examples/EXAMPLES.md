# Runtime Test Examples

Run these commands from your project root to see Runtime Test in action.

## Basic Examples

### Print Properties
```bash
godot --path . --quit-after 60 addons/runtime_test/examples/test_target.tscn -- \
  --print:.:state \
  --print:.:health
```

**Expected output:**
```
[TestTarget] Ready - state: IDLE, health: 100
[RT:PRINT] .:state = 0
[RT:PRINT] .:health = 100
[RT:RESULTS] Done: 2 OK, 0 ERR
```

---

### Set Property + Call Method
```bash
godot --path . --quit-after 100 addons/runtime_test/examples/test_target.tscn -- \
  --set:.:health=50 \
  --call:.:transition_to:ATTACKING
```

**Expected output:**
```
[TestTarget] Ready - state: IDLE, health: 100
[TestTarget] Health: 100 -> 50
[RT:OK] set .:health = 50
[TestTarget] State: IDLE -> ATTACKING
[TestTarget] Signal received: state_changed(ATTACKING)
[RT:OK] call .:transition_to([2])
[RT:RESULTS] Done: 2 OK, 0 ERR
```

---

### Emit Signal
```bash
godot --path . --quit-after 100 addons/runtime_test/examples/test_target.tscn -- \
  --emit:.:state_changed:DEAD
```

**Expected output:**
```
[TestTarget] Signal received: state_changed(DEAD)
[RT:OK] emit .:state_changed([3])
[RT:RESULTS] Done: 1 OK, 0 ERR
```

---

### Watch Mode + Property Changes
```bash
godot --path . addons/runtime_test/examples/test_target.tscn -- \
  --watch \
  --watchprop:.:state \
  --call:.:transition_to:MOVING
```

**Expected output:**
```
[TestTarget] State: IDLE -> MOVING
[RT:OK] call .:transition_to([1])
[RT:RESULTS] Watching 1 properties for changes:
  [RT:WATCH] .:state = 1 (initial)

==================================================
[RT:RESULTS] WATCH MODE ACTIVE
==================================================
Press 'Q' to quit when done observing.
```

---

### Chained Operations
```bash
godot --path . --quit-after 100 addons/runtime_test/examples/test_target.tscn -- \
  --set:.:is_invulnerable=true \
  --call:.:take_damage:50 \
  --print:.:health
```

**Expected output:**
```
[RT:OK] set .:is_invulnerable = true
[TestTarget] Damage blocked - invulnerable
[RT:OK] call .:take_damage([50])
[RT:PRINT] .:health = 100
[RT:RESULTS] Done: 3 OK, 0 ERR
```

Health remains 100 because `is_invulnerable` was set first.

---

## Error Examples

### Property Not Found
```bash
godot --path . --quit-after 60 addons/runtime_test/examples/test_target.tscn -- \
  --set:.:nonexistent=true
```

**Output:**
```
[RT:ERR] set .:nonexistent - property not found
[RT:RESULTS] Done: 0 OK, 1 ERR
```

### Method Not Found
```bash
godot --path . --quit-after 60 addons/runtime_test/examples/test_target.tscn -- \
  --call:.:bad_method
```

**Output:**
```
[RT:ERR] call .:bad_method - method not found
[RT:RESULTS] Done: 0 OK, 1 ERR
```
