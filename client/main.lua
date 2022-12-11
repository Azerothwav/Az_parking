-- Global Variables
local CurrentParkings = {}
local ZoneVehicles  = {}
local CurrentCar = {}
local insideParkingZone = false
local inVehicle = false
local timeAdjust = 0
local runTimeAdjust = false
local lookingPrice = false

-- Init all available garages
for garageName, parking in pairs(_Parkings) do
	table.insert(ZoneVehicles, garageName)
	table.insert(CurrentParkings, garageName)
	ZoneVehicles[garageName] = {}
	CurrentParkings[garageName] = false
end

-- Handle new car parked in ZONE
RegisterNetEvent("az_parking:addVehicle")
AddEventHandler("az_parking:addVehicle", function(vehicle, garageName)
	if ZoneVehicles[garageName] ~= {} and ZoneVehicles[garageName][vehicle.plate] == nil then
		SpawnLocalVehicle(vehicle, garageName)
		return
	end
end)

-- Handle new car parked in ZONE
RegisterNetEvent("az_parking:deleteVehicle")
AddEventHandler("az_parking:deleteVehicle", function(vehicle, garageName)
	if ZoneVehicles[garageName] ~= nil and type(ZoneVehicles[garageName]) == "table" then
		for index, veh in pairs(ZoneVehicles[garageName]) do
			if veh.plate == vehicle.plate then
				DeleteLocalVehicle(veh, garageName)
				return
			end
		end	
	end
end)

-- Delete LOCAL NEAR LOCATION VEHICLE
function DeleteNearVehicle(location, garageName, plate)
	for i=1, 5 do
		local vehicle = GetClosestVehicle(location.x, location.y, location.z, 5.0)
		if plate == _Utils.Trim(GetVehicleNumberPlateText(vehicle)) then
			SetEntityAsNoLongerNeeded(vehicle)
			DeleteVehicle(vehicle)
			local tmpModel = GetEntityModel(vehicle)
			SetModelAsNoLongerNeeded(tmpModel)
			if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
			ClearAreaOfVehicles(location.x, location.y, location.z, 1.0, false, false, false, false, false)
		end
		Citizen.Wait(100)
	end
end

-- Spawn LOCAL Vehicle
local IsSpawning = false
function SpawnLocalVehicle(vehicleData, garageName)
	DeleteNearVehicle(vector3(vehicleData.location.x, vehicleData.location.y, vehicleData.location.z), garageName, vehicleData.plate)
	while IsSpawning do
		Wait(10)
	end
	if ZoneVehicles[garageName][vehicleData.plate] == nil then
		IsSpawning = true
		ESX.Game.SpawnLocalVehicle(vehicleData.props.model, vehicleData.location, vehicleData.location.h, function(generatedVeh)
			FreezeEntityPosition(generatedVeh, true)
			_Utils.SetVehicleProperties(generatedVeh, vehicleData.props)
			ZoneVehicles[garageName][vehicleData.plate] = { 
				owner = vehicleData.owner, 
				plate = vehicleData.plate, 
				entity = generatedVeh, 
				location = vehicleData.location, 
				garageName = garageName 
			}
			Wait(10)
			SetVehicleOnGroundProperly(generatedVeh)
			SetEntityAsMissionEntity(generatedVeh, true, true)
			SetModelAsNoLongerNeeded(vehicleData.props.model)
			SetEntityInvincible(generatedVeh, true)
			Wait(1)
			if not vehicleData.owner or vehicleData.owner ~= PlayerData.identifier then
				SetVehicleDoorsLocked(generatedVeh, 2)
			end			
			IsSpawning = false
		end)
	end
end

-- Spawn PARKING ZONE vehicles
function SpawnLocalParking(garageName)	
	ESX.TriggerServerCallback('az_parking:getZoneVehicles', function(vehicles)
		for index, vehicle in pairs(vehicles) do
			SpawnLocalVehicle(vehicle, garageName)
			Wait(5)
		end
	end, garageName)
end

-- Remove LOCAL VEHICLE from SPAWNED VEHICLES
function DeleteLocalVehicle(vehicle, garageName)
	SetModelAsNoLongerNeeded(vehicle.entity)	
	DeleteVehicle(vehicle.entity)
	if DoesEntityExist(vehicle.entity) then DeleteEntity(vehicle.entity) end
	ZoneVehicles[garageName][vehicle.plate] = nil
	ClearAreaOfVehicles(vehicle.location.x, vehicle.location.y, vehicle.location.z, 2.5, false, false, false, false, false)
