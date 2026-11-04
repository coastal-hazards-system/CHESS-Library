# Retired equations

No callers. Kept off the path by `chess_setup_path.m`.

- `melby_low_crested_stability.m` - Melby low-crested breakwater stability (structure type 4 was removed).
- `submerged_armor_stone_damage.m` - submerged armor-stone damage.

The Melby seaside and Van Gent leeside Dn50 equations and the submerged armor-stone stability correction moved to `Structure_Responses/Equations/Stability/` (2026-11-04): the rubble mound Dn50 comes from the ANN (`Structure_Responses/ANN/ann_rubblemound_stability.m`) unless `dn50_use_legacy_model = 1`.
