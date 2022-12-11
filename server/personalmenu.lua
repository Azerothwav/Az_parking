ESX.RegisterServerCallback('az_parking:getAllCars', function(source, cb)
    local _source = source
    xPlayer = ESX.GetPlayerFromId(_source)
    identifier = xPlayer.identifier

    MySQL.Async.fetchAll(
        'SELECT owned_vehicles.*, vehicle_model_prices.price FROM owned_vehicles LEFT JOIN vehicle_model_prices ON owned_vehicles.model = vehicle_model_prices.model WHERE owner=@identifier AND (job IS NULL OR job = @job)',
    {
        ['@identifier'] = identifier,
        ['@job'] = xPlayer.job.name,
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

RegisterServerEvent('az_parking:renamevehicle')
AddEventHandler('az_parking:renamevehicle', function(plate, name)
    MySQL.Async.execute('UPDATE owned_vehicles SET '..Config.VehicleNameColumn..'=@vehiclename WHERE plate=@plate', {['@vehiclename'] = name, ['@plate'] = plate})
end)