## MODIFIED Requirements

### Requirement: RewardPool rescue pool uses Meta unlock extras

`RewardPool.get_rescue_pool()` SHALL return the default base pool (`M01`, `M02`, `M03`, `M04`) plus any `add_to_pool` template ids from unlocked Meta entries via `MetaManager.get_pool_extras()`. Duplicates SHALL be removed. When no Meta pool extras are unlocked, behavior SHALL match the 8A default pool.

#### Scenario: Default rescue pool without Meta

- **WHEN** no Meta pool extras are unlocked
- **THEN** `get_rescue_pool()` returns `["M01", "M02", "M03", "M04"]`

#### Scenario: M08 added to rescue pool when META_M08 unlocked

- **WHEN** `META_M08` is unlocked
- **THEN** `get_rescue_pool()` contains `"M08"`
