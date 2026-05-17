local AirDroneUnit = import('/mods/BlackOpsFAF-Merged/lua/BlackOpsunits.lua').AirDroneUnit
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher

local TrashBagAdd = TrashBag.Add

-- Goliath Drone (base class, kept as BEA0005 for historical compatibility)
BEA0005 = Class(AirDroneUnit) {

    Weapons = {
       Cannon01 = Class(TSAMLauncher) {},
       Cannon02 = Class(TSAMLauncher) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        AirDroneUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash
        self.EngineManipulators = {}
        self.EngineRotateBones = {'Engines1'}
        for _, value in self.EngineRotateBones do
            table.insert(self.EngineManipulators, CreateThrustController(self, "thruster", value))
        end
        for _,value in self.EngineManipulators do
            value:SetThrustingParam(-0.0, 0.0, -0.25, 0.25, -0.1, 0.1, 1.0, 0.25)
        end
        for _, v in self.EngineManipulators do
            TrashBagAdd(trash,v)
        end
    end,

}

-- Extends BEA0005 with Returning-flag-based docking.
-- IssueMove to bone world position; OnMotionHorzEventChange attaches on Stopped+Returning.
-- DroneLinkHeartbeat re-issues IssueMove each tick while Returning so a walking Goliath
-- doesn't leave the drone landing on stale terrain.
BEA0006 = Class(BEA0005) {

    SetParent = function(self, parent, droneName)
        BEA0005.SetParent(self, parent, droneName)
        self.Returning = false
        IssueGuard({self}, parent)
    end,

    DroneNavigateToDock = function(self)
        self.DockingRequired = true
        self.Returning = true
        IssueClearCommands({self})
        local bonePos = self.Carrier:GetPosition(
            self.Carrier.DroneData[self.Name].Attachpoint)
        IssueMove({self}, bonePos)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        BEA0005.OnMotionHorzEventChange(self, new, old)
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

TypeClass = BEA0006
