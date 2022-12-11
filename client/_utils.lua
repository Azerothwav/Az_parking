_Utils = {}
ESX	= nil
PlayerData = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(5)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(50)
	end
	PlayerData = ESX.GetPlayerData()
	DoScreenFadeOut(10)
	DoScreenFadeIn(10)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

_Utils.SendNotification = function(message, type)
	exports.pNotify:SendNotification({
		text = message,
		type = type,
		queue = "az_parking",
	})
end

_Utils.SetFuel = function(vehicle, value)
	if Config.UseLegacyFuel then
		exports[Config.LegacyFuelResName]:SetFuel(vehicle, value + 0.0) 
	else
		SetVehicleFuelLevel(vehicle, value + 0.0)
	end
end

_Utils.GetFuel = function(vehicle)
	if Config.UseLegacyFuel then
		return exports[Config.LegacyFuelResName]:GetFuel(vehicle)
	else
		return ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1) or 0
	end
end

-- Draw 3D Text inGAME
_Utils.Draw3DText = function(x, y, z, textInput, fontId, scaleX, scaleY)
	local px, py, pz = table.unpack(GetGameplayCamCoords())
	local dist       = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)    
	local scale      = (1 / dist) * 20
	local fov        = (1 / GetGameplayCamFov()) * 100
	local scale      = scale * fov   
	SetTextScale(scaleX * scale, scaleY * scale)
	SetTextFont(fontId)
	SetTextProportional(1)
	SetTextColour(250, 250, 250, 255)
	SetTextDropshadow(1, 1, 1, 1, 255)
	SetTextEdge(2, 0, 0, 0, 150)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(textInput)
	SetDrawOrigin(x, y, z + 2, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

-- Show GTAV Default help text
_Utils.DisplayHelpText = function(text)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

_Utils.Round = function(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

_Utils.Trim = function(value)
	if value then
		return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
	else
		return nil
	end
end

_Utils.GetVehicleName = function(vehicleData, vehicleHash)
	if vehicleData[Config.VehicleNameColumn] then
		-- CUSTOM USER NAME
		return vehicleData[Config.VehicleNameColumn]
	elseif vehicleData.model then
		-- GET CAR MODEL FROM DB
		return vehicleData.model
	else
		-- GET CAR NAME FROM DEFAULT GTAV GAME NAME
		return GetDisplayNameFromVehicleModel(vehicleHash)
	end
end

_Utils.GetVehicles = function()
	local vehicles = {}
	
	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end
	
	return vehicles
end

_Utils.GetVehiclesInArea = function(coords, area)
	local vehicles = _Utils.GetVehicles()
	local vehiclesInArea = {}
	
	for i=1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance      = GetDistanceBetweenCoords(vehicleCoords, coords.x, coords.y, coords.z, true)
		
		if distance <= area then
			table.insert(vehiclesInArea, vehicles[i])
		end
	end
	
	return vehiclesInArea
end

_Utils.GetVehiclePlate = function(vehicle)
	return _Utils.Trim(GetVehicleNumberPlateText(vehicle))
end

_Utils.GetDuplicateVehicleCloseby = function(plate, coords, area)
	local vehicles = _Utils.GetVehiclesInArea(coords, area)
	for i,v in ipairs(vehicles) do
		if _Utils.Trim(GetVehicleNumberPlateText(v)) == plate then
			return v
		end
	end
	return false
end


_Utils.IsTableEmpty = function(self)
	if self == nil then
		return true
	end
	for _, _ in pairs(self) do
		return false
	end
	return true
end
   
_Utils.DoesAPlayerDrivesCar = function(plate)
	local isVehicleTaken = false
	local players = ESX.Game.GetPlayers()
	for i = 1, #players, 1 do
	   local target = GetPlayerPed(players[i])
	   if target ~= PlayerPedId() then
		  local plate1 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, true))
		  local plate2 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, false))
		  if plate == plate1 or plate == plate2 then
			 isVehicleTaken = true
			 break
		  end
	   end
	end
	return isVehicleTaken
 end
 
 _Utils.GetVehicleProperties = function(vehicle)
	if (not DoesEntityExist(vehicle)) then return end

	local colorPrimary, colorSecondary = GetVehicleColours(vehicle)

	local color1Custom = {}
	color1Custom[1], color1Custom[2], color1Custom[3] = GetVehicleCustomPrimaryColour(vehicle)
	
	local color2Custom = {}
	color2Custom[1], color2Custom[2], color2Custom[3] = GetVehicleCustomSecondaryColour(vehicle)

	local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
	local extras = {}

	for extraId = 0, 25 do
		if DoesExtraExist(vehicle, extraId) then
			local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
			extras[tostring(extraId)] = state
		end
	end

	local saveFuelLevel = _Utils.GetFuel(vehicle)
	
	local props = {
		model             = GetEntityModel(vehicle),
		
		plate             = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
		plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),
		
		bodyHealth        = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
		engineHealth      = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),
		tankHealth        = ESX.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),
		
		fuelLevel         = saveFuelLevel,
		dirtLevel         = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),

		color1            = colorPrimary,
		color1Custom      = color1Custom,

		color2            = colorSecondary,
		color2Custom      = color2Custom,

		color1Type 		  = GetVehicleModColor_1(vehicle),
		color2Type 		  = GetVehicleModColor_2(vehicle),
		
		pearlescentColor  = pearlescentColor,
		wheelColor        = wheelColor,
		
		wheels            = GetVehicleWheelType(vehicle),
		windowTint        = GetVehicleWindowTint(vehicle),
		xenonColor        = GetVehicleXenonLightsColour(vehicle),
		
		neonEnabled       = {
			IsVehicleNeonLightEnabled(vehicle, 0),
			IsVehicleNeonLightEnabled(vehicle, 1),
			IsVehicleNeonLightEnabled(vehicle, 2),
			IsVehicleNeonLightEnabled(vehicle, 3)
		},
		
		neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
		extras            = extras,
		tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),
		
		modSpoilers       = GetVehicleMod(vehicle, 0),
		modFrontBumper    = GetVehicleMod(vehicle, 1),
		modRearBumper     = GetVehicleMod(vehicle, 2),
		modSideSkirt      = GetVehicleMod(vehicle, 3),
		modExhaust        = GetVehicleMod(vehicle, 4),
		modFrame          = GetVehicleMod(vehicle, 5),
		modGrille         = GetVehicleMod(vehicle, 6),
		modHood           = GetVehicleMod(vehicle, 7),
		modFender         = GetVehicleMod(vehicle, 8),
		modRightFender    = GetVehicleMod(vehicle, 9),
		modRoof           = GetVehicleMod(vehicle, 10),
		
		modEngine         = GetVehicleMod(vehicle, 11),
		modBrakes         = GetVehicleMod(vehicle, 12),
		modTransmission   = GetVehicleMod(vehicle, 13),
		modHorns          = GetVehicleMod(vehicle, 14),
		modSuspension     = GetVehicleMod(vehicle, 15),
		modArmor          = GetVehicleMod(vehicle, 16),
		
		modTurbo          = IsToggleModOn(vehicle, 18),
		modSmokeEnabled   = IsToggleModOn(vehicle, 20),
		modXenon          = IsToggleModOn(vehicle, 22),
		
		modFrontWheels    = GetVehicleMod(vehicle, 23),
		modBackWheels     = GetVehicleMod(vehicle, 24),
		
		modPlateHolder    = GetVehicleMod(vehicle, 25),
		modVanityPlate    = GetVehicleMod(vehicle, 26),
		modTrimA          = GetVehicleMod(vehicle, 27),
		modOrnaments      = GetVehicleMod(vehicle, 28),
		modDashboard      = GetVehicleMod(vehicle, 29),
		modDial           = GetVehicleMod(vehicle, 30),
		modDoorSpeaker    = GetVehicleMod(vehicle, 31),
		modSeats          = GetVehicleMod(vehicle, 32),
		modSteeringWheel  = GetVehicleMod(vehicle, 33),
		modShifterLeavers = GetVehicleMod(vehicle, 34),
		modAPlate         = GetVehicleMod(vehicle, 35),
		modSpeakers       = GetVehicleMod(vehicle, 36),
		modTrunk          = GetVehicleMod(vehicle, 37),
		modHydrolic       = GetVehicleMod(vehicle, 38),
		modEngineBlock    = GetVehicleMod(vehicle, 39),
		modAirFilter      = GetVehicleMod(vehicle, 40),
		modStruts         = GetVehicleMod(vehicle, 41),
		modArchCover      = GetVehicleMod(vehicle, 42),
		modAerials        = GetVehicleMod(vehicle, 43),
		modTrimB          = GetVehicleMod(vehicle, 44),
		modTank           = GetVehicleMod(vehicle, 45),
		modWindows        = GetVehicleMod(vehicle, 46),
		modLivery         = GetVehicleMod(vehicle, 48),
		livery            = GetVehicleLivery(vehicle)
	}
	
	props.tyres = {}
	props.windows = {}
	props.doors = {}
	
	for id = 1, 7 do
		local tyreId = IsVehicleTyreBurst(vehicle, id, false)
		
		if tyreId then
			props.tyres[#props.tyres + 1] = tyreId
			
			if tyreId == false then
				tyreId = IsVehicleTyreBurst(vehicle, id, true)
				props.tyres[#props.tyres] = tyreId
			end
		else
			props.tyres[#props.tyres + 1] = false
		end
	end
	
	for id = 1, 13 do
		local windowId = IsVehicleWindowIntact(vehicle, id)
		
		if windowId ~= nil then
			props.windows[#props.windows + 1] = windowId
		else
			props.windows[#props.windows + 1] = true
		end
	end
	
	for id = 0, 5 do
		local doorId = IsVehicleDoorDamaged(vehicle, id)
		
		if doorId then
			props.doors[#props.doors + 1] = doorId
		else
			props.doors[#props.doors + 1] = false
		end
	end
	
	props.vehicleHeadLight  = GetVehicleHeadlightsColour(vehicle)
	
	return props
end

_Utils.SetVehicleProperties = function(vehicle, props)
	if DoesEntityExist(vehicle) then
		SetVehicleModKit(vehicle, 0)
		SetVehicleAutoRepairDisabled(vehicle, false)
		
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		
		if (props.color1) then
			ClearVehicleCustomPrimaryColour(vehicle)
	
			local color1, color2 = GetVehicleColours(vehicle)
			SetVehicleColours(vehicle, props.color1, color2)
		end
	
		if (props.color1Custom) then
			SetVehicleCustomPrimaryColour(vehicle, props.color1Custom[1], props.color1Custom[2], props.color1Custom[3])
		end
	
		if (props.color2) then
			ClearVehicleCustomSecondaryColour(vehicle)
	
			local color1, color2 = GetVehicleColours(vehicle)
			SetVehicleColours(vehicle, color1, props.color2)
		end
	
		if (props.color2Custom) then
			SetVehicleCustomSecondaryColour(vehicle, props.color2Custom[1], props.color2Custom[2], props.color2Custom[3])
		end

		if (props.color1Type) then
			SetVehicleModColor_1(vehicle, props.color1Type)
		end
	
		if (props.color2Type) then
			SetVehicleModColor_2(vehicle, props.color2Type)
		end

		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
		if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor) end
		if props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor) end
		if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
		if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
		
		if props.neonEnabled then
			SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
			SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
			SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
			SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
		end
		
		if props.extras then
			for extraId,enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(extraId), 0)
				else
					SetVehicleExtra(vehicle, tonumber(extraId), 1)
				end
			end
		end
		
		if props.neonColor ~= nil then
			if not props.neonColor[1] then
				SetVehicleNeonLightsColour(vehicle, props.neonColor["1"], props.neonColor["2"], props.neonColor["3"])
			else
				SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
			end
		end
		
		if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) end
		
		if props.tyreSmokeColor ~= nil then
			if not props.tyreSmokeColor[1] then
				SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor["1"], props.tyreSmokeColor["2"], props.tyreSmokeColor["3"])
			else
				SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
			end
		end
		
		if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
		if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
		if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
		if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
		if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
		if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
		if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
		if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
		if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
		if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
		if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
		if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
		if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
		if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
		if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
		if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
		if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
		if props.modTurbo then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
		if props.modXenon then ToggleVehicleMod(vehicle,  22, props.modXenon) end
		if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
		if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
		if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
		if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
		if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
		if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
		if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
		if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
		if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
		if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
		if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
		if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
		if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
		if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
		if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
		if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
		if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
		if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
		if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
		if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
		if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
		if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
		if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
		if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end
		
		if (props.modLivery) then
			SetVehicleMod(vehicle, 48, props.modLivery, false)
		end
	
		if (props.livery) then
			SetVehicleLivery(vehicle, props.livery)
		end
		
		if props.windows then
			for windowId = 1, 9, 1 do
				if props.windows[windowId] == false then
					SmashVehicleWindow(vehicle, windowId)
				end
			end
		end
		
		if props.tyres then
			for tyreId = 1, 7, 1 do
				if props.tyres[tyreId] ~= false then
					SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
				end
			end
		end
		
		if props.doors then
			for doorId = 0, 5, 1 do
				if props.doors[doorId] ~= false then
					SetVehicleDoorBroken(vehicle, doorId - 1, true)
				end
			end
		end
		if props.vehicleHeadLight then SetVehicleHeadlightsColour(vehicle, props.vehicleHeadLight) end

		if props.fuelLevel then 
			_Utils.SetFuel(vehicle, props.fuelLevel)	
		end
	end
end

_Utils.GetCarSpawnDistance = function(vehicle)
	if vehicle.pound then
		local goToPos = GetNearestWarehouse()
		if goToPos then
			return CalculateTravelDistanceBetweenPoints(vector3(goToPos.x, goToPos.y, goToPos.z), GetEntityCoords(PlayerPedId()))..'m'
		else
			return 0
		end
	elseif vehicle.stored and vehicle.garage_type == Config.RealParking.Type and vehicle.location then
		local parkingLocation = json.decode(vehicle.location)
		return CalculateTravelDistanceBetweenPoints(vector3(parkingLocation.x, parkingLocation.y, parkingLocation.z), GetEntityCoords(PlayerPedId()))..'m'
	elseif vehicle.stored and _Garages[vehicle.garage_name] and _Garages[vehicle.garage_name].spawn then
		local garageLocation = _Garages[vehicle.garage_name].spawn
		return CalculateTravelDistanceBetweenPoints(vector3(garageLocation.x, garageLocation.y, garageLocation.z), GetEntityCoords(PlayerPedId()))..'m'
	else
		local goToPos = GetNearestRecoverPoint()
		if goToPos then
			return CalculateTravelDistanceBetweenPoints(vector3(goToPos.x, goToPos.y, goToPos.z), GetEntityCoords(PlayerPedId()))..'m'
		else
			return 0
		end
	end
	return 0
end

_Utils.GenerateVehicleLabel = function(vehicle)
	local props = json.decode(vehicle.vehicle)
	local vehiclename = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
	local plate = "<span style='color:#d1af15;font-weight:bold;margin: 0 10px'>[".._Utils.Trim(vehicle.plate).."]</span>"
	if vehicle.pound then
		return  "<div style='display:flex'>"..vehiclename..plate.."</div>"
	elseif vehicle.stored and vehicle.garage_type == Config.RealParking.Type then
		return "<div style='display:flex'>"..vehiclename..plate.."</div>"
	elseif vehicle.stored then
		return "<div style='display:flex'>"..vehiclename..plate.."</div>"
	else
		return "<div style='display:flex'>"..vehiclename..plate.."</div>"
	end
end

_Utils.GenerateVehicleLabelWithDistance = function(vehicle)
	if vehicle.pound then
		return  _Utils.GenerateVehicleLabel(vehicle).."<span style='color:"..Config.Colors.pound.."'>".._U('pound') .. "</span>"
	elseif vehicle.stored and vehicle.garage_type == Config.RealParking.Type then
		return _Utils.GenerateVehicleLabel(vehicle).."<div><span style='color:"..Config.Colors.parking.."'>".._U('parking') .. "</span> • ".._Utils.GetCarSpawnDistance(vehicle)..'</div>'
	elseif vehicle.stored then
		return _Utils.GenerateVehicleLabel(vehicle).."<div><span style='color:"..Config.Colors.stored.."'>".._U('stored') .. "</span> • ".._Utils.GetCarSpawnDistance(vehicle)..'</div>'
	else
		return _Utils.GenerateVehicleLabel(vehicle).."<div><span style='color:"..Config.Colors.outside.."'>".._U('outside') .. "</span> • ".._Utils.GetCarSpawnDistance(vehicle)..'</div>'
	end
end

_Utils.IncludeJob = function(authorizedJobs, job, job2) 
	print(authorizedJobs)
	if authorizedJobs == nil or job == nil or job2 == nil then return true end
	for key,value in pairs(authorizedJobs) do
		if value == job or 'off'..value == job then
			return key
		end
		if value == job2 or 'off'..value == job2 then
			return key
		end
	end
	return false
end

_Utils.FindIndex = function(array, string) 
	if string == nil then return true end
	for key,value in pairs(array) do
		if value == string then
			return key
		end
	end
	return false
end

_Utils.Includes = function(array, search) 
	for key, value in pairs(array) do
		if value == search then
			return key
		end
	end
	return false
end