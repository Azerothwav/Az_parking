-- Global Variables
local CurrentGarage = nil
local CarMenu = nil
local IsMenuOpen = false
local UserGroup = nil

-- Handle UserGroup Changed
RegisterNetEvent("az_parking:userGroupChange")
AddEventHandler("az_parking:userGroupChange", function(userGroupName)
	UserGroup = userGroupName
end)

function StoreCurrentVehicle(vehicle, garageName)
	local vehicleProps = _Utils.GetVehicleProperties(vehicle)
	local vehiclePosition = GetEntityCoords(vehicle)
	local vehicleHeading  = GetEntityHeading(vehicle)
	if vehicleProps and vehicleProps.tankHealth and vehicleProps.tankHealth < 1 then
		if Config.UseAdvencedNotification then
			ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('car_broken'), Config.CharGarage, 1)
		else
			ESX.ShowNotification_U('car_broken');
		end
		return
	end
	ESX.TriggerServerCallback("az_parking:storeVehicle", function(callback)
		if callback.status then
			ClearPedTasks(ped, true)
			TaskLeaveVehicle(GetPlayerPed(-1), vehicle, 64)
			Citizen.Wait(1500)
			RemoveCarFromEarth(vehicleProps.plate, vehicle)
			SetEntityAsMissionEntity(vehicle, false, false)
			SetEntityAsNoLongerNeeded(vehicle)
			DeleteVehicle(vehicle)
			if DoesEntityExist(vehicle) then 
				DeleteEntity(vehicle) 
			end
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
		location = {x = vehiclePosition.x, y = vehiclePosition.y, z = vehiclePosition.z, h = vehicleHeading},
		props    = vehicleProps,
		garageName  = garageName,
	})
end

function GenerateParkingLabel(garageName)
	if garageName and _Garages[garageName] and _Garages[garageName].name then
		return _U('garage_title')..' - '.._Garages[garageName].name
	else
		return _U('garage_title')
	end
end

function SpawnGarageVehicle(vehData, garageName)
	local player = GetPlayerPed(-1)
	local spawn = _Garages[garageName].spawn
	local props = json.decode(vehData.vehicle)
	if ESX.Game.IsSpawnPointClear(spawn, 2.0) then
		DoScreenFadeOut(150)
		ESX.TriggerServerCallback("az_parking:getOutFromGarage", function(callback)
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
		end, vehData, garageName)
	else
		if Config.UseAdvencedNotification then
			ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('error'), Config.CharGarage, 1)
		else
			ESX.ShowNotification_U('error');
		end 
	end
end

