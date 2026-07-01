## ADDED Requirements

### Requirement: Bestiary view provides Meta unlock tab

`bestiary_view.tscn` SHALL allow switching between the existing species grid (**灵兽**) and a Meta unlock list (**解锁**) without changing navigation back to the main menu. The unlock tab SHALL use the same `MenuStyle` card presentation as other menu pages.

#### Scenario: Tab switch preserves back navigation

- **WHEN** the player opens the unlock tab and presses Back
- **THEN** the scene returns to `main_menu.tscn` as before

#### Scenario: Species grid hidden on unlock tab

- **WHEN** the unlock tab is selected
- **THEN** the 8-cell species grid is not visible and the unlock list is shown
