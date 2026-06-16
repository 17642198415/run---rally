# chapter-1-data-layer Specification

## Purpose

Defines the chapter 1 foundation for the Godot tactics monster demo: project skeleton, JSON-driven base data, Autoload data access, and command-line unit test coverage.

## Requirements

### Requirement: Project skeleton matches chapter 1
The Godot project SHALL contain the chapter 1 directory skeleton for data, scripts, scenes, and placeholder assets without implementing later gameplay systems.

#### Scenario: Skeleton directories are present
- **WHEN** the repository is inspected after the change
- **THEN** `data/units`, `data/skills`, `scripts/autoload`, `scenes/battle`, and `assets/placeholder` exist

### Requirement: Base game data is JSON-driven
The system SHALL define 8 monster unit JSON files, 10 skill JSON files, and one hero JSON file with fields required by the chapter 1 data contract.

#### Scenario: Unit and skill data can be parsed
- **WHEN** the data loader loads all data files
- **THEN** all 8 unit IDs, all 10 skill IDs, and the hero data are available without JSON parse errors

#### Scenario: Unit skill mapping is valid
- **WHEN** each unit is loaded
- **THEN** its `skill_id` references an existing skill JSON entry

### Requirement: DataLoader exposes data query APIs
The system SHALL provide a `DataLoader` Autoload with `load_all()`, `get_unit(unit_id)`, `get_skill(skill_id)`, `get_hero()`, and `get_all_unit_ids()` APIs.

#### Scenario: Query M01
- **WHEN** `DataLoader.load_all()` has completed and `get_unit("M01")` is called
- **THEN** the returned dictionary contains `name` equal to `火尾狐`

#### Scenario: Query hero
- **WHEN** `DataLoader.load_all()` has completed and `get_hero()` is called
- **THEN** the returned dictionary contains `id` equal to `HERO` and `skill_id` equal to `S_INSPIRE`

### Requirement: Autoloads are registered in chapter 1 order
The project SHALL register `DataLoader`, `GameState`, `SaveManager`, and `MetaManager` as Autoload singletons in the required order.

#### Scenario: Project configuration contains Autoloads
- **WHEN** `project.godot` is inspected
- **THEN** the Autoload section lists `DataLoader`, `GameState`, `SaveManager`, and `MetaManager` in that order

### Requirement: Unit tests can be run from the command line
The project SHALL include a minimal unit test framework that can run data layer tests from a headless Godot command.

#### Scenario: Data layer unit test passes
- **WHEN** the unit test command is executed in the project root
- **THEN** tests for data loading, key fields, and unit-skill references pass with a zero exit code
