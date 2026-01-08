# godot-runtime-test

**CLI-based Runtime Testing Framework for Godot 4.x**

Run any Godot scene from the command line and inject test behavior at runtime. Set properties, call methods, emit signals, capture signal emissions, and assert expectations—all without touching your source files.

Originally built for AI coding agents (Claude Code, Cursor) to run tests automatically via CLI—but works great for manual debugging too.

**YouTube Guide:** Coming soon

## Quick Start

```bash
# Basic property test
godot --path . --headless scene.tscn -- --set:.:health=50 --expect:.:health=50

# Signal capture test
godot --path . --headless scene.tscn -- \
  --listen:.:health_changed \
  --call:.:take_damage:30 \
  --expect-signal:.:health_changed
```

## Installation

### Option 1: Copy Addon
1. Copy `addons/runtime_test/` to your project's `addons/` folder
2. Enable in **Project → Project Settings → Plugins**
3. The `RuntimeTest` autoload is registered automatically

### Option 2: Use Godot Asset Store (Coming Soon...)
Not yet available.

## Features

- **Injection**: `--set`, `--call`, `--emit`
- **Observation**: `--print`, `--listen`, `--watchprop`
- **Assertions**: `--expect`, `--expect-signal`, `--expect-no-signal`
- **Timing**: `--wait`, `--wait-frames`
- **Interactive**: `--watch` mode with Q to quit

## Grep-Friendly Output

All output uses `[RT:*]` prefix for easy filtering:

```bash
godot ... 2>&1 | grep "\[RT:"           # All RuntimeTest output
godot ... 2>&1 | grep "\[RT:FAIL\]"     # Just failures
godot ... 2>&1 | grep "\[RT:PASS\]"     # Just passes
```

## Exit Codes

- `0` = All assertions passed
- `1` = One or more assertions failed

Perfect for CI pipelines!

## Documentation

- [Full Command Reference](addons/runtime_test/README.md)
- [Examples](addons/runtime_test/examples/EXAMPLES.md)

## Claude Code Integration

This repo includes a Claude skill at `.claude/skills/runtime-test/SKILL.md` for AI-assisted testing workflows.

## License

MIT
