_Utils = {}

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

_Utils.GetParkingPrice = function(parkingTime, parkingFee, parkingMinFee)
	if parkingTime ~= nil and parkingFee ~= nil then
		local price = math.floor(((os.time() - parkingTime) / 86400) * parkingFee)
		if price > 0 then
			return price
		else
			return parkingMinFee or Config.MinParkingPrice or 0
		end
	else
		return 0
	end
end

_Utils.SendServerNotification = function(target, message, type)
	TriggerClientEvent("pNotify:SendNotification", target, {
		text = message,
		type = type,
		queue = "az_parking",
	})
end

_Utils.SaveCarInDatabase = function(xPlayer, vehicle, plate, garageType, callback, onSaved)
	MySQL.Async.fetchAll("SELECT plate,`stored` FROM owned_vehicles WHERE `plate` = @plate", {
		--['@identifier'] = xPlayer.identifier,
		['@plate']      = plate
	}, function(rs)
		if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil and rs[1].stored then
			callback({
				status  = false,
				message = _U("already_parking"),
			})
			return;
		elseif type(rs) == 'table' and #rs > 0 and rs[1] ~= nil and not rs[1].stored then
			MySQL.Async.execute("UPDATE owned_vehicles SET `stored` = 1, `location` = @location, `garage_time` = @time, `garage_name` = @garage_name, `vehicle` = @vehicle, `garage_type` = @garage_type WHERE `plate` = @plate",
			{
				["@vehicle"]    = json.encode(vehicle.props),
				["@location"]    = json.encode(vehicle.location),
				["@time"]    = os.time(),
				["@garage_name"] = vehicle.garageName,
				["@identifier"]   = xPlayer.identifier,
				['@garage_type']  = garageType,
				["@plate"]   = plate,
				--['@owner'] = xPlayer.identifier
			},
			function(rowsChanged)
				if rowsChanged > 0 then
					local vehicle = { plate = plate, props = vehicle.props, garageName = vehicle.garageName, location = vehicle.location, garageTime = os.time(), owner = xPlayer.identifier }
					if onSaved then
						onSaved(vehicle, vehicle.garageName)
					end
					callback({
						status  = true,
						message = _U("car_saved"),
						vehicle = vehicle
					})
					return;
				end
			end)
		else
			callback({
				status  = false,
				message = _U("not_your_car"),
			})
			return;
		end
	end)
end

_Utils.Round = function(value, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", value))
end