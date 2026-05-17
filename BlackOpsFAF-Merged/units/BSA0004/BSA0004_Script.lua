-- Yenzotha Drone

local AirDroneUnit = import('/mods/BlackOpsFAF-Merged/lua/BlackOpsunits.lua').AirDroneUnit
local YenzothaExperimentalLaser02 = import ('/mods/BlackOpsFAF-Merged/lua/BlackOpsWeapons.lua').YenzothaExperimentalLaser02

local OldBSA0004 = Class(AirDroneUnit) {

    Weapons = {
        EyeWeapon01 = Class(YenzothaExperimentalLaser02) {},
    },

    ContrailEffects = {'/effects/emitters/contrail_ser_polytrail_01_emit.bp'}

}

-- Extends base class with Returning-flag-based docking.
-- Mirrors the BEA0006 pattern: DroneNavigateToDock sets Returning=true,
-- OnMotionHorzEventChange attaches on Stopped+Returning.
-- DroneLinkHeartbeat continuously updates the move target while Returning
-- so a moving Yenzotha doesn't leave drones stranded on terrain.
BSA0004 = Class(OldBSA0004) {

    SetParent = function(self, parent, droneName)
        OldBSA0004.SetParent(self, parent, droneName)
        self.Returning = false
    end,

    DroneNavigateToDock = function(self)
        self.JustUndocked = false
        self.DockingRequired = true
        self.Returning = true
        IssueClearCommands({self})
        local bonePos = self.Carrier:GetPosition(
            self.Carrier.DroneData[self.Name].Attachpoint)
        IssueMove({self}, bonePos)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        OldBSA0004.OnMotionHorzEventChange(self, new, old)
        if new == 'Stopped' and self.Returning
        and self.Carrier and not self.Carrier.Dead then
            local attachBone = self.Carrier.DroneData[self.Name].Attachpoint
            self:AttachBoneTo(-1, self.Carrier, attachBone)
            self.Carrier.DroneData[self.Name].Docked = attachBone
            self:SetDoNotTarget(true)
            self:SetImmobile(true)
            self.Returning = false
            self.DockingRequired = false
        end
    end,

    DroneLinkHeartbeat = function(self)
        while self and not self.Dead and self.Carrier and not self.Carrier.Dead do
            local distance = self:GetDistanceFromAttachpoint()

            if self.Returning then
                IssueClearCommands({self})
                local bonePos = self.Carrier:GetPosition(
                    self.Carrier.DroneData[self.Name].Attachpoint)
                IssueMove({self}, bonePos)
            elseif distance > self.MaxRange and self.AwayFromCarrier == false then
                self:DroneRecall()
            elseif distance <= self.ReturnRange and self.AwayFromCarrier == true then
                self:DroneRelease()
            end

            WaitSeconds(self.HeartBeatInterval)
        end
    end,

    DroneRecall = function(self, disableweapons)
        self.AwayFromCarrier = true
        self.Returning = true
        self:SetSpeedMult(2.0)
        self:SetAccMult(2.0)
        self:SetTurnMult(2.0)
        if disableweapons and not self.WeaponsDisabled then
            for i = 1, self:GetWeaponCount() do
                local wep = self:GetWeapon(i)
                wep:SetWeaponEnabled(false)
                wep:AimManipulatorSetEnabled(false)
            end
            self.WeaponsDisabled = true
        end
        IssueClearCommands({self})
        local bonePos = self.Carrier:GetPosition(
            self.Carrier.DroneData[self.Name].Attachpoint)
        IssueMove({self}, bonePos)
        for k, cap in self.CapTable do
            self:RemoveCommandCap(cap)
        end
    end,

    DroneRelease = function(self)
        self.AwayFromCarrier = false
        self.Returning = false
        self:SetSpeedMult(1.0)
        self:SetAccMult(1.0)
        self:SetTurnMult(1.0)
        if self.WeaponsDisabled then
            for i = 1, self:GetWeaponCount() do
                local wep = self:GetWeapon(i)
                wep:SetWeaponEnabled(true)
                wep:AimManipulatorSetEnabled(true)
            end
            self.WeaponsDisabled = false
        end
        self:RestoreCommandCaps()
    end,
}

TypeClass = BSA0004
