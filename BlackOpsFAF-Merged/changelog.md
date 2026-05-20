---
## Adjustments by Punzler (20.Mai.2026)

**EES0301 (Seawolf Advanced Tactical Submarine):**
- EES0301_unit.bp: set RULEUCC_Tactical to true so the tactical missile launch button is always visible.
- EES0301_script.lua: removed dynamic RULEUCC_Tactical toggling from OnStopBeingBuilt and OnLayerChange — button no longer hides when submerged.
- UEFTacNuke01_proj.bp: increased MaxSpeed from 12 to 50.

---
## Adjustments by Punzler (20.Mai.2026)

**Disable Total Mayhem T1 air units:**
- Blueprints.lua ModBlueprints: strips all BUILTBY* categories from 9 Total Mayhem units (BRNBT1AIRST, BRMBT1AIRST, BROBT1AIRST, BRMAT1INTC, BRMAT1ADVFIG, BROAT1INTC, BROAT1FIG, BRNAT1ADVFIG, BRNAT1INTC) so they still exist in the engine but cannot be built by any factory, engineer, or gate. Add or remove unit IDs in the `disabledUnits` table to adjust.

---
## Adjustments by Punzler (20.Mai.2026)

**BSB2402 (Seraphim Quantum Rift Archway):**
- BSB2402_Script.lua: changed energy consumption per second from `energyDrain * 3` to `energyDrain / 100` — energy drain now scales proportionally like mass drain instead of being a flat 3x multiplier of the built unit's total energy cost.

---
## Adjustments by Punzler (13.Mai.2026)

**BRL0401 (Basilisk) bugfixes:**
- units/BRL0401/BRL0401_Script.lua: OnScriptBitClear now calls CWalkingLandUnit.OnScriptBitClear instead of OnScriptBitSet — copy-paste typo that left the parent's bit state inconsistent when toggling out of deployed mode.
- units/BRL0401/BRL0401_Script.lua: moved the long-range weapon init (ShoulderGuns / MissileRack2 disable + ChangeMaxRadius(0), and the AI HeadWeapon ChangeMaxRadius(500) override) out of OnCreate into OnStopBeingBuilt. OnCreate runs before the unit is finished and SetWeaponEnabledByLabel can fail to stick — moving it post-build fixes deployed mode never actually firing ShoulderGuns/MissileRack2 after the toggle.
- units/BRL0401/BRL0401_unit.bp: swapped MuzzleBones + TurretBoneMuzzle on LeftBolter and RightBolter so each side fires from its own barrel. Was mirrored — LeftBolter aimed via Left_Bolter bones but spawned projectiles from Right_Bolter_Muzzle_*, RightBolter vice versa.
- units/BRL0401/BRL0401_unit.bp: corrected LOC keys Description/UnitName/HelpText from brl0307_*/brl0308_* to brl0401_*. Copy-paste tags would have pulled in the wrong unit's localised strings once a translation file is dropped in.
- units/BRL0401/BRL0401_unit.bp: TorsoWeapon DisplayName fixed from 'Head weapon' to 'Torso Weapon'.
- units/BRL0401/BRL0401_Script.lua cleanup: removed dead args on self:CreateDeathExplosionDustRing() (function takes only self), collapsed `WaitSeconds(1); WaitSeconds(0.1)` to `WaitSeconds(1.1)`, removed the duplicate `local army = self:GetArmy()` later in DeathThread.

---
## Adjustments by Punzler (12.Mai.2026)
**Paragon for all factions:**
- xab1401 (Aeon Paragon): UEF, CYBRAN, SERAPHIM categories added so T3 engineers/SCUs of every faction can build it. Patch lives in Blueprints.lua ModBlueprints (idempotent via table.find, no blueprint snapshot — future FAF balance changes to the Paragon remain in effect). Note: Paragon has the EXPERIMENTAL category and therefore appears in the T4 tab, not T3.

**Quantum Gates build all-faction sACUs:**
- uab0304/ueb0304/urb0304/xsb0304 (Aeon/UEF/Cybran/Seraphim Quantum Gate): Added 'BUILTBYQUANTUMGATE SUBCOMMANDER' expression to Economy.BuildableCategory so each gate can produce sACUs of all four factions. Engineers/drones remain faction-locked (vanilla behavior). Implemented in Blueprints.lua ModBlueprints (idempotent via table.find, no blueprint snapshot).

