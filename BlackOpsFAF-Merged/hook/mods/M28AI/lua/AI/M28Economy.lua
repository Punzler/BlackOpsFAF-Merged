-- BlackOpsFAF-Merged: Force bUpdateUpgradeTracker=true on any UpgradeUnit call
-- where the caller passed false/nil and the unit actually has a blueprint-defined
-- upgrade target. M28's UpgradeUnit issues the upgrade order inside "if bUpdateUpgradeTracker
-- then" (m28economy.lua:95-154), so passing false makes the upgrade silently no-op
-- and trips the line-179 ErrorHandler ("Dont have a valid upgrade ID").
--
-- Known callers with the bug:
--   m28economy.lua:875 in ConsiderHydroUpgradeLoop (passes false) — fires on any
--     unit with BP.General.UpgradesTo set, including hydrocarbon plants and vanilla
--     mex (ueb1202 -> ueb1302 etc.)
--   m28building.lua:6604 in UpgradeShieldsCoveringSMD (passes nothing -> nil) —
--     fires on T2 shields covering an SMD to push them to T3 (ueb4202 -> ueb4301
--     via Shields Enhanced).
--
-- The intent of those call sites is to actually upgrade the unit. The conservative
-- guard (BP.UpgradesTo must be non-empty) prevents unintended side effects on
-- units that aren't upgrade-capable.
if UpgradeUnit then
    local origUpgradeUnit = UpgradeUnit
    function UpgradeUnit(oUnitToUpgrade, bUpdateUpgradeTracker, iOptionalWait)
        if not bUpdateUpgradeTracker
            and oUnitToUpgrade
            and not oUnitToUpgrade.Dead
            and oUnitToUpgrade.GetBlueprint
        then
            local oBP = oUnitToUpgrade:GetBlueprint()
            if oBP and oBP.General
                and oBP.General.UpgradesTo
                and oBP.General.UpgradesTo ~= ''
            then
                bUpdateUpgradeTracker = true
            end
        end
        return origUpgradeUnit(oUnitToUpgrade, bUpdateUpgradeTracker, iOptionalWait)
    end
end
