-- BlackOpsFAF-Merged: Allow hydrocarbon plant upgrades
-- The FAF engine's CheckBuildRestriction calls CanBuild(), which returns
-- false for RULEUBR_OnHydrocarbonDeposit upgrade targets (unlike
-- RULEUBR_OnMassDeposit which works correctly for vanilla mex upgrades).
-- This override allows the engine to accept IssueUpgrade commands when
-- the target blueprint's UpgradesFrom matches the calling unit's ID.

local oldCheckBuildRestriction = Unit.CheckBuildRestriction
Unit.CheckBuildRestriction = function(self, target_bp)
    if target_bp.General and target_bp.General.UpgradesFrom == self.UnitId then
        return true
    end
    return oldCheckBuildRestriction(self, target_bp)
end
