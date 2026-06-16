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
- Shared test helpers live in `tests/helpers/`.
- Keep tests focused on data/logic behavior, not editor-only state.
- Do not create a parallel test framework unless the user explicitly asks; extend the existing minimal helper first.

Current helper pattern:

```gdscript
const Assertions = preload("res://tests/helpers/test_assertions.gd")
var checks := Assertions.new()
```

## Test Command

Use this command from the project root:

```powershell
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_data_loader.gd"
```

For another test file, replace only the script path. Keep paths quoted.

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

## TDD Workflow

1. Add or update the smallest relevant test first.
2. Run the Godot headless command and confirm the test fails for the expected reason.
3. Implement the minimum production change.
4. Re-run the same test until it passes.
5. Run any nearby tests affected by the change.
6. Report the exact command and pass/fail output.

## Verification Checklist

Before saying the work is complete:

- [ ] Test file is under `tests/unit/`.
- [ ] Shared helpers are under `tests/helpers/`.
- [ ] GDScript has no Variant inference warnings.
- [ ] Godot headless command was run.
- [ ] Output shows `PASS` or the remaining failure is clearly reported.
