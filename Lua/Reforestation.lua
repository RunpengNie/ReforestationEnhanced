-- Reforestation
-- Author: FramedArchitecture
-- Extended by: Jerry Nie
--------------------------------------------------------------------
local bExpansion2         = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY)

local plantForestID       = GameInfoTypes["IMPROVEMENT_PLANT_FOREST"]
local plantJungleID       = GameInfoTypes["IMPROVEMENT_PLANT_JUNGLE"]

local forestTechInfo      = GameInfo.Technologies["TECH_CIVIL_SERVICE"]
local jungleTechInfo      = GameInfo.Technologies["TECH_CIVIL_SERVICE"]
local chemistryTechInfo   = GameInfo.Technologies["TECH_CHEMISTRY"]

local random              = math.random
local resources           = {}
--------------------------------------------------------------------
function OnUpdateForests(playerID, x, y, improvementID)
    local plot = Map.GetPlot(x, y)

    if improvementID == plantForestID then
        PlantForest(plot)
    elseif improvementID == plantJungleID then
        PlantJungle(plot)
    end
end
--------------------------------------------------------------------
function OnMapUpdateForests()
    local n = Map.GetNumPlots() - 1
    for i = 0, n do
        local plot = Map.GetPlotByIndex(i)
        local impID = plot:GetImprovementType()

        if impID == plantForestID then
            PlantForest(plot)
        elseif impID == plantJungleID then
            PlantJungle(plot)
        end
    end
end
--------------------------------------------------------------------
function OnChemistryResearched(teamID, techID)
    if chemistryTechInfo and (techID == chemistryTechInfo.ID) then
        -- Remove slow versions of builds, keeping only fast versions
        DB.Query("DELETE FROM Unit_Builds WHERE BuildType = 'BUILD_FOREST'")
        DB.Query("DELETE FROM Unit_Builds WHERE BuildType = 'BUILD_JUNGLE'")
        
        -- Remove this listener once Chemistry is researched
        GameEvents.TeamTechResearched.Remove(OnChemistryResearched)
    end
end
--------------------------------------------------------------------
function OnTechResearched(teamID, techID)
    if forestTechInfo and (techID == forestTechInfo.ID) then
        Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
    end
    if jungleTechInfo and (techID == jungleTechInfo.ID) then
        Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
    end

    -- Remove once both are researched
    if (forestTechInfo == nil or Teams[teamID]:IsHasTech(forestTechInfo.ID)) and
       (jungleTechInfo == nil or Teams[teamID]:IsHasTech(jungleTechInfo.ID)) then
        GameEvents.TeamTechResearched.Remove(OnTechResearched)
    end
end
--------------------------------------------------------------------
function PlantForest(plot)
    plot:SetImprovementType(-1)
    plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1)

    if (RandomInteger() <= 10) then
        local resourceInfo = GameInfo.Resources[resources[random(#resources)]]
        if resourceInfo then
            plot:SetResourceType(resourceInfo.ID, 1)
        end
    end
end
--------------------------------------------------------------------
function PlantJungle(plot)
    plot:SetImprovementType(-1)
    plot:SetFeatureType(FeatureTypes.FEATURE_JUNGLE, -1)

    if (RandomInteger() <= 6) then
        local resourceInfo = GameInfo.Resources[resources[random(#resources)]]
        if resourceInfo then
            plot:SetResourceType(resourceInfo.ID, 1)
        end
    end
end
--------------------------------------------------------------------
function RandomInteger(min, max)
    local min = min or 1
    local max = max and ((max - min) + 1) or 100
    return min + Game.Rand(max, "")
end
--------------------------------------------------------------------
function Initialize()
    if bExpansion2 then
        GameEvents.BuildFinished.Add(OnUpdateForests)
    elseif forestTechInfo or jungleTechInfo then
        local bInitialized = false
        if forestTechInfo and Teams[Game.GetActiveTeam()]:IsHasTech(forestTechInfo.ID) then
            Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
            bInitialized = true
        end
        if jungleTechInfo and Teams[Game.GetActiveTeam()]:IsHasTech(jungleTechInfo.ID) then
            Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
            bInitialized = true
        end
        if not bInitialized then
            GameEvents.TeamTechResearched.Add(OnTechResearched)
        end
    end
    
    -- Listen for Chemistry tech to switch to fast builds
    if chemistryTechInfo and not Teams[Game.GetActiveTeam()]:IsHasTech(chemistryTechInfo.ID) then
        GameEvents.TeamTechResearched.Add(OnChemistryResearched)
    end
end
Initialize()