end

-- Remove ALL VEHICLES from parking
function CleanParkingVehicles(garageName)
	if ZoneVehicles[garageName] then
		for index, vehicle in pairs(ZoneVehicles[garageName]) do
			DeleteLocalVehicle(vehicle, garageName)
		end
		ZoneVehicles[garageName] = {}
	end
end

-- Check USER CURRENT PARKINGS and clean other parkings vehicles
function CleanOtherParkings()
	for index, garageName in pairs(CurrentParkings) do
		if not CurrentParkings[garageName] then
			CleanParkingVehicles(garageName)
		end
	end
end 

-- Return Spawned vehicle if it is parked.
function GetStoredCar(vehicle, garageName)
	local vehicleProps = _Utils.GetVehicleProperties(vehicle)
	if ZoneVehicles[garageName] == nil then
		return false
	end
	local spawnedVehicle = ZoneVehicles[garageName][vehicleProps.plate]
	if spawnedVehicle ~= nil then
		return spawnedVehicle
	end
	return false
end

-- Car FEE price from database
function GetFeeFromDatabase(plate)
	ESX.TriggerServerCallback("az_parking:getCarParkingPrice", function(price, garageFee)
		CurrentCar.price = price
		CurrentCar.garageFee = garageFee
		lookingPrice = false
	end, plate)
end

-- Returns new price based on fee and new time
function FeeAdjust(price, fee, time)
	return math.floor(price + ((time / 86400) * fee))
end

-- Only allow cars,bikes,quadbikes and bicycles.
-- TODO: Allow by garageName on Config props
function IsAllowedCar(vehicle, garageName)
	return IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelAQuadbike(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or IsThisModelABicycle(GetEntityModel(vehicle))
end

-- Save car to database
function SaveCurrentVehicle(vehicle, garageName)
	local vehicleProps = _Utils.GetVehicleProperties(vehicle)
	local vehiclePosition    = GetEntityCoords(vehicle)
	local vehicleHeading   = GetEntityHeading(vehicle)
	if vehicleProps and vehicleProps.tankHealth and vehicleProps.tankHealth < 1 then
		if Config.UseAdvencedNotification then
			ESX.ShowAdvancedNotification('GARAGE', 'Status', _U("car_broken"), Config.CharGarage, 1)
		else
			ESX.ShowNotification_U("car_broken");
		end
		return
	end
	ESX.TriggerServerCallback("az_parking:saveVehicle", function(callback)
		if callback.status then
			SetVehicleDoorsLocked(vehicle, 2)
			ClearPedTasks(ped, true)
			TaskLeaveVehicle(GetPlayerPed(-1), vehicle, 64)
			Citizen.Wait(2000)
			ClearPedTasksImmediately(GetPlayerPed(-1))
			RemoveCarFromEarth(vehicleProps.plate, vehicle)
			DeleteVehicle(vehicle)
			TriggerServerEvent('az_parking:addGlobalVehicle', callback.vehicle, garageName)
			if Config.UseAdvencedNotification then
				ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('car_saved'), Config.CharGarage, 1)
			else
				ESX.ShowNotification_U('car_saved');
			end
		else
			if Config.UseAdvencedNotification then
				ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('error'), Config.CharGarage, 1)
			else
				ESX.ShowNotification_U('error');
			end
		end
	end, {
		location = { x = vehiclePosition.x, y = vehiclePosition.y, z = vehiclePosition.z, h = vehicleHeading },
		props    = vehicleProps,
		garageName  = garageName,
	})
end

-- Driving current car
function DriveCurrentVehicle(currentVehicle, storedVehicle)
	DoScreenFadeOut(150)
	ESX.TriggerServerCallback("az_parking:driveVehicle", function(callback)
		DoScreenFadeIn(150)
		local vehicle = callback.vehData
		if callback.status then
			DeleteVehicle(currentVehicle)
			if DoesEntityExist(currentVehicle) then 
				DeleteEntity(currentVehicle) 
			end
			Wait(5)
			DoScreenFadeIn(150)
			ESX.Game.SpawnVehicle(vehicle.props.model, vehicle.location, vehicle.location.h, function(vehicleEntity)
				_Utils.SetVehicleProperties(vehicleEntity, vehicle.props)
				AddCarOnEarth(vehicle.props.plate, vehicleEntity)
				TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicleEntity, -1)
				SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
				SetVehicleOnGroundProperly(vehicleEntity)
			end)
			if Config.UseAdvencedNotification then
				ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('vehicle_sucess'), Config.CharGarage, 1)
			else
				ESX.ShowNotification_U('vehicle_sucess');
			end
		else
			DoScreenFadeIn(150)
			if Config.UseAdvencedNotification then
				ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('error'), Config.CharGarage, 1)
			else
				ESX.ShowNotification_U('error');
			end
		end
	end, storedVehicle, storedVehicle.garageName)
