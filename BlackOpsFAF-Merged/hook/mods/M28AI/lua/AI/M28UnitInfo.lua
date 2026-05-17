-- BlackOpsFAF-Merged: Fix GetUnitUpgradeBlueprint returning nil for BlackOps hydro
-- upgrades (CanBuild fails for RULEUBR_OnHydrocarbonDeposit when the source unit
-- occupies the deposit). Falls back to UpgradesTo when UpgradesFrom matches.
-- Note: M28Economy.lua imports M28UnitInfo via import(), which captures the global
-- environment. Wrapping the global here is reflected in that import table.
if GetUnitUpgradeBlueprint then
    local _orig = GetUnitUpgradeBlueprint
    function GetUnitUpgradeBlueprint(oUnit, bGetSupportFactory)
        local result = _orig(oUnit, bGetSupportFactory)
        if not result and oUnit and not oUnit.Dead then
            local sUpgradesTo = oUnit:GetBlueprint().General.UpgradesTo
            if sUpgradesTo and sUpgradesTo ~= '' then
                local oUpgradeBP = __blueprints[sUpgradesTo]
                if oUpgradeBP and oUpgradeBP.General
                    and oUpgradeBP.General.UpgradesFrom == oUnit.UnitId
                then
                    result = sUpgradesTo
                end
            end
        end
        return result
    end
end
