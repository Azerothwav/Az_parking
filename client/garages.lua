lastvehicle, lastvehiclemodel, lastvehicleplate = nil, nil, nil
local estimatedSpeed, vehiclechair, speedaccel, freinage, fuelLevel, btZoneCharge = 0.0, 0.0, 0.0, 0.0, 0.0, false
StunVehicle = {}
RageMenu.Menu.isOpen = false
RageMenu.Menu.Garage = RageUI.CreateMenu("", "Garage", nil, nil, "azui_main", "azui_garage")
RageMenu.Menu.GarageSpawn = RageUI.CreateSubMenu(RageMenu.Menu.Garage, "", "Garage", nil, nil, "azui_main", "azui_garage")

RageMenu.Menu.Garage.Closed = function()
	RageMenu.Menu.isOpen = false
    RageUI.Visible(RageMenu.Menu.Garage, false)
	RageUI.Visible(RageMenu.Menu.GarageSpawn, false)
	RenderScriptCams(false, 1, 1500, 1, 0)
	DestroyCam(MainCamera, false)
	if DoesEntityExist(lastvehicle) then
		DeleteEntity(lastvehicle)
	end
	lastvehicle, lastvehicleplate = nil, nil
end

function ChargeData(GaragesTable, RecoversTable)
	if GaragesTable ~= nil and RecoversTable ~= nil then
		for k, v in pairs(Recovers) do
			Recovers[k] = nil
		end
		for k, v in pairs(GaragesDataJSON) do
			GaragesDataJSON[k] = nil
		end
		for k, v in pairs(GaragesTable) do
			GaragesDataJSON[k] = {}
			for x, w in pairs(v) do
				GaragesDataJSON[k][x] = w
			end
		end
		for k, v in pairs(RecoversTable) do
			Recovers[k] = {}
			for x, w in pairs(v) do
				Recovers[k][x] = w
			end
		end
	else
		local result = json.decode(LoadResourceFile("Az_parking", "data/garages.json"))
		if result ~= nil then
			for k, v in pairs(result) do
				GaragesDataJSON[k] = {}
				for x, w in pairs(v) do
					GaragesDataJSON[k][x] = w
				end
			end
		end
		local result2 = json.decode(LoadResourceFile("Az_parking", "data/recovers.json"))
		if result2 ~= nil then
			for k, v in pairs(result2) do
				Recovers[k] = {}
				for x, w in pairs(v) do
					Recovers[k][x] = w
				end
			end
		end
	end
	LaunchBlips()
end

RegisterNetEvent('az_garage:rebootGarage')
AddEventHandler('az_garage:rebootGarage', function(GaragesTable, RecoversTable)
	ChargeData(GaragesTable, RecoversTable)
end)

AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		Citizen.Wait(500)
		ChargeData()
	end
end)

AddEventHandler("az_parking:storeVehicle", function(data)
	StoreCurrentVehicle(GetVehiclePedIsIn(PlayerPedId(), false), data.name, data.jobname)
end)

function StoreCurrentVehicle(vehicle, garageName, jobname)
	local vehicleProps = _Utils.GetVehicleProperties(vehicle)
	local cansqlrequest = true
	for k, v in pairs(StunVehicle) do
		if vehicleProps.plate == v then
			cansqlrequest = false
			_Utils.SendNotification(Config.Lang["car_error"])
		end
	end
	if cansqlrequest then
		if vehicleProps and vehicleProps.tankHealth < 200 then
			_Utils.SendNotification(Config.Lang["car_broken"])
			return
		end
		_Utils.CallBack("az_parking:storeVehicle", function(callback)
			if callback.status then
				TaskLeaveVehicle(PlayerPedId(), vehicle, 64)
				Citizen.Wait(1500)
				RemoveCarFromEarth(vehicleProps.plate, vehicle)
				SetEntityAsMissionEntity(vehicle, false, false)
				SetEntityAsNoLongerNeeded(vehicle)
				TriggerServerEvent("az_parking:deleteCar", VehToNet(vehicle))
				_Utils.SendNotification(Config.Lang["car_save"])
			else
				if callback.stunvehicle ~= nil and callback.stunvehicle then
					table.insert(StunVehicle, vehicleProps.plate)
				end
				_Utils.SendNotification(callback.message)
			end
		end, {props = vehicleProps, garageName = garageName, garageJobName = jobname})
	end
