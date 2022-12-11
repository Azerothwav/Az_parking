local started = false
local ZoneVehicles = {}

-- Handle resource START, get all vehicles from DB
MySQL.ready(function()
	if not started then
		GetVehiclesFromDatabase()
	end
end)

-- Store all vehicles in the AutoStoreCarParking that belong to users who no longer belong to that job
function StoreAllJobCars()
	MySQL.Async.fetchAll("SELECT plate, garage_name FROM owned_vehicles JOIN users ON owned_vehicles.owner = users.identifier WHERE garage_name IS NOT NULL AND owned_vehicles.job IS NOT NULL "..(Config.EnableCivJob and "AND owned_vehicles.job <> '"..Config.CivJob.."'" or "").." AND NOT (owned_vehicles.job = users.job OR CONCAT('off',owned_vehicles.job) = users.job) AND `stored` = 1", {}, 
	function(rs)
		if type(rs) == 'table' and #rs > 0 then
			for key, value in pairs(rs) do
				print("STORING JOB CARS: ", value.plate, value.garage_name)
				RemoveVehicleFromZone({ plate = value.plate, garageName = value.garage_name })
			end
		end
		MySQL.Async.execute("UPDATE owned_vehicles RIGHT JOIN users ON owned_vehicles.owner = users.identifier SET `stored` = 1, garage_name = '"..Config.StoreJobCarsGarage.."' WHERE owned_vehicles.job IS NOT NULL "..(Config.EnableCivJob and "AND owned_vehicles.job <> '"..Config.CivJob.."'" or "").." AND NOT (owned_vehicles.job = users.job OR CONCAT('off',owned_vehicles.job) = users.job)", {}, 
		function(rs)
			if Config.PrintCarStored then
				print("STORED "..rs.." CARS")
			end
		end)
	end)
end

RegisterServerEvent('az_parking:addGlobalVehicle')
AddEventHandler('az_parking:addGlobalVehicle', function(vehicle, garageName)
	TriggerClientEvent("az_parking:addVehicle", -1, vehicle, garageName)
end)

RegisterServerEvent('az_parking:removeGlobalVehicle')
AddEventHandler('az_parking:removeGlobalVehicle', function(source, vehicle, garageName)
	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `location` = NULL, `garage_name` = NULL, `garage_time` = NULL WHERE `plate` = @plate', {
		["@plate"]      = vehicle.plate
	})
	TriggerClientEvent("az_parking:deleteVehicle", -1, vehicle, garageName)
	RemoveVehicleFromZone(vehicle)
end)

RegisterServerEvent('az_parking:impoundVehicle')
AddEventHandler('az_parking:impoundVehicle', function(cb, vehicleProps, garageName)
	local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
	local plate = vehicleProps.plate
	MySQL.Async.fetchAll(
	'UPDATE owned_vehicles SET vehicle=@props, pound=1, location=NULL, garage_time=NULL, garage_name=NULL WHERE plate=@plate',
	{
		['@props'] = json.encode(vehicleProps),
		['@plate'] = plate
	}, function(rs)
		if rs and (not rs.errorCount) then
			if Config.Debug then
				print('IMPOUNDED VEHICLE: ', plate)
			end
			local vehicleData = { plate = plate, garageName = garageName }
			TriggerClientEvent("az_parking:deleteVehicle", -1, vehicleData, garageName)
			RemoveVehicleFromZone(vehicleData)
			cb(true)
		else
			cb(false)
		end
	end)
end)

RegisterServerEvent('az_parking:getVehicleInfo')
AddEventHandler('az_parking:getVehicleInfo', function(cb, plate, fromCallback, player)
	local xPlayer = nil
	local _source = source
	if fromCallback then
		xPlayer = ESX.GetPlayerFromId(player)
	else
		xPlayer = ESX.GetPlayerFromId(_source)
	end
	MySQL.Async.fetchAll("SELECT owned_vehicles.owner, owned_vehicles.plate, owned_vehicles.garage_time, owned_vehicles.garage_name, users.firstname, users.lastname FROM owned_vehicles LEFT JOIN users ON users.identifier = owned_vehicles.owner WHERE plate=@plate", {
		['@plate']      = plate
	}, function(rs)
		if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
			local parkingPrice = 0
			if rs[1].garage_time and rs[1].garage_name then
				parkingPrice = _Utils.GetParkingPrice(rs[1].garage_time, _Parkings[rs[1].garage_name].fee, _Parkings[rs[1].garage_name].minFee)
			end
			local vehicleInfo = {
				plate = plate,
				price = parkingPrice,
				garageName = rs[1].garage_name,
				owner = rs[1].owner,
				firstname = rs[1].firstname or '',
				lastname = rs[1].lastname or '',
				officer = xPlayer.name or ''
			}
			cb(vehicleInfo)
		else
			cb(nil)
		end
	end)
end)

