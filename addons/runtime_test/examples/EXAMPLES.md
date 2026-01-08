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

## Multi-Node Example

### Damage and Heal via Signal Chain
This example demonstrates interacting with multiple nodes. The Character has a HealSpell child component that listens for the `heal_requested` signal.

```bash
godot --path . --quit-after 100 addons/runtime_test/examples/multi_node.tscn -- \
  --print:.:health \
  --call:.:take_damage:50 \
  --print:.:health \
  --call:.:request_heal \
  --print:.:health
```

**Expected output:**
```
[Character] Ready - health: 100/100
[HealSpell] Ready - connected to Character (heal amount: 30)
[RT:PRINT] .:health = 100
[Character] Taking 50 damage
[Character] Health: 100 -> 50
[RT:OK] call .:take_damage([50])
[RT:PRINT] .:health = 50
[Character] Requesting heal...
[HealSpell] Heal requested! Casting heal on Character...
[Character] Health: 50 -> 80
[Character] Healed for 30 (now 80/100)
[HealSpell] Heal complete!
[RT:OK] call .:request_heal([])
[RT:PRINT] .:health = 80
[RT:RESULTS] Done: 5 OK, 0 ERR
```

Flow: health 100 → take 50 damage → health 50 → request heal → HealSpell receives signal → heals 30 → health 80

---

### Modify Child Node Property with Assertion
```bash
godot --path . --quit-after 100 addons/runtime_test/examples/multi_node.tscn -- \
  --set:HealSpell:heal_amount=50 \
  --call:.:take_damage:80 \
  --call:.:request_heal \
  --expect:.:health=70
```

**Expected output:**
```
[Character] Ready - health: 100/100
[HealSpell] Ready - connected to Character (heal amount: 30)
[RT:OK] set HealSpell:heal_amount = 50
[Character] Taking 80 damage
[Character] Health: 100 -> 20
[RT:OK] call .:take_damage([80])
[Character] Requesting heal...
[HealSpell] Heal requested! Casting heal on Character...
[Character] Health: 20 -> 70
[Character] Healed for 50 (now 70/100)
[HealSpell] Heal complete!
[RT:OK] call .:request_heal([])
[RT:PASS] .:health = 70
[RT:RESULTS] Done: 3 OK, 0 ERR, 1 PASS, 0 FAIL
```

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