end

function transferejob(vehData, garageName)
	local props = json.decode(vehData.mods)
	_Utils.CallBack("az_parking:getOutFromGarage", function(callback)
		local vehicle = callback.vehData
		plate = props.plate
		TriggerServerEvent('az_parking:transfereJob', plate)
		if callback.status then
			_Utils.SpawnVehicle(vehicle.props.model, spawnPos, vehicle.props.plate, function(vehicleEntity)
				AddCarOnEarth(vehicle.props.plate, vehicleEntity)
				TaskWarpPedIntoVehicle(PlayerPedId(), vehicleEntity, -1)
				SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
				SetVehicleOnGroundProperly(vehicleEntity)
				SetEntityAsMissionEntity(vehicleEntity, true, true)
				_Utils.SetVehicleProperties(vehicleEntity, vehicle.props, true)
			end)
			_Utils.SendNotification(Config.Lang["car_out"])
		else
			_Utils.SendNotification(Config.Lang["car_error"])
		end
	end, vehData, garageName)
end

function SpawnGarageVehicle(vehData, garageName, possibleSpawn, garagetype, jobname)
	DoScreenFadeOut(500)
	Citizen.Wait(1000)
	local freeSpawn = false
	local spawnPos = nil
	if type(possibleSpawn) == "table" then
		for k,v in pairs(possibleSpawn) do
			local coordsTest = vector3(v.x, v.y, v.z)
			if _Utils.IsPositionFree(coordsTest, 1.5) then
				spawnPos = vector4(v.x, v.y, v.z, v.w)
				freeSpawn = true
			end
		end
	else
		if _Utils.IsPositionFree(possibleSpawn, 1.5) then
			spawnPos = possibleSpawn
			freeSpawn = true
		end
	end
	if garagetype == "civil" then
		if freeSpawn then
			_Utils.CallBack("az_parking:getOutFromGarage", function(callback)
				local vehicle = callback.vehData
				if callback.status then
					_Utils.SpawnVehicle(vehicle.props.model, spawnPos, vehicle.props.plate, function(vehicleEntity)
						AddCarOnEarth(vehicle.props.plate, vehicleEntity)
						TaskWarpPedIntoVehicle(PlayerPedId(), vehicleEntity, -1)
						SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
						SetVehicleOnGroundProperly(vehicleEntity)
						SetEntityAsMissionEntity(vehicleEntity, true, true)
						_Utils.SetVehicleProperties(vehicleEntity, vehicle.props, true)
					end)
					_Utils.SendNotification(Config.Lang["car_out"])
				else
					_Utils.SendNotification(Config.Lang["car_error"])
				end
			end, vehData, garageName)
		else
			_Utils.SendNotification(Config.Lang["no_place"])
		end
	elseif garagetype == "job" then
		if DoesEntityExist(lastvehicle) then
			DeleteEntity(lastvehicle)
		end
		if freeSpawn then
			_Utils.SpawnVehicle(lastvehiclemodel, spawnPos, vehData.plate, function(vehicleEntity)
				AddCarOnEarth(vehData.plate, vehicleEntity)
				TaskWarpPedIntoVehicle(PlayerPedId(), vehicleEntity, -1)
				SetVehicleOnGroundProperly(vehicleEntity)
				TriggerServerEvent('az_parking:setJobVehicleState', {plate = vehData.plate, state = false, jobname = jobname})
				_Utils.SendNotification(Config.Lang["car_out"])
				_Utils.SetVehicleProperties(vehicleEntity, vehData, true)
			end)
		else
			_Utils.SendNotification(Config.Lang["no_place"])
		end
	elseif garagetype == "recover" then
		_Utils.CallBack("az_parking:getOutFromRecover", function(callback)
			local vehicle = callback.vehData
			if callback.status then
				if freeSpawn then
					_Utils.SpawnVehicle(vehicle.props.model, spawnPos, vehicle.props.plate, function(vehicleEntity)
						AddCarOnEarth(vehicle.props.plate, vehicleEntity)
						TaskWarpPedIntoVehicle(PlayerPedId(), vehicleEntity, -1)
						SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
						SetVehicleOnGroundProperly(vehicleEntity)
						_Utils.SetVehicleProperties(vehicleEntity, vehicle.props, true)
					end)
					_Utils.SendNotification(Config.Lang["car_out"])
				end
			else
				_Utils.SendNotification(Config.Lang["car_error"])
			end
		end, {vehicle = vehData, jobname = jobname})
	end
	Citizen.Wait(1000)
	DoScreenFadeIn(500)
