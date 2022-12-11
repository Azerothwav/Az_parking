-- Global Variables
local CarPending = false
local PedAlive = nil
local ColdDownValet = nil
local ColdDownMenu = nil
local InValidation = false

Citizen.CreateThread(function()
	while true do
		if ColdDownMenu ~= nil then
			ColdDownMenu = ColdDownMenu - 1
			if ColdDownMenu <= 0 then
				ColdDownMenu = nil
			end
		end
		Citizen.Wait(1000)
	end
end)

Citizen.CreateThread(function()
	while true do
		if ColdDownValet ~= nil then
			ColdDownValet = ColdDownValet - 10
			if ColdDownValet <= 0 then
				ColdDownValet = nil
				_Utils.SendNotification(_U('colddown_finished'), "info")
				if PedAlive ~= nil then
					SetEntityAsNoLongerNeeded(PedAlive)
					DeletePed(PedAlive)
					PedAlive = nil
				end
			end
		end
		if PedAlive ~= nil then
			if IsEntityDead(PedAlive) then
				SetEntityAsNoLongerNeeded(PedAlive)
				DeletePed(PedAlive)
				PedAlive = nil
			end
		end
		Citizen.Wait(10000)
	end
end)

function PriceSpanWrapper(text)
	return '<span style="margin-left:30px;font-size:20px;color:'..Config.Colors.prices..'">'..text..'</span>'
end

function GetNearestWarehouse()
	local userCoords = GetEntityCoords(GetPlayerPed(-1))
	local warehouseLocated = _Warehouses[1].menu
	for key, value in pairs(_Warehouses) do
		if #(userCoords - value.menu) < #(userCoords - warehouseLocated) then
			warehouseLocated = value.menu
		end
	end
	return warehouseLocated
end

function GetNearestRecoverPoint()
	local userCoords = GetEntityCoords(GetPlayerPed(-1))
	local recoverPointLocated =  vector3(_RecoverPoints[1].x, _RecoverPoints[1].y, _RecoverPoints[1].z)
	for key, point in pairs(_RecoverPoints) do
		local pointPos = vector3(point.x, point.y, point.z)
		if #(userCoords - pointPos) < #(userCoords - recoverPointLocated) then
			recoverPointLocated = pointPos
		end
	end
	return recoverPointLocated
end

function WaitToArrive(vehicle)
	local arrived = false
	while not arrived do
		local playerPos = GetEntityCoords(GetPlayerPed(-1))
		local coords = GetEntityCoords(vehicle)
		local distance = #(coords - playerPos)
		if distance <= 25.0 then
			arrived = true
			SetVehicleBrake(vehicle, true)
			if PedAlive ~= nil then
				SetEntityAsNoLongerNeeded(PedAlive)
				DeletePed(PedAlive)
				PedAlive = nil
			end
		end
		Citizen.Wait(200)
	end
end

function CreateBlipOnEntity(entity) 
	local blip = AddBlipForEntity(entity)
	SetBlipAsShortRange(blip, false)
	SetBlipDisplay(blip, 6)
	SetBlipScale(blip, 0.9)
	SetBlipSprite(blip, 595)
	SetBlipColour(blip, 46)
	SetBlipFlashes(blip, true)
	SetBlipRoute(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Valet")
	EndTextCommandSetBlipName(blip)
	return blip
end

function ChangeVehicleName(vehicle)
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'rename_vehicle', { title = _U('change_name') },
	function(dialog, menu)
		if not string.match(dialog.value, "%w") then
			_Utils.SendNotification(_U('alphanumeric_error'), "error")
			return
		end
		if string.len(dialog.value) > 15 then
			_Utils.SendNotification(_U('max_characters', 15), "error")
			return
		end
		if string.len(dialog.value) >= 1 then
			TriggerServerEvent('az_parking:renamevehicle',  vehicle.plate, dialog.value)
			ESX.UI.Menu.CloseAll()
		else
			_Utils.SendNotification(_U('cannot_be_empty'), "error")
			menu.close()
			OpenCarMenu()
		end
	end,
	function(dialog, menu)
		menu.close()
		OpenCarMenu()
	end)
end

