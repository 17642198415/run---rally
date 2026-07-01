---
name: godot-unit-testing
description: Create, maintain, and run Godot 4.6 GDScript unit tests for this project. Use when adding tests, generating test files, fixing test failures, validating data/logic scripts, or when the user mentions unit tests, headless tests, GDScript tests, or Godot test framework.
---

# Godot Unit Testing

## When to Use

Use this skill before adding or changing tests for Godot/GDScript code in this project, especially for:

- New data or logic scripts under `scripts/`.
- New JSON-driven gameplay data under `data/`.
- Bug fixes that need regression coverage.
- Commands that run tests with Godot headless mode.

## Project Test Layout

- Unit tests live in `tests/unit/`.
- UI scene tests live in `tests/ui/` (headless `change_scene`, button signals, navigation).
- Shared test helpers live in `tests/helpers/`.
- Keep unit tests focused on data/logic behavior; UI tests cover scene load and menu navigation only.
- Do not create a parallel test framework unless the user explicitly asks; extend the existing minimal helper first.

Current helper pattern:

```gdscript
const Assertions = preload("res://tests/helpers/test_assertions.gd")
var checks := Assertions.new()
```

UI tests additionally use:

```gdscript
const Harness = preload("res://tests/helpers/scene_test_harness.gd")
```

`SceneTestHarness` provides `change_scene`, `await_idle(frames)`, `press_button`, `assert_current_scene`, `reset_save_defaults()`, `setup_run_for_node_type`, `press_route_node_on_current_layer`, `assert_new_run_roster`, and related Run/Meta setup helpers (isolated `user://ui_test_save.json`).

## Test Command

Use this command from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File "tests\run_all_tests.ps1"
```

Runs all `tests/unit/test_*.gd` then `tests/ui/test_*.gd`. Success prints `ALL 46 TESTS PASSED`.

Single unit test:

```powershell
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --path "." --script "tests\unit\test_data_loader.gd"
```

Single UI test:

```powershell
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --path "." --script "tests\ui\test_ui_campaign_flow.gd"
```

`run_all_tests.ps1` auto-runs `godot --import` when global `class_name` cache is empty (required for `MenuStyle` / `RunState` in headless scene scripts).

If the Godot path changes, first verify with:

```powershell
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --version
```

## GDScript 4.6 Rules

Godot 4.6 treats several warnings as errors in this project. Follow these rules:

- Do not use `assert` as a variable name; use `checks`.
- Avoid `:=` when the right side is a Variant or dynamic call.
- Add explicit types for dictionaries, arrays, and dynamic calls:
  - `var data: Dictionary = loader.get_unit("M01")`
  - `var ids: Array[String] = loader.get_all_unit_ids()`
  - `var parsed: Variant = JSON.parse_string(text)`
- Use `quit(exit_code)` in `SceneTree` test scripts.
- Do not use `OS.exit_code`; it is not valid here.
- Prefer Autoload access via `get_root().get_node("DataLoader")` in headless tests when testing registered singletons.

## Test Script Pattern

Use this structure for unit tests:

```gdscript
extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
var checks := Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var unit: Dictionary = loader.get_unit("M01")
	checks.assert_equal(unit.get("name"), "火尾狐", "M01 has expected name.")

	quit(checks.finish())
```

UI tests use async `_run()` after `call_deferred`, because `change_scene_to_file` needs multiple frames:

```gdscript
extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checks := Assertions.new()
	var harness := Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.change_scene("res://scenes/main_menu.tscn")
	await harness.await_idle()
	quit(checks.finish())
```

Always `await harness.await_idle()` (default 3 frames) after scene changes or `Button.pressed.emit()`.

## TDD Workflow

1. Add or update the smallest relevant test first.
2. Run the Godot headless command and confirm the test fails for the expected reason.
3. Implement the minimum production change.
4. Re-run the same test until it passes.
5. Run any nearby tests affected by the change.
6. Report the exact command and pass/fail output.

## Verification Checklist

Before saying the work is complete:

- [ ] Test file is under `tests/unit/` or `tests/ui/`.
- [ ] Shared helpers are under `tests/helpers/`.
- [ ] GDScript has no Variant inference warnings.
- [ ] `run_all_tests.ps1` or targeted Godot headless command was run.
- [ ] Output shows `PASS` or the remaining failure is clearly reported.
