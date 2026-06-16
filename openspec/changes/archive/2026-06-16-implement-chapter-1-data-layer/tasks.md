## 1. Test Framework and RED Tests

- [x] 1.1 Add a minimal headless Godot unit test runner for data layer tests
- [x] 1.2 Add data layer tests for unit count, skill count, hero fields, M01 lookup, and unit skill references
- [x] 1.3 Run the data layer tests before implementation and confirm they fail for missing production code/data

## 2. Chapter 1 Skeleton and Data

- [x] 2.1 Create chapter 1 directories for data, autoload scripts, battle scene placeholder, and placeholder assets
- [x] 2.2 Add 8 unit JSON files with required stats, capture metadata, tags, and skill IDs
- [x] 2.3 Add 10 skill JSON files including `S_INSPIRE` and `S_BERSERK`
- [x] 2.4 Add `data/hero.json` with `HERO` and `S_INSPIRE`

## 3. Autoload Implementation

- [x] 3.1 Implement `scripts/autoload/data_loader.gd` with `load_all()`, `get_unit()`, `get_skill()`, `get_hero()`, and `get_all_unit_ids()`
- [x] 3.2 Implement lightweight `game_state.gd`, `save_manager.gd`, and `meta_manager.gd` chapter 1 shells
- [x] 3.3 Register Autoloads in `project.godot` in the required order
- [x] 3.4 Keep `scenes/main_menu.tscn` as the main scene and make it suitable for chapter 1 startup validation

## 4. Verification

- [x] 4.1 Run unit tests and fix failures until all data layer tests pass
- [x] 4.2 Run a Godot parse/startup check if CLI is available
- [x] 4.3 Update `README.md` progress for chapter 1 when verification passes
