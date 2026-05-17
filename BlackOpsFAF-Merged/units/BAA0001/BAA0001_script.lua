local AirDroneUnit = import('/mods/BlackOpsFAF-Merged/lua/BlackOpsunits.lua').AirDroneUnit
local WeaponsFile = import('/lua/aeonweapons.lua')
local AANDepthChargeBombWeapon = WeaponsFile.AANDepthChargeBombWeapon
local ADFQuantumAutogunWeapon = WeaponsFile.ADFQuantumAutogunWeapon

-- Upvalue for performance
local TrashBagAdd = TrashBag.Add

-- Tempest Drone
---@class BAA0001 : AirDroneUnit
BAA0001 = Class(AirDroneUnit) {

    Weapons = {
        MainGun = Class(import('/lua/aeonweapons.lua').ADFCannonOblivionWeapon) {
            FxMuzzleFlash = {
                '/effects/emitters/oblivion_cannon_flash_04_emit.bp',
                '/effects/emitters/oblivion_cannon_flash_05_emit.bp',
                '/effects/emitters/oblivion_cannon_flash_06_emit.bp',
            },
        },
        BlazeGun = Class(ADFQuantumAutogunWeapon) {},
        Depthcharge = Class(AANDepthChargeBombWeapon) {},
    },

    ---@param self BAA0001
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        AirDroneUnit.OnStopBeingBuilt(self, builder, layer)

        local trash = self.Trash

        self.AnimManip = CreateAnimator(self)

        TrashBagAdd(trash, self.AnimManip)

        self.AnimManip:PlayAnim(self.Blueprint.Display.AnimationTakeOff, false):SetRate(1)
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            TrashBagAdd(trash, self.OpenAnim)
        end
    end,

    ---@param self BAA0001
    ---@param new VerticalMovementState
    ---@param old VerticalMovementState
    OnMotionVertEventChange = function(self, new, old)
        -- Intercept BEFORE parent to prevent AirUnit layer transition to water.
        -- JustUndocked guard prevents immediate re-dock after UndockDrone releases us.
        if new == 'Down'
        and not self.JustUndocked
        and self.Carrier and not self.Carrier.Dead
        and not self.Carrier.DroneData[self.Name].Docked then
            local distance = self:GetDistanceFromAttachpoint()
            if distance <= 3 then
                local attachpoint = self.Carrier.DroneData[self.Name].Attachpoint
                IssueClearCommands({self})
                self:AttachBoneTo(-1, self.Carrier, attachpoint)
                self.Carrier.DroneData[self.Name].Docked = attachpoint
                self:SetDoNotTarget(true)
                self:SetImmobile(true)
                self.DockingRequired = false
                self.AwayFromCarrier = false
            end
        end

        AirDroneUnit.OnMotionVertEventChange(self, new, old)

        local bp = self.Blueprint
        if (new == 'Top' or new == 'Up') and old == 'Down' then
            self.AnimManip:SetRate(-1)
        elseif new == 'Down' then
            self.AnimManip:PlayAnim(bp.Display.AnimationLand, false):SetRate(1)
        elseif new == 'Up' then
            self.AnimManip:PlayAnim(bp.Display.AnimationTakeOff, false):SetRate(1)
        end
    end,

    -- Clear JustUndocked flag when carrier calls drone home.
    -- The flag was set by UndockDrone to suppress the spurious 'Down' event on detach.
    DroneNavigateToDock = function(self)
        self.JustUndocked = false
        self.DockingRequired = true
        IssueClearCommands({self})
        local bonePos = self.Carrier:GetPosition(
            self.Carrier.DroneData[self.Name].Attachpoint)
        IssueMove({self}, bonePos)
    end,

}

TypeClass = BAA0001
