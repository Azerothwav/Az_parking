if Config.FrameWork == "ESX" then
	ESX.RegisterServerCallback("az_parking:getOutFromRecover", function(source, callback, parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		local plate   = parametre.vehicle.plate
		local query = nil
		local dataquery = {}
		if parametre.jobname ~= nil and parametre.jobname ~= "civ" and parametre.jobname ~= "none" then
			query = "SELECT plate, vehicle, owner FROM owned_vehicles WHERE job = @job AND `plate` = @plate"
			dataquery = {
				['@job'] = parametre.jobname,
				['@plate']      = plate
			}
		else
			query = "SELECT plate, vehicle, owner FROM owned_vehicles WHERE `owner` = @identifier AND `plate` = @plate"
			dataquery = {
				['@identifier'] = xPlayer.identifier,
				['@plate']      = plate
			}
		end
		MySQL.Async.fetchAll(query, dataquery
		, function(rs)
			if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
				local fee = Config.RecoverBasePrice
				local playerMoney = xPlayer.getAccount('bank').money	
				local playerBank = xPlayer.getAccount('money').money
				
				if playerMoney >= fee or playerBank >= fee then
					if playerMoney >= fee then
						xPlayer.removeAccountMoney('bank', fee)
					elseif playerBank >= fee then
						xPlayer.removeAccountMoney('money', fee)
					end
					MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `garage_name` = NULL, `garage_type`= NULL WHERE `plate` = @plate', {
						["@plate"]      = plate
					})
					local vehicleData = { 
						plate = rs[1].plate, 
						props = json.decode(rs[1].vehicle), 
						owner = rs[1].owner, 
					}
					callback({
						status  = true,
						message = Config.Lang["car_out"],
						vehData = vehicleData
					})
					return
				else
					local left = fee - playerMoney
					callback({
						status  = false,
						message = Config.Lang["not_enought_money"],
					})
					return
				end
			else
				callback({
					status  = false,
					message = Config.Lang["car_error"],
				})
				return
			end
		end)
	end)

	ESX.RegisterServerCallback('az_parking:getNotStored', function(source, cb, parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		local identifier = xPlayer.identifier
		local query = nil
		local dataquery = {}
		if parametre.jobname ~= nil and parametre.jobname ~= "civ" and parametre.jobname ~= "none" then
			query = "SELECT * FROM owned_vehicles WHERE job =@job AND (`stored`=0) AND type=@vehType"
			dataquery = {
				['@job'] = parametre.jobname,
				['@vehType'] = parametre.type,
			}
		else
			query = "SELECT * FROM owned_vehicles WHERE `owner` = @identifier AND (`stored`=0) AND type=@vehType AND job IS NULL"
			dataquery = {
				['@identifier'] = xPlayer.identifier,
				['@vehType'] = parametre.type,
			}
		end
		MySQL.Async.fetchAll(
			query,
			dataquery,
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
elseif Config.FrameWork == "QBCore" then
	QBCore.Functions.CreateCallback("az_parking:getOutFromRecover", function(source, callback, parametre)
		local Player = QBCore.Functions.GetPlayer(source)
		local plate   = parametre.vehicle.plate
		local query = nil
		local dataquery = {}
		if parametre.jobname ~= nil then
			query = "SELECT plate, mods, citizenid FROM player_vehicles WHERE job = @job AND `plate` = @plate"
			dataquery = {
				['@job'] = parametre.jobname,
				['@plate']      = plate
			}
		else
			query = "SELECT plate, mods, citizenid FROM player_vehicles WHERE `citizenid` = @citizenid AND `plate` = @plate"
			dataquery = {
				['@citizenid'] = Player.PlayerData.citizenid,
				['@plate']      = plate
			}
		end
		MySQL.Async.fetchAll(query, dataquery
		, function(rs)
			if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
				local fee = Config.RecoverBasePrice
				local playerMoney = xPlayer.getAccount('bank').money	
				local playerBank = xPlayer.getAccount('money').money
				
				if playerMoney >= fee or playerBank >= fee then
					if playerMoney >= fee then
						xPlayer.removeAccountMoney('bank', fee)
					elseif playerBank >= fee then
						xPlayer.removeAccountMoney('money', fee)
					end
					MySQL.Async.execute('UPDATE player_vehicles SET `state` = 0, `garage` = NULL WHERE `plate` = @plate', {
						["@plate"]      = plate
					})
					local vehicleData = { 
						plate = rs[1].plate, 
						props = json.decode(rs[1].mods), 
						owner = rs[1].citizenid, 
					}
					callback({
						status  = true,
						message = Config.Lang["car_out"],
						vehData = vehicleData
					})
					return
				else
					local left = fee - playerMoney
					callback({
						status  = false,
						message = Config.Lang["not_enought_money"],
					})
					return
				end
			else
				callback({
					status  = false,
					message = Config.Lang["car_error"],
				})
				return
			end
		end)
	end)

	QBCore.Functions.CreateCallback('az_parking:getNotStored', function(source, cb, parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		local query = nil
		local dataquery = {}
		if parametre.jobname ~= nil then
			query = "SELECT * FROM player_vehicles WHERE job =@job AND `state`=0"
			dataquery = {
				['@job'] = parametre.jobname
			}
		else
			query = "SELECT * FROM player_vehicles WHERE `citizenid` = @citizenid AND `state`=0"
			dataquery = {
				['@citizenid'] = Player.PlayerData.citizenid
			}
		end
		MySQL.Async.fetchAll(
			query,
			dataquery,
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
end