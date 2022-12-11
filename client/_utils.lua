_Utils = {}

_Utils.ActiveKeyboard = function(titre, taille)
	DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", "", "", "", "", taille)
	input = true
	while input do
		if input == true then
			HideHudAndRadarThisFrame()
			if UpdateOnscreenKeyboard() == 3 then
				input = false
			elseif UpdateOnscreenKeyboard() == 1 then
				local inputText = GetOnscreenKeyboardResult()
				if string.len(inputText) > 0 then
					input = false
					return inputText
				else
					DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", "", "", "", "", taille)
				end
			elseif UpdateOnscreenKeyboard() == 2 then
				input = false
			end
		end
		Citizen.Wait(0)
	end
end

_Utils.CanAccessGarage = function(jobname)
	local haveTheJob = false
	if jobname == nil or jobname == 'none' or jobname == 'civ' then
		return true
	else
		for k, v in pairs(Config.Job["name"]) do
			if v() == jobname then
				haveTheJob = true
			end
		end
		return haveTheJob
	end
end

_Utils.SpawnVehicle = function(model, spawnpos, plate, cb)
	if Config.FrameWork == "ESX" then
		ESX.Game.SpawnVehicle(model, spawnpos.xyz, spawnpos.w, function(vehicleEntity)
			Config.GiveKey(plate)
			cb(vehicleEntity)
		end)
	elseif Config.FrameWork == "QBCore" then
		QBCore.Functions.SpawnVehicle(model, function(vehicleEntity)
			SetEntityHeading(vehicleEntity, spawnpos.w)
			Config.GiveKey(plate)
			cb(vehicleEntity)
		end, spawnpos.xyz, true)
	end
end

_Utils.IsBoss = function()
	local haveTheGrade = false
	for k, v in pairs(Config.Job["grade"]) do
		if v() == "Boss" or v() == "Chief" then
			haveTheGrade = true
		end
	end
	return haveTheGrade
end

_Utils.CallBack = function(name, cb, ...)
	if Config.FrameWork == "ESX" then
		ESX.TriggerServerCallback(name, function(callback)
			cb(callback)
		end, ...)
	elseif Config.FrameWork == "QBCore" then
		QBCore.Functions.TriggerCallback(name, function(callback)
			cb(callback)
		end, ...)
	end
end

_Utils.GenerateVehicleLabel = function(vehicle, vehiclesurname)
	if Config.FrameWork == "ESX" then
		props = json.decode(vehicle.vehicle)
	elseif Config.FrameWork == "QBCore" then
		props = json.decode(vehicle.mods)
	end
	local vehiclename = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
	local plate = "[~o~".._Utils.Trim(vehicle.plate).."~s~]"
	if vehiclesurname ~= nil then
		return vehiclesurname.." - "..plate.." - [~o~"..string.upper(vehiclename).."~s~]"
	else
		return vehiclename.." - "..plate
	end
end

_Utils.IsPositionFree = function(position, range)
    local isFree = true
    local entityOnPosition = 0
    for k, entity in pairs(_Utils.EnumerateVehicles()) do
        local coords = GetEntityCoords(entity)
        if GetDistanceBetweenCoords(position, coords, true) <= range then
            isFree = false
            entityOnPosition = entity
        end
    end
    return isFree, entityOnPosition
end

_Utils.EnumerateVehicles = function()
	return GetGamePool("CVehicle")
end

_Utils.SendNotification = function(message, type)
	if Config.FrameWork == "ESX" then
		ESX.ShowNotification(message)
	elseif Config.FrameWork == "QBCore" then
		QBCore.Functions.Notify(message)
	end
end

_Utils.SetFuel = function(vehicle, value)
	if Config.UseLegacyFuel then
		exports["LegacyFuel"]:SetFuel(vehicle, value + 0.0) 
	else
		SetVehicleFuelLevel(vehicle, value + 0.0)
	end
end

_Utils.GetFuel = function(vehicle)
	if Config.UseLegacyFuel then
		return exports["LegacyFuel"]:GetFuel(vehicle)
	else
		return _Utils.Round(GetVehicleFuelLevel(vehicle), 1) or 0
	end
end

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
	local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
	local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
	local customPrimaryColor = nil
	if hasCustomPrimaryColor then
		local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
		customPrimaryColor = {r, g, b}
	end

	local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
	local customSecondaryColor = nil
	if hasCustomSecondaryColor then
		local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
		customSecondaryColor = {r, g, b}
	end
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
		
		plate             = _Utils.Trim(GetVehicleNumberPlateText(vehicle)),
		plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),
		
		bodyHealth        = _Utils.Round(GetVehicleBodyHealth(vehicle), 1),
		engineHealth      = _Utils.Round(GetVehicleEngineHealth(vehicle), 1),
		tankHealth        = _Utils.Round(GetVehiclePetrolTankHealth(vehicle), 1),
		
		fuelLevel         = saveFuelLevel,
		dirtLevel         = _Utils.Round(GetVehicleDirtLevel(vehicle), 1),

		color1            = colorPrimary,
		color1Custom      = customPrimaryColor,

		color2            = colorSecondary,
		color2Custom      = customSecondaryColor,

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
		livery            = GetVehicleLivery(vehicle),
	}

	if Config.UseAz_Vehicle then
		props["vehiclemetadata"] = exports["az_vehicle"]:getPartsVehicle(_Utils.Trim(GetVehicleNumberPlateText(vehicle)), vehicle)
	end
	
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

_Utils.SetVehicleProperties = function(vehicle, props, showvehicle)
	if DoesEntityExist(vehicle) then
		SetVehicleEngineHealth(vehicle, props["engineHealth"] and props["engineHealth"] + 0.0 or 1000.0)
		SetVehicleBodyHealth(vehicle, props["bodyHealth"] and props["bodyHealth"] + 0.0 or 1000.0)
		SetVehicleFuelLevel(vehicle, props["fuelLevel"] and props["fuelLevel"] + 0.0 or 1000.0)
		
		SetVehicleModKit(vehicle, 0)
		SetVehicleAutoRepairDisabled(vehicle, false)
		
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		
		if props.customPrimaryColor then
            SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2],
                props.customPrimaryColor[3])
        end
        if props.customSecondaryColor then
            SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2],
                props.customSecondaryColor[3])
        end
        if props.color1 then
            SetVehicleColours(vehicle, props.color1, colorSecondary)
        end
        if props.color2 then
            SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
        end
        if props.pearlescentColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
        end
        if props.wheelColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
        end

		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
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
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) end
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
			for doorId = 0, 6, 1 do
				if props.doors[doorId] ~= false then
					SetVehicleDoorBroken(vehicle, doorId - 1, true)
				end
			end
		end
		if props.vehicleHeadLight then SetVehicleHeadlightsColour(vehicle, props.vehicleHeadLight) end

		if props.fuelLevel then 
			_Utils.SetFuel(vehicle, props.fuelLevel)	
		end
		if Config.UseAz_Vehicle then
			if showvehicle and showvehicle ~= nil then
				exports["az_vehicle"]:setVehicleWithParts(props, vehicle, props.plate)
			end
		end
	end
end