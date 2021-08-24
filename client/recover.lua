-- Global Variables
local CurrentRecoverPoint = nil
local IsMenuOpen = false

function SpawnRecoverVehicle(vehData, recoverPoint)
	local player = GetPlayerPed(-1)
	local spawn = recoverPoint
	local props = json.decode(vehData.vehicle)
	if ESX.Game.IsSpawnPointClear(spawn, 2.0) then
		DoScreenFadeOut(150)
		ESX.TriggerServerCallback("az_parking:getOutFromRecover", function(callback)
			local vehicle = callback.vehData
			if callback.status then
				DoScreenFadeIn(150)
				ESX.Game.SpawnVehicle(vehicle.props.model, spawn, spawn.h, function(vehicleEntity)
					_Utils.SetVehicleProperties(vehicleEntity, vehicle.props)
					AddCarOnEarth(vehicle.props.plate, vehicleEntity)
					TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicleEntity, -1)
					SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
					SetVehicleOnGroundProperly(vehicleEntity)
				end)
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('FOURRIERE', 'Status', 'Véhicule sortis de la fourrière', Config.CharGarage, 1)
				else
					ESX.ShowNotification('Vehicule sortis de la fourrière');
				end
			else
				DoScreenFadeIn(150)
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('FOURRIERE', 'Status', 'Une erreur lors de la sortis de la fourrière', Config.CharGarage, 1)
				else
					ESX.ShowNotification('Une erreur lors de la sortis de la fourrière');
				end
			end
		end, vehData)
	else
		_Utils.SendNotification(_U('no_spawn_places'), "error")
		if Config.UseAdvencedNotification then
			ESX.ShowAdvancedNotification('FOURRIERE', 'Status', _U('no_spawn_places'), Config.CharGarage, 1)
		else
			ESX.ShowNotification_U('no_spawn_places');
		end
	end
end

-- Open Recover Menu Function Handler
function OpenMenuRecover(recoverPoint)
	ESX.UI.Menu.CloseAll()
	IsMenuOpen = true
	ESX.TriggerServerCallback('az_parking:getNotStoredCars', function(vehicles)
		if not vehicles then
			if Config.UseAdvencedNotification then
				ESX.ShowAdvancedNotification('FOURRIERE', 'Status', _U("no_cars_founded"), Config.CharGarage, 1)
			else
				ESX.ShowNotification_U("no_cars_founded");
			end
		end
		local elements = {}
		for key, vehicle in pairs(vehicles) do
			local recoverPrice = math.ceil(vehicle.price * Config.RecoverRate)
			table.insert(elements, { 
				label = '<div style="display:flex">'.._Utils.GenerateVehicleLabel(vehicle).."<span style='color:red'>$"..recoverPrice.."</span></div>",
				value = 'recover_vehicle',
				vehicle = vehicle
			})
		end
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'recover_menu',
			{
			title = _U('recover_menu'),
			align = 'bottom-right',
			elements = elements
			},
		function(data, menu)
			if (data.current.value == 'recover_vehicle') then
				if not IsCarOnEarth(data.current.vehicle.plate) and not _Utils.DoesAPlayerDrivesCar(data.current.vehicle.plate) then
					SpawnRecoverVehicle(data.current.vehicle, recoverPoint)
				else
					if Config.UseAdvencedNotification then
						ESX.ShowAdvancedNotification('FOURRIERE', 'Status', _U('vehicle_on_map'), Config.CharGarage, 1)
					else
						ESX.ShowNotification_U('vehicle_on_map');
					end
				end
				menu.close()
			end
		end,
		function(data, menu)
			menu.close()
		end)
	end)
end

-- Player Keyboard input handler for open menu thread
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if CurrentRecoverPoint ~= nil and IsControlJustReleased(0, 38) then
			local PlayerPed = PlayerPedId()
			if IsPedInAnyVehicle(PlayerPed, false) then
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('FOURRIERE', 'Status', _U('cant_inside_vehicle'), Config.CharGarage, 1)
				else
					ESX.ShowNotification_U('cant_inside_vehicle');
				end
			else
				OpenMenuRecover(CurrentRecoverPoint)
			end
		end
	end
end)

-- Recover Marker Thread
Citizen.CreateThread(function()
	while true do
		if ESX ~= nil and CurrentRecoverPoint ~= nil then
			local point = vector3(CurrentRecoverPoint.x, CurrentRecoverPoint.y, CurrentRecoverPoint.z)
			DrawMarker(Config.RecoverPoints.Marker.type, point, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.RecoverPoints.Marker.color.r, Config.RecoverPoints.Marker.color.g, Config.RecoverPoints.Marker.color.b, 100, false, true, 2, true, false, false, false)
			DrawMarker(43, vector3(point.x, point.y, point.z - 1.0), 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.RecoverPoints.Marker.size, Config.RecoverPoints.Marker.size, Config.RecoverPoints.Marker.size, Config.RecoverPoints.Marker.color.r, Config.RecoverPoints.Marker.color.g, Config.RecoverPoints.Marker.color.b, 100, false, true, 2, true, false, false, false)
			if CurrentRecoverPoint.onPoint then
				_Utils.DisplayHelpText(_U('recover_help'))
			end
		end
		Citizen.Wait(5)
	end
end)

-- Position Thread
Citizen.CreateThread(function()
	while true do
		if ESX ~= nil then
			local playerCoords = GetEntityCoords(PlayerPedId())
			for key, point in pairs(_RecoverPoints) do
				local spawnPoint = vector3(point.x, point.y, point.z)
				if #(playerCoords - spawnPoint) < Config.RecoverPoints.DrawDistance then
					CurrentRecoverPoint = point
					if #(playerCoords - spawnPoint) < Config.RecoverPoints.Marker.size then
						CurrentRecoverPoint.onPoint = true
					else
						if IsMenuOpen then
							ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'recover_menu')
							IsMenuOpen = false
						end
						CurrentRecoverPoint.onPoint = false
					end
				else
					CurrentRecoverPoint = nil
				end
			end
		end
		Citizen.Wait(500)
	end
end)

-- Recover Blips Thread
Citizen.CreateThread(function()
	-- Display blips for RecoverPoints
	for k, point in pairs(_RecoverPoints) do
		local blip = AddBlipForCoord(point.x, point.y, point.z)
		SetBlipSprite(blip, Config.RecoverPoints.Blip.type or 380)
		SetBlipColour(blip, Config.RecoverPoints.Blip.color or 57)
		SetBlipScale(blip, Config.RecoverPoints.Blip.size or 0.9)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(Config.RecoverPoints.Blip.name)
		EndTextCommandSetBlipName(blip)
	end
end)