-- Get out from recover to drive
ESX.RegisterServerCallback("az_parking:getOutFromRecover", function(source, callback, vehicle)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plate   = vehicle.plate
	
	MySQL.Async.fetchAll("SELECT owned_vehicles.plate, owned_vehicles.vehicle, owned_vehicles.owner, vehicle_model_prices.price FROM owned_vehicles LEFT JOIN vehicle_model_prices ON owned_vehicles.model = vehicle_model_prices.model WHERE `owner` = @identifier AND `plate` = @plate", {
		['@identifier'] = xPlayer.identifier,
		['@plate']      = plate
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

			local fee         =   math.floor(rs[1].price or Config.RecoverBasePrice * Config.RecoverRate)
			local playerMoney = xPlayer.getMoney()		
			
			if playerMoney >= fee then
				TriggerEvent('esx_addonaccount:getSharedAccount', Config.RecoverPoints.Society, function(account)
					xPlayer.removeMoney(fee)
					account.addMoney(fee)
				end)
				MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `location` = NULL, `garage_name` = NULL, `garage_time` = NULL, `garage_type`= NULL WHERE `plate` = @plate AND `owner` = @identifier', {
					["@plate"]      = plate,
					["@identifier"] = xPlayer.identifier
				})
				local vehicleData = { 
					plate = rs[1].plate, 
					props = json.decode(rs[1].vehicle), 
					owner = rs[1].owner, 
				}
				if fee == 0 then
					callback({
						status  = true,
						message = string.format(_U("recover_free_success")),
						vehData = vehicleData
					})
					return;
				else
					callback({
						status  = true,
						message = string.format(_U("recover_success", fee)),
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

ESX.RegisterServerCallback('az_parking:getNotStoredCars', function(source, cb)
    local _source = source
    xPlayer = ESX.GetPlayerFromId(_source)
    identifier = xPlayer.identifier

    MySQL.Async.fetchAll(
    'SELECT owned_vehicles.*, vehicle_model_prices.price FROM owned_vehicles LEFT JOIN vehicle_model_prices ON owned_vehicles.model = vehicle_model_prices.model WHERE owner=@identifier AND (`stored`=0 AND pound=0)',
    {
        ['@identifier'] = identifier,
        ['@job'] = xPlayer.job.name,
		['@job2'] = xPlayer.job2.name
    },
    function(result)
		if type(result) == 'table' and #result > 0 and result[1] ~= nil then
			for key, value in pairs(result) do
				value.price = value.price or Config.RecoverBasePrice
			end
       		cb(result)
		else
			cb({})
		end
    end)
end)