end

TriggerEvent('az_parking:storeCarHouse', 'House')

AddEventHandler("az_parking:getVehicle", function(data)
	OpenSpawnMenu(data.name, data.jobname, data.possibleSpawn) 
end)

function OpenSpawnMenu(garageName, jobname, possibleSpawn) 
	RageMenu.Menu.isOpen = true
	if jobname ~= nil and jobname ~= "none" and jobname ~= "civ" then
		if _Utils.CanAccessGarage(jobname) then
			_Utils.CallBack("az_parking:retrieveJobVehicles", function(jobVehicles)
				if #jobVehicles > 0 then
					local vehiclespawn = nil
					RageUI.Visible(RageMenu.Menu.Garage, not RageUI.Visible(RageMenu.Menu.Garage))
					while RageMenu.Menu.isOpen do
						RageUI.IsVisible(RageMenu.Menu.Garage, function()
							for k, v in pairs(jobVehicles) do 
								if v.stored then
									RageUI.Button(_Utils.GenerateVehicleLabel(v, v.vehiclename), "Essence ["..fuelLevel.. "] / Vitesse Max ["..estimatedSpeed..'] / Places ['..vehiclechair.. '] / Acceleration ['..speedaccel.. '] / Freinage ['..freinage..']', {}, true, {
										onSelected = function()
											ShowVehicleBeforeSpawn(v.vehicle, possibleSpawn)
											vehiclespawn = v
											RageUI.Visible(RageMenu.Menu.Garage, not RageUI.Visible(RageMenu.Menu.Garage))
											RageUI.Visible(RageMenu.Menu.GarageSpawn, not RageUI.Visible(RageMenu.Menu.GarageSpawn))
										end
									})
								elseif v.state == 1 then
									RageUI.Button(_Utils.GenerateVehicleLabel(v, v.vehiclename), "Essence ["..fuelLevel.. "] / Vitesse Max ["..estimatedSpeed..'] / Places ['..vehiclechair.. '] / Acceleration ['..speedaccel.. '] / Freinage ['..freinage..']', {}, true, {
										onSelected = function()
											ShowVehicleBeforeSpawn(v.mods, possibleSpawn)
											vehiclespawn = v
											RageUI.Visible(RageMenu.Menu.Garage, not RageUI.Visible(RageMenu.Menu.Garage))
											RageUI.Visible(RageMenu.Menu.GarageSpawn, not RageUI.Visible(RageMenu.Menu.GarageSpawn))
										end
									})
								else
									RageUI.Button("~r~".._Utils.GenerateVehicleLabel(v, v.vehiclename), "Essence ["..fuelLevel.. "] / Vitesse Max ["..estimatedSpeed..'] / Places ['..vehiclechair.. '] / Acceleration ['..speedaccel.. '] / Freinage ['..freinage..']', {}, true, {
										onSelected = function()
											_Utils.SendNotification(Config.Lang["vehicle_already_out"])
										end
									})
								end
							end
						end)
						RageUI.IsVisible(RageMenu.Menu.GarageSpawn, function()
							RageUI.Button(Config.Lang["get_out_vehicle"], nil, {}, true, {
								onSelected = function()
									RageMenu.Menu.Garage.Closed()
									if Config.FrameWork == "ESX" then
										SpawnGarageVehicle(json.decode(vehiclespawn.vehicle), garageName, possibleSpawn, "job", jobname)
									elseif Config.FrameWork == "QBCore" then
										SpawnGarageVehicle(json.decode(vehiclespawn.mods), garageName, possibleSpawn, "job", jobname)
									end
								end,
								onActive = function()
									for k, v in pairs(possibleSpawn) do
										DrawMarker(20, v.x, v.y, v.z + 1.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0., 0.3, 255, 255, 255, 200, 1, true, 2, 0, nil, nil, 0)
									end
								end
							})
							RageUI.Button(Config.Lang["rename_vehicle"], nil, {}, true, {
								onSelected = function()
									RageMenu.Menu.Garage.Closed()
									TriggerServerEvent('az_parking:renamevehicle', vehiclespawn.plate, _Utils.ActiveKeyboard(k, 64))
								end
							})
						end)
						Citizen.Wait(0)
					end
				else
					_Utils.SendNotification(Config.Lang["no_vehicle"])
				end
			end, {jobname = jobname, garageName = garageName})
		else
			_Utils.SendNotification(Config.Lang["cant_access"])
		end
	else
		local vehiclespawn = nil
		_Utils.CallBack("az_parking:getGarageCars", function(vehicles)
			if vehicles == nil or not type(rs) == 'table' then
				_Utils.SendNotification(Config.Lang["no_vehicle"])
			else
				RageUI.Visible(RageMenu.Menu.Garage, not RageUI.Visible(RageMenu.Menu.Garage))
				while RageMenu.Menu.isOpen do
					RageUI.IsVisible(RageMenu.Menu.Garage, function()
						for k, v in pairs(vehicles) do 
							RageUI.Button(_Utils.GenerateVehicleLabel(v, v.vehiclename), "Essence ["..fuelLevel.. "] / Vitesse Max ["..estimatedSpeed..'] / Places ['..vehiclechair.. '] / Acceleration ['..speedaccel.. '] / Freinage ['..freinage..']', {}, true, {
								onSelected = function()
									if Config.FrameWork == "ESX" then
										ShowVehicleBeforeSpawn(v.vehicle, possibleSpawn)
									elseif Config.FrameWork == "QBCore" then
										ShowVehicleBeforeSpawn(v.mods, possibleSpawn)
									end
									RageUI.Visible(RageMenu.Menu.Garage, not RageUI.Visible(RageMenu.Menu.Garage))
									RageUI.Visible(RageMenu.Menu.GarageSpawn, not RageUI.Visible(RageMenu.Menu.GarageSpawn))
									vehiclespawn = v
								end
							})
						end
					end)
					RageUI.IsVisible(RageMenu.Menu.GarageSpawn, function()
						RageUI.Button(Config.Lang["get_out_vehicle"], nil, {}, true, {
							onSelected = function()
								RageMenu.Menu.Garage.Closed()
								SpawnGarageVehicle(vehiclespawn, garageName, possibleSpawn, "civil")
							end,
							onActive = function()
								for k, v in pairs(possibleSpawn) do
									DrawMarker(20, v.x, v.y, v.z + 1.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0., 0.3, 255, 255, 255, 200, 1, true, 2, 0, nil, nil, 0)
								end
							end
						})
						if _Utils.IsBoss() then
							RageUI.Button(Config.Lang["transfert_vehicle"], nil, {}, true, {
								onSelected = function()
									RageMenu.Menu.Garage.Closed()
									transferejob(vehiclespawn, garageName)
								end
							})
						end
						RageUI.Button(Config.Lang["rename_vehicle"], nil, {}, true, {
							onSelected = function()
								RageMenu.Menu.Garage.Closed()
								TriggerServerEvent('az_parking:renamevehicle', vehiclespawn.plate, _Utils.ActiveKeyboard(k, 64))
							end
						})
					end)
					Citizen.Wait(0)
				end
			end
		end, {garageName = garageName, vehType = 'car'})
	end