function GenerateVehicleAndSendToUser(vehData, price, society)
	local userCoords = GetEntityCoords(GetPlayerPed(-1))
	local found, outPos, outHeading = GetClosestVehicleNodeWithHeading(userCoords.x, userCoords.y, userCoords.z, 1, 1500.0, 0)
	spawn = { x = outPos.x, y = outPos.y, z = outPos.z, h = outHeading}
	if spawn and #(userCoords - vector3(spawn.x,spawn.y,spawn.z)) > 299.0 then -- MAX FIVEM SPAWN area
		_Utils.SendNotification(_U('cant_spawn'), "error")
		return
	end
	if PedAlive ~= nil or IsCarOnEarth(vehData.plate) then
		_Utils.SendNotification(_U('vehicle_on_map'), "error")
		return
	end
	if InValidation then
		_Utils.SendNotification(_U('pending_process'), "error")
		return
	end
	InValidation = true
	ESX.TriggerServerCallback('az_parking:payMoney', function(hasEnoughMoney, left)
		InValidation = false
		if hasEnoughMoney then
			ESX.UI.Menu.CloseAll()
			Citizen.CreateThread(function()
				ColdDownValet = Config.CarMenu.ColdDown
				CarPending = true
				_Utils.SendNotification(_U('car_requested'), "success")
				local vehicleData = { plate = vehData.plate, garageName = vehData.garage_name }
				TriggerServerEvent("az_parking:removeGlobalVehicle", -1, vehicleData, vehData.garage_name)

				RequestModel(Config.CarMenu.ValetPed)
				while not HasModelLoaded(Config.CarMenu.ValetPed) do
					RequestModel(Config.CarMenu.ValetPed)
					Citizen.Wait(100)
				end
				
				local props = json.decode(vehData.vehicle)
				if spawn then
					ESX.Game.SpawnVehicle(props.model, vector3(spawn.x,spawn.y,spawn.z), spawn.h, function(spawnedVehicle)
						AddCarOnEarth(vehData.plate, spawnedVehicle)
						SetEntityAsMissionEntity(spawnedVehicle, true, true)
						driverPed = CreatePedInsideVehicle(spawnedVehicle, 6, Config.CarMenu.ValetPed, -1, true, false)
						PedAlive = driverPed
						SetEntityAsMissionEntity(driverPed, true, true)
						_Utils.SetVehicleProperties(spawnedVehicle, props)
						_Utils.SetFuel(spawnedVehicle, 100)
						SetVehicleHasBeenOwnedByPlayer(spawnedVehicle, true)
						SetVehicleOnGroundProperly(spawnedVehicle)
						SetDriverAggressiveness(driverPed, 0.0)
						SetEntityInvincible(spawnedVehicle, true)
						SetEntityInvincible(driverPed, true)
						SetBlockingOfNonTemporaryEvents(driverPed, true)
						TaskVehicleDriveToCoordLongrange(driverPed, spawnedVehicle, userCoords.x, userCoords.y, userCoords.z, 15.0, 786748, 6.0)
						local vehicleBlip = CreateBlipOnEntity(spawnedVehicle)
						WaitToArrive(spawnedVehicle)
						_Utils.SetFuel(spawnedVehicle, props.fuelLevel)
						SetEntityInvincible(spawnedVehicle, false)
						CarPending = false
						TaskLeaveVehicle(driverPed, spawnedVehicle, 6)
						SetEntityAsNoLongerNeeded(driverPed)
						DeletePed(driverPed)
						RemoveBlip(vehicleBlip)
						if PedAlive ~= nil then
							SetEntityAsNoLongerNeeded(PedAlive)
							DeletePed(PedAlive)
							PedAlive = nil
						end
					end)
				end
			end)
		else
			_Utils.SendNotification(_U('not_enough_money_left', left), "error")
		end
	end, price, society)
end

function OpenPoundVehicleMenu(vehicle)
	ESX.UI.Menu.CloseAll()
	local elements = {}
	table.insert(elements, { label = _U('mark_gps'), value = 'go_to_pound' })
	table.insert(elements, { label = _U('change_name'), value = 'change_name' })
	table.insert(elements, { label = _U('go_back'), value = 'go_back' })

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pound_menu',
		{
		title = '<span style="font-weight:bold">'.._Utils.GetVehicleName(vehicle)..'</span> - '.._U('pound'),
		align = 'bottom-right',
		elements = elements
		},
	function(data, menu)
		if (data.current.value == 'go_to_pound') then
			local position = GetNearestWarehouse()
			SetNewWaypoint(position.x, position.y)
			_Utils.SendNotification(_U('marked_on_map'), "info")
			menu.close()
		elseif (data.current.value == 'change_name') then
			ChangeVehicleName(vehicle)
			menu.close()
		else
			menu.close()
			OpenCarMenu()
		end
	end,
	function(data, menu)
		menu.close()
		OpenCarMenu()
	end)
end