function OpenSpawnMenu(garageName) 
	ESX.UI.Menu.CloseAll()
	local garage = {}

	if _Garages[CurrentGarage.garage].jobs then
		ESX.TriggerServerCallback('az_parking:retrieveJobVehicles', function(jobVehicles)
			if #jobVehicles > 0 then
				for k,v in ipairs(jobVehicles) do
					local props = json.decode(v.vehicle)
					local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
					local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

					if v.stored then
						label = label .. ('<span style="color:green;">%s</span>'):format(_U('vehicle_in'))
					else
						label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('vehicle_out'))
					end

					table.insert(garage, {
						label = label,
						stored = v.stored,
						model = props.model,
						vehicleProps = props
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
					title    = _U('garage_title'),
					align    = 'top-left',
					elements = garage
				}, function(data2, menu2)
					if data2.current.stored then
						local spawn = _Garages[garageName].spawn

						if spawn then
							menu2.close()

							ESX.Game.SpawnVehicle(data2.current.model, spawn, spawn.h, function(vehicle)
								ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)
								TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
								SetVehicleOnGroundProperly(vehicleEntity)
								TriggerServerEvent('t1ger_keys:stolenCarKeys', GetVehicleNumberPlateText(vehicle))

								TriggerServerEvent('az_parking:setJobVehicleState', data2.current.vehicleProps.plate, false)
								if Config.UseAdvencedNotification then
									ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('vehicle_sucess'), Config.CharGarage, 1)
								else
									ESX.ShowNotification_U('vehicle_sucess');
								end
							end)
						end
					else
						if Config.UseAdvencedNotification then
							ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('error'), Config.CharGarage, 1)
						else
							ESX.ShowNotification_U('error');
						end 
					end
				end, function(data2, menu2)
					menu2.close()
				end)

			else
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('no_vehicle_out'), Config.CharGarage, 1)
				else
					ESX.ShowNotification_U('no_vehicle_out');
				end
			end
		end, 'car')
	elseif _Garages[CurrentGarage.garage].jobs2 then
		ESX.TriggerServerCallback('az_parking:retrieveJob2Vehicles', function(vehicles)
			if #vehicles > 0 then
				for k,v in ipairs(vehicles) do
					local props = json.decode(v.vehicle)
					local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
					local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

					if v.stored then
						label = label .. ('<span style="color:green;">%s</span>'):format(_U('vehicle_in'))
					else
						label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('vehicle_out'))
					end

					table.insert(garage, {
						label = label,
						stored = v.stored,
						model = props.model,
						vehicleProps = props
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
					title    = _U('garage_title'),
					align    = 'top-left',
					elements = garage
				}, function(data2, menu2)
					if data2.current.stored then
						local spawn = _Garages[garageName].spawn

						if spawn then
							menu2.close()

							ESX.Game.SpawnVehicle(data2.current.model, spawn, spawn.h, function(vehicle)
								ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)
								TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
								SetVehicleOnGroundProperly(vehicleEntity)

								TriggerServerEvent('az_parking:setJob2VehicleState', data2.current.vehicleProps.plate, false)
								if Config.UseAdvencedNotification then
									ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('vehicle_sucess'), Config.CharGarage, 1)
								else
									ESX.ShowNotification_U('vehicle_sucess');
								end
							end)
						end
					else
						if Config.UseAdvencedNotification then
							ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('error'), Config.CharGarage, 1)
						else
							ESX.ShowNotification_U('error');
						end 
					end
				end, function(data2, menu2)
					menu2.close()
				end)

			else
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('no_vehicle_out'), Config.CharGarage, 1)
				else
					ESX.ShowNotification_U('no_vehicle_out');
				end
			end
		end, 'car')
	else 
		ESX.TriggerServerCallback('az_parking:getGarageCars', function(vehicles)
				if vehicles == nil or not type(rs) == 'table' then
					ESX.ShowNotification(_U('no_cars_founded'))
				end
				local elements = {}
					for key, vehicle in pairs(vehicles) do
						local props = json.decode(vehicle.vehicle)
						local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
						table.insert(elements, { 
							label = '<div style="display:flex">'.. vehicleName .."</span>"..  '<span style="display:flex">'.._Utils.GenerateVehicleLabel(vehicle).."<span style='color:darkgreen'>$"..(vehicle.parkingPrice or 0).."</span>"..'</div>',
							value = 'spawn_vehicle',
							vehicle = vehicle
						})
					end
				IsMenuOpen = true
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'garage_menu',
					{
					title = GenerateParkingLabel(garageName),
					align = 'bottom-right',
					elements = elements
					},
				function(data, menu)
					if (data.current.value == 'spawn_vehicle') then
						currentVehicle = data.current.vehicle
						SpawnGarageVehicle(data.current.vehicle, garageName)
						menu.close()
					end
				end,
				function(data, menu)
					menu.close()
				end)
		end, garageName)
	end
end