**M28 AI Mass Extractor upgrade fix:**
- hook/mods/M28AI/lua/AI/M28Economy.lua: extended the bUpdateUpgradeTracker force to also cover MASSEXTRACTION. M28's ConsiderHydroUpgradeLoop is misnamed and actually runs on any unit with BP.UpgradesTo set, including vanilla mex; the existing hook only covered HYDROCARBON, leaving T2 mex upgrades silently blocked and spamming "M28ERROR: Dont have a valid upgrade ID; UnitID=ueb1202; sExpectedUpgradeID=ueb1302" in the log. M28 now actually issues T2→T3 mex upgrades for all four factions. v2: generalised the guard from a category whitelist (HYDROCARBON + MASSEXTRACTION) to "any unit with BP.General.UpgradesTo set" — caught a second failing path via M28Building.UpgradeShieldsCoveringSMD (m28building.lua:6604) which passes no second argument and therefore defaults bUpdateUpgradeTracker to nil. Now covers T2 shield → T3 shield upgrades for the Shields Enhanced chain (ueb4202 → ueb4301 etc.) too.

**BEB4209 (UEF Anti-Teleport Building) script fix:**
- units/BEB4209/BEB4209_script.lua: replaced `self.AIBrain:GetEconomyStored('Energy')` with `self:GetAIBrain():GetEconomyStored('Energy')` (two call sites, lines 143 and 172). The old `self.AIBrain` field doesn't carry the GetEconomyStored method in FAF, so the ResourceThread / EconomyWaitUnit threads aborted with "attempt to call method 'GetEconomyStored' (a nil value)" — leaving the unit unable to toggle its shield based on stored energy.

**M28 AI satellite-centre defence trigger:**
- hook/mods/M28AI/lua/AI/M28Team.lua (new): extends tEnemyBigThreatCategories[reftEnemyNukeLaunchers] with categories.xeb2402 (Novax Centre) and categories.bab2404 (Artemis Satellite Control). M28's AddUnitToBigThreatTable then registers any visible satellite-centre as a nuke launcher, which triggers the existing SMD-build logic in core base zones. The mod's modified T3 SMDs carry an AntiSat weapon, so an SMD is the correct defensive response to a satellite-centre on the map.

**M28 AI satellite retreat under fire:**
- hook/mods/M28AI/lua/AI/M28Events.lua (new): wraps OnDamaged. When an M28-owned satellite (refCategorySatellite — Novax xea0002 + Artemis baa0401) takes damage from an enemy unit, the hook resolves the attacker, computes a retreat position 120 ogrids away from the attacker on the line through the satellite (SMD EffectiveRadius=90 + 30 buffer), and issues IssueMove. Damage events are throttled to one IssueMove per 2 seconds; every hit extends a 15-second "do not re-target" window via the BO_SatRetreatUntil flag.
- hook/mods/M28AI/lua/AI/M28Air.lua (new): two-part NovaxCoreTargetLoop wrap. Part 1 short-circuits while BO_SatRetreatUntil is in the future, so M28Air doesn't immediately countermand the retreat IssueMove with a fresh attack order. Part 2 runs after the original picks a target: if the target sits within (90 SMD range + 32 sat attack range + 8 buffer = 130 ogrids) of any known enemy SMD, the order is overridden. If the satellite itself is also in or near SMD range, it is moved to 120 ogrids out on the line from the SMD; otherwise the attack order is just cleared so the sat doesn't fly toward danger. The refoNovaxLastTarget reference is cleared so the next loop iteration doesn't relock onto the same dangerous target. Net effect: satellites stop ping-ponging in and out of SMD coverage once the SMD has been spotted (typically after the first hit).

**M28 AI Novax-Centre satellite-launch watchdog:**
- hook/mods/M28AI/lua/AI/M28Events.lua: wraps OnConstructed for M28-owned Novax Centres (refCategoryNovaxCentre, i.e. xeb2402). Forks a periodic check (every 15s, starting 5s after completion) that detects when the Centre is stuck — fraction complete=1, command queue empty, work progress=0, state Idle/Building — and no satellite is attached (oCentre.Satellite is nil or invalid). In that case the hook issues IssueClearCommands + IssueBuildFactory({centre}, 'xea0002', 1) to unblock the Centre. Observed in game_27045480.log where a freshly built Novax Centre stayed idle for >200 ticks without ever launching its satellite, likely because the script-side state (OpenState/Extend auto-spawn) and the engine factory-queue state desynchronised.

