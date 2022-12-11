_Utils = {}
if Config.FrameWork == "ESX" then
	ESX = nil
	
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

	_Utils.SaveCarInDatabase = function(xPlayer, vehicle, plate, garageType, callback, onSaved)
		MySQL.Async.execute("UPDATE owned_vehicles SET `stored` = 1, `garage_name` = @garage_name, `vehicle` = @vehicle, `garage_type` = @garage_type WHERE `plate` = @plate",
		{
			["@vehicle"]    = json.encode(vehicle.props),
			["@garage_name"] = vehicle.garageName,
			["@identifier"]   = xPlayer.identifier,
			['@garage_type']  = garageType,
			["@plate"]   = plate,
		},
		function(rowsChanged)
			if rowsChanged > 0 then
				local vehicle = { plate = plate, props = vehicle.props, garageName = vehicle.garageName, owner = xPlayer.identifier }
				if onSaved then
					onSaved(vehicle, vehicle.garageName)
				end
				callback({
					status  = true,
					message = Config.Lang["car_save"],
					vehicle = vehicle
				})
				return
			end
		end)
	end
elseif Config.FrameWork == "QBCore" then
	QBCore = exports['qb-core']:GetCoreObject()

	_Utils.SaveCarInDatabase = function(Player, vehicle, plate, garageType, callback, onSaved)
		MySQL.Async.execute("UPDATE player_vehicles SET `state` = 1, `garage` = @garage_name, `mods` = @vehicle WHERE `plate` = @plate",
		{
			["@vehicle"]    = json.encode(vehicle.props),
			["@garage_name"] = vehicle.garageName,
			["@identifier"]   = Player.PlayerData.citizenid,
			["@plate"]   = plate,
		},
		function(rowsChanged)
			if rowsChanged > 0 then
				local vehicle = { plate = plate, props = vehicle.props, garageName = vehicle.garageName, owner = Player.PlayerData.citizenid }
				if onSaved then
					onSaved(vehicle, vehicle.garageName)
				end
				callback({
					status  = true,
					message = Config.Lang["car_save"],
					vehicle = vehicle
				})
				return
			end
		end)
	end
end

_Utils.ShowServerNotification = function(source, msg)
	if Config.FrameWork == "ESX" then
		local xPlayer = ESX.GetPlayerFromId(source)
		xPlayer.showNotification(msg)
	end
end