-- Player Keyboard input handler for open menu thread
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if CurrentGarage ~= nil and IsControlJustReleased(0, 38) then
			if _Garages[CurrentGarage.garage] and _Garages[CurrentGarage.garage].jobs and _Garages[CurrentGarage.garage].jobs2 and not _Utils.IncludeJob(_Garages[CurrentGarage.garage].jobs, _Garages[CurrentGarage.garage].jobs2, PlayerData.job.name, PlayerData.job2.name) then
				if Config.UseAdvencedNotification then
					ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('wrong_job'), Config.CharGarage, 1)
				else
					ESX.ShowNotification_U('wrong_job');
				end
			else
				local PlayerPed = GetPlayerPed(-1)
				if CurrentGarage.action == 'spawn' then
					if IsPedInAnyVehicle(PlayerPed, false) then
						if Config.UseAdvencedNotification then
							ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('cant_inside_vehicle'), Config.CharGarage, 1)
						else
							ESX.ShowNotification_U('cant_inside_vehicle');
						end
					else
						OpenSpawnMenu(CurrentGarage.garage)
					end
				elseif CurrentGarage.action == 'delete' then
					local currentVehicle = GetVehiclePedIsIn(PlayerPed, false)
					if currentVehicle and currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == PlayerPed then
						StoreCurrentVehicle(currentVehicle, CurrentGarage.garage)
					else
						if Config.UseAdvencedNotification then
							ESX.ShowAdvancedNotification('GARAGE', 'Status', _U('not_in_vehicle'), Config.CharGarage, 1)
						else
							ESX.ShowNotification_U('not_in_vehicle');
						end
					end
				end
			end
		end
	end
end)

-- Player position at Garage Thread
Citizen.CreateThread(function()
	while true do
		if ESX ~= nil and CurrentGarage ~= nil then
			local spawnPoint = CurrentGarage.spawnPoint
			local deletePoint = CurrentGarage.deletePoint
			-- Spawn point
			DrawMarker(Config.Garages.SpawnMarker.type, spawnPoint, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.Garages.SpawnMarker.color.r, Config.Garages.SpawnMarker.color.g, Config.Garages.SpawnMarker.color.b, 100, false, true, 2, true, false, false, false)
			DrawMarker(27, vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Garages.SpawnMarker.size, Config.Garages.SpawnMarker.size, 1.0, Config.Garages.SpawnMarker.color.r, Config.Garages.SpawnMarker.color.g, Config.Garages.SpawnMarker.color.b, 100, false, true, 2, true, false, false, false)
			-- Delete point
			DrawMarker(Config.Garages.DeleteMarker.type, deletePoint, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.Garages.DeleteMarker.color.r, Config.Garages.DeleteMarker.color.g, Config.Garages.DeleteMarker.color.b, 100, false, true, 2, true, false, false, false)
			DrawMarker(27, vector3(deletePoint.x, deletePoint.y, deletePoint.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Garages.DeleteMarker.size, Config.Garages.DeleteMarker.size, 1.0, Config.Garages.DeleteMarker.color.r, Config.Garages.DeleteMarker.color.g, Config.Garages.DeleteMarker.color.b, 100, false, true, 2, true, false, false, false)
			-- Show Car Parking PRICE
			if Config.Garages.ShowTitle and not CurrentGarage.hideTitle then
				if CurrentGarage.name then
					if CurrentGarage.jobs ~= nil or CurrentGarage.mafia ~= nil then
						_Utils.Draw3DText(deletePoint.x, deletePoint.y, deletePoint.z - 0.7, CurrentGarage.name, 4, 0.15, 0.15)
					else
						_Utils.Draw3DText(deletePoint.x, deletePoint.y, deletePoint.z - 0.7, '~y~'..CurrentGarage.name, 4, 0.15, 0.15)
					end
				end
				if CurrentGarage.jobs ~= nil or CurrentGarage.mafia ~= nil then
					_Utils.Draw3DText(deletePoint.x, deletePoint.y, deletePoint.z - 1.0, '~m~'..string.upper(_U("private_garage")), 4, 0.09, 0.09)
				elseif CurrentGarage.fee and CurrentGarage.fee > 0 then
					_Utils.Draw3DText(deletePoint.x, deletePoint.y, deletePoint.z - 1.0, _U("parking_fee", CurrentGarage.fee), 4, 0.09, 0.09)
				else
					_Utils.Draw3DText(deletePoint.x, deletePoint.y, deletePoint.z - 1.0, _U("parking_free"), 4, 0.09, 0.09)
				end
			end

			-- Action position validation
			if CurrentGarage.action then
				if CurrentGarage.action == "spawn" then
					_Utils.DisplayHelpText(_U('spawn_help'));
				elseif CurrentGarage.action == "delete" then
					_Utils.DisplayHelpText(_U('delete_help'));
				end
			else
				if IsMenuOpen then
					ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'garage_menu')
					IsMenuOpen = false
				end
			end
		end
		Citizen.Wait(0)
	end
end)

