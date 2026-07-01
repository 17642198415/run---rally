## ADDED Requirements

### Requirement: reward_pool.json defines seven post-battle rewards

The project SHALL include `data/route/reward_pool.json` with a `rewards` array containing exactly these reward ids: `R_BALL`, `R_HEAL`, `R_ATK`, `R_HP`, `R_SKILL`, `R_COIN`, `R_RESCUE`. Each entry MUST have `id`, `name`, `desc`, and `effect` keys. The file MUST include `boss_weight_bonus` listing `R_ATK`, `R_SKILL`, and `R_RESCUE`.

#### Scenario: reward_pool.json loads and parses

- **WHEN** `RewardPool.load_pool()` is called in headless mode
- **THEN** it returns a dictionary with at least 7 rewards and a non-empty `boss_weight_bonus` array

#### Scenario: Each reward has a recognized effect shape

- **WHEN** the pool is loaded
- **THEN** `R_BALL` effect includes `balls`, `R_HEAL` includes `heal_pct`, `R_COIN` includes `coins`, `R_ATK`/`R_HP`/`R_SKILL` include `target: "one_pet"`, and `R_RESCUE` includes `random_pet` and `hp_pct`

### Requirement: RewardPool picks three unique rewards with boss weight bonus

The system SHALL provide `RewardPool` static methods `pick_three(rng: RandomNumberGenerator, is_boss: bool) -> Array` that returns exactly 3 reward dictionaries drawn without replacement from the loaded pool using each reward's `weight` (default 1 if absent). When `is_boss` is true, rewards whose `id` appears in `boss_weight_bonus` MUST have their selection weight multiplied by 2 before drawing.

#### Scenario: pick_three returns three distinct rewards

- **WHEN** `RewardPool.pick_three(rng, false)` is called
- **THEN** the result has size 3 and all three `id` values are unique

#### Scenario: Same seed produces same triple for elite

- **WHEN** two RNGs are seeded identically and `pick_three(rng, false)` is called on each
- **THEN** both results contain the same three reward ids in the same order

#### Scenario: Boss mode increases bonus reward frequency

- **WHEN** `pick_three` is called 200 times with `is_boss=true` and random seeds
- **THEN** at least one of `R_ATK`, `R_SKILL`, or `R_RESCUE` appears in the triple more often than when `is_boss=false` with the same seeds (statistical smoke; unit test may use forced RNG sequence)

### Requirement: RewardPool applies reward effects to RunState

`RewardPool.apply_reward(state: RunState, reward: Dictionary, target_unit_id: String, loader: Node) -> bool` SHALL mutate `state` according to `reward.effect`:

| Effect keys | Behavior |
|-------------|----------|
| `balls` | increment `state.balls` |
| `heal_pct` | heal all `reserve` entries by that fraction of max HP (also update HERO in `party` if present) |
| `coins` | increment `state.coins` |
| `stat` + `delta` + `target: one_pet` | add delta to `atk` or `max_hp` on matching `reserve` entry; for `max_hp`, also increase current `hp` by delta capped at new max |
| `skill_cd` + `target: one_pet` | reduce `skill_cd` on matching reserve entry, floor at 0 |
| `random_pet` + `hp_pct` | append a new reserve unit from the rescue pool at `hp_pct` of template max HP via the same id/skill rules as capture |

The function MUST return `false` without partial mutation when `target: one_pet` is required but `target_unit_id` is empty or not found, or when reserve is full for `R_RESCUE`. On failure, `state` MUST remain unchanged from before the call.

#### Scenario: R_BALL increments balls

- **WHEN** `apply_reward` is called with `R_BALL` on a state with `balls == 3`
- **THEN** `state.balls == 4` and the function returns true

#### Scenario: R_HEAL heals reserve by percentage

- **WHEN** a reserve unit has `hp=10, max_hp=20` and `R_HEAL` with `heal_pct: 0.25` is applied
- **THEN** that unit's `hp` becomes 15

#### Scenario: R_ATK requires valid target

- **WHEN** `R_ATK` is applied with an empty `target_unit_id`
- **THEN** the function returns false and reserve atk values are unchanged

#### Scenario: R_RESCUE adds unit when reserve has space

- **WHEN** reserve size is below cap and `R_RESCUE` is applied
- **THEN** reserve gains one new entry with a unique `unit_id` and `hp` equal to `hp_pct` of template max HP

### Requirement: reward_pick scene presents three-card picker UI

`scenes/roguelike/reward_pick.tscn` with script `reward_picker.gd` SHALL display the title「战后奖励 — 选 1」and three card buttons built from `RunManager.get_pending_rewards()`. Each card shows reward `name` and `desc`. Selecting a card with `target: one_pet` SHALL prompt the player to pick a reserve unit before confirming. After a successful `RunManager.apply_reward_choice(reward_id, target_unit_id)`, the scene MUST navigate to `route_map.tscn` for elite victories, or `run_summary.tscn` when `RunManager.get_last_outcome().victory` is true (BOSS path).

#### Scenario: Elite reward selection returns to route map

- **WHEN** the player selects a non-target reward after an elite victory
- **THEN** `apply_reward_choice` succeeds, `pending_rewards` is cleared, and the game loads `route_map.tscn`

#### Scenario: Boss reward selection proceeds to run summary

- **WHEN** the player confirms a reward after BOSS victory with `get_last_outcome().victory == true`
- **THEN** the game loads `run_summary.tscn` after choice is applied

#### Scenario: Picker uses MenuStyle card shell

- **WHEN** `reward_pick.tscn` finishes `_ready()`
- **THEN** `MenuStyle.apply_page_shell` is applied without crash

### Requirement: RunManager exposes reward choice API

`RunManager` SHALL provide:

- `get_pending_rewards() -> Array`: returns `state.pending_rewards` or empty array if no active run
- `apply_reward_choice(reward_id: String, target_unit_id: String = "") -> bool`: finds matching reward in pending list, calls `RewardPool.apply_reward`, clears `pending_rewards` and `pending_reward_is_boss` on success, and calls `save()`
- `has_pending_rewards() -> bool`: convenience check

#### Scenario: apply_reward_choice clears pending after success

- **WHEN** pending rewards contain `R_COIN` and `apply_reward_choice("R_COIN")` succeeds
- **THEN** `get_pending_rewards()` is empty and save persists the updated state

#### Scenario: apply_reward_choice rejects unknown id

- **WHEN** `apply_reward_choice("R_INVALID")` is called
- **THEN** it returns false and pending rewards remain unchanged