function OpenStoredVehicleMenu(vehicle)
	ESX.TriggerServerCallback("az_parking:getCarGaragePrice", function(price, garageFee)
		ESX.UI.Menu.CloseAll()
		local elements = {}
		local garageLocation = {}
		if vehicle.garage_name and _Garages[vehicle.garage_name] and _Garages[vehicle.garage_name].spawn then
			garageLocation = _Garages[vehicle.garage_name].spawn
		else
			_Utils.SendNotification(_U('cannot_find_parking'), "error")
			return
		end
		local valetPrice = Config.CarMenu.ValetPrice(vector3(garageLocation.x, garageLocation.y, garageLocation.z), GetEntityCoords(PlayerPedId()))
		local totalPrice = math.ceil(price+valetPrice)
		
		table.insert(elements, { label = '<span>'.._U('ship')..'</span>'..PriceSpanWrapper('Valet: $'..valetPrice..' | Total: $'..totalPrice), value = 'call_valet' })
		table.insert(elements, { label = _U('mark_gps')..PriceSpanWrapper(_U('price_at_point')..': $'..price), value = 'go_to_parking' })
		table.insert(elements, { label = _U('change_name'), value = 'change_name' })
		table.insert(elements, { label = _U('go_back'), value = 'go_back' })

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stored_menu',
			{
				title = '<span style="font-weight:bold">'.._Utils.GetVehicleName(vehicle)..'</span> - '.._U('pending_parking_price')..' $'..price,
				align = 'bottom-right',
				elements = elements
			},
		function(data, menu)
			if (data.current.value == 'call_valet') then
				if ColdDownValet ~= nil then
					_Utils.SendNotification(_U('pending_coldown', ColdDownValet), "error")
					return
				end
				if PedAlive ~= nil or CarPending then
					_Utils.SendNotification(_U('pending_car'), "error")
					return
				end
				GenerateVehicleAndSendToUser(vehicle, price + valetPrice, _Garages[vehicle.garage_name].society)
				menu.close()
			elseif (data.current.value == 'go_to_parking') then
				if _Garages[vehicle.garage_name] then
					local currentGaragePos = _Garages[vehicle.garage_name].spawn
					SetNewWaypoint(currentGaragePos.x, currentGaragePos.y)
					_Utils.SendNotification(_U('marked_on_map'), "info")
					menu.close()
				else
					_Utils.SendNotification(_U('cannot_find_parking'), "error")
				end
			elseif (data.current.value == 'change_name') then
				ChangeVehicleName(vehicle)
				menu.close()
			else
				menu.close()
				OpenCarMenu()
			end
		end,
		function(data, menu)
			menu.close()
			OpenCarMenu()
		end)
	end, vehicle.plate)
end

function OpenStoredParkingVehicleMenu(vehicle)
	ESX.TriggerServerCallback("az_parking:getCarParkingPrice", function(price, garageFee)
		ESX.UI.Menu.CloseAll()
		local elements = {}
		
		local parkingLocation = {}
		if vehicle and vehicle.location then
			parkingLocation = json.decode(vehicle.location)
		else
			_Utils.SendNotification(_U('cannot_find_parking'), "error")
			return
		end
		local valetPrice = Config.CarMenu.ValetPrice(vector3(parkingLocation.x, parkingLocation.y, parkingLocation.z), GetEntityCoords(PlayerPedId()))
		local totalPrice = math.ceil(price+valetPrice)

		table.insert(elements, { label = '<span>'.._U('ship')..'</span>'..PriceSpanWrapper('Valet: $'..valetPrice..' | Total: $'..totalPrice), value = 'call_valet' })
		table.insert(elements, { label = _U('mark_gps')..PriceSpanWrapper(_U('price_at_point')..': $'..price), value = 'go_to_parking' })
		table.insert(elements, { label = _U('change_name'), value = 'change_name' })
		table.insert(elements, { label = _U('go_back'), value = 'go_back' })

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'parking_menu',
			{
			title = '<span style="font-weight:bold">'.._Utils.GetVehicleName(vehicle)..'</span> - '.._U('pending_parking_price')..' $'..price,
			align = 'bottom-right',
			elements = elements
			},
		function(data, menu)
			if (data.current.value == 'call_valet') then
				if ColdDownValet ~= nil then
					_Utils.SendNotification(_U('pending_coldown', ColdDownValet), "error")
					return
				end
				if PedAlive ~= nil or CarPending then
					_Utils.SendNotification(_U('pending_car'), "error")
					return
				end
				GenerateVehicleAndSendToUser(vehicle, totalPrice, _Parkings[vehicle.garage_name].society)
				menu.close()
			elseif (data.current.value == 'go_to_parking') then
				local position = json.decode(vehicle.location)
				SetNewWaypoint(position.x, position.y)
				_Utils.SendNotification(_U('marked_on_map'), "info")
				menu.close()
			elseif (data.current.value == 'change_name') then
				ChangeVehicleName(vehicle)
				menu.close()	
			else
				menu.close()
				OpenCarMenu()
			end
		end,
		function(data, menu)
			menu.close()
			OpenCarMenu()
		end)
	end, vehicle.plate)