**Cleanup (no behavior change except Sorian-AI):**
- Removed dead backup: lua/OldEffectTemplateBackup.lua (4309 lines, zero imports).
- Removed unused customunits tree: lua/customunits/ (31 BrewLAN-style Sorian unit-list files, all unreferenced).
- Removed orphan unit folder: units/BELK002/ (script-only, no _unit.bp, class name 'BALK002' mismatched the directory name).
- Removed model-preview cache files: units/EES0301/6qb3F.tmp.jpg, units/EES0302/qr99FA.tmp.jpg, units/ERL0301/a0995C.tmp.jpg, units/EEB0402/EEB0402_lod0.txt.
- Removed Sorian-AI defense builder extensions: hook/lua/AI/AIBuilders/SorianDefenseBuilders.lua (684 lines; latent SIBC/SBC undefined-variable bug made the conditions silent-broken anyway) and the three AddGlobalBuilderGroup calls for 'BO-SorianT3BaseDefenses', 'BO-SorianT3BaseDefenses - Emerg' and 'BO-SorianT3LightDefenses' in hook/lua/AI/AIAddBuilderTable.lua. Sorian-AI users now fall back to FAF base Sorian behavior; the 'BO-HydroCarbonUpgrade' injection is preserved.

---
## Adjustments by Punzler (10.Mai.2026)
Bugfixes and balance changes ported from BlackOpsFAF-DoomsBalanceAndPatch (v5) by Doompants.

**FAF Patch 3818 compatibility — drone carrier docking:**
- BEL0402 (Goliath): AI.StagingPlatformScanRadius=30, Transport.DockingSlots=3
- UAS0401 (Tempest): AI.StagingPlatformScanRadius=30, Transport.DockingSlots=6; tooltip corrected from 'AA Drones' to 'Gunship Drones'
- BSL0401 (Yenzotha carrier): AI.StagingPlatformScanRadius=30, Transport.DockingSlots=7
- BSA0004 (Yenzotha drone): DRONE category added to blueprint

**Drone docking logic (BlackOpsunits.lua):**
- AirDroneUnit.OnStopBeingBuilt: save/restore Carrier around parent call — FAF was wiping the Carrier reference, causing heartbeat to exit silently
- Added UndockDrone: SetImmobile(false) before DetachFrom(false), plus JustUndocked flag to block immediate re-dock
- Added SendIdleDronesToDock: sends idle undocked drones home via DroneNavigateToDock
- DroneMaintenanceState: now calls DroneNavigateToDock for damaged drones that are not yet docked
- AssignDroneTarget: now calls UndockDrone before issuing attack order
- AssistHeartBeat: idle beat counter triggers SendIdleDronesToDock after ~2s with no valid target

**BEA0006 (Goliath drone):**
- Returning flag docking system: DroneNavigateToDock sets Returning=true, OnMotionHorzEventChange attaches on Stopped+Returning
- DroneLinkHeartbeat continuously re-issues IssueMove to current bone position so a walking Goliath doesn't strand drones on terrain

**BAA0001 (Tempest drone):**
- Sink-through-hull fix: docking intercept now runs BEFORE AirUnit parent call to block the layer transition to water
- JustUndocked guard prevents immediate re-dock when UndockDrone releases the drone at water level

**BSA0004 (Yenzotha drone):**
- Same Returning flag docking system as BEA0006: DroneNavigateToDock + OnMotionHorzEventChange intercept + DroneLinkHeartbeat tracking

**UAS0401 (Tempest):**
- OnKilled chain fixed: KillThread+DeadState+KillAllDrones before ASeaUnit.OnKilled — Tempest was freezing on fatal damage instead of sinking
- IsValidDroneTarget override: excludes air-layer targets — drones have no working air weapon, dispatching them at air units blocked docking indefinitely

**BSB2402 (Seraphim Quantum Rift Archway):**
- OnFailedToBuild: FactoryBuildFailed now explicitly cleared after parent call — factory was permanently stalled until the next build order arrived

**EEB0402 (Philly Stellar Generator):**
- Economy.RebuildBonusIds = { 'eeb0402' } added — wreckage was not rebuildable

**EES0301 (Seawolf Advanced Tactical Submarine):**
- Hitbox: SizeX/SizeY 0.7->0.9 — torpedoes and projectiles were passing through the unit
- Concussion torpedo ring radii: inner 0.5->3, outer 1.5->5 — FAF NukeDamage refactor broke the old PassData pipeline, causing 0-damage hits and log spam

**Crash damage normalization:**
- UAA0310 (CZAR): DeathImpact.Damage 16000->7000
- BEA0402 (Citadel MKII): DeathImpact.Damage 10880->7000

