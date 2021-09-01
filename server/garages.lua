-- Get out from garage to Drive
ESX.RegisterServerCallback("az_parking:getOutFromGarage", function(source, callback, vehicle, garageName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plate   = vehicle.plate
	
	MySQL.Async.fetchAll("SELECT owner,plate,type,vehicle,garage_name,garage_time,location,job FROM owned_vehicles WHERE `owner` = @identifier AND `plate` = @plate AND `stored` = 1", {
		['@identifier'] = xPlayer.identifier,
		['@plate']      = plate,
		['@garage_type']  = Config.Garages.Type
	}, function(rs)
		if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
			
			if rs[1].job ~= nil and (Config.EnableCivJob and rs[1].job ~= Config.CivJob) and rs[1].job ~= xPlayer.job.name then
				callback({
					status  = false,
					message = string.format(_U("wrong_job")),
					vehData = vehicleData
				})
				return;
			end

			local fee = 0
			if _Garages[rs[1].garage_name] then
				fee = _Utils.GetParkingPrice(rs[1].garage_time, _Garages[rs[1].garage_name].fee, _Garages[rs[1].garage_name].minFee)
			end
			local playerMoney = xPlayer.getMoney()
			
			if playerMoney >= fee then
				if _Garages[rs[1].garage_name] and _Garages[rs[1].garage_name].society then
					TriggerEvent('esx_addonaccount:getSharedAccount', _Garages[rs[1].garage_name].society, function(account)
						xPlayer.removeMoney(fee)
						account.addMoney(fee)
					end)
				else
					xPlayer.removeMoney(fee)
				end
				MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `location` = NULL, `garage_name` = NULL, `garage_time` = NULL, `garage_type`=@garage_type WHERE `plate` = @plate AND `owner` = @identifier', {
					["@plate"]      = plate,
					["@identifier"] = xPlayer.identifier,
                    ['@garage_type']  = Config.Garages.Type
				})
				local vehicleData = { 
					plate = rs[1].plate, 
					props = json.decode(rs[1].vehicle), 
					garageTime = rs[1].garage_time, 
					owner = rs[1].owner, 
					garageName = rs[1].garage_name
				}
				if fee == 0 then
					callback({
						status  = true,
						message = string.format(_U("pay_free_success")),
						vehData = vehicleData
					})
					return;
				else
					callback({
						status  = true,
						message = string.format(_U("pay_success", fee)),
						vehData = vehicleData
					})
					return;
				end
			else
				local left = fee - playerMoney
				callback({
					status  = false,
					message = _U("not_enough_money_left", left),
				})
				return;
			end
		else
			callback({
				status  = false,
				message = _U("invalid_car"),
			})
			return;
		end
	end)
end)

-- Get VEHICLE parking price from FEE
ESX.RegisterServerCallback("az_parking:getCarGaragePrice", function(source, cb, plate)
	if Config.Debug then
		print("Buscando placa: ".. plate)
	end
	MySQL.Async.fetchAll("SELECT owner, garage_name,garage_time FROM owned_vehicles WHERE `plate`= @plate AND `garage_type` = @garage_type", {
		['@plate'] = plate,
		['@garage_type']  = Config.Garages.Type
	}, function(response) 
		if type(response) == 'table' and response[1] ~= nil then
			if Config.Debug then
				print("We have founded one or more vehicles")
				print(json.encode(response[1]))
			end
			local vehicleInfo = response[1]
			local garageName = vehicleInfo.garage_name
			local fee = 0
			if garageName == nil then
				-- TODO: NOTIFY CAR PARKING NAME NOT FOUND
				if Config.Debug then
					print("Parking not founded")
				end
				cb(0, 0, response[1].owner, nil)
			end
			if vehicleInfo.garage_time ~= nil and _Garages[garageName] ~= nil and _Garages[garageName].fee ~= nil then
				if Config.Debug then
					print("Parking price cannot be calculated")
				end
				local currentFee = _Utils.GetParkingPrice(vehicleInfo.garage_time, _Garages[garageName].fee, _Garages[garageName].minFee)
				if Config.Debug then
					print("Price of parking: "..currentFee)
				end
				cb(currentFee, _Garages[garageName].fee, response[1].owner, garageName)
			else
				-- TODO: NOTIFY CAR FEE ERROR
				cb(0, 0, response[1].owner, garageName)
			end
		else
			-- TODO: NOTIFY CAR NOT FOUND ERROR
			if Config.Debug then
				print("No se encontraron vehiculos")
			end
			cb(0, 0, nil, nil)
		end
	end)
end)

ESX.RegisterServerCallback('az_parking:getGarageCars', function(source, cb, garageName)
    local _source = source
    xPlayer = ESX.GetPlayerFromId(_source)
    identifier = xPlayer.identifier

	local query = 'SELECT * FROM owned_vehicles WHERE owner=@identifier AND (job IS NULL OR job = @job) AND garage_name=@garageName AND garage_type=@garageType'
	if Config.EnableCivJob then
		query = 'SELECT * FROM owned_vehicles WHERE owner=@identifier AND (job IS NULL OR job = "civ" OR job = @job) AND garage_name=@garageName AND garage_type=@garageType'
	end

    if _Garages[garageName] then
        MySQL.Async.fetchAll(
			query,
        {
            ['@identifier'] = identifier,
            ['@job'] = xPlayer.job.name,
            ['@garageName'] = garageName,
            ['@garageType'] = Config.Garages.Type
        },
        function(result)
			local vehicles = nil
            if type(result) == 'table' and #result > 0 then
				vehicles = {}
                for key, vehicle in pairs(result) do
                    if _Garages[garageName].fee and _Garages[garageName].fee > 0 then
                        local addVehicle = vehicle
                        addVehicle.parkingPrice = _Utils.GetParkingPrice(vehicle.garage_time, _Garages[garageName].fee, _Garages[garageName].minFee)
                        table.insert(vehicles, addVehicle)
                    else
                        table.insert(vehicles, vehicle)
                    end
                end
                cb(vehicles)
            end
            cb(vehicles)
        end)
    else
        print(_U('garage_error'))
    end
end)

ESX.RegisterServerCallback('az_parking:storeVehicle', function(source, cb, vehicle)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local plate   = vehicle.props.plate
    
    if vehicle.garageName == nil or _Garages[vehicle.garageName] == nil then
        cb({
            status  = false,
            message = _U("parking_not_found"),
        })
    end

    if xPlayer then
        _Utils.SaveCarInDatabase(xPlayer, vehicle, plate, Config.Garages.Type, cb)
    else
        cb({
            status  = false,
            message = _U("player_error"),
        })
    end
end)


ESX.RegisterServerCallback('az_parking:retrieveJobVehicles', function(source, cb, type)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE type = @type AND job = @job', {
		['@type'] = type,
		['@job'] = xPlayer.job.name
	}, function(result)
		cb(result)
	end)
end)

RegisterServerEvent('az_parking:setJobVehicleState')
AddEventHandler('az_parking:setJobVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate AND job = @job', {
		['@stored'] = state,
		['@plate'] = plate,
		['@job'] = xPlayer.job.name
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('az_parking: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)