end

function ShowVehicleBeforeSpawn(vehicle, possibleSpawn)
	props = json.decode(vehicle)
	if lastvehicleplate ~= props.plate then
		DeleteEntity(lastvehicle)
		while DoesEntityExist(lastvehicle) ~= false do
			DeleteEntity(lastvehicle)
			Citizen.Wait(0)
		end
		lastvehicleplate = props.plate
		lastvehiclemodel = props.model
		for k, v in pairs(possibleSpawn) do
			local coordsTest = vector3(v.x, v.y, v.z)
			if _Utils.IsPositionFree(coordsTest, 1.5) then
				spawnPos = vector4(v.x, v.y, v.z, v.w)
				freeSpawn = true
			end
		end
		if freeSpawn then
			_Utils.SpawnVehicle(props.model, spawnPos, props.plate, function(vehicleEntity)
				MainCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', GetEntityCoords(vehicleEntity), 0.0, 0.0, 0.0, 90.0, true, 2)
				while not DoesCamExist(MainCamera) do
					Citizen.Wait(500)
				end
				PointCamAtEntity(MainCamera, vehicleEntity, 0.0, 0.0, 0.0, 1)
				AttachCamToVehicleBone(MainCamera, vehicleEntity, GetEntityBoneIndexByName(vehicleEntity, 'bonnet'), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true)
				DetachCam(MainCamera)
				local camcoords = GetCamCoord(MainCamera)
				SetCamCoord(MainCamera, camcoords.x - 3.0, camcoords.y - 2.5, camcoords.z + 1.0)
				RenderScriptCams(true, 1, 1500, 1, 0)
				lastvehicle = vehicleEntity
				estimatedSpeed = _Utils.Round(GetVehicleEstimatedMaxSpeed(vehicleEntity) * 3.6, 1)
				vehiclechair = GetVehicleMaxNumberOfPassengers(vehicleEntity) + 1
				speedaccel = _Utils.Round(GetVehicleAcceleration(vehicleEntity), 1)
				freinage = _Utils.Round(GetVehicleMaxBraking(vehicleEntity),1)
				fuelLevel = _Utils.Round(props.fuelLevel)
				FreezeEntityPosition(vehicleEntity, true)
				SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
				SetVehicleOnGroundProperly(vehicleEntity)
				SetDisableVehicleWindowCollisions(vehicleEntity, false)
				SetEntityAlpha(vehicleEntity, 150)
				SetEntityCollision(vehicleEntity, false, false)
				_Utils.SetVehicleProperties(vehicleEntity, props, false)
			end)
		end
	end
