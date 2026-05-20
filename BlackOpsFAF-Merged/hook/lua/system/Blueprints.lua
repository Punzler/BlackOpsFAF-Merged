do
    function ExtractCloakMeshBlueprint(bp)
        local meshid = bp.Display.MeshBlueprint
        if not meshid then return end

        local meshbp = original_blueprints.Mesh[meshid]
        if not meshbp then return end

        local shadernameE = 'ShieldCybran'
        local shadernameA = 'ShieldAeon'
        local shadernameC = 'ShieldCybran'
        local shadernameS = 'ShieldAeon'

        local cloakmeshbp = table.deepcopy(meshbp)
        if cloakmeshbp.LODs then
            for i,cat in bp.Categories do
            if cat == 'UEF' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameE
                end
            elseif cat == 'AEON' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameA
                end
            elseif cat == 'CYBRAN' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameC
                end
            elseif cat == 'SERAPHIM' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameS
                end
            end
            end
        end
        cloakmeshbp.BlueprintId = meshid .. '_cloak'
        bp.Display.CloakMeshBlueprint = cloakmeshbp.BlueprintId
        MeshBlueprint(cloakmeshbp)
    end

    function ExtractPhaseMeshBlueprint(bp)
        local meshid = bp.Display.MeshBlueprint
        if not meshid then return end

        local meshbp = original_blueprints.Mesh[meshid]
        if not meshbp then return end

        local shadernameP1 = 'ShieldUEF'
        local shadernameP2 = 'AlphaFade'
        local shadernameP12 = 'PhalanxEffect'
        local shadernameP22 = 'AlphaFade'

        local phase1meshbp = table.deepcopy(meshbp)
        if phase1meshbp.LODs then
            for i,cat in bp.Categories do
            if cat == 'UEF' then
                for i,lod in phase1meshbp.LODs do
                    lod.ShaderName = shadernameP1
                end
            elseif cat == 'AEON' then
                for i,lod in phase1meshbp.LODs do
                    lod.ShaderName = shadernameP1
                end
            elseif cat == 'CYBRAN' then
                for i,lod in phase1meshbp.LODs do
                    lod.ShaderName = shadernameP12
                end
            elseif cat == 'SERAPHIM' then
                for i,lod in phase1meshbp.LODs do
                    lod.ShaderName = shadernameP12
                end
            end
            end
        end
        local phase2meshbp = table.deepcopy(meshbp)
        if phase2meshbp.LODs then
            for i,cat in bp.Categories do
            if cat == 'UEF' then
                for i,lod in phase2meshbp.LODs do
                    lod.ShaderName = shadernameP2
                end
            elseif cat == 'AEON' then
                for i,lod in phase2meshbp.LODs do
                    lod.ShaderName = shadernameP2
                end
            elseif cat == 'CYBRAN' then
                for i,lod in phase2meshbp.LODs do
                    lod.ShaderName = shadernameP22
                end
            elseif cat == 'SERAPHIM' then
                for i,lod in phase2meshbp.LODs do
                    lod.ShaderName = shadernameP22
                end
            end
            end
        end
        phase1meshbp.BlueprintId = meshid .. '_phase1'
        phase2meshbp.BlueprintId = meshid .. '_phase2'
        bp.Display.Phase1MeshBlueprint = phase1meshbp.BlueprintId
        bp.Display.Phase2MeshBlueprint = phase2meshbp.BlueprintId
        MeshBlueprint(phase1meshbp)
        MeshBlueprint(phase2meshbp)
    end

    local OldModBlueprints = ModBlueprints
    function ModBlueprints(all_blueprints)
        OldModBlueprints(all_blueprints)
        for id,bp in all_blueprints.Unit do
            ExtractCloakMeshBlueprint(bp)
            ExtractPhaseMeshBlueprint(bp)
            if table.find(bp.Categories, 'SUBCOMMANDER') then
                table.insert(bp.Categories, 'ANTITELEPORT')
            end
            if bp.Weapon then
                for ik, wep in bp.Weapon do
                    if HasTargetLayer(wep, "Air") then
                        if not wep.AntiSat == true then
                            wep.TargetRestrictDisallow = wep.TargetRestrictDisallow and wep.TargetRestrictDisallow .. ', SATELLITE' or 'SATELLITE'
                        end
                    end
                end
            end
            if not bp.Categories or not bp.Display.Mesh.LODs then continue end
            CalculateNewLod(bp)
        end

        -- =========================================================
        -- BLACKOPS DRONE CARRIER FIXES (FAF Patch 3818, Feb 2025)
        -- FAF aligned PODSTAGINGPLATFORM with AIRSTAGINGPLATFORM behavior,
        -- requiring explicit AI.StagingPlatformScanRadius and Transport.DockingSlots.
        -- Without these fields drones will not dock automatically.
        -- =========================================================
        local bel0402 = all_blueprints.Unit['bel0402']
        if bel0402 then
            bel0402.AI = bel0402.AI or {}
            bel0402.AI.StagingPlatformScanRadius = 30
            bel0402.Transport = bel0402.Transport or {}
            bel0402.Transport.DockingSlots = 3
            bel0402.Transport.StorageSlots = 0
        end

        local uas0401 = all_blueprints.Unit['uas0401']
        if uas0401 then
            uas0401.AI = uas0401.AI or {}
            uas0401.AI.StagingPlatformScanRadius = 30
            uas0401.Transport = uas0401.Transport or {}
            uas0401.Transport.DockingSlots = 6
            uas0401.Transport.StorageSlots = 0
            if uas0401.Display and uas0401.Display.Abilities then
                for i, ability in uas0401.Display.Abilities do
                    if ability == '<LOC ability_aadrones>Anti-Air Drones' or
                       ability == 'ability_aadrones' then
                        uas0401.Display.Abilities[i] = '<LOC ability_gunshipdrones>Gunship Drones'
                    end
                end
            end
        end

        local bsl0401 = all_blueprints.Unit['bsl0401']
        if bsl0401 then
            bsl0401.AI = bsl0401.AI or {}
            bsl0401.AI.StagingPlatformScanRadius = 30
            bsl0401.Transport = bsl0401.Transport or {}
            bsl0401.Transport.DockingSlots = 7
            bsl0401.Transport.StorageSlots = 0
        end

        -- BSA0004 Yenzotha drone missing DRONE category (has POD but not DRONE)
        local bsa0004 = all_blueprints.Unit['bsa0004']
        if bsa0004 and bsa0004.Categories then
            if not table.find(bsa0004.Categories, 'DRONE') then
                table.insert(bsa0004.Categories, 'DRONE')
            end
        end

        -- =========================================================
        -- PARAGON FOR ALL FACTIONS
        -- Adds UEF, CYBRAN, SERAPHIM categories to the Aeon Paragon
        -- (xab1401) so T3 engineers/SCUs of every faction can build it.
        -- =========================================================
        local xab1401 = all_blueprints.Unit['xab1401']
        if xab1401 and xab1401.Categories then
            for _, fac in {'UEF', 'CYBRAN', 'SERAPHIM'} do
                if not table.find(xab1401.Categories, fac) then
                    table.insert(xab1401.Categories, fac)
                end
            end
        end

        -- =========================================================
        -- QUANTUM GATES BUILD ALL-FACTION sACUs
        -- Adds a faction-agnostic 'BUILTBYQUANTUMGATE SUBCOMMANDER'
        -- expression to every faction's Quantum Gate so each gate
        -- can produce sACUs of all four factions, while engineers
        -- and drones remain faction-locked (vanilla behavior).
        -- =========================================================
        for _, gateId in {'uab0304', 'ueb0304', 'urb0304', 'xsb0304'} do
            local gate = all_blueprints.Unit[gateId]
            if gate and gate.Economy and gate.Economy.BuildableCategory then
                local cat = 'BUILTBYQUANTUMGATE SUBCOMMANDER'
                if not table.find(gate.Economy.BuildableCategory, cat) then
                    table.insert(gate.Economy.BuildableCategory, cat)
                end
            end
        end

        -- =========================================================
        -- DISABLE SPECIFIC UNITS FROM OTHER MODS
        -- Add unit IDs (lowercase) to this table to prevent them
        -- from being built. Build categories are stripped so the
        -- units still exist but cannot be constructed.
        -- =========================================================
        local disabledUnits = {
            'brnbt1airst',
            'brmbt1airst',
            'brobt1airst',
            'brmat1intc',
            'brmat1advfig',
            'broat1intc',
            'broat1fig',
            'brnat1advfig',
            'brnat1intc',
        }
        local disabledSet = {}
        for _, uid in disabledUnits do
            disabledSet[uid] = true
        end

        local buildCategoriesToRemove = {
            'BUILTBYTIER1FACTORY', 'BUILTBYTIER2FACTORY', 'BUILTBYTIER3FACTORY',
            'BUILTBYCOMMANDER', 'BUILTBYTIER2COMMANDER', 'BUILTBYTIER3COMMANDER',
            'BUILTBYTIER2ENGINEER', 'BUILTBYTIER3ENGINEER',
            'BUILTBYQUANTUMGATE', 'BUILTBYEXPERIMENTALSUB',
        }

        for uid, bp in all_blueprints.Unit do
            if disabledSet[uid] and bp.Categories then
                local newCats = {}
                for _, cat in bp.Categories do
                    local dominated = false
                    for _, rem in buildCategoriesToRemove do
                        if cat == rem then
                            dominated = true
                            break
                        end
                    end
                    if not dominated then
                        table.insert(newCats, cat)
                    end
                end
                bp.Categories = newCats
            end
        end

        -- =========================================================
        -- CRASH DAMAGE NORMALISATION
        -- FAF's AirUnit crash system reads DeathImpact.Damage from blueprint.
        -- Auto-formula (mass/4.5) produced excessive values for both units.
        -- Normalised to 7000 to match balanced vanilla experimental standard.
        -- =========================================================
        local uaa0310 = all_blueprints.Unit['uaa0310']
        if uaa0310 and uaa0310.Weapon then
            for _, wep in uaa0310.Weapon do
                if wep.Label == 'DeathImpact' then
                    wep.Damage = 7000   -- was 16000+
                    break
                end
            end
        end

        local bea0402 = all_blueprints.Unit['bea0402']
        if bea0402 and bea0402.Weapon then
            for _, wep in bea0402.Weapon do
                if wep.Label == 'DeathImpact' then
                    wep.Damage = 7000   -- was 10880
                    break
                end
            end
        end
    end
