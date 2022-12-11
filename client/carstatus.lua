-- Global Variables
local CarsOnEarth = {}

function AddCarOnEarth(plate, entity)
    table.insert(CarsOnEarth, { plate = plate, entity = entity })
end

function IsCarOnEarth(plate)
	for k,v in pairs (CarsOnEarth) do
		if ESX.Math.Trim(v.plate) == ESX.Math.Trim(plate) then
			if DoesEntityExist(v.entity) then
				return true
			else
				table.remove(CarsOnEarth, k)
				return false
			end
		end
	end
end

function RemoveCarFromEarth(plate, entity)
	for k,v in pairs (CarsOnEarth) do
		if ESX.Math.Trim(v.plate) == ESX.Math.Trim(plate) then
			table.remove(CarsOnEarth, k)
		end
	end
end