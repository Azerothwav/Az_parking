if Config.FrameWork == "ESX" then
	ESX.RegisterServerCallback("az_parking:getOutFromGarage", function(source, callback, vehicle, garageName)
		local xPlayer = ESX.GetPlayerFromId(source)
		local plate   = vehicle.plate
		
		MySQL.Async.fetchAll("SELECT owner,plate,type,vehicle,garage_name,job FROM owned_vehicles WHERE `owner` = @identifier AND `plate` = @plate AND `stored` = 1", {
			['@identifier'] = xPlayer.identifier,
			['@plate']      = plate,
			['@garage_type']  = 1
		}, function(rs)
			if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
				MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `garage_name` = NULL, `garage_type`=@garage_type WHERE `plate` = @plate AND `owner` = @identifier', {
					["@plate"]      = plate,
					["@identifier"] = xPlayer.identifier,
					['@garage_type']  = 1
				})
				local vehicleData = { 
					plate = rs[1].plate, 
					props = json.decode(rs[1].vehicle), 
					owner = rs[1].owner, 
					garageName = rs[1].garage_name
				}
				callback({
					status  = true,
					message = Config.Lang["car_out"],
					vehData = vehicleData
				})
				return
			else
				callback({
					status  = false,
					message = Config.Lang["car_error"],
				})
				return
			end
		end)
	end)

	ESX.RegisterServerCallback('az_parking:getGarageCars', function(source, cb, parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		local identifier = xPlayer.identifier
		local query = "SELECT * FROM owned_vehicles WHERE owner=@identifier AND type=@vehType AND job IS NULL AND stored=1 AND garage_name=@garagename"
		local dataquery = {
			['@identifier'] = identifier,
			['@vehType'] = parametre.vehType,
			['@garagename'] = parametre.garageName
		}
		MySQL.Async.fetchAll(
			query,
			dataquery,
		function(result)
			local vehicles = nil
			if type(result) == 'table' and #result > 0 then
				vehicles = {}
				for key, vehicle in pairs(result) do
					table.insert(vehicles, vehicle)
				end
			end
			cb(vehicles)
		end)
	end)

	ESX.RegisterServerCallback('az_parking:storeVehicle', function(source, cb, vehicle)
		local xPlayer = ESX.GetPlayerFromId(source)
		local plate   = vehicle.props.plate
		local query = nil
		if vehicle.garageJobName == nil or vehicle.garageJobName == "none" or vehicle.garageJobName == "civ" then
			if vehicle.type == 2 then
				query = "SELECT job, vip FROM owned_vehicles WHERE plate = @plate"
			else
				query = "SELECT job FROM owned_vehicles WHERE plate = @plate"
			end
			dataquery = {
				['@plate'] = plate
			}
			MySQL.Async.fetchAll(query, dataquery, function(result)
				if result[1] == nil then
					cb({
						status  = false,
						stunvehicle = true,
						message = Config.Lang["car_error"],
					})
				else
					if result[1].job ~= nil then
						cb({
							status  = false,
							message = Config.Lang["job_vehicle"],
						})
					elseif result[1].vip ~= 0 and vehicle.type == 2 then
						cb({
							status  = false,
							message = Config.Lang["steal_vip"],
						})
					else
						if vehicle.garageName == nil then
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
						if xPlayer then
							_Utils.SaveCarInDatabase(xPlayer, vehicle, plate, vehicle.type, cb)
						else
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
					end
				end
			end)
		else
			query = "SELECT job FROM owned_vehicles WHERE plate = @plate"
			dataquery = {
				['@plate'] = plate
			}
			MySQL.Async.fetchAll(query, dataquery, function(result)
				if result[1] == nil or result[1]["job"] == nil then
					cb({
						status  = false,
						message = Config.Lang["car_error"],
					})
				else
					if result[1]["job"] == nil and result[1]["job"] ~= xPlayer["job"].name then
						cb({
							status  = false,
							message = Config.Lang["cant_access"],
						})
					else
						if vehicle.garageName == nil then
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
						if xPlayer then
							_Utils.SaveCarInDatabase(xPlayer, vehicle, plate, 1, cb)
						else
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
					end
				end
			end)
		end
	end)

	ESX.RegisterServerCallback('az_parking:retrieveJobVehicles', function(source, cb, parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		query = "SELECT vehiclename, plate, vehicle, owner, stored FROM owned_vehicles WHERE job = @job AND garage_name=@garagename"
		dataquery = {
			['@job'] = parametre.jobname,
			['@garagename'] = parametre.garageName
		}
		MySQL.Async.fetchAll(query, dataquery, function(result)
			cb(result)
		end)
	end)

	RegisterServerEvent('az_parking:setJobVehicleState')
	AddEventHandler('az_parking:setJobVehicleState', function(parametre)
		local xPlayer = ESX.GetPlayerFromId(source)
		query = "UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate AND job = @job"
		dataquery = {
			['@stored'] = parametre.state,
			['@plate'] = parametre.plate,
			['@job'] = parametre.jobname
		}
		MySQL.Async.execute(query, dataquery, function()
		end)
	end)

	if Config.StoreOnServerStart then
		MySQL.ready(function ()
			MySQL.Async.execute("UPDATE owned_vehicles SET `stored`=0 WHERE `stored`=3", {})
		end)
	end

	RegisterServerEvent('az_parking:transfereJob')
	AddEventHandler('az_parking:transfereJob', function(plate)
		local xPlayer = ESX.GetPlayerFromId(source)
		MySQL.Async.execute('UPDATE owned_vehicles SET `job` = @job WHERE plate = @plate', {
			['@job'] = xPlayer.job.name,
			['@plate'] = plate,
		}, function()
		end)
	end)

	RegisterServerEvent('az_parking:renamevehicle')
	AddEventHandler('az_parking:renamevehicle', function(plate, name)
		MySQL.Async.execute('UPDATE owned_vehicles SET vehiclename=@vehiclename WHERE plate=@plate', {['@vehiclename'] = name, ['@plate'] = plate})
	end)
elseif Config.FrameWork == "QBCore" then
	QBCore.Functions.CreateCallback("az_parking:getOutFromGarage", function(source, callback, vehicle, garageName)
		local Player = QBCore.Functions.GetPlayer(source)
		local plate   = vehicle.plate
		
		MySQL.Async.fetchAll("SELECT citizenid,plate,mods,garage FROM player_vehicles WHERE `citizenid` = @citizenid AND `plate` = @plate AND `state` = 1", {
			['@citizenid'] = Player.PlayerData.citizenid,
			['@plate']      = plate,
			['@garage_type']  = 1
		}, function(rs)
			if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
				MySQL.Async.execute('UPDATE player_vehicles SET `state` = 0, `garage` = NULL WHERE `plate` = @plate AND `citizenid` = @citizenid', {
					["@plate"]      = plate,
					["@citizenid"] = Player.PlayerData.citizenid
				})
				local vehicleData = { 
					plate = rs[1].plate, 
					props = json.decode(rs[1].mods), 
					owner = rs[1].citizenid, 
					garageName = rs[1].garage
				}
				callback({
					status  = true,
					message = Config.Lang["car_out"],
					vehData = vehicleData
				})
				return
			else
				callback({
					status  = false,
					message = Config.Lang["car_error"],
				})
				return
			end
		end)
	end)

	QBCore.Functions.CreateCallback('az_parking:getGarageCars', function(source, cb, parametre)
		local Player = QBCore.Functions.GetPlayer(source)
		query = "SELECT * FROM player_vehicles WHERE citizenid=@citizenid AND job IS NULL AND state=1 AND garage=@garagename"
		dataquery = {
			['@citizenid'] = Player.PlayerData.citizenid,
			['@garagename'] = parametre.garageName
		}
		MySQL.Async.fetchAll(
			query,
			dataquery,
		function(result)
			local vehicles = nil
			if type(result) == 'table' and #result > 0 then
				vehicles = {}
				for key, vehicle in pairs(result) do
					table.insert(vehicles, vehicle)
				end
			end
			cb(vehicles)
		end)
	end)

	QBCore.Functions.CreateCallback('az_parking:storeVehicle', function(source, cb, vehicle)
		local Player = QBCore.Functions.GetPlayer(source)
		local plate   = vehicle.props.plate
		local query = nil
		if vehicle.garageJobName == nil or vehicle.garageJobName == "none" or vehicle.garageJobName == "civ" then
			if vehicle.type == 2 then
				query = "SELECT job, vip FROM player_vehicles WHERE plate = @plate"
			else
				query = "SELECT job FROM player_vehicles WHERE plate = @plate"
			end
			dataquery = {
				['@plate'] = plate
			}
			MySQL.Async.fetchAll(query, dataquery, function(result)
				if result[1] == nil then
					cb({
						status  = false,
						stunvehicle = true,
						message = Config.Lang["car_error"],
					})
				else
					if result[1].job ~= nil then
						cb({
							status  = false,
							message = Config.Lang["job_vehicle"],
						})
					elseif result[1].vip ~= 0 and vehicle.type == 2 then
						cb({
							status  = false,
							message = Config.Lang["steal_vip"],
						})
					else
						if vehicle.garageName == nil then
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
						if Player then
							_Utils.SaveCarInDatabase(Player, vehicle, plate, vehicle.type, cb)
						else
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
					end
				end
			end)
		else
			query = "SELECT job FROM player_vehicles WHERE plate = @plate"
			dataquery = {
				['@plate'] = plate
			}
			MySQL.Async.fetchAll(query, dataquery, function(result)
				if result[1] == nil or result[1]["job"] == nil then
					cb({
						status  = false,
						message = Config.Lang["car_error"],
					})
				else
					if result[1]["job"] == nil and result[1]["job"] ~= Player.PlayerData.job.name then
						cb({
							status  = false,
							message = Config.Lang["cant_access"],
						})
					else
						if vehicle.garageName == nil then
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
						if Player then
							_Utils.SaveCarInDatabase(Player, vehicle, plate, 1, cb)
						else
							cb({
								status  = false,
								message = Config.Lang["car_error"],
							})
						end
					end
				end
			end)
		end
	end)

	QBCore.Functions.CreateCallback('az_parking:retrieveJobVehicles', function(source, cb, parametre)
		query = "SELECT vehiclename, plate, mods, citizenid, state FROM player_vehicles WHERE job = @job AND garage=@garagename"
		dataquery = {
			['@job'] = parametre.jobname,
			['@garagename'] = parametre.garageName
		}
		MySQL.Async.fetchAll(query, dataquery, function(result)
			cb(result)
		end)
	end)

	RegisterServerEvent('az_parking:setJobVehicleState')
	AddEventHandler('az_parking:setJobVehicleState', function(parametre)
		query = "UPDATE player_vehicles SET `state` = @state WHERE plate = @plate AND job = @job"
		dataquery = {
			['@stored'] = parametre.state,
			['@plate'] = parametre.plate,
			['@job'] = parametre.jobname
		}
		MySQL.Async.execute(query, dataquery, function()
		end)
	end)

	if Config.StoreOnServerStart then
		MySQL.ready(function ()
			MySQL.Async.execute("UPDATE player_vehicles SET `state`=1 WHERE `state`=0", {})
		end)
	end

	RegisterServerEvent('az_parking:transfereJob')
	AddEventHandler('az_parking:transfereJob', function(plate)
		local Player = QBCore.Functions.GetPlayer(source)
		MySQL.Async.execute('UPDATE player_vehicles SET `job` = @job WHERE plate = @plate', {
			['@job'] = Player.PlayerData.job.name,
			['@plate'] = plate,
		}, function()
		end)
	end)

	RegisterServerEvent('az_parking:renamevehicle')
	AddEventHandler('az_parking:renamevehicle', function(plate, name)
		MySQL.Async.execute('UPDATE player_vehicles SET vehiclename=@vehiclename WHERE plate=@plate', {['@vehiclename'] = name, ['@plate'] = plate})
	end)
end

RegisterNetEvent('az_parking:deleteCar', function(entity)
	DeleteEntity(NetworkGetEntityFromNetworkId(entity))  
end)