-- Player position thread
Citizen.CreateThread(function()
	while true do
		if ESX ~= nil then
			if CurrentGarage ~= nil then
				CurrentGarage = nil
			end
			local playerCoords = GetEntityCoords(GetPlayerPed(-1))
			for key, garage in pairs(_Garages) do
				if not garage.mafia or (garage.mafia and _Utils.Includes(garage.mafia, UserGroup)) then
					local spawnPoint = vector3(garage.spawn.x, garage.spawn.y, garage.spawn.z)
					local deletePoint = vector3(garage.delete.x, garage.delete.y, garage.delete.z)
					if #(deletePoint - playerCoords) < Config.Garages.DrawDistance then
						if CurrentGarage == nil or CurrentGarage.garage ~= key then
							CurrentGarage = garage
							CurrentGarage.garage = key
							CurrentGarage.spawnPoint = spawnPoint
							CurrentGarage.deletePoint = deletePoint
						end
						if #(spawnPoint - playerCoords) < Config.Garages.SpawnMarker.size then
							if not CurrentGarage or CurrentGarage.garage ~= key or CurrentGarage.action ~= 'spawn' then
								CurrentGarage.action = 'spawn'
							end
						elseif #(deletePoint - playerCoords) < Config.Garages.DeleteMarker.size then
							if not CurrentGarage or CurrentGarage.garage ~= key or CurrentGarage.action ~= 'delete' then
								CurrentGarage.action = 'delete'
							end
						else
							if CurrentGarage and CurrentGarage.action ~= nil then
								CurrentGarage.action = nil
							end
						end
					end
				end
			end
		end
		Citizen.Wait(500)
	end
end)

-- Traditional garage Blips Thread
Citizen.CreateThread(function()
	for k, garage in pairs(_Garages) do
		if (garage.mafia and _Utils.Includes(garage.mafia, UserGroup)) or not garage.mafia then
			local blip = AddBlipForCoord(garage.spawn.x, garage.spawn.y, garage.spawn.z)
			SetBlipPriority(blip, 8)
			if garage.jobs ~= nil or garage.mafia ~= nil then
				SetBlipSprite(blip, garage.blipType or Config.Garages.PrivateGarageBlip.sprite or 524)
				SetBlipColour(blip, garage.blipColor or Config.Garages.PrivateGarageBlip.color or 12)
				SetBlipScale(blip, Config.Garages.PrivateGarageBlip.size or 0.5)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString('Garage Privee')
				EndTextCommandSetBlipName(blip)
			elseif garage.fee and garage.fee > 0 then
				SetBlipSprite(blip, garage.blipType or Config.Garages.PublicGarageBlip.sprite or 524)
				SetBlipColour(blip, garage.blipColor or Config.Garages.PublicGarageBlip.color or 54)
				SetBlipScale(blip, Config.Garages.PublicGarageBlip.size or 0.5)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString('Garage')
				EndTextCommandSetBlipName(blip)
			elseif garage.jobs2 ~= nil or garage.mafia ~= nil then
				SetBlipSprite(blip, garage.blipType or Config.Garages.PrivateGarageBlip.sprite or 524)
				SetBlipColour(blip, garage.blipColor or Config.Garages.PrivateGarageBlip.color or 12)
				SetBlipScale(blip, Config.Garages.PrivateGarageBlip.size or 0.5)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString('Garage Privee')
				EndTextCommandSetBlipName(blip)
			else
				SetBlipSprite(blip, garage.blipType or Config.Garages.FreeGarageBlip.sprite or 524)
				SetBlipColour(blip, garage.blipColor or Config.Garages.FreeGarageBlip.color or 12)
				SetBlipScale(blip, Config.Garages.FreeGarageBlip.size or 0.5)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString('Garage Gratuit')
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)