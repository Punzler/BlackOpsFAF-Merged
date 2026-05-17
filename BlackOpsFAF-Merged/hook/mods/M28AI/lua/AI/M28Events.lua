-- BlackOpsFAF-Merged: When an M28-owned satellite (refCategorySatellite) takes
-- damage from an enemy unit, issue a retreat move away from the attacker and
-- flag the satellite so M28Air's NovaxCoreTargetLoop hook (see M28Air.lua)
-- pauses its own re-targeting for a few seconds. The mod's modified T3 SMDs
-- can intercept satellites with EffectiveRadius=90, so the retreat target is
-- placed 120 ogrids from the attacker (90 + 30 buffer).
--
-- Throttling:
--   refiLastRetreatIssued limits IssueMove to one command per 2 seconds so we
--   don't spam orders while taking sustained fire, but every damage tick still
--   extends refiSatelliteRetreatUntil to suppress M28's re-targeting.

refiSatelliteRetreatUntil = 'BO_SatRetreatUntil'   -- GameTimeSeconds until which M28Air should not re-target this sat
refiLastRetreatIssued     = 'BO_SatLastRetreat'    -- GameTimeSeconds of the last IssueMove we sent

-- Watchdog: vanilla Novax Centre (xeb2402) auto-spawns its satellite via
-- CreateUnitHPR('XEA0002', ...) in OpenState/Extend() after OnStopBeingBuilt.
-- In rare cases (observed in game_27045480.log) the script-side state and
-- the engine factory-queue state desynchronise and the Centre is left in
-- a "Building" state with empty command queue and zero work progress — no
-- satellite ever appears. This watchdog runs alongside the Centre, detects
-- that stuck condition, and force-issues a build of xea0002 to unblock it.
local function BO_NovaxSatelliteWatchdog(oCentre)
    WaitSeconds(5)
    while M28UnitInfo.IsUnitValid(oCentre) do
        if not (oCentre.Satellite and M28UnitInfo.IsUnitValid(oCentre.Satellite)) then
            local sState      = M28UnitInfo.GetUnitState(oCentre)
            local bQueueEmpty = M28Utilities.IsTableEmpty(oCentre:GetCommandQueue())
            local iProgress   = oCentre:GetWorkProgress() or 0
            if bQueueEmpty and iProgress == 0
               and (sState == 'Idle' or sState == 'Building')
            then
                IssueClearCommands({oCentre})
                IssueBuildFactory({oCentre}, 'xea0002', 1)
            end
        end
        WaitSeconds(15)
    end
end

if OnConstructed then
    local _BO_origOnConstructed = OnConstructed
    function OnConstructed(oEngineer, oJustBuilt)
        _BO_origOnConstructed(oEngineer, oJustBuilt)
        if not M28Utilities.bM28AIInGame then return end
        if not M28UnitInfo.IsUnitValid(oJustBuilt) then return end
        if not oJustBuilt:GetAIBrain().M28AI then return end
        if not EntityCategoryContains(M28UnitInfo.refCategoryNovaxCentre, oJustBuilt.UnitId) then return end
        ForkThread(BO_NovaxSatelliteWatchdog, oJustBuilt)
    end
end

if OnDamaged then
    local _BO_origOnDamaged = OnDamaged
    function OnDamaged(self, instigator)
        _BO_origOnDamaged(self, instigator)

        if not M28Utilities.bM28AIInGame then return end
        if not self.GetAIBrain or not self:GetAIBrain().M28AI then return end
        if not self.UnitId or not EntityCategoryContains(M28UnitInfo.refCategorySatellite, self.UnitId) then return end

        -- Resolve the actual attacking unit (mirrors the resolution logic in
        -- the original OnDamaged a few lines below).
        local oAttacker
        if instigator and not instigator:BeenDestroyed() then
            if instigator.GetLauncher and instigator:GetLauncher() then
                oAttacker = instigator:GetLauncher()
            elseif IsProjectile(instigator) or IsCollisionBeam(instigator) then
                if instigator.unit then oAttacker = instigator.unit end
            elseif IsUnit(instigator) then
                oAttacker = instigator
            end
        end
        if not M28UnitInfo.IsUnitValid(oAttacker) then return end
        if not IsEnemy(oAttacker.Army, self.Army) then return end

        local iNow = GetGameTimeSeconds()
        -- Always extend the M28Air-suppression window on every hit so the sat
        -- stays under our control while damage is ongoing.
        self[refiSatelliteRetreatUntil] = iNow + 15

        -- Throttle the actual move order to once every 2 seconds.
        if (self[refiLastRetreatIssued] or 0) >= iNow - 2 then return end
        self[refiLastRetreatIssued] = iNow

        local tSatPos      = self:GetPosition()
        local tAttackerPos = oAttacker:GetPosition()
        local iAngle       = M28Utilities.GetAngleFromAToB(tAttackerPos, tSatPos)
        local tRetreatPos  = M28Utilities.MoveInDirection(tAttackerPos, iAngle, 120, true)

        IssueClearCommands({self})
        IssueMove({self}, tRetreatPos)
    end
end
