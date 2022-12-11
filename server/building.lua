local Garages = {}
local Recovers = {}

MySQL.ready(function()
	local result = json.decode(LoadResourceFile("Az_parking", "./data/garages.json"))
	if result ~= nil then
		for k, v in pairs(result) do
			Garages[k] = {}
			for x, w in pairs(v) do
				Garages[k][x] = w
			end
		end
	end
	local result2 = json.decode(LoadResourceFile("Az_parking", "./data/recovers.json"))
	if result2 ~= nil then
		for k, v in pairs(result2) do
			Recovers[k] = {}
			for x, w in pairs(v) do
				Recovers[k][x] = w
			end
		end
	end
end)

RegisterNetEvent('az_garage:setNewGarage')
AddEventHandler('az_garage:setNewGarage', function(indication, data)
	if indication == 'garage' then
		table.insert(Garages, {name = data.name, spawnPos = data.possiblespawn, position = data.spawnpoint, delete = data.deletepoint, jobname = data.jobname})
		SaveResourceFile("Az_parking", "./data/garages.json", json.encode(Garages), -1)
		TriggerClientEvent('az_garage:rebootGarage', -1, Garages, Recovers)
	elseif indication == 'recover' then
		table.insert(Recovers, {name = data.name, spawnPos = data.possiblespawn, position = data.spawnpoint, jobname = data.jobname, typeVeh = 'car'})
		SaveResourceFile("Az_parking", "./data/recovers.json", json.encode(Recovers), -1)
		TriggerClientEvent('az_garage:rebootGarage', -1, Garages, Recovers)
	end
end)