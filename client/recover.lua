RageMenu.Menu.RecoverIsOpen = false
RageMenu.Menu.Recover = RageUI.CreateMenu("", "Recover", nil, nil, "azui_main", "azui_garage")
RageMenu.Menu.RecoverSpawn = RageUI.CreateSubMenu(RageMenu.Menu.Recover, "", "Garage", nil, nil, "azui_main", "azui_garage")

RageMenu.Menu.Recover.Closed = function()
	RageMenu.Menu.RecoverIsOpen = false
    RageUI.Visible(RageMenu.Menu.Recover, false)
	RageUI.Visible(RageMenu.Menu.RecoverSpawn, false)
	RenderScriptCams(false, 1, 1500, 1, 0)
	DestroyCam(MainCamera, false)
	if DoesEntityExist(lastvehicle) then
		DeleteEntity(lastvehicle)
	end
	lastvehicle, lastvehiclemodel, lastvehicleplate = nil, nil, nil
end

function OpenMenuRecover(jobname, typeVeh, spawn)
	_Utils.CallBack("az_parking:getNotStored", function(vehicles)
		if #vehicles == 0 then
			_Utils.SendNotification(Config.Lang["no_vehicle"])
		else
			local vehiclespawn = nil
			RageUI.Visible(RageMenu.Menu.Recover, not RageUI.Visible(RageMenu.Menu.Recover))
			RageMenu.Menu.RecoverIsOpen = true
			while RageMenu.Menu.RecoverIsOpen do
				RageUI.IsVisible(RageMenu.Menu.Recover, function()
					for k, v in pairs(vehicles) do 
						RageUI.Button(_Utils.GenerateVehicleLabel(v), nil, {}, true, {
							onSelected = function()
								ShowVehicleBeforeSpawn(v.vehicle, spawn)
								if not IsCarOnEarth(v.plate) and not _Utils.DoesAPlayerDrivesCar(v.plate) then
									vehiclespawn = v
									RageUI.Visible(RageMenu.Menu.Recover, not RageUI.Visible(RageMenu.Menu.Recover))
									RageUI.Visible(RageMenu.Menu.RecoverSpawn, not RageUI.Visible(RageMenu.Menu.RecoverSpawn))
								else
									_Utils.SendNotification(Config.Lang["vehicle_on_map"])
								end
							end
						})
					end
				end)
				RageUI.IsVisible(RageMenu.Menu.RecoverSpawn, function()
					RageUI.Button(Config.Lang["get_out_vehicle"], nil, {}, true, {
						onSelected = function()
							RageMenu.Menu.Recover.Closed()
							SpawnGarageVehicle(vehiclespawn, nil, spawn, "recover", jobname)
						end,
						onActive = function()
							for k, v in pairs(spawn) do
								DrawMarker(20, v.x, v.y, v.z + 1.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0., 0.3, 255, 255, 255, 200, 1, true, 2, 0, nil, nil, 0)
							end
						end
					})
				end)
				Citizen.Wait(0)
			end
		end
	end, {type = typeVeh, jobname = jobname})
end

AddEventHandler("az_parking:openRecovers", function(data)
	OpenMenuRecover(data.jobname, data.typeVeh, data.possibleSpawn)
end)

Citizen.CreateThread(function()
	while true do
		local wait = 1000
		if ESX ~= nil then
			local playerCoords = GetEntityCoords(PlayerPedId())
			for k, v in pairs(Recovers) do
				if not Config.UseBtTarget then
					local position = vector3(v.position.x, v.position.y, v.position.z)
					if GetDistanceBetweenCoords(position, playerCoords, true) < 20 then
						wait = 0 
						if v.jobname ~= nil and v.jobname ~= 'civ' then
							_Utils.Draw3DText(v.position.x, v.position.y, v.position.z - 0.7, Config.Lang["private_recover"], 4, 0.15, 0.15)
						else
							_Utils.Draw3DText(v.position.x, v.position.y, v.position.z - 0.7, Config.Lang["public_recover"], 4, 0.15, 0.15)
						end
						DrawMarker(36, position, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)
						DrawMarker(25, vector3(position.x, position.y, position.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)
						if not RageUI.Visible(RageMenu.Menu.Recover) then
							if GetDistanceBetweenCoords(position, playerCoords, true) < 2 then
								_Utils.DisplayHelpText(Config.Lang["recover_help"])
							end
							if IsControlJustReleased(0, 38) then
								if IsPedInAnyVehicle(PlayerPedId(), false) then
									_Utils.SendNotification(Config.Lang["cant_in_a_vehicle"])
								else
									OpenMenuRecover(v.jobname, v.typeVeh, v.spawnPos)
								end
							end
						end
					end
				else
					if not btZoneCharge then
						btZoneCharge = true
						for x, w in pairs(v.spawnPos) do
							local interactionPos = vector4(w.x, w.y, w.z + 0.5, w.w)
							exports[Config.TargetRessource]:addBoxZone({
								coords = interactionPos.xyz,
								size = vec3(4, 4, 4),
								rotation = 45,
								debug = false,
								options = {
									{
										name = v.name,
										jobname = v.jobname,
										typeVeh = v.typeVeh,
										event = 'az_parking:openRecovers',
										icon = 'fas fa-warehouse',
										label = Config.Lang["see_recover_vehicle"],
										possibleSpawn = Recovers[k]["spawnPos"],
										index = k,
										canInteract = function(entity, distance, coords, name)
											if not IsPedInAnyVehicle(PlayerPedId(), false) then
												return true
											else
												return false
											end
										end
									}
								}
							})
						end
					end
				end
			end
		end
		Citizen.Wait(wait)
	end
end)