**XEA0002 (Novax Defense Satellite) + XEB2402 (Novax Control Center):**
- XEA0002: UNTARGETABLE removed so BlackOps SMD anti-satellite weapon can target it; Health 100->7000 (~14 SMD shots to kill); BUILTBYNOVAX category added; SizeY/CollisionOffsetY adjusted for reliable missile collision
- XEB2402: BuildableCategory "SATELLITE"->"BUILTBYNOVAX" — prevents the BlackOps Artemis satellite (BAA0401) from appearing as a build option in the Novax Center

**Balance:**
- BAB2306 (Aria T3 PD): Damage 50->41 (unavoidable beam + top DPS + top range was uncompetitive to play against)
- BSB2306 (Uttuathuum T3 PD): Damage 600->1050 (underpowered against swarms)
- AT-tower T3 (BAB0003, BEB0003, BRB0006, BSB0003): NoTeleDistance 56->65
- AT-tower T2 (BAB0004, BEB0004, BRB0007, BSB0006): NoTeleDistance 25->30
- AT-tower 4209 variants: MaintenanceConsumptionPerSecondEnergy 350->750
- AT-tower 4309 variants: MaintenanceConsumptionPerSecondEnergy 1200->5000

---
## Adjustments by Punzler (10.Mai.2026)
**M28AI — Hydrocarbon power plant upgrades (T1→T2→T3):**
- Root cause: `ConsiderHydroUpgradeLoop` called `UpgradeUnit(oUnit, false)`, setting
  `bUpdateUpgradeTracker=false`. Inside `UpgradeUnit` the entire `IssueTrackedUpgrade`
  block is gated on this flag — so `IssueUpgrade` was **never sent to the engine**.
- Fix A (`hook/mods/M28AI/lua/AI/M28Economy.lua`): wraps `UpgradeUnit`; forces
  `bUpdateUpgradeTracker=true` when the unit is a `HYDROCARBON` structure, so
  `IssueTrackedUpgrade` is reached and `IssueUpgrade` is actually sent.
- Fix B (`hook/mods/M28AI/lua/AI/M28UnitInfo.lua`): wraps global
  `GetUnitUpgradeBlueprint`; returns the upgrade ID directly via `UpgradesTo`/
  `UpgradesFrom` cross-check when `CanBuild()` fails, preventing the unnecessary
  `refbTriedIgnoringCanBuildForUpgrade` fallback path.
- Existing `hook/lua/sim/Unit.lua` (`CheckBuildRestriction` override) is now
  actually reached for the first time and correctly allows the upgrade.
---
## Adjustments by Punzler (09.Mai.2026)
- fixed multiplayer desinc with Total Mayhem
- Unit eeb0402 (Stellar Generator) rebalanced:
  - Health: 50000 -> 10000
  - MaxHealth: 50000 -> 10000
  - ShieldMaxHealth: 4000 -> 40000
  - ShieldRegenRate: 55 -> 200
  - ProductionPerSecondEnergy: 2501 -> 5501
  - ProductionPerSecondMass: 25 -> 75
- BAA0401 — Artemis (Experimental Satellite) fixed Range
  - BeamGun (Z. 255) and ArtemisCannon (Z. 356) set MaxRadius = 3 -> 7
---
## v26 (21.Apr.2025)

- Added Annotations (MrRowey)
- Speed up functions (MrRowey)
- Fixed CreateProjectileAtMuzzle hooks by returning the projectile to parent function
- Unit bea0402 (Experimental Aerial Fortress) now has a dummy weapon to attack enemies directly below.
- Unit bea0402 (Experimental Aerial Fortress) UISelection from tank tp air unit (thanks to DJ_Calaco)

---

## v25 (02.Nov.2024)

Fixes by Basilisk3:
- Unit bes0402 (Experimental Dreadnaught) Hitbox enlarged downwards so that torpedoes can hit the unit more effectively
- Unit uaa0310 (Experimental Aircraft Carrier) Add switch and fix animation for Superweapon

Fixes by Uveso:
- fixed SorianDefenseBuilders.lua (removed dependency for sorian buildconditions)
- fixed TransportClass on several units
- GargEMPWarhead01_proj.bp fix DesiredShooterCap not matching health
- ArtemisCannon02_proj.bp fix DesiredShooterCap not matching health
- Unit eeb0402 (Stellar Generator) Hitbox enlarged downwards so that torpedoes can hit the unit more effectively
- Unit uaa0310 (Experimental Aircraft Carrier) Add shield from FAF CZAR
- Unit bal0206 (Medium Assault Tank) fix collision box
- Unit bel9010 (Jammer Crystal) fix collision box