end

Citizen.CreateThread(function()
	while true do
		wait = 1000
		if #GaragesDataJSON > 0 then
			local playerCoords = GetEntityCoords(PlayerPedId())
			if not RageUI.Visible(RageMenu.Menu.Garage) and not RageUI.Visible(RageMenu.Menu.GarageSpawn) then
				if not Config.UseBtTarget then
					for k, v in pairs(GaragesDataJSON) do
						local positionPos = vector3(v.position.x, v.position.y, v.position.z)
						local deletePos = vector3(v.delete.x, v.delete.y, v.delete.z)
						if GetDistanceBetweenCoords(positionPos, playerCoords, true) < 20 then
							wait = 0
							if v.jobname ~= 'civ' and v.jobname ~= 'none' then
								_Utils.Draw3DText(v.position.x, v.position.y, v.position.z - 1.3, Config.Lang["private_garage"], 4, 0.15, 0.15)
							else
								_Utils.Draw3DText(v.position.x, v.position.y, v.position.z - 1.3, Config.Lang["public_garage"], 4, 0.15, 0.15)
							end
							DrawMarker(36, positionPos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)
							DrawMarker(25, vector3(positionPos.x, positionPos.y, positionPos.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)
							DrawMarker(5, deletePos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, true, false, false, false)
							DrawMarker(27, vector3(deletePos.x, deletePos.y, deletePos.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 1.0, 255, 255, 255, 100, false, true, 2, true, false, false, false)
							if GetDistanceBetweenCoords(deletePos, playerCoords, true) < 2 then
								_Utils.DisplayHelpText(Config.Lang["delete_help"])
								if IsControlJustReleased(0, 38) then
									local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
									if currentVehicle and currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
										if _Utils.CanAccessGarage(v.jobname) then
											StoreCurrentVehicle(currentVehicle, v.name, v.jobname)
										else
											_Utils.SendNotification(Config.Lang["cant_access"])
										end
									else
										_Utils.SendNotification(Config.Lang["not_in_a_vehicle"])
									end
								end
							elseif GetDistanceBetweenCoords(positionPos, playerCoords, true) < 1 then
								_Utils.DisplayHelpText(Config.Lang["spawn_help"])
								if IsControlJustReleased(0, 38) then
									if IsPedInAnyVehicle(PlayerPedId(), false) then
										_Utils.SendNotification(Config.Lang["cant_in_a_vehicle"])
									else
										if _Utils.CanAccessGarage(v.jobname) then
											OpenSpawnMenu(v.name, v.jobname, v.spawnPos)
										else
											_Utils.SendNotification(Config.Lang["cant_access"])
										end
									end
								end
							end
						end
					end
				else
					if not btZoneCharge then
						btZoneCharge = true
						for k, v in pairs(GaragesDataJSON) do
							for x, w in pairs(v.spawnPos) do
								local interactionPos = vector4(w.x, w.y, w.z + 0.5, w.w)
								if Config.TargetRessource == "ox_target" then
									exports[Config.TargetRessource]:AddBoxZone({
										coords = interactionPos.xyz,
										size = vec3(4, 4, 4),
										rotation = 45,
										debug = false,
										options = {
											{
												name = v.name,
												event = 'az_parking:getVehicle',
												icon = 'fas fa-warehouse',
												label = Config.Lang["see_vehicle"],
												possibleSpawn = GaragesDataJSON[k]["spawnPos"],
												jobname = v.jobname,
												canInteract = function(entity, distance, coords, name)
													if not IsPedInAnyVehicle(PlayerPedId(), false) then
														if _Utils.CanAccessGarage(v.jobname) then
															return true
														else
															return false
														end
													else
														return false
													end
												end
											},
											{
												name = v.name,
												event = 'az_parking:storeVehicle',
												icon = 'fas fa-parking',
												label = Config.Lang["put_in_garage"],
												jobname = v.jobname,
												canInteract = function(entity, distance, coords, name)
													if IsPedInAnyVehicle(PlayerPedId(), false) then
														if _Utils.CanAccessGarage(v.jobname) then
															return true
														else
															return false
														end
													else
														return false
													end
												end
											}
										}
									})
								else
									exports[Config.TargetRessource]:AddBoxZone(v.name..x, interactionPos.xyz, 5.0, 2.0, {
										name = v.name..x,
										heading = interactionPos.w,
										debugPoly = false,
										minZ = interactionPos.z - 5.0,
										maxZ = interactionPos.z + 5.0,
									}, {
										options = {
											{
												name = v.name,
												type = "client",
												event = "az_parking:getVehicle",
												icon = "fas fa-warehouse",
												label = Config.Lang["see_vehicle"],
												jobname = v.jobname,
												possibleSpawn = GaragesDataJSON[k]["spawnPos"],
												canInteract = function(entity)
													if not IsPedInAnyVehicle(PlayerPedId(), false) then
														if _Utils.CanAccessGarage(v.jobname) then
															return true
														else
															return false
														end
													else
														return false
													end
												end
											},
											{
												name = v.name,
												type = "client",
												event = "az_parking:storeVehicle",
												icon = "fas fa-parking",
												label = Config.Lang["put_in_garage"],
												jobname = v.jobname,
												canInteract = function(entity)
													if IsPedInAnyVehicle(PlayerPedId(), false) then
														if _Utils.CanAccessGarage(v.jobname) then
															return true
														else
															return false
														end
													else
														return false
													end
												end
											},
										},
										distance = 3.0
									})
								end
							end
						end
					end
				end
			end
		end
		Citizen.Wait(wait)
	end
end)

local BlipJob = {}
function LaunchBlips()
	Citizen.CreateThread(function()
		if #BlipJob > 0 then
			for k, v in pairs(BlipJob) do
				RemoveBlip(v)
			end
		end
		for k, v in pairs(GaragesDataJSON) do
			blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
			SetBlipPriority(blip, 8)
			SetBlipScale(blip, 0.5)
			SetBlipAsShortRange(blip, true)
			if v.jobname ~= 'civ' and v.jobname ~= 'none' then
				if _Utils.CanAccessGarage(v.jobname) then
					SetBlipSprite(blip, 524)
					SetBlipColour(blip, 12)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString('Garage '..v.jobname)
					EndTextCommandSetBlipName(blip)
					table.insert(BlipJob, blip)
				else
					RemoveBlip(blip)
				end
			else
				SetBlipSprite(blip, 524)
				SetBlipColour(blip, 12)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString('Garage')
				EndTextCommandSetBlipName(blip)
			end
		end
		for k, v in pairs(Recovers) do
			local blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
			SetBlipSprite(blip, 38)
			SetBlipColour(blip, 57)
			SetBlipScale(blip, 0.4)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName("STRING")
			if v.jobname ~= nil then
				AddTextComponentString(Config.Lang["private_recover"])
			else
				AddTextComponentString(Config.Lang["public_recover"])
			end
			EndTextCommandSetBlipName(blip)
		end
	end)
end