end

-- Time ADJUST timer
Citizen.CreateThread(function()
	while(true) do
		if runTimeAdjust then
			timeAdjust = timeAdjust + 1
		end
		Citizen.Wait(1000)
	end
end)

-- Position - InVehicle thread
Citizen.CreateThread(function()
  while true do
	insideParkingZone = false
	if ESX ~= nil and PlayerData ~= nil then
		local plyPed = GetPlayerPed(-1)
		local coord = GetEntityCoords(plyPed)
		for garageName, parking in pairs(_Parkings) do
			local atThisGarage = false
			local zone = parking.zone
			local inZone = zone:isPointInside(coord)
			local zoneCenter = zone:getBoundingBoxCenter()
			local zoneSize = #(zone:getBoundingBoxMax() - zone:getBoundingBoxMin()) / 2
			local distanceBetweenZone = #(coord.xy - zoneCenter.xy)
			if inZone then
				insideParkingZone = garageName
				atThisGarage = true
			end
			if distanceBetweenZone < zoneSize + Config.RealParking.RenderDistance - 10.0 then
				atThisGarage = true
			end
			if atThisGarage and CurrentParkings[garageName] == false and #ZoneVehicles[garageName] == 0 then
				CurrentParkings[garageName] = true
				SpawnLocalParking(garageName)
			end
			if not atThisGarage then
				CurrentParkings[garageName] = false
				if ZoneVehicles[garageName] ~= nil then
					CleanParkingVehicles(garageName)
				end
			end
		end
	end
    Citizen.Wait(200)
  end
end)   

-- Driving/Saving CAR Thread
local storedVehicle = nil
Citizen.CreateThread(function()
	while true do
		if ESX ~= nil then
			local playerPed = GetPlayerPed(-1)
			local currentVehicle = GetVehiclePedIsIn(playerPed)
			if insideParkingZone ~= false and currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
				if storedVehicle == nil then
					storedVehicle = GetStoredCar(currentVehicle, insideParkingZone)
				end			
				
				if storedVehicle == false then
					_Utils.DisplayHelpText(_U("press_to_save"))
				else
					runTimeAdjust = true
					if CurrentCar.price ~= nil and CurrentCar.garageFee ~= nil then
						local cFee = FeeAdjust(CurrentCar.price, CurrentCar.garageFee, timeAdjust)
						_Utils.DisplayHelpText(string.format(_U("need_parking_fee", cFee)))
					else 
						if lookingPrice == false then
							lookingPrice = true
							GetFeeFromDatabase(storedVehicle.plate)
						end
					end
				end
				
				if IsControlJustReleased(0, 74) then
					if storedVehicle == false then
						if insideParkingZone and _Parkings[insideParkingZone].jobs and not _Utils.IncludeJob(_Parkings[insideParkingZone].jobs, PlayerData.job.name) then
							if Config.UseAdvencedNotification then
								ESX.ShowAdvancedNotification('GARAGE', 'Status', _U("not_allowed_zone"), Config.CharGarage, 1)
							else
								ESX.ShowNotification_U("not_allowed_zone");
							end
						else
							if IsAllowedCar(currentVehicle, insideParkingZone) then
								SaveCurrentVehicle(currentVehicle, insideParkingZone)
							else
								if Config.UseAdvencedNotification then
									ESX.ShowAdvancedNotification('GARAGE', 'Status', _U("only_allowed_car"), Config.CharGarage, 1)
								else
									ESX.ShowNotification_U("only_allowed_car");
								end
							end
						end
					else
						DriveCurrentVehicle(currentVehicle, storedVehicle)
					end
				end
			else
				storedVehicle = nil
				runTimeAdjust = false
				timeAdjust = 0

				if CurrentCar.price or CurrentCar.garageFee then
					CurrentCar = {}
				end
			end
		end
		Citizen.Wait(0)
	end
end)