-- Add Vehicle to Local ZoneVehicles storage
function AddVehicleToZone(vehicle, zone)
	if ZoneVehicles[zone] == nil then
		local newZone = { zone }
		table.insert(ZoneVehicles, newZone)
		ZoneVehicles[zone] = {}
	end
	ZoneVehicles[zone][vehicle.plate] = {type = vehicle.type, props = vehicle.props, location = vehicle.location, parking = zone, plate = vehicle.plate, time = vehicle.garageTime, owner = vehicle.owner}
end

-- Remove Vehicle from Local ZoneVehicles storage
function RemoveVehicleFromZone(vehicle)
	if vehicle.garageName == nil then
		for key, zone in pairs(ZoneVehicles) do
			for index, veh in pairs(zone) do
				if veh.plate and veh.plate == vehicle.plate then
					ZoneVehicles[zone][veh.plate] = nil
					return
				end
			end
		end
	else
		local garageName = vehicle.garageName
		if ZoneVehicles[garageName] == nil then
			return
		end
		ZoneVehicles[garageName][vehicle.plate] = nil
	end
end

-- GET ALL VEHICLES FROM DATABASE for this parking type
function GetVehiclesFromDatabase() 
	StoreAllJobCars()
	started = true
	MySQL.Async.fetchAll("SELECT owner,plate,type,vehicle,garage_name,garage_time,location FROM owned_vehicles WHERE garage_name IS NOT NULL AND garage_type=@garage_type AND pound=0 AND `stored`=1", {
		['@garage_type']  = Config.RealParking.Type
	}, function(response) 
		if type(response) == 'table' and #response > 0 then
			if Config.Debug then
				print("Loading "..#response.." cars")
			end
			for k, v in pairs(response) do
				if v.vehicle and v.location then
					local vProps = json.decode(v.vehicle)
					local vLocation = json.decode(v.location)
					local plate   = v.plate
					local fee = 0
					if _Parkings and _Parkings[v.garage_name] then
						fee = _Parkings[v.garage_name].fee
						if fee == nil or fee < 0 then
							fee = 0
						end
					end
					AddVehicleToZone({ plate = plate, props = vProps, location = vLocation, garageTime = v.garage_time, owner = v.owner }, v.garage_name)
				end
			end
		else
			if Config.Debug then
				print("No cars founded")
			end
		end
	end)
end

function addToSet(set, key)
    set[key] = true
end

function removeFromSet(set, key)
    set[key] = nil
end

function setContains(set, key)
    return set[key] ~= nil
end

-- Get amount of vehicles parking at GARAGE NAME
function GetParkingCount(name, location)
	if ZoneVehicles[name] == nil then
		return true, 0, 0
	end
	local coords = vector3(location.x, location.y, location.z)
	local parkCount = 0
	local modelCount = 0
	local models = {}
	for key, value in pairs(ZoneVehicles[name]) do
		parkCount = parkCount + 1
		local valueCoords = vector3(value.location.x, value.location.y, value.location.z)
		if #(coords - valueCoords) <= 2.2 then
			return false, 0, 0
		end
		if not setContains(models, value.props.model) then
			addToSet(models, value.props.model)
			modelCount = modelCount + 1
		end
	end
	return true, parkCount, modelCount
end

-- Get vehicles at specific GARAGE NAME
ESX.RegisterServerCallback("az_parking:getZoneVehicles", function(source, cb, garageName)
	Citizen.CreateThread(function()
		while not started do
			Citizen.Wait(100)
		end
		if started then
			if ZoneVehicles[garageName] == nil then
				if Config.Debug then
					print("The parking "..garageName.." doesnt have cars")
				end
				cb({})
			else
				cb(ZoneVehicles[garageName])
			end
		end
	end)
end)

-- Get VEHICLE parking price from FEE
ESX.RegisterServerCallback("az_parking:getCarParkingPrice", function(source, cb, plate)
	if Config.Debug then
		print("Buscando placa: ".. plate)
	end

	local vehicle = false
	for parkIndex, park in pairs(ZoneVehicles) do
		for carIndex, car in pairs(park) do
			if car.plate == plate then
				vehicle = car
			end
		end
	end

	if vehicle then
		if Config.Debug then
			print("We have founded one vehicle")
			print(json.encode(vehicle))
		end
		local garageName = vehicle.parking
		local fee = 0
		if garageName == nil then
			-- TODO: NOTIFY CAR PARKING NAME NOT FOUND
			if Config.Debug then
				print("Parking not founded")
			end
			cb(0, 0, vehicle.owner, nil)
		end
		if vehicle.time ~= nil and _Parkings[garageName] ~= nil and _Parkings[garageName].fee ~= nil then
			if Config.Debug then
				print("Parking price cannot be calculated")
			end
			local currentFee = _Utils.GetParkingPrice(vehicle.time, _Parkings[garageName].fee, _Parkings[garageName].minFee)
			if Config.Debug then
				print("Price of parking: "..currentFee)
			end
			cb(currentFee, _Parkings[garageName].fee, vehicle.owner, garageName)
		else
			-- TODO: NOTIFY CAR FEE ERROR
			cb(0, 0, vehicle.owner, garageName)
		end
	else
		if Config.Debug then
			print("No se encontraron vehiculos")
		end
		cb(0, 0, nil, nil)
	end
end)

-- Save a CAR into parking zone
ESX.RegisterServerCallback("az_parking:saveVehicle", function(source, cb, vehicle)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plate   = vehicle.props.plate
	
	if vehicle.garageName == nil or _Parkings[vehicle.garageName] == nil then
		cb({
			status  = false,
			message = _U("parking_not_found"),
		})
		return
	end
	local freeSlot, countCars, countModels = GetParkingCount(vehicle.garageName, vehicle.location)
	if not freeSlot then
		cb({
			status  = false,
			message = _U("busy_place"),
		})
		return
	end
	if countModels > Config.RealParking.MaxModels then
		cb({
			status  = false,
			message = _U("max_models"),
		})
		return
	end
	if countCars > _Parkings[vehicle.garageName].maxcar then
		cb({
			status  = false,
			message = _U("parking_full"),
		})
		return
	end
	if xPlayer then
		_Utils.SaveCarInDatabase(xPlayer, vehicle, plate, Config.RealParking.Type, cb, AddVehicleToZone)
	else
		cb({
			status  = false,
			message = _U("player_error"),
		})
		return
	end
end)

-- Get out to Drive a Vehicle
ESX.RegisterServerCallback("az_parking:driveVehicle", function(source, callback, vehicle, garageName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plate   = vehicle.plate
	
	MySQL.Async.fetchAll("SELECT owner,plate,type,vehicle,garage_name,garage_time,location,job FROM owned_vehicles WHERE `owner` = @identifier AND `plate` = @plate AND `stored` = 1", {
		['@identifier'] = xPlayer.identifier,
		['@plate']      = plate,
		['@garage_type']  = Config.RealParking.Type
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

			local fee         =  _Utils.GetParkingPrice(rs[1].garage_time, _Parkings[rs[1].garage_name].fee, _Parkings[rs[1].garage_name].minFee)
			local playerMoney = xPlayer.getMoney()		
			
			if playerMoney >= fee then
				
				if _Parkings[rs[1].garage_name].society then
					TriggerEvent('esx_addonaccount:getSharedAccount', _Parkings[rs[1].garage_name].society, function(account)
						xPlayer.removeMoney(fee)
						account.addMoney(fee)
					end)
				else
					xPlayer.removeMoney(fee)
				end

				MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = 0, `location` = NULL, `garage_name` = NULL, `garage_time` = NULL, `garage_type`=@garage_type WHERE `plate` = @plate AND `owner` = @identifier', {
					["@plate"]      = plate,
					["@identifier"] = xPlayer.identifier,
					['@garage_type']  = Config.RealParking.Type
				})
				
				local vehicleData = { 
					plate = rs[1].plate, 
					props = json.decode(rs[1].vehicle), 
					location = json.decode(rs[1].location), 
					garageTime = rs[1].garage_time, 
					owner = rs[1].owner, 
					garageName = rs[1].garage_name
				}
				TriggerClientEvent("az_parking:deleteVehicle", -1, vehicleData, rs[1].garage_name)
				RemoveVehicleFromZone(vehicleData)
				
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

ESX.RegisterServerCallback('az_parking:payMoney', function(source, cb, money, society)
	local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
	local playerMoney = xPlayer.getMoney() or 0
    if xPlayer and playerMoney >= money then
		if society then
			TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
				xPlayer.removeMoney(money)
				account.addMoney(money)
			end)
		else
			xPlayer.removeMoney(money)
		end
        cb(true)
    else
        cb(false, money - playerMoney)
    end
end)

ESX.RegisterServerCallback("az_parking:getVehicleCallback", function(source, callback, plate)
	TriggerEvent('az_parking:getVehicleInfo', function(vehicleData) 
		callback(vehicleData)
	end, plate, true, source)
end)
  
TriggerEvent('cron:runAt', 1, 0, StoreAllJobCars)