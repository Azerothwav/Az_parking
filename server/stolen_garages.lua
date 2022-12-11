StolenGarage = {}

MySQL.ready(function()
	local result = json.decode(LoadResourceFile("az_data", "./stolengarage.json"))
	if result ~= nil then
		for k, v in pairs(result) do
			StolenGarage[k] = {}
			for x, w in pairs(v) do
				StolenGarage[k][x] = w
			end
		end
	end
end)

RegisterNetEvent("az_parking:setNewStolenGarage")
AddEventHandler("az_parking:setNewStolenGarage", function(data)
	local index = #StolenGarage + 1
	for k, v in pairs(data) do
		if StolenGarage[index] == nil then
			StolenGarage[index] = {}
		end
		StolenGarage[index][k] = v
	end
	SaveResourceFile("az_data", "./stolengarage.json", json.encode(StolenGarage), -1)
end)

if Config.FrameWork == "ESX" then
	ESX.RegisterServerCallback('az_parking:getStolenVehicles', function(source, cb, index)
		local xPlayer = ESX.GetPlayerFromId(source)
		query = "SELECT vehiclename, plate, vehicle, owner, stored FROM owned_vehicles WHERE garage_type = @garage_type AND garage_name=@garagename"
		dataquery = {
			['@garage_type'] = 2,
			['@garagename'] = "stolengarage_"..index
		}
		MySQL.Async.fetchAll(query, dataquery, function(result)
			cb(result)
		end)
	end)

	RegisterNetEvent("az_parking:setOwnerStolenGarage")
	AddEventHandler("az_parking:setOwnerStolenGarage", function(identifier, garageindex)
		local xPlayer = ESX.GetPlayerFromId(source)
		if xPlayer.clearLicense == identifier then
			if xPlayer.getAccount('bank').money >= 1000 then
				xPlayer.removeAccountMoney('bank', 1000)
				StolenGarage[garageindex]["owner"] = identifier
				SaveResourceFile("az_data", "./stolengarage.json", json.encode(StolenGarage), -1)
				_Utils.ShowServerNotification(xPlayer.source, "Vous avez achetée le garage")
			else
				_Utils.ShowServerNotification(xPlayer.source, "Vous n'avez pas assez d'argent")
			end
		else
			StolenGarage[garageindex]["owner"] = identifier
			SaveResourceFile("az_data", "./stolengarage.json", json.encode(StolenGarage), -1)
		end
	end)
end