-- Draw 3D Text Thread
Citizen.CreateThread(function()
	while true do
		if Config.RealParking.ShowEntrances then
			local pl = GetEntityCoords(GetPlayerPed(-1))
			for k, v in pairs(_Parkings) do
				if v.entrances then
					for n, m in pairs(v.entrances) do
						if not v.hideEntrance and GetDistanceBetweenCoords(pl.x, pl.y, pl.z, m.x, m.y, m.z, true) < Config.RealParking.EntrancesDrawDistance then
							_Utils.Draw3DText(m.x, m.y, m.z, v.name, 4, 0.17, 0.17)
							if v.jobs or v.mafia then
								_Utils.Draw3DText(m.x, m.y, m.z - 0.3, string.format('~m~'.._U("private_parking")), 4, 0.12, 0.12)
								DrawMarker(36, m.x, m.y, m.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 110, 110, 110, 80, false, true, true, false, nil, false)
							elseif v.fee == nil or v.fee == 0 then
								_Utils.Draw3DText(m.x, m.y, m.z - 0.3, string.format(_U("parking_free")), 4, 0.12, 0.12)
								DrawMarker(36, m.x, m.y, m.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 10, 255, 10, 80, false, true, true, false, nil, false)
							else
								_Utils.Draw3DText(m.x, m.y, m.z - 0.3, string.format(_U("parking_fee", v.fee)), 4, 0.12, 0.12)
								DrawMarker(36, m.x, m.y, m.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 10, 10, 80, false, true, true, false, nil, false)
							end
						end
					end
				end
			end
		end

		-- Draw CARS INFO
		if Config.RealParking.ShowCarInfo and insideParkingZone ~= nil and ZoneVehicles[insideParkingZone] and PlayerData ~= nil then
			local pl = GetEntityCoords(GetPlayerPed(-1))
			for index, vehicle in pairs(ZoneVehicles[insideParkingZone]) do
				if GetDistanceBetweenCoords(pl.x, pl.y, pl.z, vehicle.location.x, vehicle.location.y, vehicle.location.z, true) < Config.RealParking.DrawDistance then
					if vehicle.owner == PlayerData.identifier then
						_Utils.Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z - 1.45, string.format(_U("plate", vehicle.plate)), 4, 0.1, 0.1)
						_Utils.Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z - 1.38, string.format(_U("you_are_owner")), 4, 0.05, 0.05)
						_Utils.Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z - 1.62, string.format(_U("parked_owner")), 4, 0.065, 0.065)
					else
						_Utils.Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z - 1.62, string.format(_U("parked")), 4, 0.065, 0.065)
					end
				end
			end
		end
		Citizen.Wait(0)
	end
end)

-- Creating Blips
Citizen.CreateThread(function()
	-- Display blips for Parkings
	for parkingName, parkingData in pairs(_Parkings) do
		if parkingData.entrances and #(parkingData.entrances) > 0then
			local generatedBlip = AddBlipForCoord(parkingData.entrances[1].x, parkingData.entrances[1].y, parkingData.entrances[1].z)
			SetBlipPriority(generatedBlip, 9)
			if parkingData.jobs ~= nil or parkingData.mafia ~= nil then
				SetBlipSprite(generatedBlip, parkingData.blipType or Config.RealParking.PrivateParkingBlip.sprite or 524)
				SetBlipColour(generatedBlip, parkingData.blipColor or Config.RealParking.PrivateParkingBlip.color or 12)
				SetBlipScale(generatedBlip, Config.RealParking.PrivateParkingBlip.size or 0.9)
				SetBlipAsShortRange(generatedBlip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('private_parking'))
				EndTextCommandSetBlipName(generatedBlip)
			elseif parkingData.fee and parkingData.fee > 0 then
				SetBlipSprite(generatedBlip, parkingData.blipType or Config.RealParking.PublicParkingBlip.sprite or 524)
				SetBlipColour(generatedBlip, parkingData.blipColor or Config.RealParking.PublicParkingBlip.color or 54)
				SetBlipScale(generatedBlip, Config.RealParking.PublicParkingBlip.size or 0.9)
				SetBlipAsShortRange(generatedBlip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(parkingData.blipName or _U('public_parking'))
				EndTextCommandSetBlipName(generatedBlip)
			else
				SetBlipSprite(generatedBlip, parkingData.blipType or Config.RealParking.FreeParkingBlip.sprite or 524)
				SetBlipColour(generatedBlip, parkingData.blipColor or Config.RealParking.FreeParkingBlip.color or 12)
				SetBlipScale(generatedBlip, Config.RealParking.FreeParkingBlip.size or 0.9)
				SetBlipAsShortRange(generatedBlip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(parkingData.blipName or _U('free_parking'))
				EndTextCommandSetBlipName(generatedBlip)
			end
		end
	end
end)