---

## v24 (21.Aug.2023)

Fixes by Uveso:
- fixed an issue where drones where able to target non unit entities

Fixes by Jip:
- Unit bel0402 (Experimental Assault Bot) fixed issue with drones
- Unit uas0401 (Experimental Battleship) fixed issue with drones
- Unit bsl0401 (Experimental Hover Tank) fixed issue with drones

Fixes by Balthazar:
- Unit xsb1102 (Hydrocarbon Power Plant) was not buildable on tech 1
- Unit urb1102 (Hydrocarbon Power Plant) was not buildable on tech 1
- Unit uab1102 (Hydrocarbon Power Plant) was not buildable on tech 1
- Unit ueb1102 (Hydrocarbon Power Plant) was not buildable on tech 1

---

## v23 (05.May.2023)

- fixed a incompatibility with BrewLAN (Thanks to Balthazar)
- fixed a bug in case a air weapon has no RangeCategory UWRC_AntiAir

---

## v22 (03.May.2023)
Thanks to Balthazar who provided this patch.

- fixed a incompatibility with BrewLAN (missing SizeZ on units)

---

## v21 (24.Apr.2023)
Thanks to Jip who provided this patch.

- Unit baa0309 Illuminate - (T3 Air Transport) fix for cloak
- Unit beb4209 ATF-205 Preventer - (Anti-Teleport Field Tower) fix for cloak
- Unit bab4309 Quantum Wake Generator - (Anti-Teleport Generator) fix for cloak
- Unit brb4309 Shroud - (Anti-Teleport Tower) fix for cloak
- Unit bsb4309 Haazthue-Uhthena - (Anti-Teleport Tower) fix for cloak
- Unit beb4309 ATF-305 Preventer - (Anti-Teleport Field Tower) fix for cloak
- Unit brb4209 Mist - (Anti-Teleport Tower) fix for cloak
- Unit bsb4209 Haazthue-Uhthena - (Anti-Teleport Tower) fix for cloak
- Unit bab4209 Quantum Wake Generator - (Anti-Teleport Generator) fix for cloak
- drones no longer checks for target.Dead ~= nil; (it is sometimes false, not nil)

---

## v20 (21.Aug.2022)

- added missing translation tags in tooltip.lua
- added german translation (translation by John kobo)
- Unit bsl0310 (Lambda Equipped Assault Bot) Added StandUpright = true,
- Unit bsb2402 (Seraphim Quantum Rift Archway) Changed General.TechLevel from "RULEUTL_Basic" to "RULEUTL_Experimental"
- Unit bab1302 (Hydrocarbon Power Plant) Changed General.TechLevel from "RULEUTL_Basic" to "RULEUTL_Secret"
- Unit beb4309 (Anti-Teleport Field Tower) Changed General.TechLevel from "RULEUTL_Advanced" to "RULEUTL_Secret"
- Unit bab2404 (Artemis Satelite Control) Changed General.TechLevel from "RULEUTL_Secret" to "RULEUTL_Experimental"
- Unit beb1302 (Hydrocarbon Power Plant) Changed General.TechLevel from "RULEUTL_Basic" to "RULEUTL_Secret"
- Unit brb5205 (Advanced Air Staging Facility) Fixed Display.Abilities.
- Unit bss0401 (Experimental Dreadnought) Changed Damage for weapon (Hu Strategic Missile Defense) from 30 to 30000.
- Unit bra0309 (T3 Air Transport) Added missing transport capacity variable (Class1Capacity = 16,)
- Unit bsa0309 (Tech3 Air Transport) Added missing transport capacity variable (Class1Capacity = 32,)
- Unit bra0409 (Experimental Assault Transport) Added missing transport capacity variable (Class1Capacity = 20,)
- Unit baa0309 (T3 Air Transport) Added missing transport capacity variable (Class1Capacity = 24,)
- Unit bab2308 (Tactical Missile Launcher) fixed no damage on AMissileSerpentineProjectile

---

## v19 (22.Dec.2020)

- Unit UAA0310 Added VeteranMassMult = 0.5, to blueprint for propper veterancy calculation
- Unit UAS0401 Added VeteranMassMult = 0.5, to blueprint for propper veterancy calculation

- Unit BAA0309 Added TeleportDelay = 10, to blueprint to match FAF patch
- Unit BSB4209 Added TeleportDelay = 10, to blueprint to match FAF patch