end

function HasTargetLayer(weapon, searchLayer)
    for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
        if string.find( TargetLayer, searchLayer ) then
            return true
        end
    end
    return false
end

function CalculateNewLod(uBP)
    -- we only check if we have SelectionSizeX + Z
    if not uBP.SelectionSizeX or not uBP.SelectionSizeZ then return end
    -- if we don't have LOD settings, return
    if table.getn(uBP.Display.Mesh.LODs) <= 0 then return end
    -- copy categories into local variable for faster access
    local Categories = {}
    for _, cat in uBP.Categories do
        Categories[cat] = true
    end
    -- If we use only higrestextures we move LODCutoff from LOD-2 to LOD-1 and delete the 2nd LOD entry
    -- do we have LODCutoff in 2nd LOD array ?
    if uBP.Display.Mesh.LODs[2].LODCutoff then
        -- copy LODCutoff from lowres to highres LOD
        uBP.Display.Mesh.LODs[1].LODCutoff = uBP.Display.Mesh.LODs[2].LODCutoff
    end
    -- delete the 2nd LOD entry
    uBP.Display.Mesh.LODs[2] = nil
    -- calculate unit/building surface by SelectionSize or HitBoxSize, whatever is bigger
    local SelectionSize = uBP.SelectionSizeX * uBP.SelectionSizeZ
    local HitBoxSize = (uBP.SizeX or 1) / 1.4  * (uBP.SizeZ or 1) / 1.4
    local UnitLodSize
    if SelectionSize > HitBoxSize then
        UnitLodSize = SelectionSize
    else
        UnitLodSize = HitBoxSize
    end
    -- make Experimental bigger, if it's not already as big as an factory. So we see experimentals a bit longer if zoomed out
    if (Categories.EXPERIMENTAL or uBP.StrategicIconName == 'icon_experimental_generic') and UnitLodSize < 5.5 then
        UnitLodSize = UnitLodSize * 1.8
    end
    -- mq use 125 as offset, so we start hiding units after strategic icons are shown.
    local mq = math.floor(UnitLodSize *35)+125 -- to compare: UnitLodSize from LandFactory x*y = 10,56.
    -- dont hide units until we display the strategic icon
    if mq < 130 then
        mq = 130
    end
    -- stop displaying land units at LOD 600 (LANDFactory has ~ 500)
    if mq > 600 and not Categories.AIR and not Categories.EXPERIMENTAL then
        mq = 600
    end
    -- stop displaying air units a little bit later then land units
    if mq > 700 and Categories.AIR and not Categories.EXPERIMENTAL then
        mq = 700
    end
    -- stop displaying all units over LOD 1000. (almost zoomed out max)
    if mq > 1000 then
        mq = 1000
    end
    -- Set the new LODCutoff inside blueprint LOD-1 or LOD-2
    uBP.Display.Mesh.LODs[1].LODCutoff = mq
    -- display strategic icons from LOD 130 on, so they will hide smaller units. Except special units.
    if uBP.Display.Mesh.IconFadeInZoom and uBP.Display.Mesh.IconFadeInZoom < 1000 then
        uBP.Display.Mesh.IconFadeInZoom = 130
    end
end
