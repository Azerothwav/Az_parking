-- Impound and Remove Vehicle from Real Parking.
RegisterServerEvent('az_parking:generateImpound')
AddEventHandler('az_parking:generateImpound', function (form, vehicleProps, vehicleEntity)
	local _source = source
	xPlayer = ESX.GetPlayerFromId(_source)
	local plate = string.gsub(vehicleProps.plate, "^%s*(.-)%s*$", "%1")
	TriggerEvent('az_parking:getVehicleInfo', function(vehicleData) 
		if vehicleData.owner then
			MySQL.Async.execute('INSERT INTO impounded_vehicles VALUES (@plate, @identifier, @officer, @officerjob, @reason, @fee, @impoundtime, @parkingprice)',
			{
				['@plate'] 			= plate,
				['@identifier']     = vehicleData.owner,
				['@officer']     	= form.officer,
				['@officerjob']     = form.officerjob,
				['@reason']			= form.reason,
				['@fee']			= form.fee,
				['@impoundtime']	= os.time(),
				['@parkingprice']	= vehicleData.price,
			}, function(rowsChanged)
				if (rowsChanged == 0) then
					_Utils.SendServerNotification(_source, _U('error'), 'error')
				else
					TriggerEvent("az_parking:impoundVehicle", function(callback)
						if callback then
							_Utils.SendServerNotification(_source, _U('impounded'), 'success')
							TriggerClientEvent('az_parking:deleteEntity', _source, vehicleEntity, plate)
						else
							_Utils.SendServerNotification(_source, _U('impound_error'), 'error')
						end
					end, vehicleProps, vehicleData.garageName)
				end
			end)
		else
			_Utils.SendServerNotification(_source, _U('owner_error'), 'error')
		end
	end, plate, true, _source)
end)


-- GET Impounded Vehicles
ESX.RegisterServerCallback('az_parking:getImpoundedVehicles', function(playerId, cb)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	MySQL.Async.fetchAll('SELECT impounded_vehicles.*, users.firstname, jobs.label, owned_vehicles.vehicle, owned_vehicles.model, owned_vehicles.'..Config.VehicleNameColumn..' FROM `impounded_vehicles` LEFT JOIN `owned_vehicles` ON impounded_vehicles.plate = owned_vehicles.plate LEFT JOIN `users` ON impounded_vehicles.officer = users.identifier LEFT JOIN `jobs` ON impounded_vehicles.officerjob = jobs.name WHERE impounded_vehicles.identifier = @identifier',
	{
		['@identifier'] = xPlayer.identifier,
	}, function (vehicles)
		for index, dbVehicle in pairs(vehicles) do
			dbVehicle.impoundParkingFee = math.floor(((os.time() - dbVehicle.impoundtime) / 86400) * Config.Impound.ParkingFee)
			dbVehicle.totalprice = dbVehicle.impoundParkingFee + dbVehicle.fee + dbVehicle.parkingprice
		end
		cb(vehicles)
	end)
end)

-- Unimpound Vehicle from database
RegisterServerEvent('az_parking:unimpoundVehicle')
AddEventHandler('az_parking:unimpoundVehicle', function (plate, warehouse, spawnNumber)
	local _source = source
	xPlayer = ESX.GetPlayerFromId(_source)
	if Config.Debug then
		Citizen.Trace('Liberando vehículo con la placa: ' .. plate)
	end
	
	local vehicle = MySQL.Sync.fetchAll('SELECT impounded_vehicles.*, owned_vehicles.vehicle FROM impounded_vehicles LEFT JOIN owned_vehicles ON impounded_vehicles.plate=owned_vehicles.plate WHERE impounded_vehicles.plate=@plate',
	{
		['@plate'] = plate,
	})
	
	if(vehicle == nil) then
		_Utils.SendServerNotification(_source, _U('vehicle_not_found'), 'warning')
		return
	end
	
	local impoundParkingPrice = math.floor(((os.time() - vehicle[1].impoundtime) / 86400) * Config.Impound.ParkingFee)
	local totalParkingPrice = vehicle[1].fee + vehicle[1].parkingprice + impoundParkingPrice
	local playerMoney = xPlayer.getMoney()

	if (playerMoney < totalParkingPrice) then
		local left = totalParkingPrice - playerMoney
		_Utils.SendServerNotification(_source, _U('insufficient_money', left), 'error')
	else
		TriggerEvent('esx_addonaccount:getSharedAccount', Config.Impound.Society, function(account)
			xPlayer.removeMoney(totalParkingPrice)
			account.addMoney(totalParkingPrice)
		end)
		local deleteFromImpounded = MySQL.Sync.execute('DELETE FROM impounded_vehicles WHERE plate=@plate',
		{
			['@plate'] = plate,
		})
		local updateState = MySQL.Sync.execute('UPDATE owned_vehicles SET pound=0, `stored`=0 WHERE plate=@plate',
		{
			['@plate'] = plate,
		})
		if deleteFromImpounded and updateState then
			TriggerClientEvent('az_parking:spawnUnimpoundedVehicle', _source, vehicle[1], warehouse, spawnNumber)
		else
			_Utils.SendServerNotification(_source, _U('database_error'), 'error')
		end
	end
	
end)