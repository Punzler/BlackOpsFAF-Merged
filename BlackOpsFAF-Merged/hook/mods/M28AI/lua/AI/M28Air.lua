-- BlackOpsFAF-Merged: Two-part hook to keep M28-owned satellites out of
-- enemy SMD coverage.
--
-- Part 1: pause M28Air's NovaxCoreTargetLoop while a satellite is actively
-- retreating from SMD fire. The retreat itself is issued from M28Events.lua's
-- OnDamaged hook, which sets refiSatelliteRetreatUntil to (GameTimeSeconds + 15)
-- on every damage tick. While that timestamp is in the future, M28Air must not
-- re-target the satellite, otherwise the retreat IssueMove would be overridden
-- immediately.
--
-- Part 2: after M28Air picks a target, check whether that target sits inside
-- the danger zone of a known enemy SMD. The mod's modified SMDs have AntiSat
-- with MaxRadius=90, so any target within (90 + sat attack range 32 + buffer)
-- of an enemy SMD will pull the satellite into kill range as it closes for
-- the attack. If we detect that, we override the order: clear commands and
-- send the satellite to a safe staging position 120 ogrids from the SMD,
-- on the line from SMD outward through the satellite's current location.
--
-- Each FAF module has its own global scope, so we declare BO_SatRetreatUntil
-- independently here (plain assignment — a read-then-assign with `or` would
-- trip FAF's strict-global check).
refiSatelliteRetreatUntil = 'BO_SatRetreatUntil'

if NovaxCoreTargetLoop then
    local _BO_origNovaxCoreTargetLoop = NovaxCoreTargetLoop
    function NovaxCoreTargetLoop(aiBrain, oNovax, bCalledFromUnitDeath)
        -- Part 1: if we're inside the retreat window, do nothing.
        if oNovax and (oNovax[refiSatelliteRetreatUntil] or 0) > GetGameTimeSeconds() then
            return
        end

        -- Let the original loop pick a target and issue commands.
        _BO_origNovaxCoreTargetLoop(aiBrain, oNovax, bCalledFromUnitDeath)

        -- Part 2: SMD-danger post-filter on whatever target the original picked.
        if not M28UnitInfo.IsUnitValid(oNovax) then return end

        local oTarget = oNovax[refoNovaxLastTarget]
        local tCheckPos
        if M28UnitInfo.IsUnitValid(oTarget) then
            tCheckPos = oTarget:GetPosition()
        else
            -- No target: original moves the sat toward enemy base. Use that as
            -- the check position so we still bail out if the enemy base is
            -- covered by an SMD.
            tCheckPos = M28Map.GetPrimaryEnemyBaseLocation(aiBrain)
        end
        if not tCheckPos then return end

        -- Find any enemy SMD known to this brain near the check position.
        local tEnemySMDs = aiBrain:GetUnitsAroundPoint(M28UnitInfo.refCategorySMD, tCheckPos, 150, 'Enemy')
        if M28Utilities.IsTableEmpty(tEnemySMDs) then return end

        local oClosestSMD
        local iClosestDist = 999999
        for _, oSMD in tEnemySMDs do
            if M28UnitInfo.IsUnitValid(oSMD) then
                local iDist = M28Utilities.GetDistanceBetweenPositions(tCheckPos, oSMD:GetPosition())
                if iDist < iClosestDist then
                    iClosestDist = iDist
                    oClosestSMD = oSMD
                end
            end
        end

        -- Danger threshold: SMD range 90 + sat attack range 32 + 8 buffer.
        if oClosestSMD and iClosestDist < 130 then
            local tSMDPos    = oClosestSMD:GetPosition()
            local iSatToSMD  = M28Utilities.GetDistanceBetweenPositions(oNovax:GetPosition(), tSMDPos)
            IssueClearCommands({oNovax})
            if iSatToSMD < 120 then
                -- Sat is itself within (or close to) SMD range. Retreat to 120
                -- ogrids from the SMD on the line outward through the sat.
                local iAngle   = M28Utilities.GetAngleFromAToB(tSMDPos, oNovax:GetPosition())
                local tSafePos = M28Utilities.MoveInDirection(tSMDPos, iAngle, 120, true)
                IssueMove({oNovax}, tSafePos)
            end
            -- Else: sat is already outside SMD danger. Clearing the attack
            -- order is enough — leave it parked rather than moving it closer.
            -- Clear the recorded target so the next loop iteration picks
            -- something else instead of locking back onto the same one.
            oNovax[refoNovaxLastTarget] = nil
        end
    end
end