end

function OpenOutsideVehicleMenu(vehicle)
	ESX.UI.Menu.CloseAll()
	local elements = {}

	local goToPos = GetNearestRecoverPoint()
	local valetPrice = Config.CarMenu.ValetPrice(vector3(goToPos.x, goToPos.y, goToPos.z), GetEntityCoords(PlayerPedId()))
	local recoverPrice = math.ceil(vehicle.price * Config.RecoverRate)
	local totalPrice = math.ceil(recoverPrice+valetPrice)
	
	table.insert(elements, { label = '<span>'.._U('ship')..'</span>'..PriceSpanWrapper('Valet: $'..valetPrice..' | Total: $'..totalPrice), value = 'call_valet' })
	table.insert(elements, { label = _U('mark_gps')..PriceSpanWrapper(_U('price_at_point')..': $'..recoverPrice), value = 'go_to_recover' })
	table.insert(elements, { label = _U('change_name'), value = 'change_name' })
	table.insert(elements, { label = _U('go_back'), value = 'go_back' })

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'outside_menu',
		{
		title = '<span style="font-weight:bold">'.._Utils.GetVehicleName(vehicle)..'</span> - '.._U('recover_price')..' $'..recoverPrice,
		align = 'bottom-right',
		elements = elements
		},
	function(data, menu)
		if (data.current.value == 'call_valet') then
			if not IsCarOnEarth(vehicle.plate) and not _Utils.DoesAPlayerDrivesCar(vehicle.plate) then
				if ColdDownValet ~= nil then
					_Utils.SendNotification(_U('pending_coldown', ColdDownValet), "error")
					return
				end
				if PedAlive ~= nil or CarPending then
					_Utils.SendNotification(_U('pending_car'), "error")
					return
				end
				GenerateVehicleAndSendToUser(vehicle, recoverPrice + valetPrice, Config.RecoverPoints.Society)
				menu.close()
			else
				_Utils.SendNotification(_U('vehicle_on_map'), "error")
			end
		elseif (data.current.value == 'go_to_recover') then
			SetNewWaypoint(goToPos.x, goToPos.y)
			_Utils.SendNotification(_U('marked_on_map'), "info")
			menu.close()
		elseif (data.current.value == 'change_name') then
			ChangeVehicleName(vehicle)
			menu.close()
		else
			menu.close()
			OpenCarMenu()
		end
	end,
	function(data, menu)
		menu.close()
		OpenCarMenu()
	end)
end

function OpenCarMenu()
	if IsEntityDead(GetPlayerPed(-1)) then
		_Utils.SendNotification(_U('dead'), "error")
		return
	end
	if ColdDownMenu ~= nil then
		_Utils.SendNotification(_U('pending_process'), "warning")
		return		
	end
	ESX.UI.Menu.CloseAll()
	ColdDownMenu = 5
	ESX.TriggerServerCallback('az_parking:getAllCars', function(vehicles)
		local elements = {}
		for key, vehicle in pairs(vehicles) do
			table.insert(elements, { 
				label = '<div style="display:flex">'.._Utils.GenerateVehicleLabelWithDistance(vehicle)..'</div>', value = 'return_vehicle', vehicle = vehicle
			})
		end
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'personal_menu',
			{
			title = _U('personal_car_menu'),
			align = 'bottom-right',
			elements = elements
			},
		function(data, menu)
			if (data.current.value == 'return_vehicle') then
				currentVehicle = data.current.vehicle
				if currentVehicle.pound then
					OpenPoundVehicleMenu(currentVehicle)
				elseif currentVehicle.stored and currentVehicle.garage_type == Config.RealParking.Type then
					OpenStoredParkingVehicleMenu(currentVehicle)
				elseif currentVehicle.stored then
					OpenStoredVehicleMenu(currentVehicle)
				else
					OpenOutsideVehicleMenu(currentVehicle)
				end
				menu.close()
			end
		end,
		function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent("az_parking:openPersonalMenu")
AddEventHandler("az_parking:openPersonalMenu", function()
	OpenCarMenu()
end)

RegisterCommand(Config.CarMenu.Command, function()
	OpenCarMenu()
end, false)