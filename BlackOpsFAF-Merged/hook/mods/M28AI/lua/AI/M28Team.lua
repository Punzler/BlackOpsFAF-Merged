-- BlackOpsFAF-Merged: Treat enemy satellite control centres identically to
-- enemy nuke launchers so M28's existing SMD-build logic fires when one is
-- visible. The mod's modified T3 SMDs (ueb4302/uab4302/urb4302/xsb4302)
-- carry an AntiSat weapon that intercepts satellites, so building SMDs is
-- the correct defensive response to a satellite-centre on the field.
--
-- Two unit IDs covered:
--   xeb2402 - Novax Centre (UEF vanilla)
--   bab2404 - Artemis Satellite Control (BlackOps Aeon)
--
-- Mechanism: M28's AddUnitToBigThreatTable iterates over
-- tEnemyBigThreatCategories and dispatches each detected enemy unit into
-- the matching threat table. Extending the reftEnemyNukeLaunchers entry
-- means satellite centres get registered there automatically when visible,
-- with no periodic loop required. This mirrors the pattern M28 uses for
-- categories.uese0001 in M28Air.lua.
if tEnemyBigThreatCategories and reftEnemyNukeLaunchers then
    tEnemyBigThreatCategories[reftEnemyNukeLaunchers] =
        tEnemyBigThreatCategories[reftEnemyNukeLaunchers]
        + categories.xeb2402
        + categories.bab2404
end
