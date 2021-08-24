-- Global Variables
local CurrentTask = {}
local isGUIOpened = false
local currentAction = nil
local currentWarehouse = false
local currentWarehouseZone = false

RegisterCommand(Config.Impound.Command, function()
	OpenImpoundGUI()
end, false)


-- Athorized Job Verification
function IsAuthorizedJob(jobName)
	for index, job in pairs(Config.Impound.AuthorizedJobs) do
		if job == jobName then
			return true
		end
	end
	return false
end

-- Open Warehouse Menu
function ShowWarehouseMenu()
	ESX.TriggerServerCallback('az_parking:getImpoundedVehicles', function(vehicles)
		for key, vehicle in pairs(vehicles) do
			vehicle.vehName = _Utils.GetVehicleName(vehicle, vehicle.model)
		end
		isGUIOpened = true
		local data = { action = "open", form = "retrieve", vehicles = vehicles }
		SetNuiFocus(true, true)
		SendNuiMessage(json.encode(data))
	end)
end

-- Handle impound to NO-OWNER Vehicle (Generated with /car or car generator)
function ImpoundNoOwnerVehicle(playerId, vehicle)
	if not DoesEntityExist(vehicle) then
		_Utils.SendNotification(_U('no_vehicle_founded'), "error")
		return
	end

	if CurrentTask.busy then
		_Utils.SendNotification(_U('busy'), "error")
		return
	end
	
	_Utils.SendNotification(_U('press_to_cancel'), "info")
	TaskStartScenarioInPlace(playerId, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
	
	CurrentTask.busy = true
	CurrentTask.task = ESX.SetTimeout(5000, function()
		ClearPedTasks(playerId)
		ESX.Game.DeleteVehicle(vehicle)
		_Utils.SendNotification(_U('no_owner_impounded'), "success")
		CurrentTask.busy = false
		Citizen.Wait(100)
	end)

	Citizen.CreateThread(function()
		while CurrentTask.busy do
			Citizen.Wait(500)
			if not DoesEntityExist(vehicle) and CurrentTask.busy then
				_Utils.SendNotification(_U('no_vehicle_founded'), "warning")
				ESX.ClearTimeout(CurrentTask.task)
				ClearPedTasks(playerId)
				CurrentTask.busy = false
				break
			end
		end
	end)
end

-- Close GUI
function CloseGUI()
	local player = PlayerPedId()
	ClearPedTasksImmediately(player)
	isGUIOpened = false
	SetNuiFocus(false)
	SendNuiMessage("{\"action\": \"close\", \"form\": \"none\"}")
end

-- Open GUI to Impound Vehicle
function OpenImpoundGUI()
	if not PlayerData.job or not IsAuthorizedJob(PlayerData.job.name) then
		_Utils.SendNotification(_U('no_impound_allowed'), "error")
		return
	end

	local player = PlayerPedId()
	if IsPedInAnyVehicle(player) then
		_Utils.SendNotification(_U('get_out_car'), "warning")
		return
	end

	local playerCoords = GetEntityCoords(player)
	local vehicle = ESX.Game.GetClosestVehicle(vector3(playerCoords.x, playerCoords.y, playerCoords.z))
	
	if vehicle == nil or (#(GetEntityCoords(vehicle) - playerCoords) > 4.0) then
		_Utils.SendNotification(_U('no_vehicles_nearby'), "error")
		return
	else
		local vehicleProps
		vehicleProps = _Utils.GetVehicleProperties(vehicle)
		ESX.TriggerServerCallback('az_parking:getVehicleCallback', function(vehicleData)
			if vehicleData == nil or vehicleData.owner == nil then
				return ImpoundNoOwnerVehicle(player, vehicle)
			end
			local data = {
				action = "open",
				form = "impound",
				rules  = Config.Impound.Rules,
				vehicle = {
					plate = vehicleData.plate,
					owner = vehicleData.firstname .. ' ' .. vehicleData.lastname,
					parkingprice = vehicleData.price,
					info = PlayerData
				},
				job = PlayerData.job.label,
				officer = vehicleData.officer
			}
			TaskStartScenarioInPlace(player, 'WORLD_HUMAN_CLIPBOARD', 0, true)
			Citizen.Wait(1500)
			ESX.UI.Menu.CloseAll()
			SetNuiFocus(true, true)
			SendNuiMessage(json.encode(data))
			isGUIOpened = true
		end, vehicleProps.plate)
	end
end

--======================
--==== NUI CALLBACKS
--======================

-- NUI Callback for close GUI
RegisterNUICallback('escape', function(data, cb)
	CloseGUI()
end)

-- NUI Callback for recover vehicles
RegisterNUICallback('unimpound', function(plate, cb)
	if currentWarehouse then
		local spawnNumber = nil
		for k, spawnLocation in pairs(currentWarehouse.spawn) do
			if ESX.Game.IsSpawnPointClear(spawnLocation, 5.0) then
				spawnNumber = k
				break
			end
		end
		
		if spawnNumber == nil then
			_Utils.SendNotification(_U('no_spawn_places'), "error")
			return
		end
		
		TriggerServerEvent('az_parking:unimpoundVehicle', plate, currentWarehouse, spawnNumber);
	else
		_Utils.SendNotification(_U('no_impound_location'), "warning")
	end
	CloseGUI()
end)

-- NUI Callback for impound action
RegisterNUICallback('impound', function(data, cb)
	if not PlayerData.job or not IsAuthorizedJob(PlayerData.job.name) then
		_Utils.SendNotification(_U('no_impound_allowed'), "error")
		CloseGUI()
		return
	end
	
	local playerCoords = GetEntityCoords(PlayerPedId())
	local vehicle = ESX.Game.GetClosestVehicle(vector3(playerCoords.x, playerCoords.y, playerCoords.z))
	local vehicleProps
	vehicleProps = _Utils.GetVehicleProperties(vehicle)

	if vehicle == nil or (_Utils.Trim(vehicleProps.plate) ~= _Utils.Trim(data.plate)) then
		_Utils.SendNotification(_U('car_moved'), "error")
		CloseGUI()
		return
	end
	
	SetModelAsNoLongerNeeded(vehicle)
	data.officer = PlayerData.identifier
	data.officerjob = PlayerData.job.name
	TriggerServerEvent('az_parking:generateImpound', data, vehicleProps, vehicle)
	cb(true)
	CloseGUI()
end)

--======================
--==== EVENTS
--======================

-- Spawn Unimpounded Vehicle
RegisterNetEvent('az_parking:spawnUnimpoundedVehicle')
AddEventHandler('az_parking:spawnUnimpoundedVehicle', function (data, zone, spawnNumber)
	local vehicleProps = json.decode(data.vehicle)
	ESX.Game.SpawnVehicle(vehicleProps.model, zone.spawn[spawnNumber], zone.spawn[spawnNumber].h, function (spawnedVehicle)
		SetVehicleHasBeenOwnedByPlayer(spawnedVehicle, true)
		_Utils.SetVehicleProperties(spawnedVehicle, vehicleProps)
		SetVehicleOnGroundProperly(spawnedVehicle)
		TaskWarpPedIntoVehicle(GetPlayerPed(-1), spawnedVehicle, -1)
	end)
	_Utils.SendNotification(_U('recovered_vehicle', data.plate), "success")
end) 

-- Open GUI Handler
RegisterNetEvent('az_parking:openImpoundGUI')
AddEventHandler('az_parking:openImpoundGUI', function ()
	OpenImpoundGUI()
end)

-- Ensure entity removed
RegisterNetEvent('az_parking:deleteEntity')
AddEventHandler('az_parking:deleteEntity', function (entity, plate)
	print("procediendo a eliminar el vehiculo: ", plate)
	local vehicleCoords = GetEntityCoords(entity)	
	SetEntityAsMissionEntity(entity, false, true)
	SetModelAsNoLongerNeeded(entity)
	DeleteVehicle(entity)
	ClearAreaOfVehicles(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 2.0, false, false, false, false, false)

	local playerCoords = GetEntityCoords(GetPlayerPed(-1))
	local vehicle = ESX.Game.GetClosestVehicle(vector3(playerCoords.x, playerCoords.y, playerCoords.z))
	local vehiclePlate = _Utils.GetVehiclePlate(vehicle)
	print("intentando con otro: ", vehiclePlate)

	if vehiclePlate == plate then
		print("coincide con el que esta al frente: ", plate)
		if DoesEntityExist(vehicle) then
			print("eliminando entidad")
			SetEntityAsMissionEntity(vehicle, false, true)
			DeleteVehicle(vehicle)
		end
	end
end)

--======================
--==== THREADS
--======================

Citizen.CreateThread(function()
	while true do
		if currentWarehouse then
			if currentWarehouse.menu then
				_Utils.DisplayHelpText(_U('impound_list'));
				if IsControlJustReleased(0, 38) then
					ShowWarehouseMenu()
				end
			end
			if currentWarehouse.zone then
				DrawMarker(Config.Impound.Marker.type, currentWarehouse.zone, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Impound.Marker.size + 0.5, Config.Impound.Marker.size, 1.0, Config.Impound.Marker.color.r, Config.Impound.Marker.color.g, Config.Impound.Marker.color.b, 100, false, true, 2, true, false, false, false)
				DrawMarker(43, vector3(currentWarehouse.zone.x, currentWarehouse.zone.y, currentWarehouse.zone.z - 2.0), 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Impound.Marker.size + 1.0, Config.Impound.Marker.size + 1.0, 3.0, Config.Impound.Marker.color.r, Config.Impound.Marker.color.g, Config.Impound.Marker.color.b, 100, false, true, 2, true, false, false, false)	
			end
		end

		if IsControlJustReleased(0, 38) and CurrentTask.busy then
			_Utils.SendNotification(_U('task_cancelled'), "info")
			ClearPedTasks(PlayerPedId())
			ESX.ClearTimeout(CurrentTask.task)
			CurrentTask.busy = false
		end
		Citizen.Wait(5)
	end
end)

-- Player position at Warehouse Menu Thread
Citizen.CreateThread(function ()
	while true do
		if ESX ~= nil then
			currentWarehouse = false
			local playerCoords = GetEntityCoords(PlayerPedId())
			for index, warehouse in pairs(_Warehouses) do
				if #(warehouse.menu - playerCoords) < Config.Impound.DrawDistance then
					currentWarehouse = { zone = warehouse.menu }
				end
				if #(warehouse.menu - playerCoords) < 2.0 then
					currentWarehouse.menu = warehouse
					currentWarehouse.spawn = warehouse.spawn
				end
			end
		end
		Citizen.Wait(500)
	end
end)

-- Warehouses Blip Thread
Citizen.CreateThread(function()
	for key, warehouse in pairs(_Warehouses) do
		local blip = AddBlipForCoord(warehouse.menu.x, warehouse.menu.y, warehouse.menu.z)
		SetBlipScale(blip, Config.Impound.Blip.size or 0.9)
		SetBlipDisplay(blip, 4)
		SetBlipSprite(blip, Config.Impound.Blip.sprite or 524)
		SetBlipColour(blip, Config.Impound.Blip.color or 2)
		SetBlipAsShortRange(blip, true)
		SetBlipPriority(blip, 10)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('police_impound'))
		EndTextCommandSetBlipName(blip)
	end
end)

-- Disable background actions if the player is currently in a menu
Citizen.CreateThread(function()
	while true do
		if isGUIOpened then
			local ply = GetPlayerPed(-1)
			local active = true
			DisableControlAction(0, 1, active) -- LookLeftRight
			DisableControlAction(0, 2, active) -- LookUpDown
			DisableControlAction(0, 24, active) -- Attack
			DisablePlayerFiring(ply, true) -- Disable weapon firing
			DisableControlAction(0, 142, active) -- MeleeAttackAlternate
			DisableControlAction(0, 106, active) -- VehicleMouseControlOverride
		end
		Citizen.Wait(500)
	end
end)
