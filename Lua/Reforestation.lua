-- Reforestation
-- Author: FramedArchitecture
-- DateCreated: 11/9/2012
--------------------------------------------------------------------
local bExpansion2		= ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY)
local plantForestID		= GameInfoTypes["IMPROVEMENT_PLANT_FOREST"]
local plantJungleID		= GameInfoTypes["IMPROVEMENT_PLANT_JUNGLE"]
local forestTechInfo	= GameInfo.Technologies["TECH_FERTILIZER"]
local random			= math.random
local resources			= {}
--------------------------------------------------------------------
function OnUpdateForests(playerID, x, y, improvementID)
	if (improvementID ~= plantForestID and improvementID ~= plantJungleID) then return end
	if (improvementID == plantJungleID) then
		PlantJungle(Map.GetPlot(x, y))
	elseif (improvementID == plantForestID) then
		PlantForest(Map.GetPlot(x, y))
	end
end
--------------------------------------------------------------------
function OnMapUpdateForests()
	local n = Map.GetNumPlots() - 1
	for i = 0, n do
		local plot = Map.GetPlotByIndex(i);
		if (plot:GetImprovementType() == plantForestID) then
			PlantForest(plot)
		elseif (plot:GetImprovementType() == plantJungleID) then
			PlantJungle(plot)
		end
	end
end
--------------------------------------------------------------------
function OnTechResearched(teamID, techID)
	if forestTechInfo and (techID == forestTechInfo.ID) then
		Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
		GameEvents.TeamTechResearched.Remove(OnTechResearched)
	end
end
--------------------------------------------------------------------
function HasAdjacentJungle(plot)
	-- 检查六边形的6个邻接单元格
	for direction = 0, 5 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
		if (adjacentPlot ~= nil and adjacentPlot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE) then
			return true
		end
	end
	return false
end
--------------------------------------------------------------------
function PlantForest(plot)
	plot:SetImprovementType(-1);
	plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
	if (RandomInteger() <= 8) then
		local resourceInfo = GameInfo.Resources[resources[random(#resources)]]
		if resourceInfo then
			plot:SetResourceType(resourceInfo.ID, 1);
		end
	end
end
--------------------------------------------------------------------
function PlantJungle(plot)
	-- 检查是否有邻接的jungle，如果没有则不种植
	if (not HasAdjacentJungle(plot)) then
		-- 如果没有邻接jungle，则取消改进
		plot:SetImprovementType(-1);
		return
	end
	
	plot:SetImprovementType(-1);
	plot:SetFeatureType(FeatureTypes.FEATURE_JUNGLE, -1);
	if (RandomInteger() <= 6) then
		local resourceInfo = GameInfo.Resources[resources[random(#resources)]]
		if resourceInfo then
			plot:SetResourceType(resourceInfo.ID, 1);
		end
	end
end
--------------------------------------------------------------------
function RandomInteger(min, max)
	local min = min and min or 1
	local max = max and ((max-min)+1) or 100
	return min + Game.Rand(max, "")
end
--------------------------------------------------------------------
function Initialize()
	if bExpansion2 then
		GameEvents.BuildFinished.Add(OnUpdateForests)
	elseif forestTechInfo then
		local bInitialized = false
		for i = 0, GameDefines.MAX_CIV_PLAYERS-1, 1 do
			if Teams[Players[i]:GetTeam()]:IsHasTech(forestTechInfo.ID) then	
				bInitialized = true
				break;
			end
		end

		if bInitialized then
			Events.ActivePlayerTurnStart.Add(OnMapUpdateForests)
		else
			GameEvents.TeamTechResearched.Add(OnTechResearched)
		end
	end

	for row in GameInfo.Resource_FeatureBooleans( "FeatureType = 'FEATURE_FOREST'" ) do
		table.insert(resources, row.ResourceType)
	end

	print("-- Reforestation Mod Loaded --")
end
--------------------------------------------------------------------
Initialize();